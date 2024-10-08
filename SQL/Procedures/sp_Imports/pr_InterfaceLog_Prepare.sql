/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/30  TD      pr_InterfaceLog_Prepare:Changes to log the interfacelog with the proper status when we have
                      pr_InterfaceLog_Prepare:Changes to read RecordTypes from input xml - (CIMSDE-1722)
  2017/09/06  KN      pr_InterfaceLog_Prepare: Noticed that only first Error is being logged to InterfaceLogDetails so fixed the issue (CIMSDE-6)
  2017/07/05  NB      pr_InterfaceLog_Prepare: corrected caller for pr_InterfaceLog_AddUpdate to pass in null for xmlDocHandle param(CIMS-1183)
  2017/02/15  NB      pr_InterfaceLog_Prepare: Enhanced to handle Export related InterfaceLog inserts and updates (CIMSDI-6)
                      pr_InterfaceLog_Prepare: Calculate failed records, because pr_Imports_ImportRecords is transactional (CIMS-623)
  2015/03/20  NB      pr_InterfaceLog_Prepare: Changes to set BusinessUnit when InterfaceLog/InterfaceLogDetails
  2015/03/18  NB      pr_InterfaceLog_Prepare: Enhanced to process end requests for File Errors(CIMS-418)
  2014/07/30  NB      pr_InterfaceLog_Prepare: Fix - convert XML encoding UTF-16 to UTF-8
  2014/07/08  NB      pr_InterfaceLog_Prepare: Modified to update EndTime, on completion.
  2014/04/11  PKS     Added pr_InterfaceLog_Prepare
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_Prepare') is not null
  drop Procedure pr_InterfaceLog_Prepare;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_Prepare is used have a good mechanism in cIMS in
  logging the transactions and alerting users to inform the status of flow
  between these systems, whether it is successful or fail.

  Input XML:
  ----------
  <LogDetails>
    <Header>
      <SourceSystem></SourceSystem>
      <TargetSystem></TargetSystem>
      <SourceReference></SourceReference>
      <TransferType></TransferType>
      <RecordType></RecordType>
      <SourceTotalRecords></SourceTotalRecords>
      <SourceProcessedRecords></SourceProcessedRecords>
      <MultiBatchProcess></MultiBatchProcess>
      <IntegrationCode></IntegrationCode>
      <ProcessType></ProcessType>
      <Reference1></Reference1>
      <Reference2></Reference2>
      <Reference3></Reference3>
      <StartTime></StartTime>
      <EndTime></EndTime>
      <ScheduleInterval></ScheduleInterval>
    </Header>
    <Details>
       <Error></Error>
    </Details>
</LogDetails>

output XML:
<Errors>
    <Error>Some error message</Error>
    <Error>Some other error message</Error>
</Errors>

or null
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_Prepare
  (@LogDetails             TXML,
   @xmlResult              TXML output)
as
  declare @vLogDetails        xml,
          @vSourceSystem      TName,
          @vTargetSystem      TName,
          @vSourceReference   TName,
          @vTransferType      TTransferType,
          @vProcessType       TName,
          @vReference1        TName,
          @vBusinessUnit      TBusinessUnit,
          @vRecordTypes       TRecordTypes,
          @vRecordsFailed     TCount,
          @vErrorRecordCount  Tcount,
          @vLogId             TRecordId,
          @vResultXML         TXML;

  declare @vErrors Table (RecordId      TRecordId Identity(1,1),
                          ErrorMessage  TVarChar);
