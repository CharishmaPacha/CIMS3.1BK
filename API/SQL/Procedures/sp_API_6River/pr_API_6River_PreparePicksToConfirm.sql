/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/24  TK      pr_API_6River_Inbound_PickTaskPicked & pr_API_6River_PreparePicksToConfirm: Added transactions (CID-1736)
  2021/02/10  TK      pr_API_6River_Inbound_PickTaskPicked & pr_API_6River_PreparePicksToConfirm:
  pr_API_6River_PreparePicksToConfirm: Initial Revision (CID-1634)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_PreparePicksToConfirm') is not null
  drop Procedure pr_API_6River_PreparePicksToConfirm;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_PreparePicksToConfirm: This procedure prepare the picks that
    needs to be confirmed.

  #PicksFromRawInput - TTaskDetailsInfoTable is the list of picks sent from 6River
  #PicksToConfirm    - TTaskDetailsInfoTable is the list of picks to be confirmed.

  Why are they different? One pick sent by CIMS can be confirmed as multiple with different CoOs.

  Scenarios:
  1. When complete task detail quantity is picked then we will just insert the task detail into #PicksToConfirm
  2. When partial task detail quantity is picked then we will split the quantity with picked units and then insert
     the NEW task detail into #PicksToConfirm
  3. When complete task detail quantity is picked but they have picked SKU with multiple CoOs i,e. if task detail
     quantity is 6 units and user confirmed pick twice by picking 2 units with CoO as 'US' and 4 units with CoO as
     'AF' then== we will split the task detail and insert two details with different CoOs into #PicksToConfirm
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_PreparePicksToConfirm
  (@BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vRecordId               TRecordId,
          @vTranCount              TCount,

          @vTaskDetailId           TRecordId,
          @vNewTaskDetailId        TRecordId,
          @vUnitsToPick            TInteger,
          @vQtyPicked              TInteger,
          @vFromLocation           TLocation,
          @vPickedBy               TUserId,
          @vCoO                    TCoO;
begin /* pr_API_6River_PreparePicksToConfirm */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vTranCount   = @@trancount;

  if (@vTranCount = 0) begin transaction;

  /* If Quantity that has been picked is matching the task detail quantity then just insert them
     into #PicksToConfirm directly */
  delete from PRI
  output deleted.TaskDetailId, deleted.TDQuantity, deleted.QtyPicked, deleted.FromLocation, deleted.PickedBy, deleted.CoO
  into #PicksToConfirm (TaskDetailId, TDQuantity, QtyPicked, FromLocation, PickedBy, CoO)
  from #PicksFromRawInput PRI
  where (TDQuantity = QtyPicked);

  /* If nothing is picked against any task detail then just insert then into #PicksToConfirm
     which may be short picked later */
  delete from PRI
  output deleted.TaskDetailId, deleted.TDQuantity, deleted.QtyPicked, deleted.FromLocation, deleted.PickedBy, deleted.CoO
  into #PicksToConfirm (TaskDetailId, TDQuantity, QtyPicked, FromLocation, PickedBy, CoO)
  from #PicksFromRawInput PRI
  where (QtyPicked = 0);

  /* Loop thru all the picks that are partially picked or picked multiple times */
  while exists (select * from #PicksFromRawInput where RecordId > @vRecordId)
    begin
      /* Initialize Variables */
      select @vNewTaskDetailId = null;

      /* Get the next record info to process */
      select top 1 @vRecordId     = RecordId,
                   @vTaskDetailId = TaskDetailId,
                   @vUnitsToPick  = TDQuantity,
                   @vQtyPicked    = QtyPicked,
                   @vFromLocation = FromLocation,
                   @vPickedBy     = PickedBy,
                   @vCoO          = CoO
      from #PicksFromRawInput
      where (RecordId > @vRecordId)
      order by RecordId;

      /* If units to be picked is greater than quantity picked then split the task detail with
         quantity that is picked and insert new task detail into #PicksToConfirm which inturn
         will be marked as picked */
      if (@vQtyPicked < @vUnitsToPick)
        begin
          /* Invoke procedure to split task detail */
          exec pr_TaskDetails_SplitDetail @vTaskDetailId, null, @vQtyPicked, null /* Operation */,
                                          @BusinessUnit, @UserId, @vNewTaskDetailId output;

          /* There may be chances that a single task detail is picked twice in that case
             reduce the units to pick on the all the task details matching with task detail Id */
          update #PicksFromRawInput
          set TDQuantity -= @vQtyPicked
          where (TaskDetailId = @vTaskDetailId);
        end

      /* If there is a new task detail then insert it or insert the old one */
      insert into #PicksToConfirm (TaskDetailId, TDQuantity, QtyPicked, FromLocation, PickedBy, CoO)
      select coalesce(@vNewTaskDetailId, @vTaskDetailId), @vQtyPicked, @vQtyPicked, @vFromLocation, @vPickedBy, @vCoO;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vTranCount = 0) commit transaction;
end try
begin catch
  if (@vTranCount = 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_PreparePicksToConfirm */

Go
