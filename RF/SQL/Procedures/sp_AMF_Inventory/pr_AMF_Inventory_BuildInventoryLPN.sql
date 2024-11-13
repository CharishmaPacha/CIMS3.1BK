/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/22  PKK     pr_AMF_Inventory_BuildInventoryLPN: Initial revision (CIMSV3-3036)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_BuildInventoryLPN') is null
  exec('Create Procedure pr_AMF_Inventory_BuildInventoryLPN as begin return; end')
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_BuildInventoryLPN: In this procedure we will be doing
    some basic validations followed by building an LPN if not passed by user and
    updating inventory on that LPN, Palletize the LPNs created f pallet is given
    and moved to Location if scanned
------------------------------------------------------------------------------*/
Alter Procedure pr_AMF_Inventory_BuildInventoryLPN
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputXML          TXML,
          @vrfcProcOutputXML         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vDeviceId                 TDeviceId,
          @vUserId                   TUserId,
          @vSKU                      TSKU,
          @LPN                       TLPN,
          @Pallet                    TPallet,
          @Location                  TLocation,
          @vInnerPacks               TInnerPacks,
          @vUnitsPerIP               TQuantity,
          @vUnits                    TQuantity,
          @vUnits1                   TQuantity,
          @vNumLPNs                  TInteger,
          @vInventoryClass1          TInventoryClass,
          @vInventoryClass2          TInventoryClass,
          @vInventoryClass3          TInventoryClass,
          @vReasonCode               TReasonCode,
          @vReasonCodeDescription    TDescription,
          @vOwnership                TOwnership,
          @vWarehouse                TWarehouse,
          @vReference                TReference,
          @vrfcSessionXML            TXML,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNStatus                TStatus,
          @vLPNType                  TTypeCode,
          @vLPNDetailId              TRecordId,
          @vLPNSKUId                 TRecordId,
          @vSKUId                    TRecordId,
          @vQuantity                 TQuantity,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLocationType             TLocationType,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vPalletStatus             TStatus,
          @vPalletLocId              TRecordId,
          @vFirstLPNId               TRecordId,
          @vFirstLPN                 TLPN,
          @vLastLPNId                TRecordId,
          @vLastLPN                  TLPN,
          @vDeviceName               TName,
          @vDefaultPrinter           TName,
          @vCreatedDate              TDateTime,
          @vAcceptExternalLPN        TControlValue,
          @vGeneratedLPNId           TRecordId,
          @vIsValidLPN               TFlags,
          @vAllowMultipleSKUs        TFlag,
          @vRulesDataXML             TXML,
          @vFormAction               TAction;

  declare @ttResultData              TNameValuePairs,
          @ttLocations               TRecountKeysTable,
          @ttLPNsToBeMoved           TInventoryTransfer,
          @ttEntitiesToPrint         TEntitiesToPrint,
          @ttLPNs                    TEntityKeysTable,
          @ttLPNsToPreprocess        TEntityKeysTable;
