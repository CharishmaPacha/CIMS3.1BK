/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetDetailsToPack_SLB') is not null
  drop Procedure pr_Packing_GetDetailsToPack_SLB;
Go
/*------------------------------------------------------------------------------
  pr_Packing_GetSLBDetailsToPack: Typically, an Order is picked and then the
    picked units are packed. However for a SLB Wave (a Wave that has a
    Bulk Order on it), the units are picked against the Bulk Order but the
    actual Customer order is the one that is being packed i.e. nothing would
    have been picked against the Order being packed. Hence this procedure is
    to merge the units need to pack from the original order details and the
    picked qty of the associated Bulk Order.

   This procedure will also retrives the information related to order shipvia
   and ShipTo information which we need to display in SLB packing screen.

   NOTE: In this procedure, we will distribute teh Picked Quantity to all customer orders in the wave and do not show the
   orders to user in Packing screen if there is no inventory available/picked for that order to pack. To define this we are
   cumulating the customer order quantity and remove the orders if picked quantity is lessthan order cumulative quantity.

   PackGroupKey - We did not included OrderId into it as Inventory picked against Bulk Order and Packing against Customer order.
   This filed is not used for grouping in UI and using to identify the Picked LPNDetails to pack against the Customer orders

  #ttSelectedEntities:
  #PackingDetails:
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetDetailsToPack_SLB
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,

          @vOrderId                    TRecordId,
          @ValidOrderId                TRecordId,
          @vBulkOrderId                TRecordId,
          @vWaveId                     TRecordId,
          @vWaveNo                     TWaveNo,
          @vBusinessUnit               TBusinessUnit,
          @vShowLinesWithNoPickedQty   TFlag,
          @vShowComponentSKUsLines     TFlag,
          @vInputParams                TInputParams,
          @vOutputXML                  TXML,
          @vActivityLogId              TRecordId,
          @vDebug                      TFlags;

begin
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vOrderId       = null;

  /* Get Debug Options */
  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  select @vShowComponentSKUsLines   = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowComponentSKUsLines', 'N', @vBusinessUnit, null /* UserId */);

  /* Should be created by caller, else exit */
  if (object_id('tempdb..#PackingDetails') is null) return;

  /* Loop through all selected entities - So far we will only have one entity i,e Order/bulk order. For SLB wave, we will only have bulk order */
  select @vWaveId = EntityId,
         @vWaveNo = Entitykey
  from #ttSelectedEntities
  where (EntityType = 'Wave');

  /* get the bulk order from wave */
  --select @vBulkOrderId = BulkOrderId
  --from Waves
  --where (WaveId = @vWaveId);

  select @vBulkOrderId = OrderId
  from OrderHeaders
  where (PickBatchId = @vWaveId) and
        (OrderType   = 'B' /* Bulk */);

  /* This proc will hit only when scanned entity is related to SLB Wave. Do not process if there is no wave found in Selected entities */
  if (@vWaveId is null) return;

  /* retrive the view information into hash table as we need to hit them again and again later */
  select * into #vwOrderToPackDetails from vwOrderToPackDetails where (WaveId = @vWaveId);
  select * into #vwBulkOrderToPackDetails from vwBulkOrderToPackDetails where (WaveId = @vWaveId);

  /* Load the original order details for all orders on the wave
     vwOrderToPackDetails includes the already packed lines as well as it has join with LPNDetails and so
     we get duplicate lines, so instead using vwBulkOrderToPackDetails */
  insert into #PackingDetails
    select *
    from #vwOrderToPackDetails
    where (WaveId = @vWaveId) and
          (Status in ('P', 'W' /* Picked, Waved */)) and
          (OrderType <> 'B' /* Bulk */) and
          (UnitsToAllocate > 0)
    order by Priority;

  /* Add cumulative required quantity of each SKU on each order, it will return the table like below
     We then use the lag to determine what units would remain after previous line is satisfied
     and compute the unitstopack

     OrderDetailId  SKUId  UnitsToAllocate SKUCumulativeQty Priority PickedQty Lag* UnitsToPack
     O1             SKU1   1               1                1        6         6    1
     O2             SKU1   2               3                1        6         5    2
     O3             SKU1   1               4                1        6         3    1
     O4             SKU1   3               7                2        6         2    2
     O5             SKU1   2               9                3        6        -1    -1
     */
  select PD.OrderDetailId, PD.SKUId, min(PD.UnitsToAllocate) as UnitsToAllocate, PD.Priority,
         sum(min(PD.UnitsToAllocate)) over(partition by PD.OrderDetailId, PD.SKUId) as SKUCumulativeQty,
         sum(BPD.PickedQuantity) as BulkPickedQty
  into #PackRequirements
  from #PackingDetails PD
    join #vwOrderToPackDetails BPD on (BPD.SKUId = PD.SKUId) and (BPD.OrderId = @vBulkOrderId) and
                                      (BPD.UnitsAssigned > 0) and (BPD.LPNStatus in ('K', 'G' /* Picked, Packing */))
  group by PD.OrderDetailId, PD.SKUId, PD.Priority
  order by PD.Priority;

  /* The lag function gives the data from the previous row. Here, we use it to get the
     Units Remaining to Pack after the previous line would have been packed
     i.e. BulkedPickedQty - SKUCumulativeQty from previous row woud tell us how many units
     remain to be packed. so for the current line the units to pack would be min of the unitstoallocate
     and the units remaining to pack

     lag(BulkPickedQty - SKUCumulativeQty -- Units Remaining To Pack,
         1                                -- from previous row
         BulkPickedQty)                   -- Is the value for the first row (which would not have previous row
     */
  select *,
         dbo.fn_MinInt(UnitsToAllocate, lag(BulkPickedQty - SKUCumulativeQty, 1, BulkPickedQty)
                                        over(partition by SKUId order by Priority, OrderDetailId)) as UnitsToPack
  into #OrderDetailsToPack
  from #PackRequirements;

  update PD
  set PD.PickedQuantity = ODTP.UnitsToPack,
      PD.UnitsToPack    = ODTP.UnitsToPack
  from #PackingDetails PD
    join #OrderDetailsToPack ODTP on (ODTP.OrderDetailId = PD.OrderDetailId) and (ODTP.UnitsToPack > 0);

  if (charindex('D', @vDebug) > 0) select * from #PackRequirements;
  if (charindex('D', @vDebug) > 0) select * from #OrderDetailsToPack;
  if (charindex('D', @vDebug) > 0) select * from #PackingDetails;

  /* delete the orders which don't have enough quantity to pack */
  delete #PackingDetails where UnitsToPack <= 0;

  /* get the pick information from the bulk order details */
  update #PackingDetails
  set PalletId           = OPD.PalletId,
      Pallet             = OPD.Pallet,
      LPNId              = OPD.LPNId,
      LPN                = OPD.LPN,
      LPNDetailId        = OPD.LPNDetailId,
      PickedFromLocation = OPD.PickedFromLocation,
      PickedBy           = OPD.PickedBy,
      SerialNo           = OPD.SerialNo
  from #vwOrderToPackDetails OPD
  where (OPD.OrderId = @vBulkOrderId) and (#PackingDetails.SKUId = OPD.SKUId);

  /* If same SKU is picked into multiple cart positions then get them in csv format.
     We are not considering FromLPN from UI while closing the package, based on Packing group,
     we are identifying from lpn details on close package itself */
  with SKUCartPositions
  as
  (
    select SKUId, string_agg(LPN, ', ') as FromLPNList
    from #vwOrderToPackDetails PD1
    where (OrderId = @vBulkOrderId) and
          (LPNStatus in ('K', 'G' /* Picked, Packing */))
    group by SKUId
  )
  update PD
  set PD.LPN = left(SCP.FromLPNList, 50)
  from #PackingDetails PD
    join SKUCartPositions SCP on (SCP.SKUId = PD.SKUId);

  /* update the pack group key. Did not included OrderId here, as inventory is picked against Bulk order and packing against customer order */
  update #PackingDetails set PackGroupKey = concat_ws('-', OrderId, SKUId);

  /* Update the cubed carton details - assumption that every SLB order will be cubed into single order */
  update PD
  set CubedCarton       = L.LPN,
      CubedCartonType   = L.CartonType,
      CubedCartonWeight = L.EstimatedWeight,
      IsCubed           = 'YES'
  from #PackingDetails PD
    join LPNs L on (L.OrderId = PD.OrderId) and (L.LPNType = 'S' /* Ship Carton */) and (L.Status = 'F');

  /* Delete component lines if not required to show */
  if (@vShowComponentSKUsLines = 'N')
    delete from #PackingDetails where (LineType = 'C' /* Component SKU */);

end /* pr_Packing_GetDetailsToPack_SLB */

Go
