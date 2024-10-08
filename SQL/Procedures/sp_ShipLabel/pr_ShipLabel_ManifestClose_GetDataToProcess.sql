/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/04  RV      pr_ShipLabel_ManifestClose_GetDataToProcess: Made changes to send Carrier from ShipVias instead of ShipLabels,
  2019/01/16  RV      pr_ShipLabel_ManifestClose_GetDataToProcess
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_ManifestClose_GetDataToProcess') is not null
  drop Procedure pr_ShipLabel_ManifestClose_GetDataToProcess;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_ManifestClose_GetDataToProcess:
  This procedure is called from console application to export to Manifest Close

@xmlInput xml structure:

<InputXML>
  <ProcessInstance>1</ProcessInstance>
  <TransferType>MainfestExport</TransferType>
  <RecordType>ME</RecordType>
  <BusinessUnit>S2G</BusinessUnit>
  <UserId>CIMSAgent</UserId>
</InputXML>'

@xmlResult xml structure:

<OutputXML>
  <InterfaceLogInfo>
    <InterfaceLogId>InterfaceLogId</InterfaceLogId>
  </InterfaceLogInfo>
  <ManifestCloseDetails>
    <ManifestExportBatch>ManifestExportBatchNo</ManifestExportBatch>
    <CarrierInterface>ADSI</CarrierInterface>
    <Carrier>UPS</Carrier>
    <ShipperAccountName>ADSI</ShipperAccountName>
    <ShipDate>Date</ShipDate>
    <EntitiesToManifest>TrackingNo1,TackingNo2..</EntitiesToManifest>
  </ManifestCloseDetails>
</OutputXML>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_ManifestClose_GetDataToProcess
  (@xmlInput          XML,
   @xmlResult         XML output)
as
  declare @vManifestExportInstance  TName,
          @vManifestExportBatch     TBatch,
          @vLabelsToExportCount     TCount,

          @vEntityKey               TEntityKey,
          @vOrderId                 TRecordId,
          @vLoadId                  TRecordId,

          @vInterfaceLogId          TRecordId,
          @vTransferType            TTransferType,
          @vRecordTypes             TRecordType,
          @vSourceReference         TName,

          @vCarrierInterface        TCarrierInterface,
          @vCarrier                 TCarrier,
          @vShipperAccountName      TName,
          @vShipDate                TDate,
          @vEntitiesToManifest      TXML,

          @xmlRulesData             TXML,
          @vActivityLogId           TRecordId,

          @vXMLEntities              XML,
          @vXMLInput                 TXML,
          @vXMLResult                TXML,

          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId;

  declare @ttManifestExportToExport  table
          (RecordId        TRecordId identity(1,1),
           EntityKey       TEntityKey,
           TrackingNo      TTrackingNo,
           FileName        TVarchar
          );