begin
  /* in the input XML, the UTF coding is being sent as UTF-16. This is incompatible with
     SQL Server convention which uses only UTF-8. Replacing UTF-16 with UTF-8 handles this issue */
  select @LogDetails = replace(@LogDetails, 'utf-16', 'utf-8');

  select @vLogDetails = convert(xml, @LogDetails);

  /* Get the Total count of RecordNodes in the XML */
  select @vSourceSystem    = Record.Col.value('SourceSystem[1]',       'TName'),
         @vTargetSystem    = Record.Col.value('TargetSystem[1]',       'TName'),
         @vSourceReference = Record.Col.value('SourceReference[1]',    'TName'),
         @vTransferType    = Record.Col.value('TransferType[1]',       'TName'),
         @vProcessType     = Record.Col.value('ProcessType[1]',        'TName'),
         @vReference1      = Record.Col.value('Reference1[1]',         'TName'),
         @vRecordTypes     = nullif(Record.Col.value('RecordTypes[1]', 'TName'), '')
  from @vLogDetails.nodes('LogDetails/Header') as Record(Col);

  insert into @vErrors
    select Record.Col.value('.',    'TVarChar')
    from @vLogDetails.nodes('LogDetails/Details/Error') as Record(Col);

  select @vLogId = RecordId
  from InterfaceLog
  where (SourceReference = @vSourceReference   ) and    /* FileName */
        (Status          = 'P' /* In process */);

  /* If there was no Log record found, and the process is Export, find the entry matching to Reference1 as it is sent with ExportBatch value from caller */
  if ((@vLogId is null) and (@vTransferType = 'Export') and (@vReference1 is not null))
    begin
      select @vLogId = RecordId
      from InterfaceLog
      where (SourceReference = @vReference1   ) and    /* ExportBatch */
            (Status          = 'P' /* In process */);

      /* Update with the actual file name */
      update InterfaceLog
      set SourceReference = @vSourceReference
      where (RecordId = @vLogId) and
            (Status   = 'P' /* In process */);
    end

  /* If there is an end call, and the Log has not been created yet, it means that
     DE has errored out even before the Import Records could be called. Mostly, this
     will happen for a file error. We intend to log this */
  if ((@vProcessType = 'End') and (@vLogId is null))
    begin
      /* Call AddUpdate Procedure to add the given entry to InterfaceLog */
      select @vRecordTypes = coalesce(@vRecordTypes, 'FILE'); /* Set the record type to FILE, as this cannot be null to send email alerts */
      select Top 1
             @vBusinessUnit = BusinessUnit
      from BusinessUnits
      where (Status = 'A');

      exec pr_InterfaceLog_AddUpdate @SourceSystem     = @vSourceSystem,
                                     @TargetSystem     = @vTargetSystem,
                                     @SourceReference  = @vSourceReference,
                                     @TransferType     = @vTransferType,
                                     @RecordType       = @vRecordTypes,
                                     @BusinessUnit     = @vBusinessUnit,
                                     @xmlData          = null,
                                     @xmlDocHandle     = null,
                                     @RecordsProcessed = 0,
                                     @LogId            = @vLogId       output,
                                     @RecordTypes      = @vRecordTypes output;
    end

  if exists (select RecordId from @vErrors)
    begin
      select @vResultXML = (select ErrorMessage as Error from @vErrors for xml path(''), root('Errors'));

      insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, LogMessage, KeyData, HostReference,
                                       BusinessUnit, Inputxml, Resultxml)
      select @vLogId, @vTransferType, @vRecordTypes, null, null, null,
             @vBusinessUnit, null, @vResultXML;
    end

  /* The record counts do not constitute the status.
     The records in the InterfaceLog with error details will indicate a failed export */
  select @vErrorRecordCount = 0;

  select @vErrorRecordCount = count(RecordId)
  from InterfaceLogDetails
  where (ParentLogId = @vLogId) and
        (ResultXML is not null);

  update InterfaceLog
  set @vRecordsFailed = RecordsProcessed - RecordsPassed,
      RecordsFailed   = @vRecordsFailed,
      Status          = case when (@vProcessType = 'End') then
                             (case when ((@vRecordsFailed = 0) and (@vErrorRecordCount = 0)) then 'S' else 'F' end)
                        else
                          Status
                        end,
      EndTime         = current_timestamp
  where (RecordId = @vLogId) and
        (Status   = 'P' /* In process */);

  /* Logic of this procedure was not implemented. */
  set @xmlResult = '<Errors>
                      <Error>Some error message</Error>
                      <Error>Some other error message</Error>
                    </Errors>';
end /* pr_InterfaceLog_Prepare */

Go
