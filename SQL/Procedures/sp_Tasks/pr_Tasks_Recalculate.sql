/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/12  VM      pr_Tasks_Recalculate: Added (HPI-993)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_Recalculate') is not null
  drop Procedure pr_Tasks_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_Recalculate: It is possible that @TasksToUpdate have duplicates,
   so handle accordingly.

  Flags: Re(C)ount, set (S)tatus
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_Recalculate
  (@TasksToUpdate  TRecountKeysTable readonly,
   @Flags          TFlags = 'S',
   @UserId         TUserId)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,
          @vRecordId   TRecordId,

          @vTaskId     TRecordId;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vTaskId = 0;

  while (exists (select * from @TasksToUpdate where EntityId > @vTaskId))
    begin
      select top 1 @vTaskId = EntityId
      from @TasksToUpdate
      where (EntityId > @vTaskId)
      order by EntityId;

      /* Call Recount and SetStatus based on the flag */
      if (charindex('C' /* Re(C)ount */, @Flags) <> 0)
        exec pr_Tasks_Recount @vTaskId;

      if (charindex('S' /* Set (S)tatus */, @Flags) <> 0)
        exec pr_Tasks_SetStatus @vTaskId, @UserId, null /* Status */, 'Y' /* recount */;
    end
end /* pr_Tasks_Recalculate */

Go
