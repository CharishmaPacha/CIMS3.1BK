/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/16  SV/AY   pr_Imports_ImportRecords: Pass BusinessUnit to add in InterfaceLog (FBV3-267)
  2021/03/19  TK      pr_Imports_CIMSDE_ImportData & pr_Imports_ImportRecords:
                      pr_Imports_ImportRecords, pr_Imports_SKUPrePacks: Changes ported from JL prod (JL-259)
  2020/03/21  MS      pr_Imports_ImportRecord, pr_Imports_ImportRecords: Set up DCMS procedures (JL-63, JL-64)
  2020/03/15  MRK     pr_Imports_ImportRecords, pr_Imports_ImportRecords, pr_Imports_ValidateASNLPNDetails, pr_InterfaceLog_AddDetails
                      pr_Imports_ImportRecord, pr_Imports_ImportRecords: Included Routing Confirmations to import the records (S2G-233)
  2018/03/22  DK/SV   pr_Imports_OrderHeaders, pr_Imports_ValidateOrderHeader, pr_Imports_ImportRecords,
  2018/02/02  SV      pr_Imports_ImportRecord, pr_Imports_ImportRecords, pr_Imports_SKUs, pr_Imports_UPCs:
  2018/01/18  NB/SV   pr_Imports_ImportRecords: Changes for improving the performance while importing large set of records (S2G-88)
  2018/01/05  AY      pr_Imports_ImportRecords: Handle duplicate records in the same import cycle (S2G-43)
                      pr_Imports_ImportRecords: enhanced to perform bulk processing for RH RD
  2017/05/24  NB      pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails,
  2017/05/16  NB/AY   pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails: Change XML
                      pr_Imports_ImportRecords: Integrated the Location import procedure (CIMS-1339)
                      pr_Imports_ImportRecords: Change to mark records as processed for direct DB integration. (HPI-202)
  2016/04/27  AY      pr_Imports_ImportRecords: Introduced string params corresponding to xml params
  2016/03/21  TK      pr_Imports_ImportRecords: Enhanced to return Result XML with erros
  2015/12/09  NY      pr_Imports_ImportRecords: Remove special characters from the inputxml.(LL-257)
  2015/11/03  RV      pr_Imports_ImportRecords: Counts updated proper while exception raised (CIMS-623)
  2015/10/24  YJ      pr_Imports_ImportRecords: Added RecordType Carton Type as well (ACME-286)
  2015/10/23  RV      pr_Imports_ImportRecords: Modified as transactional, so that entire chunk of records gets processed or none
                      pr_InterfaceLog_Prepare: Calculate failed records, because pr_Imports_ImportRecords is transactional (CIMS-623)
  2015/09/03  SV      pr_Imports_ImportRecords: Enhanced to identify the process type (sequential or Bulk) by control var (FB-356)
  2015/09/03  SV      pr_Imports_ImportRecords: Managing the imports(Single or Bulk Imports) based on Controls (FB-356)
  2015/08/12  SV      pr_Imports_ImportRecords: Resolved the issue of Incorrect Record count(Passed and Failed) (CIMS- 576)
  2015/08/06  SV      pr_Imports_ImportRecords, pr_Imports_ImportRecord: Bug fix for the logging the interface details
  2015/08/06  AY      pr_Imports_ImportRecords: Bug fix in logging details when processing records individually
  2015/07/23  AY      pr_Imports_ImportRecords: Change back to sequential processing if delete records
              SV      pr_Imports_ImportRecord,pr_Imports_ImportRecords: Made additional changes to the above mentioned issue
  2015/02/23  AK      pr_Imports_ImportRecords: Added required RecordTypes(SOH and OH)
  2014/12/02  SK      pr_Imports_ImportRecords, pr_Imports_ReceiptDetails, pr_Imports_ValidateReceiptDetail:
  2014/12/01  SK      pr_Imports_ImportRecords, pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader:
  2014/10/20  NB      pr_Imports_SKUs, pr_Imports_ImportRecords, pr_Imports_ValidateSKU
                      pr_Imports_ImportRecords: Enhanced to invoke pr_Imports_OrderDetails
                      pr_Imports_ImportRecords: Adding a node by passing in FileName in Record Node.
  2013/07/29  PK      Added pr_Imports_ImportRecords.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ImportRecords') is not null
  drop Procedure pr_Imports_ImportRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ImportRecords: Process an xml record set and imports the records
    in the xml document. The given document would have a header and body with multiple
    records. All of the records may be of the same type in the body or may not be.
    If all the records in the body are the same type and the particular record can
    be processed in bulk, then it would be processed in bulk, else each record would be
    extracted and processed.

  If the import xml has duplicate records (i.e. same SKU repeated twice in a SKU import)
  then we would get unique key violations and so we fixed that now to process records individually
  when there are duplicate records - because it could be an insert followed by an update.

  It is now enhanced to process multiple types of records, therefore the below is NOT TRUE anymore.

  Assumption : At present, it is assumed that all the records in a given XML are of one
    Record Type only. In future, this procedure should be enhanced to evaluate the XML
    to figure it instead of assuming so.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ImportRecords
  (@xmlData      xml      = null,
   @xmlResult    xml      = null output,
   @StrData      TVarchar = null,
   @StrResult    TVarchar = null output)
