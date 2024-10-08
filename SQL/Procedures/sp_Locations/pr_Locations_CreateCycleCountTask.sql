/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/24  PK      pr_Locations_CreateCycleCountTask: Ported changes done by Pavan (HA-2050)
  2016/07/13  OK      pr_Locations_CreateCycleCountTask: Enhanced to return if location does not have Pickzone on it (HPI-247)
  2014/04/10  PV      pr_Locations_CreateCycleCountTask: Added new procedure to create Location Cycle Count.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_CreateCycleCountTask') is not null
  drop Procedure pr_Locations_CreateCycleCountTask;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_CreateCycleCountTask:
    This procedure is used to create cycle count tasks for a single location.
    Typically used to generate a cycle count on a Location where there is a
    short pick
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_CreateCycleCountTask
  (@LocationId    TRecordId,
   @Operation     TOperation    = 'ShortPick',
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit,
   @Message       TMessage      = null output)
as
  declare  @vReturnCode       TInteger,
           @vWarehouse        TWarehouse,
           @vLocation         TLocation,
           @vPickZone         TZoneId,
           @vxmlLocationInfo  XML,
           @vxmlTaskOptions   XML,
           @vxmlInput         TXML,
           @vPriority         TInteger,
           @vCreateTask       TFlag,
           @vTaskDetailId     TRecordId,
           @FirstTaskId       TRecordId,
           @LastTaskId        TRecordId,
           @TasksCount        TTaskBatchNo,
           @vFirstBatchNo     TTaskBatchNo,
           @vLastBatchNo      TTaskBatchNo,
           @vTaskSubType      TTypeCode;

begin
begin try

  select @vReturnCode = 0;

  /* select control options for Creating Cycle count task for given operation */
  select @vPriority    = dbo.fn_Controls_GetAsInteger(@Operation, 'CCTaskPriority', '1', @BusinessUnit, @UserId),
         @vCreateTask  = dbo.fn_Controls_GetAsBoolean(@Operation, 'CreateCC', 'Y', @BusinessUnit, @UserId),
         @vTaskSubType = case when @Operation = 'Auditing' then 'PN' /* picking not empty */
                              when @Operation = 'ShortPick' then 'L2' /* Supervisor Count */
                              else 'D' /* Direct */
                         end;

  /* If control is set not to create cycle count task then we will not do anything */
  if (@vCreateTask = 'N')
    return;

  select @LocationId = LocationId,
         @vLocation  = Location,
         @vPickZone  = PickingZone,
         @vWarehouse  = Warehouse
  from Locations
  where (LocationId = @LocationId);

  /* Verify If TaskDetail is already created for the Location in todays batch */
  select @vTaskDetailId = TD.TaskDetailId
  from vwTaskDetails TD
    join Tasks T on (TD.TaskId = T.TaskId)
  where (TD.LocationId   = @LocationId) and
        (coalesce(TD.PickZone,'')   = coalesce(@vPickZone,'' )) and
        (T.Warehouse     = @vWarehouse ) and
        (TD.TaskStatus   = 'N' /* Not Yet Started */) and
        (TD.BusinessUnit = @BusinessUnit) and
        (cast(T.CreatedDate as Date) = cast(getdate() as date));

  /* If there is a TaskDetail already for the same Location, then exit.
     Or if there is no pickzone on the Location exit as PickZone is required to create the task */
  if (@vTaskDetailId is not null) or (@vPickZone is null)
    return;

  /* Attributes for the Tasks to be created from the XML */
  set @vxmlTaskOptions = (select @vPriority        as Priority,
                                 current_timestamp as ScheduledDate,
                                 @vTaskSubType     as SubTaskType /* Directed Cycle Count */
                          for XML raw(''), type, elements, root('OPTIONS'));

  set @vxmlLocationInfo = (select @LocationId as LocationId,
                                  @vLocation  as Location,
                                  @vPickZone  as PickZone
                           for XML raw(''), type, elements, root('LOCATIONINFO'));

  set @vxmlInput = (select '<CYCLECOUNTTASKS>'   +
                             convert(varchar(max), @vxmlLocationInfo) +
                             convert(varchar(max), @vxmlTaskOptions ) +
                           '</CYCLECOUNTTASKS>');

  exec @vReturnCode =  pr_CycleCount_CreateTasks @vxmlInput,
                                                 @BusinessUnit,
                                                 @UserId,
                                                 @FirstTaskId output,
                                                 @LastTaskId  output,
                                                 @TasksCount  output,
                                                 @Message     output;

end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_CreateCycleCountTask */

Go
