/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/30  RV      pr_PrintServiceRequests_SetStatus: Updating the PrintStatus (S2GCA-1199)
  2014/09/24  NB/TK   Added pr_PrintServiceRequests_AddOrUpdate and pr_PrintServiceRequests_SetStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintServiceRequests_SetStatus') is not null
  drop Procedure pr_PrintServiceRequests_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintServiceRequests_SetStatus:
    update the status of the PrintLabelRequest
------------------------------------------------------------------------------*/
Create Procedure pr_PrintServiceRequests_SetStatus
  (@RequestId    TRecordId,
   @Status       TStatus = null output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,
          @vEntityType         TEntity,
          @vEntityKey          varchar(50);

begin /* pr_PrintLabelRequests_SetStatus */
  select @ReturnCode   = 0,
         @Messagename  = null;

  update PrintServiceRequests
  set @vEntityType = EntityType,
      @vEntityKey  = EntityKey,
      Status = @Status,
      StartedDate = case when (@Status = 'P' /* Printing */) then
                      current_timestamp
                    else
                      StartedDate
                    end,
      CompletedDate = case when (@Status in ('P' /* Printing */)) then
                         null
                       when (@Status in ('E' /* Error */, 'C' /* Completed*/)) then
                         current_timestamp
                       else
                        CompletedDate
                       end
  where (RecordId = @RequestId);

  if (@vEntityType = 'PICKTASK') and (@Status = 'C' /* Completed */)
    update Tasks
    set LabelsPrinted = 'Y',
        PrintStatus   = 'Printed'
    where (TaskId = @vEntityKey);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PrintServiceRequests_SetStatus */

Go
