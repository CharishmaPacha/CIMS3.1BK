/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Shipping_GetPackagingType') is not null
  drop Function fn_Shipping_GetPackagingType;
Go
/*------------------------------------------------------------------------------
  fn_Shipping_GetPackagingType: Determine the packaging type to be sent to the
    carrier.

  We may have a Packaging type defined on the ShipVia i.e. for some UPS
   servies, only acceptable value is 'UPS Parcels', where as for others we
   get more details from CartonTypes table. Hence use the value from ShipVias
   and if we do not have it, then use from CartonTypes table.
   On top of that, if we are using ADSI, we may have to map these values to ADSI known values
------------------------------------------------------------------------------*/
Create Function fn_Shipping_GetPackagingType
  (@ShipViaPackagingType  TDescription,
   @CartonType            TCartonType,
   @CarrierInterface      TControlValue)
  --------------------------------------
  returns                 TDescription
as
begin
  declare @vResult                TDescription,
          @vCarrierPackagingType  TDescription,
          @vBusinessUnit          TBusinessUnit;

  /* Get the custom packaging type for the carton */
  select @vCarrierPackagingType = CarrierPackagingType,
         @vBusinessUnit         = BusinessUnit
  from CartonTypes
  where (CartonType = @CartonType);

  /* If defined on ShipVia use that as for some services the PackagingType is fixed
     else use the value from the CartonType */
  select @vResult = coalesce(@ShipViaPackagingType, @vCarrierPackagingType);

  /* if ADSI, then map value for ADSI */
  if (@CarrierInterface = 'ADSI')
    select @vResult = dbo.fn_GetMappedValue('CIMS', @vResult /* Source Value */, @CarrierInterface /* Target System */, 'CarrierPackagingType' /* Entity Type */,   null /* Operation */, @vBusinessUnit);

  return (@vResult);
end  /* fn_Shipping_GetPackagingType */

Go
