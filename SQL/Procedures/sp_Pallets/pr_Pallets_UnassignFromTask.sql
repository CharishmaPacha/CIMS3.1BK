/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/10  AY      pr_Pallets_UnassignFromTask: Clear the Task from the Pallet (CID-766)
  2016/12/14  TK      pr_Pallets_UnassignFromTask: Clear pallet id on TaskDetails as well (HPI-1174)
              TK      pr_Pallets_ClearCartPositionQty: Initial Revision
                      pr_Pallets_UnassignFromTask: Initial Revision (HPI-917)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_UnassignFromTask') is not null
  drop Procedure pr_Pallets_UnassignFromTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_UnassignFromTask: A Pallet is associated with a Task when
   the user starts picking but if for some reason the user does not want to continue
   and backs off, then we need to revert Pallet and Task back so that they
   are not linked anymore.

   This proc also reverts the status of the Tasks/TaskDetails to New if nothing is picked yet
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_UnassignFromTask
  (@PalletId       TRecordId,
   @TaskId         TRecordId,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName;
begin
  SET NOCOUNT ON;

  /* Clear Wave info if it is a Cart */
  update Pallets
  set PickBatchId = null,
      PickBatchNo = null,
      TaskId      = null
  where (PalletId   = @PalletId) and
        (PalletType = 'C' /* Cart */);

  /* If there are any InProgress picks then revert them to New if nothing has been picked yet */
  update TaskDetails
  set Status   = 'N' /* Ready To Start */,
      PalletId = null
  where (TaskId = @TaskId) and
        (Status = 'I' /* InProgress */) and
        (UnitsCompleted = 0);

  /* If Task has been started and nothing Picked then clear the Pallet on the task and
     revert back the task to ReadyToStart */
  update Tasks
  set PalletId = null
  where (TaskId = @TaskId);

  /* Recalculate the task status */
  exec pr_Tasks_SetStatus @TaskId, @UserId, @Recount = 'Y';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_UnassignFromTask */

Go
