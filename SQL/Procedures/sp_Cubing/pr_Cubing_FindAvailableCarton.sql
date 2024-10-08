/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/16  TK      pr_Cubing_FindAvailableCarton: Code refractoring
  2020/09/15  TK      pr_Cubing_FindAvailableCarton: Bug fix in initializing SKU dimension variables (HA-1436)
  2019/10/07  TK      pr_Cubing_Execute, pr_Cubing_AddCartonDetails & pr_Cubing_FindAvailableCarton:
                        Performance improvements
                      pr_Cubing_PrepareToCubePicks & pr_Cubing_AddCartons: Initial Revision (CID-883)
  2019/05/04  TK      pr_Cubing_Execute, pr_Cubing_FindAvailableCarton & pr_Cubing_FindOptimalCarton:
                        Changes to consider packing group while cubing (S2GCA-677)
  2018/02/08  TD      pr_Cubing_Execute,pr_Cubing_GetCartonTypes,pr_Cubing_FindAvailableCarton:Changes to cube based on
                        cases and unit picks (S2G-107)
  2016/10/08  AY/TK   pr_Cubing_Execute & pr_Cubing_FindAvailableCarton: Enhanced to consider nesting factor on SKUs (HPI-705)
  2015/05/06  TK      pr_Cubing_Execute & pr_Cubing_FindAvailableCarton:
                        Consider Order types while cubing certin order types have
                          some constriants for example same SKU/Case or same Style/Case.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_FindAvailableCarton') is not null
  drop Procedure pr_Cubing_FindAvailableCarton;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_FindAvailableCarton: To Find Available Carton.
    If we are unable to find a carton to cube againist Order and we have the last few units to cube
    based on WaveType Packing Tolerance value we will add into an existing carton.
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_FindAvailableCarton
  (@OrderId              TRecordId,
   @PackingGroup         TCategory,
   @SKUId                TRecordId,
   @QtyToCube            TInteger,
   @CubingCartonId       TRecordId output,
   @UnitsToCube          TInteger  output,
   @CartonSpaceRemaining TFloat    output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vSKU                    TSKU,
          @vSKU2                   TSKU,
          @vShipPack               TInteger,
          @vSpacePerIP             TFloat,
          @vSpacePerUnit           TFloat,
          @vWeightPerIP            TWeight,
          @vWeightPerUnit          TWeight,
          @vUnitsPerIP             TInteger,
          @vNestingFactor          TFloat,

          @vCartonType             TCartonType,
          @vMinSpaceRequired       TFloat,
          @vMinWeightRequired      TWeight,
          @vCartonPackingSpaces    TFloat,
          @vMaxUnitsToCubeToCarton TInteger,
          @vUnitsRemaining         TInteger,
          @vWeightRemaining        TWeight,
          @vMaxUnitDimension       TFloat,
          @vMaxIPDimension         TFloat,
          @vFirstDimension         TFloat,
          @vSecondDimension        TFloat,
          @vThirdDimension         TFloat;

begin
  SET NOCOUNT ON;

  select @vReturnCode          = 0,
         @vMessageName         = null,
         @CubingCartonId       = null,
         @UnitsToCube          = 0,
         @CartonSpaceRemaining = 0;

  /* if there are no cartons, then exit */
  if not exists(select * from #CubeCartonHdrs)
    goto ExitHandler;

  /* get the SKU Style */
  select @vSKU              = SKU,
         @vSKU2             = SKU2,
         @vUnitsPerIP       = UnitsPerIP,
         @vShipPack         = ShipPack,
         @vSpacePerIP       = SpacePerIP,
         @vSpacePerUnit     = SpacePerUnit,
         @vWeightPerIP      = InnerPackWeight,
         @vWeightPerUnit    = UnitWeight,
         @vNestingFactor    = NestingFactor,
         @vMaxUnitDimension = MaxUnitDimension,
         @vMaxIPDimension   = MaxIPDimension,
         @vFirstDimension   = FirstDimension,
         @vSecondDimension  = SecondDimension,
         @vThirdDimension   = ThirdDimension
  from #SKUs S
  where SKUId = @SKUId;

  /* Calculate the minimum space required to Cube units, At minimum we can cube 1 unit,
     however, if the SKU is in innerpacks, then minimum units to cube may be units in 1 inner pack */
  select @vMinSpaceRequired = case
                                /* When there are only IPs left to cube, then min space required is for 1 IP */
                                when (@vUnitsPerIP > 0) and (@vSpacePerIP > 0) and(@QtyToCube >= @vUnitsPerIP) then
                                  @vSpacePerIP
                                else
                                  @vSpacePerUnit * @vShipPack
                              end;

  /* compute the minimum weight required to Cube units, At minimum weight should be greater than WeightPerUnit
     however, if the SKU is in innerpacks, then minimum weight to cube may be WeightPerIP */
  select @vMinWeightRequired = case
                                /* When IPs to cube, then min weight required is InnerPackWeight */
                                when (@vUnitsPerIP > 0) and (@vWeightPerIP > 0) and (@QtyToCube >= @vUnitsPerIP) then
                                  @vWeightPerIP
                                else
                                  @vWeightPerUnit * @vShipPack
                              end;

  /* Find the carton which has the maximum space available and compute the number
     of units we can cube into the carton */

    /* Return CartonId which has the maximum space available */
    select top 1 @CubingCartonId       = CartonId,
                 @vCartonType          = CartonType,
                 @CartonSpaceRemaining = SpaceRemaining,
                 @vUnitsRemaining      = UnitsRemaining,
                 @vWeightRemaining     = WeightRemaining
    from #CubeCartonHdrs CH
    where (CH.OrderId         = @OrderId      ) and
          (CH.PackingGroup    = @PackingGroup) and
          (CH.Status          = 'O' /* Open */) and
          (CH.SpaceRemaining  >= @vMinSpaceRequired) and
          (CH.WeightRemaining >= @vMinWeightRequired) and
          (FirstDimension     >= @vFirstDimension) and
          (SecondDimension    >= @vSecondDimension) and
          (ThirdDimension     >= @vThirdDimension) and
          (CH.UnitsRemaining  >= @vShipPack)
    order by SpaceRemaining desc;

  /* If we found a carton with space, then figure out how many units we can cube into that carton */
  if (@CartonSpaceRemaining > 0)
    exec pr_Cubing_ComputeUnitsToCube @SKUId, @vCartonType, @QtyToCube, @CartonSpaceRemaining, @vUnitsRemaining, @vWeightRemaining, @UnitsToCube output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_FindAvailableCarton */

Go
