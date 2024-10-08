/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/06  AY      pr_ShipLabel_GetLPNsToGenerateLabels: Performance optimization (HA-3146)
                      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to generate the process batches ireespective of available batch (HA-2774)
                      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to get next batch to process and update process status
  2020/11/30  RKC     pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to updated generated process batch on the Zero process
  2019/06/15  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to create shipment with respect to the PickTicket (CID-176)
  2019/06/14  SPP     pr_ShipLabel_GetLPNsToGenerateLabels excluded UPS Label (CID-136) (Ported from Staging)
  2019/06/08  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to create FEDEX MPS with respect to the Order (CID-174)
  2019/06/06  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to create shipment with respect to the LPN for USPS (CID-388)
  2019/01/31  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to process labels stuck in GI (Generation InProgress) (S2G-1201)
  2018/09/24  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to generate labels, which have process batch as 0 (S2GCA-273)
                      pr_ShipLabel_GetLPNsToGenerateLabels: Excluded FEDEX label creation of Multi package shipment
  2018/07/11  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to batch the label to generate labels at once (S2G-1020)
  2018/07/09  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to create multi shipment from label generator (S2G-1004)
  2018/05/17  RV      pr_ShipLabel_ExportShippingDocs, pr_ShipLabel_GetLPNsToGenerateLabels: Bug fixed to log properly in InterfaceLog (S2G-539)
  2018/02/22  RV      pr_ShipLabel_GetLPNsToGenerateLabels: Made changes to exclude non small package carriers
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLPNsToGenerateLabels') is not null
  drop Procedure pr_ShipLabel_GetLPNsToGenerateLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLPNsToGenerateLabels:
  This procedure is called from console application to generate ship labels

  @xmlInput xml structure:
  <Root>
    <ProcessInstance>InstanceNumber</ProcessInstance>
    <Carrier>Carrier</Carrier>
    <BusinessUnit>BusinessUnit</BusinessUnit>
    <UserId>UserId</UserId>
  </Root>

  @XMLResult xml structure:
  <Root>
    <InterfaceLogInfo>
      <InterfaceLogId><InterfaceLogId>
    </InterfaceLogInfo>
    <LabelsToGenerate>
      <Entity>
        <EntityKey>LPN</EntityKey>
        <Carrier>Carrier</Carrier>
      </Entity>
    </LabelsToGenerate>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLPNsToGenerateLabels
  (@xmlInput          XML,
   @xmlResult         XML output)
as
  declare @vProcessInstance       varchar(50),
          @vCarrier               TCarrier,
          @vNextBatchToProcess    TBatch,
          @vLabelsToGenerateCount TCount,

          @vInterfaceLogId        TRecordId,
          @vTransferType          TTransferType,
          @vRecordTypes           TRecordType,
          @vSourceReference       TName,
          @vRecordsToBatchExist   TFlags,

          @vXMLEntities           XML,
          @vXMLResult             TXML,

          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId;

  declare @ttShipLabelsToGenerate  table
          (RecordId        TRecordId identity(1,1),

           EntityKey       TEntityKey,
           OrderId         TRecordId,
           Carrier         TCarrier,
           ProcessBatch    TBatch,
           Unique          (Carrier, RecordId),
           Unique          (OrderId, RecordId));

  declare @ttShipLabelEntities table
          (RecordId        TRecordId identity(1,1),
           EntityType      TTypeCode,
           OrderId         TRecordId,
           EntityKey       TEntityKey,
           Carrier         TCarrier);

