/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/22  MS      pr_Imports_DE_ACKImportedRecords: Changes to updates exception records as 'E' (CID-1135)
  2018/02/19  TD      pr_Imports_DE_GetSKUsToImport,pr_Imports_DE_ACKImportedRecords:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_ACKImportedRecords') is not null
  drop Procedure pr_Imports_DE_ACKImportedRecords;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_ACKImportedRecords:  This procedure will update the result of the each
   record which we have processed.

   Once we process the SKUs in CIMS, then we will get the result which contains
   both success and failure records. So we will update those details in ImportSKUs table

<msg xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Results Accepted="True">
    <RecordType>SKU</RecordType>
    <KeyData>00000004</KeyData>
    <RecordId>1</RecordId>
  </Results>
  <Results Accepted="False">
    <RecordType>SKU</RecordType>
    <KeyData>00000005</KeyData>
    <Error>GNC is not a valid BusinessUnit</Error>
    <RecordId>2</RecordId>
  </Results>
</msg>
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_ACKImportedRecords
  (@StrResult      varchar(max),
   @RecordType     TTypeCode,
   @ImportResultId TRecordId,
   @ImportData     xml,
   @ErrorMessage   TMessage,
   @UserId         TUserId       = null,
   @BusinessUnit   TBusinessUnit = null)
as
  declare @vReturnCode  TInteger,
          @vEntity      TEntity,

          @vSQL         TNvarchar;

  declare @ttResults table (RecordId    TRecordId Identity(1,1),
                            RecordType  TDescription,
                            KeyData     TDescription,
                            Error       TNVarChar,
                            HostRecId   TRecordId);
begin
  SET NOCOUNT ON;

  if (@StrResult is null) and (@ImportData is null)
    goto Exithandler;

  /* select to create table structure for #ttResults */
  select * into #ttResults from @ttResults;

  /* Based on the RecordType we need to define the table name, as this is a core procedure which
     will be called by all record type updates */
  set @vEntity = case
                   when @RecordType = 'ASNLH' then 'ImportASNLPNs'
                   when @RecordType = 'ASNLD' then 'ImportASNLPNDetails'
                   when @RecordType = 'CT'    then 'ImportCartonTypes'
                   when @RecordType = 'CNT'   then 'ImportContacts'
                   when @RecordType in ('OD', 'SOD') then 'ImportOrderDetails'
                   when @RecordType in ('OH', 'SOH') then 'ImportOrderHeaders'
                   when @RecordType in ('RD', 'ROD') then 'ImportReceiptDetails'
                   when @RecordType in ('RH', 'ROH') then 'ImportReceiptHeaders'
                   when @RecordType = 'SKU' then 'ImportSKUs'
                   when @RecordType in ('SPP', 'SMP') then 'ImportSKUPrePacks'
                   when @RecordType = 'UPC' then 'ImportUPCs'
                   when @RecordType = 'NOTE' then 'ImportNotes'
                 end;

  if (@ImportData is not null)
    begin
      /* If there is an exception during imports (not failure in validations, but a real exception)
         then we would flag all the records as Error in CIMSDE */
      insert into #ttResults (HostRecId, RecordType, Error)
        select nullif(Record.Col.value('RecordId[1]',   'TRecordId'),''),
               nullif(Record.Col.value('RecordType[1]', 'TDescription'),''),
               @ErrorMessage
          from @ImportData.nodes('msg/msgBody/Record') as Record(Col);
    end
  else
    begin
      /* Insert the results returned into the temp table */
      insert into #ttResults (RecordType, KeyData, Error, HostRecId)
        exec pr_Imports_DE_ParseResults @StrResult;
    end

  /* Apply the results returned from CIMS to the CIMSDE.Entity table */
  select @vSQL = 'Update E ' +
                 'set E.ProcessedTime  = current_timestamp,' +
                     'E.ExchangeStatus = case when TR.Error is null then ''Y'' /* Yes */ else ''E''  /* End */ end,' +
                     'E.Result         = TR.Error ' +
                 'from ' + @vEntity + ' E ' +
                 'join #ttResults TR on E.RecordId = TR.HostRecId ';

  /* Execute the SQL built above to update the results returned from CIMS to the corresponding CIMSDE table */
  execute sp_executesql @vSQL;

  /* Delete from the import result table */
  delete from ImportResults
  where (RecordId = @ImportResultId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_ACKImportedRecords */

Go
