/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  VS      pr_AMF_Inventory_ManagePicklane_ManageSKU: Passed Logical LPNId to remove exact SKU+InventoryClass1 (HA-2877)
  2021/01/17  TK      pr_AMF_Inventory_ManagePicklane_ManageSKU: InventoryClass should be empty if nothing passed in (BK-108)
  2020/06/09  RIA     pr_AMF_Inventory_ManagePicklane_ManageSKU: Changes to consider SKUId instead of SKU
  2020/01/26  RIA     Renamed pr_AMF_Inventory_MP_ValidateSelectedOptions to pr_AMF_Inventory_ManagePicklane_ManageSKU (CIMSV3-655)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ManagePicklane_ManageSKU') is not null
  drop Procedure pr_AMF_Inventory_ManagePicklane_ManageSKU;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ManagePicklane_ManageSKU: This proc is invoked when
    user submits the form after scanning a valid picklane. Here SKU is assigned or
    removed from a location based on the option selected by user after which
    user navigates to SetupPicklane/AddInventory based on the combinations
    available and selected.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ManagePicklane_ManageSKU
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vConfirmAddSKU            TFlags,
          @vConfirmRemoveSKU         TFlags,
          @vConfirmSetupPicklane     TFlags,
          @vConfirmAddInventory      TFlags,
          @vInventoryClass1          TInventoryClass,
          @vInventoryClass2          TInventoryClass,
          @vInventoryClass3          TInventoryClass,
          @vInventoryClasses         TInventoryClass,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vUoMsXML                  TXML,
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vLPNId                    TRecordId,
          @vSKUDescription           TDescription,
          @vSKUQty                   TQuantity,
          @vSKUStatus                TStatus,
          @vLogicalLPNId             TRecordId,
          @vStorageType              TStorageType,
          @vLocationSubType          TLocationType,
          @vDefaultUoM               TUoM,
          @vQuantity                 TQuantity,
          @vInnerPacks               TInnerPacks,
          @vMessage                  TMessage,
          @vNewSKUAdded              TFlags,
          @vReasonCodesXML           TXML,
          @vDisplayOptions           TXML,
          @vAdditionalInfoXml        TXML,
          @vxmlLocationDetails       xml,
          @vxmlLocSKUInventory       xml,
          @vLocSKUInventorysXML      TXML,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML;
