/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/07/23  RV      pr_Replenish_GetReportData : Added Procedure for Locations To Replenish Report Data.
  2015/07/23  RV      pr_Replenish_GetReportData : Added Procedure for Locations To Replenish Report Data (OB-375)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_GetReportData') is not null
  drop Procedure pr_Replenish_GetReportData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_GetReportData: For the given replenishment locations, this
    procedure returns the inventory available to be replenished for each location
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_GetReportData
  (@Locations      XML,
   @FieldSortOrder TDescription,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vMessageName         TMessageName,
          @vReturnCode          TInteger,

          @LocsToReplenish      XML,
          @vLocsToReplenish     TXML,
          @vGenerateReplenishOrders
                                TXML,
          @vLocationsInfo       TXML,
          @vOptions             TXML,
          @vConfirmMessage      TDescription;

  declare @ttLocationsToReplenish Table
          (RecordId             TRecordId identity (1,1),

           LocationId           TRecordId,
           Location             TLocation,
           LocationRow          TRow,
           LocationLevel        TLevel,
           LocationSection      TSection,
           StorageType          TTypeCode,
           PutawayZone          TLookUpCode,
           PickZone             TLookUpCode,

           SKUId                TRecordId,
           SKU                  TSKU,
           SKU1                 TSKU,
           SKU2                 TSKU,
           SKU3                 TSKU,
           SKU4                 TSKU,
           SKU5                 TSKU,
           ProdCategory         TCategory,
           ProdSubCategory      TCategory,

           LPNId                TRecordId,
           LPN                  TLPN,

           Quantity             TQuantity,
           InnerPacks           TInnerPacks,
           UnitsPerLPN          TQuantity,
           MinReplenishLevel    TQuantity,
           MinReplenishLevelDesc
                                TDescription,
           MaxReplenishLevel    TQuantity,
           MaxReplenishLevelDesc
                                TDescription,
           MaxReplenishLevelUnits
                                TQuantity,

           PercentFull          TInteger,
           MinToReplenish       TQuantity,
           MinToReplenishDesc   TDescription,
           MaxToReplenish       TQuantity,
           MaxToReplenishDesc   TDescription,
           ReplenishUoM         TUoM,

           UnitsInProcess       TQuantity,
           OrderedUnits         TQuantity,
           ResidualUnits        TQuantity,
           ReplenishType        TTypeCode,
           Warehouse            TWarehouse,
           InventoryAvailable   TFlag);

  declare @InvLPNs table
          (RecordId             TRecordId identity (1,1),
           InvLPN               TLPN,
           InvLocation          TLocation,
           InvSKUId             TRecordId,
           InvSKU               TSKU,
           InvSKUDescription    TDescription,
           InvInnerPacks        TInnerPacks,
           InvQuantity          TQuantity);

  declare @ttLocationSKUs  table
          (Location             TLocation,
           SKU                  TSKU);
begin
  /* Get user selected Locations */
  insert into @ttLocationSKUs
    select distinct Record.Col.value('.',  'TLocation'), null /* SKU */
    from @Locations.nodes('/SELECTIONS/Location') as Record(Col);

  /* Insert the locations to replenish into temp table ttLocationsToReplenish along with the relevant info */
  insert into @ttLocationsToReplenish (LocationId, Location, PickZone, SKUId, SKU, Quantity, MinReplenishLevel,
                                       MaxReplenishLevel, MaxReplenishLevelUnits)
    select LTR.LocationId, LTR.Location, LTR.PickZone, LTR.SKUId, LTR.SKU, LTR.Quantity, LTR.MinReplenishLevel,
           LTR.MaxReplenishLevel, LTR.MaxUnitsToReplenish
    from @ttLocationSKUs L join vwLocationstoreplenish LTR on (L.Location = LTR.Location);

  /* Get the inventory into a temp table for each of the SKUs in LocationsToReplenish */
  insert into @InvLPNs (InvLPN, InvLocation, InvSKUId, InvSKU, InvSKUDescription, InvQuantity)
    select distinct LD.LPN, LD.Location, LD.SKUId, LD.SKU, LD.SKUDescription, LD.Quantity
    from vwLPNDetails LD
      join @ttLocationsToReplenish LTR on (LD.SKUId = LTR.SKUId)
    where (LD.Onhandstatus = 'A' /* Available */) and (LD.Quantity > 0) and
          (LD.LocationType <> 'K' /* PickLane */);

  /* Join both the temp tables ttLocationsToReplenish and InvLPNs to return the final XML */
  set @vLocsToReplenish = (select LTR.Location, LTR.SKU, LTR.Quantity, LTR.MinReplenishLevel,
                                  LTR.MaxReplenishLevel,LTR.MaxReplenishLevelUnits, IL.InvSKUDescription,
                                  IL.InvLocation, IL.InvLPN, IL.InvQuantity
                           from @InvLPNs IL
                             left join @ttLocationsToReplenish LTR on (IL.InvSKUId = LTR.SKUId)
                             order by case
                                        when (@FieldSortOrder = 'Quantity') then
                                          cast(LTR.Quantity as varchar)
                                      else
                                        LTR.Location
                                      end
                           for xml raw('LocationDetail'), elements );

  select dbo.fn_XMLNode('LocationsInformation',
         dbo.fn_XMLNode('LocationsToReplenish', @vLocsToReplenish)) as Result;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_GetReportData */

Go
