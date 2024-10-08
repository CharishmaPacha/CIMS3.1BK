/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/12  VM      pr_Alerts_SplitTaskDetails: Added (OB2-GoLive)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_SplitTaskDetails') is not null
  drop Procedure pr_Alerts_SplitTaskDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_SplitTaskDetails:
    Identifies orphan D (Directed) lines on picklane Locations.
    Sends alert, if there are are orphan D lines.

  @ShowModifiedInLastXMinutes
    - Considers all entities which are modified in last X minutes
  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only
  @EntityId
    - If passed, ignores all other entities by considering the passed in EntityId
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_SplitTaskDetails
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 43200 /* Works for entities which are modified in 30 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
As
begin

  /* Get the totals of all D Lines */
  select TD.TaskId, T.Status, OrderdetailId, LPNDetailid, count(*) NumPicks, MIN(SKUId) SKUId, MIN(TaskDetailId) TaskDetId, MAX(TaskDetailId) TaskDetId2
  into #ttAlertData
  from TaskDetails TD with (nolock)
    join Tasks T      with (nolock) on TD.TaskId = T.TaskID
  where (TD.TaskId = coalesce(@EntityId, TD.TaskId)) and (T.Status IN ('N', 'I')) and (TD.Status NOT IN ('X')) and (TaskType = 'PB')
  group by TD.Taskid, OrderdetailId, LPNDetailId, T.Status
  having count(*) > 1

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select TaskId, TaskStatus, OrdDetId, LPNDetId, NumPicks, SKUId, TaskDetId, TaskDetId2
      from #ttAlertData
      order by TaskId;

      return(0);
    end

  /* Email the results */
  if (exists(select * from #ttAlertData))
    exec pr_Email_SendQueryResults @AlertCategory = 'pr_Alerts_SplitTaskDetails', @TableName = '#ttAlertData', @BusinessUnit  = @BusinessUnit;

end /* pr_Alerts_SplitTaskDetails */

Go
