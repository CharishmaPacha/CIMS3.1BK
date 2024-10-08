/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/24. AY      Code optimization (CIDV3-894)
  2019/10/07  TK      pr_Cubing_PrepareToCubePicks & pr_Cubing_AddCartons: Initial Revision (CID-883)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_PrepareToCubePicks') is not null
  drop Procedure pr_Cubing_PrepareToCubePicks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_PrepareToCubePicks: This procedure adds required constraints or
    computed columns to the hash tables
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_PrepareToCubePicks
  (@WaveId             TRecordId,
   @Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vWaveId              TRecordId,
          @vWaveNo              TWaveNo,
          @vWaveType            TTypeCode;
begin /* pr_Cubing_PrepareToCubePicks */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Wave Info */
  select @vWaveId   = RecordId,
         @vWaveNo   = BatchNo,
         @vWaveType = BatchType
  from Waves
  where (RecordId = @WaveId);

  /* while creating hash tables constraints won't be created so drop the columns for which constraints
     are required and re create them */

  /* For #DetailsToCube */
  alter table #DetailsToCube drop column NestingFactor, CubedQty, QtyToCube, AllocatedIPs, CubedIPs, IPsToCube, SpaceRequired, TotalSpaceRequired, SpaceCubed, TotalWeight, SortSeq;
  alter table #DetailsToCube add NestingFactor            float          default 1.0,
                                 CubedQty                 integer        default 0,      -- Qty already cubed into cartons
                                 QtyToCube                as (AllocatedQty - CubedQty),             -- Units yet to be cubed

                                 AllocatedIPs             as case when UnitsPerIP > 0 then (AllocatedQty / UnitsPerIP) else 0 end,                             -- Original IPs allocated
                                 CubedIPs                 as case when UnitsPerIP > 0 then (CubedQty / UnitsPerIP) else 0 end,                                 --IPs already cubed
                                 IPsToCube                as case when UnitsPerIP > 0 then ((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP)) else 0 end, --IPs yet to be cubed

                                 SpaceRequired            as case when (AllocatedQty - CubedQty) = 0 then 0
                                                                  /* when IPstoCube > 0 and there are no units, then space is IPsToCube * SpaceperIP */
                                                                  when (UnitsPerIP > 0 and
                                                                       ((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP) /* IPsToCube */) > 0) and
                                                                       ((AllocatedQty - CubedQty) % UnitsPerIP) = 0 then
                                                                    (((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP)) * SpacePerIP)                         -- IPsToCube * SpacePerIP
                                                                  /* when IPstoCube > 0 and some units, then space is IPsToCube * SpaceperIP + Space for units considering nesting factor */
                                                                  when (UnitsPerIP > 0 and
                                                                       ((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP) /* IPsToCube */) > 0) then
                                                                   ((((AllocatedQty / UnitsPerIP) - (CubedQty / UnitsPerIP)) * SpacePerIP) +                       -- IPsToCube * SpacePerIP +
                                                                    (SpacePerUnit + (((AllocatedQty - CubedQty) % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor)) -- UnitsToCube * SpacePerUnit ~ Applying NestingFactor
                                                                  else
                                                                  /* when remaining qty is only units and there are no IPs */
                                                                    SpacePerUnit + ((AllocatedQty - CubedQty - 1) * SpacePerUnit * NestingFactor)
                                                             end, -- Space required for the remaining units which are yet to be cubed

                                 TotalSpaceRequired       as case when (AllocatedQty = 0) then 0
                                                                  /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * SpacePerIP */
                                                                  when (UnitsPerIP > 0 and (AllocatedQty / UnitsPerIP) /* IPsAllocated */ > 0) and
                                                                       (AllocatedQty % UnitsPerIP) = 0 then
                                                                    ((AllocatedQty / UnitsPerIP) * SpacePerIP)                                                    -- IPsAllocated * SpacePerIP
                                                                  /* when AllocatedIPs > 0, then it is IPsAllocated * SpacePerIP + Remainingunits * Spaces for units considering nesting factor */
                                                                  when (UnitsPerIP > 0 and (AllocatedQty / UnitsPerIP) /* IPsAllocated */ > 0) then
                                                                    (((AllocatedQty / UnitsPerIP) * SpacePerIP) +                                                  -- IPsAllocated * SpacePerIP +
                                                                    (SpacePerUnit + (((AllocatedQty % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor)))           -- UnitsAllocated * SpaceperUnit ~ Apply Nesting factor
                                                                  else
                                                                  /* when AllocatedQty is only units i.e. no IPs */
                                                                    SpacePerUnit + ((AllocatedQty - 1) * SpacePerUnit * NestingFactor)
                                                             end,

                                 SpaceCubed               as case when (CubedQty = 0) then 0
                                                                  /* when CubedQty is only IPs and ther are no remaining units */
                                                                  when (UnitsPerIP > 0) and (CubedQty % UnitsPerIP = 0) and (SpacePerIP > 0) then
                                                                    ((CubedQty / UnitsPerIP) * SpacePerIP)                                                        -- IPsCubed * SpacePerIP
                                                                  /* when CubedQty is IPs + some additonal units */
                                                                  when (UnitsPerIP > 0) and (CubedQty % UnitsPerIP > 0) and (SpacePerIP > 0) then
                                                                    (((CubedQty / UnitsPerIP) * SpacePerIP) +                                                      -- IPsCubed * SpacePerIP +
                                                                     (SpacePerUnit + ((CubedQty % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor))                 -- UnitsCubed * SpacePerUnit ~ Apply nesting factor
                                                                  else
                                                                  /* CubedQty is only units, no IPs */
                                                                    SpacePerUnit + ((CubedQty - 1) * SpacePerUnit * NestingFactor)
                                                             end,

                                 TotalWeight              as case when (AllocatedQty = 0) then 0
                                                                  /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * InnerPackWeight */
                                                                  when (UnitsPerIP > 0) and  (AllocatedQty % UnitsPerIP = 0) and (InnerPackWeight > 0) then
                                                                    ((AllocatedQty / UnitsPerIP) * InnerPackWeight)                                                    -- IPsAllocated * InnerPackWeight
                                                                  /* when AllocatedIPs > 0, then it is IPsAllocated * InnerPackWeight + Remainingunits * UnitWeight for units */
                                                                  when (UnitsPerIP > 0) and (AllocatedQty % UnitsPerIP > 0) and (InnerPackWeight > 0) then
                                                                    ((AllocatedQty / UnitsPerIP) * InnerPackWeight) +
                                                                    ((AllocatedQty % UnitsPerIP) * UnitWeight)
                                                                  else
                                                                  /* when AllocatedQty is only units i.e. no IPs */
                                                                    UnitWeight * AllocatedQty
                                                             end,
                                 ItemWeightToCube         as case when (AllocatedQty - CubedQty = 0) then 0
                                                                  /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * InnerPackWeight */
                                                                  when (UnitsPerIP > 0) and  ((AllocatedQty - CubedQty) % UnitsPerIP = 0) and (InnerPackWeight > 0) then
                                                                    (((AllocatedQty - CubedQty) / UnitsPerIP) * InnerPackWeight)                                                    -- IPsAllocated * InnerPackWeight
                                                                  /* when AllocatedIPs > 0, then it is IPsAllocated * InnerPackWeight + Remainingunits * UnitWeight for units */
                                                                  when (UnitsPerIP > 0) and ((AllocatedQty - CubedQty) % UnitsPerIP > 0) and (InnerPackWeight > 0) then
                                                                    (((AllocatedQty - CubedQty) / UnitsPerIP) * InnerPackWeight) +
                                                                    (((AllocatedQty - CubedQty) % UnitsPerIP) * UnitWeight)
                                                                  else
                                                                  /* when AllocatedQty is only units i.e. no IPs */
                                                                    UnitWeight * (AllocatedQty - CubedQty)
                                                             end,
                                 SortSeq                  integer       default 0;

  /* For #CubeCartonHdrs */
  alter table #CubeCartonHdrs drop column SpaceUsed, SpaceRemaining, WeightUsed, WeightRemaining, MaxUnits, MaxDimension, UnitsRemaining, NumUnits, NumSKUs;
  alter table #CubeCartonHdrs add SpaceUsed           float  default 0,
                                  SpaceRemaining      as (EmptyCartonSpace - SpaceUsed),

                                  WeightUsed          float  default 0,
                                  WeightRemaining     as (MaxWeight - WeightUsed),

                                  MaxUnits            integer,
                                  MaxDimension        float,
                                  UnitsRemaining      as (MaxUnits - NumUnits),

                                  NumUnits            integer  default 0,
                                  NumSKUs             integer  default 0;

  /* For #CubeCartonDtls */
  alter table #CubeCartonDtls drop column NestingFactor, UnitsCubed, SpaceUsed, WeightUsed;
  alter table #CubeCartonDtls add NestingFactor       float Default 1.0,
                                  UnitsCubed          integer                    default 0,
                                  SpaceUsed           as case when (UnitsCubed = 0) then 0
                                                              /* when CubedQty is only IPs and ther are no remaining units */
                                                              when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP = 0) and (SpacePerIP > 0) then
                                                                ((UnitsCubed / UnitsPerIP) * SpacePerIP)                                                        -- IPsCubed * SpacePerIP
                                                              /* when CubedQty is IPs + some additonal units */
                                                              when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP > 0) and (SpacePerIP > 0) then
                                                                (((UnitsCubed / UnitsPerIP) * SpacePerIP) +                                                      -- IPsCubed * SpacePerIP +
                                                                 (SpacePerUnit + ((UnitsCubed % UnitsPerIP) - 1) * SpacePerUnit * NestingFactor))                 -- UnitsCubed * SpacePerUnit ~ Apply nesting factor
                                                              else
                                                              /* CubedQty is only units, no IPs */
                                                                SpacePerUnit + ((UnitsCubed - 1) * SpacePerUnit * NestingFactor)
                                                         end,
                                  WeightUsed          as case when (UnitsCubed = 0) then 0
                                                              /* when AllocatedIPs > 0 and there are no remaining units, then it is IPsAllocated * InnerPackWeight */
                                                              when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP = 0) and (WeightPerIP > 0) then
                                                                ((UnitsCubed / UnitsPerIP) * WeightPerIP)                                                    -- IPsAllocated * InnerPackWeight
                                                              /* when AllocatedIPs > 0, then it is IPsAllocated * InnerPackWeight + Remainingunits * UnitWeight for units */
                                                              when (UnitsPerIP > 0) and (UnitsCubed % UnitsPerIP > 0) and (WeightPerIP > 0) then
                                                                ((UnitsCubed / UnitsPerIP) * WeightPerIP) +
                                                                ((UnitsCubed % UnitsPerIP) * WeightPerUnit)
                                                              else
                                                              /* when AllocatedQty is only units i.e. no IPs */
                                                                UnitsCubed * WeightPerUnit
                                                         end;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_PrepareToCubePicks */

Go
