/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/20  RV      pr_Packing_ClosePackage, pr_Packing_GetPrintList: Made changes to return the SPL notifications
  2022/03/02  RV      pr_Packing_ClosePackage: Made changes to insert the label and report printer into entities to print hash table (CIMSV3-1768)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_ClosePackage') is not null
  drop Procedure pr_Packing_ClosePackage;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_ClosePackage:
    This procedure is invoked from V3 UI Packing when user has finished packing
    of a carton.

    The procedure reads the inputs for the packed details, processes the respective updates,
    and returns all the details needed by UI for further processing

 Procedure returns two data sets

  a. ResultsMessages        xml format of #ResultMessages to show to the user
     CreateShipment         designating if the the Shipment has been created or not
                            based upon which UI would attempt to create the shipment
     APIOutboundRecorId:    If API is used to create shipment, but API is not being invoked by CLR,
                            then API outbound record is created and passed back to UI for processing it
     ProcessList            When the print list is ready with all necessary data, then it is returned
                            as an XML and this would be used to pass to PrintManager to do the actual
                            printing of the labels and documents
     ProcessPrintList       Y/N to indicate to UI if the print list is to be processed. Typically the
                            case when UI has to CreateShipment and then process the print list
     ProcessPrintListInput  Information of the list of entities to print by UI - used when
                            ProcessPrintList=Y. This, later, becomes the input to Packing_GetPrintList

  b. vwAPIOutboundTransactionsToProcess
                            The data record that is to be be used to invoke the API. Applicable only
                            when APIOutboundRecordId is not null and when CreateShipment = Y. It means
                            that UI should create the shipment using API

  For Small package carrier orders, shipment can be created in various ways
    1. by API using CLR     CreateShipment will be Created
    2. by API by UI         CreateShipment will be ToBeCreated and APIOutboundRecordId will be given
    3. by CIMSSI by UI      CreateShipment will be ToBeCreated but no APIOutboundRecordId
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_ClosePackage
  (@InputXML     TXML)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vMessage                TMessage,
          @vActivityLogId          TRecordId,
          @vDebug                  TFlags,  -- use 'SE,ETP' to display temp tables
          @vxmlInput               xml,

          @vEntity                 TEntity,
          @vCloseLPNOutputXML      TXML,
          @vxmlCloseLPNOutput      xml,
          @vCartonType             TCartonType,
          @vPalletId               TRecordId,
          @vFromLPNId              TRecordId,
          @vWeight                 TWeight,
          @vVolume                 TVolume,
          @vLPNContents            varchar(max),
          @vToLPN                  TLPN,
          @vReturnTrackingNo       TTrackingNo,

          @vAction                 TAction,
          @vOperation              TDescription,
          @vDeviceId               TDeviceId,
          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId,

          @vCreateShipment         TControlValue,
          @vCreateShipmentInput    TXML,
          @vAPIOutboundRecordId    TRecordId,

          @vPackedLPN              TLPN,
          @vPackedLPNId            TRecordId,

          @vOrderId                TRecordId,
          @vPickTicket             TPickTicket,
          @vOrderStatus            TStatus,
          @vShipVia                TShipvia,
          @vCarrier                TCarrier,
          @vIsSmallPackageCarrier  TFlags,

          @vLabelPrinterName       TName,
          @vReportPrinterName      TName,
          @vRulesDataXML           TXML,
          @vPrintListXML           TXML,
          @vPrintListOutputXML     TXML,
          @vGeneratePrintList      TFlags,
          @vGeneratePrintListInput TXML,
          @xmlResultMessages       TXML;

  declare @ttPackedDetails         TPackDetails,
          @ttSelectedEntities      TEntityValuesTable,
          @ttEntitiesToPrint       TEntitiesToPrint,
          @ttPrintList             TPrintList,
          @ttResultMessages        TResultMessagesTable,
          @ttResultData            TNameValuePairs;