begin /* pr_ShipLabel_ManifestClose_GetDataToProcess */
begin try
  begin transaction;
  SET NOCOUNT ON;

  if (@xmlInput is null)
    return;

  /* Parse the input xml data */
  select @vManifestExportInstance  = Record.Col.value('ProcessInstance[1]', 'varchar(50)'),
         @vTransferType            = Record.Col.value('TransferType[1]',    'TTransferType'),
         @vRecordTypes             = Record.Col.value('RecordType[1]',      'TRecordType'),
         @vBusinessUnit            = Record.Col.value('BusinessUnit[1]',    'TBusinessUnit'),
         @vUserId                  = Record.Col.value('UserId[1]',          'TUserId')
  from @xmlInput.nodes('/InputXML') as Record(Col);

  /* Get the first batchc to manifest export to close, which are related to Load as single batch
     Note: ManifestBatch updated with LoadId while Load mark as shipped */
  select top 1 @vEntityKey           = SL.EntityKey,
               @vOrderId             = SL.OrderId,
               @vManifestExportBatch = SL.ManifestExportBatch,
               @vCarrierInterface    = SL.CarrierInterface,
               @vCarrier             = S.Carrier
  from ShipLabels SL
    join ShipVias S on (SL.RequestedShipVia = S.ShipVia)
  where (SL.ManifestExportStatus = 'XR' /* Export Required */) and
        (SL.BusinessUnit         = @vBusinessUnit) and
        (SL.Status               = 'A' /* Active */) and
        (SL.TrackingNo           <> '')
  order by SL.RecordId;

  select @vXMLInput = cast(@xmlInput as varchar(max))

  /* Activity Log */
  exec pr_ActivityLog_AddMessage 'ManifestClose_GetDataToProcess', null, @vManifestExportBatch, 'ManifestExportBatch',
                                 null, @@ProcId, @vXMLInput,
                                 @vBusinessUnit, @vUserId, @ActivityLogId = @vActivityLogId output;

  /* If there are no records to Manifest close then exit */
  if (coalesce(@vManifestExportBatch, 0) = 0)
    goto ExitHandler;

  select @vShipperAccountName = ShipperAccountName
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get ship date from Loads */
  select @vShipDate = ShippedDate
  from Loads LD
    join LPNs L on (L.LoadId = LD.LoadId)
  where (L.LPN = @vEntityKey);

  /* Update shiplabels records to Manifest Export Inprogress and insert the updated records into temp table to export */
  update ShipLabels
  set ManifestExportStatus  = 'XI' /* Export In Progress */,
      ModifiedDate          = current_timestamp
  output Inserted.EntityKey, Inserted.TrackingNo into @ttManifestExportToExport (EntityKey, TrackingNo)
  where (ManifestExportBatch   = @vManifestExportBatch) and
        (ManifestExportStatus  = 'XR' /* Export Required */) and
        (Status                = 'A' /* Active */) and
        (TrackingNo            <> '');

  select @vLabelsToExportCount = @@rowcount;

  /* Get all the entities as comma seperated with list tracking numbers */
  select @vEntitiesToManifest = stuff((select ',' + TrackingNo
                                       from @ttManifestExportToExport
                                       FOR XML PATH(''), TYPE)
                                      .value('.','varchar(MAX)'), 1, 1, '');

  /* If we do not send LogId then we are trying to find LogId by using Source Reference, so there is
     chance to have same Batch Number. Avoid this by prefixing the caller identitiy.
     This is true for all callers of pr_InterfaceLog_AddUpdate to have unique reference to send */
  select @vSourceReference = 'ManifestExport_' + cast(@vManifestExportBatch as varchar);

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

  /* Build output XML */
  select @vXMLResult = dbo.fn_XMLNode('OutputXML',
                         dbo.fn_XMLNode('InterfaceLogInfo',
                           dbo.fn_XMLNode('InterfaceLogId',          @vInterfaceLogId)) +
                         dbo.fn_XMLNode('ManifestCloseDetails',
                           dbo.fn_XMLNode('ManifestExportBatch',     @vManifestExportBatch) +
                           dbo.fn_XMLNode('CarrierInterface',        @vCarrierInterface) +
                           dbo.fn_XMLNode('Carrier',                 @vCarrier) +
                           dbo.fn_XMLNode('ShipperAccountName',      @vShipperAccountName) +
                           dbo.fn_XMLNode('ShipDate',                @vShipDate) +
                           dbo.fn_XMLNode('EntitiesToManifest',      coalesce(@vEntitiesToManifest, ''))));

  /* Activity Log */
  exec pr_ActivityLog_AddMessage 'ManifestClose_GetDataToProcess', null, @vManifestExportBatch, 'ManifestExportBatch', null, @@ProcId, @vXMLResult,
                                 @vBusinessUnit, @vUserId, @ActivityLogId = @vActivityLogId output;

ExitHandler:
  select @xmlResult = convert(xml, @vXMLResult);
  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
end catch
end /* pr_ShipLabel_ManifestClose_GetDataToProcess */

Go
