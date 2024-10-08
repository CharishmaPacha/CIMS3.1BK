/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/17  AY      pr_Picking_NextBatchToPick: Do not assign Waves based upon Pallet used (S2G-645)
  2018/04/13  OK      pr_Picking_NextBatchToPick: Changes to suggest the pick based on the Pick Group (S2G-612)
  2013/12/22  PK      pr_Picking_NextBatchToPick: Suggesting Inprogress tasks to user if user did not key in the batch.
  2013/09/29  PK      pr_Picking_NextBatchToPick: Changes to get the allocated batch to pick.
                      pr_Picking_NextBatchToPick: Fixed to ensure LPN Picking works after Pallet Picking for same batch
  2012/07/16  AY      pr_Picking_NextBatchToPick: select from desired Warehouse only.
  2012/06/25  PK      pr_Picking_NextBatchToPick: Returning Batches if the Batch status is in Ready to Pull and BatchType in PiecePicks,
  2011/11/16  AY      pr_Picking_NextBatchToPick: Bug fix - Newest batches were being issued first.
  2011/10/13  AY      pr_Picking_NextBatchToPick: Bug fix - when PickBatch.Zone = Mixed then
  2011/09/26  TD      pr_Picking_NextBatchToPick: Fixed Syntax Error.
  2011/09/24  TD      pr_Picking_NextBatchToPick: retuns Pauses(U) batches also.
  2011/09/22  TD      pr_Picking_NextBatchToPick: Fixed bug NoBatchesToPack.
                      pr_Picking_ValidatePickBatchNo,pr_Picking_NextBatchToPick: implemented the procedures
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_NextBatchToPick') is not null
  drop Procedure pr_Picking_NextBatchToPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_NextBatchToPick:
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_NextBatchToPick
  (@PickZone      TZoneId      = null,
   @DestZone      TLookUpCode  = null,
   @PickGroup     TPickGroup,
   @BatchType     TTypeCode    = null,
   @PickPallet    TPallet,
   @Warehouse     TWarehouse,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @PickBatchNo   TPickBatchNo        output,
   @TaskId        TRecordId    = null output)
as
  declare @PalletId   TRecordId,
          @PalletType TTypeCode;
begin /* pr_Picking_NextBatchToPick */
  /* Initialize output vars */
  select @PickBatchNo = null;

  /* If the TaskId is not null then get the task */
  if (@TaskId is not null)
    select @TaskId      = TaskId,
           @PickBatchNo = BatchNo
    from Tasks
    where (TaskId       = @TaskId) and
          (PickGroup    like @PickGroup + '%') and
          (BatchNo      = coalesce(@PickBatchNo, BatchNo)) and
          (Status       in ('I' /* Inprogress */, 'N' /* New */)) and
          (BusinessUnit = @BusinessUnit);

  /* If User has given a valid task, then we have a batch to pick, then exit */
  if (@PickBatchNo is not null)
    return;

  /* This functionality is not applicable anymore. This was more for Loehmanns
     where we did not have task picking and each user was assigned a Wave to pick */

  -- /* If there is already a batch associated with the pallet, then return it
  --    ToDo: Return task id if there is one */
  -- select @PickBatchNo = BatchNo
  -- from PickBatches
  -- where (Pallet       = @PickPallet) and
  --       (Status       in ('P' /* Picking */, 'U' /* Paused */)) and
  --       (BusinessUnit = @BusinessUnit);
  --
  -- if (@PickBatchNo is not null)
  --   return;

  select @PalletType = PalletType
  from Pallets
  where Pallet = @PickPallet;

  /* If the user did not key in the BatchNo and if the Pallet is not associated with
     any batch (assuming it is empty) and TaskId is null then check whether there are
     any inprogress tasks for the user */
  select top 1 @TaskId      = TD.TaskId,
               @PickBatchNo = T.BatchNo
  from TaskDetails TD
    join Tasks T on (T.TaskId = TD.TaskId)
  where (TD.Status    = 'I' /* Inprogress */) and
        (T.AssignedTo = @UserId) and
        (T.PickGroup like @PickGroup + '%')
  order by T.TaskId, TD.TaskDetailId;

  if (@PickBatchNo is not null)
    return;

  /* Check whether there are any allocated batches to pick, if there are any batches then
     suggest the Pick task of the batch to pick by the user, If the batch has already started
     picking by the user and if the task is in Inprogress then suggest the task to complete
     picking of that task, Or if there are any new users then suggest the new task to pick */
  select top 1 @PickBatchNo = BatchNo,
               @TaskId      = TaskId
  from vwPickTasks
  where (coalesce(PickZone, '') = coalesce(@PickZone, PickZone, '')) and
        (DestZone           = coalesce(@DestZone, DestZone)) and
        (PickGroup          = @PickGroup) and
        (BatchType          = coalesce(@BatchType, BatchType)) and
        (PickBatchWarehouse = @Warehouse) and
        (BusinessUnit       = @BusinessUnit) and
        --(IsAllocated        = 'Y'/* Yes */) and
        (UnitsToPick        > 0) and
        (PickBatchStatus in ('R'/* Ready To Pick */, 'P'/* Picking */, 'U'/* Paused */)) and
        (((AssignedTo = @UserId) and (TaskStatus in ('I'/* Inprogress */, 'N' /* new */))) or
         ((AssignedTo is null) and (TaskStatus = 'N'/* New */)))
  order by assignedto desc, TaskStatus, BatchPriority asc, CreatedDate asc, TaskPriority, TaskId;

  /* If the above query doesn't return any Batch, assuming that the batches are not allocated,
     then suggest the picks using PickDetails */
  if (@PickBatchNo is not null)
    return;

  /* Need to join with vwPickDetails to ensure that that BatchNo we return
     has valid picks from it.

     I don't see any reason to do this join with zone also. It is possible that
     there is inventory but in a different zone. More over, when the Batch.PickZone
     is mixed, it would not find any pick details as there is no PickingZone called
     Mixed. Hence it would say 'No Batches to pick' even there are. AY 2011/10/13

     Status has to include Picking as if they have pallets and they started picking pallets
     the batch would be in a Picking status by the time they are ready to pick the LPNs
     */
  select top 1 @PickBatchNo = BatchNo
  from PickBatches B join vwPickDetails BPD on B.BatchNo  = BPD.PickBatchNo
                                           -- and B.PickZone = BPD.PickingZone
  where (coalesce(B.PickZone, '') = coalesce(@PickZone, B.PickZone, '')) and
        (B.BatchType         = coalesce(@BatchType, B.BatchType)) and
        (B.Warehouse         = @Warehouse   ) and
        (B.BusinessUnit      = @BusinessUnit) and
        (B.IsAllocated       = 'NA'/* Not applicable */) and
        ((B.Status = 'L' /* Ready To Pull */) and (B.BatchType =  'U' /* Piece Picks */ ) or
        ((B.Status in ('R', 'P' /* Ready To Pick, Picking */)) and (B.BatchType <> 'U' /* Piece Picks */))) and
        (BPD.UnitsToAllocate > 0)
        -- ToDo: never automatically assign Cross Docking batches for picking unless BatchType is not null
  order by B.Priority asc, B.CreatedDate asc;

end /* pr_Picking_NextBatchToPick */

Go
