/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_PauseBatch') is not null
  drop Procedure pr_Packing_PauseBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_PauseBatch:
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_PauseBatch
  (@PalletOrBatchNo    TPallet,       /* Scanned pallet Number or BatchNo */
   @PackingStationId   TRecordId,     /* CURRENTLY UNUSED - LocationId of the Packing Station */
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)       /* Packer */
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,
          @vPalletStatus  TStatus,
          @vUserId        TUserId,
          @vPalletId      TRecordId,
          @vPallet        TPallet,
          @vPickBatchId   TRecordId,
          @vPickBatchNo   TPickBatchNo;
begin
  set @ReturnCode = 0

  select @vPalletId     = P.PalletId,
         @vPallet       = P.Pallet,
         @vPalletStatus = P.Status,
         @vUserId       = P.ModifiedBy,
         @vPickBatchId  = W.WaveId,
         @vPickBatchNo  = W.WaveNo
  from  Pallets P
    left outer join Waves W on (P.PickBatchId = W.WaveId)
  where ((P.Pallet   = @PalletOrBatchNo) or (W.WaveNo = @PalletOrBatchNo)) and
        (P.BusinessUnit = @BusinessUnit);

  /* check pallet id and number */
  if (@vPalletId is null)
    set @MessageName = 'Packing_InvalidPalletOrBatch';
  else
  /* ensure Pallet is not being packed by another user */
  if (@vPalletStatus <> 'G' /* Packing */)
    set @MessageName = 'Packing_PalletNotInPacking';
  else
  if (coalesce(@vUserId, '') <>  @UserId /* validate user */)
    set @MessageName = 'PalletBeingPackedByAnotherUser';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* revert Pallet status to 'picked' */
  update Pallets
  set Status       = 'K',               /* 'Picked' */
      LocationId   = @PackingStationId, /* LocationId of the Packing Station */
      ModifiedBy   = @UserId,           /* Current user working on the Pallet */
      ModifiedDate = current_timestamp
  where (PalletId = @vPalletId);

  /* Revert Pick Batch status to Picked */
  exec pr_PickBatch_SetStatus @vPickBatchNo, 'K' /* Picked */, @UserId;

  /* Audittrail */
  exec pr_AuditTrail_Insert 'PackingPauseBatch', @UserId, null /* ActivityTimestamp */,
                            @PickBatchId   = @vPickBatchId,
                            @PalletId      = @vPalletId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Packing_PauseBatch */

Go
