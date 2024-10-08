/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/27  MS      pr_API_UPS_GetPaymentInfo: Changes to insert DDP records (BK-958)
  2022/07/21  RV      pr_API_UPS_GetPaymentInfo: Made changes to send SoldTo Zip if BillTo Zip is not present (OBV3-929)
  2021/11/25  OK      pr_API_UPS_GetPaymentInfo: Bug fix to pass proper account number for 3RDPARTY billing (BK-709)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetPaymentInfo') is not null
  drop Procedure pr_API_UPS_GetPaymentInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetPaymentInfo: Extract data from get shipment data xml and
   build payment info json.

  Document Reference: https://vsvn.foxfireindia.com:8443/svn/sct/cIMS3.0/branches/Dev3.0/Documents/Manuals/Developer Manuals/UPS Shipping Package RESTful Developer Guide.pdf
  Page No: 32
  Sample output:
  "PaymentInformation": {
        "ShipmentCharge": [
          {
            "Type": "01",
            "BillShipper": {
              "AccountNumber": "F95314",
              "Address": {
                "PostalCode": "90025",
                "CountryCode": "US"
              }
            }
          },
          {
            "Type": "02",
            "BillShipper": {
              "AccountNumber": "F95314",
              "Address": {
                "PostalCode": "90025",
                "CountryCode": "US"
              }
            }
          }
        ]
      }
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetPaymentInfo
  (@InputXML         xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @PaymentInfoJSON  TNVarchar output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vTermsOfShipment   TDescription;

  declare @ttPaymentInfo table(PaymentTypeCode   TTypecode,
                               PayorType         TDescription,
                               PayorAccount      TAccount,
                               PayorPostalCode   TZip,
                               PayorCountryCode  TCountry,
                               -- input info
                               FreightTerms      TDescription,
                               ShipperAccount    TAccount,
                               BillToAccount     TAccount,
                               BillToPostalCode  TZip,
                               BillToCountryCode TCountry,
                               SoldToPostalCode  TZip,
                               SoldToCountryCode TCountry,
                               RecordId          TRecordId identity(1,1));
begin /* pr_API_UPS_GetPaymentInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Extract the Account details */
  insert into @ttPaymentInfo(PaymentTypeCode, FreightTerms, ShipperAccount, BillToAccount, BillToPostalCode, BillToCountryCode, SoldToPostalCode, SoldToCountryCode)
    select '01' as TypeCode,
           Record.Col.value('(ORDERHEADER/FreightTerms)[1]',     'TDescription'),
           Record.Col.value('(ACCOUNTDETAILS/ACCOUNTNUMBER)[1]', 'TAccount'),
           Record.Col.value('(ORDERHEADER/BillToAccount)[1]',    'TAccount'),
           Record.Col.value('(BILLTOADDRESS/Zip)[1]',            'TZip'),
           Record.Col.value('(BILLTOADDRESS/Country)[1]',        'TCountry'),
           Record.Col.value('(SOLDTOADDRESS/Zip)[1]',            'TZip'),
           Record.Col.value('(SOLDTOADDRESS/Country)[1]',        'TCountry')
    from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
    OPTION (OPTIMIZE FOR ( @InputXML = null ));

  /* get Terms Of Shipment */
  select @vTermsOfShipment = Record.Col.value('(CIINFO/Terms)[1]', 'TDescription')
  from @InputXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
  OPTION (OPTIMIZE FOR ( @InputXML = null ));

  /* get payor type */
  update @ttPaymentInfo
  set PayorType = case when (FreightTerms in ('SENDER', 'PREPAID'))                then 'BillShipper'
                       when (FreightTerms in ('COLLECT', 'RECEIVER', 'RECIPIENT')) then 'BillReceiver'
                       when (FreightTerms = '3RDPARTY')                            then 'BillThirdParty'
                       when (FreightTerms = 'CONSIGNEE')                           then 'ConsigneeBilled'
                       else 'BillShipper'
                  end;

  /* Update payor account */
  update @ttPaymentInfo
  set PayorAccount = case when (PayorType in ('BillReceiver', 'BillThirdParty')) then BillToAccount
                          else ShipperAccount
                     end;

  /* Use BillToInfo when available, else use ShipTo */
  update @ttPaymentInfo
  set PayorPostalCode  = coalesce(BillToPostalCode,  SoldToPostalCode),
      PayorCountryCode = coalesce(BillToCountryCode, SoldToCountryCode);

  /* Clear info if ConsigneeBilled */
  update @ttPaymentInfo
  set PayorAccount     = null,
      PayorPostalCode  = null,
      PayorCountryCode = null
  where (PayorType = 'ConsigneeBilled');

  /* TermsOfShipment is DDP & PayorType is BillShipper, insert record */
  if (@vTermsofShipment = 'DDP')
    insert into @ttPaymentInfo(PaymentTypeCode, PayorType, PayorAccount, PayorPostalCode, PayorCountryCode)
      select '02', PayorType, PayorAccount, PayorPostalCode, PayorCountryCode
      from @ttPaymentInfo
      where (PayorType = 'BillShipper');

  /* Build PaymentInfo json */
  /* ShipmentCharge.Type: 01 = Transportation, 02 = Duties and Taxes, 03 = Broker of Choice */
  select @PaymentInfoJSON = (select [Type]                          = PaymentTypeCode,
                                    [ConsigneeBilledIndicator]      = case when PayorType = 'ConsigneeBilled' then '' else null end,
                                    [PayorType.AccountNumber]       = PayorAccount,
                                    [PayorType.Address.PostalCode]  = PayorPostalCode,
                                    [PayorType.Address.CountryCode] = PayorCountryCode
                             from @ttPaymentInfo
                             FOR JSON PATH);

  select @PaymentInfoJSON = '{ "ShipmentCharge":'+ @PaymentInfoJSON +'}';

  /* Replace PayorType with updated payortype value */
  select @PaymentInfoJSON = replace(@PaymentInfoJSON, 'PayorType', PayorType) from @ttPaymentInfo

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetPaymentInfo */

Go
