/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/23  MS      pr_Inventory_OnhandInventory, pr_Inventory_InvSnapshot_Create: Changes to insert SourceSystem (BK-1026)
  2023/01/18  MS      pr_Inventory_OnhandInventory: Changes to insert inventorykey for SKUsToship dataset (BK-992)
  2022/05/30  VS      pr_Inventory_OnhandInventory: Added Lot in InventoryKey so fetch the Lot value and insert into #OHIResults (JLFL-98)
  2021/08/22  AY      pr_Inventory_OnhandInventory: Performance optimizations (HA-3105)
  2020/10/20  PK      pr_Inventory_OnhandInventory: Return InventoryKey as well when @ReturnResultSet is 'Y'- Port back from HA Prod/Stag by VM (HA-1483)
  2020/06/24  VS      pr_Inventory_OnhandInventory: Performance changes (S2GCA-1165)
  2019/08/20  RKC     pr_Inventory_OnhandInventory: Made changes for show the data in onhandinventory page
  2015/10/26  OK      pr_Inventory_OnhandInventory: Made the changes to get the Quantity values from vwExportsOnhandInventory (CIMS-653)
  2015/10/14  OK      pr_Inventory_OnhandInventory: Removed the Innerpack calculations from Procedure and gets from vwExportsOnhandInventory(CIMS-653)
  2015/07/20  NY      pr_Inventory_OnhandInventory: Enhanced to allow Mode to be configured by control var (FB-217)
  2014/12/22  SK      pr_Inventory_OnhandInventory: Added an additional MODE operation to expand SKUPrePacks details
  2014/09/11  AK      pr_Inventory_OnhandInventory: Added vwEOHINV_UDF1 to vwEOHINV_UDF10
  2014/09/10  AY      pr_Inventory_OnhandInventory: Correct Onhand value
  2014/09/03  TD      pr_Inventory_OnhandInventory: Added putaway class, UDFs.
  2014/07/01  AY      pr_Inventory_OnhandInventory: Changes for performance gain
              AY      pr_Inventory_OnhandInventory: Fixed issue of showing duplicate entries
  2014/02/03  NY      pr_Inventory_OnhandInventory: Added InnerPacks.
  2014/01/30  NY      pr_Inventory_OnhandInventory: Added coalesce function.
  2013/01/20  NY      pr_Inventory_OnhandInventory: Added Available, Reserved and Onhand InnerPacks.
  2014/01/08  AY      pr_Inventory_OnhandInventory: Changes to fix where in we do not show ToShipQty
  2013/12/11  NY      pr_Inventory_OnhandInventory: Added UnitsPerInnerPack to show in Onhand Inventory.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_OnhandInventory') is not null
  drop Procedure pr_Inventory_OnhandInventory;
