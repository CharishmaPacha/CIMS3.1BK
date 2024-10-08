/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/13  VS      pr_Imports_ImportSQLRecords: Pass the RecordId to process the Duplicate records (cIMSV3-1604)
  2021/08/20  OK      pr_Imports_OrderHeaders: Enhanced to use Hash tables and refactored the code to have seperate procs for Insert, Update and delete
                      pr_Imports_ImportsSQLData, pr_Imports_ImportSQLRecords: Enhanced to support OH and OD imports (CIMSV3-1603 and CIMSV3-1604)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ImportSQLRecords') is not null
  drop Procedure pr_Imports_ImportSQLRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ImportSQLRecords: Procedure to process records sequentially when ##Imports
  1. Has duplicate records (i.e. same SKU repeated twice in a SKU import) OR
  2. Has Records to be deleted
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ImportSQLRecords
  (@ImportTableName  TName,
   @BusinessUnit     TBusinessUnit = null,
   @IsDESameServer   TFlag         = null,
   @ParentLogId      TRecordId     = null,
   @RecordType       TRecordType   = null,
   @RecordCount      TCount        = null)
as
  declare @vReturnCode       TInteger,
          @vRecordType       TRecordType,
          @vRecordId         TRecordId,
          @vImportRecordId   TRecordId,
          @vTransferType     TTransferType,
          @vRecordsFailed    TCount,
          @vResultXML        TXML,
           /* Open Xml Document variables */
          @vXmlDocHandle     TInteger,
          @xmldata           xml,
          @vSQL              TSQL,
          @vDebug            TControlValue = 'N';
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vRecordId     = 0,
         @vTransferType = 'Import';

  /* Get the ImportRecordId to process records sequentially */
  select @vSQL = 'insert into #ImportBatchRecords(ImportRecordId)' +
                 '  select RecordId from ' + @ImportTableName;

  exec sp_executesql @vSQL;

  /* Loop through each record and call the respective impport procedure to insert/Update/delete data */
  while exists (select * from #ImportBatchRecords where RecordId > @vRecordId)
    begin
      begin try
      begin transaction
        /* Get the ImportRecordId from #ImportBatchRecords */
        select top 1 @vRecordId       = IMS.RecordId,
                     @vImportRecordId = IMS.ImportRecordId
        from #ImportBatchRecords IMS
        where (IMS.RecordId > @vRecordId)
        order by IMS.RecordId;

        /* Call Import process respective to the RecordType */
        if (@RecordType = 'SKU' /* SKUs */)
          exec pr_Imports_SKUs null, null, @ParentLogId, @BusinessUnit, @IsDESameServer, @RecordId = @vImportRecordId;
        else
        if (@RecordType = 'OH' /* Order Headers */)
          exec pr_Imports_OrderHeaders null, null, @ParentLogId, @BusinessUnit, @IsDESameServer, @RecordId = @vImportRecordId;
        else
        if (@RecordType = 'OD' /* Order Details */)
          exec pr_Imports_OrderDetails null, null, @ParentLogId, @BusinessUnit, @IsDESameServer, @RecordId = @vImportRecordId;

      end try
      begin catch
        select @vRecordsFailed += @vRecordsFailed;

        /* Log the error message for processing this record */
        select @vResultXML = (select Error_Message() as Error for xml path(''));

        insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, LogMessage, KeyData,
                                         HostReference, BusinessUnit, Inputxml, Resultxml)
          select @ParentLogId, @vTransferType, @RecordType, 'Error', null,
                 @ImportTableName + 'ID:'+cast(@vImportRecordId as varchar(35)),
                 @BusinessUnit, null, @vResultXML;
      end catch

      /* Always commit this transaction since errors per record are noted and other records can continue to process */
      commit transaction;

      /* If more than 50% records failed, raise error to stop processing */
      if ((@vRecordsFailed * 1.0/@RecordCount) > 0.5)
        raiserror('More than 50% imports failed', 16, 1);
    end /* End of while loop */

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ImportSQLRecords */

Go
