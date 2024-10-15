/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/07/29  TD      Variable Mapping Corrections (OBV3-2107)
  2024/07/12  RV      Made changes to update the ship date with the current date when the ship date is earlier than the current date (MBW-944)
  2024/06/06  RV      Cleaned up insurance related code (CIMSV3-3659)
  2024/05/06  RV      Update the PackageWeightOz on CarrierPackageInfo (CIMSV3-1781)
  2024/04/24  RV      Made changes to calculate the Insured value based upon the control value (CIMSV3-3571)
  2024/04/15  RV      Bug fixed to set the contact type as 'B' when the Bill to address is present (OBV3-2049)
  2024/02/17  RV      pr_Carrier_GetShipmentData: Added LabelReference1Type-LabelReference5Type and LabelReference1Value-LabelReference5Value (CIMSV3-3395)
  2024/01/03  TK      pr_Carrier_GetShipmentData: Remove special characters in CustPO while generating label (MBW-677)
  2023/12/27  SRP     pr_Carrier_GetShipmentData : Back ported from onsite prod (MBW-674)
  2023/12/22  VS      pr_Carrier_GetShipmentData, pr_Carrier_UpdateCartonDetails: Made changes to improve the Performance (FBV3-1660)
  2023/12/22  MS      pr_Carrier_GetShipmentData: Changes to change futureshipdate if the order missed schedule (MBW-473)
  2023/12/08  VS      pr_Carrier_GetShipmentData, pr_Carrier_UpdateCartonDetails: Made changes to improve the Performance (FBV3-1660)
  2023/12/04  VS      pr_Carrier_GetShipmentData: Made changes to get the References (FBV3-1660)
  2023/09/08  AY      pr_Carrier_GetShipmentData: Save special services in CarrierShipmentData (MBW-464)
  2023/08/10  RV      pr_Carrier_GetShipmentData, pr_Carrier_Response_SaveShipmentData: Made changes populate the hash table instead of xml (JLFL-320)
  2023/08/22  RV      pr_Carrier_GetShipmentData: Populated the ReceiverTaxId and PickTicket (CIMSV3-2760)
  2023/07/27  NB      pr_Carrier_GetShipmentData changes to pass in LPNCartonType to get packaging type and carton details, instead
  2023/05/25  VS      pr_Carrier_CreateShipment, pr_Carrier_GetShipmentData: Validate Carrier validations in Create Shipment (CIMSV3-2807)
  2023/04/13  VS      pr_Carrier_GetShipmentData: Made changes to validate the Carrier rules (OBV3-1750)
  2023/03/09  VS      pr_Carrier_GetShipmentData: Do not Validate Shipment in API Message Building (OBV3-1746)
  2023/01/06  VS      pr_Carrier_GetShipmentData: Get the BillToAddress info (OBV3-1652)
  2022/12/28  VS      pr_Carrier_GetShipmentData: Get the CommercialInvoice details (OBV3-1465)
  2022/12/27  VS      pr_Carrier_GetShipmentData: Get the Brokerinfo based on Country (OBV3-1532)
  2022/12/21  VS      pr_Carrier_GetShipmentData: Made changes to get the Commercial Invoice details (OBV3-1532)
  2022/11/17  AY      pr_Carrier_GetShipmentData: Initial revision (OBV3-1447)
  2022/11/14  AY      pr_Carrier_GetShipmentData: New version of Shipping_GetShipmentData with hash tables (OBV3-1432)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_GetShipmentData') is not null
  drop Procedure pr_Carrier_GetShipmentData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_GetShipmentData:
       Returns the Shipping Information for a given LPNId or OrderId
       This is currently used to call the Carrier Shipping API to create a
       shipment in the carrier system for UPS, FEDEX and ADSI

  This proc expects the followng hash table and populates the hash table data:

    #OrderHeaders: OrderHeaders table
    #CarrierShipmentData: TCarrierShipmentData, which is having the carrier ship information
    #CarrierPackageInfo: LPNs + TCarrierPackagesInfo

 if Requested by is API then we would not be sending these as part of XML
   a. CommoditiesInfo
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_GetShipmentData
  (@LPNId       TRecordId    = null,
   @OrderId     TRecordId    = null,
   @RequestedBy TDescription = 'CIMSSI',
   @Result      TXML         = null output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TMessage,
          @vUserId                     TUserId,
          @vBusinessUnit               TBusinessUnit,
          /* XML Vars */
          @vCartonDetailsxml           varchar(max),
          @vShippingAccountxml         varchar(max),
          @vShipViaxml                 varchar(max),
          @vXMLShipVia                 xml,
          @vLabelAttributesxml         varchar(max),
          @vAdditionalFieldsxml        varchar(max),
          @vRequestPackagesxml         varchar(max),
          @vResponsePackagesxml        varchar(max),
          @vResponsexml                varchar(max),
          @vReferencexml               varchar(max),
          @vCustomsxml                 varchar(max),
          @vCommoditiesxml             varchar(max), /* package level commodity info */
          @vCommoditiesInfoxml         varchar(max), /* shipment level commodity info */
          @vCN22InfoXML                varchar(max), /* Applicable only to UPS Mail Innovations international shipping */
          @vCIInfoXML                  varchar(max), /* Commercial Invoice - for international shipping */
          @vAdditionalShippingDocs     varchar(max),
          @vServiceDetailxml           varchar(max),
          @vShipViaSpecialServicesxml  varchar(max),
          @xmlRulesData                varchar(max),
          @vShipLabelLogging           TFlags,
          /* Order Info */
          @vSoldToId                   TCustomerId,
          @vSoldToName                 TName,
          @vShipToId                   TShipToId,
          @vShipToName                 TName,
          @vBillToAccount              TBillToAccount,
          @vBillToAddress              TContactRefId,
          @vReturnAddress              TReturnAddress,
          @vShipToState                TState,
          @vShipToCountry              TCountry,
          @vShipToAddressRegion        TAddressRegion,
          @vShipVia                    TShipVia,
          @vShipmentRefNumber          TShipmentRefNumber,
          @vCarrierServiceCode         varchar(50),
          @vCarrierServiceCodeMapping  TDescription,
          @vShipViaPackagingType       TDescription,
          @vSPGShipmentType            TFlag,
          @vPackagingType              TDescription,
          @vShipFrom                   TShipFrom,
          @vWaveShipDate               TDateTime,
          @vManifestAction             TDescription,
          @vOrderId                    TRecordId,
          @vCustPO                     TCustPO,
          @vPickTicket                 TPickTicket,
          @vOrderType                  TOrderType,
          @vTotalPackages              TCount,
          @vOrderCategory1             TOrderCategory,
          @vOrderCategory2             TOrderCategory,
          @vWaveId                     TRecordId,
          @vWaveNo                     TWaveNo,
          @vWaveType                   TTypeCode,
          @vOrderDate                  TDateTime,
          @vDesiredShipDate            TDateTime,
          @vSalesOrder                 TSalesOrder,
          @vAccount                    TAccount,
          @vAccountName                TAccountName,
          @vOwnership                  TOwnership,
          @vWarehouse                  TWarehouse,
          @vCarrierOptions             TDescription,
          @vInsuredValue               TMoney,
          @vFreightTerms               TDescription,
          /* LPN Info */
          @vLPNId                      TRecordId,
          @vLPN                        TLPN,
          @vPackageSeqNo               TInteger,
          @vLPNCartonType              TCartonType,
          @vCustomerContactId          TRecordId,
          @vShipToContactId            TRecordId,
          @vUCCBarcode                 TBarcode,
          @vCustomsValue               TMoney,
          @vSenderTaxId                TControlValue,
          @vReceiverTaxId              TControlValue,

          /* Carrier Info */
          @vIsSmallPackageCarrier      TFlag,
          @vCarrier                    TCarrier,
          @vSmartPostIndiciaType       TDescription,
          @vSmartPostHubId             TDescription,
          @vSmartPostEndorsement       TDescription,
          @vCarrierInterface           TCarrierInterface,
          @vLabelFormatType            TTypeCode,
          @vImageLabelType             TTypeCode,
          @vLabelRotation              TDescription,
          @vLabelStockType             TTypeCode,
          @vShipViaSpecialServices     TVarchar,
          @vShipViaStandardAttributes  TVarchar,
          @vIsResidential              TFlags,
          @vFutureShipDate             TDate,
          @vCutOffTime                 time,
          @vSaveCIFormInDB             TControlValue,
          @vFutureShipDateEntity       TControlValue,
          @vBillToContact              TControlValue,
          @vUnitValueOption            TControlValue,
          /* PO Info */
          @vPurchaseOrder              TReceiptType,
          @vRecordId                   TRecordId,
          @vEntity                     TEntity,
          @vDebug                      TFlags,
          @vCurrentDate                TDate;

  declare @ttLPNs                      TEntityKeysTable,
          @ttMarkers                   TMarkers;

begin /* pr_Carrier_GetShipmentData */
  select @vReturnCode          = 0,
         @vRecordId            = 0,
         @vMessageName         = null,
         @vMessage             = null,
         @vCurrentDate         = convert(date, getdate()),

         @vRequestPackagesxml  = '',
         @vResponsePackagesxml = '';

  if (coalesce(@LPNId, '') = '') and  (coalesce(@OrderId, '') = '')
    set @vMessageName = 'InvalidData';

  select @vEntity = iif(@LPNId is not null, 'LPN', 'Order');

  if (coalesce(@OrderId, '') = '')
    select @vOrderId = OrderId from LPNs where (LPNId = @LPNId);
  else
    select @vOrderId = @OrderId;

  if (@LPNId is not null)
    insert into @ttLPNs(EntityId, EntityKey)
      select LPNId, LPN from LPNs where LPNId = @LPNId;
  else
  if (@OrderId is not null)
    insert into @ttLPNs(EntityId, EntityKey)
      select LPNId, LPN from LPNs where (OrderId = @OrderId) and (LPNType = 'S' /* Ship Carton */)
      order by LPNId;

  /* Delete LPNs if there is already a valid shipment */
  delete L
  from @ttLPNs L
    join ShipLabels SL on (SL.EntityKey = L.EntityKey) and (BusinessUnit = @vBusinessUnit)
  where (SL.IsValidTrackingNo = 'Y' /* Yes */);

  if (not exists (select * from @ttLPNs))
    set @vMessageName = 'NoLPNsToCreateShipment';

  /* Create #OrderHeaders if it doesn't exist. Need to do below so that OrderId is not an identity column */
  if (object_id('tempdb..#OrderHeaders') is null)
    select * into #OrderHeaders from OrderHeaders where 1 = 2
    union all
    select * from OrderHeaders where (OrderId = @vOrderId);
  else
    insert into #OrderHeaders select * from OrderHeaders where (OrderId = @vOrderId);

  select @vSoldToId           = SoldToId,
         @vSoldToName         = SoldToName,
         @vShipToId           = ShipToId,
         @vBillToAddress      = BillToAddress,
         @vReturnAddress      = ReturnAddress,
         @vShipVia            = ShipVia,
         @vCarrierOptions     = CarrierOptions,
         @vShipFrom           = ShipFrom,
         @vCustPO             = dbo.fn_RemoveSpecialChars(CustPO),
         @vSalesOrder         = SalesOrder,
         @vPickTicket         = PickTicket,
         @vOrderType          = OrderType,
         @vTotalPackages      = LPNsAssigned,
         @vOrderDate          = OrderDate,
         @vDesiredShipDate    = DesiredShipDate,
         @vAccount            = Account,
         @vAccountName        = AccountName,
         @vWaveId             = PickBatchId,
         @vOrderCategory1     = OrderCategory1,
         @vOrderCategory2     = OrderCategory2,
         @vOwnership          = Ownership,
         @vWarehouse          = Warehouse,
         @vBusinessUnit       = BusinessUnit,
         @vFreightTerms       = FreightTerms
  from #OrderHeaders;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  select @vUnitValueOption = dbo.fn_Controls_GetAsString('Shipping', 'UnitValue', 'UnitSalePrice', @vBusinessUnit, @vUserId);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Carrier_GetShipmentData_Start';

  select @vWaveNo       = WaveNo,
         @vWaveType     = WaveType,
         @vWaveShipDate = coalesce(nullif(ShipDate, ''), current_timestamp)
  from Waves
  where (WaveId = @vWaveId);

  /* Get ShipToAddressId */
  select @vShipToAddressRegion = AddressRegion,
         @vShipToContactId     = ContactId,
         @vIsResidential       = case when Residential = 'Y' then 'true' else 'false' end,
         @vShipToState         = State,
         @vShipToCountry       = Country,
         @vReceiverTaxId       = TaxId
  from vwShipToAddress
  where (ShipToId = @vShipToId);

  select @vCarrier                   = Carrier,
         @vShipViaPackagingType      = PackagingType,
         @vCarrierServiceCode        = CarrierServiceCode,
         @vIsSmallPackageCarrier     = IsSmallPackageCarrier,
         @vShipViaStandardAttributes = StandardAttributes,
         @vShipViaSpecialServices    = SpecialServices,
         @vCutOffTime                = CutOffTime
  from vwShipVias
  where (ShipVia = @vShipVia);

  /* We do not want to have validations when we are generating labels...
     these should be done much ahead and not even get this far if it is not valid
     OBV3-1746 */
--  if (@vIsSmallPackageCarrier = 'Y' /* Yes */)
--    exec pr_Shipping_ValidateToShip null /* LoadId */, @vOrderId, null /* PalletId */, @LPNId, @vMessage output, @vMessageName output, @vShippingAccountxml output;

  /* Get the sender tax id */
  select @vSenderTaxId          = dbo.fn_Controls_GetAsString('Shipping', 'SenderTaxId', '', @vBusinessUnit, @vUserId);
  select @vFutureShipDateEntity = dbo.fn_Controls_GetAsString('Shipping', 'FutureShipDateEntity',   'Order', @vBusinessUnit, @vUserId);
  select @vBillToContact        = dbo.fn_Controls_GetAsString('Shipping', 'AlternateBillToContact', 'SoldTo', @vBusinessUnit, @vUserId);

  /* Build Rules data */
  select @xmlRulesData =  dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('LPNId',            @LPNId) +
                            dbo.fn_XMLNode('OrderId',          @vOrderId) +
                            dbo.fn_XMLNode('Entity',           @vEntity) +
                            dbo.fn_XMLNode('PickTicket',       @vPickTicket) +
                            dbo.fn_XMLNode('SalesOrder',       @vSalesOrder) +
                            dbo.fn_XMLNode('OrderType',        @vOrderType) +
                            dbo.fn_XMLNode('LPNCartonType',    @vLPNCartonType) +
                            dbo.fn_XMLNode('OrderCategory1',   @vOrderCategory1) +
                            dbo.fn_XMLNode('OrderCategory2',   @vOrderCategory2) +
                            dbo.fn_XMLNode('ShipToId',         @vShipToId) +
                            dbo.fn_XMLNode('SoldToId',         @vSoldToId) +
                            dbo.fn_XMLNode('IsSmallPackageCarrier',
                                                               @vIsSmallPackageCarrier) +
                            dbo.fn_XMLNode('ShipViaPackagingType',
                                                               @vShipViaPackagingType) +
                            dbo.fn_XMLNode('Carrier',          @vCarrier) +
                            dbo.fn_XMLNode('CarrierInterface',        '') +
                            dbo.fn_XMLNode('ShipVia',          @vShipVia) +
                            dbo.fn_XMLNode('FreightTerms',     @vFreightTerms) +
                            dbo.fn_XMLNode('CarrierOptions',   @vCarrierOptions) +
                            dbo.fn_XMLNode('AddressRegion',    @vShipToAddressRegion) +
                            dbo.fn_XMLNode('DocumentType',     '') +
                            dbo.fn_XMLNode('Account',          @vAccount) +
                            dbo.fn_XMLNode('AccountName',      @vAccountName) +
                            dbo.fn_XMLNode('InsuredValue',     '') +
                            dbo.fn_XMLNode('WaveNo',           @vWaveNo) +
                            dbo.fn_XMLNode('WaveType',         @vWaveType) +
                            dbo.fn_XMLNode('Operation',        '') +
                            dbo.fn_XMLNode('Ownership',        @vOwnership) +
                            dbo.fn_XMLNode('Warehouse',        @vWarehouse) +
                            dbo.fn_XMLNode('ShipFrom',         @vShipFrom) +
                            dbo.fn_XMLNode('CustPO',           @vCustPO) +
                            dbo.fn_XMLNode('ShipmentRefNumber', @vShipmentRefNumber) +
                            dbo.fn_XMLNode('MessageNamePrefix',
                                                               'ShipLabel'));

  exec pr_RuleSets_Evaluate 'CreateSPGShipment', @xmlRulesData, @vSPGShipmentType output;
  exec pr_RuleSets_Evaluate 'ManifestAction', @xmlRulesData, @vManifestAction output;

  /* Use the rules and get the Shipping Account Name and then the corresponding details */
  exec pr_Shipping_GetShippingAccountDetails @xmlRulesData, @vBusinessUnit, @vUserId, @vShippingAccountXML output;

  /* XMLRulesData: Get the InnerXML and add the ShippingAccountXml into it */
  select @xmlRulesData = dbo.fn_XMLAddNameValue(@xmlRulesData, 'RootNode', 'ShippingAccountXML', @vShippingAccountXML);

  /* Below rules execution will validate the orders to generate the labels */
  --exec pr_RuleSets_ExecuteAllRules 'Carrier_Validations', @xmlRulesData, @vBusinessUnit;

  select @vFutureShipDate = iif(@vFutureShipDateEntity = 'Wave', @vWaveShipDate, @vDesiredShipDate);

  /* If the future ship date is older than the current date, then override it with the current date */
  if (@vFutureShipDate < @vCurrentDate)
    select @vFutureShipDate = getdate();

  /* Current Date & Shipdate are same, but if the current time is passed the schedule time
     then shift the order to next day*/
  if ((@vFutureShipDate = @vCurrentDate) and (FORMAT(getdate(),'HH:mm') > @vCutOffTime))
    select @vFutureShipDate = DATEADD(day, 1, @vFutureShipDate);

  /* Adjust the ShipDate for weekends */
  update #OrderHeaders
  set DesiredShipDate = case when DATEPART(dw,@vFutureShipDate) = 7 /* Saturday */ then dateadd(day, 2, @vFutureShipDate)
                             when DATEPART(dw,@vFutureShipDate) = 1 /* Sunday */ then dateadd(day, 1, @vFutureShipDate)
                             else @vFutureShipDate
                        end
  where (OrderId = @vOrderId);

  /* Following values are hardcoded need to update as per client requirement*/
  /*Todo: This values must be returned based on rules*/

