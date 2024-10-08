/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/06  RV      pr_Shipping_GetLPNData: Bug fixed to populate data in hash table (BK-572)
  2021/05/20  TK      pr_Shipping_GetLPNData: Generate UCCBarcode if value is null (HA-2816)
  2020/06/25  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Included the ZPLIMAGELABEL to fill while create shipment
                        pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Get the ZPLIMAGELABEL and save in ShipLabels table,
                        if label image type other than ZPL (HA-854)
  2020/02/24  YJ      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData, pr_Shipping_RegenerateTrackingNumbers,
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_ValidateToShip,
                      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2019/11/26  HYP     pr_Shipping_SaveShipmentData/pr_Shipping_SaveLPNData and pr_Shipping_GetShipmentData/ pr_Shipping_GetLPNData:
                        Made changes to capture TrackingBarcode (FB-1546)
  2019/09/05  VS      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Made changes to do not round the PackageWeight value for USPSF ShipVia (CID-1017)
  2019/02/26  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Enabled future ship date enabled by PK on request by client
  2019/02/15  RV      pr_Shipping_GetLPNData: Made changes to validate whether the shipment already created or not
                        pr_Shipping_GetShipmentData: Made changes exclude LPNs, which are already created shipment for PickTicket
                        and added validation for LPN if already shipment created (S2G-1198)
  2019/01/18  RV      pr_Shipping_GetLPNData,pr_Shipping_GetShipmentData: Made changes to retun ManifestAction based on the rules
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData: Made changes to update the CarrierInterface (S2GCA-434)
  2018/11/19  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Made changes to send SPG shipment type based on the rules (S2G-1170)
  2018/11/16  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Made changes to get the future ship date
                        from Waves and included in OrderHeaders xml (S2G-1163)
  2018/09/17  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Stuff Carrier Interface with newly evaluated value to get the
                        label image type and label rotation (S2GCA-260)
  2018/09/03  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Made changes to add IsSmallPackageCarrier
                        to the rules data (S2GCA-236)
  2018/08/29  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData, pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData,
                      pr_Shipping_VoidShipLabels: Made changes to decide whether the shipment is small package carrier or not from
                        IsSmallPackageCarrier flag from ShipVias table (S2GCA-131)
  2018/05/18  TK/RV   pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Use function to get carton details xml
                      fn_Shipping_GetCartonDetails: Initial revision (S2G-800)
  2018/05/11  PM      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData:Updated registered AES number for FedEx/UPS on the international orders(S2G-602)
  2018/04/26  RV      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Made changes to send rotation value to rotate
                        the small package label to print ship label properly on the packing list (S2G-699)
  2018/02/21  RV      pr_Shipping_GetShipmentData: Few of the migrated from OB Prod. Added validation for valid LPN or PickTicket.
                      pr_Shipping_GetShipmentData,pr_Shipping_GetLPNData: Insert/update the carton into the shiplabel table while raising error
                      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Process error status changed Error (E) to Label Generation Error (LGE)
  2018/02/09  RV      pr_Shipping_GetShipmentData, pr_Shipping_GetLPNData: Get ShipVias with respect to the BusinessUnit (S2G-110)
  2018/02/01  RV      pr_Shipping_GetShipmentData, pr_Shipping_GetLPNData: Get the Label image type (ZPL/PNG) from rules and retun in Request xml to
                        get the ZPL/PNG
                      pr_Shipping_SaveShipmentData, pr_Shipping_SaveLPNData: Save Label image and ZPL save appropriate column (HPI-113)
  2017/09/25  VM      pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData: Use vwContacts for ShipFromAddress (OB-576)
  2017/04/11  NB      Modified pr_Shipping_BuildReferences (CIMS-1259)
                        for reading ADSI specific reference controls
                      Modified pr_Shipping_GetShipmentData - changes to
                        read mapping for CarrierPackagingType
                      Modified pr_Shipping_GetLPNData - added changes from
                        pr_Shipping_GetShipmentData for Carrier Interface handling
  2017/03/22  NB      Modified pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData (CIMS-1259)
                        to read CarrierInterface from rules, return CarrierInterface in XML.
                        Added new Carrier, ShipVia nodes in Response xml structure
                      Modified pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData
                        to read Carrier and ShipVia from Response, and update to ShipLabels.ShippingDetail
  2017/01/17  NB      Modified pr_Shipping_GetLPNData, pr_Shipping_GetShipmentData to read SpecialServices
                        from ShipVia details(HPI-1270)
  2016/11/24  KN      pr_Shipping_GetLPNData , pr_Shipping_GetShipmentData optimized code (HPI-1032)
  2016/11/10  KN      pr_Shipping_GetLPNData , pr_Shipping_GetShipmentData debugging is set based on control variable (HPI-1032)
  2016/05/09  YJ      pr_Shipping_GetLPNData: Used temp table to fetch Commodities information (CIMS-927)
  2016/04/26  RV      pr_Shipping_ValidateToShip: Added an optional and output parameter to return Message Name.
                      pr_Shipping_GetLPNData: Validate the shipping details and get the Shipping Account details by calling the pr_Shipping_ValidateToShip (NBD-384)
  2016/04/20  RV      pr_Shipping_GetLPNData: Ceiling the Actual Weight when ShipVia is USPS to avoid the USPS shipping errors (NBD-390)
  2016/04/12  TK      pr_Shipping_GetLPNData: Consider UnitSalePrice if RetailUnitPrice is zero (NBD-379)
  2016/02/26  TK      pr_Shipping_GetLPNData: Enhanced to retrieve Shipping Account Details based upon Rules
                      pr_Shipping_ValidateToShip: Enhanced to use rules to evalute Shipping Account Details
              AY      pr_Shipping_GetShippingAccountDetails: Added (LL-276)
  2015/09/18  PK      pr_Shipping_GetLPNData: Building Commodities section to ship international orders - WIP (FB-404)
  2015/05/22  RV      pr_Shipping_SaveLPNData: Split the Notification and insert/update to respective fields
              DK      pr_Shipping_GetLPNData: Modified to send USPSEndorsement and PackageWeight.
  2015/05/14  DK      pr_Shipping_GetLPNData: Modified to get CarrierPackagingType from Shipvias.
  2015/04/20  DK      pr_Shipping_GetLPNData, pr_Shipping_SaveLPNData: Made changes to get ShipVia from LPNs if Order Shipvia is not specified.
  2015/04/14  DK      pr_Shipping_GetLPNData: Made changes to send the ServiceDetails
  2011/10/09  AY      pr_Shipping_GetLPNData: Changed to use views for Soldto/ShipTo addresses
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetLPNData') is not null
  drop Procedure pr_Shipping_GetLPNData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetLPNData:
       Returns the Shipping Information for a given LPN or LPNId
       This is currently used to call the Carrier Shipping API to create a
       shipment in the carrier system for USPS and DHL

  The Information is sent back as an XML String with the following structure
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetLPNData
  (@LPN   TLPN      = null,
   @LPNId TRecordId = null)
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
          @vSpecialServicesxml varchar(max),
          @vResponsexml        varchar(max),
          @vReferencexml       varchar(max),
          @vCustomsxml         varchar(max),
          @vCommoditiesxml     varchar(max),
          @vServiceDetailxml   varchar(max),
          @xmlRulesData        varchar(max),
          @vShipLabelLogging   TFlags,

          /* Order Info */
          @vSoldToId           TCustomerId,
          @vShipToId           TShipToId,
          @vBillToAddress      TContactRefId,
          @vReturnAddress      TReturnAddress,
          @vIsSmallPackageCarrier
                               TFlag,
          @vShipVia            TShipVia,
          @vCarrierServiceCode varchar(50),
          @vCarrierServiceCodeMapping
                               TDescription,
          @vShipViaPackagingType
                               TVarchar,
          @vSPGShipmentType    TFlag,
          @vShipFrom           TShipFrom,
          @vManifestAction     TDescription,
          @vWaveShipDate       TDateTime,
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
          /* LPN Info */
          @vLPN                TLPN,
          @vCartonType         TCartonType,
          @vPackagingType      TDescription,
          @vCustomerContactId  TRecordId,
          @vShipToContactId    TRecordId,
          @vUCCBarcode         TBarcode,
          @vValue              TMoney,
          /* Carrier Info */
          @vCarrier            TCarrier,
          @vCarrierRulexmlData varchar(max),
          @vCarrierInterface   TCarrierInterface,
          @vImageLabelType     TTypeCode,
          @vLabelRotation      TDescription,
          @vIsValidTrackingNo  TFlag,
          @vStandardAttributes TVarChar,
          @vSpecialServices    TVarChar,

          /* PO Info */
          @vPurchaseOrder      TReceiptType;
  declare @ttLPNShipLabelData  TLPNShipLabelData,
          @ttLPNs              TEntityKeysTable;