begin /* pr_AMF_Inventory_ManagePicklane_ManageSKU */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML            = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML          = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML           = null,
         @InfoXML            = null,
         @vUoMsXML           = '',
         @vAdditionalInfoXml = '',
         @vNewSKUAdded       = 'N'; -- set when New SKU is added to dynamic picklanes

  /*  Read inputs from InputXML */
  select @vBusinessUnit         = Record.Col.value('(SessionInfo/BusinessUnit)[1]',             'TBusinessUnit'  ),
         @vUserId               = Record.Col.value('(SessionInfo/UserName)[1]',                 'TUserId'        ),
         @vDeviceId             = Record.Col.value('(SessionInfo/DeviceId)[1]',                 'TDeviceId'      ),
         @vLocationId           = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',       'TRecordId'      ),
         @vLocation             = Record.Col.value('(Data/m_LocationInfo_Location)[1]',         'TLocation'      ),
         @vLPNId                = Record.Col.value('(Data/LPNId)[1]',                           'TRecordId'      ),
         @vSKU                  = Record.Col.value('(Data/SKU)[1]',                             'TSKU'           ),
         @vStorageType          = Record.Col.value('(Data/m_LocationInfo_StorageType)[1]',      'TStorageType'   ),
         @vLocationSubType      = Record.Col.value('(Data/m_LocationInfo_LocationSubType)[1]',  'TStorageType'   ),
         @vConfirmAddSKU        = Record.Col.value('(Data/ConfirmAddSKU)[1]',                   'TFlags'         ),
         @vConfirmRemoveSKU     = Record.Col.value('(Data/ConfirmRemoveSKU)[1]',                'TFlags'         ),
         @vConfirmSetupPicklane = Record.Col.value('(Data/ConfirmSetupPicklane)[1]',            'TFlags'         ),
         @vConfirmAddInventory  = Record.Col.value('(Data/ConfirmAddInventory)[1]',             'TFlags'         ),
         @vInventoryClass1      = coalesce(Record.Col.value('(Data/InventoryClass1)[1]',        'TInventoryClass'), ''),
         @vInventoryClass2      = coalesce(Record.Col.value('(Data/InventoryClass2)[1]',        'TInventoryClass'), ''),
         @vInventoryClass3      = coalesce(Record.Col.value('(Data/InventoryClass3)[1]',        'TInventoryClass'), ''),
         @vInventoryClasses     = Record.Col.value('(Data/m_InventoryClasses)[1]',              'TInventoryClass'),
         @vOperation            = Record.Col.value('(Data/Operation)[1]',                       'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Update CurrentPickingResponse as CurrResponse might be updated in V2, so
     don't want to over write that */
  update Devices
  set CurrentPickingResponse  = @DataXML
  where (DeviceId = @vDeviceId + '@' + @vUserId);

  /* Get the top SKU */
  select top 1 @vSKUId           = SKUId,
               @vSKU             = SKU,
               @vSKUDescription  = Description,
               @vSKUStatus       = Status
  from dbo.fn_SKUs_GetScannedSKUs (@vSKU, @vBusinessUnit);

  /* Get quantity of scanned SKU to default on screen when user is adding inventory */
  select @vLogicalLPNId = LPNId,
         @vSKUQty       = Quantity
  from LPNs
  where (LocationId = @vLocationId) and (LPNType = 'L') and (SKUId = @vSKUId);

  /* Validate SKU except when user is doing only ConfirmSetupPicklane */
  if (@vSKUId is null) and ((@vConfirmAddSKU = 'Y') or (@vConfirmRemoveSKU = 'Y') or (@vConfirmAddInventory = 'Y'))
    set @vMessageName = 'SKUIsInvalid';
  else
  /* If adding inventory then either SKU already in Loc or is being added now */
  if (@vConfirmAddInventory = 'Y') and (@vConfirmAddSKU <> 'Y') and (@vLogicalLPNId is null)
    set @vMessageName = 'AMF_SKUIsNotSetupForLocation';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Check for the option selected and call approprite V2 proc */
  if (@vConfirmRemoveSKU = 'Y')
    begin
      exec pr_RFC_RemoveSKUFromLocation @vLocationId, @vLocation,  @vLPNId, null /* SKUId */, @vSKU,
                                        @vInnerPacks, @vQuantity, null, 'RemoveSKUs' /* Operation */,
                                        @vBusinessUnit, @vUserId;

      /* Get the success message, AT to be shown to user as success message */
      select top 1 @vMessage = Comment
      from vwATEntity
      where (EntityType = 'Location') and (EntityId = @vLocationId)
      order by AuditId desc

      /* Build the success message */
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
    end
  else
  /* If adding SKU to a Static Picklane, we can add the SKU without the inventory and it is done now
     where as for Dynamic Piclane, it would be done later */
  if (@vConfirmAddSKU = 'Y') and (@vLocationSubType not in ('D' /* Dynamic */ ))
    begin
      exec pr_RFC_AddSKUToLocation @vLocationId, @vLocation, null /* SKUId */, @vSKU,
                                   @vInnerPacks, @vQuantity, null, @vOperation,
                                   @vInventoryClass1, @vInventoryClass2, @vInventoryClass3,
                                   @vBusinessUnit, @vUserId;

      /* Get the success message, AT to be shown to user as success message */
      select top 1 @vMessage = Comment
      from vwATEntity
      where (EntityType = 'Location') and (EntityId = @vLocationId)
      order by AuditId desc

      /* Build the success message */
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
    end

  /* Get Location Info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'LPNList', @vOperation, @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Call the proc to validate and get all possible options */
  exec pr_Inventory_ManagePicklane_GetValidOptions @vLocationId, @vBusinessUnit, @vDisplayOptions output;

  /* If user is choosing to Setup Picklane or Add Inventory, we need to send back
     UoM List and Default UoM, ReasonCodes and Inventory in the Location */
  if ((@vConfirmSetupPicklane = 'Y') or (@vConfirmAddInventory = 'Y'))
    begin
      /* Fetch the UoMs */
      exec pr_AMF_BuildLookUpList 'UoM' /* Look up Category */, 'UoM', 'select UoM', @vBusinessunit, @vUoMsXML output;

      /* Fetch the reason codes for add inventory */
      exec pr_AMF_BuildLookUpList 'RC_LPNCreateInv', 'ReasonCodes', 'select a reason', @vBusinessunit, @vReasonCodesXML output;

      /* If picklane is unitstorage type then default UoM to eaches */
      if (@vStorageType like 'U%' /* Units */)
        select @vDefaultUoM = 'EA';
      else
        /* User will be forced to select the UoM */
        select @vDefaultUoM = '1';

      if (@vConfirmAddInventory = 'Y')
        begin
          /* Get the SKUs in the Location, based on user scanned input */
          select @vxmlLocSKUInventory = (select top 30 LPN, SKU, dbo.fn_AppendStrings(SKUDescription, ' / ', InventoryClass1) SKUDescription, Quantity,
                                                SKU1, SKU2, SKU3, SKU4, SKU5,
                                                InventoryClass1, InventoryClass2, InventoryClass3,
                                                LPNId, SKUId, Pallet, UPC
                                         from vwLPNs
                                         where (LocationId = @vLocationId) and
                                               ((SKU like '%'+ @vSKU + '%') or ((UPC like '%'+ @vSKU + '%')))
                                         order by LPN, SKUSortOrder
                                         for Xml Raw('LPN'), elements XSINIL, Root('LOCLPNS'));

          select @vLocSKUInventorysXML = coalesce(convert(varchar(max), @vxmlLocSKUInventory), '');
        end

      /* We will be using this to consider this as new SKU for dynaic picklane */
      if (@vConfirmAddSKU = 'Y') and (@vLocationSubType in ('D' /* Dynamic */ ))
        select @vNewSKUAdded = 'Y';

      /* Build the Additional Info required. This will be a combinaton of the user
         selected options, inputs retrieved from previous forms if any and or info like
         qty or descriptions to show in the next form */
      select @vAdditionalInfoXml = dbo.fn_XMLNode('ConfirmSetupPicklane', @vConfirmSetupPicklane) +
                                   dbo.fn_XMLNode('ConfirmAddInventory', @vConfirmAddInventory) +
                                   dbo.fn_XMLNode('SKU', @vSKU) +
                                   dbo.fn_XMLNode('SKUDescription', @vSKUDescription) +
                                   dbo.fn_XMLNode('SKUQty', coalesce(@vSKUQty, 0)) +
                                   dbo.fn_XMLNode('DefaultUoM', @vDefaultUoM) +
                                   dbo.fn_XMLNode('NewSKUAddedForDynamicLoc', @vNewSKUAdded);
    end

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLocationInfoXML +
                                           coalesce(@vLocSKUInventorysXML, @vLocationDetailsXML, '') +
                                           @vDisplayOptions + coalesce(@vAdditionalInfoXml, '') +
                                           dbo.fn_XMLNode('InventoryClasses', @vInventoryClasses) +
                                           coalesce(@vUoMsXML, '') +
                                           coalesce(@vReasonCodesXML, ''));

end /* pr_AMF_Inventory_ManagePicklane_ManageSKU */

Go