-- Applicable for UPS only

--   set @vServiceDetailxml = dbo.fn_XMLNode('SERVICEDETAILS',
--                              dbo.fn_XMLNode('MICostCenter', @vCustPO) +
--                              dbo.fn_XMLNode('MIPackageId' , @vPickTicket) +
--                              dbo.fn_XMLNode('MailerId'    , '924912333') +
--                              dbo.fn_XMLNode('USPSEndorsement', '1'));

  /* if there is not ResidentialFlag in the StandardAttributes, append the node to validate in the CIMSSI */
  if (@vShipViaStandardAttributes not like '%<ISRESIDENTIAL>%')
    select @vShipViaStandardAttributes = dbo.fn_XMLAppendNode(@vShipViaStandardAttributes, 'ISRESIDENTIAL', @vIsResidential);

  /* access ship service details table and get the label details based on shipvia */
  set @vShipViaxml = dbo.fn_XMLNode('SHIPVIA', @vShipViaStandardAttributes);

  /* If a mapping to the Carrier Service Code is defined, then change the same in the XML */
  if (@vCarrierServiceCodeMapping != @vCarrierServiceCode)
    set @vShipViaxml = replace(@vShipViaxml, '<CARRIERSERVICECODE>' + @vCarrierServiceCode + '</CARRIERSERVICECODE>', '<CARRIERSERVICECODE>' + @vCarrierServiceCodeMapping + '</CARRIERSERVICECODE>');

  /* Read Special Services from ShipVia record */
  set @vShipViaSpecialServicesxml =  dbo.fn_XMLNode('SPECIALSERVICES', @vShipViaSpecialServices);

  select @vXMLShipVia = cast(@vShipViaxml as xml);

  select @vLabelFormatType      = Record.Col.value('(LABELFORMAT)[1]',          'TTypeCode'),
         @vLabelStockType       = Record.Col.value('(LABELSTOCKSIZE)[1]',       'TTypeCode'),
         @vSmartPostIndiciaType = Record.Col.value('(SMARTPOSTINDICIATYPE)[1]', 'TDescription'),
         @vSmartPostHubId       = Record.Col.value('(SMARTPOSTHUBID)[1]',       'TDescription'),
         @vSmartPostEndorsement = Record.Col.value('(SMARTPOSTENDORSEMENT)[1]', 'TDescription')
  from @vXMLShipVia.nodes('/SHIPVIA') as Record(Col)
  OPTION (OPTIMIZE FOR (@vXMLShipVia = null));

  /* Get the LabelImageTypes to use */
  exec pr_RuleSets_Evaluate 'ShipLabelImageTypes', @xmlRulesData, @vImageLabelType output;

  /* Get the Label Rotation */
  exec pr_RuleSets_Evaluate 'ShipLabelRotation', @xmlRulesData, @vLabelRotation output;

  /* Determine which integration we are going to use i,e. Direct with UPS/FedEx or ADSI */
  exec pr_RuleSets_Evaluate 'CIMSSI_CarrierInterface', @xmlRulesData output, @vCarrierInterface output, @StuffResult = 'Y';

  /* Update the CarrierInterface in Xmldata*/
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'CarrierInterface', @vCarrierInterface);

  /* Update the BillToAddress based upon control variable and other required fields */
  update #CarrierShipmentData
  set /* Order Info */
      OrderId              = @vOrderId,
      PickTicket           = @vPickTicket,
      OrderDate            = @vOrderDate,
      FutureShipDate       = @vFutureShipDate,
      FreightTerms         = @vFreightTerms,
      TotalPackages        = @vTotalPackages,
      CarrierOptions       = @vCarrierOptions,
      /* Ship To Info */
      ShipToId             = @vShipToId,
      ShipToState          = @vShipToState,
      ShipToCountry        = @vShipToCountry,
      ShipToAddressRegion  = @vShipToAddressRegion,
      SoldToId             = @vSoldToId,
      /* Shipper Info */
      SenderTaxId          = @vSenderTaxId,
      /* Ship Via info */
      Carrier              = @vCarrier,
      ShipVia              = @vShipVia,
      CarrierServiceCode   = @vCarrierServiceCode,
      ServiceClass         = '',
      StandardAttributes   = @vShipViaStandardAttributes,
      SpecialServices      = @vShipViaSpecialServices,
      CarrierInterface     = @vCarrierInterface,
      ShipmentType         = @vSPGShipmentType,
      ManifestAction       = @vManifestAction,
      CarrierPackagingType = @vShipViaPackagingType,
      /* Smart Post info */
      SmartPostIndiciaType = @vSmartPostIndiciaType,
      SmartPostHubId       = @vSmartPostHubId,
      SmartPostEndorsement = @vSmartPostEndorsement,
      /* Billing Info */
      BillToContact        = case when (coalesce(@vBillToAddress, '') <> '') then @vBillToAddress
                                  when (@vBillToContact = 'ShipTo' )       then @vShipToId
                                  when (@vBillToContact = 'SoldTo' )       then @vSoldToId
                             end,
      BillToContactType    = case when (coalesce(@vBillToAddress, '') <> '') then 'B'
                                  when (@vBillToContact = 'ShipTo' )       then 'S'
                                  when (@vBillToContact = 'SoldTo' )       then 'C'
                             end,
      ReceiverTaxId        = @vReceiverTaxId,
      /* Label Info */
      LabelFormatType      = @vLabelFormatType,
      LabelStockType       = @vLabelStockType,
      LabelImageType       = @vImageLabelType,
      LabelRotation        = @vLabelRotation,
      CurrencyCode         = 'USD';

  exec pr_RuleSets_ExecuteAllRules 'Carrier_GetShipmentData' /* RuleSetType */, @xmlRulesData, @vBusinessUnit;

  /* Reason: This code is not required, already we are validating in UI. Also while generating the
     return labels this have some issues. So we need to re design for Return label
     Note: If these statement uncomments, returning errors from UI while generating labels */
  /* Exclude lpns  which already have  trackingno and label in shiplabes table */
  --delete T from  @ttLPNs T join ShipLabels S
  --on T.EntityKey = S.EntityKey where (S.Label is not null) and (coalesce(S.TrackingNo, '') <> '')

  /* copy all LPNs into temp table to get the commodities info */
  select * into #ttLPNs from @ttLPNs;
  exec pr_Shipping_GetCommoditiesInfo null /* LPNId */, @vBusinessUnit, null /* UserId */, @vCommoditiesInfoxml output;

  /* Required to call LPN Packages Resquence as FedEx requires Package Seq Number for Multi-Package shipment required */
  exec pr_LPNs_PackageNoResequence @vOrderId;

  insert into #CarrierPackageInfo
    select L.*, @vEntity EntityType, L.LPN /* EntityKey */, null PackageType, null PackageDescription, null InsuranceRequired,
                null InsuredValue, null CartonDetailsXML, null CartonLength, null CartonWidth, null CartonHeight, null CNNDescription,
                null PackageWeight, null PackageWeightOz, null WeightUoM, null DimensionUoM, null CIPurpose, null CITerms, null CIDate,
                null CINumber, null CIFreightCharge, null CIInsuranceValue, null CIOtherCharges, null CIComments, null CISaveInDB,
                null LabelReference1, null LabelReference2, null LabelReference3, null LabelReference4, null LabelReference5,
                null LabelReference1Type, null LabelReference1Value, null LabelReference2Type, null LabelReference2Value,
                null LabelReference3Type, null LabelReference3Value, null LabelReference4Type, null LabelReference4Value,
                null LabelReference5Type, null LabelReference5Value
    from #ttLPNs ttL
      join LPNs L on (ttL.EntityId = L.LPNId);

  /* Update the Package info */
  ;with LPNInsValue as
  (
   select CP.LPNId, sum(LD.Quantity * (case /* Calculate the Insured value based upon the control value */
                                         when (@vUnitValueOption = 'UnitSalePrice')
                                           then coalesce(nullif(OD.UnitSalePrice, 0), nullif(S.UnitPrice, 0), S.UnitCost)
                                         else
                                           S.UnitCost
                                       end)) InsuredValue
   from #CarrierPackageInfo CP
     join LPNDetails LD on (LD.LPNId = CP.LPNId)
     join OrderDetails OD on (CP.OrderId = OD.OrderId) and (LD.OrderDetailId = OD.OrderDetailId)
     join SKUs S on (LD.SKUId = S.SKUId)
   group by CP.LPNId
  )
  update CP
  set PackageDescription = CP.LPNId,
      InsuredValue       = LIV.InsuredValue
  from #CarrierPackageInfo CP
    join LPNInsValue LIV on (CP.LPNId = LIV.LPNId)

  /* Update the Customs value for the shipment */
  select @vCustomsValue = sum(InsuredValue) from #CarrierPackageInfo;
  select @vCustomsValue = case when coalesce(@vCustomsValue, 0) < 1 then 1 else @vCustomsValue end;
  update #CarrierShipmentData set CustomsValue = cast(coalesce(@vCustomsValue, 0) as varchar);

  /* Update the PackageType, Carton Dimensions for all the Packages */
  exec pr_Carrier_UpdateCartonDetails @xmlRulesData, @vBusinessUnit;

  /* Apply Rules to get Ref1, Ref2 & Ref3 values */
  exec pr_RuleSets_ExecuteAllRules 'CarrierPackages', @xmlRulesData, @vBusinessUnit;
  --exec pr_RuleSets_ExecuteAllRules 'ShippingReferences' /* RuleSetType */, @xmlRulesData, @vBusinessUnit;

  /* Will migrate this to pr_Carrier_BuildAdditonalfields.
     We will defer this to later as this is required for ADSI only */
  /* Build the addition fields for the carriers */
  /* As of now no V3 client is using and we can refactor this later */
  --exec pr_Shipping_BuildAdditionalFields @xmlRulesData, @vAdditionalFieldsxml output;

