/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/10  MS      pr_ShipLabels_UpdatePackageDimensions: Bug fix for ambiguous column (BK-192)
  2019/10/31  AY/MS   pr_ShipLabels_UpdatePackageDimensions: Added procedure to compute PackageDimentions (S2GCA-1022)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabels_UpdatePackageDimensions') is not null
  drop Procedure pr_ShipLabels_UpdatePackageDimensions;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabels_UpdatePackageDimensions:
    This procedure updates all dimensions of packages of the specific wave
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabels_UpdatePackageDimensions
 (@BusinessUnit TBusinessUnit)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName;

begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null;

  /* Update the carton dimensions from Carton Types */
  update STI
  set PackageLength = CT.OuterLength,
      PackageWidth  = CT.OuterWidth,
      PackageHeight = CT.OuterHeight
  from #ShipLabelsToInsert STI
    join CartonTypes CT on (STI.CartonType  = CT.CartonType) and
                           (CT.BusinessUnit = @BusinessUnit)
  where (STI.InsertRequired = 'Y');

  /* Update the package weight/Volume from LPNs */
  update STI
  set PackageVolume = L.LPNVolume,
      PackageWeight = L.LPNWeight
  from #ShipLabelsToInsert STI join LPNs L on STI.EntityId = L.LPNId
  where (STI.InsertRequired = 'Y');

  /* Get SKUId for LPNs with CartonType of STD_BOX, STD_UNIT and use the SKU Dimensions */
  with LPNSKUs(LPNId, CartonType, SKUId) as
  (
    select LD.LPNId, min(CartonType), min(LD.SKUId)
    from #ShipLabelsToInsert STI join LPNDetails LD on STI.EntityId = LD.LPNId
    where (STI.CartonType in ('STD_BOX', 'STD_UNIT')) and (InsertRequired = 'Y')
    group by LD.LPNId
  )
  update STI
  set PackageLength = case when STI.CartonType = 'STD_BOX'  then coalesce(nullif(S.InnerpackLength, 0), nullif(S.UnitLength, 0), CT.OuterLength)
                           when STI.CartonType = 'STD_UNIT' then coalesce(nullif(S.UnitLength, 0), CT.OuterLength)
                      end,
      PackageWidth  = case when STI.CartonType = 'STD_BOX'  then coalesce(nullif(S.InnerpackWidth,  0), nullif(S.UnitWidth,  0), CT.OuterWidth)
                           when STI.CartonType = 'STD_UNIT' then coalesce(nullif(S.UnitWidth,  0), CT.OuterWidth)
                      end,
      PackageHeight = case when STI.CartonType = 'STD_BOX'  then coalesce(nullif(S.InnerpackHeight, 0), nullif(S.UnitHeight, 0), CT.OuterHeight)
                           when STI.CartonType = 'STD_UNIT' then coalesce(nullif(S.UnitHeight, 0), CT.OuterHeight)
                      end
  from #ShipLabelsToInsert STI
    join LPNSKUs     LS on (STI.EntityId    = LS.LPNId) and (STI.SKUId = LS.SKUId)
    join SKUs         S on (LS.SKUId        = S.SKUId)
    join CartonTypes CT on (STI.CartonType  = CT.CartonType) and (CT.BusinessUnit = @BusinessUnit)

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabels_UpdatePackageDimensions */

Go
