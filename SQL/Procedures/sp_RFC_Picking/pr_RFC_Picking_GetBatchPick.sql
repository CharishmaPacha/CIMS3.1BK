/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/09  TK      pr_RFC_Picking_GetBatchPick & pr_RFC_Picking_ConfirmBatchPick & pr_RFC_Picking_SkipBatchPick:
                      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_SkipBatchPick: Correction to DeviceId param
  2019/11/05  RIA     pr_RFC_Picking_GetBatchPick: Changes to consider pick group (CID-836)
  2018/11/14  KSK     pr_RFC_Picking_GetBatchPick: Update pallet on Tasks (OB-529)
  2018/05/13  AY      pr_RFC_Picking_GetBatchPick: Validation of Task Pick Groups corrected (S2G-762)
  2018/04/18  TK      pr_RFC_Picking_GetBatchPick: pass in PickZone while evaulating rules to get valid pick group (S2G-CRP)
  2018/04/16  AY      pr_RFC_Picking_GetBatchPick: Logging changes and validate User Warehouse (S2G-645)
  2018/03/30  RV      pr_RFC_Picking_GetBatchPick: Made changes to send PickTicket to get correct task (S2G-534)
  2018/02/05  TD      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmLPNPick:
  2017/01/09  RV      pr_RFC_Picking_GetBatchPick: Update Pallet on Task while picking (HPI-1242)
  2016/11/26  SV/TK   pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_StartBuildCart: Clearing up the earlier AlternateLPN info over the cart LPNs for the new pick (HPI-891)
  2016/11/24  ??      pr_RFC_Picking_GetBatchPick: Changed the sequence of status check (HPI-GoLive)
  2016/11/23  PK      pr_RFC_Picking_GetBatchPick: Bug fix to display the correct missing LPN in the error message.
  2016/10/24  SV/TK   pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_StartBuildCart: Clearing up the earlier AlternateLPN info over the cart LPNs for the new pick (HPI-891)
  2016/10/12  PK      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick: Enabled MultipleOrderDetails for all PP type of waves.
  2016/10/09  PK      pr_RFC_Picking_GetBatchPick: Modified check condition to consider Account in ('63', '64') (HPI-GoLive)
  2016/10/03  KL      pr_RFC_Picking_GetBatchPick: Send the pallet to pr_Picking_FindNextTaskToPickFromBatch procedure as siganture was changed (FB-768)
  2016/10/01  ??      pr_RFC_Picking_GetBatchPick: Modified check condition to consider BatchType 'PC' as well (HPI-GoLive)
  2016/09/29  ??      pr_RFC_Picking_GetBatchPick: Modified check condition to exclude Status 'K' and few other changes (HPI-GoLive)
  2016/09/23  RV      pr_RFC_Picking_GetBatchPick: Do not allow to start picking if all LPNs are not built onto the cart for Pick To Ship Waves (HPI-761)
  2016/08/05  KL      pr_RFC_Picking_GetBatchPick: Added validation to restrict invalid pallets to pick (CIMS-895)
  2016/08/01  OK      pr_RFC_Picking_GetBatchPick: Added the validation to restrict the picking if task dependent on any replenish task (HPI-371)
  2016/07/30  KL      pr_RFC_Picking_GetBatchPick: Added validation to validate pallet type for LPN pick (HPI-384)
  2016/06/21  TK      pr_RFC_Picking_GetBatchPick: Changes made to use new procedures (cIMS-895)
  2016/03/30  AY      pr_RFC_Picking_GetBatchPick: Clear Pick path position on start of picking
  2016/01/20  TK      pr_RFC_Picking_GetBatchPick: Enhanced user to scan Either Task or Pallet, since it is not mandatory
  2015/11/02  OK      pr_RFC_Picking_GetBatchPick: Validate the PickZone if user passes TaskId (FB-477)
  2015/10/28  AY      pr_RFC_Picking_GetBatchPick: Validate given Pick Zone first (FB-447)
                      pr_RFC_Picking_GetBatchPick: Update Pallet Warehouse when Picking is initiated (FB-456)
  2015/09/01  VM      pr_RFC_Picking_GetBatchPick: Bugfix - corrected Task & Pickzone requirement validations and used controls to validate as well
  2015/01/13  VM      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick:
  2014/09/04  TD      pr_RFC_Picking_GetBatchPick:Changes to get taskId based on the Zone.
  2014/04/08  PK      pr_RFC_Picking_GetBatchPick: Changed the input parameters to XML.
  2014/02/27  NY      pr_RFC_Picking_GetBatchPick : Show proper message when a user tried to pick that is assigned to other user(xsc-360)
  2013/12/22  TD      pr_RFC_Picking_GetBatchPick:bugfix: To avoid assigning same task to two users at the same time.
  2103/10/28  TD      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_PauseBatch: Changes to pick multiple uses at a time for the same
  2013/09/26  PK      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick: Changes to suggest the Picks from tasks if the batch is allocated.
                      pr_RFC_Picking_GetBatchPick: Updating the tasks and changed the callers by adding TaskId and TaskDetailId.
                      pr_RFC_Picking_GetBatchPick: Added New xml Parameter.
                      pr_RFC_Picking_GetBatchPick: Picking of LPNs after Pallet Picking did not
  2012/07/16  AY      pr_RFC_Picking_GetBatchPick: Get batch within the Warehouse User is logged in
  2012/07/03  AY      pr_RFC_Picking_GetBatchPick: Set PalletType to Picking
  2012/05/15  PK      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_ConfirmBatchPick: Migrated from FH related to LPN/Piece Pick.
  2012/02/01  VM      pr_RFC_Picking_GetBatchPick: Modified to pass new param values pr_Picking_BatchPickResponse
  2012/01/27  PK      pr_RFC_Picking_GetBatchPick: Added begin trans and end trans in between catch and try block to rollback
  2011/08/26  PK      pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_GetBatchPick
  2011/08/02  DP      pr_RFC_Picking_GetBatchPick: Implemented the Procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_GetBatchPick') is not null
  drop Procedure pr_RFC_Picking_GetBatchPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_GetBatchPick: This procedure identifies the Batch to Pick
    and then issues the first pick from the PickBatch. It uses the input
    params to filter the PickBatches. Assuming all inputs are valid, it first
    identifies the PickBatch as follows:
    if the PickBatchNo is given, then it uses the given Pick Batch
    if the PickTicketNo is given, then it identifies the Batch of Order and uses that
    if neither are given, then it finds the highest priority batch in the given
      PickZone i.e. if no pickzone is specified, then the highest priority batch
      across all zones is identified.

    Once the Pick Batch is identified, then it issues the first pick from the PickBatch

    @xmlInput XML Structure:
    <GetBatchPick>
      <PickBatchNo></PickBatchNo>
      <TaskId></TaskId>
      <PickTicket></PickTicket>
      <PickZone></PickZone>
      <Pallet></Pallet>
      <DestZone></DestZone>
      <Operation></Operation>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
      <SelectionCriteria>
        <BatchType></BatchType>
        <StartRow></StartRow>
        <EndRow></EndRow>
        <StartLevel></StartLevel>
        <EndLevel></EndLevel>
        <StartSection></StartSection>
        <EndSection></EndSection>
      </SelectionCriteria>
    </GetBatchPick>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_GetBatchPick
  (@xmlInput       xml, /* User input */
   @xmlResult      xml           output)
