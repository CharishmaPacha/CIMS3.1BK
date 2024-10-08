/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/15  RV      pr_Shipping_GetShipmentData, pr_Shipping_GetShipmentData: Corrected the packing type
  2023/04/06  TD      pr_Shipping_GetShipmentData: (Pass Insurenced Value as 0 when Insurance is not requried (Support)
  2021/12/29  RT      pr_Shipping_GetShipmentData: Changes to send the IsResidential flag in the ShipmentRequest (CID-1904)
  2020/10/28  VS      pr_Shipping_GetShipmentData: We should insert only S Type cartons into Shiplabels table (HA-1620)
  2020/06/25  RV      pr_Shipping_GetShipmentData: Included the ZPLIMAGELABEL to fill while create shipment
                        pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Get the ZPLIMAGELABEL and save in ShipLabels table,
                        if label image type other than ZPL (HA-854)
  2020/05/23  RT      pr_Shipping_GetShipmentData,pr_Shipping_SaveShipmentData: Mireated changes from S2G (HA-179)
  2020/02/24  YJ      pr_Shipping_GetShipmentData, pr_Shipping_RegenerateTrackingNumbers,
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_ValidateToShip,
                      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2019/12/05  TK      pr_Shipping_GetShipmentData, pr_Shipping_SaveShipmentData & fn_Shipping_GetCartonDetails:
                        Changes to get proper carton dimensions (S2GCA-1068)
  2019/11/26  HYP     pr_Shipping_SaveShipmentData/pr_Shipping_SaveLPNData and pr_Shipping_GetShipmentData:
                        Made changes to capture TrackingBarcode (FB-1546)
  2019/09/05  VS      pr_Shipping_GetShipmentData: Made changes to do not round the PackageWeight value for USPSF ShipVia (CID-1017)
  2019/02/26  RV      pr_Shipping_GetShipmentData: Enabled future ship date enabled by PK on request by client
                      pr_Shipping_GetShipmentData: Made changes exclude LPNs, which are already created shipment for PickTicket
  2019/01/18  RV      pr_Shipping_GetShipmentData: Made changes to retun ManifestAction based on the rules
  2018/11/19  RV      pr_Shipping_GetShipmentData: Made changes to send SPG shipment type based on the rules (S2G-1170)
  2018/11/16  RV      pr_Shipping_GetShipmentData: Made changes to get the future ship date
  2018/09/25  RV      pr_Shipping_GetShipmentData: Made changes to send first package tracking number as master tracking number
  2018/09/17  RV      pr_Shipping_GetShipmentData: Stuff Carrier Interface with newly evaluated value to get the
  2018/09/03  RV      pr_Shipping_GetShipmentData: Made changes to add IsSmallPackageCarrier
  2018/08/29  RV      pr_Shipping_GetShipmentData, pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData,
  2018/07/23  RV      pr_Shipping_GetShipmentData: Made changes to get the sender tax id and send through Customs xml (S2G-919)
  2018/07/19  SPP     pr_Shipping_GetShipmentData : port back changes taken fron onsiteprod to Localprod(FB-992)
                      pr_Shipping_GetShipmentData: Made changes to return ShipTo address country code (S2G-950)
  2018/05/18  TK/RV   pr_Shipping_GetShipmentData: Use function to get carton details xml
              PM      pr_Shipping_GetShipmentData: Added InsuredValue computed as LPNDetails.Quantity * OrderDetail.UnitRetailPrice (S2G-601)
  2018/05/11  PM      pr_Shipping_GetShipmentData:Updated registered AES number for FedEx/UPS on the international orders(S2G-602)
  2018/04/30  RV      pr_Shipping_GetShipmentData: Bug fixed to create shipment (S2G-765)
  2018/04/26  RV      pr_Shipping_GetShipmentData: Made changes to send rotation value to rotate
  2018/02/21  RV      pr_Shipping_GetShipmentData: Few of the migrated from OB Prod. Added validation for valid LPN or PickTicket.
                      pr_Shipping_GetShipmentData: Insert/update the carton into the shiplabel table while raising error
              RV      pr_Shipping_GetShipmentData: Get ShipVias with respect to the BusinessUnit (S2G-110)
  2018/02/01  RV      pr_Shipping_GetShipmentData: Get the Label image type (ZPL/PNG) from rules and retun in Request xml to
  2017/10/01  OK      pr_Shipping_GetShipmentData: Enhanced to return the CN22 details and required shipping docs in xml
              VM      pr_Shipping_GetCommercialInvoiceInfo: Added and called from pr_Shipping_GetShipmentData (OB-576)
  2017/09/25  VM      pr_Shipping_GetShipmentData: Use vwContacts for ShipFromAddress (OB-576)
  2017/08/11  DK      pr_Shipping_GetShipmentData: Bug fix to send default currency value as 1 if UnitSalePrice is null (FB-998).
  2017/04/20  NB      Modified pr_Shipping_GetShipmentData (CIMS-1259)
                      Modified pr_Shipping_GetShipmentData - changes to
                      pr_Shipping_GetShipmentData for Carrier Interface handling
  2017/04/10  NB      Modified pr_Shipping_GetShipmentData (CIMS-1259)
  2017/03/22  NB      Modified pr_Shipping_GetShipmentData (CIMS-1259)
  2017/01/17  NB      Modified pr_Shipping_GetShipmentData to read SpecialServices
  2016/11/24  KN      pr_Shipping_GetShipmentData optimized code (HPI-1032)
  2016/11/10  KN      pr_Shipping_GetShipmentData debugging is set based on control variable (HPI-1032)
  2016/11/04  KN      pr_Shipping_GetShipmentData: setting "ISDEBUG" to true for enabling request / response logging (HPI-991)
                      pr_Shipping_GetShipmentData: Minor syntax corrections in XML creation
  2016/08/02  RV      pr_Shipping_GetShipmentData: Added new procedure to handle the multiple packages in a single request to the small package carriers (HPI-414)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetShipmentData') is not null
  drop Procedure pr_Shipping_GetShipmentData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetShipmentData:
       Returns the Shipping Information for a given LPNId or OrderId
       This is currently used to call the Carrier Shipping API to create a
       shipment in the carrier system for UPS, FEDEX and ADSI

  The Information is sent back as an XML String with the following structure when
   Carrier interface is CIMSSI. If it is API, then we would not not send the XML
   and instead return the info in # tables (this is a progressive step and we
   won't be doing this all at once - details below)

 if Requested by is API then we would not be sending these as part of XML
   a. CommoditiesInfo
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetShipmentData
  (@LPN        TLPN        = null,
   @LPNId      TRecordId   = null,
   @OrderId    TRecordId   = null,
   @PickTicket  TPickTicket  = null,
   @RequestedBy TDescription = 'CIMSSI')
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TMessage,
          @vUserId             TUserId,
          @vBusinessUnit       TBusinessUnit,

          /* XML Vars */
          @vLPNHeaderxml       varchar(max),
          @vLPNDetailsxml      varchar(max),
          @vOrderHeaderxml     varchar(max),
          @vOrderDetailsxml    varchar(max),
          @vShipFromxml        varchar(max),
          @vSoldToxml          varchar(max),
          @vSoldToAddressxml   varchar(max),
          @vShipToxml          varchar(max),
          @vShipToAddressxml   varchar(max),
          @vBillToAddressxml   varchar(max),
          @vReturnAddressxml   varchar(max),
          @vCartonDetailsxml   varchar(max),
          @vShippingAccountxml varchar(max),
          @vShipViaxml         varchar(max),
          @vLabelAttributesxml varchar(max),
          @vAdditionalFieldsxml
                               varchar(max),
          @vRequestPackagesxml varchar(max),
          @vResponsePackagesxml
                               varchar(max),
          @vResponsexml        varchar(max),
          @vReferencexml       varchar(max),
          @vCustomsxml         varchar(max),
          @vCommoditiesxml     varchar(max), /* package level commodity info */
          @vCommoditiesInfoxml varchar(max), /* shipment level commodity info */
          @vCN22InfoXML        varchar(max), /* Applicable only to UPS Mail Innovations international shipping */
          @vCIInfoXML          varchar(max), /* Commercial Invoice - for international shipping */
          @vAdditionalShippingDocs
                               varchar(max),
          @vServiceDetailxml   varchar(max),
          @vSpecialServicesxml varchar(max),
          @xmlRulesData        varchar(max),
          @vShipLabelLogging   TFlags,

          /* Order Info */
          @vSoldToId           TCustomerId,
          @vShipToId           TShipToId,
          @vShipToName         TName,
          @vBillToAddress      TContactRefId,
          @vReturnAddress      TReturnAddress,
          @vShipToAddressRegion
                               TAddressRegion,
          @vShipVia            TShipVia,
          @vCarrierServiceCode varchar(50),
          @vCarrierServiceCodeMapping
                               TDescription,
          @vShipViaPackagingType
                               TDescription,
          @vSPGShipmentType    TFlag,
          @vPackagingType      TDescription,
          @vShipFrom           TShipFrom,
          @vWaveShipDate       TDateTime,
          @vManifestAction     TDescription,
          @vOrderId            TRecordId,
          @vCustPO             TCustPO,
          @vPickTicket         TPickTicket,
          @vOrderType          TOrderType,
          @vOrderCategory1     TOrderCategory,
          @vOrderCategory2     TOrderCategory,
          @vWaveId             TRecordId,
          @vWaveNo             TWaveNo,
          @vWaveType           TTypeCode,
          @vDesiredShipDate    TDateTime,
          @vSalesOrder         TSalesOrder,
          @vOH_UDF6            TUDF,
          @vAccount            TAccount,
          @vAccountName        TAccountName,
          @vOwnership          TOwnership,
          @vWarehouse          TWarehouse,
          @vCarrierOptions     TDescription,
          @vInsuranceRequired  TFlags,
          @vInsuredValue       TMoney,
          /* LPN Info */
          @vLPNId              TRecordId,
          @vLPN                TLPN,
          @vPackageSeqNo       TInteger,
          @vMasterTrackingNo   TTrackingNo,
          @vCartonType         TCartonType,
          @vCustomerContactId  TRecordId,
          @vShipToContactId    TRecordId,
          @vUCCBarcode         TBarcode,
          @vValue              TMoney,
          @vSenderTaxId        TControlValue,
          @vLPNDescription     TDescription,

          /* Carrier Info */
          @vIsSmallPackageCarrier
                               TFlag,
          @vCarrier            TCarrier,
          @vCarrierRulexmlData varchar(max),
          @vCarrierInterface   TCarrierInterface,
          @vImageLabelType     TTypeCode,
          @vLabelRotation      TDescription,
          @vSpecialServices    TVarchar,
          @vStandardAttributes TVarchar,
          @vIsResidential      TFlags,
          @vCN22LabelRequired  TControlValue,
          @vCIFormRequired     TControlValue, /* Commercial Invocie */
          @vSaveCIFormInDB     TControlValue,

          /* PO Info */
          @vPurchaseOrder      TReceiptType,
          @vRecordId           TRecordId,

          @vEntity             TEntity,

          @vDebug              TFlags;

  declare @ttLPNs              TEntityKeysTable,
          @ttMarkers           TMarkers;

begin /* pr_Shipping_GetShipmentData */
  select @ReturnCode           = 0,
         @vRecordId            = 0,
         @Messagename          = null,
         @Message              = null,

         @vRequestPackagesxml  = '',
         @vResponsePackagesxml = '';

  if (coalesce(@LPNId, '') = '' and coalesce(@LPN, '') = '' and coalesce(@OrderId, '') = '' and coalesce(@PickTicket, '') = '')
    set @MessageName = 'InvalidData';

  if (coalesce(@LPNId, '') = '' and coalesce(@LPN, '') <> '')
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN);

  if (coalesce(@OrderId, '') = '' and coalesce(@PickTicket, '') <> '')
    select @OrderId = OrderId
    from OrderHeaders
    where (PickTicket = @PickTicket)

  /* Get the Entity type */
  if (coalesce(@OrderId, '') <> '')
    select @vEntity = 'PickTicket';
  else
    select @vEntity = 'LPN';

  if (coalesce(@OrderId, '') = '')
    select @vOrderId = OrderId
    from LPNs
    where (LPNId = @LPNId);
  else
    select @vOrderId = @OrderId;

  if (coalesce(@LPNId, '') = '' and coalesce(@OrderId, '') = '')
    set @MessageName = 'NotanLPNorPickTicket';

  if (@LPNId is not null)
    insert into @ttLPNs(EntityId, EntityKey)
      select LPNId, LPN
      from LPNs
      where LPNId = @LPNId;
  else
  if (@OrderId is not null)
    insert into @ttLPNs(EntityId, EntityKey)
      select LPNId, LPN
      from LPNs
      where (OrderId = @OrderId) and
            (LPNType = 'S' /* Ship Carton */)
      order by LPNId;

  /* Delete LPNs if there is already a valid shipment */
  delete L
  from @ttLPNs L
    join ShipLabels SL on (SL.EntityKey = L.EntityKey)
  where (SL.IsValidTrackingNo = 'Y' /* Yes */)

  if (not exists (select * from @ttLPNs))
    set @MessageName = 'NoLPNsToCreateShipment';

  select @vSoldToId           = SoldToId,
         @vShipToId           = ShipToId,
         @vBillToAddress      = BillToAddress,
         @vReturnAddress      = ReturnAddress,
         @vShipVia            = ShipVia,
         @vCarrierOptions     = CarrierOptions,
         @vShipFrom           = ShipFrom,
         @vCustPO             = CustPO,
         @vSalesOrder         = SalesOrder,
         @vPickTicket         = PickTicket,
         @vOrderType          = OrderType,
         @vDesiredShipDate    = DesiredShipDate,
         @vAccount            = Account,
         @vAccountName        = AccountName,
         @vWaveId             = PickBatchId,
         @vOrderCategory1     = OrderCategory1,
         @vOrderCategory2     = OrderCategory2,
         @vOwnership          = Ownership,
         @vWarehouse          = Warehouse,
         @vOH_UDF6            = UDF6,
         @vBusinessUnit       = BusinessUnit,
         @vInsuranceRequired  = UDF13
  from OrderHeaders
  where (OrderId = @vOrderId);

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Shipping_GetShipmentData_Start';

  select @vWaveNo   = WaveNo,
         @vWaveType = WaveType,
         @vWaveShipDate = coalesce(nullif(ShipDate, ''), current_timestamp)
  from Waves
  where (WaveId = @vWaveId);

  /* Get Customer AddressId */
  select @vCustomerContactId = CustomerContactId
  from Customers
  where (CustomerId = @vSoldToId);

  /* Get ShipToAddressId */
  select @vShipToAddressRegion = AddressRegion,
         @vShipToContactId     = ContactId,
         @vIsResidential       = case when Residential = 'Y' then 'true' else 'false' end
  from vwShipToAddress
  where (ShipToId = @vShipToId);

  select @vCarrier               = Carrier,
         @vShipViaPackagingType  = PackagingType,
         @vCarrierServiceCode    = CarrierServiceCode,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier,
         @vStandardAttributes    = StandardAttributes,
         @vSpecialServices       = SpecialServices
  from vwShipVias
  where (ShipVia = @vShipVia);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ValidateToShip_Start';

  if (@vIsSmallPackageCarrier = 'Y' /* Yes */)
    exec pr_Shipping_ValidateToShip null /* LoadId */, @vOrderId, null /* PalletId */, @LPNId, @Message output, @MessageName output, @vShippingAccountxml output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ValidateToShip_End';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get the sender tax id */
  select @vSenderTaxId = dbo.fn_Controls_GetAsString('Shipping', 'SenderTaxId', '', @vBusinessUnit, @vUserId);

  /* Build Rules data */
  select @xmlRulesData =  dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('LPNId',            @LPNId) +
                            dbo.fn_XMLNode('OrderId',          @vOrderId) +
                            dbo.fn_XMLNode('Entity',           @vEntity) +
                            dbo.fn_XMLNode('PickTicket',       @vPickTicket) +
                            dbo.fn_XMLNode('SalesOrder',       @vSalesOrder) +
                            dbo.fn_XMLNode('OrderType',        @vOrderType) +
                            dbo.fn_XMLNode('OrderCategory1',   @vOrderCategory1) +
                            dbo.fn_XMLNode('OrderCategory2',   @vOrderCategory2) +
                            dbo.fn_XMLNode('ShipToId',         @vShipToId) +
                            dbo.fn_XMLNode('SoldToId',         @vSoldToId) +
                            dbo.fn_XMLNode('IsSmallPackageCarrier',
                                                               @vIsSmallPackageCarrier) +
                            dbo.fn_XMLNode('Carrier',          @vCarrier) +
                            dbo.fn_XMLNode('CarrierInterface',        '') +
                            dbo.fn_XMLNode('ShipVia',          @vShipVia) +
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
                            dbo.fn_XMLNode('ShipFrom',         @vShipFrom));

  /* Determine which integration we are going to use ie. Direct with UPS/FedEx or ADSI */
  exec pr_RuleSets_Evaluate 'CarrierInterface', @xmlRulesData, @vCarrierInterface output;
  select @vCarrierInterface = coalesce(@vCarrierInterface, 'DIRECT'); -- If no rules are defined, then use DIRECT option as carrier interface
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'CarrierInterface', @vCarrierInterface);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'CarrierInterface_RulesEvaluation_Completed';

  exec pr_RuleSets_Evaluate 'CreateSPGShipment', @xmlRulesData, @vSPGShipmentType output;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ORDERHEADER_XMLBuild_Start';

  exec pr_RuleSets_Evaluate 'ManifestAction', @xmlRulesData, @vManifestAction output;

  set @vOrderHeaderxml   = (select *, @vCarrierInterface as CARRIERINTERFACE,
                                      @vWaveShipDate FutureShipDate, @vSPGShipmentType as SPGShipmentType,  @vManifestAction ManifestAction
                            from OrderHeaders
                            where OrderId = @vOrderId
                            for xml raw('ORDERHEADER'), elements);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ORDERDETAIL_XMLBuild_Start';

  /* Nothing in OrderDetail is required for the purpose of generating Carrier Label
     but instead of dropping it altogether just limiting to one record */
  set @vOrderDetailsxml  = (select top 1 * from OrderDetails
                            where OrderId = @vOrderId
                            for xml raw('ORDERDETAIL'), elements);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SHIPFROM_XMLBuild_Start';

  set @vShipFromxml      = (select * from vwContacts
                            where (ContactRefId = @vShipFrom) and
                                  (ContactType = 'F' /* Ship From */)
                            for xml raw('SHIPFROM'), elements);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SOLDTO_XMLBuild_Start';

  /* Why is this required for carrier integration? */
  set @vSoldToxml        = (select * from Customers CUST
                            where (CUST.CustomerId = @vSoldToId)
                            for xml raw('SOLDTO'), elements );

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SOLDTOADDRESS_XMLBuild_Start';

  set @vSoldToAddressxml = (select * from vwSoldToAddress
                            where (SoldToId = @vSoldToId)
                            for xml raw('SOLDTOADDRESS'), elements);

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SHIPTO_XMLBuild_Start';

  /* Why is this required for carrier integration? */
  set @vShipToxml        = (select * from ShipTos SHTO
                            where (SHTO.ShipToId = @vShipToId)
                            for xml raw('SHIPTO'), elements );

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SHIPTOADDRESS_XMLBuild_Start';

  set @vShipToAddressxml = (select *, Country as CountryCode from dbo.fn_Contacts_GetShipToAddress (@vOrderId, @vShipToId)
                            for xml raw('SHIPTOADDRESS'), elements );

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'BILLTOADDRESS_XMLBuild_Start';

  set @vBillToAddressxml = (select * from Contacts
                            where (ContactRefId = @vBillToAddress) and
                                  (ContactType = 'B' /* BillTo Address */)
                            for xml raw('BILLTOADDRESS'), elements );

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'RETURNADDRESS_XMLBuild_Start';

  /* Why is this required for carrier integration? */
  set @vReturnAddressxml = (select * from Contacts
                            where (ContactRefId = @vReturnAddress) and
                                  (ContactType = 'R' /* Return Address */)
                            for xml raw('RETURNADDRESS'), elements );

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SERVICEDETAILS_XMLBuild_Start';

  /* Following values are hardcoded need to update as per client requirement*/
  /*Todo: This values must be returned based on rules*/
  set @vServiceDetailxml = dbo.fn_XMLNode('SERVICEDETAILS',
                             dbo.fn_XMLNode('MICostCenter', @vCustPO) +
                             dbo.fn_XMLNode('MIPackageID' , @vSalesOrder + cast(@vOrderId as varchar)) +
                             dbo.fn_XMLNode('MailerId'    , '924912333') +
                             dbo.fn_XMLNode('USPSEndorsement', '1'));

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SHIPVIA_XMLBuild_Start';

  /* if there is not ResidentialFlag in the StandardAttributes, append the node to validate in the CIMSSI */
  if (@vStandardAttributes not like '%<ISRESIDENTIAL>%')
    select @vStandardAttributes = dbo.fn_XMLAppendNode(@vStandardAttributes, 'ISRESIDENTIAL', @vIsResidential);

  /* access ship service details table and get the label details based on shipvia */
  set @vShipViaxml = dbo.fn_XMLNode('SHIPVIA', @vStandardAttributes);

  /* If a mapping to the Carrier Service Code is defined, then change the same in the XML */
  if (@vCarrierServiceCodeMapping != @vCarrierServiceCode)
    set @vShipViaxml = replace(@vShipViaxml, '<CARRIERSERVICECODE>' + @vCarrierServiceCode + '</CARRIERSERVICECODE>', '<CARRIERSERVICECODE>' + @vCarrierServiceCodeMapping + '</CARRIERSERVICECODE>');

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'SPECIALSERVICES_XMLBuild_Start';

  /* Read Special Services from ShipVia record */
  set @vSpecialServicesxml =  dbo.fn_XMLNode('SPECIALSERVICES', @vSpecialServices);

  /* Gather info for Customs */
  select @vValue = sum(LD.Quantity * coalesce(nullif(OD.UnitSalePrice, 0), S.UnitPrice)) --we are getting RetailUnitPrice as zero
  from LPNDetails LD
    join @ttLPNs ttL on (ttL.EntityId = LD.LPNId)
    join OrderDetails OD on (LD.OrderId = OD.OrderId) and (LD.OrderDetailId = OD.OrderDetailId)
    join SKUs S on (LD.SKUId = S.SKUId);

 /* Send the default value to pass in a $1 instead of sending 0 to avoid errors from UPS/FedEx */
 select @vValue = case when @vValue < 1 then 1 else @vValue end;

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'CUSTOMS_XMLBuild_Start';

  set @vCustomsxml = '<CUSTOMS>' +
                        dbo.fn_XMLNode('VALUE',       cast(@vValue as varchar)) +
                        dbo.fn_XMLNode('CURRENCY',    'USD') +
                        dbo.fn_XMLNode('SenderTaxId', @vSenderTaxId) +
                     '</CUSTOMS>';

  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'DocumentType', 'CommercialInvoice');

  exec pr_RuleSets_Evaluate 'InternationalShipDocs', @xmlRulesData, @vCIFormRequired output;

  /* Replace the Document type to CN22 to use same xml for CN22 rules */
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'DocumentType', 'CN22');

  exec pr_RuleSets_Evaluate 'InternationalShipDocs', @xmlRulesData, @vCN22LabelRequired output;

  /* Build XML for required shipping labels/forms */
  set @vAdditionalShippingDocs = '<ADDITIONALSHIPPINGDOCS>' +
                                    dbo.fn_XMLNode('COMMERCIALINVOICE', @vCIFormRequired) +
                                    dbo.fn_XMLNode('CN22',              @vCN22LabelRequired) +
                                 '</ADDITIONALSHIPPINGDOCS>'

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'LabelImageTypes_XMLBuild_Start';

  /* Get the LabelImageTypes to use */
  exec pr_RuleSets_Evaluate 'ShipLabelImageTypes', @xmlRulesData, @vImageLabelType output;

  /* Get the Label Rotation */
  exec pr_RuleSets_Evaluate 'ShipLabelRotation', @xmlRulesData, @vLabelRotation output;

  set @vLabelAttributesxml = dbo.fn_XMLNode('LABELATTRIBUTES',
                               dbo.fn_XMLNode('LabelImageType', @vImageLabelType) +
                               dbo.fn_XMLNode('LabelRotation',  @vLabelRotation));

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ExcludeLPNs_XMLBuild_Start';

  /* Reason: This code is not required, already we are validating in UI. Also while generating the
     return labels this have some issues. So we need to re design for Return label
     Note: If these statement uncomments, returning errors from UI while generating labels */
  /* Exclude lpns  which already have  trackingno and label in shiplabes table */
  --delete T from  @ttLPNs T join ShipLabels S
  --on T.EntityKey = S.EntityKey where (S.Label is not null) and (coalesce(S.TrackingNo, '') <> '')

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ExcludeLPNs_XMLBuild_End';

  /* copy all LPNs into temp table to get the commodities info */
  select * into #ttLPNs from @ttLPNs;
  exec pr_Shipping_GetCommoditiesInfo null /* LPNId */, @vBusinessUnit, null /* UserId */, @vCommoditiesInfoxml output;

  /* Required to call LPN Packages Resquence as FedEx requires Package Seq Number for Multi-Package shipment required */
  exec pr_LPNs_PackageNoResequence @vOrderId;

  while (exists(select * from @ttLPNs where RecordId > @vRecordId))
    begin
      /* select top 1 here */
      select top 1 @vLPNId      = EntityId,
                   @vLPN        = EntityKey,
                   @vRecordId   = RecordId
      from @ttLPNs
      where (RecordId > @vRecordId)
      order by RecordId;

      select @vOrderId       = OrderId,
             @vCartonType    = CartonType,
             @vLPN           = LPN,
             @vPackageSeqNo  = PackageSeqNo,
             @vUCCBarcode    = UCCBarcode,
             @vBusinessUnit  = BusinessUnit,
             @vPurchaseOrder = ReceiptNumber
      from LPNs
      where (LPNId = @vLPNId);

      /* Gather info for insurance */
      select @vInsuredValue = sum(LD.Quantity * coalesce(nullif(OD.UnitSalePrice, 0), coalesce(OD.RetailUnitPrice, 0))) --we are getting RetailUnitPrice as zero
      from LPNDetails LD
        join OrderDetails OD on (LD.OrderId = OD.OrderId) and (LD.OrderDetailId = OD.OrderDetailId)
      where LPNId = @vLPNId;

      /* Stuff with InsuredValue */
      select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'InsuredValue', @vInsuredValue);

      /* If insured value is R then evaluate from rules
                             Y then Insurance required
                             other than Insurance not reuired */
      if (dbo.fn_IsInList('IR' /**/, @vCarrierOptions) > 0)
        /* Get insurance reuired or not */
        exec pr_RuleSets_Evaluate 'ShipLabel_InsuranceRequired', @xmlRulesData, @vInsuranceRequired output;
      else
      if (dbo.fn_IsInList('IA' /**/, @vCarrierOptions) > 0 /* Insure Always */)
        select @vInsuranceRequired = 'Y';
      else
        select @vInsuranceRequired = 'N';

      /* if the Insurance is not required then set the value to 0 */
      if (@vInsuranceRequired = 'N')
        set @vInsuredValue =0;

      /* FEDEX: Even multi package shipment creation also FEDEX allows to create individually only. First package shipment is
         treating as master package and need to send this master package tracking number as master tracking number to the sub sequent
         packages. Also send total number of packages at the time of master package shipment creation.But some times there may
         be a change in total packages at the time of re allocation. At this situation creating single shipment for the remaining packages */
      if (@vCarrier = 'FEDEX') and (@vPackageSeqNo <> 1)
        select @vMasterTrackingNo = SL.TrackingNo
        from ShipLabels SL
          join LPNs L on (L.LPN = SL.EntityKey)
        where (SL.OrderId       = @vOrderId) and
              (SL.Status        = 'A') and
              (SL.ProcessStatus in ('LG', 'XC', 'XR', 'XI', 'XE')) and
              (L.PackageSeqNo   = 1) and
              (SL.TotalPackages >= @vPackageSeqNo);

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'CONTAINERHEADER_XMLBuild_Start';

      /* Build Package Description */
      select @vLPNDescription = @vLPNId; /* This is required for International Shipments via ADSI */
      /* Build XML with ALL possible info that might be needed for a Shipping Integration */
      set @vLPNHeaderxml     = (select L.*,
                                       (case when @vShipViaPackagingType = 'Irregulars' then L.LPNWeight
                                             when @vShipVia not in ('USPSF') and @vShipVia like 'USPS%' then ceiling(L.LPNWeight) /* Temporary fix to ceiling actual weight to avoid the USPS less weight errors while actual weight is less than 1*/
                                             else L.LPNWeight end) as PackageWeight,
                                             @vLPNDescription as LPNDescription,
                                        @vInsuranceRequired as DeclaredvalueFlag, coalesce(@vInsuredValue, 0) as DeclaredValueAmount, @vMasterTrackingNo as MasterTrackingNo,
                                        coalesce(S.Description, 'Multiple') SKUDescription
                                from LPNs L
                                  join SKUs S on (L.SKUId = S.SKUId)
                                where LPNId = @vLPNId
                                for xml raw('CONTAINERHEADER'), elements);

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'CONTAINERDETAIL_XMLBuild_Start';

      /* Nothing in LPNDetails is required for the purpose of generating Carrier Label
         but instead of dropping it altogether just limiting to one record */
      set @vLPNDetailsxml    = (select top 1 * from LPNdetails
                                where LPNId = @vLPNId
                                for xml raw('CONTAINERDETAIL'), elements);

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'CARTONDETAILS_XMLBuild_Start';

      /* Get the packaging type based upon service and cartontype used. see GetPackagingType function for more details */
      select @vPackagingType = dbo.fn_Shipping_GetPackagingType(@vShipViaPackagingType, @vCartonType, @vCarrierInterface);

      select @vCartonDetailsxml = dbo.fn_Shipping_GetCartonDetails(@vLPNId, @vCartonType, @vPackagingType, @vBusinessUnit);

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'GetCommoditiesInfo_Start';

      /* CIMSSI is expecting commodities in package level */
      if (@RequestedBy = 'CIMSSI')
        exec pr_Shipping_GetCommoditiesInfo @vLPNId, @vBusinessUnit, null /* UserId */, @vCommoditiesxml output;

      /* TODO: Need discussions on Multiple shipments */
      if (@vCN22LabelRequired = 'Y')
        exec pr_Shipping_GetCN22Info @vLPNId, @vCN22InfoXML output;

      /* Commercial Invoice */
      if (@vCIFormRequired = 'Y' /* Yes */)
        /* Build the Commercial Invoice Form XML - Required for International shipments */
        exec pr_Shipping_GetCommercialInvoiceInfo @vLPNId, @vSaveCIFormInDB, @vCIInfoXML output;

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'BuildReferences_Start';

      /* Build the references XML */
      exec pr_Shipping_BuildReferences @vCarrier, @vSoldToId, @vLPN, @vSalesOrder, @vPickTicket, @vUCCBarcode, @vCustPO, @vPurchaseOrder, @vDesiredShipDate,  @vCarrierInterface, @vBusinessUnit,
                                       @vReferencexml output;

      /* Build the addition fields for the carriers */
      exec pr_Shipping_BuildAdditionalFields @xmlRulesData, @vAdditionalFieldsxml output;

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'RequestPACKAGE_XMLBuild_Start';

      /* Build the Pacakge XML */
      set @vRequestPackagesxml = @vRequestPackagesxml + '<PACKAGE>' +
                                                           coalesce(@vLPNHeaderxml,        '') +
                                                           coalesce(@vLPNDetailsxml,       '') +
                                                           coalesce(@vCartonDetailsxml,    '') +
                                                           coalesce(@vCommoditiesxml,      '') + --This will be obsolete after SI enhanced to read it from REQUEST node or all clients upgraded to API
                                                           coalesce(@vReferencexml,        '') +
                                                           coalesce(@vAdditionalFieldsxml, '') +
                                                        '</PACKAGE>'

      if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'ResponsePACKAGE_XMLBuild_Start';

      set @vResponsePackagesxml = @vResponsePackagesxml + '<PACKAGE>' +
                                                             dbo.fn_XMLNode('CONTAINERID',   @vLPNId) +
                                                             dbo.fn_XMLNode('CONTAINER',     @vLPN) +
                                                             dbo.fn_XMLNode('IMAGELABEL',    'Image Label Here') +
                                                             dbo.fn_XMLNode('ZPLIMAGELABEL', 'ZPL Label Here') +
                                                             dbo.fn_XMLNode('TRACKINGNO',    'Tracking Number here') +
                                                             dbo.fn_XMLNode('TRACKINGBARCODE', 'Tracking Barcode here') +
                                                             dbo.fn_XMLNode('CARRIER',       'Carrier here') +
                                                             dbo.fn_XMLNode('SHIPVIA',       'Ship Via here') +
                                                          '</PACKAGE>'

    end /* While end */

  select @vRequestPackagesxml  = dbo.fn_XMLNode('PACKAGES', coalesce(@vRequestPackagesxml,  '')),
         @vResponsePackagesxml = dbo.fn_XMLNode('PACKAGES', coalesce(@vResponsePackagesxml, ''));

  /* This is the RESPONSE Skeleton expected from the Interface Layer
     There could be multiple different options which the Carrier Web Services can return and
     when we call the web service, we expect to read the following information from the web service response
     and return back to the caller, either to save it in the DB (as in our case) or to do any other process as the case may be */

  select @vShipLabelLogging    = dbo.fn_Controls_GetAsString('Shipping', 'UPSShipLabelLogging',    'N', @vBusinessUnit, @vUserId)

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Response_XMLBuild_Start';

  set @vResponsexml = @vResponsePackagesxml +
                      /* Do not send any value to LabelType as while saving, it could be a problem if same value returns */
                      dbo.fn_XMLNode('LABELTYPE', '') +
                      dbo.fn_XMLNode('RATE', 'Rate here') +
                      dbo.fn_XMLNode('LISTNETCHARGES', 'List Net Changes') +
                      dbo.fn_XMLNode('ACCTNETCHARGES', 'Actual Net Changes') +
                      dbo.fn_XMLNode('ISDEBUG', case when @vShipLabelLogging = 'Y' then 'true' else 'false' end) +
                      dbo.fn_XMLNode('ROUTECODE', 'Route code here') +
                      dbo.fn_XMLNode('NOTIFICATIONS', 'NOTIFICATIONS here') +
                      dbo.fn_XMLNode('Message', 'Messages here') +
                      dbo.fn_XMLNode('REFERENCES', 'References here')

  select '<SHIPPINGINFO>' +
           '<REQUEST>' +
             coalesce(@vOrderHeaderxml,     '') +
             coalesce(@vOrderDetailsxml,    '') +
             coalesce(@vShipFromxml,        '') +
             coalesce(@vSoldToxml,          '') +
             coalesce(@vSoldToAddressxml,   '') +
             coalesce(@vShipToxml,          '') +
             coalesce(@vShipToAddressxml,   '') +
             coalesce(@vBillToAddressxml,   '') +
             coalesce(@vReturnAddressxml,   '') +
             coalesce(@vShippingAccountxml, '') +
             coalesce(@vServiceDetailxml,   '') +
             coalesce(@vShipViaxml,         '') +
             coalesce(@vLabelAttributesxml, '') +
             coalesce(@vSpecialServicesxml, '') +
             coalesce(@vCustomsxml,         '') +
             coalesce(@vAdditionalShippingDocs, '') +   /* Invoice, CN22, CoO forms etc */
             coalesce(@vCN22InfoXML,            '') +
             coalesce(@vCIInfoXML,              '') +
             coalesce(@vCommoditiesInfoxml,     '') +
             coalesce(@vRequestPackagesxml, '') +
           '</REQUEST>' +
           '<RESPONSE>' +
             coalesce(@vResponsexml, '') +
           '</RESPONSE>' +
         '</SHIPPINGINFO>' as result

  if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'pr_Shipping_GetShipmentData_End';

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'Shipping', @LPNId, @LPN, 'GetShipmentData', @@ProcId, 'Markers_GetShipmentData';

ErrorHandler:
  if (@MessageName is not null)
    begin
      select @Message = dbo.fn_Messages_Build(@MessageName, null, null, null, null, null);

      /* If there is no Entity is available in ShipLabels table insert with message, other wise update with error and Process status */
      if (not exists(select EntityKey from ShipLabels where EntityKey = @LPN))
        insert into Shiplabels (EntityId, EntityKey, OrderId, PickTicket, WaveId, WaveNo, ShipVia, Carrier, CarrierInterface, TrackingNo, ProcessStatus, Notifications, BusinessUnit)
          select @LPNId, @LPN, @vOrderId, @vPickTicket, @vWaveId, @vWaveNo, @vShipVia, @vCarrier, @vCarrierInterface, '', 'LGE' /* Label Generation Error */, @Message, @vBusinessUnit;
      else
        update S
        set S.Notifications = @Message,
            S.ProcessStatus = 'LGE' /* Label Generation Error */
        from ShipLabels S
        where (EntityKey = @LPN);

      exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;
    end
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_GetShipmentData */

Go
