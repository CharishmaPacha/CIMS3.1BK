/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  AY      pr_RFC_Picking_ConfirmBatchPalletPick: Changed signature for pr_Pallets_Lost (HA-1837)
  2016/09/17  RV      pr_RFC_Picking_ConfirmBatchPalletPick: Check validation before close the Task DetailID (HPI-694)
  2015/11/27  SV      pr_RFC_Picking_ConfirmBatchPalletPick: Enhancement for showing the DropLoc and DropZone for the last BatchPalletPick (FB-504)
  2015/07/28  TK      pr_RFC_Picking_ConfirmBatchPalletPick & pr_RFC_Picking_GetBatchPalletPick:
  2012/09/26  PK      pr_RFC_Picking_ConfirmBatchPalletPick: Passing PickBatchNo as it was not declared with the default value in
  2012/09/25  AY      pr_RFC_Picking_GetBatchPalletPick, pr_RFC_Picking_ConfirmBatchPalletPick:
  2012/08/22  PK      pr_RFC_Picking_ConfirmBatchPalletPick: Moved the Logic of Unallocation of LPNs to a new procedure
  2012/08/17  PK      Added pr_RFC_Picking_GetBatchPalletPick, pr_RFC_Picking_ConfirmBatchPalletPick.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ConfirmBatchPalletPick') is not null
  drop Procedure pr_RFC_Picking_ConfirmBatchPalletPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ConfirmBatchPalletPick:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ConfirmBatchPalletPick
  (/* Standard params */
   @DeviceId               TDeviceId,
   @UserId                 TUserId,
   @BusinessUnit           TBusinessUnit,
   /* User input params */
   @PickBatchNo            TPickBatchNo,
   @PickZone               TZoneId,
   @PickTicket             TPickTicket,
   @PickingPallet          TPallet,
   /* Info from earlier response */
   @OrderDetailId          TRecordId,
   @PickType               TLookUpCode,
   /* User confirmed values */
   @PalletPicked           TPallet,
   @PickedFromLocation     TLocation,
   @ShortPick              TFlag = 'N',      /*Default it set to 'N'...Caller will send the required value */
   /* output */
   @xmlResult              xml        output)
As
  declare @ActivityType            TTypeCode,
          @ValidPickBatchNo        TPickBatchNo,
          @BatchType               TTypeCode,
          @ValidPickZone           TZoneId,
          @vPickedPalletId         TRecordId,
          @vPickedPallet           TPallet,
          @vPalletLocationId       TRecordId,
          @vPalletLocation         TLocation,
          @vPalletSKUId            TRecordId,
          @vPalletQuantity         TQuantity,
          @ttPalletLPNs            TEntityKeysTable,
          @vWarehouse              TWarehouse,
          @vBusinessUnit           TBusinessUnit,
          @PickedPalletStatus      TStatus,
          @MessageName             TMessage,
          @CCMessage               TDescription,
          @ConfirmPalletMessage    TMessage,
          @PickPallet              TPallet,
          @PickPalletId            TRecordId,
          @vPickBatchNo            TPickBatchNo,
          @PickPalletLocation      TLocation,
          @UnitsToPick             TQuantity,
          @ConfirmBatchPickMessage TMessage,
          @vPickBatchId            TRecordId,
          @vTaskId                 TRecordId,
          @vTaskDetailId           TRecordId,
          @vTDQuantity             TQuantity,
          @vTDStatus               TStatus,
          @vDropLocation           TLocation,
          @vDestDropLoc            TLocation,
          @vDestDropZone           TZoneId,
          @vNumPicksCompleted      TInteger,
          @xmlResultvar            Txml,
          @ReturnCode              TInteger,
          @vReasonCode             TReasonCode,

          @vPickGroup              TPickGroup,
          @vActivityLogId          TRecordId;

