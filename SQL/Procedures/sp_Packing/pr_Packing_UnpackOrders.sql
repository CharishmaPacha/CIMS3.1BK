/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/09/03  SK      pr_Packing_Unpack, pr_Packing_UnpackOrders: Added procedures to unpack packed LPNs from given orders (CIMS-584).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_UnpackOrders') is not null
  drop Procedure pr_Packing_UnpackOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_UnpackOrders:

  This procedure is used to unpack packed LPNs of an order called through the previous
  procedure
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_UnpackOrders
  (@OrderId       TRecordId,
   @PickCart      TPallet,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @FromLPNId     TRecordId output,
   @xmlResult     TXML output)
as
declare @vRecordId        TRecordId,
        @vValidLPNStatus  TStatus,
        @vOrderWave       TPickBatchNo,
        @vPalletWave      TPickBatchNo,
        @vPalletId        TRecordId,
        @ToLPNId          TRecordId,
        @ToLPN            TLPN,
        @FromLPN          TLPN,
        @CurrentSKUId     TRecordId,
        @CurrentSKU       TSKU,
        @TransferQuantity TQuantity,
        @QtyToExplode     TQuantity,

        @vReturnCode      TInteger,
        @MessageName      TMessageName,

        @vTIXMLInput        XML;

declare @ttLPNDetails table (RecordId  TRecordId identity (1,1),
                             OrderId   TRecordId,
                             LPNStatus TStatus,
                             LPNId     TRecordId,
                             LPN       TLPN,
                             SKUId     TRecordId,
                             SKU       TSKU,
                             Quantity  TQuantity);

begin
  SET NOCOUNT ON;
  /* Process Steps
      1. Filter LPNs based on Status from control table
      2. Find Cart Position from the PickCart given
      3. Modify LPN - transfer the position - procedure - check if recounts
      4. Recount & Status update - LPNs, Orders, Batch
      5. Logging & exit
      6. output */

  /* Initializing values */
  select @vReturnCode  = 0,
         @vRecordId    = 0;

  /* Get allowable statuses for orders to be unpacked */
  select @vValidLPNStatus = dbo.fn_Controls_GetAsString('Packing', 'ValidUnpackLPNStatus', 'D' /* Packing */, @BusinessUnit, null);

  /* Get batch number */
  select @vOrderWave = PickBatchNo
  from OrderHeaders
  where OrderId = @OrderId

  /* Get batch no associated with the pick cart */
  select @vPalletWave = PickBatchNo,
         @vPalletId   = PalletId
  from Pallets
  where Pallet = @PickCart

  /* Get LPN position to be transferred to */
  select @ToLPNId = LP.LPNId,
         @ToLPN   = LP.LPN
  from LPNs LP
    join Pallets P on LP.PalletId = P.PalletId and
                      P.Pallet    = @PickCart and
                      LP.OrderId  = @OrderId

  /* If LPN position is not already associated, then find new position on the given cart */
  if (coalesce(@ToLPNId, '') = '')
    begin
      select top 1 @ToLPNId = LP.LPNId,
                   @ToLPN   = LP.LPN
      from LPNs LP
        join Pallets P on LP.PalletId = P.PalletId and
                          P.Pallet    = @PickCart and
                          LP.Status    = 'N' /* New */ and
                          LP.LPNType   in ('A' /* Cart */, 'TO' /* Tote */);
    end

  /* Get LPN details into a temporary table for processing */
  insert into @ttLPNDetails(OrderId, LPNStatus, LPNId, LPN, SKUId, SKU, Quantity)
    select OrderId, LPNStatus, LPNId, LPN, SKUId, SKU, Quantity
    from vwLPNDetails
    where OrderId = @OrderId and
          charindex(LPNStatus, @vValidLPNStatus) <> 0

   /* Validations */
  /* Validate Pick cart association with the Order */
  if (coalesce(@vPalletWave, '') <> '' and
      @vPalletWave <> @vOrderWave)
    select @MessageName = 'Unpack_PalletNotAssociatedwithOrder'
  else
  if (@ToLPNId is null)
    select @MessageName = 'Unpack_NoPositionToUnPack';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Loop through list of LPNDetails to transfer the units */
  while (exists(select * from @ttLPNDetails where RecordId > @vRecordId))
    begin
      /* select details for transferring units */
      select top 1 @vRecordId        = RecordId,
                   @FromLPNId        = LPNId,
                   @FromLPN          = LPN,
                   @CurrentSKUId     = SKUId,
                   @CurrentSKU       = SKU,
                   @TransferQuantity = Quantity
      from @ttLPNDetails
      where RecordId > @vRecordId
      order by RecordId

        select @vTIXMLInput = (select @FromLPNId           FromLPNId,
                                      @FromLPN             FromLPN,
                                      @CurrentSKUId        CurrentSKUId,
                                      @CurrentSKU          CurrentSKU,
                                      @QtyToExplode        QtyToExplode,
                                      @TransferQuantity    TransferQuantity,
                                      @ToLPNId             ToLPNId,
                                      @ToLPN               ToLPN,
                                      @BusinessUnit        BusinessUnit,
                                      @UserId              UserId
                               FOR XML PATH('TransferInventory'));

      /* Transfer the inventory */
      exec @vReturnCode = pr_RFC_TransferInventory @vTIXMLInput,
                                                   @xmlResult output

      if (@vReturnCode > 0)
        goto ExitHandler;

    end /* End LPNDetails loop */

  /* Update the status of ToLPN after unpack is completed */
  update LPNs
  set Status  = 'K' /* Picked */
  where LPNId = @ToLPNId

  /* Manually set Order headers status to Picking if previous status was picking or Picked */
  update OrderHeaders
  set Status = case
                when Status = 'K' /* Packed */ then
                  'P' /* Picked */
                else
                  Status /* No change */
                end
  where OrderId = @OrderId

  /* set count and status of the order */
  exec pr_OrderHeaders_Recount @OrderId;

  /* Re-evaluate the status of the batch */
  exec pr_PickBatch_SetStatus @vOrderWave;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_UnpackOrders */

Go
