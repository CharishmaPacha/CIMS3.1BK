/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/10/17  RV      pr_RFC_Picking_GetBatchPalletPick: Return appropriate message for Identified Batch's task not released for picking (FB-440)
              DK      pr_RFC_Picking_GetBatchPalletPick: Added validations to verify Bulk Orders(FB-440).
  2015/07/28  TK      pr_RFC_Picking_ConfirmBatchPalletPick & pr_RFC_Picking_GetBatchPalletPick:
                        Enhanced to consider created Task and its Status Progress (FB-265)
  2012/10/10  PK      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_GetUnitPick, pr_RFC_Picking_GetBatchPalletPick,
                       pr_RFC_Picking_GetBatchPick: Added New xml Parameter.
  2012/09/25  AY      pr_RFC_Picking_GetBatchPalletPick, pr_RFC_Picking_ConfirmBatchPalletPick:
                        Ensure multiple users can pick pallets from same batch.
                      pr_RFC_Picking_GetBatchPick: Picking of LPNs after Pallet Picking did not
                        work and had to be revised.
  2012/08/17  PK      Added pr_RFC_Picking_GetBatchPalletPick, pr_RFC_Picking_ConfirmBatchPalletPick.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_GetBatchPalletPick') is not null
  drop Procedure pr_RFC_Picking_GetBatchPalletPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_GetBatchPalletPick: This procedure identifies the Batch to Pick
    and then issues the first pick from the PickBatch. It uses the input
    params to filter the PickBatches. Assuming all inputs are valid, it first
    identifies the PickBatch as follows:
    if the PickBatchNo is given, then it uses the given Pick Batch
    if the PickTicketNo is given, then it identifies the Batch of Order and uses that
    if neither are given, then it finds the highest priority batch in the given
      PickZone i.e. if no pickzone is specified, then the highest priority batch
      across all zones is identified.

    Once the Pick Batch is identified, then it issues the first pick from the PickBatch

     @xmlInput Contains                        XML:
                                       <SelectionCriteria>
   1. @BatchType                         <BatchType></BatchType>
   2. @StartRow                          <StartRow></StartRow>
   3. @EndRow                            <EndRow></EndRow>
   4. @StartLevel                        <StartLevel></StartLevel>
   5. @EndLevel                          <EndLevel></EndLevel>
   6. @StartSection                      <StartSection></StartSection>
   7. @EndSection                        <EndSection></EndSection>
                                       </SelectionCriteria>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_GetBatchPalletPick
  (@DeviceId       TDeviceId,
   @UserId         TUserId,
   @BusinessUnit   TBusinessUnit,
   @PickBatchNo    TPickBatchNo  = null, /* User input */
   @PickTicket     TPickTicket   = null, /* User input */
   @PickZone       TZoneId       = null, /* User input */
   @xmlInput       xml           = null, /* User input */
   @xmlResult      xml           output)
As
  declare @PickPallet                            TPallet,
          @Loop                                  TCount,
          @vUserWarehouse                        TWarehouse,
          @vBatchWarehouse                       TWarehouse,
          @OrderId                               TRecordId,
          @ValidPickTicket                       TPickTicket,
          @ValidPickBatchNo                      TPickBatchNo,
          @ValidPickZone                         TZoneId,
          @PickPalletId                          TRecordId,
          @vRowCount                             TCount,
          @PickPalletLocation                    TLocation,
          @PickPalletZone                        TZoneId,
          @PickPalletSKU                         TSKU,
          @UnitsToPick                           TQuantity,
          @PickType                              TFlag,
          @BatchType                             TTypeCode,
          @vOrderType                            TTypeCode,
          @PickBatchId                           TRecordId,
          @vOrgPickBatchNo                       TPickBatchNo,
          @vTaskId                               TRecordId,
          @vTaskDetailId                         TRecordId,
          @vWaveId                               TRecordId,
          @vTaskStatus                           TStatus,
          @vPickGroup                            TPickGroup,
          @vActivityLogId                        TRecordId;

  declare @ReturnCode                            TInteger,
          @MessageName                           TMessageName,
          @Message                               TDescription,
          @xmlResultvar                          TXML;

