/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/24  NB      Added pr_PrintServiceRequests_GetNextBatch
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintServiceRequests_GetNextBatch') is not null
  drop Procedure pr_PrintServiceRequests_GetNextBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintServiceRequests_GetNextBatch:
    Fetch the next list of Print Service Requests to process
------------------------------------------------------------------------------*/
Create Procedure pr_PrintServiceRequests_GetNextBatch
  (@XmlPrintQueue     TXML   output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription;

begin /* pr_PrintServiceRequests_GetNextBatch */
  select @ReturnCode   = 0,
         @Messagename  = null;

  set @XmlPrintQueue = (select Top 1
                               RecordId,
                               RequestedDate as RequestedDate,
                               StartedDate as StartedDate,
                               CompletedDate as CompletedDate,
                               PrinterId,
                               EntityType as EntityType,
                               EntityKey as EntityKey,
                               RequestInfo as RequestInfo,
                               Priority as Priority,
                               Status as Status,
                               BusinessUnit as BusinessUnits
                        from PrintServiceRequests
                        where (Status = 'S' /* Scheduled */)
                        order by Priority, RecordId
                        FOR XML PATH('PRINTREQUEST'), ROOT('PRINTQUEUE'));
/*
  set @XmlPrintQueue = (select 1 as RecordId,
                                current_timestamp as RequestedDate,
                                 current_timestamp as StartedDate,
                                 current_timestamp as CompletedDate,
                                 'PDF' as PrinterId,
                                 'PICKTASK' as EntityType,
                                 12345 EntityKey,
                                 null as RequestInfo,
                                 1 as Priority,
                                 'S' as Status,
                                 'GNC' as BusinessUnit,
                                 'rfcadmin' as CreatedBy
                          FOR XML PATH('PRINTREQUEST'), ROOT('PRINTQUEUE'));
*/
ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PrintServiceRequests_GetNextBatch */

Go
