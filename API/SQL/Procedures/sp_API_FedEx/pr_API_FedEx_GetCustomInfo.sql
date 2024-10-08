/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_GetCustomInfo') is not null
  drop Procedure pr_API_FedEx_GetCustomInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_GetCustomInfo: Returns the CustomInfo in XML Format for FEDEX.

------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_GetCustomInfo
  (@ShipmentInfoXML        XML,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @CustomsClearanceDetail TVarchar output)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vAccountNumber            TAccount,
          @vMeterNumber              TMeterNumber,
          @vCurrency                 TVarChar,
          @vAmount                   TMoney,
          @vNumberOfPieces           TQuantity,
          @vDescription              TDescription,
          @vCountryOfManufacture     TCoO,
          @vQuantity                 TQuantity,
          @vQuantityUnits            TUoM,
          @vUnits                    TUoM,
          @vValue                    TQuantity,
          @vFreightTerms             TDescription,
          @vShipperAccount           TAccount,
          @vBillToAccount            TAccount,
          @vPayorType                TDescription,
          @vPayorAccount             TAccount,
          @vPersonName               TName,
          @vContactId                TRecordId,
          @vCustomsValue             TVarchar,
          @vUnitPrice                TVarchar,
          @vWeight                   TVarchar,
          @vDutiesPayment            TVarchar,
          @vContact                  TVarchar,
          @vCommodities              TVarchar;

begin /* pr_API_FedEx_GetCustomInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Extract the Account details */
  select @vShipperAccount       = Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]',  'TAccount'),
         @vBillToAccount        = Record.Col.value('(ORDERHEADERS/BillToAccount)[1]',    'TAccount'),
         @vPersonName           = Record.Col.value('(BILLTOADDRESS/Name)[1]',            'TName'),
         @vContactId            = Record.Col.value('(BILLTOADDRESS/ContactId)[1]',       'TRecordId'),
         @vMeterNumber          = Record.Col.value('(ACCOUNTDETAILS/MeterNumber)[1]',    'TMeterNumber'),
         @vCurrency             = Record.Col.value('(CustomsValue/Currency)[1]',         'TVarChar'),
         @vAmount               = Record.Col.value('(CustomsValue/Amount)[1]',           'TMoney'),
         @vNumberOfPieces       = Record.Col.value('(Commodities/NumberOfPieces)[1]',    'TQuantity'),
         @vDescription          = Record.Col.value('(Commodities/Description)[1]',       'TDescription'),
         @vCountryOfManufacture = Record.Col.value('(Commodities/Manufacturer)[1]',      'TCoO'),
         @vQuantity             = Record.Col.value('(Commodities/Quantity)[1]',          'TQuantity'),
         @vQuantityUnits        = Record.Col.value('(Commodities/QuantityUoM)[1]',       'TUoM'),
         @vUnits                = Record.Col.value('(Commodities/Weight/WeightUoM)[1]',  'TUoM'),
         @vValue                = Record.Col.value('(Commodities/Weight/Value)[1]',      'TQuantity'),
         @vFreightTerms         = Record.Col.value('(ORDERHEADER/FreightTerms)[1]',      'TDescription')
  from @ShipmentInfoXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col);

  /* Identify the payor type */
  select @vPayorType = case when (@vFreightTerms in ('SENDER', 'PREPAID'))                then 'BillShipper'
                            when (@vFreightTerms in ('COLLECT', 'RECEIVER', 'RECIPIENT')) then 'BillReceiver'
                            when (@vFreightTerms = '3RDPARTY')                            then 'BillThirdParty'
                            when (@vFreightTerms = 'CONSIGNEE')                           then 'ConsigneeBilledIndicator'
                            else 'BillShipper'
                       end;

  /* Get payor account based upon the payor type */
  select @vPayorAccount = case when (@vPayorType = 'BillShipper')                 then @vShipperAccount
                               when (@vPayorType in ('BillReceiver', '3RDPARTY')) then @vBillToAccount
                               else @vShipperAccount
                          end;

  select @vWeight =  dbo.fn_XMLNode('Weight',
                                      dbo.fn_XMLNode('Units', @vUnits) +
                                      dbo.fn_XMLNode('Value', @vValue));

  select @vUnitPrice =  dbo.fn_XMLNode('UnitPrice',
                                            dbo.fn_XMLNode('Currency', @vCurrency) +
                                            dbo.fn_XMLNode('Amount', @vAmount));

  select @vCustomsValue =  dbo.fn_XMLNode('CustomsValue',
                                            dbo.fn_XMLNode('Currency', @vCurrency) +
                                            dbo.fn_XMLNode('Amount', @vAmount));

  select @vCommodities = dbo.fn_XMLNode('Commodities',
                                            dbo.fn_XMLNode('NumberOfPieces',       @vNumberOfPieces) +
                                            dbo.fn_XMLNode('Description',          @vDescription) +
                                            dbo.fn_XMLNode('CountryOfManufacture', @vCountryOfManufacture) +
                                            @vWeight + @vUnitPrice + @vCustomsValue );

  select @vContact =  dbo.fn_XMLNode('CustomsValue',
                                            dbo.fn_XMLNode('PersonName', @vPersonName) +
                                            dbo.fn_XMLNode('ContactId', @vContactId));

  select @vDutiesPayment = '<DutiesPayment>' +
                             '<PaymentType>' +  @vFreightTerms + '</PaymentType>' +
                               '<Payor>' +
                                '<ResponsibleParty>' +
                                  '<AccountNumber>' + @vPayorAccount + '</AccountNumber>' +
                                  '<Tins>
                                    <TinType>BUSINESS_STATE</TinType>
                                    <Number>213456</Number>
                                   </Tins>' +
                                  @vContact +
                                '</ResponsibleParty>' +
                               '</Payor>' +
                            '</DutiesPayment>'

  select @CustomsClearanceDetail = '<CustomsClearanceDetail>' +
                                      @vDutiesPayment +
                                      '<DocumentContent>DOCUMENTS_ONLY</DocumentContent>' +
                                      @vCustomsValue +
                                      @vCommodities  +
                                      '<ExportDetail>
                                        <ExportComplianceStatement>30.37(f)</ExportComplianceStatement>
                                      </ExportDetail>' +
                                    '</CustomsClearanceDetail>';



ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_GetCustomInfo */

Go
