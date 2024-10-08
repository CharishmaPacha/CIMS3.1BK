/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/18  TK      pr_Putaway_SuggestedQtyToPA: Suggest minimum quantity to putaway based upon ReservedQty instead of DirectedReservedQty (HA-990)
  2018/11/16  TK      pr_Putaway_SuggestedQtyToPA: Do not consider location capacity while computing minimum units to putaway (HPI-2152)
  2018/11/09  TK      pr_Putaway_MinimumQtyToPA -> pr_Putaway_SuggestedQtyToPA
                      pr_Putaway_SuggestedQtyToPA: MsgInfo with Primary & Secondary location quantities (HPI-2115)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_SuggestedQtyToPA') is not null
  drop Procedure pr_Putaway_SuggestedQtyToPA;
Go
/*------------------------------------------------------------------------------
  pr_Putaway_SuggestedQtyToPA:
    This Proc returns the Max qty that can be fit into a Location and user an defined msg. Max Qty would be atleast
  Directed Reserve Qty when Location is full, or Location Qty is less that LPNQty. Or it would
  be Max of LPN Qty & Location capacity
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_SuggestedQtyToPA
  (@LPNId               TRecordId,
   @LocationId          TRecordId,
   @SKUId               TRecordId,
   @PrimaryLocPAQty     TQuantity  output,
   @SecondaryLocPAQty   TQuantity  output,
   @MessageInfo         TMessage   output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vLocCapacity        TQuantity,
          @vTotalLocQty        TQuantity,
          @vTotalDRQty         TQuantity,
          @vTotalReservedQty   TQuantity,
          @vDynamicAvailQty    TQuantity,
          @vQtyRequiredInDynamicLoc
                               TQuantity,
          @vLocMaxUnits        TQuantity,
          @vLocMinUnits        TQuantity,
          @vLocMinLevelReach   TQuantity,
          @vMinQtyToPA         TQuantity,
          @vLPNQty             TQuantity;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* get the LPNQuantity */
  select @vLPNQty = Quantity
  from LPNs
  where (LPNId = @LPNId);

  /* get the max units that can be fit into location */
  select top 1 @vLocMaxUnits = MaxReplenishLevelUnits,
               @vLocMinUnits = MinReplenishLevelUnits
  from vwLocationsToReplenish
  where (LocationId = @LocationId) and
        (SKUId      = @SKUId);

  /* get the total Location Qty & total directed Qty */
  /* There is no directed reserve concept now, so get the compute quanities based upon reserved quantities  */
  select @vTotalLocQty      = coalesce(sum(case when LD.OnhandStatus in ('A', 'R' /* Available, Reserved */) then LD.Quantity else 0 end), 0),
         @vTotalDRQty       = coalesce(sum(case when LD.OnhandStatus = 'D'/* Directed */ then LD.ReservedQty else 0 end), 0),
         @vTotalReservedQty = coalesce(sum(case when LD.OnhandStatus in ('A', 'R', 'D'/* Available, Reserved, Directed */) then LD.ReservedQty else 0 end), 0)
  from Locations    LOC
    join LPNs       L   on (L.LocationId = LOC.LocationId)
    join LPNDetails LD  on (LD.LPNId = L.LPNId) and (LD.SKUId = @SKUId)
  where (LOC.LocationId = @LocationId);

  /* Get the Available Quantity available for the SKU in dynamic locations */
  select @vDynamicAvailQty = coalesce(sum(LD.Quantity), 0)
  from LPNDetails LD
    join LPNs      L   on (LD.LPNId = L.LPNId)
    join Locations Loc on (L.LocationId = Loc.LocationId)
  where (LD.SKUId            = @SKUId) and
        (LD.OnHandStatus     = 'A'/* Available  */) and
        (Loc.LocationType    = 'K'/* Picklane */) and
        (Loc.LocationSubType = 'D'/* Dynamic */);

  /* Qty to be putaway in dynamic location is the difference between OnDemand quantity and available quantity in dynamic location */
  select @vQtyRequiredInDynamicLoc = case when (@vTotalReservedQty > @vDynamicAvailQty)
                                            then @vTotalReservedQty - @vDynamicAvailQty
                                          else 0
                                     end;

  /* LocMaxUnits = Maximum units that can fit into the Location or the maximum demand for orders in the Location. i.e.
     this is the number of units that are needed to be PA into the location */
  /* Compute Min Qty that can be putaway, it should be min of LPNQty, MaxUnits that can fit in location & DirectedResvereQty */
  select @vLocCapacity      = (@vLocMaxUnits - @vTotalLocQty),
         @vLocMinLevelReach = (@vLocMinUnits - @vTotalLocQty),
         @PrimaryLocPAQty   = dbo.fn_MinInt(@vLPNQty, @vTotalDRQty),
         @SecondaryLocPAQty = dbo.fn_MinInt(@vLPNQty, @vQtyRequiredInDynamicLoc);

  /* if total Min Qty to Putaway is greater than zero then build message and return message to RF */
  if (@PrimaryLocPAQty > 0)
    begin
      if (@SecondaryLocPAQty > 0)
        select @MessageInfo = dbo.fn_Messages_Build('PALPN_MsgInfoWithPriAndSecLocQty', @PrimaryLocPAQty, @SecondaryLocPAQty, @vLocCapacity, null, null);
      else
      if (@vLPNQty <> @PrimaryLocPAQty) and (@vLocCapacity > 0) and (@vLocCapacity < @vTotalDRQty)
        select @MessageInfo = dbo.fn_Messages_Build('PALPN_MsgInfoWithLocQty', @vTotalDRQty, @vLocCapacity, null, null, null);
      else
      if (@vLPNQty <> @PrimaryLocPAQty) and (@vLocCapacity <= 0)
        select @MessageInfo = dbo.fn_Messages_Build('PALPN_MsgInfoWithoutLocQty', @vTotalDRQty, null, null, null, null);
    end
  else
  if (@vLocMinLevelReach > 0)
    select @MessageInfo = dbo.fn_Messages_Build('PALPN_MsgInfoUptoMinLevel', @vLocCapacity, @vLocMinLevelReach, null, null, null);
  else
    select @MessageInfo = dbo.fn_Messages_Build('PALPN_MsgInfoNoDemand', @vLocCapacity, null, null, null, null);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Putaway_SuggestedQtyToPA */

Go
