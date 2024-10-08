/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/27  SK      pr_CycleCount_CreateTasks: modified logic to output the number of cycle count batches created (HA-1690)
  2020/11/17  SK      pr_CycleCount_Action_CreateTasks, pr_CycleCount_CreateTasks: Added new field mapping to create tasks with RequestedCClevel (HA-1567)
  2020/10/05  PK      pr_CycleCount_CreateTasks: Consider task status when choosing a current batch for cycle count (HA-1488)
  2020/07/10  AJM     pr_CycleCount_CreateTasks : ported from prod (HA-296)
  2018/06/05  OK      pr_CycleCount_CreateTasks: Enhanced to update the RequestedCCLevel on TaskDetails based on Rules (S2G-217)
  2018/03/23  OK      pr_CycleCount_CreateTasks: Corrected the caller as per the latest signature (S2G-XXX)
  2015/06/01  TK      pr_CycleCount_CreateTasks: IsTaskAllocated flag must be 'N' for CycleCount Tasks.
  2015/05/09  AY      pr_CycleCount_CreateTasks: Changed pr_Tasks_Add parameters.
  2014/07/24  TD      pr_CycleCount_CreateTasks:Consider tasksubtype while getting task.
  2014/04/08  PV      pr_CycleCount_CreateTasks: Enhanced to Identify batches created today and and Taskdetails,
  2012/09/05  AY      pr_CycleCount_CreateTasks: Set CreatedBy appropriately.
  2012/08/30  NY      pr_CycleCount_CreateTasks:used TMessage, as complete message is not displaying.
  2012/07/17  AY      pr_CycleCount_CreateTasks: Default for LocationRow if null or else
                      pr_CycleCount_CreateTasks: Add task with Warehouse
  2012/06/30  SP      Placed the transaction controls in 'pr_CycleCount_CreateTasks'.
  2012/02/01  VM      pr_CycleCount_CreateTasks: Modified to retrieve ScheduledDate from xml and add it to task.
  2012/01/23  YA      pr_CycleCount_CreateTasks: Priority value which was hard coded before was made to fetch
                         by renaming it to pr_CycleCount_GetResults and pr_CycleCount_CreateTasks.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_CreateTasks') is not null
  drop Procedure pr_CycleCount_CreateTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_CreateTasks:
    This procedure is used to create cycle count tasks for a given set of
    Locations passed in as XML

    Format:  <CYCLECOUNTTASKS>
               <LOCATIONINFO>
                 <LocationId> </LocationId>
                 <Location> </Location>
                 <PickZone> </PickZone>
               </LOCATIONINFO>
               <OPTIONS>
                 <Priority></Priority>
                 <ScheduledDate></ScheduledDate>
                 <SubTaskType></SubTaskType>
                 <CCProcess></CCProcess>
               </OPTIONS>
             </CYCLECOUNTTASKS>
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_CreateTasks
  (@Locations     varchar(max),
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @FirstTaskId   TRecordID     = null output,
   @LastTaskId    TRecordId     = null output,
   @TasksCount    TCount        = null output,
   @Message       TMessage      = null output)
as
  declare  @ReturnCode        TInteger,
           @MessageName       TMessageName,
           @vTaskId           TRecordId,
           @vTaskDetailId     TRecordId,
           @vTaskDesc         TDescription,
           @vPickZone         TZoneId,
           @vBatchNo          TTaskBatchNo,
           @vFirstBatchNo     TTaskBatchNo,
           @vLastBatchNo      TTaskBatchNo,
           @vNewTaskDetails   TCount,
           @vRow              TLocation,
           @vLocationId       TRecordId,
           @vWarehouse        TWarehouse,
           @vOwnership        TOwnership,
           @vSubTaskType      TFlag,
           @vCCProcess        TOperation,
           @vPriority         TPriority,
           @vScheduledDate    TDateTime,
           @xmlLocations      xml,
           @xmlRulesData      TXML;

  declare @ttCycleLocations Table
          (RecordId        TRecordId  identity (1,1),
           LocationId      TRecordId,
           Location        TLocation,
           PickZone        TZoneId,
           Warehouse       TWarehouse,
           LocationRow     TLocation,
           SortOrder       TInteger null);

