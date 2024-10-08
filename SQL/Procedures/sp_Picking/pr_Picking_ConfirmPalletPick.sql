/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/01/13  OK      pr_Picking_ConfirmPalletPick: Logged the AT on Pallet, BulkOrder and Location (FB-453)
  2015/12/11  VS      pr_Picking_ConfirmPalletPick: Added to log Audit trail information on the orders (FB-453)
  2012/10/24  VM      pr_Picking_ConfirmPalletPick: Commented a select statement, which could be used for debugging
                      pr_Picking_ConfirmPalletPick: Clear Pallet Location when it is picked.
                      pr_Picking_ConfirmPalletPick: New procedure to Confirm pick of each LPN on the pallet.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ConfirmPalletPick') is not null
  drop Procedure pr_Picking_ConfirmPalletPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ConfirmPalletPick:
    Procedure marks the PalletId and its LPNs as Picked
    Invokes Status recalculation on Order Header
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ConfirmPalletPick
  (@PalletId        TRecordId,
   @PickBatchNo     TPickBatchNo,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vPickBatchNo         TPickBatchNo,
          @vPallet              TPallet,
          @vPalletQuantity      TQuantity,
          @vSKUId               TRecordId,
          @vLPN                 TLPN,
          @vLocationId          TRecordId,
          @vLocation            TLocation,
          @vRecordId            TRecordId,
          @vActivityType        TActivityType,
          @vPalletId            TRecordId,
          @vLPNId               TRecordId,
          @vOrderId             TRecordId,
          @vOrderDetailId       TRecordId,
          @vLPNCount            TCount,
          @vPalletQty           TQuantity,
          @vPickbatchId         TRecordId,
          @vPickTicket          TPickTicket,
          @vAuditId             TRecordId;

  declare @ttPalletPickingLPNs Table
          (RecordId             TRecordId  identity (1,1),
           LPNId                TRecordId,
           LPN                  TLPN,
           SKUId                TRecordId,
           SKU                  TSKU,
           OrderId              TRecordId,
           PickTicket           TPickTicket, /* For AT */
           OrderDetailId        TRecordId,
           Processed            TFlag      default 'N');

  declare @ttOrdersPicked       TEntityKeysTable,
          @ttLPNsPicked         TEntityKeysTable;

begin /* pr_Picking_ConfirmPalletPick */
  select @vActivityType = 'PalletPick';

  /* Insert the LPNs on the pallet into temp table */
  insert into @ttPalletPickingLPNs (LPNId, LPN, SKUId, SKU, OrderId, OrderDetailId, PickTicket)
    select LPNId, LPN, SKUId, SKU, OrderId, OrderDetailId, PickTicket
    from vwLPNDetails
    where (PalletId     = @PalletId) and
          (BusinessUnit = @BusinessUnit);

  /* Get Pallet Info for AT */
  select @vLocationId = LocationId,
         @vPalletId   = PalletId,
         @vLPNCount   = NumLPNs,
         @vPalletQty  = Quantity
  from Pallets
  where (PalletId = @PalletId);

  /* Get the PickbatchId to log AT */
  select @vPickbatchId = RecordId
  from PickBatches
  where (BatchNo = @PickBatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* begin Loop */
  while (exists(select *
                from @ttPalletPickingLPNs
                where Processed = 'N'/* No */))
    begin
      /* select the each LPN on the Pallet */
      select top 1 @vRecordId      = RecordId,
                   @vLPNId         = LPNId,
                   @vLPN           = LPN,
                   @vOrderId       = OrderId,
                   @vOrderDetailId = OrderDetailId,
                   @vPickTicket    = PickTicket
      from @ttPalletPickingLPNs
      where Processed = 'N'/* No */;

      /* Passing each LPN which is allocated to the orders to mark the LPN as Picked and update the orders as well */
      if (@vLPNId is not null)
        exec pr_Picking_ConfirmLPNPick @vOrderId,
                                       @vOrderDetailId,
                                       @vLPNId,
                                       @BusinessUnit,
                                       @UserId;

      --select @vOrderId vOrderId, @vOrderDetailId vOrderDetailId, @vLPNId vLPNId;

      /* Update the LPN as processed  */
      update @ttPalletPickingLPNs
      set Processed = 'Y' /* Yes */
      where (RecordId = @vRecordId);

      /* Add the Order to list of orders for AT */
      if not exists (select * from @ttOrdersPicked where EntityId = @vOrderId)
        insert into @ttOrdersPicked(EntityId, EntityKey)
          select @vOrderId, @vPickTicket;

      insert into @ttLPNsPicked (EntityId, EntityKey)
        select @vLPNId, @vLPN;

      /* Clearing the variables in loop */
      select @vRecordId = null, @vLPNId = null, @vOrderId = null, @vOrderDetailId = null;
    end

  if (not exists(select *
                 from @ttPalletPickingLPNs
                 where Processed = 'N'))
    begin
      /* Clear Pallet's Location */
      exec pr_Pallets_SetLocation @PalletId, null, 'N' /* No - Update LPNs */, @BusinessUnit, @UserId;

      /* Todo: As we are not updating Pallet Status by calculating Pallet LPNs Status,
         So Marking the Pallet as Picked */
      exec pr_Pallets_SetStatus @PalletId, 'K' /* Picked */, @UserId;
    end

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* Activity Timestamp */,
                            @PalletId      = @vPalletId,
                            @LocationId    = @vLocationId,
                            @PickBatchId   = @vPickBatchId,
                            @Quantity      = @vPalletQty,  -- NumLPNs already handled in the proc by using Pallet.NumLPNs
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditId output;

  /* Link AT to Orders & LPNs of pallet */
  exec pr_AuditTrail_InsertEntities @vAuditId, 'PickTicket', @ttOrdersPicked, @BusinessUnit;

  /* pr_Picking_ConfirmLPNPick does logging of AT on LPN, so it is not needed here again */
  --exec pr_AuditTrail_InsertEntities @vAuditId, 'LPN', @ttLPNsPicked, @BusinessUnit;

end /* pr_Picking_ConfirmPalletPick */

Go
