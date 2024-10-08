/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/06  MS      pr_RFC_Picking_ConfirmBatchPick: Changes to suggest Skipped Picks at the end (HA-1449)
                      pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_SkipBatchPick: Correction to DeviceId param
  2016/12/02  RV      pr_RFC_Picking_SkipBatchPick: Update the TaskDetail Status as Inprogress, if there are any units to pick (HPI-1086)
  2016/11/23  KL      pr_RFC_Picking_SkipBatchPick:Log the audit activity details for task skip pick (HPI-1037)
  2015/09/03  TK      pr_RFC_Picking_SkipBatchPick: Consider suggested Location pickpath if the Task is not allocated (CIMS-516)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_SkipBatchPick') is not null
  drop Procedure pr_RFC_Picking_SkipBatchPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_SkipBatchPick:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_SkipBatchPick
  (@xmlInput             xml,
   @xmlResult            xml  output)
As
  declare @DeviceId                            TDeviceId,
          @UserId                              TUserId,
          @BusinessUnit                        TBusinessUnit,
          @PickBatchNo                         TPickBatchNo,
          @PickZone                            TZoneId,
          @PickTicket                          TPickTicket,
          @PickingPallet                       TPallet,
          @OrderDetailId                       TRecordId,
          @FromLPN                             TLPN,
          @FromLPNId                           TRecordId,
          @LPNDetailId                         TRecordId,
          @PickType                            TLookUpCode,
          @TaskId                              TRecordId,
          @TaskDetailId                        TRecordId,
          @ToLPN                               TLPN,
          @SKUPicked                           TSKU,
          @LPNPicked                           TLPN,
          @vShipPack                           TInteger,
          @UnitsPicked                         TInteger,
          @PickedFromLocation                  TLocation,
          @ShortPick                           TFlag,
          @EmptyLocation                       TFlags,
          @ConfirmEmptyLocation                TFlags,
          @DestZone                            TLookUpCode,
          @Operation                           TDescription,
          @PickGroup                           TPickGroup,
          @vLocationType                       TTypeCode,

          @ValidPickZone                       TZoneId,
          @LPNLocationId                       TLocation,
          @LPNLocation                         TLocation,
          @LPNPalletId                         TPallet,
          @SKUId                               TRecordId,
          @LPNInnerPacks                       TInteger,
          @LPNQuantity                         TInteger,
          @ValidFromLPN                        TLPN,
          @vLPNType                            TTypeCode,
          @vLPNStatus                          TStatus,
          @ValidToLPN                          TLPN,
          @vToLPNId                            TRecordId,
          @vToLPN                              TLPN,
          @ToLPNOrderId                        TRecordId,
          @ToLPNPalletId                       TRecordId,
          @ToLPNType                           TTypeCode,
          @ToLPNStatus                         TStatus,
          @vToLPNDestZone                      TZoneId,
          @PickingPalletId                     TRecordId,
          @PickedLPNSKUId                      TRecordId,
          @NextLPNToPickFrom                   TLPN,
          @NextLPNIdToPickFrom                 TRecordId,
          @NextLPNDetailId                     TRecordId,
          @NextLocationToPick                  TLocation,
          @SKUToPick                           TSKU,
          @UnitsToPick                         TInteger,
          @vUnitsPicked                        TInteger,
          @ValidPickTicket                     TPickTicket,
          @OrderId                             TRecordId,
          @vOrderId                            TRecordId,
          @OrderStatus                         TStatus,
          @ValidPickBatchNo                    TPickBatchNo,
          @PickBatchId                         TRecordId,
          @vPickBatchType                      TTypeCode,
          @ValidPickingPallet                  TPallet,
          @vBusinessUnit                       TBusinessUnit,
          @ActivityType                        TActivityType,
          @vBatchStatus                        TStatus,
          @vSetBatchStatusToPickedOnNoMoreInv  TFlag,
          @vPickBatchId                        TRecordId,
          @vLDReservedQty                      TQuantity,
          @vNumPicksCompleted                  TCount,
          /* Tasks Related */
          @vTaskLPNId                          TRecordId,
          @vTaskDetailStatus                   TStatus,
          @vTaskSubType                        TTypeCode,
          @vValidTempLPNId                     TRecordId,
          @vTaskDestZone                       TZoneId,
          @vTaskLocationId                     TRecordId,
          @vTotalTaskDetailsXML                TXML,
          @vTotalTaskDetailsXMLResult          TXML,
          @vCurrentTaskDetailIdXML             TXML,
          @vResultTaskDetailIdXML              TXML,

          /* @OrderDetailId                    TRecordId, */
          @UnitsAuthorizedToShip               TInteger,
          @UnitsAssigned                       TInteger,
          @vUnitsToAllocate                    TInteger,
          @vUnitsPerInnerPack                  TInteger,
          @ConfirmBatchPickMessage             TMessageName,
          @LocToPick                           TLocation,
          @vPickType                           TLookUpCode,

          @vWarehouse                          TWarehouse,
          @vGenerateTempLabel                  TControlValue,
          @vConfirmedAllCases                  TFlags,

          @vTDUnitsCompleted                   TQuantity,
          @vPTRemainingToPick                  TQuantity,

          @vIsBatchAllocated                   TFlag,
          @vIsTempLabelGenerated               TFlag,
          @vPickMultiSKUCategory               TCategory,
          @vIsMultiSKUTote                     TFlags,
          @vAllowPickMultipleSKUsintoLPN       TControlValue,
          @vCCOperation                        TDescription,
          @ttPickedLPNs                        TEntityKeysTable,
          @vSkipPickCategory                   TCategory,
          @vAllowSkipPick                      TControlValue,
          @vPickSequence                       TPickSequence,
          @vLocPickPath                        TLocation,
          @vAccount                            TCustomerId,
          @vDeviceId                           TDeviceId,

          @vPickingMode                        TVarChar,
          @vActivityLogId                      TRecordId,

          @xmlRulesData                        TXML;

  declare @ReturnCode                          TInteger,
          @MessageName                         TMessageName,
          @CCMessage                           TDescription,
          @Message                             TDescription,
          @vDebugOptions                       TFlags,
          @xmlResultvar                        TVarchar;