ErrorHandler:
  if (@vMessageName is not null)
    begin
      select @vMessage = dbo.fn_Messages_Build(@vMessageName, null, null, null, null, null);

      /* If Shiplabels are already exists in Shiplabel table then update the label generation error message */
      update S
      set S.Notifications = @vMessage,
          S.ProcessStatus = 'LGE' /* Label Generation Error */
      from ShipLabels S
        join @ttLPNs ttL on (ttL.EntityId = S.EntityId) and (S.Status = 'A' /* Active */)

      /* If there is no Entity is available in ShipLabels table insert with message, other wise update with error and Process status */
      insert into Shiplabels (EntityId, EntityKey, OrderId, PickTicket, WaveId, WaveNo, ShipVia, Carrier, CarrierInterface, TrackingNo, ProcessStatus, Notifications, BusinessUnit)
        select ttL.EntityId, ttL.EntityKey, @vOrderId, @vPickTicket, @vWaveId, @vWaveNo, @vShipVia, @vCarrier, @vCarrierInterface, '', 'LGE' /* Label Generation Error */, @vMessage, @vBusinessUnit
        from @ttLPNs ttL
          left outer join Shiplabels S on (S.EntityId = ttL.EntityId) and (S.Status = 'A')
        where (S.EntityId is null);
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_GetShipmentData */

Go
