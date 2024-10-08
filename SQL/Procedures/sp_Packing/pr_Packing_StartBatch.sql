/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/01/16  TK      pr_Packing_StartBatch: Enhanced to restrict multiple Users to pack single batch
  2013/06/11  PK      pr_Packing_StartBatch: Changed the order of validations.
  2013/05/19  AY      pr_Packing_StartBatch: Enhance to allow scanning of LPN/Cart Position.
  2013/05/02  AY      pr_Packing_StartBatch: Allow multiple users to pack same batch, but not same pallet.
  2013/04/25  PK      pr_Packing_StartBatch: Allowing the Picking Carts to be packed.
  2013/04/13  AY      pr_Packing_StartBatch: Allow users with permission to pack batches
  2012/07/27  NY      pr_Packing_StartBatch: parameter PackingStationId => PackingStation
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_StartBatch') is not null
  drop Procedure pr_Packing_StartBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_StartBatch: This procedure is invoked when Packing is started
    or resumed on a batch. By the time a Pallet/Batch is ready for packing, the
    Pallet and Batch are linked as the Pallet would have been used to Pick the
    batches. This is now being enchanced to allow user to start packing by scanning
    a Cart or Cart Position. If user scans a valid Cart position, then directly
    take user to Order Packing. If the user scans a valid Cart/Batch which has
    only one position as well, then take the user to Order Packing as well.
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_StartBatch
  (@PalletOrBatchNo    TPallet,       /* Scanned pallet Number or BatchNo or LPN */
   @PackStation        TName,         /* Name of the Packing Station */
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,       /* Packer */
   @PalletId           TRecordId output,
   @OrderId            TRecordId output)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,
          @vPallet               TPallet,
          @vPalletStatus         TStatus,
          @vPackingUser          TUserId,
          @vPickBatchId          TRecordId,
          @vBatchPalletId        TRecordId,
          @vPickBatchNo          TPickBatchNo,
          @vBatchPalletCount     TCount,
          @vOrdersToPack         TCount,
          @vScannedEntity        TFlags,
          @vValidPalletStatuses  TFlags,
          @vPackingStationId     TRecordId;  /* CURRENTLY UNUSED - LocationId of the Packing Station */
begin
  select @ReturnCode  = 0,
         @MessageName = null;

  /* Determine what the user scanned, try pallet first */
  select @PalletId       = PalletId,
         @vScannedEntity = 'P' /* Pallet */
  from Pallets
  where (Pallet       = @PalletOrBatchNo) and
        (BusinessUnit = @BusinessUnit);

  /* If not Pallet, try Pallet Position i.e LPN. We then take the PalletId from it
     and start packing it. */
  if (@vScannedEntity is null)
    select @PalletId       = PalletId,
           @vScannedEntity = 'L' /* LPN */
    from LPNs
    where (LPN          = @PalletOrBatchNo) and
          (BusinessUnit = @BusinessUnit);

  /* If neither Pallet nor LPN then try Batch */
  if (@vScannedEntity is null)
    select @vPickBatchId   = RecordId,
           @vPickBatchNo   = BatchNo,
           @vScannedEntity = 'B' /* Batch */
    from PickBatches
    where (BatchNo      = @PalletOrBatchNo) and
          (BusinessUnit = @BusinessUnit);

  /* If user scanned the Pick Batch, then check the number of Pallets/Carts for the Batch */
  if (@vScannedEntity = 'B' /* Pick Batch */)
    begin
      select @vBatchPalletCount = count(*),
             @vBatchPalletId    = min(PalletId)
      from Pallets
      where (PickBatchNo = @vPickBatchNo);

      /* If the Batch has only one pallet, then assume that the user wants to start packing the Pallet/Cart */
      if (@vBatchPalletCount = 1)
        select @PalletId = @vBatchPalletId;
    end

  /* If we have a Pallet/Cart then get info to validate and get the positions
     on the pallet to start packing */
  if (@PalletId is not null)
    begin
      select @vPallet       =  P.Pallet,
             @vPalletStatus =  P.Status,
             @vPackingUser  =  P.PackingByUser,
             @vPickBatchId  = PB.RecordId,
             @vPickBatchNo  = PB.BatchNo
      from  Pallets P
            left outer join PickBatches PB on (P.PickBatchNo = PB.BatchNo)
      where (P.PalletId = @PalletId);

      /* Check the LPNs/Positions on the Pallet that can be packed */
      select @vOrdersToPack = count(distinct coalesce(OrderId, 0)),
             @OrderId       = min(coalesce(OrderId, 0))
      from vwOrdersToPack
      where (PalletId = @PalletId);

      /* If there are more than one Order on the Pallet/Cart to pack, then clear the OrderId
         as we cannot determine which Order user would like to pack when they start the Batch */
      if (@vOrdersToPack > 1) select @OrderId = null;
    end

  /* Fetch the valid cancel batch status */
  select @vValidPalletStatuses = dbo.fn_Controls_GetAsString('Packing', 'ValidPalletStatuses', 'CKG' /* Picking, Picked, Packing */,
                                                             @BusinessUnit, @UserId);

  /* Validations */
  if (@vScannedEntity = 'B' /* Pick batch */) and (@vBatchPalletCount > 1)
    set @MessageName = 'Packing_MultiplePalletsForBatch'
  /* check pallet id and number */
  else
  if (@PalletId is null)
    set @MessageName = 'Packing_InvalidPalletOrBatch';
  else
  /* ensure Pallet is not being packed by another user */
  if (@vPalletStatus = 'G' /* Packing */) and
     (@vPackingUser <> @UserId /* validate user */)/* and
     (dbo.fn_Permissions_IsAllowed(@UserId, 'ORPackedByAnotherUser') <> '0') */
    set @MessageName = 'PalletBeingPackedByAnotherUser';
  else
  /* check pallet is ready for packing */
  if (charindex(@vPalletStatus, @vValidPalletStatuses) = 0)
    set @MessageName = 'Packing_InvalidPalletStatus';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update Pallet Status to Packing */
  update Pallets
  set Status        = 'G',                             /* Packing                            */
      LocationId    = @vPackingStationId,              /* LocationId of the Packing Station  */
      PackingByUser = @UserId,
      ModifiedBy    = coalesce(@UserId, System_User),  /* Current user working on the pallet */
      ModifiedDate  = current_timestamp
  where (PalletId = @PalletId);

  /* set Pick Batch status to Packing */
  exec pr_PickBatch_SetStatus @vPickBatchNo, 'A' /* Packing */, @UserId;

  /* Audittrail */
  exec pr_AuditTrail_Insert 'PackingStartBatch', @UserId, null /* ActivityTimestamp */,
                            @PickBatchId   = @vPickBatchId,
                            @PalletId      = @PalletId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Packing_StartBatch */

Go
