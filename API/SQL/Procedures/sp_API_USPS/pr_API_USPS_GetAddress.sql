/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_USPS_GetAddress') is not null
  drop Procedure pr_API_USPS_GetAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_USPS_GetAddress: Returns the request address in jsonn as expected by UPS.

  Sample output:

------------------------------------------------------------------------------*/
Create Procedure pr_API_USPS_GetAddress
  (@ContactId     TRecordId,
   @ContactType   TTypeCode,
   @ContactRefId  TContactRefId,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @Address       TXML output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_USPS_GetAddress */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  if (@ContactId is null)
    select @ContactId = ContactId
    from Contacts
    where (ContactType = @ContactType) and (ContactRefId = @ContactRefId) and (BusinessUnit = @BusinessUnit);

  /* Build Address */
  select @Address = (select FromName           = Name,
                            FromPhone          = PhoneNo,
                            FromAddress        = AddressLine1,
                            FromCity           = City,
                            FromState          = State,
                            FromPostalCode     = Zip,
                            FromCountryCode    = Country
                         from Contacts
                         where (ContactId = @ContactId)
                         for xml path);
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_USPS_GetAddress */

Go
