/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  VS      pr_Locations_Recalculate, pr_Locations_UpdateCount: Passed EntityStatus Parameter (BK-910)
  2017/12/19  TD      pr_Locations_UpdateCount:Changes to update Volume and weight on location (CIMS-1750)
  2017/08/29  TK      pr_Locations_UpdateCount: Invoke RequestRecalcCounts to defer Location count updates (HPI-1644)
  2017/04/24  AY      pr_Locations_UpdateCount: Fix issue with -ve qty on Locations (HPI-687)
  2016/11/16  AY      pr_Locations_UpdateCount: Correct location counts to prevent -ve (HPI-GoLive).
  2016/03/15  OK      pr_Locations_UpdateCount, pr_Locations_SetStatus: Get the Transient Locations from control var for Counts and setting status (NBD-283)
  2015/07/19  AY      pr_Locations_UpdateCounts: Do not need to keep track of counts in Staging, Dock Locations
                      pr_Locations_UpdateCount:bug fix: Made changes to get 0 if the sum of the quantity is null.
  2014/03/04  PK      pr_Locations_UpdateCount: Changed the UpdateOption default value to *
  2014/01/13  AY      pr_Locations_UpdateCount/SetStatus: Avoid repeated counting of Qty in the Location
  2013/11/11  NY      pr_Locations_UpdateCount: Updating Status for Staging, bulk and dock locations.
  2013/11/10  AY      pr_Locations_UpdateCount: Keep counts on Dock/Staging. Enhance to recalc counts (to be used for fixing and in CC)
  2013/05/15  AY      pr_Locations_UpdateCount: Changed to ignore counts for SDC locations
  2013/02/25  AY      pr_Locations_UpdateCount: Optimized to not keep track of Counts on Conveyor Locations
  2010/12/10  VM      Added pr_Locations_SetStatus and modified pr_Locations_UpdateCount to call new procedure.
  2010/12/03  PK      pr_Locations_UpdateCount : Replaced UpdateOption(wip) - Changes.
  2010/12/03  VM      pr_Locations_Summarize => pr_Locations_UpdateCount:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_UpdateCount') is not null
  drop Procedure pr_Locations_UpdateCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_UpdateCount:

  /* '=' - Exact Qty, '+' - Add Qty, '-' - Subtract Qty , '*' - Recalculate */
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_UpdateCount
  (@LocationId   TRecordId     = null,
   @Location     TLocation     = null,
   @UpdateOption TFlags        = '*',
   @NumPallets   TCount        = null,
   @NumLPNs      TCount        = null,
   @InnerPacks   TInnerPacks   = null,
   @Quantity     TQuantity     = null,
   @ProcId       TInteger      = null,
   @Operation    TOperation    = null,
   @BusinessUnit TBusinessUnit = null)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,

          @vLocationId                 TRecordId,
          @vLocation                   TLocation,
          @vCurrentMultiplier          TInteger,
          @vNewMultiplier              TInteger,
          @vLocationType               TLocationType,
          @vCurrLPNs                   TCount,
          @vCurrInnerPacks             TCount,
          @vCurrQuantity               TCount,

          @vCurrWeight                 TWeight,
          @vCurrVolume                 TVolume,

          @ttLocations                 TRecountKeysTable,

          @vIgnoreLocationsToSetStatus TControlValue,
          @vBusinessUnit               TBusinessUnit;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@LocationId is null) and (@Location is not null)
    select @vLocationId     = LocationId,
           @vLocation       = Location,
           @vLocationType   = LocationType,
           @vCurrLPNs       = NumLPNs,
           @vCurrInnerPacks = InnerPacks,
           @vCurrQuantity   = Quantity,
           @vBusinessUnit   = BusinessUnit
    from Locations
    where (Location = @Location) and (BusinessUnit = @BusinessUnit);
  else
    select @vLocationId     = LocationId,
           @vLocation       = Location,
           @vLocationType   = LocationType,
           @vCurrLPNs       = NumLPNs,
           @vCurrInnerPacks = InnerPacks,
           @vCurrQuantity   = Quantity,
           @vBusinessUnit   = BusinessUnit
    from Locations
    where (LocationId = @LocationId);

  /* defer Location re-count for later */
  if (charindex('$', @UpdateOption) > 0)
    begin
      /* invoke RequestRecalcCounts to defer Location count updates */
      exec pr_Entities_RequestRecalcCounts 'Location', @vLocationId, @vLocation, 'S'/* RecalcOption */,
                                           @@ProcId, @Operation, @vBusinessUnit, null /* EntityStatus */, @ttLocations;

      goto ExitHandler;
    end

  /* Get the transient locations from Control Var */
  select @vIgnoreLocationsToSetStatus = dbo.fn_Controls_GetAsString('Location', 'IgnoreLocationsToSetStatus', 'C' /* Conveyor */, @vBusinessUnit /* BusinessUnit */, System_User /* UserId */);

  /* If any of the counts are already -ve or will lead to -ve on update, then re-calc */
  if (@vCurrLPNs < 0) or (@vCurrInnerPacks < 0) or (@vCurrQuantity < 0)  or
     ((@UpdateOption = '-') and (@NumLPNs    > @vCurrLPNs      )) or
     ((@UpdateOption = '-') and (@InnerPacks > @vCurrInnerPacks)) or
     ((@UpdateOption = '-') and (@Quantity   > @vCurrQuantity  ))
    select @UpdateOption = '*' /* Recalculate */;

  /* if we are recalculating status anyway, then skip thip part as we don't need to do it twice */
  if (@UpdateOption = '*') goto SetStatus;

  /* We do not need to keep track of counts in transient locations, so leave them at zero always */
   if (charindex(@vLocationType, @vIgnoreLocationsToSetStatus) > 0)
    select @vCurrentMultiplier = '0',
           @vNewMultiplier     = '0';
  else
  if (@UpdateOption = '=' /* Exact */)
    select @vCurrentMultiplier = '0',
           @vNewMultiplier     = '1';
  else
  if (@UpdateOption = '+' /* Add */)
    select @vCurrentMultiplier = '1',
           @vNewMultiplier     = '1';
  else
  if (@UpdateOption = '-' /* Subtract */)
    select @vCurrentMultiplier = '1',
           @vNewMultiplier     = '-1';
  else
  if (@UpdateOption = '*' /* Recalculate */)
    begin
      select @vCurrentMultiplier = '0',
             @vNewMultiplier     = '1';

      select @NumPallets  = count(distinct PalletId),
             @NumLPNs     = count(*),
             @InnerPacks  = coalesce(sum(InnerPacks), 0),
             @Quantity    = coalesce(sum(Quantity), 0),
             @vCurrVolume = sum(LPNVolume),
             @vCurrWeight = sum(LPNWeight)
      from LPNs
      where (LocationId = @LocationId);
    end

  /* 1. update Counts */
  update Locations
  set NumPallets  = coalesce((NumPallets  * @vCurrentMultiplier) +
                            (@NumPallets * @vNewMultiplier), NumPallets),
      NumLPNs     = coalesce((NumLPNs     * @vCurrentMultiplier) +
                            (@NumLPNs    * @vNewMultiplier), NumLPNs),
      InnerPacks  = coalesce((InnerPacks  * @vCurrentMultiplier) +
                             (@InnerPacks * @vNewMultiplier), InnerPacks),
      Quantity    = coalesce((Quantity    * @vCurrentMultiplier) +
                             (@Quantity   * @vNewMultiplier), Quantity),
      Volume      = coalesce((Volume  * @vCurrentMultiplier) +
                             (@vCurrVolume * @vNewMultiplier), Volume),
      Weight      = coalesce((Weight * @vCurrentMultiplier) +
                             (@vCurrWeight * @vNewMultiplier), Weight)
  where (LocationId = @vLocationId);

SetStatus:

  /* Call procedure to set Location status */
  exec @vReturnCode = pr_Locations_SetStatus @vLocationId, '*';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_UpdateCount */

Go
