/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/28  VS      pr_Putaway_FindLocationForLPN, pr_Putaway_FindLocationForPallet: Added Control to if no location found move to next screen (HA-288)
  2019/02/14  AY      pr_Putaway_FindLocationForLPN: Changed to limit finding of Locations within LPN DestZone if there is one
                      pr_Putaway_FindLocationForLPN
  2017/02/20  OK      pr_Putaway_FindLocationForLPN: Enhanced to do not suggest the on hold location to putaway inventory (GNC-1426)
  2016/10/28  AY      pr_Putaway_FindLocationForLPN: Migrated from onsite (HPI-GoLive)
  2016/10/24  AY      pr_Putaway_FindLocationForLPN: Always allow to PA to pick lane (temp fix.)
  2016/01/04  TK      pr_Putaway_FindLocationForLPN: Consider max units per Location while suggesting Location(NBD-84)
  2015/11/05  RV      pr_Putaway_FindLocationForLPN: PA Rules order by Sequence No (FB-493)
                      pr_Putaway_FindLocationForLPN.
                      pr_Putaway_FindLocationForLPN: Validating Warehouse while doing putaway
  2013/05/30  AY      pr_Putaway_FindLocationForLPN: Enhanced to PA Cart Positions directly to Pickanes
  2013/05/29  TD      pr_Putaway_PAPalletNextLPNResponse:  Added new params to pr_Putaway_FindLocationForLPN.
  2013/03/25  PK      pr_Putaway_FindLocationForLPN, pr_Putaway_PAPalletNextLPNResponse:
  2012/08/21  VM/NY   pr_Putaway_FindLocationForLPN: Modified to set LPNType = 'L' for all normal LPNs to find location to Putaway
  2012/01/12  PK      pr_Putaway_FindLocationForLPN: Made changes to find a location which has less quantity to Putaway,
                      pr_Putaway_FindLocationForLPN: Default value for @vReturnCode, set @vMessageName as o/p param
  2011/11/27  AY      pr_Putaway_FindLocationForLPN: Enhanced to PA from Cart positions.
  2011/08/19  VM      pr_Putaway_FindLocationForLPN: Bug-fix - Find a location other than current location
  2011/08/11  VM      pr_Putaway_FindLocationForLPN: Bug-fix - Clean records in temp table which is used in loop
  2011/07/25  AY/VM   pr_Putaway_FindLocationForLPN: Find location based on LastPutawayDate on LPNDetail
  2011/07/22  VM      pr_Putaway_FindLocationForLPN: Consider null valued rules as well for LPNType, PutawayClass
  2011/07/20  VM      pr_Putaway_FindLocationForLPN: Bug-fix + return LocStorageType as well
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_FindLocationForLPN') is not null
  drop Procedure pr_Putaway_FindLocationForLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_FindLocationForLPN: This procedure is the core of the Directed
    putaway logic. It takes an LPN as input and uses the info of the LPN and
    applies the putaway rules in sequence until a valid location to putaway is
    found. When found, it returns the Zone, the Location and it's storage type.

  This is now enhanced to find a Location for an LPN or an LPN Detail based upon
  PAType. If PAType is L, then we intend to find a Location for an
  LPN i.e to PA entire LPN into a Location, else we try to find location for
  the LPN Detail i.e. to PA the LPN contents. If none is given, it determined
  here.
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_FindLocationForLPN
  (@LPNId              TRecordId,
   @SKUId              TRecordId,
   @PAType             TFlags,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId,
   ----------------------------------------------
   @DestZone           TLookUpCode  = null output,
   @DestLocation       TLocation    = null output,
   @DestLocStorageType TStorageType = null output,
   @PASKUId            TRecordId    = null output,
   @PAInnerPacks       TInnerPacks  = null output,
   @PAQuantity         TQuantity    = null output,
   @MessageName        TMessageName = null output)
