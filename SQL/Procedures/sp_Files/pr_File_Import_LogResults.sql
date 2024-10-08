/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Import_LogResults') is not null
  drop Procedure pr_File_Import_LogResults;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Import_LogResults: This procedure takes inputs and log the records
   in interfacelog
------------------------------------------------------------------------------*/
Create Procedure pr_File_Import_LogResults
 (@FileName        TVarchar,
  @FileType        TTypecode,
  @TempTableName   TVarchar,
  @TempTableFields TVarchar,
  @BusinessUnit    TBusinessunit,
  @UserId          TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vRecordId          TRecordId,

          @vInterfaceLogId    TRecordId,
          @vRecordsProcessed  TCount,
          @vRecordsFailed     TCount,

          @vxmlMsgHeader      TXml,
          @vInputXml          TXml,
          @vResultXml         TXml,

          @vSQL               TNVarchar;

declare @ttLogs table(RecordId            TRecordId,
                      InputXml            TXml,
                      ResultXml           TXml,
                      KeyData             TVarchar,
                      NumRecordsProcessed TCount,
                      NumRecordsFailed    TCount)

begin
begin try /* pr_File_Import_LogResults */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Create table structure */
  select * into #InterfaceLog        from @ttLogs
  select * into #InterfaceLogDetails from @ttLogs;

  select @vSQL = 'declare @vInputXml          TXml,
                          @vResultXml         TXml,
                          @vRecordsProcessed  TCount,
                          @vRecordsPassed     TCount;' +

                 /* Interfacelog */
                 '/* Get the All records which are extracted from file */
                  set @vInputXml = (select '+ @TempTableFields +' from ' + @TempTableName + ' for xml path(''Record''),root(''msgbody'')); ' +

                 '/* Get the valid records which are inserted into maintable */
                  set @vResultXml = (select '+ @TempTableFields +' from ' + @TempTableName + ' where Validated = ''Y'' for xml path(''Record''),root(''msgbody'')); ' +

                 'select @vRecordsProcessed = count(*) from ' + @TempTableName + ';' +
                 'select @vRecordsPassed    = count(*) from ' + @TempTableName + ' where Validated = ''Y'' ;' +

                 'insert into #InterfaceLog(InputXml, ResultXml, NumRecordsProcessed, NumRecordsFailed)
                    select @vInputXml, @vResultXml, @vRecordsProcessed, @vRecordsProcessed - @vRecordsPassed;' +

                 /* Interfacelog Details */
                 'insert into #InterfaceLogDetails(RecordId, KeyData, InputXml, ResultXml)
                    select RecordId,
                           KeyData,
                           cast((select '+ @TempTableFields +'  FOR XML PATH(''Record''),TYPE) as varchar(max)),
                           case when coalesce(ValidationMsg, '''') <> ''''
                                  then cast((select ValidationMsg as Error FOR XML PATH(''Errors''),TYPE) as varchar(max))
                           else null
                           end
                    from ' + @TempTableName + '; '

  /* Execute SQL Statements */
  exec (@vSQL)

  /* Xml's to insert into Interfaclog table */
  select @vInputXml         = InputXml,
         @vResultXml        = ResultXml,
         @vRecordsProcessed = NumRecordsProcessed,
         @vRecordsFailed    = NumRecordsFailed
  from #InterfaceLog;

  /* xmlMsgHeader */
  select @vxmlMsgHeader = dbo.fn_XMLNode('msgHeader',
                            dbo.fn_XMLNode('SourceSystem',    'CIMSUI') +
                            dbo.fn_XMLNode('SourceReference', @FileName) +
                            dbo.fn_XMLNode('TargetSystem',    'CIMS') +
                            dbo.fn_XMLNode('TransferMethod',  'UI'));

  /* Inputxml for Interfacelog */
  select @vInputXml = '<msg>' + convert(varchar(max), @vxmlMsgHeader) + convert(varchar(max), @vInputxml) + '</msg>';

  /* Create interface log record */
  exec pr_InterfaceLog_AddUpdate @SourceSystem     = 'CIMSUI',
                                 @TargetSystem     = 'CIMS',
                                 @SourceReference  = @FileName,
                                 @TransferType     = 'Import',
                                 @BusinessUnit     = @BusinessUnit,
                                 @xmlData          = @vInputXml,
                                 @xmlDocHandle     = null,
                                 @RecordsProcessed = @vRecordsProcessed,
                                 @LogId            = @vInterfaceLogId output,
                                 @RecordTypes      = @FileType;

  /* Update interfacelog counts */
  exec pr_InterfaceLog_UpdateCounts @vInterfaceLogId, @vRecordsFailed;

  /* Insert records into InterfaceLogDetails */
  insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, HostReference, KeyData,
                                   HostRecId, InputXml,ResultXml, BusinessUnit)
    select cast(@vInterfacelogId as varchar(10)), 'Import', @FileType, @FileName, KeyData,
           RecordId, InputXml, ResultXml, @BusinessUnit
    from #InterfaceLogDetails ;

  /* Drop the table once data loaded into the Original table */
  select @vSQL = 'drop table ' + @TempTableName;
  exec(@vSQL)

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_File_Import_LogResults */

Go
