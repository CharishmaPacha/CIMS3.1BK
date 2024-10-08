/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/11  VS      pr_Reservation_UpdateShipCartons: Need to get ReservedQty from #ToLPNDetails (HA-2732)
  2021/05/07  AY      pr_Reservation_UpdateShipCartons, pr_Reservation_ActivateShipCartons: Keep track
  2021/01/20  AY      pr_Reservation_UpdateShipCartons: Add activated LPNs to the Load
              TK      pr_Reservation_UpdateFromLPNs & pr_Reservation_UpdateShipCartons: recount pallets (HA-1934)
                      pr_Reservation_UpdateShipCartons: Evaluate LPN status and onhandstatus later (HA-1789)
  2020/12/07  RKC     pr_Reservation_UpdateShipCartons: Made changes to update the LPNs status as Packed (HA-1725)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_UpdateShipCartons') is not null
  drop Procedure pr_Reservation_UpdateShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_UpdateShipCartons: Once it is determined which ShipCartons
    to activate, we need to update the actual tables to reflect the activation.
    This procedure updates the LPN Details and LPNs of the activated ship cartons
    and recalculates them.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_UpdateShipCartons
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,
          @vToLPNId              TRecordId,
          @vLPNId                TRecordId,
          @vIsLPNActivated       TFlag;

  declare @ttLPNsToRecount       TRecountKeysTable,
          @ttPalletsToRecount    TRecountKeysTable;

begin /* pr_Reservation_UpdateShipCartons */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vIsLPNActivated = 'Y' /* default - yes */;

  /* Check if any SKU of Ship Carton is not activated for any reason */
  if (exists (select * from #ToLPNDetails where ProcessedFlag <> 'A' /* Activate */))
    begin
      set @vMessageName = 'LPNActv_ShipCartons_ActivationUnsuccessful';

      insert into #ResultMessages (MessageType, MessageName, Value1, Value2, Value3, Value4)
        select 'E' /* Error */, 'LPNActivation_InvShortToActivate', min(S.SKU), min(S.Description),
               sum(TLD.Quantity - TLD.ReservedQty), min(TLD.InventoryClass1)
        from #ToLPNDetails TLD
          join SKUs S on S.SKUId = TLD.SKUId
        where (TLD.ProcessedFlag <> 'A')
        group by TLD.KeyValue;
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Activate all the generated labels */
  update L
  set L.Status       = 'D' /* Packed */,
      L.OnhandStatus = 'R' /* Reserved */
  from LPNs L
    join #ToLPNDetails TLL on (L.LPNId = TLL.LPNId)
  where (TLL.ProcessedFlag = 'A' /* Activate */);

  /* Update the LPN Details onhand status from Unavailable to Reserved */
  update LD
  set OnhandStatus = 'R' /* Reserved */,
      ReservedQty  = TLL.Quantity
  from LPNDetails LD
    join #ToLPNDetails TLL on LD.LPNDetailId = TLL.LPNDetailId
  where (TLL.ProcessedFlag = 'A' /* Activate */);

  /* Populate temporary LPNIds to Recount */
  insert into @ttLPNsToRecount (EntityId)
    select distinct LPNId
    from #ToLPNDetails
    where (ProcessedFlag = 'A' /* Activated */);

  /* Recalc LPNs */
  exec pr_LPNs_Recalculate @ttLPNsToRecount, 'C' /* Recount */;

  /* TODO (FUTURE Enhancement) */
  /* Scope for future: We need to re-think all our options here at the end */

  /* Add activated LPNs to the Load */
  while (exists (select * from @ttLPNsToRecount where RecordId > @vRecordId))
    begin
      select top 1 @vLPNId    = EntityId,
                   @vRecordId = RecordId
      from @ttLPNsToRecount
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_LPNs_AddToALoad @vLPNId, @BusinessUnit, 'Y' /* Recount Load/Shipment/BoL */, @UserId;
    end

  /* Recount Pallets */
  insert into @ttPalletsToRecount (EntityId)
    select distinct L.PalletId
    from @ttLPNsToRecount LTR join LPNs L on (LTR.EntityId = L.LPNId)

  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'C', @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_UpdateShipCartons */

Go