begin /* pr_AMF_Inventory_BuildInventoryLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Create temp tables */
  select * into #ResultData        from @ttResultData;
  select * into #CreateLPNs        from @ttLPNs;
  select * into #EntitiesToPrint   from @ttEntitiesToPrint;
  select * into #LPNsToPreprocess  from @ttLPNsToPreprocess;
  select * into #LPNsToBeMoved     from @ttLPNsToBeMoved;
  alter table #LPNsToBeMoved drop column InventoryKey, NewInventoryKey;
  alter table #LPNsToBeMoved add InventoryKey      as concat_ws('-', SKUId, Ownership, Warehouse, Lot, InventoryClass1, InventoryClass2, InventoryClass3),
                                 NewInventoryKey   as concat_ws('-', coalesce(NewSKUId, SKUId), coalesce(NewOwnership, Ownership),
                                                                     coalesce(NewWarehouse, Warehouse), coalesce(NewLot, Lot),
                                                                     coalesce(NewInventoryClass1, InventoryClass1),
                                                                     coalesce(NewInventoryClass2, InventoryClass2),
                                                                     coalesce(NewInventoryClass3, InventoryClass3));
  /* Read the values from input */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',       'TBusinessUnit'  ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',           'TDeviceId'      ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',           'TUserId'        ),
         @vSKUId           = Record.Col.value('(Data/m_SKUInfo_SKUId)[1]',           'TRecordId'      ),
         @vSKU             = Record.Col.value('(Data/m_SKUInfo_SKU)[1]',             'TSKU'           ),
         @LPN              = nullif(Record.Col.value('(Data/LPN)[1]',                'TLPN'     ), '' ),
         @Pallet           = nullif(Record.Col.value('(Data/Pallet)[1]',             'TPallet'  ), '' ),
         @Location         = nullif(Record.Col.value('(Data/Location)[1]',           'TLocation'), '' ),
         @vNumLPNs         = nullif(Record.Col.value('(Data/NumLPNs)[1]',            'TInteger' ), '' ),
         @vInnerPacks      = nullif(Record.Col.value('(Data/NewInnerPacks)[1]',      'TQuantity'), '' ),
         @vUnits           = nullif(Record.Col.value('(Data/NewUnits)[1]',           'TQuantity'), '' ),
         @vUnits1          = nullif(Record.Col.value('(Data/NewUnits1)[1]',          'TQuantity'), '' ),
         @vInventoryClass1 = coalesce(Record.Col.value('(Data/InventoryClass1)[1]',  'TInventoryClass'), ''),
         @vInventoryClass2 = coalesce(Record.Col.value('(Data/InventoryClass2)[1]',  'TInventoryClass'), ''),
         @vInventoryClass3 = coalesce(Record.Col.value('(Data/InventoryClass3)[1]',  'TInventoryClass'), ''),
         @vReasonCode      = Record.Col.value('(Data/ReasonCode)[1]',                'TReasonCode'    ),
         @vOwnership       = Record.Col.value('(Data/Owner)[1]',                     'TOwnership'     ),
         @vWarehouse       = Record.Col.value('(Data/Warehouse)[1]',                 'TWarehouse'     ),
         @vReference       = Record.Col.value('(Data/Reference)[1]',                 'TReference'     ),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',                 'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col);

  select @vDeviceName = @vDeviceId + '@' + @vUserId;
  select @vDefaultPrinter = DefaultPrinter from Devices where DeviceId = @vDeviceName;

  /* Select the quantity */
  select @vQuantity = coalesce(@vUnits, @vUnits1);

  /* Get LPN related info */
  if (@LPN is not null)
    select @vLPNId     = LPNId,
           @vLPN       = LPN,
           @vLPNSKUId  = SKUId,
           @vLPNStatus = Status,
           @vLPNType   = LPNType
    from LPNs
    where (LPNId = dbo.fn_LPNs_GetScannedLPN (@LPN, @vBusinessUnit, 'LTU'));

  /* Get Pallet related info */
  if (@Pallet is not null)
    select @vPalletId     = PalletId,
           @vPallet       = Pallet,
           @vPalletStatus = Status,
           @vPalletLocId  = LocationId
    from Pallets
    where (PalletId = dbo.fn_Pallets_GetPalletId (@Pallet, @vBusinessUnit));

  /* Get Location related info */
  if (@Location is not null)
    select @vLocationId   = LocationId,
           @vLocation     = Location,
           @vLocationType = LocationType
    from Locations
    where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, @vDeviceId, @vUserId, @vBusinessUnit));

  /* get the controls for multi SKU LPNs */
  select @vAllowMultipleSKUs = dbo.fn_Controls_GetAsBoolean('Inventory', 'AllowMultiSKULPNs', 'N' /* No */, @vBusinessUnit, @vUserId);

  /* Validations */
  if (@vSKUId is null)
    set @vMessageName = 'SKUIsRequired';
  else
  if (@vQuantity < 1)
    set @vMessageName = 'InvalidQuantity';
  else
  if (@vAllowMultipleSKUs = 'N') and (@vLPNSKUId <> @vSKUId)
    set @vMessageName = 'MultiSKULPNsNotAllowed';
  else
  if (@LPN is not null) and (@vLPNType not in ('C' /* Carton */))
    set @vMessageName = 'InvalidLPNType';
  else
  if (@vPallet is not null) and (@vPalletId is null)
    set @vMessageName = 'BuildInv_InvalidPallet';
  else
  if (@vLocation is not null) and (@vLocationId is null)
    set @vMessageName = 'BuildInv_InvalidLocation';
  else
  if (@vPalletLocId is not null) and (@vLocationId <> @vPalletLocId)
    set @vMessageName = 'BuildInv_PalletLocationMismatch';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Get controls */
  select @vAcceptExternalLPN = dbo.fn_Controls_GetAsBoolean(@vOperation, 'AcceptExternalLPN', 'N' /* No */,  @vBusinessUnit, @vUserId);

  /* If user scanned an LPN that is already present in the database */
  if (@vLPNId is not null)
    insert into #CreateLPNs (EntityId, EntityKey) select @vLPNId, @vLPN;

  /* If client accepts external LPN and user scanned an LPN, then generate with the sequence given by user */
  if (@vAcceptExternalLPN = 'Y') and (@LPN is not null) and (@vLPN is null)
    begin
      /* Build xml to evaluate Rules */
      select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('Ownership',       @vOwnership) +
                              dbo.fn_XMLNode('Warehouse',       @vWarehouse) +
                              dbo.fn_XMLNode('Operation',       'BuildInvLPN') +
                              dbo.fn_XMLNode('BusinessUnit',    @vBusinessUnit));

      /* check whether the scanned external LPN is valid or not */
      exec pr_LPNs_ValidateExternalLPN @vRulesDataXML, @LPN, @vBusinessUnit, @vUserId, @vIsValidLPN output;

      /* If user scanned an invalid external LPN then raise an error */
      if (@vIsValidLPN = 'N')
        set @vMessageName = 'BuildInv_InvalidExternalLPN';

      /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
      if (@vMessageName is not null)
        exec pr_Messages_ErrorHandler @vMessageName;

      /* Generate a new LPN if the value given for LPN is valid */
      exec @vReturnCode = pr_LPNs_Generate default /* @LPNType */,
                                           1       /* @NumLPNsToCreate */,
                                           @LPN    /* @LPNFormat - create the LPN as given */,
                                           @vWarehouse,
                                           @vBusinessUnit,
                                           @vUserId,
                                           @vLPNId    output,
                                           @vLPN      output;

      /* insert into hash table, so that we avoid creating LPN in createLPNs proc */
      insert into #CreateLPNs (EntityId, EntityKey) select @vLPNId, @vLPN;
    end

  /* Build the input for V2 procedure */
  select @vrfcProcInputxml = (select Record.Col.value('(Data/m_SKUInfo_SKUId)[1]',            'TRecordId'      ) as SKUId,
                                     Record.Col.value('(Data/SKU)[1]',                        'TSKU'           ) as NewSKU,
                                     @vLPN                                                                       as LPN,
                                     Record.Col.value('(Data/Pallet)[1]',                     'TPallet'        ) as Pallet,
                                     Record.Col.value('(Data/Location)[1]',                   'TLocation'      ) as Location,
                                     iif(@Pallet <> '', 'N', '')                                                 as GeneratePallet,
                                     Record.Col.value('(Data/NumLPNs)[1]',                    'TInteger'       ) as NumLPNsToCreate,
                                     Record.Col.value('(Data/NewInnerPacks)[1]',              'TInnerPacks'    ) as InnerPacksPerLPN,
                                     Record.Col.value('(Data/NewUnitsPerInnerPack)[1]',       'TInteger'       ) as UnitsPerInnerPack,
                                     @vQuantity                                                                  as UnitsPerLPN,
                                     Record.Col.value('(Data/Owner)[1]',                      'TOwnership'     ) as Owner,
                                     Record.Col.value('(Data/Warehouse)[1]',                  'TWarehouse'     ) as Warehouse,
                                     Record.Col.value('(Data/ReasonCode)[1]',                 'TReasonCode'    ) as ReasonCode,
                                     Record.Col.value('(Data/Operation)[1]',                  'TOperation'     ) as Operation,
                                     Record.Col.value('(Data/LabelFormatToPrint)[1]',         'TName'          ) as LPNLabelFormat,
                                     @vDefaultPrinter                                                            as PrinterName,
                                     Record.Col.value('(Data/InventoryClass1)[1]',            'TInventoryClass') as InventoryClass1,
                                     Record.Col.value('(Data/InventoryClass2)[1]',            'TInventoryClass') as InventoryClass2, -- Future use
                                     Record.Col.value('(Data/InventoryClass3)[1]',            'TInventoryClass') as InventoryClass3  -- Future use
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml path('Data'), root('Root'));

  select @vrfcSessionXML = (select Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ) as BusinessUnit,
                                   Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ) as DeviceId,
                                   Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ) as UserId
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml path('SessionInfo'));

  select @vrfcProcInputXML = dbo.fn_XmlAddNode(@vrfcProcInputxml, 'Root', @vrfcSessionXML);

  /* call the create LPNs proc to create inv and print the LPNs, if pallet is given
     then LPN is moved on to that pallet */
  exec pr_LPNs_CreateLPNs @vrfcProcInputXML, @vrfcProcOutputXML output;

  select @vxmlrfcProcOutput = convert(xml, @vrfcProcOutputXML);

  /* Fetch the First and LastLPNId, so that based on them we can move the LPNs to Location if provided */
  select top 1 @vFirstLPNId = EntityId from #CreateLPNs order by RecordId;

  /* If Location is given, make sure LPN is moved to that location along with the pallet if pallet is given */
  if (@vLocationId is not null)
    begin
      /* If Pallet is given and it is not already in the Location then move the Pallet
         into the Location */
      if (@vPalletId is not null) and (@vPalletLocId is null)
        exec pr_Pallets_SetLocation @vPalletId, @vLocationId, 'Y' /* Yes, update LPNs as well */, @vBusinessUnit, @vUserId;
      else
      /* If Pallet is not given, but Location has been given, move LPNs into the Location */
      if (@vPallet is null)
        begin
          /* Get all the created LPNs */
          insert into #LPNsToBeMoved (LPNId, LPN, LocationId, Location, ProcessFlag)
            select EntityId, EntityKey, @vLocationId, @vLocation, 'N' /* No */
            from #CreateLPNs;

          /* Invoke procedure that move all the LPNs to New location */
          exec pr_LPNs_BulkMove default /* Operation */, @vBusinessUnit, @vUserId;
        end

      /*------------- Recalc Locations  -------------*/
      insert into @ttLocations (EntityId, EntityKey) select @vLocationId, @vLocation;
      exec pr_Locations_Recalculate @ttLocations, '*' /* Recount */, @vBusinessUnit;
    end

  insert into #LPNsToPreprocess (EntityId, EntityKey)
    select EntityId, EntityKey from #CreateLPNs;

  /* Pre-process the newly created LPN to establish Putaway and Picking Class */
  exec pr_LPNs_PreProcess null, @vBusinessUnit, @vUserId;

  /* 'ListLink_LPNsCreatedSuccessfully' is inserted from pr_LPNs_Generate, which is UI exclusive message and we are generating LPNs and building success message from pr_LPNs_Generate,
      but as per RF functionality we don't have necessity to use Listlink message which is generating from pr_LPNs_Generate so deleting the success linklist  message and displaying only the success message  */
  if object_id('tempdb..#ResultMessages') is not null
    delete from #ResultMessages; --where MessageName  = 'ListLink_LPNsCreatedSuccessfully';

  /* Get the success message, AT to be shown to user as success message */
  select top 1 @vMessage = Comment
  from vwATEntity
  where (EntityType = 'LPN') and (EntityId = @vFirstLPNId)
  order by AuditId desc;

  /* When user given valid LPN or created using LPNsGenerate */
  if (@vLPNId is not null)
    begin
      /* Fetch the ReasonCode descriptions */
      select @vReasonCodeDescription = dbo.fn_LookUps_GetDesc('RC_LPNCreateInv', @vReasonCode, @vBusinessUnit, default);

      select @vMessage = dbo.fn_Messages_Build('AMF_BuildInvLPN_Successful', @vLPN, @vSKU, @vQuantity, @vReasonCodeDescription, null);
    end

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', dbo.fn_XMLNode('Resolution', 'Done') +
                                           dbo.fn_XMLNode('Pallet', coalesce(@vPallet, '')) +
                                           dbo.fn_XMLNode('Location', coalesce(@vLocation, '')));

end /* pr_AMF_Inventory_BuildInventoryLPN */

Go
