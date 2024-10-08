/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/21  TK      pr_LPNs_EstimateCartonDims: Initial Revision (HA-2664)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_EstimateCartonDims') is not null
  drop Procedure pr_LPNs_EstimateCartonDims;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_EstimateCartonDims: This proc evaluates the appropriate carton type,
    dimensions and weight of given set of LPNs

  #CartonDims -> TCartonDims
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_EstimateCartonDims
  (@WaveId             TRecordId  = null,
   @Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vUseSKUDimensions      TControlValue;

  declare @ttCartonTypes          TCartonTypes,
          @ttOrdersToCube         TOrdersToCube;
begin /* pr_LPNs_EstimateCartonDims */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Create required hash tables */
  select * into #CartonTypes from @ttCartonTypes;
  select * into #OrdersToCube from @ttOrdersToCube;

  /* Get controls */
  select @vUseSKUDimensions = dbo.fn_Controls_GetAsString('Cubing', 'UseSKUDimensions', 'Y' /* Yes */, @BusinessUnit, system_user);

  /* Get the Orders that needs to be cubed */
  insert into #OrdersToCube (OrderId, OrderCartonGroup)
    select distinct OH.OrderId, OH.CartonGroups
    from #CartonDims CD
      join OrderHeaders OH on (CD.OrderId = OH.OrderId);

  /* Get the types of cartons that are applicable for this order */
  exec pr_Cubing_GetCartonTypes null, @WaveId, @BusinessUnit;

  /* Populate Required values in #CartonDims */
  ;with ComputedCartonDims as
   (
     select LD.LPNId,
            sum(LD.Quantity) as LPNQuantity,
            sum(LD.Quantity * S.UnitWeight) as PackageWeight,
            sum(LD.Quantity * S.UnitVolume) as PackageVolume,
            max(case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.FirstNumber  else 0.1 end) as FirstDimension, /* If SKU dims cannot be used then insert with least value */
            max(case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.SecondNumber else 0.1 end) as SecondDimension,
            max(case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.ThirdNumber  else 0.1 end) as ThirdDimension
    from #CartonDims CD
      join LPNDetails LD on (CD.LPNId = LD.LPNId)
      join SKUs       S  on (LD.SKUId = S.SKUId)
      cross apply dbo.fn_SortValuesAscending(S.UnitLength, S.UnitWidth, S.UnitHeight) FN
    group by LD.LPNId
   )
   update CD
   set LPNQuantity     = CCD.LPNQuantity,
       PackageWeight   = CCD.PackageWeight,
       PackageVolume   = CCD.PackageVolume,
       FirstDimension  = CCD.FirstDimension,
       SecondDimension = CCD.SecondDimension,
       ThirdDimension  = CCD.ThirdDimension,
       CartonGroup     = OTC.OrderCartonGroup
   from #CartonDims CD
     join ComputedCartonDims CCD on (CD.LPNId = CCD.LPNId)
     join #OrdersToCube OTC on (CD.OrderId = OTC.OrderId);

  /* Identify the best suitable carton type for the give set of LPNs */
  ;with EstimatedCartonTypes as
   (
     select CD.LPNId, CT.CartonType, CT.EmptyCartonSpace as CartonVolume, CT.EmptyWeight,
            row_number() over (partition by LPNId order by EmptyCartonSpace) as RecordId  -- Partitions the dataset by LPNId and orders the dataset by EmptyCartonSpace ascending
     from #CartonDims CD
       join #CartonTypes CT on (CD.CartonGroup = CT.CartonGroup)
     where (CT.EmptyCartonSpace >= CD.PackageVolume  ) and
           (CT.MaxWeight        >= CD.PackageWeight  ) and
           (CT.FirstDimension   >= CD.FirstDimension ) and
           (CT.SecondDimension  >= CD.SecondDimension) and
           (CT.ThirdDimension   >= CD.ThirdDimension ) and
           (CT.MaxUnits         >= CD.LPNQuantity    )
   )
   update CD
   set CartonType    = coalesce(ECT.CartonType, 'STD_BOX'),            -- If no carton type found then use STD_BOX as carton type
       PackageVolume = coalesce(ECT.CartonVolume, CD.PackageVolume),   -- No matter what that computed volume is! but if there is a carton type then just use its volume
       PackageWeight = CD.PackageWeight + coalesce(ECT.EmptyWeight, 0) -- Add Carton weight to computed weight
   from #CartonDims CD
     left outer join EstimatedCartonTypes ECT on (CD.LPNId = ECT.LPNId) and (ECT.RecordId = 1); -- which means take the carton type of the first record as EstimatedCartonTypes will have all applicable carton types for LPN

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_EstimateCartonDims */

Go
