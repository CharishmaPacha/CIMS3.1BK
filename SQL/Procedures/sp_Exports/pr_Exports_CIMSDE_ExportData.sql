/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/04  VS      pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData, pr_Exports_GetData: Improve the Performance of Export data to CIMSDE DB (HA-3032)
  2021/08/02  VS      pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData: Improve the Performance of Export data to CIMSDE DB (HA-3032)
  2021/06/09  RKC     pr_Exports_CIMSDE_ExportData: Added the TransType in where condition
  2021/06/01  RKC     pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData: Used the #table instead of temp table (HA-2850)
  2020/02/12  VS      pr_Exports_CIMSDE_ExportData: Added Looping to Exports multiple batches in schedule single(S2G-1369)
  2021/02/01  SK      pr_Exports_InsertRecords, pr_Exports_CIMSDE_ExportData, pr_Exports_GetData
                      pr_Exports_CIMSDE_ExportData: Changes to mark interface record as succeeded (S2G-339)
                      pr_Exports_CIMSDE_ExportData, pr_Exports_CIMSDE_ExportOnhandInventory, pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenOrders
  2018/03/19  SV      pr_Exports_CIMSDE_ExportData: We always need to pass the user given I/P rather than exporting all the unprocess records - WIP
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CIMSDE_ExportData') is not null
  drop Procedure pr_Exports_CIMSDE_ExportData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CIMSDE_ExportData: This procedure is used to send the export data
    for a given batch to CIMSDE database. If no batch is given, it would create a
    new batch and push the results of the newly created batch to CIMSDE.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CIMSDE_ExportData
  (@TransType     TTypeCode  = null,
   @BatchNo       TBatch     = null,
   @Ownership     TOwnership = null,
   @SourceSystem  TName      = null,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vIntegrationType    TControlValue,
          @vExportsOnHold      TControlValue,
          @vExportHoldTimeStr  TControlValue,
          @vTransferToDBMethod TControlValue,
          @vExportHoldDateTime TDateTime,

          @vxmlResult          xml,
          @vxmlResultString    TXML,

          @vMessage            TNVarchar,
          @vSourceReference    TDescription,
          @vRecordId           TRecordId,
          @vResultXML          TXML;

  declare @vExportBatches table (RecordId          TInteger identity(1,1),
                                 ExportBatch       TBatch,
                                 Status            TStatus,
                                 ProcessedDateTime TDatetime);

begin /* pr_Exports_CIMSDE_ExportData */
begin try
  select @vRecordId           = 0,
         @vIntegrationType    = dbo.fn_Controls_GetAsString ('Exports', 'IntegrationType',     'DE',       @BusinessUnit, @UserId),
         @vTransferToDBMethod = dbo.fn_Controls_GetAsString ('Exports', 'TransferToDBMethod',  'SQLDATA',  @BusinessUnit, @UserId);

  /* Create #ExportBatches if it doesn't exist */
  if (object_id('tempdb..#ExportBatches') is null)
    select * into #ExportBatches from @vExportBatches;

  /* if the integration type is not database, then exit as this procedure is only
     for DB integration */
  if (@vIntegrationType <> 'DB')
    return;

  /* Get the Batches which are not Exported to the Host */
  insert into #ExportBatches (ExportBatch, Status)
    select ExportBatch, Status
    from Exports
    where (Status = 'N') and
          (ExportBatch > 0) and
          (TransType = coalesce(@TransType, TransType))
    group by ExportBatch, Status
    order by ExportBatch;

  /* Export all batches information to the Host */
  while exists (select * from #ExportBatches where RecordId > @vRecordId)
    begin
      select top 1 @BatchNo   = ExportBatch,
                   @vRecordId = RecordId
      from #ExportBatches
      where RecordId > @vRecordId
      order by RecordId;

      /* call procedure here to get the open data to export to host */
      exec pr_Exports_CaptureData @BatchNo /* BatchNo */, @vIntegrationType /* integration type */, @vTransferToDBMethod, @TransType /* transtype */,
                                  @Ownership, @SourceSystem, @BusinessUnit, @UserId, null /* xml input */,
                                  @vxmlResult output;

      /* convert xml data to varchar */
      select @vxmlResultString = convert(varchar(max), @vxmlResult);

      /* call procedure here to export the data into host exports table */
      exec CIMSDE_pr_PushExportDataFromCIMS @BatchNo, @vxmlResultString, @vTransferToDBMethod, @UserId, @BusinessUnit;

      /* Mark Interface records as succeeded. However, if it is SQLData, we will do all at once in the end */
      if (@vTransferToDBMethod <> 'SQLDATA')
        exec pr_InterfaceLog_MarkAsProcessed null /* IntefaceLogId */, @vxmlResult;

      /* Mark the Batch as processed */
      update #ExportBatches
      set status            = 'Y' /* Processed */,
          ProcessedDateTime = current_timestamp
      where (ExportBatch = @BatchNo) and (Status = 'N');

      /* Clear the string once records are processed */
      select @BatchNo = null, @vxmlResultString = null, @vxmlResult =  null

      /* For Every Batch it will drop the table and will create new ##ExportTransactions table */
      if (object_id('tempdb..##ExportTransactions') is not null)
        drop table ##ExportTransactions
    end

  /* Calculate the Status and log the EndTime as the interface processing is completed */
  if (@vTransferToDBMethod = 'SQLDATA') and exists (select * from #ExportBatches where Status = 'Y')
    begin
      update IL
      set Status       = case when (RecordsFailed = 0) then 'S'/* Succeeded */ else 'F'/* Failed */ end,
          EndTime      = current_timestamp,
          ModifiedDate = current_timestamp
      from InterfaceLog IL
        join #ExportBatches EB on IL.SourceReference = cast(EB.ExportBatch as varchar);
    end

end try
begin catch
  /* log into Interface table with the failure message for tracking/Research */
  select @vMessage         = Error_Message(),
         @vSourceReference = Object_Name(@@ProcId);

  /* Save the exceptions to InterfaceLog tables so that users can be alerted of the failure */
  exec pr_InterfaceLog_SaveExceptions 'CIMS' /* Source System */, 'CIMSDE' /* Target System */,
                                      @vSourceReference, 'Export' /* Transfer Type */,
                                      'End' /* Process Type */, 'DB' /* RecordTypes */,
                                      @BusinessUnit, @vMessage;

  /* raise an exception if there is any */
  exec pr_ReRaiseError;

end catch;

end /* pr_Exports_CIMSDE_ExportData */

Go