begin /* pr_ShipLabel_GetLPNsToGenerateLabels */
begin try
  begin transaction;
  SET NOCOUNT ON;

  if (@xmlInput is null) return;

  select @vProcessInstance = Record.Col.value('ProcessInstance[1]', 'varchar(50)'),
         @vCarrier         = Record.Col.value('Carrier[1]',         'TCarrier'), /* For future use */
         @vTransferType    = Record.Col.value('TransferType[1]',    'TTransferType'),
         @vRecordTypes     = Record.Col.value('RecordType[1]',      'TRecordType'),
         @vBusinessUnit    = Record.Col.value('BusinessUnit[1]',    'TBusinessUnit'),
         @vUserId          = Record.Col.value('UserId[1]',          'TUserId')
  from @xmlInput.nodes('/InputGenerateLabels') as Record(Col);

  /* Not required to process if there are any other than small package carriers or voided LPNs */
  update ShipLabels
  set ProcessStatus    = 'NR' /* Not Required */
  where (ProcessStatus = 'N' /* Not yet processed */) and
        (Status        = 'V' /* Voided */) and
        (BusinessUnit  = @vBusinessunit);

  /* If Process Batch is Zero and Records exists then we need to updated New process batch on those records
     So many places we are inserting the Records into Shiplabels table with process batch as Zero
     From Allocation process we are computing the process batch but some other process we are not compluting the Process Batch
     for this case we need to Generate new process batch and need to update the records which has Process Batch as Zero
     This will also reset the batches stuck in GI so that they will be processsed again */
  exec pr_ShipLabel_GenerateBatches @vBusinessUnit, @vUserId;

  /* Get the next batch to generate the labels */
  with LabelsToProcess (ProcessBatch) as
  (
   select top 1 ProcessBatch
   from ShipLabels
   where (ProcessStatus = 'N' /* Not Yet Processed */) and
         (Status        = 'A' /* Active */) and
         (ProcessBatch <> 0) and
         (OrderId is not null)
   order by RecordId
  )
  /* Update shiplabels records to Inprogress and insert the updated records into temp table */
  update SL
  set ProcessStatus        = 'GI' /* Generation In Progress */,
      ProcessedInstance    = @vProcessInstance,
      @vNextBatchToProcess = SL.ProcessBatch,
      ModifiedDate         = current_timestamp
  output inserted.EntityKey, inserted.OrderId, inserted.Carrier, inserted.ProcessBatch
  into @ttShipLabelsToGenerate (EntityKey, OrderId, Carrier, ProcessBatch)
  from ShipLabels SL
    join LabelsToProcess LP on (SL.ProcessBatch = LP.ProcessBatch)
  where (SL.ProcessStatus  = 'N' /* Not Yet Processed */) and
        (SL.Status         = 'A' /* Active */) and
        (SL.OrderId is not null);

  /* If we do not send LogId then we are trying to find LogId by using Source Reference, so there is
     chance to have same Batch Number. Avoid this by prefixing the caller identitiy.
     This is true for all callers of pr_InterfaceLog_AddUpdate to have unique reference to send */
  select @vLabelsToGenerateCount = @@rowcount,
         @vSourceReference       = 'GenerateLabels_' + cast(@vNextBatchToProcess as varchar);

  /* If there are no batches to process then exit */
  if (@vNextBatchToProcess is null)
    goto ExitHandler;

  /* Update the Carrier with respect to the Order to send the details
     to Label generator if we don't have it */
  update TSL
  set Carrier = S.Carrier
  from @ttShipLabelsToGenerate TSL
    join OrderHeaders OH on (TSL.OrderId = OH.OrderId)
    join ShipVias      S on (S.ShipVia   = OH.ShipVia)
  where TSL.Carrier is null;

  /* for UPS and FedEx, we have multi package shipment implemented.
     Hence, we would be using to send PickTicket to use this feature in case of UPS/FedEx only */
  with CompleteOrders (OrderId, Carrier, NumLPNs) as
  (
   select OrderId, Carrier, count(*)
   from @ttShipLabelsToGenerate
   where Carrier in ('UPS', 'FEDEX') /* Excluded other carriers creation of Multi package shipment */
   group by OrderId, Carrier
  )
  insert into @ttShipLabelEntities(EntityType, OrderId, EntityKey, Carrier)
    select 'PickTicket', OH.OrderId, PickTicket, Carrier
    from CompleteOrders CO
      join OrderHeaders OH on (CO.OrderId = OH.OrderId) and (CO.NumLPNs = OH.NumLPNs)

  /* If the order is not added above, then add the individual LPNs for those orders */
  insert into @ttShipLabelEntities (EntityType, EntityKey, Carrier)
    select 'LPN', SLG.EntityKey, SLG.Carrier
    from @ttShipLabelsToGenerate SLG
      left outer join @ttShipLabelEntities SLE on (SLG.OrderId = SLE.OrderId)
    where (SLE.OrderId is null)

  /* Build output xml here */
  set @vXMLEntities = (select EntityType,
                              EntityKey,
                              Carrier
                       from @ttShipLabelEntities Entity
                       for xml raw('LabelsToGenerate'), elements);

  /* Create interface log */
  exec pr_InterfaceLog_AddUpdate @SourceSystem     = 'CIMS',
                                 @TargetSystem     = 'CIMS',
                                 @SourceReference  = @vSourceReference,
                                 @TransferType     = @vTransferType,
                                 @BusinessUnit     = @vBusinessUnit,
                                 @xmlData          = @XmlResult,
                                 @xmlDocHandle     = null,
                                 @RecordsProcessed = @vLabelsToGenerateCount,
                                 @LogId            = @vInterfaceLogId output,
                                 @RecordTypes      = @vRecordTypes output;

  select @vXMLResult = convert(varchar(Max), @vXMLEntities);

  select @vXMLResult = dbo.fn_XMLNode('Root',
                         dbo.fn_XMLNode('InterfaceLogInfo',
                         dbo.fn_XMLNode('InterfaceLogId', @vInterfaceLogId)) + @vXMLResult);

ExitHandler:

  select @xmlResult = convert(xml, @vXMLResult);
  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;
end catch
end /* pr_ShipLabel_GetLPNsToGenerateLabels */

Go
