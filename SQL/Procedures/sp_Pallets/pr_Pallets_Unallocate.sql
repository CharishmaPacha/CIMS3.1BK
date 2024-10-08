/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/09/17  RV      pr_Pallets_Unallocate: Check validation before close the Task DetailID (HPI-694)
  2015/11/16  OK      pr_Pallets_Unallocate: Temporarly Clearing the Order Info on Pallet (FB-514)
  2015/10/20  OK      pr_Pallets_Unallocate: Made the changes to update the status on the pallet after cancelling the task (FB-412)
  2015/10/13  OK      pr_Pallets_Unallocate: Made the changes to use pr_LPNDetails_UnallocateMultiple for
                      unallocating the LPNs on the pallet (FB-412).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_Unallocate') is not null
  drop Procedure pr_Pallets_Unallocate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_Unallocate:
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_Unallocate
  (@PalletId         TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vErrMsg            TMessage,

          @vTaskId            TRecordId,
          @vTaskDetailId      TRecordId,
          @vLPNId             TRecordId,
          @vLPNDetailId       TRecordId;

  declare @ttLPNsOnPallet     TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get all the LPNs on the pallet */
  insert into @ttLPNsOnPallet (EntityId, EntityKey)
    select L.LPNId, LD.LPNDetailId
    from LPNs L
    join LPNDetails LD on ( LD.LPNId = L.LPNId)
    where (L.PalletId = @PalletId);

  /* Get the TaskDetailId on the Pallet */
  select @vTaskDetailId = TaskDetailId
  from TaskDetails
  where (PalletId = @PalletId) and
        (Status not in ('C','X'));

  /* Unallocate all the LPNs on the Pallet */
  exec pr_LPNDetails_UnallocateMultiple 'PalletUnallocate' /* @Operation */,
                                        @ttLPNsOnPallet /* LPNsToUnallocate */,
                                        null /* @LPNId */,
                                        null /* @LPNDetailId */, @BusinessUnit, @UserId

  /* Being it is a Pallet unallocate, there will be only one Task and though LPNDetail Unallocate
     calls the Task close, it is not going to close the task as mulitple LPNs are on one pallet pick task
     Hence, we need to explicitly close the pallet pick task here */
  if (@vTaskDetailId is not null)
    exec pr_TaskDetails_Close @vTaskDetailId /* TaskDetailId */, null /* LPNDetailId */, @UserId, null /* @Operation */;

  /* Temporarly Clearing the Order Info on Pallet here */
  update Pallets
  set PickBatchId = 0, /* Default */
      PickBatchNo = null
  where (PalletId = @PalletId);

  /* Update the status on the pallet after cancel the picktask */
  exec pr_Pallets_SetStatus @PalletId = @PalletId,
                            @UserId   = @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_Unallocate */

Go
