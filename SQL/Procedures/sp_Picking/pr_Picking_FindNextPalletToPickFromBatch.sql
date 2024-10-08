/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/09/25  AY      pr_Picking_FindNextPalletToPickFromBatch: Added to aid with multiple users picking pallets from same batch
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindNextPalletToPickFromBatch') is not null
  drop Procedure pr_Picking_FindNextPalletToPickFromBatch;
Go

Create Procedure pr_Picking_FindNextPalletToPickFromBatch
  (@PickBatchId     TRecordId,
   @PickBatchNo     TPickBatchNo,
   @PickZone        TZoneId,
   @UserId          TUserId,
   @SearchType      TFlag        = 'F',        /* Refer to Notes above, for valid values and their usage */
   @PickPalletId    TRecordId    output,
   @PickPallet      TPallet      output,
   @MessageName     TMessageName output
   )
as
begin /* pr_Picking_FindNextPalletToPickFromBatch */
  select @PickPalletId = null,
         @PickPallet   = null,
         @MessageName  = null;

  /* First, check if there is already a pallet assigned to the user that is in Picking status */
  select top 1 @PickPallet   = Pallet,
               @PickPalletId = PalletId
  from vwPallets
  where ((PickBatchId = @PickBatchId) or (PickBatchNo = @PickBatchNo)) and
        (Status = 'C'/* Picking */ and ModifiedBy = @UserId) and
        (PalletType  = 'I' /* Inventory Pallet */) and
        (coalesce(PickingZone, '') = coalesce(@PickZone, PickingZone, ''))
  order by Location;

  /* If we found a pallet, then exit */
  if (@PickPalletId is not null)
    goto FoundPalletToPick;

  /* Fetch the next pallet to pick. Order it by Status so that it will give
     the next allocated pallet. This is to ensure that two users are not given
     the same pallet to pick at the same time. */
  select top 1 @PickPallet   = Pallet,
               @PickPalletId = PalletId
  from vwPallets
  where ((PickBatchId = @PickBatchId) or (PickBatchNo = @PickBatchNo)) and
        (Status      in ('A'/* Allocated */, 'C'/* Picking */)) and
        (PalletType  = 'I' /* Inventory Pallet */) and
        (coalesce(PickingZone, '') = coalesce(@PickZone, PickingZone, ''))
  order by Status, Location;

  /* If nothing has been found then issue an error message */
  if (@PickPalletId is null) and (@PickZone is not null)
    select @MessageName = 'NoPalletsToPickInZoneForBatch'
  else
  if (@PickPalletId is null)
    select @MessageName = 'NoPalletsAvailToPickForBatch';

  if (@MessageName is not null)
    return;

FoundPalletToPick:
  /* Update Pallet's Status to Picking */
  update Pallets
  set Status        = 'C' /* Picking */,
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  where (PalletId = @PickPalletId);
end /* pr_Picking_FindNextPalletToPickFromBatch */

Go

/*------------------------------------------------------------------------------
  Proc pr_Picking_FindNextPickFromBatch: This Procedure returns the details of
  next pick i.e., LPN, Location, SKU, UnitsToPick, OrderDetailId on Batch.
------------------------------------------------------------------------------*/
