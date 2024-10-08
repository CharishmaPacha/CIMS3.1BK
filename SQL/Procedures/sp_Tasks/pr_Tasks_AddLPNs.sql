/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/06/12  TD      pr_Tasks_AddLPNs:Added new procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_AddLPNs') is not null
  drop Procedure pr_Tasks_AddLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_AddLPNs: This procedure will call while user doing unit picking.
      For every pick we will insert data into this table.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_AddLPNs
  (@TaskId                 TRecordId,
   @TaskDetailId           TRecordId,
   @LPNId                  TRecordId,
   @LPNDetailId            TRecordId,
   -----------------------------------------------
   @RecordId               TRecordId        output,
   @CreatedDate            TDateTime = null output,
   @ModifiedDate           TDateTime = null output,
   @CreatedBy              TUserId   = null output,
   @ModifiedBy             TUserId   = null output)
As
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vPickBatchId   TRecordId,
          @vPickBatchNo   TPickBatchNo,
          @vDestZone      TZoneId,
          @vWarehouse     TWarehouse,
          @vBusinessUnit  TBusinessUnit;

  declare @Inserted table (RecordId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Do validations here */

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* select details here */
  select @vPickBatchId  = PickBatchId,
         @vPickBatchNo  = PickBatchNo,
         @vDestZone     = DestZone,
         @vWarehouse    = DestWarehouse,
         @vBusinessUnit = BusinessUnit
  from LPNs
  where (LPNId = @LPNId);

  /* Validates TaskId whether it is exists, if it then it updates or inserts  */
  if (not exists(select *
                 from LPNTasks
                 where RecordId = @RecordId))
    begin
      insert into LPNTasks(PickBatchId, PickBatchNo, TaskId, TaskDetailId,
                           LPNId, LPNDetailId, Status, Warehouse,
                           BusinessUnit, CreatedBy)
        output inserted.RecordId, inserted.CreatedDate, inserted.CreatedBy
          into @Inserted
        select @vPickBatchId, @vPickBatchNo, @TaskId, @TaskDetailId,
               @LPNId, @LPNDetailId, 'A', @vWarehouse,
               @vBusinessUnit, coalesce(@CreatedBy, System_User);

      select @RecordId    = RecordId,
             @CreatedDate = CreatedDate,
             @CreatedBy   = CreatedBy
      from @Inserted;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_AddLPNs */

Go
