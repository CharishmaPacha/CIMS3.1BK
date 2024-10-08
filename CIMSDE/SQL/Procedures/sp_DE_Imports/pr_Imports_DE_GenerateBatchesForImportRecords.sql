/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/26  MS      pr_Imports_DE_GenerateBatchesForImportRecords: Bug fix to get KeyValue (BK-672)
  2021/10/05  VS      pr_ImportDE_CreateBatchesForImportRecords renamed to pr_Imports_DE_GenerateBatchesForImportRecords proc (HA-3084)
  2021/09/23  VS      pr_ImportDE_CreateBatchesForImportRecords renamed to pr_Imports_DE_GenerateBatchesForImportRecords proc (HA-3084)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GenerateBatchesForImportRecords') is not null
  drop Procedure pr_Imports_DE_GenerateBatchesForImportRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_DE_GenerateBatchesForImportRecords:
    This procedure is used to identify, create and update the batch numbers for input import table
    This will be invoked through a SQL Job running on CIMSDE

   @TableName:  Pass the Import Table name
   @KeyValue:   KeyValue for the import table

  ex: exec pr_Imports_DE_GenerateBatchesForImportRecords 'ImportSKUs', 'SKU', 'HA', 'cimsadmin'
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GenerateBatchesForImportRecords
  (@TableName          TName,
   @KeyValue           TControlValue,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vRecordsPerBatch       TInteger,
          @vNumRecords            TCount,
          @vNumBatches            TCount,
          @vNextSeqNo             bigint,
          @vSQL                   nvarchar(max);

  declare @ttImportRecords table (KeyValue       TControlValue,
                                  Status         TStatus,
                                  ImportBatch    TBatch,
                                  ImportRecordId TRecordId,
                                  RecordId       TInteger identity(1,1));
begin

  /* Create #ImportRecords temp table to create the ImportBatches */
  if object_id('tempdb..#ImportRecords') is null
    select * into #ImportRecords from @ttImportRecords

  /* Get the Controls */
  select @vRecordsPerBatch = dbo.fn_Controls_GetAsInteger('ImportBatch', 'RecordsPerBatch', '1000', @BusinessUnit, @UserId);

  /* Get the records which don't have the ImportBatches */
  select @vSQL = 'insert into #ImportRecords(ImportRecordId, ImportBatch, Status, KeyValue)
                    select RecordId, coalesce(ImportBatch, 0), ''N'', '+ '''' + @KeyValue + '''' +'
                    from ' + @TableName +'
                    where (ExchangeStatus = ''N'' /* Not yet processed */) and
                          (BusinessUnit   = '+''''+ @BusinessUnit +''''+') and
                          (coalesce(ImportBatch, 0)  = 0)
                    order by RecordId;'

  exec sp_executesql @vSQL;

  /* If there are no records then goto Exithandler */
  if not exists (select * from #ImportRecords)
    goto ExitHandler;

  /* Get the Total Records count */
  select @vNumRecords = count(*) from #ImportRecords;

  /* Compute num batches to be created */
  select @vNumBatches = ceiling(@vNumRecords * 1.0 / @vRecordsPerBatch)

  /* Get the next process batch */
  exec pr_Sequence_GetNext 'Seq_Imports_ImportBatch', @vNumBatches, @UserId, @BusinessUnit, @vNextSeqNo output;

  update #ImportRecords
  set ImportBatch = @vNextSeqNo + ceiling(RecordId * 1.0 / @vRecordsPerBatch)

  /* Update the Import Batch on ImportSKUs */
  set @vSQL = 'Update IMS
                set ImportBatch = ITS.ImportBatch
                from ' + @TableName +' IMS
                  join #ImportRecords ITS on ITS.ImportRecordId = IMS.RecordId
                where (IMS.ExchangeStatus = ''N'' /* Not yet processed */) and
                      (IMS.BusinessUnit   = '+''''+ @BusinessUnit +''''+') and
                      (coalesce(IMS.ImportBatch, 0) = 0)';

  exec sp_executesql @vSQL;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GenerateBatchesForImportRecords */

Go
