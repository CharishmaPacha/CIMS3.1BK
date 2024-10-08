/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/06  TK      pr_Reservation_UpdateFromLPNs: Changes to delete consumed LPN Details (BK-265)
                      pr_Reservation_UpdateFromLPNs: Bug fix in deducting reserved quantities (HA-2170)
  2021/02/25  TK      pr_Reservation_UpdateFromLPNs: Bug Fix to recount pallets properly (BK-226)
              TK      pr_Reservation_UpdateFromLPNs & pr_Reservation_UpdateShipCartons: recount pallets (HA-1934)
  2021/01/17  TK      pr_Reservation_UpdateFromLPNs: Changes made to reduce reserved quantity on from LPN
                      pr_Reservation_UpdateFromLPNs: Deduct quantity based on LPNDetailId
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_UpdateFromLPNs') is not null
  drop Procedure pr_Reservation_UpdateFromLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_UpdateFromLPNs: Once it has been determined which from LPNs
   to deduct the inventory from, this procedure is invoked to do the actual
   updates on the From LPNs. This reduces the qty on the FromLPN Details with
   the reserved qty and recounts the LPNs.

  If the FromLPN end ups being consumed, then the OnConsume procedure is called
  to clear the Location etc and update the location counts of the From LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_UpdateFromLPNs
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId;

  declare @ttLPNsToRecount       TRecountKeysTable,
          @ttPalletsToRecount    TRecountKeysTable;
begin /* pr_Reservation_UpdateFromLPNs */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Deduct inventory from LPN Detail */
  update LD
  set LD.Quantity    -= FLD.ReservedQty,
      LD.InnerPacks  -= case when LD.InnerPacks > 0 and LD.UnitsPerPackage > 0 then FLD.ReservedQty / LD.UnitsPerPackage else 0 end,
      LD.ReservedQty = dbo.fn_MaxInt(LD.ReservedQty - FLD.ReservedQty, 0)  -- At HA, activating ship cartons will deduct available quantity from picklanes so they will not have any reserved quantity updated on it
  from LPNDetails LD
    join #FromLPNDetails FLD on LD.LPNDetailId = FLD.LPNDetailId
  where (FLD.ReservedQty > 0);

  /* Delete the LPN Details whose quantity is '0' */
  delete LD
  from LPNDetails LD
    join #FromLPNDetails FLD on LD.LPNDetailId = FLD.LPNDetailId
  where (LD.Quantity = 0);

  /* Recount of From LPNs - Single SKU vs Multi SKU */
  insert into @ttLPNsToRecount(EntityId)
    select distinct LPNId from #FromLPNDetails where ReservedQty > 0;

  /* Get the Pallets to recount */
  /* We need to get the pallets before the LPNs are consumed, because once they are consumed we will clear pallet info */
  insert into @ttPalletsToRecount (EntityId)
    select distinct L.PalletId
    from @ttLPNsToRecount LTR join LPNs L on (LTR.EntityId = L.LPNId)
    where PalletId is not null;

  /* Invoke proc to Recount LPNs */
  exec pr_LPNs_Recalculate @ttLPNsToRecount, 'CO' /* C = Recount;  O = On Consume */;

  /* Invoke proc to Recount Pallets */
  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'C', @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_UpdateFromLPNs */

Go
