/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Debug_ReplayActivity') is not null
  drop Procedure pr_Debug_ReplayActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Debug_ReplayActivity: Procedure to re-execute an entry from the Activity
    log i.e. it takes the given activity log id and tries to execute again - which
    would be helpful for debugging as we can run the same in debug mode.
------------------------------------------------------------------------------*/
Create Procedure pr_Debug_ReplayActivity
  (@ActivityLogId    TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vProcName          TName,
          @vxmlInput          TXML,
          @vxmlResult         TXML;
begin
  SET NOCOUNT ON;

  select @vxmlInput = xmlData,
         @vProcName = ProcName
  from CurrActivityLog
  where (RecordId = @ActivityLogId);

  if (@vProcName = 'pr_Entities_ExecuteAction_V3')
    exec @vProcName @vxmlInput, @BusinessUnit, @UserId, @vxmlResult output;

  select cast(@vxmlResult as xml);
end /* pr_Debug_ReplayActivity */

Go