as
  declare @ReturnCode        TInteger,
          @Message           TDescription,
          @vDebug            TFlags,

          @vLPNType          TTypeCode,
          @vLPNLocationId    TRecordId,
          @vLPNQty           TQuantity,
          @vLPNIPs           TQuantity,
          @vLPNWeight        TWeight,
          @vLPNVolume        TVolume,
          @vLPNPalletId      TRecordId,
          @vPALPNType        TTypeCode,
          @vPalletType       TTypeCode,
          @vPutawayType      TControlValue,
          @vDestWarehouse    TWarehouse,
          @vLPNDestZone      TZoneId,
          @vSKUId            TRecordId,
          @vSKUCount         TCount,
          @vUnitsPerIP       TQuantity,
          @vUnitsPerLPN      TQuantity,

          @vUnitWeight       TWeight,
          @vSKUPutawayClass  TCategory,
          @vLPNPutawayClass  TCategory,

          @vRuleCount        TCount,
          @vRulePRRecordId   TRecordId,
          @vRecordId         TRecordId,
          @vRuleSKUExists    TFlag,
          @vRuleLocStatus    TStatus,
          @vRuleLocClass     TCategory,
          @vCurrentRule      TInteger;

  declare @ttPutawayRules Table
          (RecordId            TRecordId identity (1,1),
           PRRecordId          TRecordId,
           SequenceNo          TInteger,
           LocationType        TLocationType,
           StorageType         TStorageType,
           LocationStatus      TStatus,
           PutawayZone         TLookupCode,
           Location            TLocation,
           SKUExists           TFlag,
           PalletPutawayClass  TPutawayClass,
           Warehouse           TWarehouse,
           LocationClass       TCategory,

           Primary Key         (RecordId));

  declare @ttLocationsFiltered Table
          (LocationId          TRecordId,
           Location            TLocation,
           LocationType        TLocationType,
           LocStorageType      TStorageType,
           PutawayZone         TLookupCode,
           PutawayPath         TLocation,
           Units               TQuantity,
           AllowMultipleSKUs   TFlag,

           MinReplenishLevel   TQuantity,
           MaxReplenishLevel   TQuantity,
           ReplenishUoM        TUoM,

           MaxUnitsPerLocation TQuantity,

           Primary Key    (LocationId));
