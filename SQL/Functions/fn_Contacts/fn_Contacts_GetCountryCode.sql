/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this function exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2022/05/04  AY      fn_Contacts_GetCountryCode: Map Valid/Unofficial Country Names to a valid code (OBV3-610)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Contacts_GetCountryCode') is not null
  drop Function fn_Contacts_GetCountryCode;
Go
/*------------------------------------------------------------------------------
  Function fn_Contacts_GetCountryCode: In several cases we get invalid country
    or get a country name instead of the country code where as carriers expect a
    country code only. This procedure validates the given country name/code and
    returns a country code. It look up invalid or unofficial names against official
    names as well. For example, if we pass in "United States of America" it would
    return US.
------------------------------------------------------------------------------*/
Create Function fn_Contacts_GetCountryCode
  (@Country       TCountry,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
  --------------------
   returns   TCountry
as
begin
  declare @vValidCountry  TCountry;

  /* If country code is wrong then get from correct value from Mappings */
  if (exists(select * from vwLookups where LookUpCode = @Country and LookUpCategory = 'Country'))
    return(upper(@Country));

  /* If is not valid, then check if there is a mapping, if there no mappign then the same is returned back */
  select @vValidCountry = dbo.fn_GetMappedValueDefault('CIMS', @Country /* Source Value */, 'CIMS' /* Target System */, 'Country' /* Entity Type */, @Country, null /* Operation */, @BusinessUnit);

  /* If it is invalid and yet there is no mapping, then check if it is the description */
  if (@vValidCountry = @Country)
    select @vValidCountry = LookUpCode
    from vwLookUps
    where (LookUpDescription = @vValidCountry) and (LookUpCategory = 'Country');

  return(upper(@vValidCountry));
end /* fn_Contacts_GetCountryCode */

Go
