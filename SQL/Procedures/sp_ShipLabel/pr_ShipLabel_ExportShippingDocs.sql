/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/17  RV      pr_ShipLabel_ExportShippingDocs, pr_ShipLabel_GetLPNsToGenerateLabels: Bug fixed to log properly in InterfaceLog (S2G-539)
  2018/05/06  PK      pr_ShipLabel_ExportShippingDocs: Returning TrackingNo, FileName in the dataset (S2G-826).
  2018/04/10  RV      pr_ShipLabel_ExportShippingDocs: Made changes to export shipping documents for export required waves (S2G-545)
  2018/03/10  RV      pr_ShipLabel_ExportShippingDocsComplete: Initial version (S2G-268)
  2018/02/20  RV      pr_ShipLabel_ExportShippingDocs: Initial version (S2G-268)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_ExportShippingDocs') is not null
  drop Procedure pr_ShipLabel_ExportShippingDocs;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_ExportShippingDocs:
  This procedure is called from console application to export ship labels and Packing lists

  @xmlInput xml structure:
  <ShippingDocsToExport>
    <ProcessInstance>InstanceNumber</ProcessInstance>
    <TransferType>TransType</TransferType>
    <RecordType>RecordType</RecordType>
    <BusinessUnit>BusinessUnit</BusinessUnit>
    <UserId>UserId</UserId>
  </ShippingDocsToExport>

  @xmlResult xml structure:
  <Root>
    <InterfaceLogInfo>
      <InterfaceLogId>InterfaceLogId<InterfaceLogId>
    </InterfaceLogInfo>
  <ShippingDocsToExport>
    <Entity>
      <EntityKey>LPN</EntityKey>
      <ShipLabelData>LabelData</ShipLabelData>
      <PackingListData>Packing list for LPN</PackingListData>
    </Entity>
    <Entity>
      <EntityKey>LPN</EntityKey>
      <ShipLabelData>LabelData</ShipLabelData>
      <PackingListData>Packing list for LPN</PackingListData>
    </Entity>
      .
      .
    </ShippingDocsToExport>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_ExportShippingDocs
  (@xmlInput          XML,
   @xmlResult         XML output)
as
  declare @vExportInstance      varchar(50),
          @vNextExportBatch     TBatch,
          @vLabelsToExportCount TCount,

          @vWaveId              TRecordId,

          @vInterfaceLogId      TRecordId,
          @vTransferType        TTransferType,
          @vRecordTypes         TRecordType,
          @vSourceReference     TName,

          @vXMLEntities         XML,
          @vXMLResult           TXML,

          @vBusinessUnit        TBusinessUnit,
          @vUserId              TUserId;

  declare @ttShippingDocsToExport  table
          (RecordId        TRecordId identity(1,1),
           EntityKey       TEntityKey,
           TrackingNo      TTrackingNo,
           LabelData       TVarchar,
           PackingListData TVarchar,
           FileName        TVarchar
          );
begin /* pr_ShipLabel_ExportShippingDocs */
begin try
  begin transaction;
  SET NOCOUNT ON;

  if (@xmlInput is null)
    return;

  select @vExportInstance = Record.Col.value('ProcessInstance[1]',  'varchar(50)'),
         @vTransferType    = Record.Col.value('TransferType[1]',    'TTransferType'),
         @vRecordTypes     = Record.Col.value('RecordType[1]',      'TRecordType'),
         @vBusinessUnit    = Record.Col.value('BusinessUnit[1]',    'TBusinessUnit'),
         @vUserId          = Record.Col.value('UserId[1]',          'TUserId')
  from @xmlInput.nodes('/ShippingDocsToExport') as Record(Col);

  /* Get the first wave to export all documents, which are related to wave as single batch */
  select top 1 @vWaveId = WaveId
  from ShipLabels
  where (ProcessStatus = 'XR' /* Export Required */) and
        (BusinessUnit  = @vBusinessUnit) and
        (Status        = 'A' /* Active */) and
        (WaveId is not null)
  order by RecordId;

  /* If there are no records to export then exit */
  if (coalesce(@vWaveId, 0) = 0)
    goto ExitHandler;

  /* Get the next label export batch no */
  exec pr_Controls_GetNextSeqNo 'ExportShippingDocs', 1, @vUserId, @vBusinessUnit,
                                @vNextExportBatch output;

  /* Update shiplabels records to Export Inprogress and insert the updated records into temp table to export */
  update ShipLabels
  set ProcessStatus  = 'XI' /* Export In Progress */,
      ExportInstance = @vExportInstance,
      ExportBatch    = @vNextExportBatch,
      ModifiedDate   = current_timestamp
  output Inserted.EntityKey, Inserted.TrackingNo, Inserted.ZPLLabel into @ttShippingDocsToExport (EntityKey, TrackingNo, LabelData)
  where (WaveId         = @vWaveId) and
        (ProcessStatus  = 'XR' /* Export Required */) and
        (Status         = 'A' /* Active */) and
        (WaveId is not null);

  /* If we do not send LogId then we are trying to find LogId by using Source Reference, so there is
     chance to have same Batch Number. Avoid this by prefixing the caller identitiy.
     This is true for all callers of pr_InterfaceLog_AddUpdate to have unique reference to send */
  select @vLabelsToExportCount = @@rowcount,
         @vSourceReference     = 'ExportShippingDocs_' + cast(@vNextExportBatch as varchar);

  /* We need to format Packing list data once we get the details from the client */

  /* Update PL data in temp table.
     Note: As of now framing with dummy data */
  update TSDE
  set PackingListData = 'Packing list for LPN: ' + TSDE.EntityKey
  from @ttShippingDocsToExport TSDE;

  /* Create interface log */
  exec pr_InterfaceLog_AddUpdate @SourceSystem     = 'CIMS',
                                 @TargetSystem     = 'WSS',
                                 @SourceReference  = @vSourceReference,
                                 @TransferType     = @vTransferType,
                                 @BusinessUnit     = @vBusinessUnit,
                                 @xmlData          = null,
                                 @xmlDocHandle     = null,
                                 @RecordsProcessed = @vLabelsToExportCount,
                                 @LogId            = @vInterfaceLogId output,
                                 @RecordTypes      = @vRecordTypes output;

  select @vXMLResult = dbo.fn_XMLNode('Root',
                         dbo.fn_XMLNode('InterfaceLogInfo',
                         dbo.fn_XMLNode('InterfaceLogId', @vInterfaceLogId)));

  /* Return data set with ship label and packing list data */
  select EntityKey, TrackingNo, LabelData, PackingListData, TrackingNo as FileName
  from @ttShippingDocsToExport;

ExitHandler:
  select @xmlResult = convert(xml, @vXMLResult);
  commit transaction;
end try
begin catch
  rollback transaction;
end catch
end /* pr_ShipLabel_ExportShippingDocs */

Go