begin /* pr_RFC_Picking_ConfirmBatchPalletPick */
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null /* xmlData */, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @PalletPicked, 'Pallet',
                      @Value1 = @PickBatchNo, @Value2 = @PickTicket, @Value3 = @PickedFromLocation,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Make null if empty strings are passed */
  select @PickBatchNo   = nullif(@PickBatchNo,   ''),
         @PickTicket    = nullif(@PickTicket,    ''),
         @PickZone      = nullif(@PickZone,      ''),
         @PickingPallet = nullif(@PickingPallet, ''),
         @PalletPicked  = nullif(@PalletPicked,  ''),
         @ActivityType  = 'BatchPalletPick',
         @PickType      = 'P' /* Pallet */;

  /* Validate PickBatchNo if given by user */
  if (@PickBatchNo is not null)
    exec pr_Picking_ValidatePickBatchNo @PickBatchNo,
                                        @PickingPallet,
                                        @ValidPickBatchNo output,
                                        @BatchType        output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* select Pallet Information */
  select @vPalletLocationId  = P.LocationId,
         @vPalletLocation    = P.Location,
         @vPickedPalletId    = P.PalletId,
         @vPickedPallet      = P.Pallet,
         @PickedPalletStatus = P.Status,
         @vPickBatchNo       = PB.BatchNo,
         @vPickBatchId       = PB.RecordId,
         @vDropLocation      = PB.DropLocation,
         @vPalletSKUId       = P.SKUId,
         @vPalletQuantity    = P.Quantity,
         @vWarehouse         = P.Warehouse,
         @vBusinessUnit      = P.BusinessUnit
  from vwPallets P
   join PickBatches PB on (P.PickBatchId = PB.RecordId)
  where ((P.Pallet       = @PalletPicked) and
         (PB.BatchNo     = @PickBatchNo)  and
         (P.BusinessUnit = @BusinessUnit));

  /* Get the Task details */
  select @vTaskId       = TaskId,
         @vTaskDetailId = TaskDetailId,
         @vTDQuantity   = TDQuantity
  from vwTaskDetails
  where (TaskPalletId = @vPickedPalletId) and
        (TaskSubType  = 'P'/* PalletPick */);

  /*As we know that, for short pick there is no need to scan any thing like sku,location..*/
  if (@ShortPick = 'N')
    begin
      /* Why to validate From LPN only when Short Pick = 'N' - Please see below comments in else condition (ShortPick = 'Y') */
      if (@vPickedPallet is null)
        set @MessageName = 'InvalidFromPallet';
      else /* NFU - New, New Temp, Picking */
      if (dbo.fn_Pallets_ValidateStatus(@vPickedPalletId, @PickedPalletStatus, 'ACNFU') <> 0)
        set @MessageName = 'PalletClosedForPicking';
      else
      if (@PalletPicked is not null) and (@vPickedPalletId is null)
        set @MessageName = 'InvalidPickingPallet';
      else
      if (@vPalletLocation <> coalesce(@PickedFromLocation, @vPalletLocation))
        set @MessageName = 'LocationDiffFromSuggested';

      /* If Error, then return Error Code/Error Message */
      if (@MessageName is not null)
        goto ErrorHandler;
    end

  if (@PickType = 'P' /* Pallet */) and (@ShortPick = 'N')
    begin
      /* Call ConfirmPalletPick */
      exec pr_Picking_ConfirmPalletPick @vPickedPalletId, @vPickBatchNo, @vBusinessUnit, @UserId;
    end
  else
  if (@ShortPick = 'Y') and (@PickType = 'P')
    begin
      /* Update Pallet and its LPNs, set Pallet and LPN as Lost and OnHandStatus to UnAvailable as picker did not
         find the Pallet in the location. However, do this only if the system thinks the
         Pallet should be in the Location - it could be that Pallet has been moved since the
         user was directed to the Location, or someone else picked it already */
      if (@vPalletLocation = @PickedFromLocation)
        begin
          /* Insert the LPNs which are on the Pallet into temp table */
          insert into @ttPalletLPNs(EntityId, EntityKey)
            select LPNId, LPN
            from LPNs
            where (PalletId     = @vPickedPalletId) and
                  (BusinessUnit = @BusinessUnit);

          /* Unallocate the LPNs - will mark the Pallet and its LPNs as Lost */
          exec pr_LPNs_Unallocate null, @ttPalletLPNs, Default, @BusinessUnit, @UserId;

          /* Trigger Pallet allocation again to find an alternate Pallet */
          update PickBatches
          set UDF10 = 'Y' /* Yes */
          where (BatchNo      = @PickBatchNo) and
                (BusinessUnit = @BusinessUnit);

          select @vReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'ShortPick', null /* CIMS Default */, @BusinessUnit, @UserId);

          /* Mark Pallet as Lost */
          exec pr_Pallets_Lost @vPickedPalletId, @vReasonCode, @BusinessUnit, @UserId;
        end

      select @ConfirmPalletMessage = dbo.fn_Messages_GetDescription('PalletShortPicked'),
             @OrderDetailId        = null /* To store next OrderDetailId */;

      exec pr_AuditTrail_Insert 'PalletShortPicked', @UserId, null /* ActivityTimestamp */,
                                @PalletId      = @vPickedPalletId,
                                @LocationId    = @vPalletLocationId,
                                @Quantity      = @vPalletQuantity;

      exec @ReturnCode = pr_Locations_CreateCycleCountTask @PickedFromLocation,
                                                           'ShortPick',
                                                           @UserId,
                                                           @BusinessUnit,
                                                           @CCMessage output;
      if (@ReturnCode > 0)
        begin
          select @MessageName = @CCMessage;
          goto ErrorHandler;
        end
    end

  if (@ShortPick = 'N'/* No */)
    /* Update Picked Units on the TaskDetail */
    update TaskDetails
    set UnitsCompleted = UnitsCompleted + @vPalletQuantity
    where (TaskDetailId = @vTaskDetailId);

  /* Mark Task Details as completed */
  if (@vTaskDetailId is not null)
    exec pr_TaskDetails_Close @vTaskDetailId, null /* LPNDetailId */, @UserId, null/* Operation */;

  /* Find the next Pallet to Pick from the Batch */
  exec pr_Picking_FindNextPalletToPickFromBatch @vPickBatchId, @PickBatchNo /* PickBatchNo */,
                                                @PickZone, @UserId, Default /* Search Type */,
                                                @PickPalletId output,
                                                @PickPallet   output,
                                                @MessageName  output;

  if (@PickPallet is not null)
    begin
      /* Get the Task Details */
      select @vTaskId       = TaskId,
             @vTaskDetailId = TaskDetailId
      from vwTaskDetails
      where (TaskPalletId = @PickPalletId) and
            (TaskSubType  = 'P' /* PalletPick */);

      /* Prepare response for the Pick to send to RF Device */
      exec pr_Picking_BatchPickResponse null,
                                        @PickPalletId,
                                        @PickPallet,
                                        null /* @LPNIdToPickFrom */,
                                        null /* @LPNToPickFrom */,
                                        null /* @LPNDetailId */,
                                        null /* @OrderDetailId */,
                                        null,
                                        null,
                                        @PickType /* Pallet Pick */,
                                        @vPickGroup,
                                        @vTaskId,
                                        @vTaskDetailId,
                                        @BusinessUnit,
                                        @UserId,
                                        @xmlResult output;
    end
  else
    begin
      select @MessageName             = null,
             @ConfirmBatchPickMessage = dbo.fn_Messages_GetDescription('BatchPalletPickComplete');

      /* Get Drop Location and Zone */
      exec pr_Picking_FindDropLocationAndZone @PickBatchNo, @BatchType, @vDropLocation, @vTaskId, 'BatchPalletPicking_Drop' /* Operation */, @BusinessUnit,
                                              @UserId, @vDestDropLoc output, @vDestDropZone output;

      /* Updating Status for Batch if the picking is Complete for the Batch */
      exec pr_PickBatch_SetStatus @PickBatchNo, null, @UserId, @vPickBatchId output;

      /* Log the Audit Trail once after the Batch is Picked */
      exec pr_AuditTrail_Insert 'PalletPickBatchComplete', @UserId, null /* ActivityTimestamp */,
                                @PickBatchId = @vPickBatchId;

      set @xmlResult = (select 0                        as ErrorNumber,
                               @ConfirmBatchPickMessage as ErrorMessage,
                               coalesce(@vDestDropLoc, '') as DestDropLocation,
                               coalesce(@vDestDropZone + '-', '') as DestDropZone
                        FOR XML RAW('BATCHPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('BATCHPICKDETAILS'));

    end

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, @ActivityType, @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPickedPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPickedPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ConfirmBatchPalletPick */

Go