As
  declare @ValidPickZone                         TZoneId,
          @LPNToPickFrom                         TLPN,
          @LPNIdToPickFrom                       TRecordId,
          @LPNDetailId                           TRecordId,
          @LocationToPick                        TLocation,
          @SKUToPick                             TSKU,
          @UnitsToPick                           TInteger,
          @LPNLocationId                         TLocation,
          @LPNLocation                           TLocation,
          @LPNPalletId                           TPallet,
          @LPNSKUId                              TSKU,
          @LPNSKU                                TSKU,
          @LPNQuantity                           TInteger,
          @ValidPickTicket                       TPickTicket,
          @OrderId                               TRecordId,
          @OrderDetailId                         TRecordId,
          @OrderLine                             TOrderLine,
          @HostOrderLine                         THostOrderLine,
          @UnitsAuthorizedToShip                 TInteger,
          @UnitsAssigned                         TInteger,
          @PickPalletId                          TRecordId,
          @ValidPallet                           TPallet,
          @ValidPickBatchNo                      TPickBatchNo,
          @PickBatch                             TPickBatchNo,
          @PickBatchId                           TRecordId,
          @vNextBatchToPick                      TPickBatchNo,
          @vPalletBatchNo                        TPickBatchNo,
          @Loop                                  TInteger,
          @LocToPick                             TLocation,
          @PickType                              TLookUpCode,
          @PickGroup                             TLookUpCode,
          @LPNToPick                             TLPN,
          @LPNIdToPick                           TRecordId,
          @TaskId                                TRecordId,
          @vTaskId                               TRecordId,
          @vTaskSubType                          TTypeCode,
          @vIsTempLabelGenerated                 TFlag,
          @vNumTempLabelsOnCart                  TCount,
          @vNumTempLabels                        TCount,
          @vMissingTempLabel                     TLPN,
          @vTaskCategory1                        TCategory,
          @TaskDetailId                          TRecordId,
          @vUserWarehouse                        TWarehouse,
          @vBatchWarehouse                       TWarehouse,

          @vIsBatchAllocated                     TFlag,
          @vIsTaskAllocated                      TFlag,
          @vDependencyFlag                       TFlag,

          @PickBatchNo                           TPickBatchNo,
          @vWaveType                             TTypeCode,
          @ValidTaskId                           TRecordId,
          @PickTicket                            TPickTicket,
          @PickZone                              TZoneId,
          @DestZone                              TLookUpCode,
          @Operation                             TDescription,
          @vPalletId                             TRecordId,
          @vPalletType                           TTypeCode,
          @vTaskPalletId                         TRecordId,
          @PickPallet                            TPallet,
          @vPalletStatus                         TStatus,
          @vTaskPickZone                         TZoneId,
          @vTaskStatus                           TStatus,

          @vScanTask                             TFlag,

          @vBatchType                            TTypeCode,
          @vAccount                              TCustomerId,

          @DeviceId                              TDeviceId,
          @UserId                                TUserId,
          @BusinessUnit                          TBusinessUnit,
          @xmlRulesData                          TXML,
          @vValidPalletTypesToPick               TDescription,

          @vPickGroup                            TPickGroup,
          @vDeviceId                             TDeviceId,
          @vActivityLogId                        TRecordId;

  declare @ReturnCode                            TInteger,
          @MessageName                           TMessageName,
          @Message                               TDescription,
          @vAssignedTo                           TUserId,
          @xmlResultvar                          TXML,
          @vPickingMode                          TVarChar,
          @vCategory3                            TCategory,
          @vNote3                                TDescription,
          @vNote4                                TDescription,
          @vNote5                                TDescription;

