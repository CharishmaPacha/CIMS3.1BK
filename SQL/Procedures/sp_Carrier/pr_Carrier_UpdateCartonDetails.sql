/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/12/22  VS      pr_Carrier_GetShipmentData, pr_Carrier_UpdateCartonDetails: Made changes to improve the Performance (FBV3-1660)
  2023/12/08  VS      pr_Carrier_GetShipmentData, pr_Carrier_UpdateCartonDetails: Made changes to improve the Performance (FBV3-1660)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_UpdateCartonDetails') is not null
  drop Procedure pr_Carrier_UpdateCartonDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_UpdateCartonDetails: This proc will update the PackageType and
    Carton Dimensions for all packages using the following rules.

  Package Type:
    a. Consider ShipVia.CarrierPackageType. If the ShipVia has a PackageType
       specified, then that supercedes everything else. This means that when using
       that ShipVia it is always considered a particular package type.
    b. Consider CartonType.CarrierPackageType: If the Carton Type has a certain
       package type, then use that. Ex: Carrier supplied boxes/bags.
    c. Translate the Carton Type to ADSI or PROSHIP terminology.

  Carton Dimensions:
    a. Get from CartonType
    b. Get from SKU if CartonType is STD_Box or STD_Unit
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_UpdateCartonDetails
  (@xmlRulesData     Txml,
   @BusinessUnit     TBusinessUnit)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vCarrierPackagingType  TDescription,
          @vCarrierInterface      TDescription;
begin
  SET NOCOUNT ON;

  /* There should be only one record for the shipment in #CarrierShipmentData */
  select @vCarrierPackagingType = CarrierPackagingType,
         @vCarrierInterface     = CarrierInterface
  from #CarrierShipmentData;

  /* Update the carton dimensions based upon the carton type */
  update CPI
  set CartonLength = coalesce(CT.OuterLength, CT.InnerLength),
      CartonWidth  = coalesce(CT.OuterWidth,  CT.InnerWidth),
      CartonHeight = coalesce(CT.OuterHeight, CT.InnerHeight),
      PackageType  = coalesce(@vCarrierPackagingType, CT.CarrierPackagingType)
  from #CarrierPackageInfo CPI
    left join CartonTypes CT on (CT.CartonType = CPI.CartonType);

  /* For STD Box/Unit, use the dimensions from the SKU */
  update CPI
  set CartonLength = case when CPI.CartonType = 'STD_BOX'  then coalesce(nullif(S.InnerpackLength, 0), nullif(S.UnitLength, 0), CPI.CartonLength)
                          when CPI.CartonType = 'STD_UNIT' then coalesce(nullif(S.UnitLength, 0), CPI.CartonLength)
                     else CPI.CartonLength end,
      CartonWidth  = case when CPI.CartonType = 'STD_BOX'  then coalesce(nullif(S.InnerpackWidth,  0), nullif(S.UnitWidth,  0), CPI.CartonWidth)
                          when CPI.CartonType = 'STD_UNIT' then coalesce(nullif(S.UnitWidth,  0), CPI.CartonWidth)
                     else CPI.CartonWidth end,
      CartonHeight = case when CPI.CartonType = 'STD_BOX'  then coalesce(nullif(S.InnerpackHeight, 0), nullif(S.UnitHeight, 0), CPI.CartonHeight)
                          when CPI.CartonType = 'STD_UNIT' then coalesce(nullif(S.UnitHeight, 0), CPI.CartonHeight)
                     else CPI.CartonHeight end
  from #CarrierPackageInfo CPI
    left join SKUs S on (S.SKUId = CPI.SKUId)
  where (CPI.CartonType in ('STD_BOX', 'STD_UNIT'));

  /* Update the PackageType based on CarrierInterface */
  if (@vCarrierInterface in ('ADSI', 'PROSHIP'))
    update CPI
    set PackageType = dbo.fn_GetMappedValue('CIMS', CPI.PackageType /* Source Value */, @vCarrierInterface /* Target System */, 'CarrierPackagingType' /* Entity Type */, null /* Operation */, @BusinessUnit)
    from #CarrierPackageInfo CPI;

end /* pr_Carrier_UpdateCartonDetails */

Go
