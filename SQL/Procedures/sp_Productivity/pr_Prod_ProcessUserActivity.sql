/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/03  MS      pr_Prod_MainProcess, pr_Prod_ProcessATRecord,
                      pr_Prod_ProcessUserActivity, pr_Prod_DS_GetUserProductivity: Changes to insert WH into Productivity table (BK-807)
  2020/01/02  SK      pr_Prod_ProcessATRecord, pr_Prod_ProcessUserActivity: Revisions post the new design discussion (CIMS-2871)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Prod_ProcessUserActivity') is not null
  drop Procedure pr_Prod_ProcessUserActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Prod_ProcessUserActivity: This procedure processes the activity of
    a particular user for the given date from the AuditTrail and splits them
    into assignments and finally generates Productivity records and productivity
    details. When done, it flags the AT records as processed.

  If UserId AND Date are not passed in, then it takes the next available user/date
  whose productivity has not been processed and processes that user for the specific
  date.

  This procedure is invoked by the pr_Prod_MainProcess procedure which runs in a job.
------------------------------------------------------------------------------*/
Create Procedure pr_Prod_ProcessUserActivity
  (@ATUserId       TUserId = null,
   @ATDate         TDate   = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId = 'cimsdba',
   @Debug          TFlags  = 'N')
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,

          @vRunThisProc           TFlags,
          @vATUserId              TUserId,
          @vATDate                TDate,
          @vATDateNext            TDate,
          @vAssignment            TDescription;

  declare @ttATList               TEntityValuesTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessage      = null,
         @vMessageName  = null,
         @vRunThisProc  = null;

  /* Create required hash tables if they do not exist */
  if (object_id('tempdb..#ATProcessed') is null)
    begin
      select * into #ATProcessed from @ttATList;
      select @vRunThisProc = 'Y' /* yes */;
    end

  /* Get the userid and date as given in input */
  if (@ATUserId is not null) and (@ATDate is not null)
    select @vATUserId = @ATUserId, @vATDate = @ATDate;
  else
    /* Fetch unique records based on userid, date from AuditTrail table */
    select distinct top 1 @vATUserId = UserId,
                          @vATDate   = ActivityDate
    from AuditTrail
    where (ProductivityFlag = 'N' /* Not yet processed */) and
          (BusinessUnit     = @BusinessUnit) and
          (coalesce(UserId, '') not in ('', 'cIMSAgent', 'cimsdba', 'cimsadmin'))
    group by ActivityDate, UserId;

  /* Next day - not in use */
  --select @vATDateNext = dateadd(dd, 1, @vATDate);

  /* Get all the records for the userid & activityDate */
  select AT.AuditId as RecordId, AT.UserId, AT.ActivityType,
         PO.Operation, PO.SubOperation, PO.JobCode, PO.Mode,
         AT.AuditId, AT.ActivityDateTime, AT.BusinessUnit,
         @vAssignment as Assignment, AD.TaskId, AD.OrderId,
         AD.WaveId, AD.Warehouse, AD.Ownership, AT.ActivityDate
  into #ProductivitySubSet
  from AuditTrail AT
    join ProdOperations PO on (AT.ActivityType = PO.ActivityType)
    left join AuditDetails AD on (AT.AuditId = AD.AuditId)
  where (AT.ProductivityFlag = 'N' /* Not yet processed */) and
        (AT.BusinessUnit     = @BusinessUnit) and
        (AT.ActivityDate     = @vATDate) and
        (AT.UserId           = @vATUserId)
  order by AuditId;

  if (charindex('D', @Debug) > 0) select top 3 * from #ProductivitySubSet order by RecordId;

  if (not exists(select * from #ProductivitySubSet))
    goto ErrorHandler;

  /* Add index to the temporary table */
  create clustered index itx_ProdSubset_RecordId on #ProductivitySubSet(RecordId);
  create index itx_ProdSubset_AuditId on #ProductivitySubSet(AuditId);
  create index itx_ProdSubset_PrimarySet on #ProductivitySubSet(UserId, Assignment, BusinessUnit);

  if (charindex('T', @Debug) > 0) print 'Assignments'+
                                        '; User: ' + cast(@vATUserId as varchar(20)) +
                                        '; Date: ' + cast(@vATDate as varchar(20)) +
                                        '; ProcessTime: ' + convert(varchar(25), getdate(), 121);

  /* Temporary code to be cleaned up later
     For Reservation right now, audit is being logged as LPNPick with no TaskId reference */
  update #ProductivitySubSet
  set Operation = case
                    when (ActivityType = 'LPNPick') and (TaskId is null) then 'Reservation'
                    else Operation
                  end;

  /* Create assignments */
  exec pr_Prod_CreateAssignments @BusinessUnit, @UserId, @Debug;

  if (charindex('T', @Debug) > 0) print 'ProcessAudits'+
                                        '; ProcessTime: '+convert(varchar(25), getdate(), 121);

  /* The Audit records have been classified into assignments, now summarise and
     insert into Productivity Header & Detail tables */
  exec pr_Prod_ProcessATRecord @BusinessUnit, @UserId, @Debug;

  /* If the main process is run which is for all users, then Record the audit records that are processed for each user
     Else this proc can be called too for a specific user or specific date, then update */
  if (@vRunThisProc is null)
    insert into #ATProcessed (EntityId)
      select AT.AuditId
      from AuditTrail AT with (nolock)
        join #ProductivitySubSet PT on AT.AuditId = PT.AuditId;
  else
    update AT
    set AT.ProductivityFlag = 'Y' /* Yes */
    from AuditTrail AT
      join #ProductivitySubSet PT on AT.AuditId = PT.AuditId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Prod_ProcessUserActivity */

Go