begin /* pr_RFC_Picking_GetBatchPalletPick */
begin try
  SET NOCOUNT ON;

  /* for all user input fields, set to nulls if empty string is passed in */
  select @PickBatchNo     = nullif(@PickBatchNo,   ''),
         @vOrgPickBatchNo = nullif(@PickBatchNo,   ''),
         @PickTicket      = nullif(@PickTicket,    ''),
         @PickZone        = nullif(@PickZone,      ''),
         @Loop            = 0,
         @vUserWarehouse  = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit),
         @vBatchWarehouse = null;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @PickTicket, 'PalletId-PickTicket',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* If PickBatch is not given and PT is given then validate
     it and determine the BatchNo from the PickTicket */
  if (@PickBatchNo is null) and (@PickTicket is not null)
    exec  pr_Picking_ValidatePickTicket @PickTicket,
                                        @OrderId         output,
                                        @ValidPickTicket output,
                                        @PickBatchNo     output;

  /* Validate PickBatchNo if given by user */
  if (@PickBatchNo is not null)
    exec pr_Picking_ValidatePickBatchNo @PickBatchNo,
                                        @PickPallet,
                                        @ValidPickBatchNo output,
                                        @BatchType        output,
                                        @vBatchWarehouse  output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  select @OrderId    = OrderId,
         @vOrderType = OrderType,
         @vWaveId    = PickBatchId
  from OrderHeaders
  where (PickTicket = @PickTicket);

  /* Validations */
  if (@PickTicket is not null) and (@OrderId is null)
    set @MessageName = 'PickTicketDoesNotExist';
  else
  if (@PickTicket is not null) and (@PickBatchNo is null)
    set @MessageName = 'PickTicketNotOnaBatch';
  else
  if (@vBatchWarehouse is not null) and (@vBatchWarehouse <> @vUserWarehouse)
    set @MessageName = 'SelectedBatchFromWrongWarehouse';
  else
  if (dbo.fn_Pickbatch_IsBulkBatch(@vWaveId) = 'Y' /* Yes */ ) and (@vOrderType <> 'B' /* Bulk Pull */)
    set @MessageName = 'CannotPickToNonBulkOrder';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