begin /* pr_RFC_Picking_SkipBatchPick */
begin try
  SET NOCOUNT ON;

  if (@xmlInput is not null)
    select @DeviceId             = Record.Col.value('DeviceId[1]',             'TDeviceId'),
           @UserId               = Record.Col.value('UserId[1]',               'TUserId'),
           @BusinessUnit         = Record.Col.value('BusinessUnit[1]',         'TBusinessUnit'),
           @PickBatchNo          = nullif(Record.Col.value('PickBatchNo[1]',   'TPickBatchNo'), ''),
           @PickZone             = nullif(Record.Col.value('PickZone[1]',      'TZoneId'), ''),
           @PickTicket           = nullif(Record.Col.value('PickTicket[1]',    'TPickTicket'), ''),
           @PickingPallet        = Record.Col.value('PickingPallet[1]',        'TPallet'),
           @OrderDetailId        = Record.Col.value('OrderDetailId[1]',        'TRecordId'),
           @FromLPN              = Record.Col.value('FromLPN[1]',              'TLPN'),
           @FromLPNId            = Record.Col.value('FromLPNId[1]',            'TRecordId'),
           @LPNDetailId          = Record.Col.value('FromLPNDetailId[1]',      'TRecordId'),
           @PickType             = Record.Col.value('PickType[1]',             'TTypeCode'),
           @TaskId               = Record.Col.value('TaskId[1]',               'TRecordId'),
           @TaskDetailId         = Record.Col.value('TaskDetailId[1]',         'TRecordId'),
           @ToLPN                = nullif(Record.Col.value('ToLPN[1]',         'TLPN'), ''),
           @SKUPicked            = nullif(Record.Col.value('SKUPicked[1]',     'TSKU'), ''),
           @LPNPicked            = Record.Col.value('LPNPicked[1]',            'TLPN'),
           @UnitsPicked          = Record.Col.value('UnitsPicked[1]',          'TInteger'),
           @PickedFromLocation   = Record.Col.value('PickedFromLocation[1]',   'TLocation'),
           @ShortPick            = Record.Col.value('ShortPick[1]',            'TFlag'),
           @EmptyLocation        = Record.Col.value('LocationEmpty[1]',        'TFlags'),
           @ConfirmEmptyLocation = Record.Col.value('ConfirmLocationEmpty[1]', 'TFlags'),
           @DestZone             = Record.Col.value('DestZone[1]',             'TLookUpCode'),
           @PickType             = Record.Col.value('PickType[1]',             'TDescription'),
           @Operation            = Record.Col.value('Operation[1]',            'TOperation')
    from @xmlInput.nodes('ConfirmBatchPick') as Record(Col);

  /* Get Debug Options */
  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebugOptions output;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @TaskId, @PickingPallet, 'TaskId-Pallet',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Make null if empty strings are passed */
  select @ActivityType       = 'BatchUnitPick' /* BatchUnitPick */,
         @vConfirmedAllCases = 'N' /* No */,
         @vIsMultiSKUTote    = 'N' /* No */,
         @vNumPicksCompleted = 0,
         /* Build the device id */
         @vDeviceId = @DeviceId + '@' + @UserId;

  select @PickingPalletId = PalletId
  from Pallets
  where (Pallet       = @PickingPallet) and
        (BusinessUnit = @BusinessUnit);

  /* get location type here */
  select @vLocationType     = LocationType,
         @vLocPickPath      = PickPath,
         @vSkipPickCategory = case
                                when (charindex(StorageType, 'U' /* Units */) <> 0) then 'SkipShelvingPick'
                                when (charindex(StorageType, 'P' /* case */ ) <> 0) then 'SkipPTBPick'
                                else 'SkipRackPick'
                              end
  from Locations
  where (Location     = @PickedFromLocation) and
        (BusinessUnit = @BusinessUnit);

  /* get pickPath position here from vwPickTasks to update in devices table */
  select @vPickSequence = PickSequence
  from vwPickTasks
  where (TaskDetailId = @TaskDetailId);

  /* if the Batch is not allocated then get the PickPath from suggested location */
  if (@vPickSequence is null)
    select @vPickSequence = @vLocPickPath;

  /* Update the device operations */
  update Devices
  set LastUsedDateTime = current_timestamp,
      PickSequence     = @vPickSequence
  where (DeviceId = @vDeviceId);

  /* Get control value here */
  select @vAllowSkipPick = dbo.fn_Controls_GetAsString('BatchPicking', @vSkipPickCategory, 'Y',
                                                       @BusinessUnit, @UserId);

  if (@vAllowSkipPick = 'N' /* No */)
    set @MessageName = 'Picking_SkipPickNotAllowed';
  else
  if (dbo.fn_Permissions_IsAllowed(@UserId, 'RFAllowSkipPick') <> '1' /* 1 - True, 0 - False */)
    set @MessageName = 'Picking_DoNotHavePermissions';

   /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Validate PickBatchNo if given by user */
  if (@PickBatchNo is not null)
    exec pr_Picking_ValidatePickBatchNo @PickBatchNo,
                                        @PickingPallet,
                                        @ValidPickBatchNo output,
                                        @vPickBatchType   output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* Validating the Pallet */
  exec pr_Picking_ValidatePallet @PickingPallet, 'U' /* Pallet in Use */,
                                 @PickBatchNo,
                                 @ValidPickingPallet output,
                                 @TaskId, @TaskDetailId;

  /* Get whether the batch is allocated or not */
  select @vIsBatchAllocated = IsAllocated,
         @vPickBatchId      = RecordId,
         @vPickBatchType    = BatchType,
         @vAccount          = Account
  from PickBatches
  where (BatchNo      = @ValidPickBatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* if we did not get PickGroup then get it from rules */
  if (coalesce(@PickGroup, '') <> '')
    begin
      /* Build the data for evaluation of rules to get pickgroup*/
      select @xmlRulesData = '<RootNode>' +
                               dbo.fn_XMLNode('Operation',  @Operation) +
                               dbo.fn_XMLNode('PickType',   @PickType) +
                             '</RootNode>';

      /* Get the valid pickGroup here to find the task  */
      exec pr_RuleSets_Evaluate 'Task_PickGroup', @xmlRulesData, @PickGroup output;
    end

  /* Some client have complained that skipping is not working fine, so we need to log to evaluate */
  if (charindex('X', @vDebugOptions) > 0)
    exec pr_ActivityLog_Task null /* Operation */, @TaskId, default, 'TaskDetails', @@ProcId, @BusinessUnit = @BusinessUnit;

  if (@vIsBatchAllocated = 'Y')
    begin
      /* Since we are skipping the TaskDetail, revert it's status back to New from InProgress */
      update TaskDetails
      set PalletId = null,
          Status   = case
                       when unitsCompleted > 0 then 'I' else 'N'
                     end
      where (TaskDetailId = @TaskDetailId) and
            (UnitsToPick  > 0); /* Added extra check to Mark status as InProgress */;

      /* Find the next Pick Task or Pick from Task for the Batch */
      exec pr_Picking_FindNextTaskToPickFromBatch @UserId,
                                                  @DeviceId,
                                                  @BusinessUnit,
                                                  @PickBatchNo,
                                                  @PickTicket,
                                                  @ValidPickZone,
                                                  @DestZone,
                                                  @PickGroup,
                                                  'P' /* Partial Picks - Units */,
                                                  null,
                                                  @PickingPallet,
                                                  @NextLPNToPickFrom   output,
                                                  @NextLPNIdToPickFrom output,
                                                  @NextLPNDetailId     output,
                                                  @OrderDetailId       output,
                                                  @UnitsToPick         output,
                                                  @LocToPick           output,
                                                  @vPickType           output,
                                                  @TaskId              output,
                                                  @TaskDetailId        output;

          /* Update taskDetail Status here */
          if (coalesce(@TaskDetailId, 0) <> 0)
            update TaskDetails
            set Status   = 'I' /* InProgress */,
                PalletId = @PickingPalletId
            where (TaskDetailId = @TaskDetailId) and
                  (UnitsToPick  > 0); /* Added extra check to Mark status as InProgress */;
        end
      else
        begin
          /* Find the next Pick from the Batch */
          exec pr_Picking_FindNextPickFromBatch @PickBatchNo,
                                                @ValidPickZone,
                                                'P' /* Partial Picks - Units */,
                                                null,
                                                @NextLPNToPickFrom   output,
                                                @NextLPNIdToPickFrom output,
                                                @NextLPNDetailId     output,
                                                @OrderDetailId       output,
                                                @UnitsToPick         output,
                                                @LocToPick           output,
                                                @vPickType           output;
        end

  if (@NextLPNToPickFrom is not null)
    begin
      if (@vPickingMode = 'MultipleOrderDetails')
        begin
          /* Prepare response for the Pick to send to RF Device */
          exec pr_Picking_BatchPickResponse @ValidPickingPallet,
                                            null /* @PalletId */,
                                            null /* @Pallet */,
                                            @NextLPNIdToPickFrom,
                                            @NextLPNToPickFrom,
                                            @NextLPNDetailId,
                                            @OrderDetailId,
                                            @UnitsToPick,
                                            @LocToPick,
                                            @vPickType,
                                            @PickGroup,
                                            @TaskId,
                                            @TaskDetailId,
                                            @BusinessUnit,
                                            @UserId,
                                            @xmlResult output;
         end
     else
       begin
         /* Prepare response for the Pick to send to RF Device */
        exec pr_Picking_BatchPickResponse @ValidPickingPallet,
                                          null /* @PalletId */,
                                          null /* @Pallet */,
                                          @NextLPNIdToPickFrom,
                                          @NextLPNToPickFrom,
                                          @NextLPNDetailId,
                                          @OrderDetailId,
                                          @UnitsToPick,
                                          @LocToPick,
                                          @vPickType,
                                          @PickGroup,
                                          @TaskId,
                                          @TaskDetailId,
                                          @BusinessUnit,
                                          @UserId,
                                          @xmlResult output;
         end
    end
  else
    begin
      set @ConfirmBatchPickMessage = dbo.fn_Messages_GetDescription('BatchPickComplete');

      /* Valid Batch Statuses */
      select @vSetBatchStatusToPickedOnNoMoreInv = dbo.fn_Controls_GetAsBoolean('BatchPicking', 'SetBatchStatusToPickedOnNoMoreInv', 'N'/* No */, @BusinessUnit, @UserId);

      set @xmlResult = (select 0                        as ErrorNumber,
                               @ConfirmBatchPickMessage as ErrorMessage
                        FOR XML RAW('BATCHPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('BATCHPICKDETAILS'));
    end

  /* Some client have complained that skipping is not working fine, so we need to log to evaluate */
  if (charindex('X', @vDebugOptions) > 0)
     exec pr_ActivityLog_Task null /* Operation */, @TaskId, default, 'TaskDetails', @@ProcId, @BusinessUnit = @BusinessUnit;

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @vDeviceId, @UserId, @ActivityType, @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_SkipBatchPick */

Go
