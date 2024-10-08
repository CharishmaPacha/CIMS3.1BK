/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_GetAddress') is not null
  drop Procedure pr_API_FedEx_GetAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_GetAddress: Returns the request address in XML as expected by FedEx.

  Sample output:
  <Shipper>
    <AccountNumber>150067600</AccountNumber>
    <Contact>
      <PersonName>Abhay</PersonName>
      <CompanyName>Syntel</CompanyName>
      <PhoneNumber>9822280721</PhoneNumber>
      <EMailAddress>abhay_palaskar@syntelinc.com</EMailAddress>
    </Contact>
    <Address>
      <StreetLines>Test Sender Address Line1</StreetLines>
      <City>Anchorage</City>
      <StateOrProvinceCode>AK</StateOrProvinceCode>
      <PostalCode>99501</PostalCode>
      <CountryCode>US</CountryCode>
    </Address>
  </Shipper>
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_GetAddress
  (@ContactId     TRecordId,
   @ContactType   TTypeCode,
   @ContactRefId  TContactRefId,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @RootNode      TDescription,
   @AccountNumber TDescription,
   @AddressXML    TXML output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_FedEx_GetAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@ContactId is null)
    select @ContactId = ContactId
    from Contacts
    where (ContactType = @ContactType) and (ContactRefId = @ContactRefId) and (BusinessUnit = @BusinessUnit);

  /* Build Address as XML */
  select @AddressXML = (select ContactPerson  as "Contact/PersonName",
                               Name           as "Contact/CompanyName",
                               PhoneNo        as "Contact/PhoneNumber",
                               Email          as "Contact/EmailAddress",
                               AddressLine1   as "Address/StreetLines",
                               AddressLine2   as "Address/StreetLines",
                               City           as "Address/City",
                               State          as "Address/StateOrProvinceCode",
                               Zip            as "Address/PostalCode",
                               Country        as "Address/CountryCode"
                         from Contacts
                         where (ContactId = @ContactId)
                         FOR XML PATH(''));

  select @AddressXML = dbo.fn_XMLNode(@RootNode,
                         dbo.fn_XMLNode('AccountNumber', @AccountNumber) + @AddressXML);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_GetAddress */

Go