begin
begin try
  begin transaction;
  select @ReturnCode    = 0,
         @Message       = null,
         @FirstTaskId   = null,
         @TasksCount    = 0,
         @vFirstBatchNo = null,
         @vLastBatchNo  = null,
         @xmlLocations  = convert(xml, @Locations);

  /* If no locations are passed in, nothing to do, exit */
  if (@xmlLocations is null)
    return;

  /* Get the attributes for the Tasks to be created from the XML */
  select @vPriority      = Records.Cols.value('Priority[1]',      'TPriority'),
         @vScheduledDate = Records.Cols.value('ScheduledDate[1]', 'TDateTime'),
         @vSubTaskType   = Records.Cols.value('SubTaskType[1]',   'TFlag'),
         @vCCProcess     = Records.Cols.value('CCProcess[1]',     'TOperation')
  from @xmlLocations.nodes('CYCLECOUNTTASKS/OPTIONS') as Records(Cols);

  set @vSubTaskType = coalesce(nullif(@vSubTaskType,''), 'D' /* Directed */);

  /* Get the locations into the temp table to work with */
  insert into @ttCycleLocations (LocationId, Location, Pickzone)
    select Records.Cols.value('LocationId[1]' , 'TRecordId'),
           Records.Cols.value('Location[1]'   , 'TLocation'),
           Records.Cols.value('PickZone[1]'   , 'TZoneId'  )
    from @xmlLocations.nodes('CYCLECOUNTTASKS/LOCATIONINFO') as Records(Cols)

  /* Fetch additional details of the locations to group them */
  /* substring(L.Location, 3, 2) - This should be a temporary as LocationRow should actually be setup while Locations are created */
  update @ttCycleLocations
  set LocationRow = coalesce(L.LocationRow, substring(L.Location, 3, 2)),
      PickZone    = coalesce(L.PickingZone, ''),
      Warehouse   = L.Warehouse
  from @ttCycleLocations CCL join Locations L on CCL.LocationId = L.LocationId;

  while (exists(select * from @ttCycleLocations))
    begin
      /* Find the first row of a PickZone to create batch by pickzone and row. */
      select top 1 @vRow        = LocationRow,
                   @vTaskDesc   = LocationRow,
                   @vLocationId = LocationId,
                   @vPickZone   = PickZone,
                   @vWarehouse  = Warehouse
      from @ttCycleLocations
      order by PickZone;

      /* If we do not have a Cycle count batch, create new one. If we do, then
         add a Task Header to it and continue */
      select @vBatchNo = BatchNo,
             @vTaskId   = TaskId
      from Tasks
      where (coalesce(PickZone, '') = coalesce(@vPickZone, '')) and
            (Warehouse     = @vWarehouse              ) and
            (BusinessUnit  = @BusinessUnit            ) and
            (TaskType      = 'CC' /* Cycle Count */   ) and
            (TaskSubType   = @vSubTaskType            ) and
            (ScheduledDate = @vScheduledDate          ) and
            (Priority      = @vPriority               ) and
            (Status        not in ('X' /* Cancelled */, 'C' /* Completed */));

      if (@vBatchNo is null)
        exec pr_Tasks_GetNextBatchNo 'CC', @BusinessUnit, @UserId, @vBatchNo output;

      if (@vTaskId is null)
        begin
          exec pr_Tasks_Add 'CC',           /* CycleCount */               --@TaskType
                            @vSubTaskType,  /* Directed or Non-Directed */
                            @vTaskDesc,                                    --@TaskDesc
                            'N',            /* Not yet started */          --@Status
                            0,                                             --@DetailCount
                            0,                                             --@CompletedCount,
                            0,              /* We won't have BatchId for CC batches */
                            @vBatchNo,
                            @vPickZone,
                            null,                                          --@PutawayZone
                            @vWarehouse,
                            @vPriority,
                            @vScheduledDate,
                            'N' /* No */,   /* IsTaskAllocated */
                            @BusinessUnit,
                            @vOwnership,
                            @vTaskId output,
                            @CreatedBy = @UserId;

          select @TasksCount += 1;
        end

      /* Now add all TaskDetails i.e Locations to the Task Header created */
      insert into TaskDetails(TaskId, Status, LocationId, BusinessUnit, CreatedBy)
        select @vTaskId, 'N' /* New/Not Yet Started */, LocationId,
               @BusinessUnit, @UserId
        from @ttCycleLocations
        where (coalesce(PickZone, '') = coalesce(@vPickZone, '')) and
              (LocationRow = @vRow) and
              (Warehouse   = @vWarehouse)
        order by Location;

      /* Save count of new details just inserted */
      select @vNewTaskDetails = @@rowcount;

      /* Update the counts, status of the Task Header */
      exec pr_Tasks_UpdateCount @vTaskId, '+', @vNewTaskDetails, default /* Completed Count */, @UserId;

      /* Build the xml to update the RequestedCCLevel for newly inserted Locations/TaskDetails */
      select @xmlRulesData = '<RootNode>' +
                                dbo.fn_XMLNode('TaskId',       @vTaskId) +
                                dbo.fn_XMLNode('PickZone',     @vPickZone) +
                                dbo.fn_XMLNode('LocationRow',  @vRow) +
                                dbo.fn_XMLNode('Warehouse',    @vWarehouse) +
                                dbo.fn_XMLNode('CCProcess',    @vCCProcess) +
                             '</RootNode>'

      /* Update the RequestedCCLevel on newly created TaskDetails in Rules */
      exec pr_RuleSets_ExecuteRules 'CycleCount_LocationCountDetail', @xmlRulesData;

      /* Delete the Locations that we have just created task details for */
      delete from @ttCycleLocations
      where (PickZone    = @vPickZone) and
            (LocationRow = @vRow) and
            (Warehouse   = @vWarehouse);

      /* Initialize values to null and set Count of tasks created */
      select @FirstTaskId   = coalesce(@FirstTaskId, @vTaskId),
             @LastTaskID    = @vTaskId,
             @vFirstBatchNo = coalesce(@vFirstBatchNo, @vBatchNo),
             @vLastBatchNo  = @vBatchNo,
             @vPickZone     = null,
             @vTaskId       = null,
             @vBatchNo      = null,
             @vWarehouse    = null;
    end

  if (@TasksCount = 1)
    exec @Message = dbo.fn_Messages_Build 'CC_CreateTasks_Successful1', Default, @vFirstBatchNo;
  else
  if (@TasksCount > 1)
    exec @Message = dbo.fn_Messages_Build 'CC_CreateTasks_Successful2',
                      @TasksCount, @vFirstBatchNo, @vLastBatchNo;
  else
    exec @Message = dbo.fn_Messages_Build 'CC_CreateTasks_NoneCreated';

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_CycleCount_CreateTasks */

Go
