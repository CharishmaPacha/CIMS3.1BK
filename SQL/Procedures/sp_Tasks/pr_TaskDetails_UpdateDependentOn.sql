/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/08  TK      pr_TaskDetails_UpdateDependentOn: Ignore canceled tasks (FBV3-967)
              AY      pr_TaskDetails_UpdateDependentOn: Renamed from pr_TaskDetails_UpdateDependencies &
                        Corrected to work against new model of PR Lines (OB2-Support)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_UpdateDependentOn') is not null
  drop Procedure pr_TaskDetails_UpdateDependentOn;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_UpdateDependentOn: A Task detail can be dependent on one or more replenish tasks,
         a replenish tasks can contain multiple LPNs too so the idea here
         is to update DependentOn with Combination of Tasks & LPNs.
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_UpdateDependentOn
as
  /* Variable declaration */
  declare @vRecordId        TRecordId,
          @vTaskId          TRecordId,
          @vTaskDetailId    TRecordId,
          @vPrevTaskId      TRecordId,
          @vDependentTasks  TDescription,
          @vDependentLPNs   TDescription,
          @vDependentOn     TDescription;

  declare @ttDependencies table (TaskId         TRecordId,
                                 TaskDetailId   TRecordId,
                                 RTaskId        TRecordId,
                                 RLPN           TLPN,
                                 RLPNStatus     TStatus,
                                 RTaskStatus    TStatus,
                                 PicklaneLPNId  TRecordId,
                                 RecordId       TRecordId identity(1,1));
begin
  /* For each task and TaskDetail get the task id and LPNs that they it is dependent upon */
  with DependencyTaskDetails(TaskId, TaskDetailId, RTaskId, RLPN,  RLPNStatus, RTaskStatus, PicklaneLPNId) as
  (
    select distinct TD.TaskId, TD.TaskDetailId, RTD.TaskId, L.LPN, L.Status, RTD.Status, LD.LPNId
    from Tasks T
      join TaskDetails       TD on (T.TaskId            = TD.TaskId                 )
      join LPNDetails        LD on (TD.LPNId            = LD.LPNId                  ) and
                                   (LD.OnhandStatus     = 'D'/* Directed  */ )
      left outer join LPNs   L  on (LD.ReplenishOrderId = L.OrderId                 ) and
                                   (LD.SKUId            = L.SKUId                   )
      left outer join TaskDetails RTD on (L.LPNId             = RTD.LPNID          )
    where (T.DependencyFlags in ('R', 'S')) and (TD.DependencyFlags in ('R', 'S'))
  )
  insert into @ttDependencies
      select * from DependencyTaskDetails;

  with DestinedLPNs (TaskId, TaskDetailId, RTaskId, RLPN, RLPNStatus, RTaskStatus) as
  (
    select DT.TaskId, DT.TaskDetailId, L2.TaskId, L2.LPN, L2.Status, T.Status
    from @ttDependencies DT
      join LPNs L1 on (DT.PicklaneLPNId = L1.LPNId)
      join LPNs L2 on (L1.LPN           = L2.DestLocation) and
                      (L2.Status        <> 'C' /* Consumed */)
      left outer join Tasks T on L2.TaskId = T.TaskId
    where DT.RLPN is null
  )
  insert into @ttDependencies (TaskId, TaskDetailId, RTaskId, RLPN, RLPNStatus, RTaskStatus)
    select * from DestinedLPNs order by TaskId

  select @vRecordId = 0, @vPrevTaskId = 0;

  /* Loop thru and Process all the dependent TaskDetail */
  while exists(select * from @ttDependencies where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId     = RecordId,
                   @vTaskId       = TaskId,
                   @vTaskDetailId = TaskDetailId
      from @ttDependencies
      where RecordId > @vRecordId
      order by RecordId;

      /* A TaskDetail can be dependent on one or more replenish tasks, a replenish tasks can contain multiple LPNs too so the idea here
         is to update DependentOn with Combination of Tasks & LPNs as shown below

         1. If Original tasks is T1, TaskDetail TD1 and these are dependent on Replenish Task RT1 and RT1 is associated with LPNs L1, L2
            then we would update DependentOn as
              Task: RT1 LPNs: L1, L2
         2. If Original tasks is T1, TaskDetail TD1 and these are dependent on Replenish Task RT1 and RT2, both the tasks are associated with LPNs L1, L2 & L3, L4
            then we would update DependentOn as
              Task: RT1, RT2 LPNs: L1, L2, L3, L4
      */
      select @vDependentTasks = stuff((select distinct ',' + coalesce(cast(RTaskId as varchar), '')
      from  @ttDependencies
      where (TaskDetailId = @vTaskDetailId) and (RTaskStatus <> 'C' /* Completed */)
      for xml path('')), 1, 1, '');

      select @vDependentLPNs = stuff((select distinct ',' + coalesce(RLPN, '')
      from  @ttDependencies
      where (TaskDetailId = @vTaskDetailId) and (RLPNStatus <> 'C' /* Consumed */)
      for xml path('')), 1, 1, '');

      select @vDependentOn = coalesce('Tasks: ' + @vDependentTasks + ' ', '') +
                             coalesce('LPNs: ' + nullif(@vDependentLPNs, ''), '');

      /* Update Dependencies on TaskDetail */
      update TaskDetails
      set DependentOn = LEFT(@vDependentOn, 120) -- DependentOn is TDescription
      where (TaskDetailId = @vTaskDetailId);

      if (@vPrevTaskId <> @vTaskId)
        begin
          select @vDependentTasks = stuff((select distinct ',' + coalesce(cast(RTaskId as varchar), '')
          from  @ttDependencies
          where (TaskId = @vTaskId) and (RTaskStatus <> 'C' /* Completed */)
          for xml path('')), 1, 1, '');

          update Tasks
          set DependentOn = LEFT('Tasks: ' + @vDependentTasks, 120) -- DependentOn is TDescription
          where (TaskId = @vTaskId);

          select @vPrevTaskId = @vTaskId;
        end
    end
end /* pr_TaskDetails_UpdateDependentOn */

Go
