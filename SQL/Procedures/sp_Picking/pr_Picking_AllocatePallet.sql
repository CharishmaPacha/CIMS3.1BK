/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/25  TK      pr_Picking_AllocatePallet & pr_Picking_ConfirmLPNPick: Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
  2015/10/17  DK      pr_Picking_AllocatePallet: Bug fix to update OrderId on pallet (FB-440).
                      pr_Picking_AllocatePallet: Use recordid as that is for sure will not lead to infinite loops
  2012/08/20  PK      pr_Picking_AllocatePallet: Passing UserId to log audit comments.
  2012/08/12  PK      Added pr_Picking_AllocatePallet, pr_Picking_IsPalletAllocable, pr_Picking_FindPallet and corrected the
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_AllocatePallet') is not null
  drop Procedure pr_Picking_AllocatePallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_AllocatePallet: This procedure allocates each of the LPNs on
    the pallet to the OrderDetails as specified in the PalletDetails matching.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_AllocatePallet
  (@PalletDetails  XML,
   @PickBatchId    TRecordId,
   @PalletId       TRecordId)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,

          @vRecordId         TRecordId,
          @vOrderId          TRecordId,
          @vPickBatchId      TRecordId,
          @vPickBatchNo      TPickBatchNo,
          @vPalletId         TRecordId,
          @vLPNId            TRecordId,
          @vLPNDetailId      TRecordId,
          @vSKUId            TRecordId,
          @vOrderDetailId    TRecordId,
          @vUnitsToAllocate  TQuantity,
          @vUserId           TUserId;

  declare @ttPalletDetails Table
          (RecordId             TRecordId  identity (1,1),
           PalletId             TRecordId,
           Pallet               TPallet,
           LPNId                TRecordId,
           LPN                  TLPN,
           LPNDetailId          TRecordId,
           SKUId                TRecordId,
           SKU                  TSKU,
           Quantity             TQuantity,
           OrderId              TRecordId,
           OrderDetailId        TRecordId,
           Processed            TFlag      default 'N');

begin /* pr_Picking_AllocatePallet */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vUserId         = System_User;

  /* insert the processed Pallet Details into temp table */
  insert into @ttPalletDetails(PalletId, Pallet, LPNId, LPN, LPNDetailId, SKUId, SKU, Quantity, OrderId, OrderDetailId)
    select Record.Col.value('(PalletId/text())[1]',       'TRecordId'),
           Record.Col.value('(Pallet/text())[1]',         'TPallet'),
           Record.Col.value('(LPNId/text())[1]',          'TRecordId'),
           Record.Col.value('(LPN/text())[1]',            'TLPN'),
           Record.Col.value('(LPNDetailId/text())[1]',    'TRecordId'),
           Record.Col.value('(SKUId/text())[1]',          'TRecordId'),
           Record.Col.value('(SKU/text())[1]',            'TSKU'),
           Record.Col.value('(Quantity/text())[1]',       'TQuantity'),
           Record.Col.value('(OrderId/text())[1]',        'TRecordId'),
           Record.Col.value('(OrderDetailId/text())[1]',  'TRecordId')
    from @PalletDetails.nodes('PalletDetails') as Record(Col);

  /* Get the PickBatchId */
  select @vPickBatchNo = BatchNo
  from PickBatches
  where (RecordId = @PickBatchId);

  /* begin Loop */
  while (exists (select *
                 from @ttPalletDetails
                 where (Processed = 'N'/* No */)))
    begin
      /* Get the top 1 LPN on the Pallet and allocate it to the Order */
      select top 1 @vRecordId        = RecordId,
                   @vLPNId           = LPNId,
                   @vLPNDetailId     = LPNDetailId,
                   @vSKUId           = SKUId,
                   @vPalletId        = PalletId,
                   @vOrderId         = OrderId,
                   @vOrderDetailId   = OrderDetailId,
                   @vUnitsToAllocate = Quantity
      from @ttPalletDetails
      where (Processed = 'N');

      /* Allocate the LPN to the Order - this updates the counts, statuses on the Order and LPN */
      exec pr_Allocation_AllocateLPN @vLPNId,
                                     @vOrderId,
                                     @vOrderDetailId,
                                     0 /* TaskDetailId */,
                                     @vSKUId,
                                     @vUnitsToAllocate;

      update @ttPalletDetails
      set Processed = 'Y' /* Yes */
      where (RecordId = @vRecordId);

      /* Insert Audit Trail */
      exec pr_AuditTrail_Insert 'LPNAllocatedToOrder', @vUserId, null /* ActivityTimestamp */,
                                @LPNId         = @vLPNId,
                                @SKUId         = @vSKUId,
                                @OrderId       = @vOrderId,
                                @OrderDetailId = @vOrderDetailId,
                                @Quantity      = @vUnitsToAllocate;
    end

  /* Pallets is allocated to the order, Update Pallet */
  update Pallets
  set PickBatchNo = @vPickBatchNo,
      PickBatchId = @PickBatchId,
      Status      = 'A' /* Allocated */
  where (PalletId = @PalletId);

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert 'PalletAllocatedToBatch', @vUserId, null /* ActivityTimestamp */,
                            @PickBatchId = @PickBatchId,
                            @PalletId    = @PalletId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_AllocatePallet */

Go
