/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/21  MS      pr_Receivers_GetSummaryInfo: Added proc to return summary of receiver (HA-202)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_GetSummaryInfo') is not null
  drop Procedure pr_Receivers_GetSummaryInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_GetSummaryInfo:
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_GetSummaryInfo
  (@InputXml      TXML,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit)
as
  declare @vInputXml    xml,
          @vReceiverId  TRecordId;

  declare @ttinputSelectionFilters   TSelectionFilters;
begin
  select @vInputXml = cast(@InputXml as xml);

  insert into @ttinputSelectionFilters(FieldName, FilterOperation, FilterValue)
    select Record.Col.value('FieldName[1]',       'TName'),
           Record.Col.value('FilterOperation[1]', 'TName'),
           Record.Col.value('FilterValue[1]',     'TName')
    from @vInputXml.nodes('Root/SelectionFilters/Filter') as Record(Col);

  select @vReceiverId = FilterValue
  from @ttinputSelectionFilters
  where FieldName = 'ReceiverId';

  select *
  from vwReceivers
  where (ReceiverId = @vReceiverId)

end /* pr_Receivers_GetSummaryInfo */

Go
