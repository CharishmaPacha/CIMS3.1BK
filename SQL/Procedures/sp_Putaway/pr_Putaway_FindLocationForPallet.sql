/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/05  RKC     pr_Putaway_FindLocationForPallet: Considering warhouse mapping for dest Warehouse (CIMSV3-623)
  2020/04/28  VS      pr_Putaway_FindLocationForLPN, pr_Putaway_FindLocationForPallet: Added Control to if no location found move to next screen (HA-288)
                      pr_Putaway_FindLocationForPallet - Changes to consider max pallets and maxLPNs while finding location for LPN/Pallet.
  2012/08/23  VM      pr_Putaway_FindLocationForPallet: Bugfix - Get distinct SKUId to get count of SKU
                      pr_Putaway_FindLocationForPallet: Find Pallet or LPN & Pallet Location for Pallets
  2012/03/16  PK      Added pr_Putaway_FindLocationForPallet, pr_Putaway_NextPAPalletResponse,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_FindLocationForPallet') is not null
  drop Procedure pr_Putaway_FindLocationForPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_FindLocationForPallet: This procedure is the core of the Directed
    putaway logic. It takes an Pallet as input and uses the info of the Pallet and
    applies the putaway rules in sequence until a valid location to putaway is
    found. When found, it returns the Zone, the Location and it's storage type.
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_FindLocationForPallet
  (@PalletId           TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId,
   ------------------------------------
   @xmlResult          xml      output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TDescription,

          @vPallet           TPallet,
          @vNumLPNs          TCount,
          @vPalletType       TTypeCode,
          @vPalletStatus     TStatus,
          @vPalletIPs        TQuantity,
          @vPalletQuantity   TQuantity,
          @vPalletWeight     TWeight,
          @vPalletVolume     TVolume,

          @vPalletLocationId TRecordId,
          @vPalletLocation   TLocation,
          @vPAPalletType     TTypeCode,
          @vPutawayType      TControlValue,

          @vDestLocation     TLocation,
          @vDestZone         TLookupCode,
          @vDestWarehouse    TWarehouse,

          @vDestLocStorageType
                             TStorageType,
          @vSKUId            TRecordId,
          @vSKUCount         TCount,
          @vLPNCount         TCount,
          @vPutawayClass     TCategory,

          @vRuleCount        TCount,
          @vRulePRRecordId   TRecordId,
          @vRecordId         TRecordId,
          @vRuleSKUExists    TFlag,
          @vRuleLocStatus    TStatus,
          @vRuleLocClass     TCategory,
          @vCurrentRule      TInteger;

  declare @ttPutawayRules Table
          (RecordId       TRecordId identity (1,1),
           PRRecordId     TRecordId,
           LocationType   TLocationType,
           StorageType    TStorageType,
           LocationStatus TStatus,
           PutawayZone    TLookupCode,
           Location       TLocation,
           SKUExists      TFlag,
           LocationClass  TCategory);

  declare @ttLocationsFiltered Table
          (LocationId     TRecordId,
           Location       TLocation,
           LocStorageType TStorageType,
           PutawayZone    TLookupCode,
           Units          TQuantity);
begin
begin try
  SET NOCOUNT ON;
  select @ReturnCode  = 0,
         @MessageName = null;

  /* Get the controls values */
  select @vPutawayType = dbo.fn_Controls_GetAsString('Putaway', 'PutawayType', 'SUGGESTED' /* Suggested Putaway */,  @BusinessUnit, @UserId);

  /* Get LPNCount, SKUCount and SKU of the pallet to fetch the PutawayClass of the SKU */
  select @vLPNCount = count(distinct LPNId),
         @vSKUCount = count(distinct SKUId),
         @vSKUId    = Min(SKUId)
  from vwLPNDetails
  where (PalletId     = @PalletId) and
        (BusinessUnit = @BusinessUnit);

  if (@vSKUCount > 1)
    set @vPutawayClass = 'MixedSKU';
  else
    select @vPutawayClass = PutawayClass
    from SKUs
    where (SKUId = @vSKUId);

  /* Get Dest Warehouse from the LPNs */
  select distinct @vDestWarehouse = DestWarehouse
  from LPNs
  where (PalletId     = @PalletId) and
        (BusinessUnit = @BusinessUnit);

  /* Get Pallet Info */
  select @vPallet           = Pallet,
         @vPAPalletType     = PalletType,
         @vNumLPNs          = NumLPNs,
         @vPalletLocationId = LocationId,
         @vPalletLocation   = Location,
         @vPalletStatus     = Status,
         @vPalletIPs        = coalesce(InnerPacks, 0),
         @vPalletQuantity   = Quantity
  from vwPallets
  where (PalletId = @PalletId);

  /* Get total volume and weight of the pallet - sun of the all lpns volume / weight
     on the pallet */
  select @vPalletWeight = sum(coalesce(ActualWeight, EstimatedWeight, 0.0)),
         @vPalletVolume = sum(coalesce(ActualVolume, EstimatedVolume, 0.0))
  from LPNs
  where (PalletId = @PalletId);

  /* Get all active putaway rules that apply to the Pallet into temp table */
  insert into @ttPutawayRules(PRRecordId, LocationType, StorageType, LocationStatus,
                              PutawayZone, Location, SKUExists, LocationClass)
    select RecordId, LocationType, StorageType, LocationStatus,
           PutawayZone, Location, SKUExists, LocationClass
    from vwPutawayRules
    where (PAType = 'A' /* Pallets */) and
          ((PalletType   is null) or (PalletType   = @vPAPalletType)) and
          ((SKUPutawayClass is null) or (SKUPutawayClass = @vPutawayClass)) and
          (BusinessUnit = @BusinessUnit) and
          (Status       = 'A' /* Active */)
    order by SequenceNo;

  select @vRuleCount = @@rowcount,
         @vRecordId  = 0;

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

      /* we need to consider PutawayClass on the location while doing putaway.
         And also make sure we need to suggest the location when there is a enough space for Pallet/LPN, units, IPs

         AvailableCapacity will be defined as MaxLimit - CurrentValue in the location */
      /* Insert all locations other than Pallets's current location (for Pallets with status 'Putaway'), which fall under the all rules except SKUExists rule */
      insert into @ttLocationsFiltered
        select LocationId, Location, StorageType, PutawayZone, Quantity
        from vwPutawayLocations
        where (PRRecordId  =  @vRulePRRecordId) and
              (LocationId  <> coalesce(@vPalletLocationId, '')) and
              (coalesce(LocationClass, '')  = coalesce(@vRuleLocClass, LocationClass, '')) and
              (AvailablePalletCapacity  >= 1) and
              (AvailableLPNCapacity    >= @vNumLPNs) and
              (AvailableIPCapacity     >= @vPalletIPs) and
              (AvailableUnitCapacity   >= @vPalletQuantity) and
              (AvailableWeightCapacity >= @vPalletWeight) and
              (AvailableVolumeCapacity >= @vPalletVolume) and
              (Warehouse  in (select TargetValue
                              from dbo.fn_GetMappedValues('CIMS', @vDestWarehouse, 'CIMS', 'Warehouse', 'Putaway', @BusinessUnit))) and
              (StorageType like '%A%' /* Pallets */) and
              (Status      = coalesce(@vRuleLocStatus,  'E' /* Empty */))
        order by PutawayPath;

      /* If locations matching the rule is  not found, then try the next rule */
      if (@@rowcount = 0) continue;

       /* Find the top 1 Location from the temp table to putaway the Pallet into it */
       select top 1 @vDestLocation       = LF.Location,
                    @vDestZone           = LF.PutawayZone,
                    @vDestLocStorageType = LF.LocStorageType
       from @ttLocationsFiltered LF;

      /* found a location - exit loop */
      if (@vDestLocation is not null) and (@vDestZone is not null)
        break;
    end

   /* Form the XML with the Putaway details and send it to the caller */
   set @xmlResult = (select @PalletId                     as PalletId,
                            @vPallet                      as Pallet,
                            @vPalletType                  as PalletType,
                            @vNumLPNs                     as NumCasesOnPallet,
                            @vPalletLocation              as PalletLocation,
                            @vPalletStatus                as PalletStatus,
                            @vPalletQuantity              as PalletQuantity,
                            @vDestZone                    as DestZone,
                            @vDestLocation                as DestLocation,
                            @vDestLocStorageType          as DestStorageType
                     FOR XML RAW('PutawayPallet'), TYPE, ELEMENTS XSINIL, ROOT('PAPalletDetails'));

  /* If a location or a zone are determined, then exit with success */
  if (@vDestLocation is not null) or (@vDestZone is not null)
    goto ExitHandler;

  /* If no location found using all applicable rules - inform the caller with a message */
  if (@vPutawayType = 'DIRECTED') /* Ignore validation if it not directed Putaway */
    select @MessageName = 'NoLocationsToPutawayPallet';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end try
begin catch
  set @xmlResult =  (select ERROR_NUMBER()    as ErrorNumber,
                            ERROR_SEVERITY()  as ErrorSeverity,
                            ERROR_STATE()     as ErrorState,
                            ERROR_PROCEDURE() as ErrorProcedure,
                            ERROR_LINE()      as ErrorLine,
                            ERROR_MESSAGE()   as ErrorMessage
                     FOR XML RAW('ERRORINFO'), TYPE, ELEMENTS XSINIL, ROOT('ERRORDETAILS'));
end catch;
end /* pr_Putaway_FindLocationForPallet */

Go
