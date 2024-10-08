/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/08/02  TK      pr_Tasks_GetDetailLabelsToPrint: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_GetDetailLabelsToPrint') is not null
  drop Procedure pr_Tasks_GetDetailLabelsToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_GetDetailLabelsToPrint: Given a task, the procedure determines
    if a Task Detail label(s) should be printed for the task.
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_GetDetailLabelsToPrint
  (@TaskId        TRecordId,
   @DocToPrint    TTypeCode,
   @RuleDataXML   TXML)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TDescription,

          @vTaskDetailLabelFormat TName;;

begin /* pr_Tasks_GetDetailLabelsToPrint */
  select @vReturnCode   = 0,
         @vMessagename  = null;

  if (@DocToPrint = 'TDL' /* Employee Labels */)
    begin
      /* Determime the task label to print - if none is returned, then no detail label would print */
      exec pr_RuleSets_Evaluate 'TaskDetailLabelsToPrint', @RuleDataXML, @vTaskDetailLabelFormat output;

      select distinct TD.TaskId, TD.TaskId /* EntityKey */, @DocToPrint, @vTaskDetailLabelFormat
      from TaskDetails TD
        join OrderDetails OD on (TD.OrderDetailId = OD.OrderDetailId)
      where (TD.TaskId = @TaskId) and
            (coalesce(nullif(OD.UDF1, ''), '') <> '') and
            (coalesce(nullif(OD.UDF2, ''), '') <> '');
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_GetDetailLabelsToPrint */

Go
