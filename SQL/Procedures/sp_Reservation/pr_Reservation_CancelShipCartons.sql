/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/28  PKK     pr_Reservation_CancelShipCartons: Updated the ProcessFlag on #LPNDetails to 'Y', when LPNs are voided (HA-2701)
  2021/05/19  MS      pr_Reservation_CancelShipCartons: Changes to void ShipLabels while voiding Temp LPNs (HA-2751)
  2021/05/14  SK      pr_Reservation_CancelShipCartons: Re evaluate Pallet Count after canceling Ship carton (HA-2734)
  2021/05/02  TK      pr_Reservation_CancelShipCartons: Bug fix AT not being logged on PickTicket (HA-2720)
  2021/04/15  AY      pr_Reservation_CancelShipCartons: Revert LPNs to Bulk PT (HA-2596)
  2021/03/18  TK      pr_Reservation_CancelShipCartons: Update load & shipment ids with '0' (HA-GoLive)
  2021/03/18  SK      pr_Reservation_CancelShipCartons: Updated the correct operation name to be sent for voiding LPNs (HA-2319)
  2021/03/17  MS      pr_Reservation_UpdateShipCartons: Code optimization (HA-1935)
                      pr_Reservation_CancelShipCartons: Caller changes to Load & Shipment
  2021/03/05  PK      pr_Reservation_CancelShipCartons: Ported changes done by Pavan (HA-2152)
  2021/03/02  AY      pr_Reservation_CancelShipCartons: Code review, Debugging of Activation procs
  2021/02/26  PK      Added pr_Reservation_CancelShipCartons, pr_Reservation_CancelActivatedLPNs,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_CancelShipCartons') is not null
  drop Procedure pr_Reservation_CancelShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_CancelShipCartons: Shipping cartons for an Order may have
   to be unallocated, voided or reverted backed to picked. To make sure the right
   this is done rather than depending upon the user to make the right choice, we
   have a wrapper called Cancel Ship Cartons.

  If the ship cartons are in New Temp Status - they are just voided
  If the ship cartons are Packed/Staged for an Order which is on a bulk Wave, then
    the carton is unallocated from the customer order and reverted to the Bulk order
  If the ship cartons are packed/staged for a Customer order and there is no bulk
    order, then the LPN is just unallocated from the Order.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_CancelShipCartons
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,

          @EntityXML              TXML,
          @xmlResult              TXML,

          @ttLPNsToRecount        TRecountKeysTable,
          @ttOrdersToRecount      TEntityKeysTable,
          @ttWavesToRecalc        TEntityKeysTable,
          @ttShipmentsToRecount   TEntityKeysTable,
          @ttLoadsToRecount       TEntityKeysTable,
          @ttPalletsToUpdate      TRecountKeysTable,
          @ttShipLabelsToVoid     TEntityKeysTable;
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the list of NewTemp Status LPNs in XML Format to void */
  select @EntityXML = (select distinct LD.LPNId
                       from #LPNDetails LD
                       where (LPNStatus = 'F' /* New Temp */)
                       for XML Path('LPNContent'), Root('LPNs'));

  if (@EntityXML is not null)
    begin
      /* Build FinalXML to send to Void LPN caller */
      select @EntityXML = '<ModifyLPNs>
                             <Data>
                               <Operation>LPNShipCartonCancel</Operation>
                               <ReasonCode>Default</ReasonCode>
                               <Reference>CancelShipCartons</Reference>
                               <BusinessUnit>' + coalesce(@BusinessUnit, '') + '</BusinessUnit>
                               <UserId>' + coalesce(@UserId, '') + '</UserId>
                            </Data>' +
                            coalesce(@EntityXML, '') +
                          '</ModifyLPNs>'

      /* Void the labels */
      exec @vReturnCode = pr_LPNs_Void @EntityXML, @BusinessUnit, @UserId, 'Void' /* ReasonCode */,
                                       null /* ReceiverNumber */, 'VoidLPNs' /* Operation */, @xmlResult output;
    end

  /* Mark the LPNs as processed */
  update LD
  set ProcessedFlag = 'Y' /* Yes */
  from #LPNDetails LD
    join LPNs L on (LD.LPNId = L.LPNId)
  where L.Status in ('V' /* Voided */);

  /* Update the BulkOrderId of the Wave for the LPNs. Note that sometimes there may not be a Bulk Order */
  update LD
  set LD.BulkOrderId    = OH.OrderId,
      LD.BulkPickTicket = OH.PickTicket
  from #LPNDetails LD
    join OrderHeaders OH on (LD.WaveId = OH.PickBatchId)
  where (OH.OrderType = 'B' /* Bulk */) and
        (OH.Status not in ('D', 'X' /* Completed/Canceled */)) and
        (LD.ProcessedFlag = 'N' /* No */);

  /* Assign the LPNs to the Bulk OrderId & OrderDetailId */
  update LD
  set LD.OrderId       = TLD.BulkOrderId,
      LD.OrderDetailId = OD.OrderDetailId
  from LPNDetails LD
    join #LPNDetails TLD on (LD.LPNDetailId      = TLD.LPNDetailId   )
    join OrderDetails OD on (TLD.BulkOrderId     = OD.OrderId        ) and
                            (TLD.SKUId           = OD.SKUId          ) and
                            (TLD.InventoryClass1 = OD.InventoryClass1) and
                            (TLD.InventoryClass2 = OD.InventoryClass2) and
                            (TLD.InventoryClass3 = OD.InventoryClass3)
  where (TLD.ProcessedFlag = 'N' /* No */);

  /* Update Bulk OrderDetail UnitsAssigned when cancelling the activated shiplabels */
  ;with BulkOrderDetails (OrderId, OrderDetailId, Quantity)
   as
   (
    select OD.OrderId, OD.OrderDetailId, sum(TLD.Quantity)
    from OrderDetails OD
    join #LPNDetails TLD on (TLD.BulkOrderId     = OD.OrderId) and
                            (TLD.SKUId           = OD.SKUId) and
                            (TLD.InventoryClass1 = OD.InventoryClass1) and
                            (TLD.InventoryClass2 = OD.InventoryClass2) and
                            (TLD.InventoryClass3 = OD.InventoryClass3)
    where (TLD.ProcessedFlag = 'N' /* No */)
    group by OD.OrderId, OD.OrderDetailId
   )
  update OD
  set OD.UnitsAssigned         += BOD.Quantity,
      OD.UnitsAuthorizedToShip += BOD.Quantity
  from OrderDetails OD
    join BulkOrderDetails BOD on (OD.OrderId = BOD.OrderId) and
                                 (OD.OrderDetailId = BOD.OrderDetailId);

  /* Update Customer OrderDetails by decrementing UnitsAssigned since user requested
     to cancel the shiplabels */
  ;with CustOrderDetails (OrderId, OrderDetailId, Quantity)
   as
   (select TLD.OrderId, TLD.OrderDetailId, sum(Quantity)
    from #LPNDetails TLD
    where (TLD.ProcessedFlag = 'N' /* No */)
    group by TLD.OrderId, TLD.OrderDetailId
   )
   update OD
   set OD.UnitsAssigned -= COD.Quantity
   from OrderDetails OD
     join CustOrderDetails COD on (COD.OrderId       = OD.OrderId) and
                                  (COD.OrderDetailId = OD.OrderDetailId);

  /* Clear information on the LPNs and also update the statuses and type */
  update L
  set L.LPNType      = 'C' /* Carton */,
      L.Status       = 'K' /* Picked */,
      L.OrderId      = TLD.BulkOrderId,
      L.PickTicketNo = TLD.BulkPickTicket,
      L.PalletId     = null,
      --L.Pallet     = null,
      --L.UCCBarcode = null,
      --L.TrackingNo = null,
      L.BoL          = null,
      L.LoadId       = 0,
      --L.LoadNumber = null,
      L.ShipmentId   = 0
  from LPNs L
    join #LPNDetails TLD on (L.LPNId = TLD.LPNId)
  where (TLD.ProcessedFlag = 'N' /* No */);

  /* Recount of From LPNs - Single SKU vs Multi SKU */
  insert into @ttLPNsToRecount(EntityId)
    select distinct LPNId from #LPNDetails where Quantity > 0 and ProcessedFlag = 'N' /* No */;

  /* Recount From LPNs */
  exec pr_LPNs_Recalculate @ttLPNsToRecount, 'C' /* Recount */;

  /* Mark the records as processed */
  update LD
  set LD.ProcessedFlag = 'Y' /* Yes */
  from #LPNDetails LD
  where (LD.ProcessedFlag = 'N' /* No */);

  /* Get all the shiplabels if they exist and void them */
  insert into @ttShipLabelsToVoid(EntityId)
    select distinct LPNId
    from #LPNDetails LD
      join Shiplabels SL on LD.LPNId = SL.EntityId and
                            SL.EntityType = 'L' /* LPN */ and
                            SL.Status <> 'V' /* Voided */
    where (ProcessedFlag = 'Y' /* Yes */);

  /* Void labels if exists */
  if (exists (select * from @ttShipLabelsToVoid))
    exec pr_Shipping_VoidShipLabels null /* Order Id */, null /* LPNId */, @ttShipLabelsToVoid, @BusinessUnit,
                                    default /* RegenerateLabel - No */, @vMessage output;

  /* Recalc Pallets */
  insert into @ttPalletsToUpdate(EntityId)  select distinct PalletId from #LPNDetails;
  exec pr_Pallets_Recalculate @ttPalletsToUpdate, 'C' /* Update count */, @BusinessUnit, @UserId;

  /* Recount Orders */
  insert into @ttOrdersToRecount(EntityId)
    select distinct OrderId from #LPNDetails
    union
    select distinct BulkOrderId from #LPNDetails

  exec pr_OrderHeaders_Recalculate @ttOrdersToRecount, 'S' /* Status */, @UserId;

  /* Recalc Waves */
  insert into @ttWavesToRecalc (EntityId, EntityKey) select distinct WaveId, WaveNo from #LPNDetails;
  exec pr_PickBatch_Recalculate @ttWavesToRecalc, '$S' /* Defer & Compute Status only */, @UserId, @BusinessUnit;

  /* Recalc Shipments */
  insert into @ttShipmentsToRecount(EntityId) select distinct ShipmentId from #LPNDetails;
  exec pr_Shipment_Recalculate @ttShipmentsToRecount, default, @BusinessUnit, @UserId;

  /* Recalc Loads */
  insert into @ttLoadsToRecount(EntityId) select distinct LoadId from #LPNDetails;
  exec pr_Load_Recalculate @ttLoadsToRecount;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_CancelShipCartons */

Go
