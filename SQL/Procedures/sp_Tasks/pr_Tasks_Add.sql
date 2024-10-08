/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/20  TK      pr_Tasks_Add: Changes to update WaveId on Tasks (S2G-152)
  2015/05/09  AY      pr_Tasks_Add: Added new parameter IsTaskAllocated
  2014/06/12  TD      pr_Tasks_AddLPNs:Added new procedure.
  2012/10/05  PKS     pr_Tasks_Add: Small bug fixed to handle Empty Pickzone
  2012/07/16  AY      pr_Tasks_Add: Added Warehouse
  2012/02/01  VM      pr_Tasks_Add: Added ScheduledDate
                      pr_Tasks_Add: Modified to insert TaskDesc as well
  2011/12/29  YA      Renamed 'pr_Tasks_AddOrUpdate' to 'pr_Tasks_Add' and removed update functionality
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Add') is not null
  drop Procedure pr_Tasks_Add;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Add:
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Add
  (@TaskType               TTypeCode,
   @SubTaskType            TTypeCode,
   @TaskDesc               TDescription,
   @Status                 TStatus,
   @DetailCount            TCount,
   @CompletedCount         TCount,
   @WaveId                 TRecordId,
   @BatchNo                TTaskBatchNo,
   @PickZone               TZoneId,
   @PutawayZone            TZoneId,
   @Warehouse              TWarehouse,
   @Priority               TPriority,
   @ScheduledDate          TDateTime,
   @IsTaskAllocated        TFlags,
   @BusinessUnit           TBusinessUnit,
   @Ownership              TOwnership,
   -----------------------------------------------
   @TaskId                 TRecordId        output,
   @CreatedDate            TDateTime = null output,
   @ModifiedDate           TDateTime = null output,
   @CreatedBy              TUserId   = null output,
   @ModifiedBy             TUserId   = null output)
As
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName;

  declare @Inserted table (TaskId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Validations */
  if (@TaskType is null)
    set @vMessageName  = 'InvalidTaskType';
  else
  if (@SubTaskType is null)
    set @vMessageName  = 'InvalidSubTaskType';
  else
  if (@Status is null)
    set @vMessageName  = 'InvalidStatus';
  else
  if(@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsInvalid';
  else
  if (@TaskType is not null) and
     (not exists(select *
                 from EntityTypes
                 where (Entity   = 'Task') and
                       (TypeCode = @TaskType) and
                       (Status   = 'A')))
    set @vMessageName  = 'TaskTypeDoesNotExist';
  else
  if (@SubTaskType is not null) and
     (not exists(select *
                 from EntityTypes
                 where (Entity   = 'SubTask') and
                       (TypeCode = @SubTaskType) and
                       (Status   = 'A')))
    set @vMessageName  = 'SubTaskTypeDoesNotExist';
  else
  if (@Status is not null) and
     (not exists(select *
                 from Statuses
                 where (Entity     = 'Task') and
                       (StatusCode = @Status) and
                       (Status     = 'A')))
    set @vMessageName  = 'StatusDoesNotExist';
  else
  if (coalesce(@PickZone, '') <> '') and
     (not exists(select *
                 from vwPickingZones
                 where (ZoneId = @PickZone)))
    set @vMessageName = 'InvalidPickZone';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Validates TaskId whether it is exists, if it then it updates or inserts  */
  if (not exists(select *
                 from Tasks
                 where TaskId = @TaskId))
    begin
      insert into Tasks(TaskType,
                        TaskSubType,
                        TaskDesc,
                        Status,
                        DetailCount,
                        CompletedCount,
                        WaveId,
                        BatchNo,
                        PickZone,
                        PutawayZone,
                        Warehouse,
                        Priority,
                        ScheduledDate,
                        IsTaskAllocated,
                        Ownership,
                        BusinessUnit,
                        CreatedBy)
                 output inserted.TaskId, inserted.CreatedDate, inserted.CreatedBy
                   into @Inserted
                 select @TaskType,
                        @SubTaskType,
                        @TaskDesc,
                        @Status,
                        @DetailCount,
                        @CompletedCount,
                        @WaveId,
                        @BatchNo,
                        @PickZone,
                        @PutawayZone,
                        @Warehouse,
                        @Priority,
                        @ScheduledDate,
                        @IsTaskAllocated,
                        @Ownership,
                        @BusinessUnit,
                        coalesce(@CreatedBy, System_User);

      select @TaskId      = TaskId,
             @CreatedDate = CreatedDate,
             @CreatedBy   = CreatedBy
      from @Inserted;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_Add */

Go
