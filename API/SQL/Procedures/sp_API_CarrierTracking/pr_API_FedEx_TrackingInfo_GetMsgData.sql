/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/12  VS      pr_API_FedEx_TrackingInfo_GetMsgData, pr_API_FedEx_ProcessTrackingInfo (BK-939)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_TrackingInfo_GetMsgData') is not null
  drop Procedure pr_API_FedEx_TrackingInfo_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_TrackingInfo_GetMsgData: generates Message data in the format required by FedEx Carrier

  Path:  D:\SVN_VS\cIMS 3.0\branches\Dev3.0\Documents\Manuals\Developer Manuals\
  FileName: FedEx_WebServices_DevelopersGuide_v2020.pdf (681)
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_TrackingInfo_GetMsgData
  (@IntegrationName    TName,
   @MessageType        TName,
   @EntityType         TTypeCode,
   @EntityId           TRecordId,
   @EntityKey          TEntityKey,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @MessageData        TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vUserId                      TUserId,
          @vTrackingNo                  TTrackingNo,
          @vAccountInfo                 TVarchar,
          @vAccountNumber               TAccount,
          @vMeterNumber                 TMeterNumber,
          @vShippingAccountPassword     TPassword,
          @vShippingAccountAccessKey    TAccessKey,
          @vShippingAcctName            TAccountName,
          @vAccountDetails              TVarchar,
          @vUserCredential              TVarchar,
          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit;

begin /* pr_API_UPS_TrackingInfo_GetMsgData */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the ShippingAccountAccessKey and MeterNumber */
  select @vShippingAccountPassword  = Password,
         @vShippingAccountAccessKey = ShipperAccessKey,
         @vAccountNumber            = ShipperAccountNumber,
         @vMeterNumber              = ShipperMeterNumber,
         @vShippingAccountAccessKey = UserId
  from ShippingAccounts
  where (ShippingAcctName = 'FEDEX') and (BusinessUnit = @BusinessUnit);

  /* Get the TrackingNo */
  select @vTrackingNo = TrackingNo from LPNs where (LPNId = @EntityId);

  /* Build Message Type */
  select @MessageData = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v16="http://fedex.com/ws/track/v16">
                          <soapenv:Header/>
                           <soapenv:Body>
                            <v16:TrackRequest>
                             <v16:WebAuthenticationDetail>
                               <v16:UserCredential>
                                 <v16:Key>' + @vShippingAccountAccessKey  + '</v16:Key>
                                 <v16:Password>'+ @vShippingAccountPassword + '</v16:Password>
                               </v16:UserCredential>
                             </v16:WebAuthenticationDetail>
                               <v16:ClientDetail>
                                 <v16:AccountNumber>' + @vAccountNumber + '</v16:AccountNumber>
                                 <v16:MeterNumber>' + @vMeterNumber + '</v16:MeterNumber>
                               </v16:ClientDetail>
                             <v16:TransactionDetail>
                               <v16:CustomerTransactionId>' + @vTrackingNo + '</v16:CustomerTransactionId>
                               <v16:Localization>
                                <v16:LanguageCode>EN</v16:LanguageCode>
                                <v16:LocaleCode>US</v16:LocaleCode>
                               </v16:Localization>
                             </v16:TransactionDetail>
                             <v16:Version>
                               <v16:ServiceId>trck</v16:ServiceId>
                               <v16:Major>16</v16:Major>
                               <v16:Intermediate>0</v16:Intermediate>
                               <v16:Minor>0</v16:Minor>
                             </v16:Version>
                             <v16:SelectionDetails>
                               <v16:CarrierCode>FDXE</v16:CarrierCode>
                               <v16:PackageIdentifier>
                                 <v16:Type>TRACKING_NUMBER_OR_DOORTAG</v16:Type>
                                 <v16:Value>' + @vTrackingNo + '</v16:Value>
                               </v16:PackageIdentifier>
                             <v16:ShipmentAccountNumber />
                             <v16:SecureSpodAccount />
                             <v16:Destination>
                             <v16:GeographicCoordinates>rates evertitque aequora</v16:GeographicCoordinates>
                             </v16:Destination>
                             </v16:SelectionDetails>
                            </v16:TrackRequest>
                          </soapenv:Body>
                         </soapenv:Envelope>'

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_TrackingInfo_GetMsgData */

Go