begin
  SET NOCOUNT ON;
  select @ReturnCode  = 0,
         @MessageName        = null,
         @DestZone           = null,
         @DestLocation       = null,
         @DestLocStorageType = null,
         @PASKUId            = null,
         @PAInnerPacks       = null,
         @PAQuantity         = null,
         @vDebug             = 'N';

  /* Get the controls values */
  select @vPutawayType = dbo.fn_Controls_GetAsString('Putaway', 'PutawayType', 'SUGGESTED' /* Suggested Putaway */,  @BusinessUnit, @UserId);

  /* Get SKU and then PutawayClass for LPN */
  select @vSKUCount = count(*),
         @vSKUId    = Min(SKUId)
  from LPNDetails
  where (LPNId        = @LPNId) and
        (SKUId        = coalesce(@SKUId, SKUId)) and
        (BusinessUnit = @BusinessUnit);
  --group by SKUId;

  if (@vSKUCount > 1)
    begin
      select @vSKUPutawayClass = 'MixedSKU',
             @vSKUId           = null;
    end
  else
    select @vSKUPutawayClass = PutawayClass,
           @vUnitWeight      = UnitWeight,
           @vUnitsPerIP      = UnitsPerInnerPack,
           @vUnitsPerLPN     = UnitsPerLPN
    from SKUs
    where (SKUId = @vSKUId);

  /* Get LPN Info */
  select @vLPNType         = LPNType,
         @vLPNLocationId   = LocationId,
         @vLPNPalletId     = PalletId,
         @vDestWarehouse   = DestWarehouse,
         @vLPNDestZone     = DestZone,
         @vLPNWeight       = coalesce(ActualWeight, EstimatedWeight, 0.0),
         @vLPNVolume       = coalesce(ActualVolume, EstimatedVolume, 0.0),
         @vLPNPutawayClass = PutawayClass,
         @vLPNIPs          = InnerPacks,
         @vLPNQty          = Quantity
  from LPNs
  where (LPNId = @LPNId);

  /* If the LPN is a position on the Cart, then use the Pallet Type as
     LPN Type for Directed Putaway */
  if (@vLPNPalletId is not null)
    select @vPalletType = PalletType
    from Pallets
    where (PalletId = @vLPNPalletId)

  /* If PA Type is LPNs, and LPN happens to be on a Pallet, then consider the putaway type
     as PalletType for Cart Type LPN or LPNs on Pallet for non-cart Pallet LPNs */
  if ((coalesce(@PAType, '') = 'L' /* LPN */) and (@vLPNPalletId is not null))
    select @PAType = Case
                       when (@vLPNType = 'A' /* Cart */) then
                         @vPalletType
                       else
                         'LP' /* PA LPNs on Pallet */
                     end;

  /* Determine the PA Type, if not given */
  if (@PAType is null)
    select @PAType = case when (@vLPNPalletId is not null) and (@vSKUCount > 1) then
                            'LD' /* PA LPN Details */
                          when (@vLPNPalletId is not null) and (@vSKUCount = 1) then
                            'LP' /* PA LPNs on Pallet */
                          when (@vLPNPalletId is not null) and (@vLPNType = 'A' /* Cart */) then
                            @vPalletType
                          when (@vLPNPalletId is null) and (@vSKUCount = 1) then
                            'L' /* PA LPN */
                          when (@vLPNPalletId is null) and (@vSKUCount > 1) then
                            'LD' /* PA LPN Detail */
                     end;

  /* Get all active putaway rules that apply to the LPN into temp table */
  insert into @ttPutawayRules(PRRecordId, SequenceNo, LocationType, StorageType, LocationStatus,
                              PutawayZone, Location, SKUExists, PalletPutawayClass, Warehouse,
                              LocationClass)
    select RecordId, SequenceNo, LocationType, StorageType, LocationStatus,
           PutawayZone, Location, SKUExists, PalletPutawayClass, Warehouse,
           LocationClass
    from vwPutawayRules
    where (PAType = @PAType) and
          ((LPNType         is null) or (LPNType         = @vLPNType        )) and
          ((PalletType      is null) or (PalletType      = @vPalletType     )) and
          ((SKUPutawayClass is null) or (SKUPutawayClass = @vSKUPutawayClass)) and
          ((LPNPutawayClass is null) or (LPNPutawayClass = @vLPNPutawayClass)) and
          ((Warehouse       is null) or (Warehouse       = @vDestWarehouse  )) and
          ((@vLPNDestZone   is null) or (PutawayZone     = coalesce(@vLPNDestZone, PutawayZone))) and
          (BusinessUnit = @BusinessUnit) and
          (Status       = 'A' /* Active */)
    order by SequenceNo;

  select @vRuleCount = @@rowcount,
         @vRecordId  = 0;

  if (charindex('D', @vDebug) > 0) select * from @ttPutawayRules;

  ---Loop through all rules---
  while (exists(select * from @ttPutawayRules where RecordId > @vRecordId))
    begin
      select top 1 @vRulePRRecordId = PRRecordId,
                   @vRuleSKUExists  = SKUExists,
                   @vRuleLocStatus  = LocationStatus,
                   @vRuleLocClass   = LocationClass,
                   @vRecordId       = RecordId
      from @ttPutawayRules
      where (RecordId > @vRecordId)
      order by RecordId;

      /* As we loop through - clean any existing records from @ttLocationsFiltered */
      delete from @ttLocationsFiltered;

      /* Insert all locations other than LPN's current location (for LPNs with status 'Putaway'),
         which fall under the all rules except SKUExists rule.
         If we are trying to find a Location to putaway contents of the cart-position then @PAType = @PalletType
         i.e. @vPalletType = Flat or Hanging. In such a scenario if the goods are flat, find Location where
         Storage Type is Units Flat and if the good are hanging, find a Units Hanging Location
         Also filters the location which is onhold and do allowed for PA

         TD-Added changes to consider LocationClass while doing putaway.
            And added check to consider whether the location has enough space to hold the LPN/Units in it. This will be done
            by based on the AvailableCapacity. AvailableCapacity will be MaxValue - CurrentValue in the location

            For Picklanes, we will consider units only */

      insert into @ttLocationsFiltered
        select LocationId, Location, LocationType, StorageType, PutawayZone, PutawayPath, Quantity, AllowMultipleSKUs,
               MinReplenishLevel, MaxReplenishLevel, ReplenishUoM, 0 /* MaxUnitsPerLocation */
        from vwPutawayLocations
        where (PRRecordId  =  @vRulePRRecordId) and
              (LocationId  <> coalesce(@vLPNLocationId, '')) and
              (coalesce(LocationClass, '')  = coalesce(@vRuleLocClass, LocationClass, '')) and
              (
               (AvailableLPNCapacity    >= 1) and
               (AvailableIPCapacity     >= @vLPNIPs) and
               (AvailableUnitCapacity   >= @vLPNQty) and
               (AvailableWeightCapacity >= @vLPNWeight) and
               (AvailableVolumeCapacity >= @vLPNVolume)
              ) and
              (Warehouse  in (select TargetValue
                              from dbo.fn_GetMappedValues('CIMS', @vDestWarehouse, 'CIMS', 'Warehouse', 'Putaway', @BusinessUnit))) and
              ((@PAType <> (coalesce(@vPalletType, ''))) or (StorageType like '%'+@vPalletType+'%')) and
              (Status      = coalesce(@vRuleLocStatus,  Status)) and
              ((coalesce(AllowedOperations, '') = '') or (charindex('P', AllowedOperations) > 0)) and
              /* If picklane, then restrict to locations of the SKU only */
              ((LocationType <> 'K') or (LocationId in (select distinct LocationId from LPNs where SKUId = @vSKUId)))
        order by PutawayPath;

      /* If locations matching the rule is not found, then try the next rule */
      if (@@rowcount = 0) continue;

      if (charindex('D', @vDebug) > 0) select @vRulePRRecordId, * from @ttLocationsFiltered;

      /* Update Max Units per Location, if the Location has replenish levels set then we would not suggest
         those Locations if putaway qty is more than max units per Location, on other hand if the Location
         doesn't have replenish levels set then we would update Max Units per Lcoation to null to bypass this feature */
     /* Update @ttLocationsFiltered
      set MaxUnitsPerLocation = case when ReplenishUoM = 'EA'  then MaxReplenishLevel
                                     when ReplenishUoM = 'CS'  and (@vUnitsPerIP > 0) then (MaxReplenishLevel * @vUnitsPerIP)
                                     when ReplenishUoM = 'LPN' and (@vUnitsPerLPN > 0) then (MaxReplenishLevel * @vUnitsPerLPN)
                                     else null /* undefined */
                                end;*/

      /* Find locations from filtered locations based on SKUExists rule */
      if (@vRuleSKUExists = 'Y' /* Yes */)
        begin
          /* When there are Multiple SKUs in the LPN, then we ought to consider
             all the Locations for all SKUs, and identify the first available location
             to putaway to, along with SKU to putaway */
          With PALPNDetails(SKUId, InnerPacks, Quantity)
          as
          (
            select SKUId, InnerPacks, Quantity
            from LPNDetails
            where (LPNId = @LPNId)  and (Quantity > 0 ) and
                  (SKUId = coalesce(@vSKUId, SKUId))
          )
        select top 1 @DestLocation       = LF.Location,
                     @DestZone           = LF.PutawayZone,
                     @DestLocStorageType = LF.LocStorageType,
                     @PASKUId            = PALD.SKUId,
                     @PAInnerPacks       = PALD.InnerPacks,
                     @PAQuantity         = PALD.Quantity
        from @ttLocationsFiltered LF
               join vwLPNDetails LD   on (LD.LocationId = LF.LocationId)
               join PALPNDetails PALD on (LD.SKUId      = PALD.SKUId)
          where ((@vSKUCount = 1) or (LF.AllowMultipleSKUs = 'Y' /* Yes */)) --and
               /* HPI wants to direct LPNs to picklane always */
               -- ((LF.LocationType = 'K') and (LF.MaxUnitsPerLocation is not null) and (PALD.Quantity <= (LF.MaxUnitsPerLocation - LF.Units)))
          order by LF.PutawayPath -- LD.LastPutawayDate desc;

        /* If the destination storage type is other than Units, then the LPN has to be putaway */
          if (@DestLocStorageType not like 'U%')
            select @PASKUId      = SKUId,
                   @PAInnerPacks = InnerPacks,
                   @PAQuantity   = Quantity
             from vwLPNs
             where (LPNId = @LPNId);
        end
      else /* (@vRuleSKUExists = 'N'/null (No/null)) */
        begin
          /* We reach this else block if there are no location for the SKU.
             Here the Locations are searched without consideration of the SKU in them
             while doing so, if the Location happens to be non-empty, then it should be
             suggested only if location accepts multiple SKUs. If the location is defined
             not to accept multiple SKUs, then it should be suggested only if empty */
          select top 1 @DestLocation       = LF.Location,
                       @DestZone           = LF.PutawayZone,
                       @DestLocStorageType = LF.LocStorageType
          from @ttLocationsFiltered LF
          where ((LF.Units = 0) or (LF.AllowMultipleSKUs = 'Y' /* Yes */))
          order by LF.Units, LF.PutawayPath, LF.Location

          /* Assumption: Identify the SKU to Putaway to be the SKU with most units in the LPN */
          if (@PAType in ('LD' /* LPN Details */, 'L' /* LPN */, 'LP' /* LPNs On Pallet */))
            select top 1 @PASKUId      = SKUId,
                         @PAInnerPacks = InnerPacks,
                         @PAQuantity   = Quantity
            from LPNDetails
            where (LPNId = @LPNId) and (SKUId = coalesce(@vSKUId, SKUId)) and (Quantity > 0 )
            order by Quantity Desc;
        end

      /* found a location - exit loop */
      if (@DestLocation is not null) and (@DestZone is not null)
        break;
    end

  /* If a location or a zone are determined, then exit with success */
  if (@DestLocation is not null) or (@DestZone is not null)
    goto ExitHandler;

  /* If no location found using all applicable rules - inform the caller with a message */
  if (@vPutawayType = 'DIRECTED') /* Ignore validation if it not directed Putaway */
    select @MessageName = 'NoLocationsToPutaway';

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Putaway_FindLocationForLPN */

Go