begin /* pr_RFC_Picking_GetBatchPick */
begin try
  SET NOCOUNT ON;

  /* Get the XML User inputs in to the local variables */
  select @PickBatchNo  = Record.Col.value('PickBatchNo[1]'    , 'TPickBatchNo'),
         @TaskId       = Record.Col.value('TaskId[1]'         , 'TRecordId'),
         @PickTicket   = Record.Col.value('PickTicket[1]'     , 'TPickTicket'),
         @PickZone     = Record.Col.value('PickZone[1]'       , 'TZoneId'),
         @PickPallet   = Record.Col.value('Pallet[1]'         , 'TPallet'),
         @DestZone     = Record.Col.value('DestZone[1]'       , 'TLookUpCode'),
         @Operation    = Record.Col.value('Operation[1]'      , 'TDescription'),
         @PickType     = Record.Col.value('PickType[1]'       , 'TTypeCode'),
         @PickGroup    = Record.Col.value('PickGroup[1]'      , 'TTypeCode'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]'   , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'         , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'       , 'TDeviceId')
  from @xmlInput.nodes('GetBatchPick') as Record(Col);

  /* for all user input fields, set to nulls if empty string is passed in */
  select @PickBatchNo     = nullif(@PickBatchNo, ''),
         @TaskId          = nullif(@TaskId     , ''),
         @PickTicket      = nullif(@PickTicket , ''),
         @PickPallet      = nullif(@PickPallet , ''),
         @DestZone        = nullif(@DestZone ,   ''),
         @PickZone        = nullif(@PickZone,    ''),
         @Loop            = 0,
         @vUserWarehouse  = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit),
         @vBatchWarehouse = null,
         @vTaskId         = @TaskId,
         @vDeviceId       = @DeviceId + '@' + @UserId;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @TaskId, @PickPallet, 'TaskId-Pallet',
                      @Value1 = @PickBatchNo, @Value2 = @PickTicket, @Value3 = @PickZone,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Control vars - this has to be enhanced in future to use rules */
  select @vScanTask = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'ScanTask',     'N' /* No */, @BusinessUnit, @UserId);

  /* clear the pickpath position from devices here
     may be we can use the same device update procedure here to clear the devices table  */
  update Devices
  set PickSequence = null
  where DeviceId = @vDeviceId;

  /* If PickBatch is not given and PT is given then validate
     it and determine the BatchNo from the PickTicket */
  if (@PickBatchNo is null) and (@PickTicket is not null)
    exec pr_Picking_ValidatePickTicket @PickTicket,
                                       @OrderId         output,
                                       @ValidPickTicket output,
                                       @PickBatchNo     output;

  if (@PickBatchNo is not null) select @vWaveType = BatchType from PickBatches where BatchNo = @PickBatchNo;
  if (@TaskId is not null) select @vWaveType = BatchType from vwPickTasks where (TaskId = @TaskId);

  /* Build the data for evaluation of rules to get pickgroup*/
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',  @Operation) +
                           dbo.fn_XMLNode('PickType',   @PickType) +
                           dbo.fn_XMLNode('PickGroup',  @PickGroup) +
                           dbo.fn_XMLNode('PickZone',   @PickZone) +
                           dbo.fn_XMLNode('WaveType',   @vWaveType));

  /* Get the valid pickGroup here to find the task  */
  exec pr_RuleSets_Evaluate 'Task_GetValidTaskPickGroup', @xmlRulesData, @vPickGroup output;

  /* Verify whether the given PickZone is valid, if provided only */
  if (@PickZone is not null)
    exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  if (@PickBatchNo is not null) and ((@ValidPickZone is not null) or (@DestZone is not null) or (@PickTicket is not null)) and (@TaskId is null)
    exec pr_Picking_GetPickTaskForPickZone @ValidPickZone, @DestZone, @vPickGroup, @ValidPickTicket, @PickBatchNo,
                                           @Operation, @BusinessUnit, @UserId, @vUserWarehouse,
                                           @ValidPickZone output, @vTaskId output;

  /* if user did not scan Task but scanned pallet then check whether there any Task associated
     with the pallet and validate it */
  /* No matter if user scans Task or not we have to validate scanned Pallet as we would
    use @ValidPallet further in the Procedure */
  if (@PickPallet is not null)
    exec pr_Picking_ValidatePallet @PickPallet, 'E' /* Empty - ValidateOption */,
                                   @vPalletBatchNo output,
                                   @ValidPallet    output,
                                   @vTaskId        output,
                                   @TaskDetailId   output;

  /* Validate TaskId if given by user or we have an active one on the Pallet */
  if (@TaskId is not null) or (@vTaskId is not null)
    exec pr_Picking_ValidateTaskId @TaskId,
                                   @vTaskId,
                                   @vPickGroup,
                                   @PickPallet,
                                   @PickTicket,
                                   @ValidTaskId output,
                                   @PickBatchNo output;

  /* Validate PickBatchNo if given by user */
  if (@PickBatchNo is not null)
    exec pr_Picking_ValidatePickBatchNo @PickBatchNo,
                                        @PickPallet,
                                        @ValidPickBatchNo output,
                                        @vWaveType        output,
                                        @vBatchWarehouse  output;

  /* Check whether scanned Task is Allocated or not */
  select @vIsTaskAllocated = IsTaskAllocated,
         @vDependencyFlag  = DependencyFlags,
         @vTaskPickZone    = PickZone,
         @vTaskPalletId    = PalletId,
         @vTaskSubType     = TaskSubType,
         @vTaskStatus      = Status,
         @vTaskCategory1   = TaskCategory1,
         @vWaveType        = coalesce(@vWaveType, BatchType)
  from vwTasks
  where (TaskId = @vTaskId);

  /* If user did not scan any Pallet but the scanned task is associated with some pallet then
      use it and validate */
  if (@PickPallet is null) and (@vTaskPalletId is not null)
    begin
      select @PickPallet = Pallet
      from Pallets
      where (PalletId = @vTaskPalletId);

      /* We have now determined a valid Batch to Pick, hence validate the Pallet
         that will be used for Picking */
      exec pr_Picking_ValidatePallet @PickPallet, 'E' /* Empty - ValidateOption */,
                                     @vPalletBatchNo output,
                                     @ValidPallet    output,
                                     @vTaskId        output,
                                     @TaskDetailId   output;
    end

  /* get Pallet details here */
  select @PickPalletId  = PalletId,
         @vPalletType   = PalletType,
         @vPalletStatus = Status
  from Pallets
  where (Pallet       = @ValidPallet ) and
        (BusinessUnit = @BusinessUnit);

  select @vNumTempLabelsOnCart  = count(*)
  from LPNs
  where (@vPalletType in ('C' /* Picking Cart */)) and (LPNType in ('S' /* Ship Carton */)) and
        (PalletId = @PickPalletId);

  select @vNumTempLabels        = count(distinct TempLabel),
         @vIsTempLabelGenerated = min(IsLabelGenerated)
  from TaskDetails
  where (TaskId = @vTaskId) and
        (Status not in ('C', 'X')) and
        (IsLabelGenerated = 'Y')

  /* Build the data for evaluation of rules */
  select @xmlRulesData = '<RootNode>' +
                           dbo.fn_XMLNode('WaveType',      @vWaveType) +
                           dbo.fn_XMLNode('TaskSubType',   @vTaskSubType) +
                           dbo.fn_XMLNode('TaskPickZone',  @vTaskPickZone) +
                           dbo.fn_XMLNode('TaskCategory1', @vTaskCategory1) +
                           dbo.fn_XMLNode('PalletType',    @vPalletType) +
                         '</RootNode>'

  /* Get the list of valid PalletTypes to allow picking of the particular task */
  exec pr_RuleSets_Evaluate 'ValidPalletTypesToPickTo', @xmlRulesData, @vValidPalletTypesToPick output;

  /* Validations */
  if (@PickTicket is not null) and (@PickBatchNo is null)
    set @MessageName = 'PickTicketNotOnaBatch';
  else
  if (@vBatchWarehouse is not null) and (@vBatchWarehouse <> @vUserWarehouse)
    set @MessageName = 'SelectedBatchFromWrongWarehouse';
  else
  if (coalesce(@TaskId, 0) = 0) and (@vScanTask = 'Y' /* Yes */)
    set @MessageName = 'TaskIsRequired';
  else
  if ((@Operation = 'Replenishment') and (@vBatchType not in ('R', 'RU', 'RP' /* Replenishment */)))
    set @MessageName = 'InvalidTaskForReplenishment';
  else
  /* If TaskId is given and trying to give invalid pickzone */
  if (@TaskId is not null) and (@vTaskPickZone <> @ValidPickZone)
    exec @MessageName = dbo.fn_Messages_Build 'InvalidPickZoneForTask', @TaskId /* TaskId */, @PickZone /* PickZone */;
  else
  /* If Task is given and that task dependent on any replenish wave then restrict picking */
  if (@vTaskId is not null) and (@vDependencyFlag = 'R')
    set @MessageName = 'TaskIsDependentOnReplenishTask';
  else
  /* If Task is not allocated, then PickZone is mandatory */
  if (@ValidPickZone is null) and (@vIsTaskAllocated = 'N'/* No */)
    set @MessageName = 'PickZoneIsRequired';
  else
  if (@vTaskSubType = 'U' /* Unit pick */) and
     (coalesce(@vValidPalletTypesToPick, 'ALL') <> 'ALL') and
     (charindex(@vPalletType, @vValidPalletTypesToPick) = 0)
    set @MessageName = 'InvalidPalletTypeToPick';
  else
  if (@vTaskSubType = 'L' /* LPN pick */) and
     (@vPalletType = 'C' /* Picking Cart*/)
    set @MessageName = 'InvalidPalletTypeToPick';
  else
  /* Not allow start picking if all LPNs are not assigned to positions on the cart */
  if (@vNumTempLabelsOnCart <> @vNumTempLabels and coalesce(@vIsTempLabelGenerated, '') = 'Y' /* Yes */) and (@vTaskStatus = 'N') and (@vPalletType = 'C' /* Cart */)
    begin
      select top 1 @vMissingTempLabel = TD.TempLabel
      from TaskDetails TD
        join LPNs L on (TD.TempLabelId = L.LPNId)
      where TD.TaskId = @vTaskId and (L.AlternateLPN is null) and (TD.Status not in ('X', 'C' /* Cancelled, Completed */));

      select @MessageName = 'NotAllLPNsBuiltToCart',
             @vNote3      = @vNumTempLabels - @vNumTempLabelsOnCart, /* Missing Temp Labels Count */
             @vNote4      = @vNumTempLabels,
             @vNote5      = @vMissingTempLabel;
    end
  else
  if (@vUserWarehouse is null)
    set @MessageName = 'UserWarehouseIsRequired';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* If User has given BatchNo, then we have to pick that batch only, if not
     take the one from the Pallet */
  select @vNextBatchToPick = coalesce(@ValidPickBatchNo, @vPalletBatchNo);

  /* Try at least four batches */
  while (@Loop < 4)
    begin
      /* Get the Next Batch to pick if user has not given PickBatchNo or Valid PT */
      /* If user scans batchnumber, and if there is no taskId scanned then we need try to
         find out the task here, because, in above we are trying to find out the task for the
         given PickZone or DestZone. If both were not given then we are not finding the task  */
      if ((@vNextBatchToPick is null) or ((@vNextBatchToPick is not null) and (@TaskId is null)))
        exec pr_Picking_NextBatchToPick @ValidPickZone,
                                        @DestZone,
                                        @vPickGroup,
                                        null /* Batch Type - future use */,
                                        @PickPallet,
                                        @vUserWarehouse,
                                        @BusinessUnit,
                                        @UserId,
                                        @vNextBatchToPick output,
                                        @vTaskId          output;

      if (@vNextBatchToPick is null)
        begin
          set @MessageName = 'NoBatchesToPick';
          break; /* exit loop */
        end

      /* Get whether the batch is allocated or not */
      select @vIsBatchAllocated = IsAllocated,
             @vAssignedTo       = AssignedTo
      from PickBatches
      where (BatchNo      = @vNextBatchToPick) and
            (BusinessUnit = @BusinessUnit);

      if (@vIsBatchAllocated = 'Y') or (@vTaskId is not null)
        begin
          /* Find the next Pick Task or Pick from Task for the Batch */
          exec pr_Picking_FindNextTaskToPickFromBatch @UserId,
                                                      @DeviceId,
                                                      @BusinessUnit,
                                                      @vNextBatchToPick,
                                                      @PickTicket,  --If PickTicket passed then suggest from that PT only
                                                      @ValidPickZone,
                                                      @DestZone,
                                                      @vPickGroup,
                                                      'P' /* SearchType*/,
                                                      null,
                                                      @ValidPallet,
                                                      @LPNToPickFrom   output,
                                                      @LPNIdToPickFrom output,
                                                      @LPNDetailId     output,
                                                      @OrderDetailId   output,
                                                      @UnitsToPick     output,
                                                      @LocToPick       output,
                                                      @PickType        output,
                                                      @vTaskId         output,
                                                      @TaskDetailId    output;
        end
      else
        begin
          /* Find the next Pick from the Batch */
          exec pr_Picking_FindNextPickFromBatch @vNextBatchToPick,
                                                @ValidPickZone,
                                                'P',
                                                null,
                                                @LPNToPickFrom   output,
                                                @LPNIdToPickFrom output,
                                                @LPNDetailId     output,
                                                @OrderDetailId   output,
                                                @UnitsToPick     output,
                                                @LocToPick       output,
                                                @PickType        output;
        end

      /* If we found an LPN to pick, then break the loop */
      if (@LPNToPickFrom is not null) or (@LocToPick is not null)
        break;

      /* If User has given a PT or BatchNo and we are unable to find any picks
         for it, then quit trying */
      if ((@ValidPickBatchNo is not null) or (@vPalletBatchNo is not null))
        begin
          if ((@UnitsToPick is null) and ((@UserId = @vAssignedTo) or (@vAssignedTo is null)))
            set @MessageName = 'NoUnitsAvailToPickForBatch';
          else
            set @MessageName = 'BatchAssignedToOtherUserForPicking'
          break;
        end;

      /* At this point, we have a Batch, but no LPNs to Pick on the Batch, so
         let us try another batch */
      select @vNextBatchToPick = null,
             @Loop             += 1;
    end;

  /* If we ran thru the loop four times and did not find a batch, then ask user to try again */
  if (@Loop = 4) and (@vNextBatchToPick is null)
    set @MessageName = 'BusyInBatchAssignment';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update Batch with the Pallet */
  update PickBatches
  set PalletId = @PickPalletId,
      Pallet   = @PickPallet
  where (BatchNo      = @vNextBatchToPick) and
        (BusinessUnit = @BusinessUnit) and
        ((PalletId is null) or (PalletId = @PickPalletId)); /* Will assign the batch to the first scanned pallet, if one or more user's requests for next batch */

  /* Updating Status to 'P' - Picking  for Batch if the picking started for the batch */
  exec pr_PickBatch_SetStatus @vNextBatchToPick, 'P' /* Picking */, @UserId, @PickBatchId output;

  /* Update Pallet with the Batch and Status to Picking */
  update Pallets
  set PickBatchId   = @PickBatchId,
      PickBatchNo   = @vNextBatchToPick,
      Status        = 'C' /* Picking */,
      PalletType    = case when (charindex(PalletType, 'CFH' /* Carts */) = 0) /* If cart, then don't change pallet type */
                           then 'P' /* Picking Pallet */
                           else PalletType end,
      Warehouse     = @vBatchWarehouse,
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  where (PalletId = @PickPalletId);

  /* Update taskDetail Status here */
  if (coalesce(@TaskDetailId, 0) <> 0)
    update TaskDetails
    set Status   = 'I' /* InProgress */,
        PalletId = @PickPalletId
    where (TaskDetailId = @TaskDetailId);

  /* Update pallet on Tasks */
  if (coalesce(@vTaskId, 0) <> 0)
    update Tasks
    set PalletId = @PickPalletId,
        Pallet   = @PickPallet
    where (TaskId = @vTaskId);

  /* Update the task if there is one */
  if (@vTaskId is not null)
    exec @ReturnCode = pr_Tasks_SetStatus @vTaskId, @UserId, 'I' /* Inprogress */;

  /* if there is any error then we need to navigate to error handler.. */
  if (@ReturnCode > 0)
    goto ErrorHandler;

  if (@vPickingMode = 'MultipleOrderDetails')
    begin
      /* Prepare response for the Pick to send to RF Device */
      exec pr_Picking_BatchPickResponse @ValidPallet,
                                        null /* @PalletId */,
                                        null /* @Pallet */,
                                        @LPNIdToPickFrom,
                                        @LPNToPickFrom,
                                        @LPNDetailId,
                                        @OrderDetailId,
                                        @UnitsToPick,
                                        @LocToPick,
                                        @PickType,
                                        @vPickGroup,
                                        @vTaskId,
                                        @TaskDetailId,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;
    end
  else
    begin
      /* Prepare response for the Pick to send to RF Device */
      exec pr_Picking_BatchPickResponse @ValidPallet,
                                        null /* @PalletId */,
                                        null /* @Pallet */,
                                        @LPNIdToPickFrom,
                                        @LPNToPickFrom,
                                        @LPNDetailId,
                                        @OrderDetailId,
                                        @UnitsToPick,
                                        @LocToPick,
                                        @PickType,
                                        @vPickGroup,
                                        @vTaskId,
                                        @TaskDetailId,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;
    end

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'GetBatchPick', @xmlResultvar, @@ProcId;

  exec pr_AuditTrail_Insert 'StartBatchPick', @UserId, null /* ActivityTimestamp */,
                            @PickBatchId = @PickBatchId,
                            @TaskId      = @vTaskId,
                            @PalletId    = @PickPalletId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @PickBatchNo, @vAssignedTo, @vNote3, @vNote4, @vNote5;

  /* Update result for the activity  */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @TaskId, @ActivityLogId = @vActivityLogId output;

  commit transaction;

end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @TaskId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_GetBatchPick */

Go