begin /* pr_Shipping_GetLPNData */
  select @ReturnCode  = 0,
         @Messagename = null,
         @Message     = null;
  select * into #ttLPNs from @ttLPNs;
  select * into #LPNShipLabels from @ttLPNShipLabelData;
  alter table #LPNShipLabels add ShipFrom           varchar(50),
                                 LabelFormatName    varchar(128),
                                 RecordId           integer;

  if (@LPNId is null)
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN);

  if (@LPNId is null)
    set @MessageName = 'LPNDoesNotExist';

  select @vOrderId           = L.OrderId,
         @vCartonType        = L.CartonType,
         @vLPN               = L.LPN,
         @vUCCBarcode        = L.UCCBarcode,
         @vBusinessUnit      = L.BusinessUnit,
         @vPurchaseOrder     = L.ReceiptNumber,
         @vIsValidTrackingNo = SL.IsValidTrackingNo
  from LPNs L
    left join ShipLabels SL on (SL.EntityKey = L.LPN) and (SL.BusinessUnit = L.BusinessUnit) and
                               (SL.Status = 'A' /* Active */)
  where (L.LPNId = @LPNId);

  if (@vUCCBarcode is null)
    begin
      /* Get all the LPNs to geneate UCC bacrcodes */
      insert into #LPNShipLabels (LPNId) select @LPNId;

      /* generate uccbarcode for the generated TempLabels */
      exec pr_ShipLabel_GenerateUCCBarcodes @vUserId, @vBusinessUnit;
    end

  /* Already LPN have valid shipment then no need to create shipment again */
  if (@vIsValidTrackingNo = 'Y' /* Yes */)
    set @MessageName = 'LPNHasValidShipment';

  select @vSoldToId        = SoldToId,
         @vShipToId        = ShipToId,
         @vBillToAddress   = BillToAddress,
         @vReturnAddress   = ReturnAddress,
         @vShipVia         = ShipVia,
         @vShipFrom        = ShipFrom,
         @vCustPO          = CustPO,
         @vSalesOrder      = SalesOrder,
         @vPickTicket      = PickTicket,
         @vOrderType       = OrderType,
         @vDesiredShipDate = DesiredShipDate,
         @vAccount         = Account,
         @vAccountName     = AccountName,
         @vOrderCategory1  = OrderCategory1,
         @vOrderCategory2  = OrderCategory2,
         @vWaveId          = PickBatchId,
         @vOwnership       = Ownership,
         @vWarehouse       = Warehouse,
         @vOH_UDF6         = UDF6
  from OrderHeaders
  where (OrderId = @vOrderId);

  select @vWaveNo         = WaveNo,
         @vWaveType       = WaveType,
         @vWaveShipDate = ShipDate /* Enabled it on 02/15/2019 on request by client */
  from Waves
  where (WaveId = @vWaveId);

  /* Get Customer AddressId */
  select @vCustomerContactId = CustomerContactId
  from Customers
  where (CustomerId = @vSoldToId);

  /* Get ShipToAddressId */
  select @vShipToContactId = ShipToAddressId
  from ShipTos
  where (ShipToId = @vShipToId);

  select @vCarrier               = Carrier,
         @vShipViaPackagingType  = PackagingType,
         @vCarrierServiceCode    = CarrierServiceCode,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier,
         @vStandardAttributes    = StandardAttributes,
         @vSpecialServices       = SpecialServices
  from vwShipVias
  where (ShipVia = @vShipVia);

  if (@vIsSmallPackageCarrier = 'Y' /* Yes */)
    exec pr_Shipping_ValidateToShip null /* LoadId */, @vOrderId, null /* PalletId */, @LPNId, @Message output, @MessageName output, @vShippingAccountxml output;

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Build data for Rules evaluation */
  select @xmlRulesData = '<RootNode>' +
                            dbo.fn_XMLNode('OrderId',                @vOrderId) +
                            dbo.fn_XMLNode('PickTicket',             @vPickTicket) +
                            dbo.fn_XMLNode('SalesOrder',             @vSalesOrder) +
                            dbo.fn_XMLNode('OrderType',              @vOrderType) +
                            dbo.fn_XMLNode('OrderCategory1',         @vOrderCategory1) +
                            dbo.fn_XMLNode('OrderCategory2',         @vOrderCategory2) +
                            dbo.fn_XMLNode('LPNId',                  @LPNId) +
                            dbo.fn_XMLNode('ShipToId',               @vShipToId) +
                            dbo.fn_XMLNode('SoldToId',               @vSoldToId) +
                            dbo.fn_XMLNode('Carrier',                @vCarrier) +
                            dbo.fn_XMLNode('CarrierInterface',       '') +
                            dbo.fn_XMLNode('IsSmallPackageCarrier',  @vIsSmallPackageCarrier) +
                            dbo.fn_XMLNode('ShipVia',                @vShipVia) +
                            dbo.fn_XMLNode('Account',                @vAccount) +
                            dbo.fn_XMLNode('AccountName',            @vAccountName) +
                            dbo.fn_XMLNode('WaveNo',                 @vWaveNo) +
                            dbo.fn_XMLNode('WaveType',               @vWaveType) +
                            dbo.fn_XMLNode('Ownership',              @vOwnership) +
                            dbo.fn_XMLNode('Warehouse',              @vWarehouse) +
                            dbo.fn_XMLNode('ShipFrom',               @vShipFrom) +
                         '</RootNode>'

  /* Determine which integration we are going to use ie. Direct with UPS/FedEx or ADSI */
  exec pr_RuleSets_Evaluate 'CarrierInterface', @xmlRulesData, @vCarrierInterface output, null /* RuleId */, 'Y' /* Stuff in Rules data */;
  select @vCarrierInterface = coalesce(@vCarrierInterface, 'DIRECT') -- If no rules are defined, then use DIRECT option as carrier interface

  exec pr_RuleSets_Evaluate 'CreateSPGShipment', @xmlRulesData, @vSPGShipmentType output;

  if (@vCarrierInterface = 'ADSI') /* why ? */
    begin
      exec pr_Shipping_GetShipmentData @LPN, @LPNId;
      goto Exithandler;
    end

  exec pr_RuleSets_Evaluate 'ManifestAction', @xmlRulesData, @vManifestAction output;

  /* Build XML with ALL possible info that might be needed for a Shipping Integration */

  set @vLPNHeaderxml     = (select *,
                                   (case when @vShipViaPackagingType = 'Irregulars' then LPNWeight
                                         when @vShipVia not in ('USPSF') and @vShipVia like 'USPS%' then ceiling(LPNWeight) /* Temporary fix to ceiling actual weight to avoid the USPS less weight errors while actual weight is less than 1*/
                                         else LPNWeight end) as PackageWeight
                            from LPNs
                            where LPNId = @LPNId
                            for xml raw('LPNHEADER'), elements);

  /* Nothing in LPNDetails is required for the purpose of generating Carrier Label
     but instead of dropping it altogether just limiting to one record */
  set @vLPNDetailsxml    = (select top 1 * from LPNdetails
                            where LPNId = @LPNId
                            for xml raw('LPNDETAIL'), elements);

  set @vOrderHeaderxml   = (select *, @vCarrierInterface as CarrierInterface,
                                      @vWaveShipDate FutureShipDate, @vManifestAction ManifestAction, @vSPGShipmentType as SPGShipmentType
                            from OrderHeaders
                            where OrderId = @vOrderId
                            for xml raw('ORDERHEADER'), elements);

  /* Nothing in OrderDetail is required for the purpose of generating Carrier Label
     but instead of dropping it altogether just limiting to one record */
  set @vOrderDetailsxml  = (select top 1 * from OrderDetails
                            where OrderId = @vOrderId
                            for xml raw('ORDERDETAIL'), elements);

  set @vShipFromxml      = (select * from vwContacts
                            where (ContactRefId = @vShipFrom) and
                                  (ContactType = 'F' /* Ship From */)
                            for xml raw('SHIPFROM'), elements);

  /* Why is this required for carrier integration? */
  set @vSoldToxml        = (select * from Customers CUST
                            where (CUST.CustomerId = @vSoldToId)
                            for xml raw('SOLDTO'), elements );

  set @vSoldToAddressxml = (select * from vwSoldToAddress
                            where (SoldToId = @vSoldToId)
                            for xml raw('SOLDTOADDRESS'), elements);

  /* Why is this required for carrier integration? */
  set @vShipToxml        = (select * from ShipTos SHTO
                            where (SHTO.ShipToId = @vShipToId)
                            for xml raw('SHIPTO'), elements );

  set @vShipToAddressxml = (select * from dbo.fn_Contacts_GetShipToAddress (@vOrderId, @vShipToId)
                            for xml raw('SHIPTOADDRESS'), elements );

  set @vBillToAddressxml = (select * from Contacts
                            where (ContactRefId = @vBillToAddress) and
                                  (ContactType = 'B' /* BillTo Address */)
                            for xml raw('BILLTOADDRESS'), elements );

  /* Why is this required for carrier integration? */
  set @vReturnAddressxml = (select * from Contacts
                            where (ContactRefId = @vReturnAddress) and
                                  (ContactType = 'R' /* Return Address */)
                            for xml raw('RETURNADDRESS'), elements );

  /* Get the packaging type based upon service and cartontype used. see GetPackagingType function for more details */
  select @vPackagingType    = dbo.fn_Shipping_GetPackagingType(@vShipViaPackagingType, @vCartonType, @vCarrierInterface);
  select @vCartonDetailsxml = dbo.fn_Shipping_GetCartonDetails(@LPNId, @vCartonType, @vPackagingType, @vBusinessUnit);

  /* access ship service details table and get the label details based on shipvia */
  set @vShipViaxml = dbo.fn_XMLNode('SHIPVIA', @vStandardAttributes);

  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'CarrierInterface', @vCarrierInterface);

  /* Get the LabelImageTypes to use */
  exec pr_RuleSets_Evaluate 'ShipLabelImageTypes', @xmlRulesData, @vImageLabelType output;

  /* Get the Label Rotation */
  exec pr_RuleSets_Evaluate 'ShipLabelRotation', @xmlRulesData, @vLabelRotation output;

  set @vLabelAttributesxml = dbo.fn_XMLNode('LABELATTRIBUTES',
                               dbo.fn_XMLNode('LabelImageType', @vImageLabelType) +
                               dbo.fn_XMLNode('LabelRotation',  @vLabelRotation));

  /* Read Special Services from ShipVia record */
  set @vSpecialServicesxml =  dbo.fn_XMLNode('SPECIALSERVICES', @vSpecialServices);

  /* Gather info for Customs */
  select @vValue = sum(LD.Quantity * coalesce(nullif(OD.RetailUnitPrice, 0), OD.UnitSalePrice)) --we are getting RetailUnitPrice as zero
  from LPNDetails LD join OrderDetails OD on LD.OrderId = OD.OrderId and LD.OrderDetailId = OD.OrderDetailId
  where (LPNId = @LPNId);

  /* Send the default value to pass in a $1 instead of sending 0 to avoid errors from UPS/FedEx */
  select @vValue = case when @vValue < 1 then 1 else @vValue end;

  set @vCustomsxml = '<CUSTOMS>' +
                       '<VALUE>' + cast(@vValue as varchar) + '</VALUE>' +
                       '<CURRENCY>' + 'USD' + '</CURRENCY>' +
                     '</CUSTOMS>';

  /* Insert LPN information into temp table to get the commodities for that LPN */
  delete from #ttLPNs;
  insert into #ttLPNs(EntityId) select @LPNId;
  exec pr_Shipping_GetCommoditiesInfo @LPNId, @vBusinessUnit, null /* UserId */, @vCommoditiesxml output;

  /* Following values are hardcoded need to update as per client requirement*/
  /*Todo: This values must be returned based on rules*/
  set @vServiceDetailxml = '<SERVICEDETAILS>' +
                             '<MICostCenter>' + @vCustPO     + '</MICostCenter>' +
                             '<MIPackageID>'  + @vSalesOrder + @vLPN + '</MIPackageID>' +
                             '<MailerId>'     + '924912333'  + '</MailerId>' +
                             '<USPSEndorsement>' + '1' +  '</USPSEndorsement>' +
                            '</SERVICEDETAILS>';

  /* Build the references */
  exec pr_Shipping_BuildReferences @vCarrier, @vSoldToId, @vLPN, @vSalesOrder, @vPickTicket, @vUCCBarcode, @vCustPO, @vPurchaseOrder, @vDesiredShipDate,  @vCarrierInterface, @vBusinessUnit,
                                   @vReferencexml output;

  select @vShipLabelLogging    = dbo.fn_Controls_GetAsString('Shipping', 'FedexShipLabelLogging',    'N', @vBusinessUnit, @vUserId)

  /* This is the RESPONSE Skeleton expected from the Interface Layer
     There could be multiple different options which the Carrier Web Services can return and
     when we call the web service, we expect to read the following information from the web service response
     and return back to the caller, either to save it in the DB (as in our case) or to do any other process as the case may be */
  set @vResponsexml = dbo.fn_XMLNode('IMAGELABEL',      'Image Label Here') +
                      dbo.fn_XMLNode('ZPLIMAGELABEL',   'ZPLImage Label Here') +
                      dbo.fn_XMLNode('TRACKINGNO',      'Tracking Number here') +
                      dbo.fn_XMLNode('RATE',            'Rate here') +
                      dbo.fn_XMLNode('SHIPPINGCHARGES', 'Shipping Charges here') +
                      dbo.fn_XMLNode('ISDEBUG', case when @vShipLabelLogging = 'Y' then 'true' else 'false' end) +
                      dbo.fn_XMLNode('ROUTECODE',       'Route code here') +
                      dbo.fn_XMLNode('NOTIFICATIONS',   'Messages here') +
                      dbo.fn_XMLNode('REFERENCES',      'References here') +
                      dbo.fn_XMLNode('CARRIER',         'Carrier here') +
                      dbo.fn_XMLNode('SHIPVIA',         'Ship Via here')
                      ;

  select '<SHIPPINGLPNINFO>' +
           '<REQUEST>' +
             coalesce(@vLPNHeaderxml,       '') +
             coalesce(@vLPNDetailsxml,      '') +
             coalesce(@vOrderHeaderxml,     '') +
             coalesce(@vOrderDetailsxml,    '') +
             coalesce(@vShipFromxml,        '') +
             coalesce(@vSoldToxml,          '') +
             coalesce(@vSoldToAddressxml,   '') +
             coalesce(@vShipToxml,          '') +
             coalesce(@vShipToAddressxml,   '') +
             coalesce(@vBillToAddressxml,   '') +
             coalesce(@vReturnAddressxml,   '') +
             coalesce(@vCartonDetailsxml,   '') +
             coalesce(@vShippingAccountxml, '') +
             coalesce(@vShipViaxml,         '') +
             coalesce(@vLabelAttributesxml, '') +
             coalesce(@vSpecialServicesxml, '') +
             coalesce(@vCustomsxml,         '') +
             coalesce(@vCommoditiesxml,     '') +
             coalesce(@vServiceDetailxml,   '') +
             coalesce(@vReferencexml,       '') +
           '</REQUEST>' +
           '<RESPONSE>' +
             coalesce(@vResponsexml, '') +
           '</RESPONSE>' +
         '</SHIPPINGLPNINFO>' as result

ErrorHandler:
  if (@MessageName is not null)
    begin
      /* Build message if invalid data is present */
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
end /* pr_Shipping_GetLPNData */

Go