as
  declare @vXmlRecord         Xml,
          @vXmlRecordCount    TCount,
          @vXmlData           TVarchar,
          @vRowCount          TCount,
          @vSourceSystem      TName,
          @vTargetSystem      TName,
          @vSourceReference   TName,
          @vTransferMethod    TName,
          @vTransferType      TTransferType,
          @vParentLogId       TRecordId,
          @vRecordSuccessful  TInteger,
          @vTotalRecordsProcessed
                              TInteger,
          @vRecordsPassed     TInteger,
          @vRecordsFailed     TInteger,
          @vSingleRecordType  TFlag,
          @vRecordType        TRecordType,
          @vRecordTypeToProcess
                              TRecordType,
          @vSequentialProcessRecordTypes
                              TRecordTypes,
          @vBusinessUnit      TBusinessUnit,
          @vRecordTypeCount   TCount,
          @vActions           TFlags,
          @vXmlRecordString   TXML,
          @vRecordTypes       TRecordTypes,
          @vReturnCode        TInteger,
          @vResultXML         TXML,
          @vXMLResult         TXML,
          @vXmlDocHandle      TInteger,
          @vCurrentRecordType TRecordType,
          @vCurrentSequenceId TRecordId,
          @vDuplicateRecords  TInteger,
          @vDebug             TControlValue = 'N';

  declare @ttRecordActions table (RecordType TRecordType,
                                  Action     TAction);

  declare @ttRecordTypes   table (RecordType      TRecordType,
                                  ProcessSequence TInteger);
