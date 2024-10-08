/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/20  TK      pr_InterfaceLog_MarkAsProcessed: Initial Revision (S2G-339)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_MarkAsProcessed') is not null
  drop Procedure pr_InterfaceLog_MarkAsProcessed;
Go
/*------------------------------------------------------------------------------
  pr_InterfaceLog_MarkAsProcessed: This procedure marks interface records as Succeeded or Failed
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_MarkAsProcessed
  (@InterfaceLogId  TRecordId,
   @xmlResult       xml)
as
  declare @vReturnCode  TInteger;
begin

  /* Get Interface LogId from xml result */
  if (@InterfaceLogId is null)
    select @InterfaceLogId = Record.Col.value('InterfaceLogId[1]', 'TRecordId')
    from @xmlResult.nodes('msg/msgHeader') as Record(Col);

  /* Calculate the Status and log the EndTime as the interface processing is completed */
  update InterfaceLog
  set Status       = case when (RecordsFailed = 0) then 'S'/* Succeeded */ else 'F'/* Failed */ end,
      EndTime      = current_timestamp,
      ModifiedDate = current_timestamp
  where (RecordId = @InterfaceLogId);

  return(coalesce(@vReturnCode, 0));
end /* pr_InterfaceLog_MarkAsProcessed */

Go
