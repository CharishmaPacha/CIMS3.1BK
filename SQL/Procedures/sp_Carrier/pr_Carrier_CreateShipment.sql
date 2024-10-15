/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/09  TK      Changes made to ignore the existing APIOT records with 'ReadyToSend' status (SRIV3-530)
  2024/04/12  VS      pr_Carrier_CreateShipment: Update the OH.ShipVia in ShipLabels table (CIMSV3-3475)
  2024/03/30  RV      pr_Carrier_CreateShipment: Made changes to not generate a label again if the carrier label has already been generated.
                        If an error occurs while processing the records (MBW-877)
  2024/02/24  VS      pr_Carrier_CreateShipment: Update the CIMS Carrier Validations in ShipLabels table (CIMSV3-3437)
  2024/02/07  MS      pr_Carrier_CreateShipment: Changes to defer the label generation (JLFL-895)
  2023/05/25  VS      pr_Carrier_CreateShipment, pr_Carrier_GetShipmentData: Validate Carrier validations in Create Shipment (CIMSV3-2807)
  2023/04/25  RV      pr_Carrier_CreateShipment: Made changes to insert the Total packages count (JLCA-777)
  2023/03/23  VS      pr_Carrier_CreateShipment: Made changes to add CartonType, FreightTerms, BillToAccount (JLFL-297)
  2023/03/20  RV      pr_Carrier_CreateShipment: Made changes to do not insert the record with transaction status Inprocess (JLCA-560)
  2023/01/13  RV      pr_Carrier_CreateShipment: Made changes to add Notifications column (OBV3-1613)
  2022/11/02  TK      pr_Carrier_CreateShipment: Update package dimensions after InsertRequired is updated (OBV3-1379)
  2022/10/20  AY      pr_Carrier_CreateShipment: Change to use APITransactionStatus as ProcessStatus is used for ShipLabel (CIMSV3-1780)
  2022/03/15  AY/RV   pr_Carrier_CreateShipment: Made changes to process createshipment with different integration and generation methods (FBV3-921)
  2022/03/11  SV      pr_Carrier_CreateShipment: Changes as per the changes at Rules_ShipLabels (FBV3-921)
  2022/02/18  VS      pr_Carrier_CreateShipment: Added ProcessStatus for APIOutboundprocess (CIMSV3-1780)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_CreateShipment') is not null
  drop Procedure pr_Carrier_CreateShipment;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_CreateShipment: Given the list of LPNs #ShipLabelsToInsert
    that are being considered for Carrier labels, this procedure evaluates using
    rules if we are ready to do so, batches those and inserts into ShipLabels table.
    Using rules it also determines the shipment type and the integration method
    i.e. CIMSSI, API. If API, it determines if it is to be processed immediately
    using CLR or a job
    Finally, if it API and to be processed immediately, it processes them as well
    and generates the labels.

     Procedure does the following:
     Delete the records from hash table if it is not a small package carrier, already have a valid shipment.
     Validates the records using rules and deletes invalid records.
     Determine the carrier interface, shipment type and API workflow and update on the hash table.
     Update the package dimensions on the hash table and insert into ship labels if already not exists.
     Batches the labels if shipment create through CIMSSI
     Insert the records into APIOutboundTransactions to create shipment through API.
     Create shipment if the APIWorkflow is CLR.

  Inputs:
    #ShipLabelsToInsert
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_CreateShipment
  (@Module       TName,
   @Operation    TOperation,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,

          @xmlRulesData          TXML;

  declare @ttAPITransactionsToProcess TEntityValuesTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Exit if no data to process */
  if (object_id('tempdb..#ShipLabelsToInsert') is null) or (not exists(select * from #ShipLabelsToInsert))
    return;

  /* Create temp table if not exists */
  if (object_id('tempdb..#APITransactionsToProcess') is null) select * into #APITransactionsToProcess from @ttAPITransactionsToProcess;

  /* Build rules data xml. Later on validations are done against #ShipLabelsToinsert
     Similar validations may be done during WaveRelease as well to prevent releasing of
     Orders that have missing data etc. But some validations could be skipped at Wave
     Release but may not be when we are generating labels. Hence we use MessageNamePrefix
     to determine if the validation is an Error or a Warning */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Module',            @Module) +
                           dbo.fn_XMLNode('Operation',         @Operation) +
                           dbo.fn_XMLNode('BusinessUnit',      @BusinessUnit) +
                           dbo.fn_XMLNode('UserId',            @UserId) +
                           dbo.fn_XMLNode('MessageNamePrefix', 'ShipLabel') +
                           dbo.fn_XMLNode('Version',           'V3')); -- CreateSPGShipment ruleset, processed below, expects this

  /* Remove Entities from temp table if not small package carriers */
  delete SLI from #ShipLabelsToInsert SLI where (SLI.IsSmallPackageCarrier = 'N');

  /* Ignore the records which already have a valid tracking no in ShipLabels */
  update ttSI
  set ttSI.InsertRequired = iif (SL.IsValidTrackingNo = 'Y', 'Ignore', 'Evaluate')
  from #ShipLabelsToInsert ttSI
    join ShipLabels SL on (ttSI.EntityKey    = SL.EntityKey) and
                          (ttSI.BusinessUnit = SL.BusinessUnit) and
                          (SL.Status         = 'A');

  /* Below rules execution will validate the orders to generate the labels */
  exec pr_RuleSets_ExecuteAllRules 'Carrier_Validations', @xmlRulesData, @BusinessUnit;

  /* Evaluate rules to determine if we are ready to create shipment and to identify the interface to use
    #ShipLabelstoInsert.InsertRequired is updated to Y to indicate we are ready to create shipment */
  exec pr_RuleSets_ExecuteAllRules 'ShipLabels_EvaluateRequirement', @xmlRulesData, @BusinessUnit;

  /* Update PackageDimensions on temp table */
  exec pr_ShipLabels_UpdatePackageDimensions @BusinessUnit;

  /* Ignore the records which is already inserted and active in ShipLabels */
  update ttSI
  set ttSI.InsertRequired = iif (SL.RecordId is not null, 'Exists', ttSI.InsertRequired)
  from #ShipLabelsToInsert ttSI
    join ShipLabels SL on (ttSI.EntityKey    = SL.EntityKey) and
                          (ttSI.BusinessUnit = SL.BusinessUnit) and
                          (SL.Status         = 'A');

  /* Update the CartonType, FreightTerms and BillToAccount */
  Update ttSI
  set ttSI.CartonType    = L.CartonType,
      ttSI.FreightTerms  = OH.FreightTerms,
      ttSI.BillToAccount = OH.BillToAccount,
      ttSI.ShipVia       = OH.ShipVia
  from #ShipLabelsToInsert ttSI
    join LPNs L on (ttSI.EntityKey = L.LPN) and (ttSI.BusinessUnit = L.BusinessUnit)
    join OrderHeaders OH on (OH.OrderId = L.OrderId);

  /* Batch the shiplabels to process through CIMSSI */
  exec pr_Carrier_BatchShipLabels @Module, @Operation, @BusinessUnit, @UserId;

  /* Insert required labels into ShipLabels table */
  insert into ShipLabels (EntityId, EntityType, EntityKey, CartonType, ProcessStatus, PackageLength, PackageWidth, PackageHeight,
                          PackageWeight, PackageVolume, OrderId, PickTicket, TotalPackages, TaskId, WaveId, WaveNo, LabelType, TrackingNo,
                          FreightTerms, BillToAccount, RequestedShipVia, ShipVia, Carrier, CarrierInterface, ProcessBatch, Notifications, BusinessUnit, CreatedBy)
    select EntityId, EntityType, EntityKey, CartonType, ProcessStatus, PackageLength, PackageWidth, PackageHeight,
           PackageWeight, PackageVolume, OrderId, PickTicket, TotalPackages, TaskId, WaveId, WaveNo, LabelType, '', /* TrackingNo does not allow null */
           FreightTerms, BillToAccount, RequestedShipVia, ShipVia, Carrier, CarrierInterface, coalesce(ProcessBatch, '0'), Notifications, BusinessUnit, CreatedBy
    from #ShipLabelsToInsert
    where (InsertRequired = 'Yes' /* Yes */);

  /* Update the CIMS Validations in ShipLabels table */
  Update SL
  set Notifications = 'CIMS:' + tSL.Notifications,
      ProcessStatus = 'LGE'
  from ShipLabels SL
    join #ShipLabelsToInsert tSL on tSL.EntityId = SL.EntityId
  where tSL.Notifications is not null

  /* Check if API integration needs to be used for Shipment Creation. If APIWorkflow is not null
     then we assume it is some kind of API processing and so if there aren't any records
     which are to be processed via API, then exit.

     If there are no records to be processed through CIMSAPI or CLR, then exit from inserting
     data into APIOutboundTransactions */
  if (not exists (select * from #ShipLabelsToInsert where (IntegrationMethod = 'API' /* Process through API */)))
    return;

  /* Do not insert if the record already exist for order entity, which is not yet processed */
  delete ttSI
  from #ShipLabelsToInsert ttSI
    join APIOutboundTransactions AOT on (AOT.EntityId = ttSI.OrderId) and (AOT.EntityType = 'Order') and (AOT.TransactionStatus in ('Initial', 'ReadyToSend', 'PrepareAndSend', 'Inprocess')) and
                                        (AOT.IntegrationName = ttSI.CarrierInterface) and (AOT.MessageType = coalesce(ttSI.MessageType, 'ShipmentRequest'))
  where (ttSI.IntegrationMethod = 'API' /* Process through API */) and (ShipmentType = 'M' /* Multi package */)

  /* For the Order entity, do not generate a label again if the carrier label has already been generated. If an error occurs while processing the records */
  delete ttSI
  from #ShipLabelsToInsert ttSI
    join APIOutboundTransactions AOT on (AOT.EntityId = ttSI.OrderId) and (AOT.EntityType = 'Order') and (AOT.TransactionStatus in ('Success')) and (AOT.ProcessStatus in ('Initial', 'Fail')) and
                                        (AOT.IntegrationName = ttSI.CarrierInterface) and (AOT.MessageType = coalesce(ttSI.MessageType, 'ShipmentRequest'))
  where (ttSI.IntegrationMethod = 'API' /* Process through API */) and (ShipmentType = 'M' /* Multi package */)

  /* Do not insert if the record already exist for LPN entity, which is not yet processed */
  delete ttSI
  from #ShipLabelsToInsert ttSI
    join APIOutboundTransactions AOT on (AOT.EntityId = ttSI.EntityId) and (AOT.EntityType = 'LPN') and (AOT.TransactionStatus in ('Initial', 'ReadyToSend', 'PrepareAndSend', 'Inprocess')) and
                                        (AOT.IntegrationName = ttSI.CarrierInterface) and (AOT.MessageType = coalesce(ttSI.MessageType, 'ShipmentRequest'))
  where (ttSI.IntegrationMethod = 'API') and (ShipmentType = 'S' /* Single package */);

  /* For the LPN entity, do not generate a label again if the carrier label has already been generated. If an error occurs while processing the records */
  delete ttSI
  from #ShipLabelsToInsert ttSI
    join APIOutboundTransactions AOT on (AOT.EntityId = ttSI.EntityId) and (AOT.EntityType = 'LPN') and (AOT.TransactionStatus in ('Success')) and (AOT.ProcessStatus in ('Initial', 'Fail')) and
                                        (AOT.IntegrationName = ttSI.CarrierInterface) and (AOT.MessageType = coalesce(ttSI.MessageType, 'ShipmentRequest'))
  where (ttSI.IntegrationMethod = 'API') and (ShipmentType = 'S' /* Single package */);

  /* Add a record to APIOutboundTransactions table to create a new shipment using carrier API */
  /* For UPS & FEDEX carriers we will create shipment request for every order and for other carriers
     we will create for each LPN */
  insert into APIOutboundTransactions (IntegrationName, TransactionStatus, MessageType, EntityType, EntityId, EntityKey, APIWorkFlow, BusinessUnit, CreatedBy)
    -- save the inserted records to process thru CLR if required
    output inserted.RecordId, inserted.APIWorkFlow, inserted.RecordId
    into #APITransactionsToProcess (EntityId, EntityType, RecordId)
    -- select the records to be processed
    select distinct CarrierInterface, APITransactionStatus, coalesce(MessageType, 'ShipmentRequest'), 'Order', OrderId, PickTicket, GenerationMethod, @BusinessUnit, @UserId
    from #ShipLabelsToInsert
    where (IntegrationMethod = 'API' /* Process through API */) and (ShipmentType = 'M' /* Multi package */)
    union all
    select distinct CarrierInterface, APITransactionStatus, coalesce(MessageType, 'ShipmentRequest'), 'LPN', EntityId, EntityKey, GenerationMethod, @BusinessUnit, @UserId
    from #ShipLabelsToInsert
    where (IntegrationMethod = 'API' /* Process through API */) and (ShipmentType = 'S' /* Single package */);

  /* process API outbound transaction through CLR if required. Eliminate non CLR records */
  delete from #APITransactionsToProcess where EntityType <> 'CLR';
  exec pr_API_OutboundCLRProcessor null /* APIRecordId */, @Operation, @BusinessUnit, @UserId;

end /* pr_Carrier_CreateShipment */

Go
