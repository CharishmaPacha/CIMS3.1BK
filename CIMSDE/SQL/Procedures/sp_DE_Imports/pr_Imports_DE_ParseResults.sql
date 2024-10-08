/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_ParseResults') is not null
  drop Procedure pr_Imports_DE_ParseResults;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_ParseResults: Parse the results returned by ImportRecords
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_ParseResults
  (@xmlInput    TXML)
as
  declare @vReturnCode      TInteger,
          @vxmlInput        XML;
begin /* pr_Imports_DE_ParseResults */
  SET NOCOUNT ON;

  select @vxmlInput = convert(xml, @xmlInput);

  select nullif(Record.Col.value('RecordType[1]', 'TDescription'),  '')  as RecordType,
         nullif(Record.Col.value('KeyData[1]',    'TDescription'),  '')  as KeyData,
         nullif(Record.Col.value('Error[1]',      'nvarchar(max)'), '')  as Error,
         nullif(Record.Col.value('RecordId[1]',   'TRecordId'),      0)  as HostRecId
  from @vxmlInput.nodes('msg/Results') as Record(Col);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_ParseResults */

Go
