/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/01  VS      pr_Import_SQLDataInterfaceLog: Log the ImportBatch in interface logs (HA-3084)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Import_SQLDataInterfaceLog') is not null
  drop Procedure pr_Import_SQLDataInterfaceLog;
Go
/*------------------------------------------------------------------------------
  pr_Import_SQLDataInterfaceLog: Procedure used to add InterfaceLogs and get the
  RecordCount, duplicate record counts, Action

  @ImportTableName: Based on ImportTable name get the values to log into interfacelogs
  @ParentLogId: To get the InterfacelogId
------------------------------------------------------------------------------*/
Create Procedure pr_Import_SQLDataInterfaceLog
  (@ImportTableName   TName,
   @BusinessUnit      TBusinessUnit,
   @RecordType        TRecordType,
   @ParentLogId       TRecordId     output,
   @Actions           TFlags        output,
   @RecordCount       TCount        output,
   @DuplicateRecords  TInteger      output)
as
  declare @vTransferType      TTransferType,
          @vImportBatchNo     TBatch,
          @vXMLData           xml,
          @vSQL               nvarchar(max);

  declare @ttRecordActions table (RecordType TRecordType,
                                  Action     TAction);
begin

  /* Create hash tables if they don't exist */
  if (object_id('tempdb..#ttRecordActions') is null) select * into #ttRecordActions from @ttRecordActions;

  /* Get the Total count of RecordCount in the ##ImportRecords */
  select @vSQL = 'select @vRecordCount   = count(*),
                         @vImportBatchNo = min(ImportBatch)
                  from ' + @ImportTableName;

  /* Run Dynamic SQL, Get the Record count */
  execute sp_executesql @vSQL, N'@vRecordCount TCount output, @vImportBatchNo TBatch output',
                        @vRecordCount = @RecordCount output, @vImportBatchNo = @vImportBatchNo output;

  /* Build the ImportBatch in XML to log in interfacelog to know which ImportBatch is being processed */
  select @vXMLData = dbo.fn_XMLNode('ImportBatchNo', @vImportBatchNo);

  /* Review the entire XML and figure out if there is a single record type and
     what actions are involved.
     Assumption: All records will have RecordType and Action specified */
  select @vSQL = 'insert into #ttRecordActions (RecordType, Action)
                    select distinct RecordType, RecordAction /* Need to pass the action */
                    from '+ @ImportTableName;

  exec sp_executesql @vSQL;

  /* Get the number of record types and the various actions in the XML */
  select @Actions += Action from #ttRecordActions;

  /* Get the DuplicateRecord count */
  select @vSQL = 'select @vDuplicateRecords = count(*)
                   from '+ @ImportTableName + ' '+'
                   group by KeyData
                   having count(*) > 1;'

  /* Run Dynamic SQL, Get the Duplicate record count */
  execute sp_executesql @vSQL, N'@vDuplicateRecords TInteger output', @vDuplicateRecords = @DuplicateRecords output;

  /* Call AddUpdate Procedure to add the given entry to InterfaceLog */
  /* @SourceReference is used for Exports validation in the below proc. */
  exec pr_InterfaceLog_AddUpdate @SourceSystem     = 'CIMSDE',
                                 @TargetSystem     = 'CIMS',
                                 @SourceReference  = 'pr_Imports_CIMSDE_ImportData',
                                 @TransferType     = 'Import',
                                 @xmlData          = @vXMLData,
                                 @xmlDocHandle     = null,
                                 @RecordsProcessed = @RecordCount,
                                 @BusinessUnit     = @BusinessUnit,
                                 @LogId            = @ParentLogId output,
                                 @RecordTypes      = @RecordType output;

end /* pr_Import_SQLDataInterfaceLog */

Go
