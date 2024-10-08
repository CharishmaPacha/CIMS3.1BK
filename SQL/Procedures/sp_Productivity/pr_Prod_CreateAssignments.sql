/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/24  SK      pr_Prod_CreateAssignments: New procedure (CIMS-2871)
  if object_id('dbo.pr_Prod_CreateAssignments') is null
  exec('Create Procedure pr_Prod_CreateAssignments as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Prod_CreateAssignments') is not null
  drop Procedure pr_Prod_CreateAssignments;
Go
/*------------------------------------------------------------------------------
  Proc pr_Prod_CreateAssignments: Processes one user' activity for a period of time
    and breaks/groups them into assignments. An assignment is a piece of work
    accomplished in sequence in a single duration. For example, from the start of
    one Pick task to the picking and drop off is all consideered as one assignment.

  #ProductivitySubSet is the activity of one user for a particular date
    created with columns from AuditTrail.
    run time under pr_Prod_ProcessUserActivity
------------------------------------------------------------------------------*/
Create Procedure pr_Prod_CreateAssignments
  (@BusinessUnit   TBusinessUnit,
   @UserId         TUserId = 'cimsdba',
   @Debug          TFlags  = 'N')
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vPrevRecordId          TRecordId,
          @vxmlRulesData          TXML,

          @vTimeAllowedInSecs     TInteger,
          @vActivityTime          TDateTime,
          @vActivityType          TActivityType,
          @vOperation             TOperation,
          @vMode                  TFlag,
          @vTimeElapsed           TInteger,
          @vIsNewAssignment       TFlags,
          @vAssignmentCount       TInteger,
          @vCurrentAssignment     TName,
          @vPreviousTime          TDateTime,
          @vPrevOperation         TOperation,
          @vPrevMode              TFlag,
          @vConsiderPrevTime      TFlag;

  declare @ttAssignments table (RecordId          TRecordId identity (1,1) not null,
                                UserId            TUserId,
                                Assignment        TDescription,
                                AuditId           TRecordId,
                                ActivityDateTime  TDateTime);
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @vPrevRecordId     = 0,
         @vAssignmentCount  = 0,
         @vPrevOperation    = 'none',
         @vPrevMode         = null,
         @vPreviousTime     = null,
         @vConsiderPrevTime = 'N' /* No */;

  /* Fetch controls or other variables */
  select @vTimeAllowedInSecs = dbo.fn_Controls_GetAsInteger('Productivity', 'TimeWindow', 900, @BusinessUnit, @UserId);

  /* Process each record to break into Assignments */
  while (exists (select * from #ProductivitySubSet where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId     = RecordId,
                   @vActivityTime = ActivityDateTime,
                   @vOperation    = Operation,
                   @vMode         = Mode,
                   @vActivityType = ActivityType
      from #ProductivitySubSet
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Temporary code to be removed later
         This activity type is preceeded with Reservation process then treat it as end of process
         Do not assign a new assignment to this activity alone */
      if (coalesce(@vPrevOperation, '') = 'Reservation') and
         (@vOperation = 'Picking') and
         (@vActivityType = 'PickPalletDropped')
        select @vOperation = 'Reservation';

      /* Time elapsed since last activity */
      select @vTimeElapsed = case
                               when @vPreviousTime is not null then datediff(ss, @vPreviousTime, @vActivityTime)
                               else 0
                             end;

      select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                                dbo.fn_XMLNode('Mode',              @vMode) +
                                dbo.fn_XMLNode('Operation',         @vOperation) +
                                dbo.fn_XMLNode('PrevOperation',     @vPrevOperation) +
                                dbo.fn_XMLNode('PrevMode',          @vPrevMode) +
                                dbo.fn_XMLNode('PrevRecordId',      @vPrevRecordId) +
                                dbo.fn_XMLNode('TimeElapsed',       @vTimeElapsed) +
                                dbo.fn_XMLNode('TimeAllowedInSecs', @vTimeAllowedInSecs));

      /* Evaluate rules to decide the assignment */
      exec pr_RuleSets_Evaluate 'ProductivityAssignments', @vxmlRulesData, @vIsNewAssignment output;

      if (@vIsNewAssignment = 'Y' /* Yes */)
        begin
          select @vAssignmentCount += 1;

          /* Assignment Id = Date + seqno + operation */
          select @vCurrentAssignment = replace(replace(replace(convert(varchar(19), @vActivityTime, 120), '-',''), ' ', ''), ':', '')
                                       + '-' + cast(@vAssignmentCount as char(5)) + '-' + coalesce(@vOperation, 'Undefined');

          /* Evaluate rules to determine start time of a new assignment */
          exec pr_RuleSets_Evaluate 'ProductivityAssignmentsTime', @vxmlRulesData, @vConsiderPrevTime output;
        end

      if (@vIsNewAssignment <> 'I' /* Ignore */)
        /* Insert the Assignment reference for the Record */
        insert into @ttAssignments (Assignment, AuditId, ActivityDateTime)
          select @vCurrentAssignment, @vRecordId, case
                                                    when @vConsiderPrevTime = 'Y' /* Yes */ then @vPreviousTime
                                                    else null
                                                  end

      /* Reset all fields */
      select @vPreviousTime     = @vActivityTime,
             @vPrevOperation    = @vOperation,
             @vPrevMode         = @vMode,
             @vPrevRecordId     = @vRecordId,
             @vIsNewAssignment  = 'N' /* No */,
             @vConsiderPrevTime = 'N' /* No */;
    end /* end while loop */

    if (charindex('T', @Debug) > 0) print 'Assignments-Done'+
                                        '; ProcessTime: '+convert(varchar(25), getdate(), 121);

    /* Update the Assignment reference from temporary table */
    update PSS
    set PSS.Assignment       = TTA.Assignment,
        PSS.ActivityDateTime = coalesce(TTA.ActivityDateTime, PSS.ActivityDateTime),
        /* temp code to handle flaw in reservation auditing */
        PSS.Operation        = case when TTA.Assignment like '%Reservation' then 'Reservation' else PSS.Operation end
    from #ProductivitySubSet PSS
      join @ttAssignments TTA on PSS.AuditId = TTA.AuditId;

    /* Delete records which have no assignments */
    delete from #ProductivitySubSet where (Assignment is null);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Prod_CreateAssignments */

Go
