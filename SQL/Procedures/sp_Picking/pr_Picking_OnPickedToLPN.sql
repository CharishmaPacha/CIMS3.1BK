/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  MS      pr_Picking_OnPickedToLPN: Changes to update Pallet Status after LPN Recount (BK-319)
  2021/04/09  RV/AY   pr_Picking_OnPickedToLPN, pr_Picking_OnPicked : Made changes to update the inventory class1 based upon the rules (HA-2580)
  2020/10/20  SK      pr_Picking_OnPicked, pr_Picking_OnPickedToLPN: Modified to include FromLPN, FromLocation and option to send pick transaction
  2020/10/19  TK      pr_Picking_OnPickedToLPN: Recount LPN instead of just updating status (HA-1588)
  2020/01/24  AY      pr_Picking_OnPickedToLPN: performance optimization
                      pr_Picking_OnPickedToLPN: Bug fix not to clear PalletId on Picked LPN (S2GCA-534)
  2018/04/11  AY      pr_Picking_OnPickedToLPN: Enhanced to use rules for To LPN Status
                      pr_Picking_OnPickedToLPN: Changes to update the WaveDropLocation in Routing Instructions (S2G-587)
  2016/11/13  VM      pr_Picking_ConfirmTaskPicks, pr_Picking_OnPickedToLPN, pr_Picking_ConfirmTaskPicks_LogAuditTrail: (HPI-993)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_OnPickedToLPN') is not null
  drop Procedure pr_Picking_OnPickedToLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_OnPickedToLPN: When an LPN is picked or all items are finally
   picked into the LPN, there are several things to be accomplished which includes
   sending the information to the Sorter/Router/Panda as well as may be recalculating
   weight of the LPN and/or adding to the Load. This procedure encapsulates on all
   such consequential updates to be done.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_OnPickedToLPN
  (@PickBatchNo       TPickBatchNo,
   @OrderId           TRecordId,
   @PalletId          TRecordId,
   @LPNId             TRecordId,
   @NewLPNStatus      TStatus,
   @UnitsPicked       TQuantity,
   @RecalcWave        TFlags = 'N' /* No */,
   @RecalcOrder       TFlags = 'N' /* No */,
   @ActivityType      TActivityType = 'UnitPick',
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vReturnCode             TInteger,

          @vBatchType              TTypeCode,

          /* Order */
          @vOrderId                TRecordId,
          @vOrderType              TTypeCode,
          @vOrderStatus            TStatus,
          @vNewOrderStatus         TStatus,
          @vOrderWarehouse         TWarehouse,
          @vAccount                TAccount,
          @vOwnership              TOwnership,

          @vOpenPicksForToLPN      TCount,

          /* LPN */
          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vDestZone               TZoneId,
          @vPalletId               TRecordId,
          @vLPNShipmentId          TRecordId,
          @vLPNLoadId              TRecordId,
          @vLPNTaskDetailId        TRecordId,
          @vSKUId                  TRecordId,
          @vPickBatchId            TRecordId,
          @vAlternateLPN           TLPN,

          /* Audit Log */
          @ActivityDate            TDateTime,

          /* Common */
          @vDefaultDropLocation    TLocation,
          @vWaveDropLocation       TLocation,
          @vPickingPalletId        TRecordId,
          @vNewLPNStatus           TStatus,
          @vRecalculateLPNWeight   TControlValue,
          @vAvailReserveLineId     TRecordId,

          /* Rules */
          @vExportToPanda          TResult,
          @vExportToSorter         TResult,
          @vExportToRouter         TResult,
          @vExportToHost           TResult,
          @vAssignLPNToLoad        TResult,
          @xmlRulesData            TXML,

          /* Temp Tabel */
          @ttPickedLPNs            TEntityKeysTable;

begin /* pr_Picking_OnPickedToLPN */
  select @ActivityDate = current_timestamp;

  /* Get Batch info */
  select @vPickBatchId      = RecordId,
         @vBatchType        = BatchType,
         @vWaveDropLocation = DropLocation
  from PickBatches
  where (BatchNo = @PickBatchNo)

  /* Get Order info */
  select @vOrderId        = OrderId,
         @vOrderType      = OrderType,
         @vOrderStatus    = Status,
         @vAccount        = Account,
         @vOwnership      = Ownership,
         @vOrderWarehouse = Warehouse
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get LPN info */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vLPNShipmentId = nullif(ShipmentId, 0),
         @vLPNLoadId     = nullif(LoadId, 0),
         @vPalletId      = PalletId,
         @vDestZone      = DestZone,
         @vAlternateLPN  = AlternateLPN
  from LPNs
  where (LPNId = @LPNId);

  /* Get the number of open picks for the ToLPN */
  select @vOpenPicksForToLPN = count(*)
  from TaskDetails
  where (TempLabelId = @vLPNId) and (Status not in ('X' /* Canceled */, 'C' /* Completed */));

  /* Update LPN DestLocation to as replenished Location, if the Order type is replenish Order */
  if (@vOrderType in ('RU', 'RP', 'R' /* Replenish Units, Replenish Cases */))
    exec pr_LPNs_SetDestination @LPNId, 'ReplenishPick';

  /* Prepare XML for rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation',      'OnPicked')   +
                         dbo.fn_XMLNode('WaveNo',         @PickBatchNo) +
                         dbo.fn_XMLNode('WaveType',       @vBatchType)  +
                         dbo.fn_XMLNode('OrderId',        @vOrderId)    +
                         dbo.fn_XMLNode('OrderType',      @vOrderType)  +
                         dbo.fn_XMLNode('Account',        @vAccount)    +
                         dbo.fn_XMLNode('Ownership',      @vOwnership)  +
                         dbo.fn_XMLNode('Warehouse',      @vOrderWarehouse) +
                         dbo.fn_XMLNode('OpenPicks',      @vOpenPicksForToLPN) +
                         dbo.fn_XMLNode('LPNShipmentId',  @vLPNShipmentId)  +
                         dbo.fn_XMLNode('LPNLoadId',      @vLPNLoadId) +
                         dbo.fn_XMLNode('LPNId',          @vLPNId) +
                         dbo.fn_XMLNode('LPN',            @vLPN) +
                         dbo.fn_XMLNode('BusinessUnit',   @BusinessUnit) +
                         dbo.fn_XMLNode('UserId',         @UserId) +
                         dbo.fn_XMLNode('ActivityType',   @ActivityType));

  /* Apply the rules to get decisions for various scenarios */
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToPanda',  @xmlRulesData, @vExportToPanda   output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToSorter', @xmlRulesData, @vExportToSorter  output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToRouter', @xmlRulesData, @vExportToRouter  output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_ExportToHost',   @xmlRulesData, @vExportToHost    output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_AssignToLoad',   @xmlRulesData, @vAssignLPNToLoad output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_RecalcWeight',   @xmlRulesData, @vRecalculateLPNWeight output;
  exec pr_RuleSets_Evaluate 'OnPicked_ToLPN_Status',         @xmlRulesData, @vNewLPNStatus output;
  -- none of these are needed for HPI, so we will do this later

  /* Update alternate LPN on the cart position too */
  update LPNs set AlternateLPN = null where (LPN = @vAlternateLPN) and (BusinessUnit = @BusinessUnit);

  /* Update Status, OnhandStatus of LPN */
  exec pr_LPNs_Recount @LPNId, @UserId, @vNewLPNStatus;

  /*---- LPN Status has to be updated before it is added to Pallet so that Pallet status would be right ---- */

  /* If LPN is not already on the picking pallet, locate it onto Picking Pallet */
  if (@PalletId is not null) and (coalesce(@vPalletId, 0) <> @PalletId)
    exec pr_LPNs_SetPallet @vLPNId, @PalletId, @UserId
  else
  if (@vPalletId is null)
    exec pr_LPNs_SetPallet @vLPNId, null, @UserId;

  /* Update weight on LPNDetail if it is LPNPick and call the LPN Recount procedure to update the weight over LPN.
     Generally, we can update directly over LPN without updating on its detail. But to be accurate we are updating
     on Detail and calling the Recount procedure */
  if (@vRecalculateLPNWeight = 'Y' /* Yes */)
    exec pr_LPNs_RecalculateWeightVolume @LPNId, @UserId;

  /* Drop the Picked LPN to default Shipping/Drop Location */
  exec pr_RuleSets_Evaluate 'OnPicked_DropLocation', @xmlRulesData, @vDefaultDropLocation output;

  /* Update the LPN Location */
  if (@vDefaultDropLocation is not null)
    exec pr_LPNs_SetLocation @vLPNId, null /* Location Id */, @vDefaultDropLocation, 'L' /* Update Option */;

  /* If the LPN is not associated with a Shipment or Load, then find one and add to it */
  if (@vAssignLPNToLoad = 'Y' /* Yes */)
    exec pr_LPNs_AddToALoad @vLPNId, @BusinessUnit, 'Y' /* Yes - @LoadRecount */, @UserId;

  /* Set PickTicket Header Counts and Status */
  if (@RecalcOrder = 'Y' /* Yes */)
    exec @vReturnCode = pr_OrderHeaders_Recount @vOrderId, null /* PickTicket */, @vNewOrderStatus output;

  /* Recalculate batch counts and status */
  if (@RecalcWave = 'Y' /* Yes */) and (@PickBatchNo is not null)
    begin
      exec pr_PickBatch_UpdateCounts @PickBatchNo, '$TL' /* Recalculate the LPNs and Tasks */
      exec pr_PickBatch_SetStatus @PickBatchNo, '$' /* Defer Status update */, @UserId;
    end

  /* When picking to an LPN is complete, then export the transactions to the Host.
     In this scenario, we export all the LPNDetails of the given LPN, but we don't
     have the details of where they were picked from. If that information is needed
     then we have to use DuringPicking option */
  if (@vExportToHost = 'OnPickingComplete')
     exec @vReturnCode = pr_Exports_LPNData 'Pick', 'LPN', null /* TransQty */,
                                            @LPNId = @vLPNId;

  /* Export to Panda if LPNs are picked */
  if (@vExportToPanda = 'Y')
    exec pr_PandA_AddLPNForExport @vLPN /* LPN */, @ttPickedLPNs,
                                  default /* LabelType */, default /* Label format */,
                                  null /* PandAStation */, null /* ProcessMode */,
                                  default /* DeviceId */, @BusinessUnit, @UserId;

  if (@vExportToSorter <> 'N' /* No */)
    begin
      exec pr_Sorter_InsertLPNDetails @vLPNId, @ttPickedLPNs, null /* Sorter Name */,
                                      @BusinessUnit, @UserId;

      /* Export the Picked LPNDetails to the Sorter if ExportToSorter is to be done on Picked */
      if (@vExportToSorter in ('P' /* On Picked */))
        exec pr_Sorter_ExportLPNDetails @vLPNId, null /* Sorter Name */, @BusinessUnit, @UserId;
    end

  /* Insert the Router Instruction into RouterInstruction table */
  if (@vExportToRouter in ('Y' /* Yes */, 'P' /* On Picked */))
    exec pr_Router_SendRouteInstruction @vLPNId, @vLPN, @ttPickedLPNs,
                                        @vWaveDropLocation /* Destination */, default /* WorkId */, 'N' /* @ForceExport */,
                                        @BusinessUnit, @UserId;

  /* Execute rules for things to happen when LPN is picked */
  exec pr_RuleSets_ExecuteAllRules 'OnPicked', @xmlRulesData, @BusinessUnit;

end /* pr_Picking_OnPickedToLPN */

Go
