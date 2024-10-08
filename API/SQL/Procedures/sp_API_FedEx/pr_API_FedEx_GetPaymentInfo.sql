/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_GetPaymentInfo') is not null
  drop Procedure pr_API_FedEx_GetPaymentInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_GetPaymentInfo: Extract data from get shipment data xml and
   build payment info XML

------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_GetPaymentInfo
  (@ContactId          TRecordId = null,
   @ContactType        TTypeCode,
   @ContactRefId       TContactRefId,
   @ShipmentInfoXML    XML,
   @AccountNumber      TDescription,
   @FreightTerms       TDescription,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ShipperAddress     TVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vContactId              TRecordId,
          @vPersonName             TName,
          @vEmailaddress           TEmailAddress,
          @vAccountNumber          TRecordId,
          @vContact                TVarchar;

begin /* pr_API_FedEx_GetPaymentInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Here Shipper address is printing on label, If we are not sending Ship from then consider the shipper is the Ship from address */
  if (@FreightTerms is null)
    select @FreightTerms = Record.Col.value('(ORDERHEADER/FreightTerms)[1]',     'TDescription')
    from @ShipmentInfoXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col);

  if (@ContactId is null)
    select @ContactId = ContactId
    from Contacts
    where (ContactType = @ContactType) and (ContactRefId = @ContactRefId) and (BusinessUnit = @BusinessUnit);

  /* Build Address as XML */
  select @vContact = (select ContactPerson  as "Contact/PersonName",
                             Name           as "Contact/CompanyName",
                             PhoneNo        as "Contact/PhoneNumber",
                             Email          as "Contact/EmailAddress"
                      from Contacts
                      where (ContactId = @ContactId)
                      FOR XML PATH(''));

  /* Build the XML for FEDEX PayerInfo */
  select @ShipperAddress = '<ShippingChargesPayment>' +
                             '<PaymentType>' +  @FreightTerms + '</PaymentType>' +
                             '<Payor>' +
                               '<ResponsibleParty>' +
                                '<AccountNumber>' + @AccountNumber + '</AccountNumber>' +
                               '</ResponsibleParty>' +
                               @vContact +
                             '</Payor>' +
                           '</ShippingChargesPayment>';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_GetPaymentInfo */

Go
