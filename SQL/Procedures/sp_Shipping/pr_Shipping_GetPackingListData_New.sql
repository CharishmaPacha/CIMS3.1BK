/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/22  RV      pr_Shipping_GetPackingListData_New: Made changes to return logo node even logo is not exists (BK-610)
  2021/08/11  RV      pr_Shipping_GetPackingListData_New: Made changes control value get from Packing list category (BK-484)
  2021/07/28  RV      pr_Shipping_GetPackingListData_New: Made changes to show the component lines based upon the rules and control (OB2-1960)
  2020/07/10  MS      pr_Shipping_GetPackingListData_New, pr_Shipping_PLGetShipLabelsXML: Changes to generate labels based on EntityType (S2GCA-1178)
  2020/06/13  MS      pr_Shipping_GetPackingListData_New, pr_Shipping_GetPackingListDetails,
  2020/06/02  MS      pr_Shipping_GetPackingListData_New: Setup Default Options to generate info (HA-597)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetPackingListData_New') is not null
  drop Procedure pr_Shipping_GetPackingListData_New;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetPackingListData_New: New Procedure to return the PackingList Info

  Note: Format of input
  @DocToPrintXML = <DocToPrint>
                     <Entity>PickTicket</Entity>
                     <EntityId></EntityId>
                     <EntityKey></EntityKey>
                     <EntityId></EntityId>
                     <DocType>PL</DocType>
                     <DocSubType>ORD</DocSubType>
                     <DocumentFormat>Packinglist_Generic</DocumentFormat>
                  </DocToPrint>
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetPackingListData_New
  (@DocToPrintXML   TXML,
   @Options         XML          = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @PLResultXML     TXML         = null output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TInteger,
          @vDebug                      TFlags = null,

          @PLHeaderxml                 TXML,
          @PLDetailsxml                TXML,

          @ShipLabelxml                TXML,
          @ReturnShipLabelxml          TXML,
          @CILabelXML                  TXML,
          @DummyDetailsxml             TXML,
          @xmlData                     TXML,
          @vReportFormat               TName,
          @vDocType                    TTypeCode,
          @vPackingListType            TTypeCode,
          @vRuleSetName                TName,
          @vLogo                       TXML,
          @vLogoRecordId               TRecordId,
          @vRemainingPageNumRows       TInteger,
          @vStartingPageNumber         TInteger,
          @vTotalPages                 TInteger,
          @vEntityType                 TTypeCode,
          @vEntityId                   TRecordId,
          @vEntityKey                  TEntity,
          @vEntity                     TTypeCode,
          @Reportsxml                  TXML,
          @OptionsXML                  TXML,
          @Resultxml                   TXML,

          @Commentsxml                 TXML,
          @TrackingNo                  TTrackingNo,
          @vOrderId                    TRecordId,
          @vPickTicket                 TPickTicket,
          @vOrderStatus                TStatus,
          @vCustPO                     TCustPO,
          @vShipToId                   TCustomerId,
          @vShipToState                TName,
          @vShipFrom                   TShipFrom,
          @vWaveType                   TTypeCode,
          @vLPNId                      TRecordId,
          @vLPN                        TLPN,
          @vPackageSeqNo               TInteger,
          @vSource                     TName,
          @vSourceSystem               TName,
          @vRequestInfo                TDescription,

          @vComments                   TVarchar,
          @vOwnership                  TTypecode,
          @vWarehouse                  TWarehouse,

          @TotalUnitsAssigned          TQuantity,
          @OrderTaxAmount              TMoney,
          @OrderSubTotal               TMoney,
          @vOrderTotal                 TMoney,
          @vTotalWeight                TWeight,
          @vTotalVolume                TVolume,
          @vUnitsPerCarton             TInteger,
          @vUCCount                    TCount,
          @vDummyRecordsCount          TCount,
          @CanPrintPackingList         TFlag,
          @vAccount                    TAccount,
          @vAdditionalPLInfo1          TVarchar,
          @vNumPackedDetails           TInteger,
          @vShowComponentSKUsLines     TFlag,
          @vCarriersIntegration        TControlValue,
          @vWaveTypesToGetODsForLPNPL  TControlValue,

          @vShipVia                    TShipVia,
          @vCarrier                    TCarrier,
          @vIsSmallPackageCarrier      TFlag,
          @vCarrierInterface           TCarrierInterface,

          @vxmlDocToPrint              XML,
          @vStaticDocsEntity           TTypeCode,
          @xmlStaticDocsToPrint        TXML,
          @StaticDocList1              TXML,
          @StaticDocList2              TXML,

          @vCreateShipment             TFlag,
          @vLoadId                     TRecordId,

          @vPrintJobId                 TRecordId,
          @vPrintListRecordId          TRecordId;

  declare @ttMarkers   TMarkers;

begin /* pr_Shipping_GetPackingListData_New */
  select @vStaticDocsEntity = null,
         @vReturnCode       = 0,
         @vMessagename      = null,
         @vComments         = '',
         @vRecordId         = 0;

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Shipping_GetPackingListData_New_Start', @@ProcId;

  /* Exit if the input are null */
  if (@DocToPrintXML is null)
    goto ExitHandler;

  select @vxmlDocToPrint = convert(xml, @DocToPrintXML);

  /* Get the Details to print the Document for the Given Entity */
  select @vEntity            = Record.Col.value('Entity[1]',             'TEntity'),
         @vEntityId          = Record.Col.value('EntityId[1]',           'TRecordId'),
         @vEntityKey         = Record.Col.value('EntityKey[1]',          'TEntityKey'),
         @vDocType           = Record.Col.value('DocType[1]',            'TTypeCode'),
         @vPackingListType   = Record.Col.value('DocSubType[1]',         'TTypeCode'),
         @vReportFormat      = Record.Col.value('DocumentFormat[1]',     'TName'),
         @vPrintListRecordId = Record.Col.value('PrintListRecordId[1]',  'TRecordId'),
         @vPrintJobId        = Record.Col.value('PrintJobId[1]',         'TRecordId')
  from @vxmlDocToPrint.nodes('/DocToPrint') as Record(Col);

  /* Setup StartingPageNumber based on ReportFormat*/
  set @vStartingPageNumber = case when (@vReportFormat like '%_AP%') then 2 else 1 end;

  /* Get the Source from the Options input xml. RequestInfo would be Data, Labels or Logo */
  select @vSource  = nullif(Record.Col.value('Source[1]',       'TName'), '')
  from @Options.nodes('/Options') as Record(Col);

  /* Setup Default Options for RequestInfo */
  set @vRequestInfo = coalesce(@vRequestInfo, 'SL,CL,SPL,Logo,Labels')

  /* Get the Static Document to print */
  select @vStaticDocsEntity = @vPackingListType;

  /* Get the info when the Entity from Shipping Docs is PickTicket */
  if (@vEntity = 'Order')
    select @vOrderId = @vEntityId;

  /* Get the info when the Entity from ShippingDocs is LPN */
  if (@vEntity = 'LPN')
    select @vOrderId      = L.OrderId,
           @vLPNId        = L.LPNId,
           @vLPN          = L.LPN,
           @vPackageSeqNo = L.PackageSeqNo
    from LPNs L
    where (LPNId = @vEntityId);

  /* get carrier integration status */
  select @vCarriersIntegration    = dbo.fn_Controls_GetAsString('ShipLPNOnPack', 'CarriersIntegration','N' /* No */, @BusinessUnit, 'CIMSAgent');
  select @vShowComponentSKUsLines = dbo.fn_Controls_GetAsBoolean('PackingList', 'ShowComponentSKUsLines', 'N', @BusinessUnit, @UserId);

  select @vOrderStatus  = OH.Status,
         @vCustPO       = OH.CustPO,
         @vAccount      = OH.Account,
         @vWaveType     = W.WaveType,
         @vOwnership    = OH.Ownership,
         @vShipVia      = OH.ShipVia,
         @vShipFrom     = OH.ShipFrom,
         @vShipToId     = OH.ShipToId,
         @vWarehouse    = OH.Warehouse,
         @vSourceSystem = OH.SourceSystem
  from OrderHeaders OH
    left outer join Waves W on (OH.PickBatchId = W.WaveId)
  where (OrderId = @vOrderId);

  /* Get the ShipToState */
  select @vShipToState = State
  from Contacts
  where (ContactRefId = @vShipToId) and (BusinessUnit = @BusinessUnit);

  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

  /* There are multiple formats of packing lists to be printed, primarily based
     upon the Carrier. We would use it as rule driven
     To do so - we need to generate an xml and get the packing list by passing xml to the procedure */
  select @xmlData = dbo.fn_XMLNode('RootNode',
                      dbo.fn_XMLNode('PackingListType',      @vPackingListType) + /* @PackingListType value might be changes to ORDWithLDs
                                                                                    in which it is not used to evaluate static doc to print */
                      dbo.fn_XMLNode('CarriersIntegration',  @vCarriersIntegration) +
                      dbo.fn_XMLNode('LPN',                  @vLPN) +
                      dbo.fn_XMLNode('LPNId',                @vLPNId) +
                      dbo.fn_XMLNode('PackageSeqNo',         @vPackageSeqNo) +
                      dbo.fn_XMLNode('PickTicket',           @vPickTicket) +
                      dbo.fn_XMLNode('OrderId',              @vOrderId) +
                      dbo.fn_XMLNode('OrderStatus',          @vOrderStatus) +
                      dbo.fn_XMLNode('LoadId',               @vLoadId)      +
                      dbo.fn_XMLNode('ShipVia',              @vShipVia) +
                      dbo.fn_XMLNode('Carrier',              @vCarrier) +
                      dbo.fn_XMLNode('IsSmallPackageCarrier',
                                                             @vIsSmallPackageCarrier) +
                      dbo.fn_XMLNode('CarrierInterface',     '') +
                      dbo.fn_XMLNode('Entity',               'PickTicket') +
                      dbo.fn_XMLNode('WaveType',             @vWaveType) +
                      dbo.fn_XMLNode('CustPO',               @vCustPO) +
                      dbo.fn_XMLNode('Account',              @vAccount) +
                      dbo.fn_XMLNode('ShipToId',             @vShipToId) +
                      dbo.fn_XMLNode('ShipFrom',             @vShipFrom) +
                      dbo.fn_XMLNode('ShipToState',          @vShipToState) +
                      dbo.fn_XMLNode('ShowComponentSKUsLines',
                                                             @vShowComponentSKUsLines) +
                      dbo.fn_XMLNode('SourceSystem',         @vSourceSystem) +
                      dbo.fn_XMLNode('Source',               @vSource) + /* Consider the source of request to determine which
                                                                            packing list to print using the rules */
                      dbo.fn_XMLNode('BusinessUnit',         @BusinessUnit) +
                      dbo.fn_XMLNode('Ownership',            @vOwnership) +
                      dbo.fn_XMLNode('DocumentType',         @vDocType) + /* @DocType will be holding the values like PL, SL, SPL,.. */
                      dbo.fn_XMLNode('StaticDocumentEntity', @vStaticDocsEntity)); /* StaticDocumentEntity is introduced as @PackingListType and @DocType
                                                                                      may have inappropriate data which cant be used to print static doc list.
                                                                                      Will make changes appropriately in Rules_DocumentLists */

  -- /* Get Carrier Interface */
  -- exec pr_RuleSets_Evaluate 'CarrierInterface', @xmlData output, @vCarrierInterface output, @StuffResult = 'Y';
  --
  -- /* Get ShipmentType to create the Shipments */
  -- exec pr_RuleSets_Evaluate 'CreateSPGShipment', @xmlData, @vCreateShipment output;

  /* Get the RuleSetname with respect to the DocType, If the document type if null then this proc call is for PL documents to print */
  if (coalesce(nullif(@vDocType, ''), 'PL') = 'PL')
    set @vRuleSetName = 'PackingList';
  else
    set @vRuleSetName = @vDocType + '_GetFormat';

  /* Get the packing list format to print if one is not specified */
  if (@vReportFormat is null)
    exec pr_RuleSets_Evaluate @vRuleSetName, @xmlData, @vReportFormat output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetPackingListHeader_Start', @@ProcId;

  /* Get the Packing List Header info */
  exec pr_Shipping_GetPackingListHeader @vLoadId, @vOrderId, @vLPNId, @vReportFormat, @vPackingListType, @xmlData, @PLHeaderxml output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetPackingListDetails_Start', @@ProcId;

  /* Get the Packing List Details info */
  exec pr_Shipping_GetPackingListDetails @vLoadId, @vOrderId, @vLPNId, @vReportFormat, @vPackingListType, @xmlData,
                                         @PLDetailsxml output, @vTotalPages output, @vNumPackedDetails output, @BusinessUnit;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'PLGetShipLabelsXML_Start', @@ProcId;

  /* Get the Packing List ShipLabel data */
  if charindex('Labels', @vRequestInfo) > 0
    exec pr_Shipping_PLGetShipLabelsXML @vOrderId, @vLPN, @BusinessUnit, @ShipLabelxml output, @ReturnShipLabelXML output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'PLGetComments_Start', @@ProcId;

  /* Build the comment xml */
  exec pr_Shipping_PLGetCommentsXML @xmlData, @Commentsxml output

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetPackingListDummyRecordsCount_Start', @@ProcId;

  /* Get the Dummy rows count to print on report */
  select @vDummyRecordsCount = dbo.fn_Shipping_GetPackingListDummyRecordsCount (@vNumPackedDetails, @vReportFormat , 'Y' /* Yes */, @BusinessUnit),
         @DummyDetailsxml = '';

  /* Build the Dummy details with rows through loop */
  while (@vDummyRecordsCount > 0)
    begin
       select @DummyDetailsxml    = coalesce(@DummyDetailsxml, '') +
                                    dbo.fn_XMLNode('DummyDetails',
                                    dbo.fn_XMLNode('DummyColumn1', '')),
              @vDummyRecordsCount = @vDummyRecordsCount -1;
    end

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetReportLogo_Start', @@ProcId;

  /* Get logo from the ContentImages with respect to the ShipFrom and load dynamically with the Logo data.*/
  if charindex('Logo', @vRequestInfo) > 0
    begin
      exec pr_RuleSets_Evaluate 'ReportLogo', @xmlData, @vLogoRecordId output;

      /* Get logo to print on the PL */
      select @vLogo = (select top 1 Image Logo
                       from ContentImages
                       where (RecordId = @vLogoRecordId)
                       for xml path (''));
    end

  /* Get the Reports info */
  set @Reportsxml = dbo.fn_XMLNode('REPORTS',
                      coalesce(@vLogo, dbo.fn_XMLNode('Logo', null)) +
                      dbo.fn_XMLNode('Report',             @vReportFormat) +
                      dbo.fn_XMLNode('TotalPages',         @vTotalPages) +
                      dbo.fn_XMLNode('StartingPageNumber', @vStartingPageNumber) +
                      dbo.fn_XMLNode('PrintJobId',         @vPrintJobId) +
                      dbo.fn_XMLNode('PrintJobIndex',      '0') + /* for future use*/
                      dbo.fn_XMLNode('PrintJobNumRecords', '0')); /* for future use*/

  set @OptionsXML = dbo.fn_XMLNode('OPTIONS',
                      dbo.fn_XMLNode('CarrierInterface', @vCarrierInterface) +
                      dbo.fn_XMLNode('ShipmentType',     @vCreateShipment));

  /* Setup Resultxml */
  select @Resultxml = dbo.fn_XMLNode('PACKINGLIST',
                        coalesce(@PLHeaderxml,        '') +
                        coalesce(@PLDetailsxml,       '') +
                        coalesce(@Commentsxml,        '') +
                        coalesce(@ShipLabelxml,       '') +
                        coalesce(@ReturnShipLabelxml, '') +
                        coalesce(@CILabelXML,         '') +
                        coalesce(@DummyDetailsxml,    '') +
                        coalesce(@Reportsxml,         '') +
                        coalesce(@OptionsXML,         ''));

  /* Packing List output xml */
  select @PLResultXML = dbo.fn_XMLNode('PACKINGLISTS', @Resultxml);

  if (charindex('D', @vDebug) > 0) select @PLResultXML as result;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Shipping_GetPackingListData_New_End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'GetPackingListData', null, null, 'Shipping_GetPackingListData', @@ProcId, 'Markers_GetPackingListData';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetPackingListData_New */

Go
