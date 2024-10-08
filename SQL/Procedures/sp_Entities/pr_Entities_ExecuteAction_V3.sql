/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2021/09/30  RV      pr_Entities_ExecuteAction_V3: Added action CreateReceiptInventory to create LPNs to receive (FBV3-265)
  2021/09/21  NB      pr_Entities_ExecuteAction_V3 modified to add pr_Users_ChangePassword caller(CIMSV3-1548)
  2021/06/17  KBB     pr_Entities_ExecuteAction_V3: pr_Loads_Update renamed as pr_Loads_Update_Obsolete (CIMSV3-1501)
  2020/12/23  KBB     pr_Entities_ExecuteAction_V3: Uncommented the Wave Related actions (HA-1825)
  2020/11/12  TK      pr_Entities_ExecuteAction_V3: Changed the Action name (CID-1569)
  2020/12/08  RKC     pr_Entities_ExecuteAction_V3: Convert Cancel task Actions to V2 terminology (HA-1755)
  2020/12/04  NB      pr_Entities_ExecuteAction_V3: changes to verify UIActionDetails.RunNowRecordLimit and add action request to
  2020/12/02  SK      pr_Entities_ExecuteAction_V3: Include Activity logging for success response and update for failed responses (HA-1717)
  2020/17/11  RKC     pr_Entities_ExecuteAction_V3: Passed the Operation parm to pr_Load_AddOrders (HA-1610)
  2020/10/14  AJM     pr_Entities_ExecuteAction_V3: Made changes to log Reallocatewave message apropriately (HA-1540)
  2020/10/08  TK      pr_Entities_ExecuteAction_V3: Changes to Load_RemoveOrder Proc signature (HA-1520)
  2020/09/16  MS      pr_Entities_ExecuteAction_V3: Moved code for Generate Waves to pr_Waves_Action_GenerateWaves & Code cleanup (HA-1403)
  2020/09/12  TK      pr_Entities_ExecuteAction_V3: Invoke CreateLPNs proc to create kits (HA-1238)
  2020/09/01  AY      pr_Entities_ExecuteAction_V3: Removed references to CCTasks_CancelTasks (CIMSV3-549)
  2020/08/12  RKC     pr_Entities_ExecuteAction_V3: Added PasswordPolicy parameters to pr_Users_AddOrUpdate (S2G-1415)
  2020/07/11  TK      pr_Entities_ExecuteAction_V3: Underscore (_) represents a single character in like command so used charindex (HA-1031)
  2020/07/10  RKC     pr_Entities_ExecuteAction_V3: Added few fields for creating & modifying the load (HA-1106)
  2020/06/26  TK      pr_Entities_ExecuteAction_V3: Changes to invoke CreateLPNs for CreateInventory action (HA-830)
  2020/06/20  MS      pr_Entities_ExecuteAction_V3: Code cleanup, remove PrintJobs code (CIMSV3-984)
  2020/06/18  SV      pr_Entities_ExecuteAction_V3, pr_Entities_BuildSQLWhere: Changes to consider Grid filters applied from UI end (CIMSV3-909)
  2020/06/18  RV      pr_Entities_ExecuteAction_V3: Corrected the ShipToId field to get the value (HA-961)
  2020/06/17  VS      pr_Entities_ExecuteAction_V3: Reallocate action name corrected (HA-998)
              MS      pr_Entities_ExecuteAction_V3: PrinterName field Corrected (HA-853)
  2020/06/17  TK      pr_Entities_ExecuteAction_V3: Changes to generate replenish order for multiple locations (HA-985)
  2020/06/13  RV      pr_Entities_ExecuteAction_V3: Included Load Modify action (HA-908)
  2020/06/12  RKC     pr_Entities_ExecuteAction_V3: Added Action for  Confirm as Shipped (HA-897)
  2020/06/11  RV      pr_Entities_ExecuteAction_V3: Made changes to call proc to generate loads (CIMSV3-759)
              RV      pr_Entities_ExecuteAction_V3: Changes to insert messages and result data into #tables instead of building as xml (HA-840)
  2020/06/10  RV      pr_Entities_ExecuteAction_V3: enhanced to support Create load action in loads page (HA-839)
  2020/06/09  RV      pr_Entities_ExecuteAction_V3: Included Remove orders from load action (HA-839)
  2020/06/08  RT      pr_Entities_ExecuteAction_V3: Included Load_GenerateBoLs (HA-824)
              AY      pr_Entities_ExecuteAction_V3: Change to use ActionProcedureName
  2020/06/08  RKC     pr_Entities_ExecuteAction_V3: Added Load_Cancel action (HA-844)
  2020/05/21  SV      pr_Entities_ExecuteAction_V3: Changes to generate waves with the action GenerateWavesviaSelectedRules (HA-510)
  2020/05/18  RKC     pr_Entities_ExecuteAction_V3: Made changes to Print the LPN & Pallet Labels while generating the LPNs & Pallets (HA-445) & (HA-447)
  2020/05/02  AJM     pr_Entities_ExecuteAction_V3: Added AddLookup, EditLookup Actions (HA-91)
  2020/04/29  HYP     pr_Entities_ExecuteAction_V3: Added Inventoryclass1 to CreateInventory (CIMSV3-861)
  2020/04/29  RT      pr_Entities_ExecuteAction_V3: Changed the Action name (HA-287)
  2020/05/18  MS      pr_Entities_ExecuteAction_V3: Changes to AdjustLPNQty (HA-181)
  2020/04/13  TK      pr_Entities_ExecuteAction_V3: Changes to pass Reference for CreateInvLPNs (HA-UATSupport)
  2020/04/08  YJ      pr_Entities_ExecuteAction_V3: Changes to Edit Controls (CIMSV3-776)
  2020/04/07  VS      pr_Entities_ExecuteAction_V3:Added AddRole, EditRole and Delete Role Actions (HA-96)
              TK      pr_Entities_ExecuteAction_V3: Changes to modify RolePermissions (HA-69)
  2020/04/01  RV      pr_Entities_ExecuteAction_V3: Made changes to display messages in V3 (JL-155)
  2020/03/30  MS      pr_Entities_ExecuteAction_V3: Changes to add/edit users (CIMSV3-467)
  2020/03/23  RV      pr_Entities_ExecuteAction_V3: Made changes to extract the nodes for close receiver (JL-161)
  2020/03/18  RKC     pr_Entities_ExecuteAction_V3: Added Action for Cycle counts page (CIMSV3-549)
  2020/03/16  MS      pr_Entities_ExecuteAction_V3  Changes to Modify Orders (CIMSV3-424)
  2020/02/18  MS      pr_Entities_ExecuteAction_V3: Changes to Include ReceiptNumber for Actions in Receipts (JL-58)
  2020/02/13  RIA     pr_Entities_ExecuteAction_V3: Changes to node name and lookupcategory (CIMSV3-694)
  2020/02/02  RIA     pr_Entities_ExecuteAction_V3: Changes to get LookUpDescription (CIMSV3-694)
  2020/01/30  MS      pr_Entities_ExecuteAction_V3: Changes to build datanode for CancelAllRemainingQuantity action (CIMSV3-431)
  2020/01/26  RIA     pr_Entities_ExecuteAction_V3: Changes to get LookUpDescription (JL-43)
  2020/01/23  RT      pr_Entities_ExecuteAction_V3: Changes to Perform Actions in Receipts (JL-88)
  2020/01/02  RT      pr_Entities_ExecuteAction_V3: Changed the Action to Receivers_PrepareForReceiving (CIMSV3-474)
  2019/06/22  MS      pr_Entities_ExecuteAction_V3  Changes for OrderDetails actions (CIMSV3-423)
  2019/05/30  YJ      pr_Entities_ExecuteAction_V3: (CID-136)(Ported from Prod)
  2019/05/27  RIA     pr_Entities_ExecuteAction_V3: Changes for SKU Actions (CIMSV3-219)
  2019/05/26  RIA     pr_Entities_ExecuteAction_V3: Changes for CreateLocation, GeneratePallets and GenerateCarts (CIMSV3-452)
  2019/05/24  RKC     pr_Entities_ExecuteAction_V3: Made changes in OrderDetails actions (CIMSV3-423)
  2019/05/22  RKC     pr_Entities_ExecuteAction_V3: Added Action for Cycle counts page (CIMSV3-549)
  2019/05/08  RIA     pr_Entities_ExecuteAction_V3: Included GenerateCarts action and commented a debug line
  2019/05/07  RKC     pr_Entities_ExecuteAction_V3: Added Action for Pick Task page (CIMSV3-264)
  2019/05/06  MS/RKC  pr_Entities_ExecuteAction_V3: Added Action for Pick Task Details page (CIMSV3-216)
  2019/05/06  MS/RKC  pr_Entities_ExecuteAction_V3: Added Action for Orders page (CIMSV3-422)
  2019/05/05  MS      pr_Entities_ExecuteAction_V3: Added Actions for OrderDetails page (CIMSV3-423)
  2019/05/02  RKC     pr_Entities_ExecuteAction_V3: Added Action LPNs for QC for both Receivers and Receipts page(CIMSV3-472)
  2019/04/30  RKC     pr_Entities_ExecuteAction_V3: Added Action for  Confirm as Shipped (CIMSV3-498)
  2019/04/26  RIA     pr_Entities_ExecuteAction_V3 Changes for SKUs as values are not loaded from temp table
  2019/04/26  RT      pr_Entities_ExecuteAction_V3: Included Action for PrepareForReceiving (CIMSV3-415)
  2019/04/25  RIA     pr_Entities_ExecuteAction_V3: Included action for CreateLocation, GeneratePallets, GenerateLPNs
  2019/04/24  YJ      pr_Entities_ExecuteAction_V3: Added ReallocateBatch Wave Action (CIMSV3-442)
  2019/04/24  MS      pr_Entities_ExecuteAction_V3: Added Action for Orders page (CIMSV3-422)
  2019/04/20  VS      pr_Entities_ExecuteAction_V3: Added ReleaseForAllocation and ReleaseForPicking Wave Action (CIMSV3-416)
  2019/04/20  VS      pr_Entities_ExecuteAction_V3: Added Modify Wave Action (CIMSV3-444)
  2019/03/25  AY      pr_Entities_ExecuteAction_V3: Changed to create temp table always (CIMSV3-417)
  2018/07/26  NB      pr_Entities_ExecuteAction_V3: enhanced to process action CreateInventory(CIMSV3-299)
  2018/06/29  NB      pr_Entities_ExecuteAction_V3: enhanced to add new action GenerateWavesviaSelectedRules(CIMSV3-153)
                      pr_Entities_ExecuteAction, pr_Entities_ExecuteAction_V3: changed calling code for pr_Entities_GetSelectedEntities procedure (CIMSV3-152)
  2018/05/29  NB      pr_Entities_BuildSQLWhere: New procedure to build sql where condition for the selection filters and summary record filters
                        in the given input xml
                      pr_Entities_GetSelectedEntities: Enhanced to fetch selected entities using selection filters and summary record filters
                      pr_Entities_ExecuteAction, pr_Entities_ExecuteAction_V3: Modified caller to GetSelectedEntities procedure (CIMSV3-152)
  2018/02/20  NB      Modified pr_Entities_ExecuteAction_V3: Added code to handle AddOrdersToWave action(CIMSV3-153)
  2018/02/18  NB      Modified pr_Entities_ExecuteAction_V3: Added code to handle generate waves by rules action(CIMSV3-153)
  2018/02/16  NB      Modified pr_Entities_ExecuteAction_V3: Added code to handle generate waves by custom settings action(CIMSV3-153)
  2018/01/08  NB      Added pr_Entities_ExecuteAction_V3(CIMSV3-204)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_ExecuteAction_V3') is not null
  drop Procedure dbo.pr_Entities_ExecuteAction_V3;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_ExecuteAction_V3:
  Calling procedure for pr_Entities_ExecuteAction in V3
  This procedure handles the calls from V3 application or modules to pr_Entities_ExecuteAction
  pr_Entities_ExecuteAction is the V2 version of the procedure, which will stay as is,
  so that is can be used directly from V2 as now.
  pr_Entities_ExecuteAction_V3 will transform or translate the inputs to the procedure
  to the format which are V2 compatible and suitable for pr_Entities_ExecuteAction.

  Note: The procedure will be error out if the selected records count is greater than
        the MaxRecordsPerRun defined for that action
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_ExecuteAction_V3
  (@EntityXML     TXML,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @xmlResult     TXML           = null output)
