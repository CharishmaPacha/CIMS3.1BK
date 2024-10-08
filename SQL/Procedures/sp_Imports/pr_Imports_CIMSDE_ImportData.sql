/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/17  VS      pr_Imports_CIMSDE_ImportData, pr_Imports_ImportsSQLData, pr_Imports_SKUs,
  2021/03/19  TK      pr_Imports_CIMSDE_ImportData & pr_Imports_ImportRecords:
  2020/10/15  MS      pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNHdr_Delete, pr_Imports_ASNLPNDetails, pr_Imports_CIMSDE_ImportData
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_CIMSDE_ImportData') is not null
  drop Procedure pr_Imports_CIMSDE_ImportData;
Go
/*------------------------------------------------------------------------------
  pr_Imports_CIMSDE_ImportData:  This procedure will be called from job to import
   the data (SKUS, etc.) from CIMSDE database to CIMS database.

  CIMSDE can be local to the CIMS DB and if so the design is now to load the data
    into ## table for processing as the ## table would be a global temporary table on the same
    server and accessible to both DBs. if CIMSDE is remote i.e. it is not on the same
    server, then we would use XML processing i.e. the data to be imported is build as
    XML on CIMSDE, stored in a table and then the record id returned.

   If we are using XML, we will fetch the generated XML and process it by
   passing the same to CIMS import procedure as input xml. So the CIMS import procedure will
   process the records, and will return the result as xml. In this process, all valid records
   will inserted into CIMS table and other failure records will not insert into CIMS, and those
   results will updated in host(CIMSDE) tables. if the record(s) was/were failed for some reason
   then it will be updated in result field.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_CIMSDE_ImportData
  (@RecordType     TRecordType,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null)
as
  declare @vParentLogId      TRecordId,
          @vxmlImportData    xml,
          @vImportData       varchar(max),
          @vxmlResult        xml,
          @vStrResult        varchar(max),
          @vMessage          TNVarchar,
          @vReturnCode       TInteger,

          @vImportResultRecId  TRecordId,
          @vImportReturnCode   TInteger,
          @vRecordsPerRun      TCount,
          @vControlCategory    TCategory,
          @vIsDESameServer     TFlag,

          @vSourceReference  TDescription;
begin /* pr_Imports_CIMSDE_ImportData */
begin try
  SET NOCOUNT ON;

  select @vControlCategory    = 'Import_' + @RecordType;
  select @vRecordsPerRun      = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'RecordsPerRun', 200, @BusinessUnit, @UserId),
         @vIsDESameServer     = dbo.fn_Controls_GetAsBoolean('Imports', 'IsDESameServer',  'Y',  @BusinessUnit, @UserId),
         @vImportResultRecId  = 1;

  /* At present we are processing the imports of open records in chunks, so we need to loop thru all the records
    processed */
  while (@vImportResultRecId > 0)
    begin
      /* reset values here */
      select @vImportResultRecId = 0, @vImportData = null;

      /* call procedure here to process the records - i.e we need to call cims
         import record procedure to import and process all records in CIMS */
      if (@RecordType = 'SKU')
        exec CIMSDE_pr_GetSKUsToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun, null,
                                       @vIsDESameServer, @vImportResultRecId output;
      else
      if (@RecordType = 'ASNLH')
        exec CIMSDE_pr_GetASNLPNsToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                          @vImportResultRecId output;
      else
      if (@RecordType = 'ASNLD')
        exec CIMSDE_pr_GetASNLPNDetailsToImport @UserId, @BusinessUnit, null /*Ownership */, @vRecordsPerRun,
                                                @vImportResultRecId output;
      else
      if (@RecordType = 'CT')
        exec CIMSDE_pr_GetCartonTypesToImport @UserId, @BusinessUnit, null /*Ownership */, @vRecordsPerRun,
                                              @vImportResultRecId output;
      else
      if (@RecordType = 'CNT')
        exec CIMSDE_pr_GetContactsToImport @UserId, @BusinessUnit, null /*Ownership */, @vRecordsPerRun,
                                           @vImportResultRecId output;
      else
      if (@RecordType = 'NOTE')
        exec CIMSDE_pr_GetNotesToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                        @vImportResultRecId output;
      else
      if (@RecordType = 'OH')
        exec CIMSDE_pr_GetOrderHeadersToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun, null,
                                               @vIsDESameServer, @vImportResultRecId output;
      else
      if (@RecordType = 'OD')
        exec CIMSDE_pr_GetOrderDetailsToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun, null,
                                               @vIsDESameServer, @vImportResultRecId output;
      else
      if (@RecordType = 'RD')
        exec CIMSDE_pr_GetReceiptDetailsToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                                 @vImportResultRecId output;
      else
      if (@RecordType = 'RH')
        exec CIMSDE_pr_GetReceiptHeadersToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                                 @vImportResultRecId output;
      else
      if (@RecordType in ('SMP', 'SPP'))
        exec CIMSDE_pr_GetSKUPrePacksToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                              @vImportResultRecId output;
      else
      if (@RecordType = 'UPC')
        exec CIMSDE_pr_GetUPCsToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                       @vImportResultRecId output;
      else
      if (@RecordType = 'TRFINV')
        exec CIMSDE_pr_GetInvAdjustmentsToImport @UserId, @BusinessUnit, null /* Ownership */, @vRecordsPerRun,
                                                 @vImportResultRecId output;

      /* if there are no open records to process then return - no need to call any other procedures */
      if (coalesce(@vImportResultRecId, 0) = 0)
        break;

      /* Get the xml from DE database for processing in CIMS */
      select @vImportData = Result
      from CIMSDE_ImportResults
      where (RecordId = @vImportResultRecId);

      /* call procedure here to process the records - i.e we need to call CIMS
         import record procedure to import and process all records in CIMS */
      if (@vIsDESameServer = 'Y') /* If CIMSDE is same server then process through ##ImportSKUs table */
        exec @vImportReturnCode = pr_Imports_ImportsSQLData @RecordType, @BusinessUnit, @vIsDESameServer, @vxmlResult output;
      else
        begin
          /* convert into xml from varchar */
          select @vxmlImportData = convert(xml, @vImportData);

          exec @vImportReturnCode = pr_Imports_ImportRecords @vxmlImportData, @vxmlResult output;
        end

      /* convert from xml to varchar  */
      select @vStrResult = convert(varchar(max), @vxmlResult);

      /* call procedure here to update the records with result after we processed
         in CIMS , so that we will not process these records in next turn when job runs.
         If there are any errors while processing then we will update that in result column */
      if (@vImportReturnCode = 0)
        exec CIMSDE_pr_AckImportedRecords @vStrResult, @RecordType, @vImportResultRecId, null /* ImportXml */, null /* Message */, @UserId, @BusinessUnit;
      else
        exec CIMSDE_pr_AckImportedRecords null /* NoResult */, @RecordType, @vImportResultRecId,
                                         @vxmlImportData /* Inputxml */, 'Import Error', @UserId, @BusinessUnit;
    end
end try
begin catch
  /* log into Interface table with the failure message for tracking/Research */
  select @vMessage         = Error_Message(),
         @vSourceReference = Object_Name(@@ProcId);

  /* Mark the records of this batch as Error */
  exec CIMSDE_pr_AckImportedRecords null /* NoResult */, @RecordType, @vImportResultRecId,
                                     @vxmlImportData /* Inputxml */, @vMessage, @UserId, @BusinessUnit;

  /* Save the exceptions to InterfaceLog tables so that users can be alerted of the failure */
  exec pr_InterfaceLog_SaveExceptions 'CIMSDE' /* Source System */, 'CIMS' /* Target System */,
                                      @vSourceReference, 'Import' /* Transfer Type */,
                                      'End' /* Process Type */, 'DB' /* RecordTypes */,
                                      @BusinessUnit, @vMessage;

  /* raise an exception if there is any */
  exec pr_ReRaiseError;

end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_CIMSDE_ImportData */

Go
