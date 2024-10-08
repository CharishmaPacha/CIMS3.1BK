/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/05  VM      pr_Allocation_AllocateFromDynamicPicklanes: Transaction commit for each Task (S2GCA-353)
              TK      pr_Allocation_GetTaskStatistics: To return total temp labels (S2GCA-334)
  2018/03/20  TD      pr_Allocation_CreatePickTasks, pr_PickBatch_IsValidToAddTaskDetail,
                      pr_Allocation_GetTaskStatistics: Changes to consider num picks while creating tasks (S2G-456)
  2017/12/28  AY/RV   pr_PickBatch_CreatePickTasks: Tasks set status and re count call after all the task details created
                      pr_Allocation_GetTaskStatistics: Get the required counts from task details instead of tasks recounts
                        every time to increase the performance (HPI-1784)
  2016/09/10  TK      Bug Fix to limit number of Order per task (HPI-609)
              AY      pr_Allocation_GetTaskStatistics: Changed to override TotalCases to TempLabelCount (HPI-609)
  2016/08/18  AY/TK   pr_Allocation_CreatePickTasks: LPN Picks - consider each LPN as one case
                      pr_Allocation_GetTaskStatistics: Recount Tasks before getting Statistics (HPI-487)
  2016/03/14  TD      Added new procedure pr_Allocation_GetTaskStatistics.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GetTaskStatistics') is not null
  drop Procedure pr_Allocation_GetTaskStatistics;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GetTaskStatistics
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GetTaskStatistics
  (@TaskId             TRecordId,
   @RecountTask        TFlag     = 'N',
   @TotalWeight        TWeight   = null output,
   @TotalVolume        TVolume   = null output,
   @TotalCases         TCount    = null output,
   @TotalCartonVolume  TVolume   = null output,
   @TotalUnits         TQuantity = null output,
   @TotalOrders        TCount    = null output,
   @TotalPicks         TCount    = null output,
   @TotalTempLabels    TCount    = null output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription;
begin
  select @ReturnCode   = 0;

  /* recalculate the necessary counts only. Do not call Recounts which
     does lot more here. Task_Recount will be called once for all
     tasks at the end after tasks are created, we don't need to call
     it as each task detail is being added */
  select @TotalCases      = sum(TD.Innerpacks),
         @TotalUnits      = sum(TD.Quantity),
         @TotalOrders     = count(distinct TD.OrderId),
         @TotalPicks      = count(distinct TD.TaskDetailId),
         @TotalTempLabels = count(distinct TempLabelId)
  from TaskDetails TD
  where (TaskId = @TaskId) and
        (TD.Status not in ('X' /* cancelled */));

  /* Get total weight and voulme here  */
  select  @TotalWeight = sum(TD.Quantity * coalesce(S.UnitWeight, 0)),
          @TotalVolume = sum(TD.Quantity * coalesce(S.UnitVolume, 0))
  from TaskDetails TD
  join SKUs S on (TD.SKUId = S.SKUId)
  where (TD.TaskId = @TaskId);

  /* get all temp labels for the task */
  with TempLabels (LPNId) As
   (
     select distinct LT.LPNId
     from TaskDetails TD
     join LPNTasks LT on (TD.TaskDetailId = LT.TaskDetailId)
     where (TD.TaskId = @TaskId)
   )

  /* get tasks' total carton volume. Also, if the are temp labels for the Task
     then the count of Temp labels is TotalCases. Note that TotalCases above
     is untouched, if there are no temp labels generated */
  select @TotalCases        = count(TL.LPNId),
         @TotalCartonVolume = sum(coalesce(CT.OuterVolume, 0))
  from TempLabels TL
    join LPNs L          on (TL.LPNId = L.LPNId)
    join CartonTypes CT  on (L.CartonType = CT.CartonType);

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_Allocation_GetTaskStatistics */

Go
