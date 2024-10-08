/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/07  AY      pr_Reservation_UpdateShipCartons, pr_Reservation_ActivateShipCartons: Keep track
  2021/04/15  AY      pr_Reservation_ActivateShipCartons: performance optimization (HA-2642)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_ActivateShipCartons') is not null
  drop Procedure pr_Reservation_ActivateShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_ActivateShipCartons: This procedure is to activate selected
    ship cartons. i.e. the Ship Cartons are already determined and to activate them
    we need to find the matchin FromLPN to deduct the inventory. The match is by
    SKU and inventory class. ToLPNDetails may be for multiple details of single LPN
    or of several LPNs.

  Inputs:
    #ToLPNDetails - the LPN details of the ShipCartons to be activated
    #FromLPNDetails - the LPN details of the available inventory to consume

  Assumptions:
    - All validations are taken care of before this call is made
    - Post validations are also taken care by caller i.e. the ToLPN is not partially activated etc.

  Process:
    Loop through #ToLPNs details and deduct the respective quantity from #FromLPNs details.
    Inventory may be deducted from several #FromLPNDetails until all necessary inventory is deducted
    Each ToLPNDetail that is completely activated is flagged with ProcessFlag of 'A'
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_ActivateShipCartons
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Debug            TFlags = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vToLPNSKUId        TRecordId,
          @vToLPNQuantity     TQuantity,
          @vTotalReservedQty  TQuantity,
          @vKeyValue          TVarchar,

          @vAllocableQty      TQuantity,
          @vFromLPNDetailId   TRecordId;
begin
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Loop through the details of Ship cartons to decrement the quantity on
     its respective inventory LPNs */
  while (exists(select * from #ToLPNDetails where (RecordId > @vRecordId))) -- not that these are really ToLPNDetails and so we should name it accordingly
    begin
      select top 1  @vRecordId          = RecordId,
                    @vToLPNSKUId        = SKUId,
                    @vToLPNQuantity     = Quantity,
                    @vTotalReservedQty  = 0,
                    @vKeyValue          = KeyValue
      from #ToLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Loop through and continue to decrement from the available inventory */
      while (@vToLPNQuantity != @vTotalReservedQty)
        begin
          select @vFromLPNDetailId = null,
                 @vAllocableQty    = 0; -- initialize

          /* Find the least quantity LPN to reserve for the SKU on the Ship Carton */
          select top 1 @vFromLPNDetailId = LPNDetailId,
                       @vAllocableQty    = AllocableQty
          from #FromLPNDetails
          where (KeyValue = @vKeyValue) and
                (AllocableQty > 0)
          order by coalesce(SortOrder, ''), AllocableQty asc;

          /* Break the innerloop if such LPN not found. Loop through the next Ship Carton detail */
          if (@vFromLPNDetailId is null)
            break;

          /* Update the FromLPN reserved Quantity first & then update the total reserved quantity */
          update #FromLPNDetails
          set ReservedQty         += dbo.fn_MinInt(AllocableQty, (@vToLPNQuantity - @vTotalReservedQty)),
              @vTotalReservedQty  += dbo.fn_MinInt(AllocableQty, (@vToLPNQuantity - @vTotalReservedQty))
          where (LPNDetailId = @vFromLPNDetailId);
        end /* End of From LPN loop */

      /* Update the Ship Carton detail with the qty that we were able to activate. If
         all qty was reserved, then update processed flag to indicate that it is activated */
      update #ToLPNDetails
      set ReservedQty = @vTotalReservedQty,
          ProcessedFlag = case when Quantity = @vTotalReservedQty then 'A' /* Activate */ else ProcessedFlag end
      where (RecordId = @vRecordId);

    end /* End of To LPN loop */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_ActivateShipCartons */

Go