Go
/*------------------------------------------------------------------------------
  pr_Inventory_OnhandInventory: Procedure returns the Onhand Qty for the given
    params summarizing by the given mode.

  Mode: 'LPN'    - gives details by SKU, LPN
        'WH'     - gives details by SKU, WH
        'SPPEXP' - expansion of SKUPrePacks
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_OnhandInventory
  (@SKUId            TRecordId     = null,
   @SKU              TSKU          = null,
   @SKU1             TSKU          = null,
   @SKU2             TSKU          = null,
   @SKU3             TSKU          = null,
   @SKU4             TSKU          = null,
   @SKU5             TSKU          = null,
   @Warehouse        TWarehouse    = null,
   @Ownership        TOwnership    = null,
   @LPN              TLPN          = null,
   @Location         TLocation     = null,
   @Brand            TBrand        = null,
   @ProdCategory     TCategory     = null,
   @ProdSubCategory  TCategory     = null,
   @Mode             TName         = null,
   @BusinessUnit     TBusinessUnit = null,
   @ReturnResultSet  TFlags        = 'Y')
as
  declare @vReturnCode  TInteger,
          @vMessageName TMessageName,
          @vMessage     TDescription;

  declare @ttOnhandInventory TOnhandInventory,
          @ttSKUsToShip      TOnhandInventorySKUsToShip;

begin
  if (coalesce(@Mode, '') = '')
    select @Mode = dbo.fn_Controls_GetAsString('OnhandInventory', 'Mode', 'WH', @BusinessUnit, null /* UserId */);

  /* Make null if empty strings are passed */
  select @Warehouse        = nullif(@Warehouse,        ''),
         @SKUId            = nullif(@SKUId,            ''),
         @SKU              = nullif(@SKU,              ''),
         @SKU1             = nullif(@SKU1,             ''),
         @SKU2             = nullif(@SKU2,             ''),
         @SKU3             = nullif(@SKU3,             ''),
         @SKU4             = nullif(@SKU4,             ''),
         @SKU5             = nullif(@SKU5,             ''),
         @Warehouse        = nullif(@Warehouse,        ''),
         @Ownership        = nullif(@Ownership,        ''),
         @LPN              = nullif(@LPN,              ''),
         @Location         = nullif(@Location,         ''),
         @Brand            = nullif(@Brand,            ''),
         @ProdCategory     = nullif(@ProdCategory,     ''),
         @ProdSubCategory  = nullif(@ProdSubCategory,  '');

  /* create tables here if they were not already created */
  select * into #ttOnhandInventory from @ttOnhandInventory
  if object_id('tempdb..#OHIResults') is null select * into #OHIResults from @ttOnhandInventory
  --select * into #ttSKUsToShip from @ttSKUsToShip

  /* alter table fields here */
  -- alter table #OHIResults drop column UnitPrice, UnitsPerInnerPack, Quantity, AvailableQty, ReservedQty, ReceivedQty, OnhandQty, OnhandValue, ToShipQty, ShortQty,
  --                                     InnerPacks, AvailableIPs, ReservedIPs, ReceivedIPs, ToShipIPs, OnhandIPs;

  alter table #OHIResults add AvailableToSellQty as (coalesce(AvailableQty, 0) - coalesce(ToShipQty, 0));
                              --KeyColumn          as SKUId + SKU + UPC + UoM + Location + Warehouse + LPN + Ownership + Lot + ExpiryDate + BusinessUnit;

  /* create index on temp table */
  if not exists (select name from sys.indexes where name = N'ix_OHResults_SKUId')
    create index ix_OHResults_SKUId on #OHIResults (SKUId) include (Ownership, Warehouse, BusinessUnit);

  /* create index on temp table */
  if not exists (select name from sys.indexes where name = N'ix_OnhandInventory_SKUId')
    create index ix_OnhandInventory_SKUId  on #ttOnhandInventory (SKUId) include (Ownership, Warehouse, BusinessUnit);

  /* Inserting data into temp table from vwExportOnhandInventory based on Inputparamters */
  if (@Mode = 'WH' /* Warehouse */)
    begin
      insert into #ttOnhandInventory  (SKUId, SKU, UnitsPerInnerPack, Warehouse, Ownership, Lot,
                                       InventoryClass1, InventoryClass2, InventoryClass3,
                                       AvailableQty, ReservedQty, ReceivedQty,
                                       InnerPacks, ReceivedIPs,
                                       BusinessUnit, InventoryKey, SourceSystem)
        select SKUId, SKU, min(UnitsPerInnerPack), DestWarehouse, Ownership, min(Lot),
               InventoryClass1, InventoryClass2, InventoryClass3,
               sum(AvailableQty), sum(ReservedQty), sum(ReceivedQty),
               sum(InnerPacks), sum(ReceivedIPs),
               BusinessUnit, min(InventoryKey), min(SourceSystem)
        from vwExportsOnhandInventory with (nolock)
        where (coalesce(SKUId, '')           = coalesce(@SKUId, SKUId, '')) and
              (coalesce(SKU, '')             = coalesce(@SKU,  SKU, '')) and
              (coalesce(SKU1, '')            = coalesce(@SKU1, SKU1, '')) and
              (coalesce(SKU2, '')            = coalesce(@SKU2, SKU2, '')) and
              (coalesce(SKU3, '')            = coalesce(@SKU3, SKU3, '')) and
              (coalesce(SKU4, '')            = coalesce(@SKU4, SKU4, '')) and
              (coalesce(SKU5, '')            = coalesce(@SKU5, SKU5, '')) and
              (coalesce(Ownership, '')       = coalesce(@Ownership, Ownership, '')) and
              (coalesce(LPN, '')             = coalesce(@LPN, LPN, '')) and
              (coalesce(Location, '')        = coalesce(@Location, Location, '')) and
              (coalesce(Brand, '')           = coalesce(@Brand, Brand, '')) and
              (coalesce(ProdCategory, '')    = coalesce(@ProdCategory, ProdCategory, '')) and
              (coalesce(ProdSubCategory, '') = coalesce(@ProdSubCategory, ProdSubCategory, '')) and
              (coalesce(BusinessUnit, '')    = coalesce(@BusinessUnit, BusinessUnit, ''))
        group by SKUId, SKU, DestWarehouse, Ownership, Lot,
                 InventoryClass1, InventoryClass2, InventoryClass3, BusinessUnit;
    end /* Mode WH */
  else
  if (@Mode = 'SPPEXP' /* SKUPrePack Expanded */)
    begin
      insert into #ttOnhandInventory(SKUId, SKU, UnitsPerInnerPack, Warehouse, Lot,
                                     AvailableQty, ReservedQty, ReceivedQty, InnerPacks, ReceivedIPs,
                                     InventoryClass1, InventoryClass2, InventoryClass3,
                                     Ownership, BusinessUnit, InventoryKey, SourceSystem)
        select coalesce(SPP.ComponentSKUId, VOH.SKUId), coalesce(S.SKU, VOH.SKU), min(VOH.UnitsPerInnerPack), VOH.DestWarehouse, min(Lot),
               coalesce(sum(coalesce(SPP.ComponentQty, 1) * VOH.AvailableQty), sum(VOH.AvailableQty)),
               coalesce(sum(coalesce(SPP.ComponentQty, 1) * VOH.ReservedQty), sum(VOH.ReservedQty)),
               coalesce(sum(coalesce(SPP.ComponentQty, 1) * VOH.ReceivedQty), sum(VOH.ReceivedQty)),
               sum(VOH.InnerPacks), sum(VOH.ReceivedIPs),
               VOH.InventoryClass1, VOH.InventoryClass2, VOH.InventoryClass3,
               VOH.Ownership, VOH.BusinessUnit, min(InventoryKey), min(VOH.SourceSystem)
        from vwExportsOnhandInventory VOH with (nolock)
          left join SKUPrePacks SPP with (nolock) on (VOH.SKUId          = SPP.MasterSKUId)
          left join SKUs        S  with (nolock)  on (SPP.ComponentSKUId = S.SKUId)
        where (coalesce(VOH.SKUId, '')            = coalesce(@SKUId, VOH.SKUId, '')) and
              (coalesce(VOH.SKU, '')              = coalesce(@SKU, VOH.SKU, '')) and
              (coalesce(VOH.SKU1, '')             = coalesce(@SKU1, VOH.SKU1, '')) and
              (coalesce(VOH.SKU2, '')             = coalesce(@SKU2, VOH.SKU2, '')) and
              (coalesce(VOH.SKU3, '')             = coalesce(@SKU3, VOH.SKU3, '')) and
              (coalesce(VOH.SKU4, '')             = coalesce(@SKU4, VOH.SKU4, '')) and
              (coalesce(VOH.SKU5, '')             = coalesce(@SKU5, VOH.SKU5, '')) and
              (coalesce(VOH.Ownership, '')        = coalesce(@Ownership, VOH.Ownership, '')) and
              (coalesce(VOH.LPN, '')              = coalesce(@LPN, VOH.LPN, '')) and
              (coalesce(VOH.Location, '')         = coalesce(@Location, VOH.Location, '')) and
              (coalesce(VOH.Brand, '')            = coalesce(@Brand, VOH.Brand, '')) and
              (coalesce(VOH.ProdCategory, '')     = coalesce(@ProdCategory, VOH.ProdCategory, '')) and
              (coalesce(VOH.ProdSubCategory, '')  = coalesce(@ProdSubCategory, VOH.ProdSubCategory, '')) and
              (coalesce(VOH.BusinessUnit, '')     = coalesce(@BusinessUnit, VOH.BusinessUnit, ''))
        group by coalesce(SPP.ComponentSKUId, VOH.SKUId), coalesce(S.SKU, VOH.SKU), VOH.DestWarehouse, VOH.Lot,
                 VOH.InventoryClass1, VOH.InventoryClass2, VOH.InventoryClass3, VOH.Ownership, VOH.BusinessUnit;
    end /* Mode SPPEXP */
  else
    begin /* Mode not WH or SPPEXP */
      insert into #ttOnhandInventory (SKUId, SKU, UnitsPerInnerPack, Warehouse, Location, LPN,
                                      Ownership, Lot, ExpiryDate, AvailableQty, ReservedQty, ReceivedQty,
                                      InnerPacks, ReceivedIPs,
                                      InventoryClass1, InventoryClass2, InventoryClass3,
                                      BusinessUnit, InventoryKey, SourceSystem)
        select SKUId, SKU, min(UnitsPerInnerPack), DestWarehouse,
               min(Location), LPN, min(Ownership), min(Lot), min(ExpiryDate),
               sum(AvailableQty), sum(ReservedQty), sum(ReceivedQty),
               sum(InnerPacks), sum(ReceivedIPs),
               InventoryClass1, InventoryClass2, InventoryClass3,
               BusinessUnit, min(InventoryKey), min(SourceSystem)
        from vwExportsOnhandInventory with (nolock)
        where (coalesce(SKUId, '')            = coalesce(@SKUId, SKUId, '')) and
              (coalesce(SKU, '')              = coalesce(@SKU,  SKU, '')) and
              (coalesce(SKU1, '')             = coalesce(@SKU1, SKU1, '')) and
              (coalesce(SKU2, '')             = coalesce(@SKU2, SKU2, '')) and
              (coalesce(SKU3, '')             = coalesce(@SKU3, SKU3, '')) and
              (coalesce(SKU4, '')             = coalesce(@SKU4, SKU4, '')) and
              (coalesce(SKU5, '')             = coalesce(@SKU5, SKU5, '')) and
              (coalesce(Ownership, '')        = coalesce(@Ownership, Ownership, '')) and
              (coalesce(LPN, '')              = coalesce(@LPN, LPN, '')) and
              (coalesce(Location, '')         = coalesce(@Location, Location, '')) and
              (coalesce(Brand, '')            = coalesce(@Brand, Brand, '')) and
              (coalesce(ProdCategory, '')     = coalesce(@ProdCategory, ProdCategory, '')) and
              (coalesce(ProdSubCategory, '')  = coalesce(@ProdSubCategory, ProdSubCategory, '')) and
              BusinessUnit                    = coalesce(@BusinessUnit, BusinessUnit, '')
        group by SKUId, SKU, LPN, Location, Ownership, Lot, ExpiryDate, DestWarehouse,
                 InventoryClass1, InventoryClass2, InventoryClass3, BusinessUnit;
    end

  /* Retrieve data from temp table into Results. We group by all fields here but that is fine because
     the fields that are not applicable to a mode would have nulls anyway */
  insert into #OHIResults (SKUId, SKU, UnitsPerInnerPack, Location, Warehouse,
                          LPN, Ownership, Lot, ExpiryDate, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3,
                          InnerPacks, AvailableIPs, ReservedIPs, ReceivedIPs,
                          Quantity, AvailableQty, ReservedQty, ReceivedQty,
                          InventoryKey, SourceSystem)
    select SKUId, SKU, coalesce(min(UnitsPerInnerPack), 0), Location, Warehouse,
           LPN, Ownership, Lot, ExpiryDate, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3,
           sum(InnerPacks), sum(coalesce(AvailableIPs, 0)), sum(coalesce(ReservedIPs, 0)), sum(coalesce(ReceivedIPs, 0)),
           sum(Quantity), sum(AvailableQty), sum(ReservedQty), sum(ReceivedQty),
           min(InventoryKey), min(SourceSystem)
    from #ttOnhandInventory
    group by SKUId, SKU, Location, Warehouse, LPN, Ownership, Lot, ExpiryDate, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3;

  /* Compute the ToShip Qty and ShortQty and insert into the temp table */
  if (@Mode in ('WH' /* Warehouse */, 'SPPEXP' /* SKUPrePack Expanded */))
    begin
      with SKUsToShip(BusinessUnit, Warehouse, Ownership, SKUId, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                      UnitsToAllocate)
      as
      (
        select OH.BusinessUnit, OH.Warehouse, OH.Ownership, OD.SKUId, OD.Lot, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3,
               sum(OD.UnitsToAllocate)
        from OrderHeaders OH with (nolock)
          join OrderDetails OD with (nolock) on (OD.OrderId = OH.OrderId)
        where (OH.Archived = 'N') and
              (OH.Status not in ('S' /* Shipped */, 'X' /* Cancelled */)) and
              (OH.OrderType not in ('A', 'B', 'R' /* Bulk, Replenish, AutoFulfill */))
        group by OH.BusinessUnit, OH.Warehouse, OH.Ownership, OD.SKUId, OD.Lot, OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3
        having sum(UnitsToAllocate) > 0
      )
      insert into @ttSKUsToShip (BusinessUnit, Warehouse, Ownership, SKUId, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                                 UnitsToShip)
        select BusinessUnit, Warehouse, Ownership, SKUId, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
               UnitsToAllocate
        from SKUsToShip;

      /* Some of the SKUs to be shipped may not be in the Results table as there is no inventory
         for them, so insert those */
      insert into #OHIResults(Warehouse, Ownership, BusinessUnit, SKUId, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                              ToShipQty, InventoryKey)
        select STS.Warehouse, STS.Ownership, STS.BusinessUnit, coalesce(STS.SKUId, 0), STS.Lot, STS.InventoryClass1, STS.InventoryClass2, STS.InventoryClass3,
               STS.UnitsToShip, STS.InventoryKey
        from @ttSKUsToShip STS
          left outer join #OHIResults R on (STS.InventoryKey = R.InventoryKey)
        where (R.SKUId is null);

      /* Update the ToShipQty on the SKUs we have inventory for */
      update TR
      set ToShipQty = STS.UnitsToShip,
          ToShipIps = case when TR.UnitsPerInnerPack > 0 then (STS.UnitsToShip/TR.UnitsPerInnerPack) else 0 end
      from #OHIResults TR
        join @ttSKUsToShip STS on (TR.InventoryKey = STS.InventoryKey);

      /* Compute the Short Qty */
      update TR
      set ShortQty  = Case
                        when (coalesce(ToShipQty,0) - coalesce(AvailableQty,0)) > 0 then
                             (coalesce(ToShipQty,0) - coalesce(AvailableQty,0))
                        else 0
                      end
      from #OHIResults TR
    end;

  /* Add the SKU details */
  update OHIR
  set OHIR.UPC             = S.SKU,
      OHIR.SKU             = coalesce(OHIR.SKU, S.SKU),
      OHIR.SKU1            = S.SKU1,
      OHIR.SKU2            = S.SKU2,
      OHIR.SKU3            = S.SKU3,
      OHIR.SKU4            = S.SKU4,
      OHIR.SKU5            = S.SKU5,
      OHIR.Description     = S.Description,
      OHIR.SKU1Description = S.SKU1Description,
      OHIR.SKU2Description = S.SKU2Description,
      OHIR.SKU3Description = S.SKU3Description,
      OHIR.SKU4Description = S.SKU4Description,
      OHIR.SKU5Description = S.SKU5Description,
      OHIR.Brand           = S.Brand,
      OHIR.ProdCategory    = S.ProdCategory,
      OHIR.ProdSubCategory = S.ProdSubCategory,
      OHIR.ABCClass        = S.ABCClass,
      OHIR.SKUSortOrder    = S.SKUSortOrder,
      OHIR.OnhandValue     = cast (OHIR.OnhandQty * S.UnitCost as money),
      OHIR.UnitPrice       = S.UnitPrice,
      OHIR.UoM             = S.UoM,
      OHIR.SourceSystem    = coalesce(OHIR.SourceSystem, S.SourceSystem)
  from #OHIResults OHIR join SKUs S on (OHIR.SKUId = S.SKUId);

  /* Return results if requested, else caller can access # table */
  if (@ReturnResultSet = 'Y')
    select R.SKUId, R.SKU, R.UPC, R.UnitPrice, R.UoM, R.UnitsPerInnerPack, R.Warehouse, R.Location,
           R.LPN, R.Ownership, R.Quantity, R.OnhandStatus, R.ExpiryDate, R.Lot,
           R.InventoryClass1, R.InventoryClass2, R.InventoryClass3,
           R.AvailableQty, R.ReservedQty, R.ReceivedQty, R.OnhandValue, R.ShortQty,
           R.InnerPacks, R.AvailableIPs, R.ReservedIPs, R.ReceivedIPs, R.BusinessUnit,
           R.vwEOHINV_UDF1, R.vwEOHINV_UDF2, R.vwEOHINV_UDF3, R.vwEOHINV_UDF4, R.vwEOHINV_UDF5,
           R.vwEOHINV_UDF6, R.vwEOHINV_UDF7, R.vwEOHINV_UDF8, R.vwEOHINV_UDF9, R.vwEOHINV_UDF10,
           R.SKU1, R.SKU2, R.SKU3, R.SKU4, R.SKU5, R.Description, R.SKU1Description,
           R.SKU2Description, R.SKU3Description, R.SKU4Description, R.SKU5Description,
           R.Brand, R.ProdCategory, R.ProdSubCategory, R.ABCClass, R.SKUSortOrder,
           R.OnhandValue, R.PutawayClass, R.InventoryKey, R.SourceSystem
    from #OHIResults R;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_OnhandInventory */

Go