as
  declare @vReturnCode                TInteger,
          @vMessage                   TMessage,
          @vActivityLogId             TRecordId,

          @vEntity                    TEntity,
          @xmlData                    xml,
          @vAction                    TAction,

          @vxmlSelectedEntities       xml,
          @vSelectedEntities          TXML,
          @vEntityCount               TCount,

          @vActionPermission          TName,
          @vActionProcedure           TName,
          @vMaxRecordsPerRun          TInteger,
          @vActionCaption             TName,
          @vActionRunNowRecordLimit   TInteger,

          @vAddOrdersToExistingWaves  TFlag,
          @vWaveNo                    TWaveNo,
          @vWavingLevel               TFlag,

          @vLPNType                   TTypeCode,
          @vLPNFormat                 TDescription,
          @vSKUId                     TRecordId,
          @vSKU                       TSKU,
          @vInnerPacks                TInnerPacks,
          @vQuantity                  TQuantity,
          @vUnitsPerCase              TQuantity,
          @vNumLPNs                   TCount,
          @vLot                       TLot,
          @vExpirydate                TDate,
          @vCoO                       TCoO,
          @vOwnership                 TOwnership,
          @vDestWarehouse             TWarehouse,
          @vReasonCode                TReasonCode,
          @vInventoryClass1           TInventoryClass,
          @vInventoryClass2           TInventoryClass,
          @vInventoryClass3           TInventoryClass,
          @vReference                 TReference,
          @vGeneratePallet            TFlag,
          @vCreatedDate               TDateTime,
          @vLPNDetailId               TRecordId,
          @vLPNId                     TRecordId,
          @vLPN                       TLPN,
          @vFirstLPNId                TRecordId,
          @vFirstLPN                  TLPN,
          @vLastLPNId                 TRecordId,
          @vLastLPN                   TLPN,
          @vPallet                    TPallet,
          @vNumLPNsCreated            TCount,
          @vFirstPalletId             TRecordId,
          @vFirstPallet               TPallet,
          @vLastPalletId              TRecordId,
          @vLastPallet                TPallet,
          @vNumPalletsCreated         TCount,
          @vAllowMultipleSKUs         TFlag,
          @vLocation                  TLocation,
          @vLocationType              TLocationType,
          @vLocationSubType           TLocationType,
          @vStorageType               TStorageType,
          @vLocationId                TrecordId,

          @vShipVia                   TShipVia,
          @vLoadType                  TTypeCode,
          @vRoutingStatus             TStatus,
          @vNumLoadsCreated           TCount,
          @vFirstLoadNumber           TLoadNumber,
          @vLastLoadNumber            TLoadNumber,
          @vLoadId                    TRecordId,
          @vLoadNumber                TLoadNumber,
          @vShipToId                  TShipToId,
          @vFromWarehouse             TWarehouse,
          @vShipFromId                TShipFrom,
          @vDeliveryDate              TDateTime,
          @vDockLocation              TLocation,
          @vStagingLocation           TLocation,
          @vLoadingMethod             TTypeCode,
          @vPalletized                TFlags,
          @vWeight                    TWeight,
          @vVolume                    TVolume,
          @vFreightCharges            TMoney,
          @vTransitDays               TCount,
          @vProNumber                 TProNumber,
          @vSealNumber                TSealNumber,
          @vTrailerNumber             TTrailerNumber,
          @vMasterTrackingNo          TTrackingNo,
          @vClientLoad                TLoadNumber,
          @vMasterBoL                 TBoLNumber,
          @vShippedDate               TDateTime,
          @vFoB                       TFlags,
          @vBoLCID                    TBoLCID,

          @vTotalOrdersToAddLoad      TCount,
          @vTotalOrdersAddedToLoad    TCount,
          @vDesiredShipDate           TDate,

          @vModifiedDate              TDateTime,
          @vCreatedBy                 TUserId,
          @vModifiedBy                TUserId,
          @vPalletType                TTypeCode,
          @vNumPallets                TCount,
          @vPalletFormat              TDescription,
          @vAssignToUserId            TUserId,

          @vUserId                    Integer,
          @vUserName                  varchar(50),
          @vPassword                  varchar(50),
          @vFirstName                 varchar(50),
          @vLastName                  varchar(50),
          @vEmail                     varchar(50),
          @vStatus                    TStatus,
          @vRoleId                    Integer,
          @vDefaultWarehouse          varchar(50),
          @vResult                    varchar(max),
          @vRecordId                  TRecordId,
          @vLabelFormatName           TName,
          @vPrinterName               TName,

          @vLookUpCategory            TCategory,
          @vLookUpCode                TLookUpCode,
          @vLookUpDescription         TDescription,
          @vSortSeq                   TSortSeq,
          @vLocationsInfo             TXML,
          @vLocationsInfoXML          xml,
          @vSelectedEntitiesXML       TXML;

  declare @ttSelectedEntities       TEntityValuesTable,
          @ttOrders                 TEntityValuesTable,
          @ttSelectedEntityKeys     TEntityKeysTable,
          @ttResultMessages         TResultMessagesTable,
          @ttResultData             TNameValuePairs,
          @ttEntitiesToPrint        TEntitiesToPrint;

