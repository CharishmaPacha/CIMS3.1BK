/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/16  SV/AY   pr_Imports_ImportRecords: Pass BusinessUnit to add in InterfaceLog (FBV3-267)
  2021/03/19  TK      pr_Imports_CIMSDE_ImportData & pr_Imports_ImportRecords:
                      pr_Imports_ImportRecords, pr_Imports_SKUPrePacks: Changes ported from JL prod (JL-259)
  2020/04/08  MS      pr_Imports_ImportRecord, pr_InterfaceLog_SaveResult: Insert HostRecId in Interfacelogdetails (HA-126)
  2020/03/21  MS      pr_Imports_ImportRecord, pr_Imports_ImportRecords: Set up DCMS procedures (JL-63, JL-64)
  2020/03/15  MRK     pr_Imports_ImportRecords, pr_Imports_ImportRecords, pr_Imports_ValidateASNLPNDetails, pr_InterfaceLog_AddDetails
  2019/04/20  VS/TK   pr_Imports_ImportRecord, pr_InterfaceLog_AddUpdateDetails, pr_Imports_Contact:
                      pr_Imports_ImportRecord, pr_Imports_ImportRecords: Included Routing Confirmations to import the records (S2G-233)
  2018/03/22  DK/SV   pr_Imports_OrderHeaders, pr_Imports_ValidateOrderHeader, pr_Imports_ImportRecords,
  2018/02/02  SV      pr_Imports_ImportRecord, pr_Imports_ImportRecords, pr_Imports_SKUs, pr_Imports_UPCs:
  2018/01/18  NB/SV   pr_Imports_ImportRecords: Changes for improving the performance while importing large set of records (S2G-88)
  2018/01/05  AY      pr_Imports_ImportRecords: Handle duplicate records in the same import cycle (S2G-43)
                      pr_Imports_ImportRecord: Enhanced to call pr_Imports_Notes (CIMS-1722).
  2017/05/30  NB      pr_Imports_ImportRecord: Added LOC to document handle creation in sequential processing. changed import
                      pr_Imports_ImportRecord: Enhanced to create document handle for OPENXML during sequential processing,
                      pr_Imports_ImportRecords: enhanced to perform bulk processing for RH RD
  2017/05/24  NB      pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails,
  2017/05/16  NB/AY   pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails: Change XML
                      pr_Imports_ImportRecords: Integrated the Location import procedure (CIMS-1339)
  2016/08/12  AY      pr_Imports_ImportRecord: Raise error if the error is not recoverable HPI-478
                      pr_Imports_ImportRecords: Change to mark records as processed for direct DB integration. (HPI-202)
  2016/05/10  NB      pr_Imports_ImportRecord: Changes to Log errors, if recorded (CIMS-929)
  2016/05/09  NB      pr_Imports_ImportRecord: insert into InterfaceLogDetails for specific record types only, when Debug is set to Always(CIMS-929)
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
  2014/06/18  PV      pr_Imports_ImportRecord: Passing businessunit to pr_Imports_OrderDetails
                      pr_Imports_ImportRecords: Enhanced to invoke pr_Imports_OrderDetails
  2013/07/30  PK      pr_Imports_ImportRecord: Logging the errors in InterfaceLog table.
                      pr_Imports_ImportRecords: Adding a node by passing in FileName in Record Node.
  2013/07/29  PK      Added pr_Imports_ImportRecords.
  2012/05/08  YA/VM   pr_Imports_ImportRecord: Return message on invalid record type
                      pr_Imports_ImportRecord: Added support for ASNs and Vendor Imports.
                      Renamed pr_Interface_Import -> pr_Imports_ImportRecord
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ImportRecord') is not null
  drop Procedure pr_Imports_ImportRecord;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ImportRecord: Returns zero if the record was processed without
    errors, else returns a non-zero value
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ImportRecord
  (@xmlData      Xml,
   @RecordType   TRecordType = null output)
as
  declare @vReturnCode   TInteger,
          @vRecordType   TRecordType,
          @vTransferType TTransferType,
          @vXmlResult    Xml,
          @vDebugOption  TControlValue,
          @vLogRecordId  TRecordId,
          @vAction       TAction,
          @vParentLogId  TRecordId,
          @vHostRecId    TRecordId,
          @vBusinessUnit TBusinessUnit,
          /* Open Xml Document variables */
          @vXmlDocHandle           TInteger,
          @vDocumentHandleCreated  TFlag;
