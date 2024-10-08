/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/29  AY      pr_Picking_ConfirmPicksAsShort, pr_Picking_ShortPickLPN: Use reason codes from control var (HA-1837)
  2020/11/30  TK      pr_Picking_ConfirmPicksAsShort: Initial Revision (CID-1545)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ConfirmPicksAsShort') is not null
  drop Procedure pr_Picking_ConfirmPicksAsShort;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ConfirmPicksAsShort:
    This procedure confirms the given set of picks as short based upon the controls that are
    set up in regards to quantity adjustments in the From LPN
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ConfirmPicksAsShort
  (@PicksInfo        TTaskDetailsInfoTable READONLY,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
As
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,

          @vRecordId                    TRecordId,

          @vFromLPNId                   TRecordId,
          @vFromLPNDetailId             TRecordId,
          @vFromLPNType                 TTypeCode,
          @vFromLPNLocationId           TRecordId,
          @vAvailLPNDetailId            TRecordId,
          @vSKUId                       TRecordId,

          @vQtyShortPicked              TQuantity,
          @vQtyToAdjust                 TQuantity,
          @vUpdateOption                TFlags,

          @vShortPick_UnallocateUnits   TControlValue,
          @vShortPick_AdjustQty         TControlValue,
          @vReasonCodeForLPNShortPick   TControlValue,
          @vReasonCodeForUnitsShortPick TControlValue,
          @vTranCount                   TCount;

  declare @ttPicksInfo                  TTaskDetailsInfoTable,
          @ttAuditTrailInfo             TAuditTrailInfo;
begin /* pr_Picking_ConfirmPicksAsShort */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vTranCount   = @@trancount;

  /* Input temp table may not have all the required information for processing.
     At the least it would have - TaskDetailId, FromLPNId and TDQuantity
     Get all the required info to process  */
  insert into @ttPicksInfo (FromLPNId, FromLPNDetailId, FromLPNType, FromLocationId, FromLocation,
                            OrderId, PickTicket, PickBatchId, PickBatchNo, SKUId, TDQuantity, ActivityType)
    select TD.LPNId, TD.LPNDetailId, FL.LPNType, FL.LocationId, FL.LocationId,
           OH.OrderId, OH.PickTicket, TD.WaveId, TD.PickBatchNo, TD.SKUId, TDQuantity, 'OrderShortPicked'
      from TaskDetails TD
        join @PicksInfo PI on (TD.TaskDetailId = PI.TaskDetailId)
        join LPNs FL on (TD.LPNId = FL.LPNId)
        join OrderHeaders OH on (TD.OrderId = OH.OrderId);

  /* Get controls */
  select @vShortPick_UnallocateUnits   = dbo.fn_Controls_GetAsString('ShortPick', 'UnallocateUnits', 'CurrentPick', @BusinessUnit, @UserId),
         @vShortPick_AdjustQty         = dbo.fn_Controls_GetAsString('ShortPick', 'ReduceInventory', 'None', @BusinessUnit, @UserId),
         @vReasonCodeForLPNShortPick   = dbo.fn_Controls_GetAsString('ShortPick', 'ReasonCodeForLPNShortPick', '120', @BusinessUnit, @UserId),
         @vReasonCodeForUnitsShortPick = dbo.fn_Controls_GetAsString('ShortPick', 'ReasonCodeForUnitsShortPick', '121', @BusinessUnit, @UserId);

  if (@vTranCount = 0) begin transaction;

  /* Loop thru each record and process it */
  while exists (select * from @ttPicksInfo where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId          = RecordId,
                   @vFromLPNId         = FromLPNId,
                   @vFromLPNDetailId   = FromLPNDetailId,
                   @vFromLPNType       = FromLPNType,
                   @vFromLPNLocationId = FromLocationId,
                   @vSKUId             = SKUId,
                   @vQtyShortPicked    = TDQuantity
      from @ttPicksInfo
      where (RecordId > @vRecordId)
      order by RecordId;

      /************************  Unallocate Picks  *************************/
      /* If the control var is set to un-allocate all picks from the LPN then unallocate whole LPN */
      if (@vShortPick_UnallocateUnits = 'AllPicks')
        exec pr_LPNs_Unallocate @vFromLPNId, default, 'N' /* unallocate Pallet */, @BusinessUnit, @UserId;
      else
        /* If the controls var is set to un-allocate current pick then unallocate current LPN detail only */
        exec pr_LPNDetails_Unallocate @vFromLPNId, @vFromLPNDetailId, @UserId, 'ShortPick';

      /*********************  update LPN Quantities  ***********************/
      /* If the control var says do nothing to the LPN quantities then continue with next record */
      if (@vShortPick_AdjustQty = 'DoNothing') continue;

      /* Compute the quantity to be reduced or Updated
         If AdjustQty option is 'Clear' then system will wipe out all the quantity from LPN if it is a picklane or
            marks the LPN as lost if it is other than picklane
         If AdjustQty option is 'CurrentPick' then system will reduce the current pick quantity from the LPN if it is a picklane or
            does nothing if it other than picklane LPN */
      if (@vShortPick_AdjustQty = 'Clear')
        select @vQtyToAdjust = 0,
               @vUpdateOption   = '=';
      else
      if (@vShortPick_AdjustQty = 'CurrentPick')
        select @vQtyToAdjust  = @vQtyShortPicked,
               @vUpdateOption = '-';

      /* If other than picklane LPN and AdjustQty option is 'Clear' then mark the LPN as lost */
      if (@vFromLPNType <> 'L' /* Logical/picklane */) and (@vShortPick_AdjustQty = 'Clear')
        exec pr_LPNs_Lost @vFromLPNId, @vReasonCodeForLPNShortPick, @UserId, 'Y' /* Clear Pallet */, 'LPNShortPicked' /* Audit Activity */;
      else
        /* If it is a picklane LPN then adjust the quantity on the LPN */
        begin
          /* Since we are unallocating the LPN/LPN Detail above, the reserved quantity will be
             added to the available line so, find an available line to adjust in the LPN */
          select top 1 @vAvailLPNDetailId = LPNDetailId
          from LPNDetails
          where (LPNId = @vFromLPNId) and
                (SKUId = @vSKUId) and
                (OnHandStatus = 'A' /* Available */)
          order by Quantity desc;

          /* Invoke proc to adjust the quantity */
          exec pr_LPNs_AdjustQty @vFromLPNId,
                                 @vAvailLPNDetailId output,
                                 @vSKUId,
                                 null,
                                 null,
                                 @vQtyToAdjust,
                                 @vUpdateOption,
                                 'Y',   /* Export? Yes */
                                 @vReasonCodeForUnitsShortPick,
                                 null,  /* Reference */
                                 @BusinessUnit,
                                 @UserId;
        end

      /* Create a cycle count task on short pick so that location can be cycle counted later if required */
      exec pr_Locations_CreateCycleCountTask @vFromLPNLocationId, 'ShortPick' /* Operation */, @UserId, @BusinessUnit;
    end

  /*********************  Log Audit Trail  ***********************/
  update @ttPicksInfo
  set ATComment = dbo.fn_Messages_BuildDescription('AT_' + ActivityType, 'LPN', FromLPN, 'ToLPN', ToLPN, 'DisplaySKU', SKU, 'Units', TDQuantity, 'Location', FromLocation, 'PTBatch', PickBatchNo + '/' + PickTicket);

  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1, Comment)
    /* From LPN */
    select distinct 'LPN', FromLPNId, FromLPN, ActivityType, @BusinessUnit, @UserId, RecordId, ATComment
    from @ttPicksInfo
    union
    /* From Location */
    select distinct 'Location', FromLocationId, FromLocation, ActivityType, @BusinessUnit, @UserId, RecordId, ATComment
    from @ttPicksInfo
    union
    select distinct 'PickTicket', OrderId, PickTicket, ActivityType, @BusinessUnit, @UserId, RecordId, ATComment
    from @ttPicksInfo
    union
    select distinct 'Wave', PickBatchId, PickBatchNo, ActivityType, @BusinessUnit, @UserId, RecordId, ATComment
    from @ttPicksInfo;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* If we have started the transaction then commit */
  if (@vTranCount = 0) commit transaction;
end try
begin catch
  /* If we have started the transaction then rollback, else let caller do it */
  if (@vTranCount = 0) rollback transaction;

  exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_ConfirmPicksAsShort */

Go
