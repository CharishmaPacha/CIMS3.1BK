/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/11  TK      pr_Cubing_Execute & pr_Cubing_FindOptimalCarton:
                        Changes to cube standard units separately (HA-1568)
  2020/09/16  TK      pr_Cubing_FindOptimalCarton: Changes to consider max of SKU dimensions while findng optimal carton
  2020/04/25  TK      pr_Cubing_AddCartonDetails, pr_Cubing_Execute, pr_Cubing_FindOptimalCarton:
                        Changes to cube either order details or task details & performance improvements
                      pr_Cubing_GetDetailsToCube: Initial Revision (HA-171)
  2019/05/04  TK      pr_Cubing_Execute, pr_Cubing_FindAvailableCarton & pr_Cubing_FindOptimalCarton:
                        Changes to consider packing group while cubing (S2GCA-677)
  2015/07/10  TK      pr_Cubing_FindOptimalCarton: Enhance to limit NumUnits to be cubed for a Carton (ACME-212)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_FindOptimalCarton') is not null
  drop Procedure pr_Cubing_FindOptimalCarton;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_FindOptimalCarton: This procedure finds the next carton
    type to be used for an Order which has still @TotalPSRequired to be cubed.
    It identifies the carton as well as the spaces within the carton.

  Notes:
    - Carton types can be specific to customers. i.e. for some customers we may
      use only some carton types, while for others we could use generic carton
      types. So, we first load the available carton types for the customer of
      the particular order

    - For some order lines (which we typically pack to individual cartons) there
      may be limit of number of units to be cubed per carton. This value is assumed
      to be passed from the host in UnitsPerCarton and if something is passed in, then
      we will not cube more than those units per carton.
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_FindOptimalCarton
  (@OrderId              TRecordId,
   @PackingGroup         TCategory,
   @SKUId                TRecordId,
   @CartonType           TCartonType output,
   @EmptyCartonSpace     TFloat      output,
   @MaxUnitsPerCarton    TCount      output,
   @MaxWeightPerCarton   TWeight     output)
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

          @vTotalUnits             TInteger,
          @vTotalWeight            TWeight,
          @vTotalSpaceRequired     TFloat,
          @vTotalWeightRequired    TWeight,
          @vMinSpaceRequired       TFloat,
          @vMinWeightRequired      TWeight,
          @vMaxSpaceToBeCubed      TFloat,
          @vMaxUnitsPerCarton      TCount,
          @vMaxUnitDimension       TFloat,
          @vMaxFirstDimension      TFloat,
          @vMaxSecondDimension     TFloat,
          @vMaxThirdDimension      TFloat,
          @vMaxIPDimension         TFloat,
          @vFirstDimension         TFloat,
          @vSecondDimension        TFloat,
          @vThirdDimension         TFloat,
          @vOrderCartonGroup       TCartonGroup;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @CartonType        = null,
         @EmptyCartonSpace  = 0,
         @MaxUnitsPerCarton = 0;

  /* If task detail needs to be cubed into STD_BOX then just return */
  if (@PackingGroup like 'STD_BOX%')
    begin
      select @CartonType = 'STD_BOX';

      goto ExitHandler;
    end

  /* get the SKU details */
  select @vSKU              = SKU,
         @vSKU2             = SKU2,
         @vUnitsPerIP       = UnitsPerIP,
         @vShipPack         = ShipPack,
         @vSpacePerIP       = SpacePerIP,
         @vSpacePerUnit     = SpacePerUnit,
         @vWeightPerIP      = InnerPackWeight,
         @vWeightPerUnit    = UnitWeight,
         @vNestingFactor    = NestingFactor,
         @vMaxIPDimension   = MaxUnitDimension,
         @vMaxUnitDimension = MaxUnitDimension,
         @vFirstDimension   = FirstDimension,
         @vSecondDimension  = SecondDimension,
         @vThirdDimension   = ThirdDimension
  from #SKUs
  where SKUId = @SKUId;

  /* Calculate the minimum space required to Cube units, At minimum we can cube 1 unit,
   however, if the SKU is in innerpacks, then minimum units to cube may be units in 1 inner pack */
  select @vMinSpaceRequired = case when (@vUnitsPerIP > 0) and (@vSpacePerIP > 0) then @vSpacePerIP
                                   else @vSpacePerUnit * @vShipPack
                              end;

  /* compute the minimum weight required to Cube units, At minimum weight should be greater than WeightPerUnit
     however, if the SKU is in innerpacks, then minimum weight to cube may be WeightPerIP */
  select @vMinWeightRequired = case when (@vUnitsPerIP > 0) and (@vWeightPerIP > 0) then @vWeightPerIP
                                    else @vWeightPerUnit * @vShipPack
                               end;

  /* Calc remaining packing spaces for the order */
  select @vTotalSpaceRequired = sum(SpaceRequired),  -- $$ this should be accurate as it is calculated using the nesting factor.
         @vMaxFirstDimension  = max(FirstDimension),
         @vMaxSecondDimension = max(SecondDimension),
         @vMaxThirdDimension  = max(ThirdDimension),
         @vTotalUnits         = sum(QtyToCube),
         @vTotalWeight        = sum(ItemWeightToCube)
  from #DetailsToCube
  where (OrderId      = @OrderId       ) and
        (Status       = 'A'/* Active */) and
        (PackingGroup = @PackingGroup  );

  /* Get the Carton group for the order in question */
  select @vOrderCartonGroup = OrderCartonGroup
  from #OrdersToCube
  where (OrderId = @OrderId) and (PackingGroup = @PackingGroup);

  /* get smallest carton that can accommdate Total inventory */
  select top 1 @CartonType         = CartonType,
               @EmptyCartonSpace   = EmptyCartonSpace,
               @MaxUnitsPerCarton  = MaxUnits,
               @MaxWeightPerCarton = MaxWeight
  from #CartonTypes
  where (CartonGroup       = @vOrderCartonGroup  ) and
        (EmptyCartonSpace >= @vTotalSpaceRequired) and
        (FirstDimension   >= @vMaxFirstDimension ) and
        (SecondDimension  >= @vMaxSecondDimension) and
        (ThirdDimension   >= @vMaxThirdDimension ) and
        (MaxWeight        >= @vTotalWeight       ) and
        (MaxUnits         >= @vTotalUnits        )
  order by EmptyCartonSpace;

  /* if we didn't find a carton that can accommodate total inventory,
     then find the largest carton for that particular customer */
  if (@CartonType is null)
    select top 1 @CartonType         = CartonType,
                 @EmptyCartonSpace   = EmptyCartonSpace,
                 @MaxUnitsPerCarton  = MaxUnits,
                 @MaxWeightPerCarton = MaxWeight
    from #CartonTypes
    where (CartonGroup       = @vOrderCartonGroup ) and
          (FirstDimension   >= @vFirstDimension   ) and
          (SecondDimension  >= @vSecondDimension  ) and
          (ThirdDimension   >= @vThirdDimension   ) and
          (EmptyCartonSpace >= @vMinSpaceRequired ) and  -- Carton should atleast have space to hold 1 unit
          (MaxWeight        >= @vMinWeightRequired)      -- Carton should atleast hold weight of 1 unit
    order by EmptyCartonSpace desc;

  /* If we are able to find by volume and dimension, just try to find any carton by dimension */
  if (@CartonType is null)
    select @CartonType = 'STD_UNIT';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_FindOptimalCarton */

Go