begin /* pr_Entities_ExecuteAction_V3 */
begin try
  /* Initialize */
  select @vReturnCode = 0;

  /* Extracting data elements from XML. */
  set @xmlData = convert(xml, @EntityXML);

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Log the input */
  exec pr_ActivityLog_AddMessage @vAction, null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 @vMessage, @@ProcId, @EntityXML, @BusinessUnit, @UserId,
                                 @ActivityLogId = @vActivityLogId output;

  /* Create temp tables */
  select * into #ttSelectedEntities from @ttSelectedEntities;
  select * into #ResultMessages     from @ttResultMessages;      -- to hold the results of the action
  select * into #ResultData         from @ttResultData;          -- to hold the data to be returned to UI
  select * into #EntitiesToPrint    from @ttEntitiesToPrint;

  /* This procedure inserts the records into #ttSelectedEntities temp table */
  exec pr_Entities_GetSelectedEntities @vEntity, @xmlData, @BusinessUnit, @UserId;

  select @vEntityCount = count(*) from #ttSelectedEntities;

  select @vActionProcedure         = ActionProcedureName,
         @vMaxRecordsPerRun        = MaxRecordsPerRun,
         @vActionCaption           = Caption,
         @vActionRunNowRecordLimit = coalesce(RunNowRecordLimit, 0)
  from UIActionDetails
  where (ActionId = @vAction) and (BusinessUnit = @BusinessUnit);

  /* We need to error out if the selected record count by the user is greater than the MaxRecordsPerRun defined for that action. */
  if (@vEntityCount > @vMaxRecordsPerRun) raiserror('Selected record(s) count exceeds the threshold limit', 16, 1);

  /* Verify if the Action is set with a Max Limit to process a finite number records in realtime
     If so, if the EntityCount exceeds the set Limit, insert the request into BackgroundProcesses to be processed by Jobs */
  if  (@vActionRunNowRecordLimit > 0) and (@vEntityCount > coalesce(@vActionRunNowRecordLimit, 0))
    begin
      /* Respond to use with a message mentioning the request is saved and will be executed in background */
      insert into #ResultMessages (MessageType, MessageName, Value1) select 'I' /* Info */, 'UIAction_ExecuteInBackGround', @vActionCaption;

      /* Insert details in BackgroundProcesses Table */
      insert into BackgroundProcesses(EntityType, ProcessClass, Operation, ExecProcedureName, InputParams, RequestedBy, BusinessUnit)
        select @vEntity, 'UIAction', @vAction, @vActionProcedure, @EntityXML, @UserId, @BusinessUnit;

      /* return to response to caller */
      goto EndProc;
    end

  /* If action procedure is defined in UI Action details, use it. If procedure name starts with _
     then let the procedure handle the transactions */
  if (@vActionProcedure is not null) and (charindex('_', @vActionProcedure) <> 1)
    begin
      begin transaction
      exec @vActionProcedure @xmlData, @BusinessUnit, @UserId;
      commit;
    end
  else
  if (@vActionProcedure is not null)
    begin
      /* Transactions handled within the procedure */
      select @vActionProcedure = substring(@vActionProcedure, 2, len(@vActionProcedure));
      exec @vActionProcedure @xmlData, @BusinessUnit, @UserId;
    end
  else
  if (@vEntity = 'OrderDetails')
    begin
      /* V2 expects different tags */
      select @EntityXML = dbo.fn_XMLRenameTag(@EntityXML,'UnitsToAllocate','ToCancel')
      select @EntityXML = dbo.fn_XMLRenameTag(@EntityXML,'UnitsOrdered','ToOrdered')
      select @EntityXML = dbo.fn_XMLRenameTag(@EntityXML,'UnitsAuthorizedToShip','ToShip')

      select @xmlData = cast(@EntityXML as xml);

      exec @vReturnCode = pr_OrderDetails_Modify @xmlData, @BusinessUnit, @UserId, @xmlResult output;
    end
  else
  if (@vAction = 'AddOrdersToWave')
    begin
      select @vxmlSelectedEntities = (select EntityId as OrderId
                                      from #ttSelectedEntities
                                      order by EntityId
                                      FOR XML RAW('OrderHeader'), TYPE, ELEMENTS, ROOT('Orders'));

      if (@vxmlSelectedEntities is not null) select @vSelectedEntities = convert(varchar(max), @vxmlSelectedEntities);

      select @vWaveNo      = Record.Col.value('PickBatchNo[1]',   'TPickBatchNo'),
             @vWavingLevel = Record.Col.value('BatchingLevel[1]', 'TFlag')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      exec pr_PickBatch_AddOrders @vWaveNo, @vSelectedEntities, @vWavingLevel,
                                  @BusinessUnit, @UserId,
                                  @vMessage out;
    end
  else
  if (@vAction in ('CreateLoad', 'Loads_CreateLoad', 'Loads_Modify', 'ManageLoads_CreateLoad'))
    begin
      select @vLoadNumber       = Record.Col.value('LoadNumber[1]',            'TLoadNumber'),
             @vLoadType         = Record.Col.value('LoadType[1]',              'TTypeCode'),
             @vRoutingStatus    = Record.Col.value('RoutingStatus[1]',         'TStatus'),
             @vFromWarehouse    = Record.Col.value('FromWarehouse[1]',         'TWarehouse'),
             @vShipFromId       = Record.Col.value('ShipFrom[1]',              'TShipFrom'),
             @vShipToId         = Record.Col.value('ConsolidatorAddressId[1]', 'TContactRefId'),
             @vShipVia          = Record.Col.value('ShipVia[1]',               'TShipVia'),
             @vDesiredShipDate  = Record.Col.value('DesiredShipDate[1]',       'TDate'),
             @vDeliveryDate     = Record.Col.value('DeliveryDate[1]',          'TDateTime'),
             @vDockLocation     = Record.Col.value('DockLocation[1]',          'TLocation'),
             @vStagingLocation  = Record.Col.value('StagingLocation[1]',       'TLocation'),
             @vPalletized       = Record.Col.value('Palletized[1]',            'TFlags'),
             @vLoadingMethod    = Record.Col.value('LoadingMethod[1]',         'TTypeCode'),
             @vWeight           = Record.Col.value('Weight[1]',                'TWeight'),
             @vVolume           = Record.Col.value('Volume[1]',                'TVolume'),
             @vFreightCharges   = Record.Col.value('FreightCharges[1]',        'TMoney'),
             @vTransitDays      = Record.Col.value('TransitDays[1]',           'TCount'),
             @vProNumber        = Record.Col.value('PRONumber[1]',             'TProNumber'),
             @vSealNumber       = Record.Col.value('SealNumber[1]',            'TSealNumber'),
             @vTrailerNumber    = Record.Col.value('TrailerNumber[1]',         'TTrailerNumber'),
             @vMasterTrackingNo = Record.Col.value('MasterTrackingNo[1]',      'TTrackingNo'),
             @vClientLoad       = Record.Col.value('ClientLoad[1]',            'TLoadNumber'),
             @vMasterBoL        = Record.Col.value('MasterBoL[1]',             'TBoLNumber'),
             @vShippedDate      = Record.Col.value('ShippedDate[1]',           'TDateTime'),
             @vFoB              = Record.Col.value('FoB[1]',                   'TFlags'),
             @vBoLCID           = Record.Col.value('BoLCID[1]',                'TBoLCID')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      if (@vAction in ('CreateLoad', 'Loads_CreateLoad', 'ManageLoads_CreateLoad'))
        exec pr_Load_CreateNew @UserId = @UserId, @BusinessUnit = @BusinessUnit,
                               @LoadType = @vLoadType, @RoutingStatus = @vRoutingStatus, @ShipVia = @vShipVia, @DesiredShipDate = @vDesiredShipDate,
                               @StagingLocation = @vStagingLocation, @LoadingMethod = @vLoadingMethod, @Palletized = @vPalletized, @FromWarehouse = @vFromWarehouse,
                               @ShipFrom = @vShipFromId, @ShipToId = @vShipToId, @DockLocation = @vDockLocation,
                               @Weight = @vWeight, @Volume = @vVolume, @FreightCharges = @vFreightCharges, @TransitDays = @vTransitDays,
                               @ProNumber = @vProNumber, @SealNumber = @vSealNumber, @TrailerNumber = @vTrailerNumber,
                               @MasterTrackingNo = @vMasterTrackingNo, @ClientLoad = @vClientLoad, @MasterBoL = @vMasterBoL, @FoB = @vFoB,
                               @LoadId = @vLoadId out, @LoadNumber = @vLoadNumber out, @Message = @vMessage out;
      -- else
      -- if (@vAction in ('Loads_Modify'))
      --   exec pr_Loads_Update_Obsolete @LoadId = @vLoadId, @LoadNumber = @vLoadNumber, @LoadType = @vLoadType, @Status = null, @FromWarehouse = @vFromWarehouse, @ShipFrom = @vShipFromId, @ShipToId = @vShipToId,
      --                       @DockLocation = @vDockLocation, @StagingLocation = @vStagingLocation, @LoadingMethod = @vLoadingMethod, @Palletized = @vPalletized,
      --                       @RoutingStatus = @vRoutingStatus, @ShipVia = @vShipVia, @DesiredShipDate = @vDesiredShipDate,
      --                       @ShippedDate = @vShippedDate, @Priority = null, @TrailerNumber = @vTrailerNumber, @SealNumber = @vSealNumber,
      --                       @ProNumber = @vProNumber, @MasterTrackingNo = @vMasterTrackingNo, @DeliveryDate = @vDeliveryDate,
      --                       @TransitDays = @vTransitDays, @Volume = @vVolume, @Weight = @vWeight, @FreightCharges = @vFreightCharges,
      --                       @ClientLoad = @vClientLoad, @MasterBoL = @vMasterBoL, @FoB = @vFoB, @BoLCID = @vBoLCID, @BusinessUnit = @BusinessUnit, @UserId = @UserId;

    end
  else
  if (@vAction = 'GenerateLoad')
    begin
      exec pr_Load_Generate @vSelectedEntities, @BusinessUnit, @UserId, @vNumLoadsCreated out, @vFirstLoadNumber out, @vLastLoadNumber out, @vMessage out;
    end
  else
  if (@vAction = 'AddOrdersToLoad')
    begin
      select @vLoadNumber  = Record.Col.value('LoadNumber[1]',   'TLoadNumber')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      /* pr_Load_AddOrders v2 Procedure expects table var with EntityKey values
         TODO pr_Load_AddOrders should be enhanced in future to read #ttSelectedEntityKeys without the need to pass in table var */
      insert into @ttSelectedEntityKeys (EntityId, EntityKey)
        select EntityId, EntityKey from #ttSelectedEntities;

      exec pr_Load_AddOrders @vLoadNumber, @ttSelectedEntityKeys, @BusinessUnit, @UserId, 'N', 'UI_Loads_AddOrders', @vTotalOrdersToAddLoad output, @vTotalOrdersAddedToLoad output, @vMessage output;
    end
  else
  if (@vAction = 'RemoveOrdersFromLoad')
    begin
      select @vLoadNumber  = Record.Col.value('LoadNumber[1]',   'TLoadNumber')
      from @xmlData.nodes('/Root/Data') as Record(Col);

      insert into @ttOrders(EntityType, EntityId, RecordId)
        select EntityType, EntityId, RecordId
        from #ttSelectedEntities;

      exec pr_Load_RemoveOrders @vLoadNumber, @ttOrders, 'Y', 'Load_RemoveOrder', @BusinessUnit, @UserId;
    end
  else
  if (@vAction in ('CreateInventory', 'Orders_CreateKits'))
    begin
      exec pr_LPNs_CreateLPNs @EntityXML, @xmlResult out;
    end
  else
  if (@vAction in ('Receipts_CreateLPNsToReceive', 'CreateReceiptInventory'))
    begin
      exec pr_Receivers_CreateReceiptInventory @EntityXML, @xmlResult out;
    end
  else
  if (@vAction = 'CreateLocation')
    begin
      select @vAllowMultipleSKUs = Record.Col.value('AllowMultipleSKUs[1]',  'TFlag'),
             @vLocation          = Record.Col.value('Location[1]',           'TLocation'),
             @vDestWarehouse     = Record.Col.value('Warehouse[1]',          'TWarehouse'),
             @vLocationSubType   = Record.Col.value('LocationSubType[1]',    'TLocationType'),
             @vLocationType      = Record.Col.value('LocationType[1]',       'TLocationType'),
             @vStorageType       = Record.Col.value('StorageType[1]',        'TStorageType')
      from @xmlData.nodes('/Root/Data') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlData = null ));

      exec pr_Locations_AddOrUpdate @vLocation, @vLocationType, @vLocationSubType, @vStorageType, null, null,
                                    null, 0, 0, null, null, null,
                                    null, null, @vAllowMultipleSKUs,
                                    @BusinessUnit, @vDestWarehouse, @UserId,
                                    @vLocationId output, @vCreatedDate output, @vModifiedDate output,
                                    @vCreatedBy output, @vModifiedBy output;

       select @xmlResult = 'Location Created Successfully';

    end
  else
  if (@vAction = 'GenerateLPNs')
    begin
      select @vLPNFormat       = Record.Col.value('LPNFormat[1]',        'TControlValue'),
             @vLPNType         = Record.Col.value('LPNType[1]',          'TTypeCode'),
             @vNumLPNs         = Record.Col.value('NumLPNs[1]',          'TCount'),
             @vDestWarehouse   = Record.Col.value('Warehouse[1]',        'TWarehouse'),
             @vLabelFormatName = Record.Col.value('LabelFormatName[1]',  'TName'),
             @vPrinterName     = Record.Col.value('LabelPrinterName[1]', 'TName')
      from @xmlData.nodes('/Root/Data') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlData = null ));

      /* We will get LPN code and based on that get the lookup description as V2 expects description */
      select @vLPNFormat = LookUpDescription
      from vwLookUps
      where (LookUpCategory = 'LPNFormat') and
            (LookUpCode = @vLPNFormat);

      exec pr_LPNs_Generate @vLPNType, @vNumLPNs, @vLPNFormat, @vDestWarehouse, @BusinessUnit, @UserId,
                            @vFirstLPNId output, @vFirstLPN output,
                            @vLastLPNId  output, @vLastLPN output,
                            @vNumLPNsCreated output, @vMessage output;

      select @xmlResult = @vMessage;

      /* Here we will get the Labels for generated LPNs. If LabelFormat Name & PrinterName
         are given then print the Labels for generated LPNs. */
      if (@vLabelFormatName is not null) and (@vPrinterName is not null)
        begin
          insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, DocumentFormat, LabelPrinterName)
            select 'LPN', LPNId, LPN, 'GenerateLPNs', @vLabelFormatName, @vPrinterName
            from LPNs
            where (LPN between @vFirstLPN and @vLastLPN) and
                  (BusinessUnit = @BusinessUnit);

          exec pr_Printing_EntityPrintRequest 'LPNs', 'GenerateLPNs', 'LPN', null /* EntityId */, null /* EntityKey */,
                                              @BusinessUnit, @UserId,
                                              @RequestMode = 'IMMEDIATE', @LabelPrinterName = @vPrinterName;
        end
    end
  else
  if (@vAction in ('GeneratePallets', 'GenerateCarts'))
    begin
      select @vLPNFormat        = Record.Col.value('CartPositionFormat[1]',  'TDescription'),
             @vLPNType          = Record.Col.value('LPNType[1]',             'TTypeCode'),
             @vNumPallets       = Record.Col.value('NumPallets[1]',          'TCount'),
             @vNumLPNs          = Record.Col.value('NumPositions[1]',        'TCount'),
             @vPalletFormat     = Record.Col.value('PalletFormat[1]',        'TDescription'),
             @vDestWarehouse    = Record.Col.value('WarehouseDesc[1]',       'TWarehouse'),
             @vPalletType       = Record.Col.value('PalletType[1]',          'TTypeCode'),
             @vLabelFormatName  = Record.Col.value('LabelFormatName[1]',     'TName'),
             @vPrinterName      = Record.Col.value('LabelPrinterName[1]',    'TName')
      from @xmlData.nodes('/Root/Data') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlData = null ));

      /* We will get LPN code and based on that get the lookup description as V2 expects description */
      select @vLPNFormat = LookUpDescription
      from vwLookUps
      where (LookUpCategory = 'PalletLPNFormat') and
            (LookUpCode = @vLPNFormat);

      /* We will get Pallet code and based on that get the lookup description as V2 expects description */
      select @vPalletFormat = LookUpDescription
      from vwLookUps
      where (LookUpCategory in ('PalletFormat_I', 'PalletFormat_C')) and
            (LookUpCode = @vPalletFormat);

      /* Call the V2 proc */
      exec pr_Pallets_GeneratePalletLPNs @vPalletType, @vNumPallets, @vPalletFormat, @vNumLPNs, @vLPNType,
                                         @vLPNFormat, @vDestWarehouse, @BusinessUnit, @UserId,
                                         @vFirstPalletId output, @vFirstPallet output,
                                         @vLastPalletId  output, @vLastPallet  output,
                                         @vNumPalletsCreated output, @vMessage    output;

      select @xmlResult = @vMessage;

      /* Here we will get the Labels for generated Pallets. If LabelFormat Name & PrinterName
         are given then print the Labels for generated Pallets */
      if (@vLabelFormatName is not null) and (@vPrinterName is not null)
        begin
          insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, DocumentFormat, LabelPrinterName)
            select 'Pallet', PalletId, Pallet, 'GeneratePallets', @vLabelFormatName, @vPrinterName
            from Pallets
            where (Pallet between @vFirstPallet and @vLastPallet) and
                  (BusinessUnit = @BusinessUnit);

          exec pr_Printing_EntityPrintRequest 'Pallets', 'GeneratePallets', 'Pallet', null /* EntityId */, null /* EntityKey */,
                                              @BusinessUnit, @UserId,
                                              @RequestMode = 'IMMEDIATE', @LabelPrinterName = @vPrinterName;
        end
    end
  else
  if (@vEntity = 'Roles') and (@vAction in ('Role_Add', 'Role_Edit', 'Role_Delete'))
    begin
      /* Invoke proc to Add/Edit/Delete Role */
      exec @vReturnCode = pr_Access_AddorUpdateRole @EntityXML;

      if (@vReturnCode = 0) goto EndProc;
    end
  else
  if (@vEntity = 'ReplenishmentLocations') and (@vAction = 'MinMaxReplenish')
    begin
      /* User may select multiple records, so build xml with selected Locations info */
      select @vLocationsInfoXML = (select LocationId, Location, StorageType, ReplenishUoM, Warehouse, Ownership,
                                          SKUId, SKU, InventoryClass1, InventoryClass2, InventoryClass3, MaxUnitsToReplenish as QtyToReplenish
                                   from #ttSelectedEntities SE
                                     join vwLocationsToReplenish LTR on (SE.EntityKey = LTR.UniqueId)
                                   FOR XML RAW('LOCATIONSINFO'), TYPE, ELEMENTS XSINIL);

      select @vLocationsInfo = cast(@vLocationsInfoXML as varchar(max));

      /* Add Locations info to xml and change root name to suit for pr_Replenish_GenerateOrders */
      select @EntityXML = dbo.fn_XMLAddNode(@EntityXML,   'Root', @vLocationsInfo);
      select @EntityXML = dbo.fn_XMLRenameTag(@EntityXML, 'Root', 'GENERATEREPLENISHORDER');

      /* Call the V2 proc */
      exec pr_Replenish_GenerateOrders @EntityXML, @BusinessUnit, @UserId, @vMessage output, null, null;

      select @xmlResult = @vMessage;
    end
  else
  if (@vEntity = 'Controls') and (@vAction in ('Controls_Edit'))
    begin
      /* Invoke proc to Edit Controls */
      exec @vReturnCode = pr_Controls_Modify @EntityXML, @vAction, @BusinessUnit;
    end
  else
  if (@vEntity = 'LookUps') and (@vAction in ('LookUp_Add', 'LookUp_Edit'))
    begin
      select @vRecordId          = Record.Col.value('RecordId[1]',         'TRecordId'),
             @vLookUpCategory    = Record.Col.value('LookUpCategory[1]',   'TCategory'),
             @vLookUpCode        = Record.Col.value('LookUpCode[1]',       'TLookUpCode'),
             @vLookUpDescription = Record.Col.value('LookUpDescription[1]','TDescription'),
             @vSortSeq           = Record.Col.value('SortSeq[1]',          'TSortSeq')
      from @xmlData.nodes('/Root/Data') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlData = null ));

      /* Insert/update LookUps */
      exec pr_LookUps_AddOrUpdate @vLookUpCategory, @vLookUpCode, @vLookUpDescription, @vSortSeq, @vStatus, null, @BusinessUnit,
                                  @vRecordId, null /* Created Date */, null /* Modified Date */, @UserId, @UserId, @vMessage output;
    end
  else
    begin
      if (@vAction = 'Loads_GenerateBoLs')
        begin
          select @vSelectedEntitiesXML = cast((select LoadId as LoadId
                                               from Loads L
                                                 join #ttSelectedEntities TE on TE.EntityId = L.LoadId
                                               for xml path('LoadId'), elements, root('LoadIds')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
          select @EntityXML = dbo.fn_XMLStuffValue (@EntityXML, 'Action', 'GenerateBoLs');
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity = 'PicklaneLPNs') and (@vAction = 'RemoveZeroQtySKUs')
        begin
          select @vSelectedEntitiesXML = cast((select EntityId as LPNId
                                               from #ttSelectedEntities
                                               order by EntityId
                                               for xml path('LPNContent'), elements, root('LPNs')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity in ('PickTicket', 'OrderHeader')) --and (@vAction = 'ModifyPickTicket' or @vAction = 'ModifyShipDetails' or @vAction =  'CloseOrder' or @vAction =  'CancelPickTicket')
        begin
          select @vSelectedEntitiesXML = cast((select OH.PickTicket as PickTicket
                                               from OrderHeaders OH
                                                 join #ttSelectedEntities TE on TE.EntityId = OH.OrderId
                                               for xml path('Order'), elements, root('Orders')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity = 'Wave')-- and (@vAction = 'CancelBatch' or @vAction = 'ModifyPriority' or @vAction = 'CloseBatch' or @vAction = 'ReleaseForAllocation' or @vAction = 'ReleaseForPicking' or @vAction = 'ReallocateBatch')
        begin
          /* This is handled in PickBatch Modify now */
          -- select @vSelectedEntitiesXML = cast((select PB.BatchNo as BatchNo from PickBatches PB
          --                                        join #ttSelectedEntities TE on TE.EntityId = PB.RecordId
          --                                      for xml path('BatchNo'), elements, root('Batches')) as varchar(max));
          --
          -- select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);

          /* Convert to V2 terminology */
          if (@vAction = 'Waves_Reallocate')
            select @EntityXML = dbo.fn_XMLStuffValue (@EntityXML, 'Action', 'Waves_Reallocate');
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity = 'Receiver') and (@vAction = 'Receivers_PrepareForReceiving')
        begin
          select @vSelectedEntitiesXML = cast((select R.ReceiverNumber as ReceiverNo from Receivers R
                                                 join #ttSelectedEntities TE on TE.EntityKey = R.ReceiverNumber
                                               for xml path(''), elements, root('Data')) as varchar(max));

          select @EntityXML = replace(@EntityXML, @vAction, 'PrepareForReceiving');

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end
      else
      /* Map V3 selected records to V2 format */
      if (@vEntity = 'Receiver') and (@vAction = 'Receivers_SelectLPNsForQC')
        begin
          select @vSelectedEntitiesXML = cast((select R.ReceiverNumber as ReceiverNo  from Receivers R
                                                 join #ttSelectedEntities TE on TE.EntityId = R.ReceiverId
                                               for xml raw('ReceiverNo'), elements) as varchar(max));

          select @EntityXML = replace(@EntityXML, @vAction, 'SelectLPNsForQC');

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'Data', @vSelectedEntitiesXML);
        end
      else
      if (@vEntity = 'Receiver') and (@vAction = 'CloseReceiver')
        begin
          select @vSelectedEntitiesXML = cast((select R.ReceiverNumber as ReceiverNo  from Receivers R
                                                 join #ttSelectedEntities TE on (TE.EntityId = R.ReceiverId)
                                               for xml raw(''), elements, root('Data')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity in ('Receipt', 'ReceiptOrder'))
        begin
          /* EntityXML: replace the Action by removing the Entity prefixed to it */
          select @EntityXML = replace(@EntityXML, @vAction, substring(@vAction, charindex('_', @vAction) + 1, len(@vAction)));

          if (@vAction = 'Receipts_SelectLPNsForQC')
            begin
              select @vSelectedEntitiesXML = cast((select RH.ReceiptId as ReceiptId,
                                                          RH.ReceiptNumber as ReceiptNumber
                                                   from ReceiptHeaders RH
                                                     join #ttSelectedEntities TE on TE.EntityId = RH.ReceiptId
                                                   for xml raw('Receipts'), elements) as varchar(max));
            end
          else
            begin
              select @vSelectedEntitiesXML = cast((select RH.ReceiptId as ReceiptId,
                                                          RH.ReceiptNumber as ReceiptNumber
                                                   from ReceiptHeaders RH
                                                     join #ttSelectedEntities TE on TE.EntityId = RH.ReceiptId
                                                   for xml path(''), elements, root('Receipts')) as varchar(max));
            end

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

      /* Actions related to RolePermissions Entity */
      if (@vEntity = 'RolePermissions') and (@vAction in ('GrantPermission', 'RevokePermission'))
        begin
          /* Invoke proc to modify permissions */
          exec @vReturnCode = pr_Access_GrantOrRevokePermission @EntityXML, @vAction, @vMessage output;

          if (@vReturnCode = 0)
            goto EndProc;
        end

      if (@vEntity = 'LPN')
        begin
          select @vSelectedEntitiesXML = cast((select EntityId  as LPNId,
                                                      EntityKey as LPN
                                               from #ttSelectedEntities
                                               order by EntityId
                                               for xml raw('LPNContent'), elements, root('LPNs')) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
        end

      if ((@vEntity ='LPNDetails') and (@vAction = 'LPNDetail_AdjustQty'))
        begin
          select @vLPNId         = Record.Col.value('LPNId[1]',      'TRecordId'),
                 @vLPN           = Record.Col.value('LPN[1]',        'TLPN'),
                 @vReasonCode    = Record.Col.value('ReasonCode[1]', 'TReasonCode'),
                 @vReference     = Record.Col.value('Reference[1]',  'TReference'),
                 @vLPNDetailId   = Record.Col.value('LPNDetailId[1]','TRecordId'),
                 @vSKUId         = Record.Col.value('SKUId[1]',      'TRecordId'),
                 @vSKU           = Record.Col.value('SKU[1]',        'TSKU'),
                 @vInnerPacks    = Record.Col.value('InnerPacks[1]', 'TInnerpacks'),
                 @vQuantity      = Record.Col.value('Quantity[1]',   'TQuantity')
               from @xmlData.nodes('/Root/Data') as Record(Col);

          set @EntityXML = '<LPNAdjustmentDetails>' +
                            '<Header>' +
                              dbo.fn_XMLNode('LPNId',      @vLPNId) +
                              dbo.fn_XMLNode('LPN',        @vLPN) +
                              dbo.fn_XMLNode('ReasonCode', @vReasonCode) +
                              dbo.fn_XMLNode('RefNumber',  @vReference) +
                            '</Header>' +
                            '<Details>' +
                              '<Detail>' +
                                dbo.fn_XMLNode('LPNDetailId',   @vLPNDetailId) +
                                dbo.fn_XMLNode('SKUId',         @vSKUId) +
                                dbo.fn_XMLNode('SKU',           @vSKU) +
                                dbo.fn_XMLNode('NewInnerPacks', @vInnerPacks) +
                                dbo.fn_XMLNode('NewQuantity',   @vQuantity) +
                              '</Detail>' +
                            '</Details>' +
                           '</LPNAdjustmentDetails>';

          /* Call V2 proc */
          exec @vReturnCode = pr_LPNs_UI_AdjustLPN @EntityXML, @BusinessUnit, @UserId, @xmlresult output;

          if (@vReturnCode = 0)
            goto EndProc;
        end

      if (@vEntity in ('SKU', 'SKUs')) -- V2 & V3 have diff notation in this regard
        begin
          select @vSelectedEntitiesXML = cast((select EntityId  as SKUId,
                                                      EntityKey as SKU
                                               from #ttSelectedEntities
                                               order by EntityId
                                               for xml raw('SKUs'), elements) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);
          --select @EntityXML = dbo.fn_XMLStuffValue(@EntityXML, 'Action', '<Action>ModifySKU</Action>');
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity = 'TaskDetails') and (@vAction = 'TaskDetails_Cancel') /* CancelTaskDetail */
        begin
          select @vSelectedEntitiesXML = cast((select T.TaskDetailId as TaskDetailId from Taskdetails T
                                                 join #ttSelectedEntities TE on TE.EntityId = T.TaskDetailId
                                               for xml raw('TaskDetails'), elements) as varchar(max));
          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);

          /* V2 expects different tags */
          select @EntityXML = dbo.fn_XMLStuffValue(@EntityXML,'Entity','Tasks');
          select @EntityXML = dbo.fn_XMLStuffValue(@EntityXML,'Action','CancelTaskDetail');
        end

      /* Map V3 selected records to V2 format */
      if (@vEntity in ('PickTask', 'Task'))
        begin
          select @vSelectedEntitiesXML = cast((select EntityId as TaskId
                                               from #ttSelectedEntities
                                               order by EntityId
                                               for xml raw('Tasks'), elements) as varchar(max));

          select @EntityXML = dbo.fn_XMLReplaceNode(@EntityXML, 'SelectedRecords', @vSelectedEntitiesXML);

          /* This is only temporary in V3, UI should return the UserId itself as AssignToUser and so when
             we make the change, we can drop this code */
          set @xmlData = convert(xml, @EntityXML);
          select @vAssignToUserId = Record.Col.value('AssignUser[1]', 'varchar(50)')
                                    from @xmlData.nodes('/Root/Data') as Record(Col);
          select @vAssignToUserId = UserId from users where UserName=@vAssignToUserId

          select @EntityXML = dbo.fn_XMLStuffValue(@EntityXML,'AssignUser', @vAssignToUserId)

          /* Convert Actions to V2 terminology */
          select @EntityXML = case
                                when @vAction = 'Tasks_Cancel' then
                                  dbo.fn_XMLStuffValue (@EntityXML, 'Action', 'CancelTask')
                                else @EntityXML
                              end;

        end

      if (@vEntity = 'User') and (@vAction in ('NewUser', 'EditUser'))
        begin
          select @vUserId           = Record.Col.value('UserId[1]',           'Integer'),
                 @vUserName         = Record.Col.value('UserName[1]',         'varchar(50)'),
                 @vPassword         = Record.Col.value('Password[1]',         'varchar(50)'),
                 @vFirstName        = Record.Col.value('FirstName[1]',        'varchar(50)'),
                 @vLastName         = Record.Col.value('LastName[1]',         'varchar(50)'),
                 @vEmail            = Record.Col.value('Email[1]',            'varchar(50)'),
                 @vStatus           = Record.Col.value('Status[1]',           'bit'),
                 @vRoleId           = Record.Col.value('RoleId[1]',           'Integer'),
                 @vDefaultWarehouse = Record.Col.value('DefaultWarehouse[1]', 'varchar(50)')
          from @xmlData.nodes('/Root/Data') as Record(Col)
          OPTION ( OPTIMIZE FOR ( @xmlData = null ));

          /* Insert/update users */
          exec  pr_Users_AddOrUpdate  @vUserName, @vPassword, @vFirstName, @vLastName, @vEmail,
                                      @vStatus, @vRoleId, null /* PasswordPolicy */, @BusinessUnit, null, @vDefaultWarehouse, @vUserId, @vResult output;

          set @vMessage = @vResult;
        end

      if (@vEntity = 'User') and (@vAction = 'ChangePassword')
        begin
          exec pr_Users_ChangePassword @xmlData, @BusinessUnit, @vUserId, @vResult output;

          set @vMessage = @vResult;
        end

      /* Convert Actions to V2 terminology */
      select @EntityXML = case
                            when @vAction = 'ChangeOwnership' then
                              dbo.fn_XMLStuffValue (@EntityXML, 'Action', 'ModifyOwnership')
                            when @vAction = 'ChangeWarehouse' then
                              dbo.fn_XMLStuffValue (@EntityXML, 'Action', 'ModifyWarehouse')
                            else
                              @EntityXML
                          end;

      exec @vReturnCode = pr_Entities_ExecuteAction @EntityXML, @BusinessUnit, @UserId,
                                                    @xmlResult output;
    end

