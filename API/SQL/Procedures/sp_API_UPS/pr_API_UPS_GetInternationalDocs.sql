/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/07  RV      pr_API_UPS_GetInternationalDocs: Made changes to send the TermsOfShipment (BK-911)
  2021/08/02  OK      pr_API_UPS_GetInternationalDocs: Changes to use hash table ehich is populated by GetShipmentData (BK-382)
  2021/07/28  OK      pr_API_UPS_GetInternationalDocs: Developed to return the JSON data which is required for International shipping documents,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetInternationalDocs') is not null
  drop Procedure pr_API_UPS_GetInternationalDocs;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetInternationalDocs:
  This proc returns the JSON with required additional international shipment documents.
  Ref: https://vsvn.foxfireindia.com:8443/svn/sct/cIMS3.0/branches/Dev3.0/Documents/Manuals/Developer%20Manuals/UPS Shipping Package RESTful Developer Guide.pdf
  Page No: 48
  01 - Invoice
  03 - CO
  04 - NAFTA CO
  05 - Partial Invoice
  06 - Packinglist
  07 - Customer Generated Forms
  08 - Air Freight Packing List
  09 - CN22 Form
  10 - UPS Premium Care Form
  11 - EEI

  TermsOfShipment:
  Page No: 69
  Valid values:
  CFR: Cost and Freight; CIF: Cost Insurance and Freight; CIP: Carriage and Insurance Paid; CPT: Carriage Paid To;
  DAF: Delivered at Frontier; DDP: Delivery Duty Paid; DDU: Delivery Duty Unpaid; DEQ: Delivered Ex Quay;
  DES: Delivered Ex Ship; EXW: Ex Works; FAS: Free Alongside Ship; FCA: Free Carrier; FOB: Free On Board

  ReasonForExport:
  SALE, GIFT, SAMPLE, return, REPAIR, INTERCOMPANYDATA, Any other reason.

  Sample output:
  "InternationalForms":[
      {
         "FormType":"01",
         "InvoiceDate":"20210525",
         "Product":{
            "Description":"SKU Description",
            "Unit":{
               "Number":"01",
               "UnitOfMeasurement":{
                  "Code":"EA"
               },
               "Value":"25"
            },
            "OriginCountryCode":"US"
         },
         "ReasonForExport":"SALE",
         "CurrencyCode":"USD",
         "Contacts":{
            "SoldTo":{
               "Name":"CANADA OMNI CAO\/OLD NAVY INC.",
               "AttentionName":"CANADA OMNI CAO\/OLD NAVY INC.",
               "Phone":{
                  "Number":"9958745741"
               },
               "Address":{
                  "AddressLine":"9500 MCLAUGHLIN ROAD N",
                  "City":"BRAMPTON,",
                  "StateProvinceCode":"ON",
                  "PostalCode":"L6V1A1",
                  "CountryCode":"MX"
               }
            }
         }
      },
      {
         "FormType":"09",
         "InvoiceDate":"20210525",
         "Product":{
            "Description":"SKU Description",
            "Unit":{
               "Number":"01",
               "UnitOfMeasurement":{
                  "Code":"EA"
               },
               "Value":"25"
            },
            "OriginCountryCode":"US"
         },
         "ReasonForExport":"SALE",
         "CurrencyCode":"USD",
         "Contacts":{
            "SoldTo":{
               "Name":"CANADA OMNI CAO\/OLD NAVY INC.",
               "AttentionName":"CANADA OMNI CAO\/OLD NAVY INC.",
               "Phone":{
                  "Number":"9958745741"
               },
               "Address":{
                  "AddressLine":"9500 MCLAUGHLIN ROAD N",
                  "City":"BRAMPTON,",
                  "StateProvinceCode":"ON",
                  "PostalCode":"L6V1A1",
                  "CountryCode":"MX"
               }
            }
         }
      }
   ]
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetInternationalDocs
  (@InputXML              xml,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @InternationalDocsJSON TNVarchar output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,

          @vCommercialInvoiceRequired TFlag,
          @vCN22Required              TNVarChar,
          @vCustPO                    TCustPO,
          @vCurrency                  TTypeCode,
          @vTermsOfShipment           TDescription,
          @vReasonForExport           TDescription,

          @vCommoditiesInfoJSON       TNVarChar,
          @vSoldToAddressJSON         TNVarChar;

begin /* pr_API_UPS_GetInternationalDocs */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0,
         @InternationalDocsJSON = '';

  /* Get additional document requirement */
  select @vCommercialInvoiceRequired = Record.Col.value('(COMMERCIALINVOICE)[1]',    'TFlag'),
         @vCN22Required              = Record.Col.value('(CN22)[1]',                 'TFlag')
  from @InputXML.nodes('/SHIPPINGINFO/REQUEST/ADDITIONALSHIPPINGDOCS') Record(Col)
  OPTION (OPTIMIZE FOR (@InputXML = null));

  if (@vCommercialInvoiceRequired = 'Y' /* Yes */)
    begin
      select @vCurrency        = Record.Col.value('(CUSTOMS/Currency)[1]',  'TTypeCode'),
             @vTermsOfShipment = Record.Col.value('(CIINFO/Terms)[1]',      'TDescription'),
             @vReasonForExport = Record.Col.value('(CIINFO/Purpose)[1]',    'TUDF')
      from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
      OPTION (OPTIMIZE FOR (@InputXML = null));

      select @vCurrency  = coalesce(@vCurrency, 'USD'),
             @vReasonForExport = iif(@vReasonForExport = 'Sold', 'SALE', coalesce(@vReasonForExport, 'SALE')),
             @vTermsOfShipment = upper(replace(@vTermsOfShipment, 'cit', ''));

      select @vCommoditiesInfoJSON = (select [Description]                  = Description,
                                             [Unit.Number]                  = cast(Quantity as varchar),
                                             [Unit.UnitOfMeasurement.Code]  = QuantityUoM,
                                             [Unit.Value]                   = cast(UnitPrice as varchar),
                                             [CommodityCode]                = HTSCode,
                                             [PartNumber]                   = SKU,
                                             [NumberOfPackagesPerCommodity] = NumberOfPieces,
                                             [ProductWeight.Weight]         = cast(UnitWeight as numeric(5,1)),
                                             [ProductWeight.UnitOfMeasurement.Code] = 'LBS',
                                             [OriginCountryCode]            = coalesce(CoO, 'US')
                                      from #CommoditiesInfo
                                      FOR JSON PATH);

      /* Build Sold To Address json */
      exec pr_API_UPS_GetShipToAddress @InputXML, @BusinessUnit, @UserId, @vSoldToAddressJSON out;

      /* Build required format */
      select @InternationalDocsJSON = '
        "InternationalForms": {
             "AdditionalDocumentIndicator":  ""'                                           +',
             "FormType":                     "01"'                                         +',
             "InvoiceDate":'               + '"' + format(getdate(), 'yyyyMMdd') + '"'     +',
             "Product":'                   + JSON_QUERY(@vCommoditiesInfoJSON)             +',
             "PurchaseOrderNumber":'       + '"' + coalesce(@vCustPO, '') + '"'            +',
             "TermsOfShipment":'           + '"' + @vTermsOfShipment + '"'                 +',
             "ReasonForExport":'           + '"' + @vReasonForExport + '"'                 +',
             "CurrencyCode":'              + '"' + @vCurrency + '"'                        +',
             "Contacts": {
                  "SoldTo" :'              + JSON_QUERY(@vSoldToAddressJSON)              +'}
        }
      '
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetInternationalDocs */

Go