begin
  SET NOCOUNT ON;

  select @vRecordsPassed    = 0,
         @vRecordsFailed    = 0,
         @vActions          = '', /* Initialised, because we are appending the value during its next occurence */
         @vRecordTypes      = '';

  /* convert inputs to nvarchar for processing */
  if (@xmlData is not null)
    select @vXmlData = convert(nvarchar(max), @xmlData);
  else
    select @vXMLData = @StrData;

  /* Remove any special chars from xml */
  select @xmlData = @vXmlData collate SQL_Latin1_General_Cp1251_CS_AS;

  /* Prepare xml doc from xml input */
  exec sp_xml_preparedocument @vXmlDocHandle output, @xmlData;

  /* Get the Total count of RecordNodes in the XML */
  select @vXmlRecordCount  = count(*),
         @vRowCount        = 1,
         @vTransferType    = 'Import'
  from OPENXML(@vXmlDocHandle, '//msg/msgBody/Record')
  with (id int '@mp:id');

  /* Read Transfer method, SourceSystem, TargetSystem and SourceReference from XML */
  select @vTransferMethod  = TransferMethod,
         @vSourceSystem    = coalesce(SourceSystem, 'HOST'),
         @vTargetSystem    = TargetSystem,
         @vSourceReference = SourceReference
  from OPENXML(@vXmlDocHandle, '//msg/msgHeader', 2)
  with (TransferMethod  TName,
        SourceSystem    TName,
        TargetSystem    TName,
        SourceReference TName);

  /* Fetching the BusinessUnit as we would be using for fetching the Control values */
  select Top 1 @vBusinessUnit = BusinessUnit
  from OPENXML(@vXmlDocHandle, '/msg/msgBody/Record', 2)
  with (BusinessUnit TBusinessUnit);

  /* Review the entire XML and figure out if there is a single record type and
     what actions are involved.
     Assumption: All records will have RecordType and Action specified */
  insert into @ttRecordActions (RecordType, Action)
    select distinct RecordType, Action
    from OPENXML(@vXmlDocHandle, '/msg/msgBody/Record', 2)
    with (RecordType  TRecordType,
          Action      TAction);

  insert into @ttRecordTypes(RecordType) select distinct RecordType from @ttRecordActions;

  /* Update process sequence from the default sequence listed in entity types
     This will update the processsequence column with the sortseq */
  update RT
  set ProcessSequence = RTS.SortSeq
  from @ttRecordTypes RT
    join EntityTypes RTS on (RTS.TypeCode = RT.RecordType) and (RTS.Entity = 'ImportRecordType');

  /* Get the number of record types and the various actions in the XML */
  select @vRecordTypeCount = count(distinct RecordType),
         @vRecordType      = Min(RecordType)            from @ttRecordActions;
  select @vRecordTypes    += RecordType + ' '           from @ttRecordTypes;
  select @vActions        += Action                     from @ttRecordActions;

  if (@vRecordType = 'ASNL')
    select @vDuplicateRecords = count(*)
    from OPENXML(@vXmlDocHandle, '/msg/msgBody/Record', 2)
    with (LPN  TLPN)
    group by LPN
    having (count(*) > 1);
  else
    select @vDuplicateRecords = count(*)
    from OPENXML(@vXmlDocHandle, '/msg/msgBody/Record', 2)
    with (KeyData  TName)
    group by KeyData
    having (count(*) > 1);

  /* Get the list of Record Types that are to be processed Sequentially (not bulk) */
  select @vSequentialProcessRecordTypes = dbo.fn_Controls_GetAsString('Import_RecordProcessType', 'Sequential', '', @vBusinessUnit, null /* UserId */);

  /* This assignment is required during validation in If condition.
     Suppose, If the importing RecordType is 'OH', while validating with the control list(if containing 'ROH'),
     as charindex('OH', 'ROH') will return 1, which is wrong. Hence appended with ''' for validating correctly. */
  select @vRecordTypeToProcess          = ',' + @vRecordType + ',',
         @vSequentialProcessRecordTypes = ','+ @vSequentialProcessRecordTypes + ',';

  /* Call AddUpdate Procedure to add the given entry to InterfaceLog */
  /* @SourceReference is used for Exports validation in the below proc. */
  exec pr_InterfaceLog_AddUpdate @SourceReference  = @vSourceReference,
                                 @TransferType     = @vTransferType,
                                 @BusinessUnit     = @vBusinessUnit,
                                 @xmlData          = @xmlData,
                                 @xmlDocHandle     = @vXmlDocHandle,
                                 @RecordsProcessed = @vXmlRecordCount,
                                 @LogId            = @vParentLogId output,
                                 @RecordTypes      = @vRecordTypes output;

  begin try
  begin transaction

  select @vCurrentSequenceId = 0;

  if (@vDebug = 'Y') select @vRecordTypeCount, @vActions, @vRecordTypeToProcess, @vRecordType, @vParentLogId ParentLogId, @vRecordTypes RecordTypes;

  /* Call Import Order Details procedure directly with the full xml
     This procedure is modified now to handle insert/Update in bulk
     However, if there are delete actions in the file, process them sequentially.
     Multi record types of OH and OD can be processed in batches now */
  if ((@vRecordTypeCount = 1) or (@vRecordTypes in ('OD OH', 'OH OD', 'RD RH', 'RH RD'))) and
     (charindex('D', @vActions) = 0) and (coalesce(@vDuplicateRecords, 0) = 0) and /* We can skip bulk updating here if there is any duplicate records in XML.Those will be update/insert individual in else block */
     (charindex(@vRecordTypeToProcess, @vSequentialProcessRecordTypes) = 0) and
     (@vRecordType in ('SOH', 'OH' /* OrderHeaders */, 'CT' /*CartonTypes*/, 'SOD', 'OD' /* OrderDetails */, 'SKU', 'SKUA', 'UPC', 'SMP', 'SPP', 'RH', 'ROH', 'RD', 'ROD', 'LOC', 'NOTE', 'DCMSRC', 'ASNLH', 'ASNLD', 'TRFINV'))
    while (exists (select ProcessSequence from @ttRecordTypes where ProcessSequence > @vCurrentSequenceId))
      begin
        select Top 1
          @vCurrentSequenceId = ProcessSequence,
          @vCurrentRecordType = RecordType
        from @ttRecordTypes
        where (ProcessSequence > @vCurrentSequenceId)
        order by ProcessSequence;

        if (@vDebug = 'Y') select @vCurrentRecordType vCurrentRecordType;
        select @vRecordType = @vCurrentRecordType;

        /* Add a new node ParentLogId to the RecordNode */
        set @xmlData.modify('insert <ParentLogId>{sql:variable("@vParentLogId")}</ParentLogId> into (//msg/msgHeader)[1]');

        if (@vRecordType = 'SKU' /* SKUs */)
          exec pr_Imports_SKUs @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType = 'SKUA' /* SKU Attributes */)
          exec pr_Imports_SKUAttributes @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType = 'UPC' /* UPCs */)
          exec pr_Imports_UPCs @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType in ('SPP', 'SMP' /* SKU Prepacks */))
          exec pr_Imports_SKUPrepacks @xmlData;
        else
        if (@vRecordType in ('RH', 'ROH' /* Receipt Headers */))
          exec pr_Imports_ReceiptHeaders @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType in ('RD', 'ROD' /* Receipt Details */))
          exec pr_Imports_ReceiptDetails @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType in ('SOH', 'OH' /* OrderHeaders */))
          exec pr_Imports_OrderHeaders @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType in ('SOD', 'OD') /* OrderDetails */)
          exec pr_Imports_OrderDetails @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId, @BusinessUnit = @vBusinessUnit;
        else
        if (@vRecordType = 'CT'/* CartonTypes */)
          exec pr_Imports_CartonTypes @xmlData;
        else
        if (@vRecordType = 'VEN' /* Vendors */)
          exec pr_Imports_Vendors @xmlData;
        else
        if (@vRecordType = 'CNT' /* Address(Contacts) */)
          exec pr_Imports_Contacts @xmlData;
        else
        if (@vRecordType = 'ASNL' /* ASNLPNs */)
          exec pr_Imports_ASNLPNs @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType = 'ASNLH' /* ASNLPNHeader */)
          exec pr_Imports_ASNLPNHeaders @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId, @BusinessUnit = @vBusinessUnit;
        else
        if (@vRecordType = 'ASNLD' /* ASNLPNDetails */)
          exec pr_Imports_ASNLPNDetails @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId, @BusinessUnit = @vBusinessUnit;
        else
        if (@vRecordType = 'NOTE' /* Notes */)
          exec pr_Imports_Notes @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType = 'LOC'/* Locations */)
          exec pr_Imports_Locations @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType = 'DCMSRC' /* RouterConfirmations */)
          exec pr_Imports_RouterConfirmations @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
        else
        if (@vRecordType = 'TRFINV' /* TransferInv */)
          exec pr_Imports_InvAdjustments_Transfers @vXmlDocHandle, @vBusinessUnit;
      end /* while (exists (select ProcessSequence from @ttRecordTypes where ProcessSequence > @vCurrentSequenceId)) */
  else
    /* Loop through each node and call Imports_ImportRecord procedure to insert the data */
    while (@vRowCount <= @vXmlRecordCount)
      begin
        /* Get each Record node from the xml */
        select @vXmlRecord = @xmlData.query('//msg/msgBody/Record[sql:variable("@vRowCount")]');

        /* Need to append msg, msgBody tags as calling pr_Imports_ImportRecord and it internally
           calls pr_Imports_ReceiptHeaders which access the data from msg/msgBody/Record */

        select @vXmlRecordString = convert(varchar(max), @vXmlRecord);
        select @vXmlRecordString = '<msg>' +
                                     dbo.fn_XMLNode('msgHeader', dbo.fn_XMLNode('ParentLogId', @vParentLogId) + dbo.fn_XMLNode('SourceSystem', @vSourceSystem)) +
                                     dbo.fn_XMLNode('msgBody', @vXmlRecordString) +
                                   '</msg>';
        select @vXmlRecord = convert(xml, @vXmlRecordString);

        /* Call Imports Procedure with each record node to insert into the database */
        exec @vRecordSuccessful = pr_Imports_ImportRecord @vXmlRecord, @vRecordType output;

        /* Increment the counters, add to RecordTypes if it is a new one */
        select @vRowCount      += 1,
               @vRecordsPassed += case when @vRecordSuccessful = 0  then 1 else 0 end,
               @vRecordsFailed += case when @vRecordSuccessful <> 0 then 1 else 0 end,
               @vRecordTypes    = case
                                    when @vRecordType is null then
                                      @vRecordTypes
                                    when (charindex(@vRecordType, coalesce(@vRecordTypes, '')) = 0) then
                                      coalesce(@vRecordTypes + ',', '') + @vRecordType
                                    else
                                      @vRecordTypes
                                  end;
      end

  if (@vRecordType in ('ASNLH', 'ASNLD'))
    /* After each batch is complete, Update the counts. update the ModifiedDate - but not
       the EndDatetime as that should be updated when the file is completed */
    update InterfaceLog
    set RecordsPassed = coalesce(RecordsPassed, 0) + coalesce(@vRecordsPassed, 0),
        RecordsFailed = coalesce(RecordsFailed, 0) + coalesce(@vRecordsFailed, 0),
        RecordTypes   = @vRecordTypes,
        ModifiedDate  = current_timestamp
    where (RecordId = @vParentLogId);

  /* If transfer method is DB, then mark it as done as each invocation is independent */
  if (coalesce(@vTransferMethod, '') <> 'FILE')
    update InterfaceLog
    set Status = case when RecordsFailed = 0 then 'S' else 'F' end
    where (RecordId = @vParentLogId) and
          (Status   = 'P' /* In process */);

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* If it is a file transfer then DE will call prepare and it will be taken care of in Prepare method */
  if (coalesce(@vTransferMethod, '') <> 'FILE')
    begin
      select @vResultXML = (select Error_Message() as Error for xml path(''));

      insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, LogMessage, KeyData, HostReference,
                                      BusinessUnit, Inputxml, Resultxml)
      select @vParentLogId, @vTransferType, @vRecordTypes, null, null, null,
             @vBusinessUnit, convert(varchar(max), @xmlData), @vResultXML;

      /* All updates have been rolled back so update status here again. We are not updating the end time as the data
         was not processed successfully */
      update InterfaceLog
      set @vRecordsFailed = RecordsProcessed - RecordsPassed,
          RecordsFailed   = @vRecordsFailed,
          Status          = case when @vRecordsFailed = 0 then 'S' else 'F' end
      where (RecordId = @vParentLogId) and
            (Status   = 'P' /* In process */);
    end

  select @vReturnCode = -1; /* Error */
end catch

  /* Build Result XML */
  exec pr_Imports_GetXmlResult @vParentLogId, @vSourceSystem, @vBusinessUnit, @xmlResult output;

  select @StrResult = convert(nvarchar(max), @xmlResult);

  /* Release the xml handle */
  exec sp_xml_removedocument @vXmlDocHandle;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ImportRecords */

Go
