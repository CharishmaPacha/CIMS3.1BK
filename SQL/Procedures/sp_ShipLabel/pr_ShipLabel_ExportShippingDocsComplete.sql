/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/10  RV      pr_ShipLabel_ExportShippingDocsComplete: Initial version (S2G-268)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_ExportShippingDocsComplete') is not null
  drop Procedure pr_ShipLabel_ExportShippingDocsComplete;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_ExportShippingDocsComplete:
    This procedure is called from console application after export shipping docs completed to log interface details
    if there are any errors.

  @XMLInput structure:
  <Root>
    <InterfaceLogId>InterfaceLogId</InterfaceLogId>
    <TransferType>TransType</TransferType>
    <RecordType>RecordType</RecordType>
    <BusinessUnit>BusinessUnit</BusinessUnit>
    <UserId>UserId</UserId>
    <ShippingDocsExportErrors>
      <Entity>
        <EntityKey></EntityKey>
        <Error></Error>
      </Entity>
      <Entity>
        <EntityKey></EntityKey>
        <Error></Error>
      </Entity>
      .
      .
    </ShippingDocsExportErrors>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_ExportShippingDocsComplete
  (@xmlInput          XML,
   @xmlResult         XML output) -- for future use
as
  declare @vInterfaceLogId        TRecordId,
          @vTransferType          TTransferType,
          @vRecordType            TRecordType,

          @vExportBatch           TBatch,

          @vRecordsProcessed      TCount,
          @vRecordsFailed         TCount,
          @vRecordsPassed         TCount,

          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId;

  declare @ttShippingDocsErrorDetails table
          (RecordId        TRecordId identity(1,1),
           KeyData         TEntityKey,
           ResultXML       TXML);

begin /* pr_ShipLabel_ExportShippingDocsComplete */
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vRecordsFailed = 0;

  if (@xmlInput is null)
    return;

  select @vInterfaceLogId = Record.Col.value('InterfaceLogId[1]', 'TRecordId'),
         @vTransferType   = Record.Col.value('TransferType[1]',   'TTransferType'),
         @vRecordType     = Record.Col.value('RecordType[1]',     'TRecordType'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
         @vUserId         = Record.Col.value('UserId[1]',         'TUserId')
  from @xmlInput.nodes('/Root') as Record(Col);

  /* Extract the error for each entity into a temp table */
  insert into @ttShippingDocsErrorDetails (KeyData, ResultXML)
    select Record.Col.value('EntityKey[1]', 'TEntityKey'),
           dbo.fn_XMLNode('Error', Record.Col.value('Error[1]', 'varchar(max)'))
    from @xmlInput.nodes('/Root/ExportErrorDetail') as Record(Col);

  /* While inserting SourceReference ProcessBatch prefix with ExportShippingDocs_, So we exclude this to get the ProcessBatchNo */
  select @vExportBatch = substring(SourceReference, charindex('_', SourceReference) + 1, len(SourceReference))
  from InterfaceLog
  where (RecordId = @vInterfaceLogId);

  /* Update the process status with export error if there are any errors */
  update SL
  set SL.ProcessStatus = 'XE' /* Export Error */,
      SL.ModifiedDate  = current_timestamp,
      SL.ModifiedBy    = @vUserId
  from ShipLabels SL
    join @ttShippingDocsErrorDetails TTSDE on (SL.EntityKey = TTSDE.KeyData)
  where (SL.ExportBatch   = @vExportBatch) and
        (SL.ProcessStatus = 'XI' /* Export Inprogress */);

  /* Update the remaining labels of the export with export complete */
  update SL
  set SL.ProcessStatus = 'XC' /* Export Completed */,
      SL.ModifiedDate  = current_timestamp,
      SL.ModifiedBy    = @vUserId
  from ShipLabels SL
  where (SL.ExportBatch   = @vExportBatch) and
        (SL.ProcessStatus = 'XI' /* Export Inprogress */);

  /* Log all errors in InterfaceLogDetails */
  insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, KeyData, ResultXML, BusinessUnit)
    select @vInterfaceLogId, @vTransferType, @vRecordType,
           KeyData, ResultXML, @vBusinessUnit
    from @ttShippingDocsErrorDetails;

  select @vRecordsFailed = @@rowcount;

  /* Update counts & status on Interface log */
  exec pr_InterfaceLog_UpdateCounts @vInterfaceLogId, @vRecordsFailed;

  commit transaction;
end try
begin catch
  rollback transaction;
end catch
end /* pr_ShipLabel_ExportShippingDocsComplete */

Go
