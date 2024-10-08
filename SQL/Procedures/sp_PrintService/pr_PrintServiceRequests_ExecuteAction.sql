/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/24  PKS     Added pr_PrintServiceRequests_ExecuteAction
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintServiceRequests_ExecuteAction') is not null
  drop Procedure pr_PrintServiceRequests_ExecuteAction;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintServiceRequests_ExecuteAction:
    update the status of the pr_PrintServiceRequests_ExecuteAction
------------------------------------------------------------------------------*/
Create Procedure pr_PrintServiceRequests_ExecuteAction
  (@BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @xmlData       TXML,
   @xmlResult     TXML output)
as
  declare @ttLabelsToPrint TEntityKeysTable;

  declare @vEntityXML      XML,
          @vEntityType     TEntity,
          @vPriority       TPriority,
          @vEntityKey      TEntity,
          @vPrinterId      TDeviceId,
          @vAction         TAction,
          @vRequestId      TRecordId,
          @vTotalTasks     TCount = 0,
          @vTasksScheduled TCount = 0,
          @vRecordId       TRecordId;
begin
   select @vEntityXML = convert (XML, @xmlData);

   if (@vEntityXML is not null)
     begin
       /* Fetching data from XML */
       insert into @ttLabelsToPrint(EntityKey)
         select Record.Col.value('./text()[1]', 'TEntity') EntityKey
         from @vEntityXML.nodes('/SchedulePrintLabels/EntityKeys/child::node()') as Record(Col);

       set @vTotalTasks = @@rowcount;

       select @vAction     = Record.Col.value('Action[1]', 'TAction'),
              @vEntityType = Record.Col.value('Entity[1]', 'TEntity')
       from @vEntityXML.nodes('/SchedulePrintLabels') as Record(Col);

       select @vPrinterId = Record.Col.value('PrinterId[1]', 'TDeviceId'),
              @vPriority  = Record.Col.value('Priority[1]', 'TPriority')
       from @vEntityXML.nodes('/SchedulePrintLabels/Data') as Record(Col);

       /* Fetching first record */
       select top 1 @vRecordId = RecordId
       from @ttLabelsToPrint
       order by RecordId;

       while (@@rowcount > 0)
         begin
           select top 1 @vEntityKey = EntityKey
           from @ttLabelsToPrint
           where (RecordId = @vRecordId);

           if(exists(select T.Status
                     from Tasks T
                      join @ttLabelsToPrint TTLP on (TTLP.EntityKey = convert(Integer, T.TaskID))
                     where (T.Status  not in ('X' /* Cancel */, 'C' /* Close */)) and
                           (convert(Integer, T.TaskID) = @vEntityKey)))
             /* Inserting Schedule records */
             exec pr_PrintServiceRequests_AddOrUpdate @UserId,
                                                      @vPrinterId,
                                                      @vEntityType,
                                                      @vEntityKey,
                                                      null,
                                                      @vPriority,
                                                      @BusinessUnit,
                                                      @vRequestId output;
           else
             set @vTasksScheduled = @vTasksScheduled + 1;

           /* Fetching the next record. */
           select Top 1 @vRecordId = RecordID
           from @ttLabelsToPrint
           where (RecordId > @vRecordId)
           order by RecordId;
         end

       set @xmlResult = 'Labels printing scheduled successfully';
       if (@vTasksScheduled > 0)
         set @xmlResult = 'Labels printing scheduled successfully, but ' + convert(varchar(5), @vTasksScheduled) + ' labels which are in Cancelled or Completed status are ignored';
     end
end /* pr_PrintServiceRequests_ExecuteAction */

Go