begin
  SET NOCOUNT ON;

  select @vDocumentHandleCreated = 'N';

  /* While processing record by record, the xmlData is passed by the caller. Transform the xml to document to process */
  if (@RecordType in ('SKU' /* SKU */, 'UPC' /* UPC */, 'SOH', 'OH' /* OrderHeaders */, 'SOD', 'OD' /* OrderDetails */, 'RH', 'ROH', 'RD', 'ROD', 'LOC' /* Locations */, 'NOTE' /* Notes */, 'DCMSRC'))
    begin
      /* Prepare xml doc from xml input */
      exec sp_xml_preparedocument @vXmlDocHandle output, @xmldata;
      select @vDocumentHandleCreated = 'Y';
    end

  /* Initialize */
  select @vLogRecordId = null,
         @vReturnCode  = 0;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  /* Get the Parent LogId */
  select @vParentLogId  = Record.Col.value('ParentLogId[1]',  'TRecordId')
  from @xmlData.nodes('msg/msgHeader') as Record(Col);

  /* Get the RecordType */
  select @vRecordType   = Record.Col.value('RecordType[1]',   'TRecordType'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @vHostRecId    = Record.Col.value('RecordId[1]',     'TRecordId'),
         @vTransferType = 'Import'
  from @xmlData.nodes('msg/msgBody/Record') as Record(Col);

  /* Get Debug option - default to debug on error only */
  select @vDebugOption = dbo.fn_Controls_GetAsString('IMPORT_'+@vRecordType, 'DEBUG', 'E' /* Default: on Error only */, @vBusinessUnit, '' /* UserId */) ;

  /* If desired then log all records - be cautious in using this as this impacts performance
     Log all records of specific record types only. Logging of all records for other record types is handled in their
     respective import procedures */
  if (@vDebugOption = 'A' /* Always */) and
     (@vRecordType in ('VEN' /* Vendors */,
                       'CNT' /* Address(Contacts) */,
                       'ASNLH' /* ASNLPNs */,
                       'ASNLD' /* ASNLPNDetails */ ))
   exec pr_InterfaceLog_AddUpdateDetails @vParentLogId, @vRecordType, @vTransferType, @vBusinessUnit, @xmldata, null /* Resultxml */,
                                         @HostRecId = @vHostRecId, @ILogRecordId = @vLogRecordId output;

begin try
  /* Based on the Record Type, call the appropriate procedure with the xml values*/
  if (@vRecordType is null)
    /* Insert the error into temp table */
    exec pr_Imports_LogError 'RecordTypeIsInvalid';
  else
  if (@vRecordType = 'SKU' /* SKUs */)
    exec pr_Imports_SKUs @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType in ('ROH', 'RH' /* Receipt Headers */))
    exec pr_Imports_ReceiptHeaders @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType in ('ROD', 'RD' /* Receipt Details */))
    exec pr_Imports_ReceiptDetails @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType in ('SOH', 'OH' /* OrderHeaders */))
    exec pr_Imports_OrderHeaders @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType in ('SOD', 'OD' /* OrderDetails */))
    exec pr_Imports_OrderDetails @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId, @BusinessUnit = @vBusinessUnit;
  else
  if (@vRecordType = 'VEN' /* Vendors */)
    exec pr_Imports_Vendors @xmlData;
  else
  if (@vRecordType = 'CNT' /* Address(Contacts) */)
    exec pr_Imports_Contacts @xmlData;
  else
  if (@vRecordType = 'ASNL' /* ASNLPNs */)
    exec pr_Imports_ASNLPNs @xmlData;
  else
  if (@vRecordType = 'ASNLH' /* ASNLPNHeader */)
    exec pr_Imports_ASNLPNHeaders @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType = 'ASNLD' /* ASNLPNDetails */)
    exec pr_Imports_ASNLPNDetails @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType in ('SPP', 'SMP' /* SKU Pre Packs */))
    exec pr_Imports_SKUPrepacks @xmlData;
  else
  if (@vRecordType = 'UPC' /* UPCs */)
    exec pr_Imports_UPCs @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType = 'CT' /* CartonTypes */)
    exec pr_Imports_CartonTypes @xmlData;
  else
  if (@vRecordType = 'NOTE' /* Notes */)
    exec pr_Imports_Notes @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType = 'LOC' /* Locations */)
    exec pr_Imports_Locations @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
  if (@vRecordType = 'DCMSRC' /* RouterConfirmations */)
    exec pr_Imports_RouterConfirmations @documentHandle = @vXmlDocHandle, @InterfaceLogId = @vParentLogId;
  else
    insert into #Errors
      select Description from Messages where MessageName = 'RecordTypeIsInvalid';
end try
begin catch
  /* If there is unrecoverable error then exit */
  if XAct_State() = -1
    exec pr_ReRaiseError;

  insert into #Errors select ERROR_MESSAGE()
end catch

  /* Save result to InterfaceLog - return non-zero value if there were any errors */
  if (@vLogRecordId is not null) or
     (exists (select * from #Errors))
    exec @vReturnCode = pr_InterfaceLog_SaveResult @vParentLogId, @vRecordType, @vTransferType,
                                                   @vBusinessUnit, @xmldata, @vXmlResult,
                                                   @HostRecId = @vHostRecId,
                                                   @ILogRecordId = @vLogRecordId output;

  /* This is so that we may use it as a named result in LINQ to SQL */
  --select @vXmlResult as XmlResult;

  /* Although local temp tables are dropped when the scope that created them is
     exited, it is good form to drop them explicitly. */
  drop table #Errors;

  /* Release the xml handle, if it was created here */
  if (@vDocumentHandleCreated = 'Y')
    exec sp_xml_removedocument @vXmlDocHandle;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ImportRecord */

Go