EndProc:

  if (exists(select * from #ResultMessages))
    exec pr_Entities_BuildMessageResults @vEntity, @vAction, @xmlResult output;

  /* Return the message as result */
  if (@xmlResult is null) select @xmlResult = @vMessage;

  /* Log success response */
  exec pr_ActivityLog_AddMessage @vAction, null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 @vMessage, @@ProcId, @xmlResult, @BusinessUnit, @UserId,
                                 @ActivityLogId = @vActivityLogId;
end try
begin catch
  /* Current Implementation of Message handlers adds some special characters to the message. These will interfere with forming
     a proper xml string. Hence, remove any special characters from the message before building the result xml with the error message */
  select @vMessage = replace(replace(replace(ERROR_MESSAGE(), '$', ''), '<', ''), '>', ''), @vReturnCode = 1;

  /* insert a message as error type to build message if procedures did not already add the errors */
  if (not exists (select * from #ResultMessages where MessageType = 'E' /* Error */))
    insert into #ResultMessages (MessageType, MessageText) select 'E' /* Error */, @vMessage;

  exec pr_Entities_BuildMessageResults @vEntity, @vAction, @xmlResult output;

  /* Roll back if there is an open transaction */
  if (@@trancount > 0) rollback;

  /* Log failed response */
  exec pr_ActivityLog_AddMessage @vAction, null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 @vMessage, @@ProcId, @xmlResult, @BusinessUnit, @UserId,
                                 @ActivityLogId = @vActivityLogId;

end catch

  return(coalesce(@vReturnCode, 0));
end/* pr_Entities_ExecuteAction_V3 */

Go
