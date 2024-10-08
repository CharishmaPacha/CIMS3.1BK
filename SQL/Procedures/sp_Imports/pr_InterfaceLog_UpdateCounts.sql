/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/22  AY      pr_InterfaceLog_UpdateCounts: Added (S2G-110)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_UpdateCounts') is not null
  drop Procedure pr_InterfaceLog_UpdateCounts;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_UpdateCounts is used to update the Records counts
    and sets the status
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_UpdateCounts
  (@ParentLogId    TRecordId,
   @FailedCount    TCount)
as
begin
  /* If failed count is not given, then calculate it */
  if (@FailedCount is null)
    select @FailedCount = count(*)
    from InterfaceLogDetails
    where (ParentLogId = @ParentLogId) and
          (ResultXML is not null);

  /* Update recordcounts and status on Interfacelog */
  update InterfaceLog
  set RecordsFailed = @FailedCount,
      RecordsPassed = RecordsProcessed - @FailedCount,
      Status        = case
                        when (@FailedCount = 0)
                          then 'S' /* Success */
                        else
                          'F' /* Failed */
                      end,
      ModifiedDate = current_timestamp
  where (RecordId = @ParentLogId)
end /* pr_InterfaceLog_UpdateCounts */

Go
