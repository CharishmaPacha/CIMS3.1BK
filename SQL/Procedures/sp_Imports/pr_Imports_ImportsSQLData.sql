/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/17  VS      pr_Imports_CIMSDE_ImportData, pr_Imports_ImportsSQLData, pr_Imports_SKUs,
  pr_Imports_ImportsSQLData, pr_Imports_ImportSQLRecords: Enhanced to support OH and OD imports (CIMSV3-1603 and CIMSV3-1604)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ImportsSQLData') is not null
  drop Procedure pr_Imports_ImportsSQLData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ImportsSQLData: Processes ##Imports Records and import the records
  into CIMS tables processing either in bulk or each record.

  If the ##Imports has duplicate records (i.e. same SKU repeated twice in a SKU import)
  then we will process the record one by one using pr_Imports_ImportSQLData proc.
  If we do not have duplicate records then proces reocrds in bulk using pr_Imports_ImportsSQLData.

  @RecordType: Based on RecordType create ##Import-- table and process the records
  @IsDESameServer: Flag representing whether CIMSDE is on same server or not.
  @xmlResult: Get the Results from Interfacelogs to update in CIMSDE.ExchangeStatus

  ex: pr_Imports_ImportsSQLData 'SKU', 'HA', 'Y', @xmlResult output
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ImportsSQLData
  (@RecordType     TRecordType,
   @BusinessUnit   TBusinessUnit,
   @IsDESameServer TFlag    = null,
   @xmlResult      xml      = null output)
as
  declare @vxmlResult               xml,
          @vXmlRecord               xml,
          @vRecordCount             TCount,
          @vSourceSystem            TName,
          @vSourceReference         TName,
          @vTransferMethod          TName,
          @vTransferType            TTransferType,
          @vParentLogId             TRecordId,
          @vRecordsFailed           TInteger,
          @vActions                 TFlags,
          @vXmlRecordString         TXML,
          @vRecordTypes             TRecordTypes,
          @vReturnCode              TInteger,
          @vResultXML               TXML,
          @vXmlDocHandle            TInteger,
          @vCurrentRecordType       TRecordType,
          @vCurrentSequenceId       TRecordId,
          @vDuplicateRecords        TInteger,
          @vRecordId                TRecordId,
          @vImportTableName         TName,
          @vImportRecordId          TRecordId,
          @vSQL                     TSQL,
          @vDebug                   TControlValue = 'N';
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vRecordsFailed    = 0,
         @vActions          = '', /* Initialised, because we are appending the value during its next occurence */
         @vRecordId         = 0,
         @vTransferType     = 'Import';

  /* Create hash tables if they don't exist */
  if (object_id('tempdb..#ImportBatchRecords') is null)
    Create table #ImportBatchRecords(ImportRecordId int,
                                     RecordId       int identity(1,1));

  /* Get the ImportTable Name */
  select @vImportTableName = case when @RecordType = 'SKU' then '##ImportSKUs'
                                  when @RecordType = 'OH'  then '##ImportOrderHeaders'
                                  when @RecordType = 'OD'  then '##ImportOrderDetails'
                                  else null
                             end;

  /* Call to log into interface log and get total, duplicate record counts and actions */
  exec pr_Import_SQLDATAInterfaceLog @vImportTableName, @BusinessUnit, @RecordType,
                                     @vParentLogId output, @vActions output, @vRecordCount output, @vDuplicateRecords output;

  if (@vDebug = 'Y') select @vRecordCount RecordCount, @vActions Actions, @RecordType RecordType, @vParentLogId ParentLogId, @vDuplicateRecords DuplicateRecords;

  /* This procedure will process the import records in bulk (insert/Update) based on ImportBatch
     Exceptions are caught under caller procedure */
  if (charindex('D' /* delete */, @vActions) = 0) and (coalesce(@vDuplicateRecords, 0) = 0)
    begin
      if (@RecordType = 'SKU' /* SKUs */)
        exec pr_Imports_SKUs @InterfaceLogId = @vParentLogId, @IsDESameServer = @IsDESameServer;
      else
      if (@RecordType = 'OH' /* Order Headers */)
        exec pr_Imports_OrderHeaders @InterfaceLogId = @vParentLogId, @IsDESameServer = @IsDESameServer;
      else
      if (@RecordType = 'OD' /* Order Details */)
        exec pr_Imports_OrderDetails @InterfaceLogId = @vParentLogId, @IsDESameServer = @IsDESameServer;
    end
  else
    /* Process each record since the ImportBatch has duplicate records OR records to be deleted */
    exec pr_Imports_ImportSQLRecords @vImportTableName, @BusinessUnit, @IsDESameServer, @vParentLogId, @RecordType, @vRecordCount;

  /* All updates have been rolled back so update status here again. We are not updating the end time as the data
     was not processed successfully */
  update InterfaceLog
  set @vRecordsFailed = RecordsProcessed - RecordsPassed,
      RecordsFailed   = @vRecordsFailed,
      Status          = case when (@vRecordsFailed = 0) then 'S' /* Success */ else 'F' /* Failed */ end
  where (RecordId = @vParentLogId) and
        (Status   = 'P' /* In process */);

  /* Build Result XML to update in CIMSDE.ExchangeStatus */
  exec pr_Imports_GetXmlResult @vParentLogId, @vSourceSystem, @BusinessUnit, @vxmlResult output;

  select @xmlResult = @vxmlResult;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ImportsSQLData */

Go