begin /* pr_Packing_ClosePackage */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessagename    = null,
         @vCreateShipment = 'NotRequired';

  /* Extracting data elements from XML. */
  set @vxmlInput = convert(xml, @InputXML);

  /* Capture Information */ -- $$$ We should get OrderId in Data
  select @vEntity            = nullif(Record.Col.value('Entity[1]',                       'TEntity'), ''),
         @vAction            = Record.Col.value('Action[1]',                              'TAction'),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'),
         @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit'),
         @vUserId            = Record.Col.value('(SessionInfo/UserId)[1]',                'TUserId'),
         @vLabelPrinterName  = Record.Col.value('(SessionInfo/DeviceLabelPrinter)[1]',    'TName'),
         @vReportPrinterName = Record.Col.value('(SessionInfo/DeviceDocumentPrinter)[1]', 'TName'),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                    'TDescription'),
         @vDebug             = Record.Col.value('(Data/Debug)[1]',                        'TFlags'),
         @vCartonType        = Record.Col.value('(Data/CartonType)[1]',                   'TCartonType'),
         @vWeight            = Record.Col.value('(Data/PackageWeight)[1]',                'TWeight')
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Read the OrderId from within the Packed Detail */
  select @vOrderId = Record.Col.value('OrderId[1]', 'TRecordId')
  from @vxmlInput.nodes('/Root/Data/PackedDetails/PackedDetail[1]') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Log the input */
  exec pr_ActivityLog_AddMessage 'Packing', null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 @vMessage, @@ProcId, @InputXML, @vBusinessUnit, @vUserId,
                                 @ActivityLogId = @vActivityLogId output;

  /* Create temp tables */
  select * into #PackDetails     from @ttPackedDetails;
  select * into #ResultMessages  from @ttResultMessages;
  select * into #ResultData      from @ttResultData;
  select * into #EntitiesToPrint from @ttEntitiesToPrint;
  select * into #PrintList       from @ttPrintList;

  /* Loads #PackedDetails (SKU, Qty etc.) from XML sent from UI */
  exec pr_Packing_LoadPackDetails @vxmlInput, @vOrderId, @vBusinessUnit, @vUserId;

  select @vAction = 'CloseLPN'; -- V2 Action Name

  exec pr_Packing_CloseLPN_V3 @vCartonType,
                              @vPalletId,
                              null,  -- @FromLPNId
                              @vOrderId,
                              @vWeight,
                              @vVolume,
                              null,  -- LPNContents, V3 uses #PackDetails to pass that info
                              null,  -- @vToLPN
                              @vReturnTrackingNo,
                              @vDeviceId /* Pack Station */,
                              @vAction,
                              @vBusinessUnit,
                              @vUserId,
                              @vCloseLPNOutputXML output;

  /* parse the OutputXML for following

     1. Process OutboundAPITransaction record for new shipment, if create shipment is Y and an API is defined for Carrier+ShipVia combination
     2. Generate Print List
     3. return Success or Error Message from OutputXML
   */
  --select @vCloseLPNOutputXML CloseLPNOutputXML;
  set @vxmlCloseLPNOutput = convert(xml, @vCloseLPNOutputXML);

  /* Get Packed LPN info */
  select @vPackedLPNId = Record.Col.value('LPNId[1]',  'TRecordId'),
         @vPackedLPN   = Record.Col.value('LPN[1]',    'TLPN')
  from @vxmlCloseLPNOutput.nodes('/PackingCloseLPNInfo/LPNInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlCloseLPNOutput = null ));

  /* Get Order info */
  select @vShipVia     = ShipVia,
         @vPickTicket  = PickTicket,
         @vOrderStatus = Status
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get Carrier Info */
  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @vBusinessUnit);

  /* If it is a small package carrier, invoke procedure to create shipment.
     Based upon the rules one of these may happen
     a. a shipment may be created and tracking no generated as well using CLR
     b. API outbound request created and recordid returned for UI to process it
     c. shipment is not created but requires UI to do it
     d. shipment is not required at the moment - may be because order is not packed yet */
  if (@vIsSmallPackageCarrier = 'Y' /* Yes */)
    exec pr_Packing_CreateShipment @vOrderId, @vPackedLPNId, 'ClosePackage', @vBusinessUnit, @vUserId,
                                   @vAPIOutboundRecordId output, @vCreateShipment output, @vCreateShipmentInput output;

  /* Load the Entities to be printed */
  insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, OrderId, PickTicket, LabelPrinterName, ReportPrinterName, RecordId)
    select 'LPN', @vPackedLPNId, @vPackedLPN, @vOrderId, @vPickTicket, @vLabelPrinterName, @vReportPrinterName, 1
    union all
    select 'Order', @vOrderId, @vPickTicket, @vOrderId, @vPickTicket, @vLabelPrinterName, @vReportPrinterName, 2;

  /* Based upon rules and the entities we could either send the PrintList to Print or
     send the EntitiesToPrint to generate the print list later */
  exec pr_Packing_BuildPrintList @InputXML, @vCreateShipment, @vPrintListOutputXML output, @vGeneratePrintList output, @vGeneratePrintListInput output;

  /* Insert the notifications into #ResultMessages */
  exec pr_Printing_GetSPLNotifications 'No' /* Build Messages */, @vBusinessUnit, @vUserId;

  if (exists(select * from #ResultMessages))
    exec pr_Entities_BuildMessageResults null, null, @xmlResultMessages output;

  /* Create Shipment: Created     - already created using CLR,
                      ToBeCreated - need to be created by UI (using API or CIMSSI)
                      NotRequired - not required */
  select @xmlResultMessages ResultMessages,
         @vCreateShipment CreateShipment,
         @vCreateShipmentInput CreateShipmentInput, -- Only one of these two will be present for shipment creation
         @vAPIOutboundRecordId APIOutboundRecordId, -- Only one of these two will be present for shipment creation
         @vGeneratePrintList GeneratePrintList,
         @vGeneratePrintListInput GeneratePrintListInput,
         @vPrintListOutputXML PrintList;

  /* This statement will return the Outbound Transaction Record to be processed by caller
     If the Record is already processed via API Caller, this will not return any records */
  select * from vwAPIOutboundTransactionsToProcess where RecordId = @vAPIOutboundRecordId;

  /* Log success response */
  exec pr_ActivityLog_AddMessage 'Packing', null /* Entity Id */, null /* EntityKey */, @vEntity,
                                 @vMessage, @@ProcId, @xmlResultMessages, @vBusinessUnit, @vUserId,
                                 @ActivityLogId = @vActivityLogId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_ClosePackage */

Go
