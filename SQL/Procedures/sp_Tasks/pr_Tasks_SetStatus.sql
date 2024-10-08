/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/07  SK/AY   pr_Tasks_SetStatus: Update CC task's detail count based on open task details (HA-2567)
  2019/06/20  AY      pr_Tasks_SetStatus: Enhanced to calc IPs/UnitsCompleted
  2019/08/14  AY      pr_Tasks_SetStatus: Added StopTime (OB2-900)
  2019/05/23  AY      pr_Tasks_SetStatus: Order Count getting cleared
  2018/11/14  VM      pr_Tasks_SetStatus: Calculate UnitsCompleted as well on Tasks (OB2-701)
  2018/08/15  PK      pr_TaskDetails_Close, pr_Tasks_SetStatus: Updating the DepdendencyFlags as '-' if the task or task detail
                        is cancelled or completed and if the DependencyFlags are still short or waiting on replenishment,
                        Also clearing DependentOn when task or task detail is cancelled or completed. (OB2-579).
  2018/07/11  OK      pr_Tasks_SetStatus: Considered the cancelled TaskDetail count to calculate the Task Status (S2G-1019)
  2017/08/28  CK      pr_Tasks_SetStatus: Recalculate the InProgress Status Count from the Task details while pick the units Partially (CIMS-1533)
  2017/06/09  PSK     pr_Tasks_SetStatus,pr_Tasks_GetLabelsToPrint: Updated "StartTime","EndTime", and "WaveGroup" fields (CIMS-1400)
  2017/04/18  VM      (GNC-1516)
                      pr_Tasks_SetStatus: Set task as canceled when there are no details exists
                      pr_TasksDetails_TransferUnits: Call Tasks_SetStatus with recount Flag ON as recounts.
  2016/09/17  KL      pr_Tasks_SetStatus: Update "Start Time" and "end Time" on UDF's (HPI-693)
  2015/06/30  YJ/VM   pr_Tasks_ReCount, pr_Tasks_SetStatus: to summaries distinct order count (SRI-328)
  2014/05/09  AY      pr_Tasks_SetStatus: Compute TotalInnerPacks and Units
  2014/04/17  TD      pr_Tasks_SetStatus:Included Onhold status while updating status.
  2014/04/17  TD      pr_Tasks_SetStatus: Included Onhold status while updating status.
  2014/02/10  NY      pr_Tasks_SetStatus : Set default counts to 0.
  2013/12/22  TD      pr_Tasks_SetStatus: Changes to avoid assigning task to two users at the same time.
  2013/11/12  TD      pr_Tasks_SetStatus: Small fix: Set task as complete if the sum of Completed Count
  2013/09/26  TD      pr_Tasks_SetStatus:Updating detail count, Cancelled Status.
                      pr_Tasks_SetStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_SetStatus') is not null
  drop Procedure pr_Tasks_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_SetStatus:
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_SetStatus
  (@TaskId   TRecordId,
   @UserId   TUserId,
   @Status   TStatus = null,
   @Recount  TFlag   = null)
as
  declare @ReturnCode              TInteger,
          @MessageName             TMessageName,

          @vDetailCount            TCount,
          @vCompletedCount         TCount,
          @vInProgressCount        TCount,
          @vCancelledCount         TCount,
          @vOnHoldCount            TCount,
          @vTotalInnerPacks        TCount,
          @vTotalUnits             TCount,
          @vTotalIPsCompleted      TCount,
          @vTotalUnitsCompleted    TCount,
          @vOrderCount             TCount,
          @vNote1                  TDescription,
          @ModifiedDate            TDateTime,
          @ModifiedBy              TUserId,
          @vNewStatus              TStatus,
          @vTaskAssignedToDiffUser TFlag;