_FindBatch:

  set @Loop = @Loop + 1;
  /* Get the Next Batch to pick if user has not given PickBatchNo or Valid PT */
  if (@PickBatchNo is null)
    select top 1 @PickBatchNo = PB.BatchNo,
                 @PickBatchId = PB.RecordId
    from PickBatches PB
     join vwPallets P on (PB.BatchNo   = P.PickBatchNo   ) and
                         (P.Status     = 'A'/* Allocated */) and
                         (P.PalletType = 'I'/* Inventory Pallet */)
    where (PB.Status in ('R'/* Ready To Pick */, 'U'/* Paused */, 'L' /* ReadyToPull */)) and
          (coalesce(P.PickingZone, '') = coalesce(@PickZone, P.PickingZone, ''));

  if (@PickBatchNo is not null)
    select @PickBatchNo = BatchNo,
           @PickBatchId = RecordId
    from PickBatches
    where (BatchNo = @PickBatchNo);

  if (@PickBatchNo is null)
    begin
      set @MessageName = 'NoPalletPicksForTheBatch';
      goto ErrorHandler;
    end

  /* Fetch a pallet that has already been started by the user */
  select top 1 @PickPallet         = Pallet,
               @PickPalletId       = PalletId,
               @PickPalletLocation = Location,
               @PickPalletZone     = PickingZone,
               @PickPalletSKU      = SKU,
               @UnitsToPick        = Quantity,
               @PickType           = 'P' /* Pallets */
  from vwPallets
  where (PickBatchId = @PickBatchId) and
        (Status = 'C'/* Picking */ and ModifiedBy = @UserId) and
        (PalletType  = 'I' /* Inventory Pallet */) and
        (coalesce(PickingZone, '') = coalesce(@PickZone, PickingZone, ''))
  order by Location;

  /* Fetch the next pallet to pick. Order it by Status so that it will give
     the next allocated pallet. This is to ensure that two users are not given
     the same pallet to pick at the same time. */
  select top 1 @PickPallet         = Pallet,
               @PickPalletId       = PalletId,
               @PickPalletLocation = Location,
               @PickPalletZone     = PickingZone,
               @PickPalletSKU      = SKU,
               @UnitsToPick        = Quantity,
               @PickType           = 'P' /* Pallets */
  from vwPallets
  where (PickBatchId = @PickBatchId) and
        (Status      in ('A'/* Allocated */, 'C'/* Picking */)) and
        (PalletType  = 'I' /* Inventory Pallet */) and
        (coalesce(PickingZone, '') = coalesce(@PickZone, PickingZone, ''))
  order by Status, Location;

  select @vRowCount = @@rowcount;

  /* Get the Task details */
  select @vTaskId       = TaskId,
         @vTaskDetailId = TaskDetailId,
         @vTaskStatus   = TaskStatus
  from vwTaskDetails
  where (TaskPalletId = @PickPalletId) and
        (TaskSubType  = 'P'/* PalletPick */);

  if ((@PickPallet is null) and (@PickPalletLocation is null))
    set @MessageName = 'NoPalletsAvailToPickForBatch';
  else
  if (coalesce(@vOrgPickBatchNo, '') = '') and (@vTaskId is not null) and (@vTaskStatus = 'O' /* Onhold */)
    set @MessageName = 'BatchIdentifiedButTaskNotReleasedForPicking';
  else
  if (@vTaskId is not null) and (@vTaskStatus = 'O' /* Onhold */)
    set @MessageName = 'TaskNotReleasedForPicking';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* If the row count returns 0, then which will loop to fetch the next batch for four time and then assign raises a message or will assign the batch */
  if (@vRowCount = 0)
    if (@Loop < 4)
      begin
        set @PickBatchNo = null;
        goto _FindBatch;
      end
    else
      begin
        set @MessageName = 'BusyInBatchAssignment';
        goto ErrorHandler;
      end

  /* Updating Status to 'P' /* Picking */ for Batch if the picking started for the batch */
  exec pr_PickBatch_SetStatus @PickBatchNo, 'P' /* Picking */, @UserId, @PickBatchId output;

  /* Update Pallet with the Batch and Status to Picking */
  update Pallets
  set Status        = 'C' /* Picking */,
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  where (PalletId = @PickPalletId);

  /* Update TaskDetail Status to In Progress */
  update TaskDetails
  set Status   = 'I' /* InProgress */
  where (TaskDetailId = @vTaskDetailId);

  /* Update the Task Status to InProgress */
  update Tasks
  set Status = 'I' /* Inprogress */
  where (TaskId = @vTaskId);

  /* Prepare response for the Pick to send to RF Device */
  exec pr_Picking_BatchPickResponse null,
                                    @PickPalletId,
                                    @PickPallet,
                                    null /* @LPNIdToPickFrom */,
                                    null /* @LPNToPickFrom */,
                                    null /* @LPNDetailId */,
                                    null /* @OrderDetailId */,
                                    @UnitsToPick,
                                    @PickPalletLocation,
                                    'P' /* Pallet Pick */,
                                    @vPickGroup,
                                    @vTaskId,
                                    @vTaskDetailId,
                                    @BusinessUnit,
                                    @UserId,
                                    @xmlResult output;

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'GetBatchPalletPick', @xmlResultvar, @@ProcId;

  exec pr_AuditTrail_Insert 'StartBatchPalletPick', @UserId, null /* ActivityTimestamp */,
                            @PickBatchId = @PickBatchId,
                            @PalletId    = @PickPalletId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Add to RF Log */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @PickPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @PickPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_GetBatchPalletPick */

Go
