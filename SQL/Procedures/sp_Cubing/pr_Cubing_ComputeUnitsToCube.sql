/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_ComputeUnitsToCube') is not null
  drop Procedure pr_Cubing_ComputeUnitsToCube;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_ComputeUnitsToCube: Given the remaining space, units and weight
   in a carton, determine how much of (IPs or Units) the given SKU can be added
   to the carton being considered.

   QtyToCube could be IPs + some more units as well. If so, we cube the IPs first.
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_ComputeUnitsToCube
  (@SKUId             TRecordId,
   @CartonType        TCartonType,
   @QtyToCube         TInteger,
   @RemainingSpace    TFloat,
   @RemainingUnits    TInteger,
   @RemainingWeight   TWeight,
   @UnitsToCube       TInteger output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vIPsToCube           TInteger,
          @vQtyToCube           TInteger,
          @vSKUShipPack         TInteger,
          @vNestingFactor       TFloat,
          @vSpacePerUnit        TFloat,
          @vSpacePerIP          TFloat,
          @vWeightPerIP         TWeight,
          @vWeightPerUnit       TWeight,
          @vUnitsPerIP          TInteger,
          @vMaxUnitsPossible    TInteger,
          @vMaxUnits            TInteger,
          @vMaxUnitsByWeight    TInteger,
          @vMaxUnitsBySpace     TInteger,
          @vUnitsToCube         TInteger; -- Final Result
begin
SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@QtyToCube = 0) return (0);

  /* Initialize */
  select @vIPsToCube = 0,
         @vQtyToCube = @QtyToCube;

  /* Get the ShipPack of the SKU */
  select @vSKUShipPack   = ShipPack,
         @vSpacePerIP    = SpacePerIP,
         @vSpacePerUnit  = SpacePerUnit,
         @vUnitsPerIP    = UnitsPerIP,
         @vWeightPerIP   = InnerPackWeight,
         @vWeightPerUnit = UnitWeight,
         @vNestingFactor = NestingFactor
  from #SKUs
  where (SKUId = @SKUId);

  /* If each carton is to be cubed to a carton by itself */
  if (@CartonType = 'STD_UNIT')
    begin
      select @UnitsToCube = 1;
      return (0);
    end

  /* If each IP is to be cubed to a carton by itself.. */
  if (@CartonType = 'STD_BOX')
    begin
      select @UnitsToCube = @vUnitsPerIP;
      return (0);
    end

  /* If SKU in InnerPacks and QtyToCube is greater than or equal to 1 IP, then figure out how many IPs to cube */
  if (@QtyToCube >= @vUnitsPerIP) and (@vUnitsPerIP > 0)
    select @vIPsToCube = (@QtyToCube / @vUnitsPerIP);

  /* If Carton does not have space for even 1 IP, then we cannot cube any IPs
     and so we should cube the remaining units */
  if (@vIPsToCube > 0) and (@RemainingSpace < @vSpacePerIP)
    select @vIPsToCube = 0,
           @vQtyToCube = (@vQtyToCube % @vUnitsPerIP);  -- in case there are individual units to cube
  else
  /* If Carton does not have space for even 1 ShipPack, then we cannot cube any items
     and so we should cube in next carton */
  if (@vSKUShipPack > 1) and (@RemainingSpace < (@vSpacePerUnit * @vSKUShipPack))
    select @vQtyToCube = 0;
  else
  if (@RemainingSpace < @vSpacePerUnit)
    select @vQtyToCube = 0;

  /* if we cannot accommodate any units then exit */
  if (@vQtyToCube = 0) return (0);

  /* If we are cubing IPs, then use @SpacePerIP and determine how many IPs to cube */
  if (@vIPsToCube > 0)
    begin
      select @vMaxUnits         = dbo.fn_MinInt(@RemainingUnits, @vUnitsPerIP * @vIPsToCube),
             @vMaxUnitsByWeight = case when (@vWeightPerIP > 0) then @vUnitsPerIP * floor(@RemainingWeight / @vWeightPerIP)
                                       else floor(@RemainingWeight / @vWeightPerUnit)
                                  end,
             @vMaxUnitsBySpace  = case when (@vSpacePerIP > 0) then @vUnitsPerIP * floor(@RemainingSpace / @vSpacePerIP)
                                       else floor((@RemainingSpace - @vSpacePerUnit) / (@vSpacePerUnit * @vNestingFactor)) + 1
                                  end;

      select @vMaxUnitsPossible = dbo.fn_MinOfThree(@vMaxUnits, @vMaxUnitsByWeight, @vMaxUnitsBySpace);
    end
  else
    begin
      select @vMaxUnits         = dbo.fn_MinInt(@RemainingUnits, @vQtyToCube),
             @vMaxUnitsByWeight = floor(@RemainingWeight / @vWeightPerUnit),
             @vMaxUnitsBySpace  = floor((@RemainingSpace - @vSpacePerUnit) / (@vSpacePerUnit * @vNestingFactor)) + 1;

      /* If not in IPs, then determine Max possible units within the space considering the nesting factor */
      select @vMaxUnitsPossible = dbo.fn_MinOfThree(@vMaxUnits, @vMaxUnitsByWeight, @vMaxUnitsBySpace);
    end

  /* Compute units to cube into a carton of this type i.e. given the carton size, we
     need to figure out how many units of the given SKU can be cubed into it */
  select @UnitsToCube = dbo.fn_MinInt(@QtyToCube, @vMaxUnitsPossible);

  /* We can only split in multiples of ShipPack, so if UnitsToCube is not in multiples of ShipPack,
     reduce it such that it would be. We shoulnd't have UnitsToCube be less than Shippack, but if that
     does happen, cube whatever units are to be cubed */
  if (@vSKUShipPack > 1) and
     (@UnitsToCube % @vSKUShipPack <> 0) and
     (@UnitsToCube > @vSKUShipPack)
    select @UnitsToCube = @UnitsToCube - @UnitsToCube % @vSKUShipPack;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_Cubing_ComputeUnitsToCube */

Go