begin /* pr_Tasks_SetStatus */
  SET NOCOUNT ON;

  select @ReturnCode      = 0,
         @MessageName     = null,
         @vDetailCount    = 0,
         @vCompletedCount = 0,
         @vCancelledCount = 0;

  /* Calculate Status, if not provided */
  if (@Status is null)
    begin
      /* If we need to recalculate the counts from the details do so, else trust the
         counts already on the task */
      if (@Recount is not null)
        begin
          /* Get the total count of Locations and completed Locations on the Task header */
          select @vDetailCount         = count(*),
                 @vOnHoldCount         = sum(case when Status = 'O'  /* On Hold */     then 1              else 0 end),
                 @vCompletedCount      = sum(case when Status = 'C'  /* Completed */   then 1              else 0 end),
                 @vInProgressCount     = sum(case when Status = 'I'  /* In Progress */ then 1              else 0 end),
                 @vCancelledCount      = sum(case when Status = 'X'  /* Cancelled */   then 1              else 0 end),
                 @vTotalInnerPacks     = sum(case when Status <> 'X' /* Cancelled */   then InnerPacks     else 0 end),
                 @vTotalUnits          = sum(case when Status <> 'X' /* Cancelled */   then Quantity       else 0 end),
                 @vTotalIPsCompleted   = sum(case when Status <> 'X' /* Cancelled */   then InnerPacksCompleted else 0 end),
                 @vTotalUnitsCompleted = sum(case when Status <> 'X' /* Cancelled */   then UnitsCompleted      else 0 end)
          from TaskDetails
          where (TaskId = @TaskId);

          /* I don't know why we need to redo order count here. NumOrders is established at time of Task creation and
             doesn't change until tasks are cancelled */
          -- select @vOrderCount = count(distinct OrderId) from TaskDetails where (TaskId = @TaskId) and (Status <> 'X');
        end
      else
        begin
          select @vDetailCount    = DetailCount,
                 @vCompletedCount = CompletedCount
          from Tasks
          where (TaskId = @TaskId);
        end

      select @Status = case
                         when (@vCancelledCount = @vDetailCount)                    then 'X'  /* Cancelled */
                         when (@vCompletedCount + @vCancelledCount = @vDetailCount) then 'C'  /* Completed */
                         when (@vOnHoldCount    + @vCancelledCount = @vDetailCount) then 'O'  /* On Hold */
                         when (@vInProgressCount > 0) or (@vCompletedCount > 0)     then 'I'  /* In Progress */
                         when (@vCompletedCount <= 0)                               then 'N'  /* Not yet started */
                       end;
    end
  else
  if (@Status = 'I' /* InProgress */) /* we are passing status as I InProgress while picking */
    begin
      /* Check if the task is already in progress with another user or not. If so,
         we raise error */
      if (exists(select * from Tasks
                 where TaskId = @TaskId and
                       Status = 'I' /* In progress */ and
                       AssignedTo <> @UserId))
        select @vTaskAssignedToDiffUser = 'Y'
      else
        select @vTaskAssignedToDiffUser = 'N'
    end

  /* Validate here, whether the task is assigned to another user or not */
  if (@vTaskAssignedToDiffUser = 'Y' /* yes */)
    begin
      select @MessageName = 'TaskAlreadyAssigned';
      select @vNote1 AssignedTo from Tasks where TaskId = @TaskId;
    end

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update Tasks Status, If InProgress, assign it to the given user */
  update Tasks
  set
    DetailCount          = case when @Recount = 'Y' /* Yes */ and TaskType = 'CC' then @vDetailCount - @vCancelledCount
                                when @Recount = 'Y' /* Yes */                     then @vDetailCount
                                else DetailCount
                           end,
    CompletedCount       = case when @Recount = 'Y' /* Yes */ then @vCompletedCount      else CompletedCount end,
    TotalInnerPacks      = case when @Recount = 'Y' /* Yes */ then @vTotalInnerPacks     else TotalInnerPacks end,
    TotalUnits           = case when @Recount = 'Y' /* Yes */ then @vTotalUnits          else TotalUnits end,
    TotalIPsCompleted    = case when @Recount = 'Y' /* Yes */ then @vTotalIPsCompleted   else TotalIPsCompleted end,
    TotalUnitsCompleted  = case when @Recount = 'Y' /* Yes */ then @vTotalUnitsCompleted else TotalUnitsCompleted end,
    --OrderCount      = coalesce(@vOrderCount, OrderCount),
    @vNewStatus          =
    Status               = coalesce(@Status, Status),
    AssignedTo           = case when (@vNewStatus = 'I' /* Inprogress */) then @UserId
                                when (@vNewStatus = 'N' /* New */       ) then null
                                else AssignedTo
                           end,
    DependencyFlags      = case when (@vNewStatus in ('C', 'X' /* Completed, Cancelled */)) and
                                     (DependencyFlags in ('R', 'S' /* Replenish, Short */)) then '-'
                                else DependencyFlags
                           end,
    DependentOn          = case when (@vNewStatus in ('C', 'X' /* Completed, Cancelled */)) then null else DependentOn end,
    StartTime            = case when (@vNewStatus = 'I' /* Inprogress */) and (StartTime is null) then convert(varchar, getdate(), 121) else StartTime end,
    StopTime             = case when (@vNewStatus = 'C' /* Completed*/) then convert(varchar, getdate(), 121) else StopTime end,
    EndTime              = case when (@vNewStatus = 'C' /* Completed*/) then convert(varchar, getdate(), 121) else EndTime end,
    ModifiedDate         = case when coalesce(@Status, Status) = 'N' then null else current_timestamp end,
    ModifiedBy           = case when coalesce(@Status, Status) = 'N' then null else coalesce(@UserId, System_User) end
  where (TaskId = @TaskId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vNote1;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Tasks_SetStatus */

Go
