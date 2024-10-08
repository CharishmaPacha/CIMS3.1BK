/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  SJ      pr_Replenish_LocationsToReplenish: Added LocationStatus,LocationStatusDesc (HA-936)
  2020/06/19  NB      pr_Replenish_LocationsToReplenish: changes to Temp Table Name(CIMSV3-817)
  2020/06/18  SJ      pr_Replenish_LocationsToReplenish: Added LocationType, LocationSubType,StorageType & StatusDescription (HA-936)
  2020/06/12  NB      changed pr_Replenish_LocationsToReplenish to insert BusinessUnit into Temp Table(HA-372)
  2019/07/05  AY      pr_Replenish_LocationsToReplenish: Performance optimizations
  2019/05/30  SPP     pr_Replenish_LocationsToReplenish: Join Ownership in Location replineshment (S2GCA-98) (Ported from Prod)
  2018/12/17  TK      pr_Replenish_LocationsToReplenish: Bug fix in calculating directed quantity (HPI-Support)
  2018/08/08  VS      pr_Replenish_LocationsToReplenish: Added indexes to table variable beacause Performance issue (OB2-349)
  2018/03/27  TK      pr_Replenish_LocationsToReplenish: Changes to consider DestLocation instead of Location on OrderDetail (S2G-511)
  2016/10/21  TK      pr_Replenish_LocationsToReplenish: Disable replenish for 1D locations (HPI-GoLive)
  2016/10/19  AY      pr_Replenish_LocationsToReplenish: Handle Min/Max, Hot replenish types correctly (HPI-GoLive)
  2016/08/31  AY      pr_Replenish_LocationsToReplenish: For Hot replenishment, return locations which have less than Demand Qty (HPI-558)
  2016/02/23  TK      pr_Replenish_LocationsToReplenish: Return Ownership value
  2015/12/15  TK      pr_Replenish_LocationsToReplenish: Consider InnerPacks for case storage Locations and Units for
  2015/12/02  DK      pr_Replenish_LocationsToReplenish: Concised the message due to its large in length (FB-397).
  2015/10/01  YJ      pr_Replenish_LocationsToReplenish: Added LocationSubType, Status fields to bind data (FB-396)
  2105/03/20  TK      pr_Replenish_LocationsToReplenish: Enhanced not to show Locations whose FinalQty is equal to MaxReplenishLevelUnits.
  2015/02/25  YJ      Added LocationType for pr_Replenish_LocationsToReplenish.
  2015/02/24  TK      pr_Replenish_LocationsToReplenish: Migrated from GNC
  2014/05/27  PV      pr_Replenish_LocationsToReplenish: Corrected to identify the locations to Replenish
  2014/05/09  PK      pr_Replenish_LocationsToReplenish, pr_Replenish_GenerateOrders:
  2014/05/08  PK      pr_Replenish_LocationsToReplenish, pr_Replenish_GenerateOrders:
  2013/09/16  PK      pr_Replenish_LocationsToReplenish: Changes related to the change of Order Status Code.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_LocationsToReplenish') is not null
  drop Procedure pr_Replenish_LocationsToReplenish;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_LocationsToReplenish: The procedure returns the Locations
    that need to be replenished based upon the input criteria. Returns the
    data in #ResultSetData (TLocationsToReplenishData). This proc could be
    invoked by UI (thru pr_UI_DS_LocationsToReplenish) or by Auto Replenish.

  It only shows the locations that can be replenished i.e. there is inventory
  to be replenished.

  It also excludes locations that already have an outstanding Replenish order
  against them.

  LocationsInfo:
   <LOCATIONSTOREPLENISH>
     <SELECTIONS>
       <ReplenishType>   </ReplenishType>
       <PutawayZone>     </PutawayZone>
       <PickZone>        </PickZone>
       <SKU>             </SKU>
     </SELECTIONS>
   </LOCATIONSTOREPLENISH>

  A replenish can be both Hot replenish as well as a min-max replenish and hence
  it is not sufficient to say it is one or the other. For example, if Location min/max
  are 10/20 and there is demand for 15 and currently there are only 8 in the location,
  then whether user chooses min/max or hot replenish type the location should qualify.

------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_LocationsToReplenish
  (@LocationsInfo     TXML,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @ConfirmMessage    TMessageName output,
   @SaveToTempTable   TFlag = null)
as
  declare @ReturnCode        TInteger,
          @ErrorMessage      TMessageName,

          @vReplenishType    TTypeCode,
          @vPutawayZone      TLookUpCode,
          @vPickZone         TLookUpCode,
          @vLocationRow      TRow,   -- Future use
          @vLocationLevel    TLevel, -- Future use
          @vSKUId            TRecordId,
          @vSKU              TSKU,
          @vStorageType      TTypeCode,
          @vHotReplenish     TFlags,

          @xmlLocationsInfo  xml,

          @vDebug            TFlags = 'N';

  declare @ttLocationsToReplenish TLocationsToReplenishData; -- Table Variable for output
begin
  select @ReturnCode       = 0,
         @xmlLocationsInfo = convert(xml, @LocationsInfo);
begin try
  /* Retrieve selections from xml */
  select @vReplenishType = Record.Col.value('ReplenishType[1]', 'TStatus'),
         @vPutawayZone   = Record.Col.value('PutawayZone[1]',   'TLookUpCode'),
         @vPickZone      = Record.Col.value('PickZone[1]',      'TLookUpCode'),
         @vStorageType   = Record.Col.value('StorageType[1]',   'TTypeCode'),
         @vSKU           = Record.Col.value('SKU[1]',           'TSKU')
  from @xmlLocationsInfo.nodes('LOCATIONSTOREPLENISH/SELECTIONS') as Record(Col);

  select @vReplenishType  = nullif(@vReplenishType, ''),
         @vPutawayZone    = nullif(@vPutawayZone,   ''),
         @vPickzone       = nullif(@vPickzone,      ''),
         @vStorageType    = nullif(@vStorageType,   ''),
         @vSKU            = nullif(@vSKU,           '');

  /* Validate selected params */
  if (@vSKU is not null)
    begin
      select @vSKUId = SKUId
      from SKUs
      where (SKU    like @vSKU + '%') and
            (Status = 'A' /* Active */);

      if (@vSKUId is null)
        begin
          select @ErrorMessage = 'SKUDoesNotExist';
          goto ErrorHandler;
        end
    end

  /* Create Temp Table, if not already created by caller */
  if (object_id('tempdb..#ResultDataSet') is null)
    select * into #ResultDataSet from @ttLocationsToReplenish;

  /* Later, Have to take temp table and loop through updating the status and calculations
       on columns which are commented below */

  /* Fetch all Locations which are to be replenished depending on the i/p parameters as well */
  insert into #ResultDataSet (LocationId, Location, LocationType, LocationTypeDesc, LocationSubType, LocationSubTypeDesc, LocationRow, LocationLevel, LocationSection,
                              StorageType, StorageTypeDesc, LocationStatus, LocationStatusDesc,PutawayZone, PickZone, SKUId, SKU, SKU1, SKU2, SKU3,
                              SKU4, SKU5, ProdCategory, ProdSubCategory, LPNId, LPN, Quantity,
                              InnerPacks, UnitsPerLPN, MinReplenishLevel, MinReplenishLevelDesc, MinReplenishLevelUnits,
                              MinReplenishLevelInnerPacks, MaxReplenishLevel, MaxReplenishLevelDesc, MaxReplenishLevelUnits, MaxReplenishLevelInnerPacks,
                              ReplenishUoM, PercentFull, MinToReplenish, MinToReplenishDesc, MaxToReplenish, MaxToReplenishDesc,
                              UnitsInProcess, OrderedUnits, ResidualUnits,
                              Ownership, Warehouse, InventoryClass1, InventoryClass2, InventoryClass3, ReplenishType, BusinessUnit, UniqueId)
  select LocationId, Location, LocationType,LocationTypeDesc, LocationSubType, LocationSubTypeDesc, LocationRow, LocationLevel, LocationSection,
         StorageType, StorageTypeDesc, LocationStatus, LocationStatusDesc, PutawayZone, PickZone, SKUId, SKU, SKU1, SKU2, SKU3,
         SKU4, SKU5, ProdCategory, ProdSubCategory, LPNId, LPN, Quantity,
         coalesce(InnerPacks, 0), UnitsPerLPN, MinReplenishLevel, MinReplenishLevelDesc, MinReplenishLevelUnits,
         MinReplenishLevelInnerPacks, MaxReplenishLevel, MaxReplenishLevelDesc, MaxReplenishLevelUnits, MaxReplenishLevelInnerPacks,
         ReplenishUoM, PercentFull, MinToReplenish, MinToReplenishDesc, MaxToReplenish, MaxToReplenishDesc,
         0  /* UnitsInProcess */, 0  /* OrderedUnits   */, 0  /* ResidualUnits  */,
         Ownership, Warehouse, InventoryClass1, InventoryClass2, InventoryClass3, ReplenishType, BusinessUnit, UniqueId
  from vwLocationsToReplenish
  where (coalesce(PutawayZone, '') = coalesce(@vPutawayZone,   PutawayZone, '')) and
        (coalesce(PickZone, '')    = coalesce(@vPickZone,      PickZone, '')) and
        (LocationRow     = coalesce(@vLocationRow,   LocationRow   )) and
        (LocationLevel   = coalesce(@vLocationLevel, LocationLevel )) and
        (StorageType     = coalesce(@vStorageType,   StorageType   )) and
        (SKU             like coalesce(@vSKU,        SKU) + '%'     ) and
        (BusinessUnit    = @BusinessUnit                            ) and
        ((coalesce(AllowedOperations, '') = '') or (charindex('R', AllowedOperations) > 0));

  if (@@rowcount = 0)
    begin
      set @ConfirmMessage = 'No records found for the selected criteria';
      goto ReturnData;
    end

  /* If there is available inventory to replenish then mark those locations - if the location
     to be replenished is a Unit storage location, then check available inventory in any
     non-unit storage location. If it is a Case storage, then consider any non-picklane (basically Reserve) */
  update LR
  set InventoryAvailable = 'Y' /* Yes */
  from #ResultDataSet LR
       join vwLPNOnhandInventory LOI on (LR.SKUId =  LOI.SKUId) and
                                        (LOI.LPNType <> 'X') and
                                        (((LR.StorageType = 'U') and (LOI.StorageType <> 'U')) or
                                         ((LR.StorageType = 'P') and (LOI.LocationType <> 'K' /* Picklane */))) and
                                        (LOI.OnhandStatus = 'A' /* Available */) and
                                        (LR.Warehouse = LOI.Warehouse) and -- this is not sufficient condition now.
                                        (LR.Ownership = LOI.Ownership);

   /* Update current quantity to the temp table */
   update LR
   set CurrentQty = case when StorageType = 'U' then  Quantity
                         when StorageType = 'P' then  InnerPacks
                    end
   from #ResultDataSet LR;

  /* get the existing replenishments for the locations i.e. created orders for the
    locations but not waved  */
  with ReplenishmentsOnOrders(LocationId, SKUId, UnitsOnOrder, InnerPacks) As
  (
    select OD.LocationId, OD.SKUId, sum(OD.UnitsToAllocate), (sum(OD.UnitsToAllocate)/UnitsPerInnerPack)
    from OrderDetails OD
      join OrderHeaders OH  on (OD.OrderId    = OH.OrderId)
       join Locations   LOC on (OD.LocationId = LOC.LocationId)
    where (OH.Status in ('N')) and (OH.OrderType in ('RU', 'RP'))
    group by OD.LocationId, OD.SKUId, OD.UnitsPerInnerPack
  )
  update LR
   set UnitsOnOrder  = case when LR.StorageType = 'U'  then RP.UnitsOnOrder
                            when LR.StorageType = 'P'  then RP.InnerPacks
                       end
  from #ResultDataSet LR
        join ReplenishmentsOnOrders RP on (LR.LocationId = RP.LocationId) and
                                          (LR.SKUId      = RP.SKUId     );

  /* get the locations which are already waved, but not allocated */
  with ReplenishmentsOnWave(LocationId, SKUId, WavedQuantity, InnerPacks) As
   (
     select OD.LocationId, OD.SKUId, sum(OD.UnitsToAllocate), (sum(OD.UnitsToAllocate)/UnitsPerInnerPack)
     from OrderDetails OD
       join OrderHeaders OH on (OD.OrderId = OH.OrderId)
       join Locations   LOC on (OD.LocationId  = LOC.LocationId)
       join PickBatches PB  on (OH.PickBatchNo = PB.BatchNo)
     where (PB.Status in ('N', 'B')) and
           (PB.BatchType = 'RU') and
           (PB.IsAllocated = 'N' /* No */) and
           (OH.Status not in ('D', 'X'))        /* Wave Status may be New or Waved but some of the orders
                                                   on the Wave may be Closed or Canceled so exclude them */
     group by OD.LocationId, OD.SKUId, OD.UnitsPerInnerPack
   )
   update LR
   set ToAllocateQty = case when LR.StorageType = 'U' then RP.WavedQuantity
                            when LR.StorageType = 'P' then RP.InnerPacks
                       end
   from #ResultDataSet LR
        join ReplenishmentsOnWave RP on (LR.LocationId = RP.LocationId) and
                                        (LR.SKUId      = RP.SKUId     );

  /* Get the quantity which is already picked and need to do putaway */
  /* Joining with OrderDetails is returning incorrect quantities as there would many order details
     for single location */
  with ReplenishmentsDirectedQty(Location, SKUId, DirectedQty, InnerPacks) As
   (
    select L.DestLocation, L.SKUId, sum(L.Quantity), sum(L.InnerPacks)
    from LPNs L
      join OrderDetails OD on (L.DestLocation = OD.Location) and
                              (L.OrderId      = OD.OrderId)
    where (L.Status = 'K' /* Picked */)
    group by L.DestLocation, L.SKUId
   )
   update LR
   set DirectedQty = case when LR.StorageType = 'U' then RP.DirectedQty
                          when LR.StorageType = 'P' then RP.InnerPacks
                     end
   from #ResultDataSet LR
        join ReplenishmentsDirectedQty RP on (LR.Location = RP.Location) and
                                             (LR.SKUId    = RP.SKUId   );

   /* get all the locations which has already allocated and need to pick */
   with ReplenishmentsOnTasks(LocationId, SKUId, AllocatedQty, InnerPacks) As
   (
    select OD.LocationId, OD.SKUId, sum(TD.Quantity), sum(TD.InnerPacks)
    from OrderDetails OD
      join OrderHeaders OH on (OD.OrderId = OH.OrderId)
      join Tasks       T   on (OH.PickBatchNo = T.BatchNo)
      join TaskDetails TD  on (T.TaskId  = TD.TaskId) and
                              (OD.SKUId  = TD.SKUId)
    where (T.Archived = 'N') and
          (TD.Status not in ('X', 'C' /* cancelled, Completed */)) and
          (OH.OrderType in ('R', 'RU', 'RP' /* Replenish */))
    group by OD.LocationId, OD.SKUId
   )
   update LR
   set AllocatedQty = case when LR.StorageType = 'CS' then RP.InnerPacks
                           when LR.StorageType = 'EA' then RP.AllocatedQty
                      end
   from #ResultDataSet LR
        join ReplenishmentsOnTasks RP on (LR.LocationId = RP.LocationId) and
                                         (LR.SKUId      = RP.SKUId     );

  /* Look at all qualified orders and see how many orders that are pending need units from picklane */
  with UnreleasedOrders (SKUId, UnitsToShip, UnitsPreAllocated) as
  (
    select OD.SKUId, sum(OD.UnitsAuthorizedToShip), sum(OD.UnitsPreallocated)
    from OrderDetails OD
      join OrderHeaders OH on (OD.OrderId = OH.OrderId)
      left outer join PickBatches PB on (OH.PickBatchNo = PB.BatchNo)
    where (OH.PreprocessFlag = 'Q') and
          (OH.Status not in ('S', 'X', 'D')) and
          (OH.OrderType not in ('RU')) and
          ((PB.Status is null) or (PB.Status = 'N' /* New - Not released */))
    group by OD.SKUId
  )
  update LR
  set OrderedUnits = UO.UnitsPreallocated,
      ReplenishType = case when (charindex('H', @vReplenishType) > 0) and
                                (FinalQty < UO.UnitsPreallocated) then 'H' else ReplenishType end,
      @vHotReplenish =
      HotReplenish = case when FinalQty < UO.UnitsPreallocated then 'H' else 'N' end,
      MaxToReplenish = case when @vHotReplenish = 'H' then  dbo.fn_MaxInt(UO.UnitsPreallocated - Quantity, MaxToReplenish) else MaxToReplenish end
  from #ResultDataSet LR
    join UnreleasedOrders UO on (LR.SKUId = UO.SKUId);

  if (charindex('Y', @vDebug) > 0)
    select 'Summary' Msg, InventoryAvailable Inv, FinalQty, MinReplenishLevelUnits MinRLU, MaxReplenishLevelUnits MaxRLU,
           CurrentQty, AllocatedQty, ToAllocateQty, DirectedQty, UnitsOnOrder,
           ReplenishType Type, MinReplenishLevelInnerPacks MinRLI, MaxReplenishLevelInnerPacks MaxRLI, *
    from #ResultDataSet;

  /* Delete Rows which are not needed in the output */
  delete from #ResultDataSet
  where (RecordId not in (select RecordId from #ResultDataSet
                          where ((InventoryAvailable = 'Y' /* Yes */)
                                  and
                                  ((charindex(ReplenishType, coalesce(@vReplenishType, '')) > 0) or
                                  (charindex(HotReplenish, coalesce(@vReplenishType, '')) > 0))
                                  and
                                  ((ReplenishType = 'R' and (ReplenishUoM = 'EA')  and (coalesce(FinalQty, 0) <= MinReplenishLevelUnits)) or
                                   (ReplenishType = 'R' and (ReplenishUoM = 'CS')  and (coalesce(FinalQty, 0) <= MinReplenishLevelUnits)) or
                                   (ReplenishType = 'R' and (ReplenishUoM = 'LPN') and (StorageType = 'U'/* Units */) and (coalesce(FinalQty, 0) <= MinReplenishLevelUnits)) or
                                   (ReplenishType = 'R' and (ReplenishUoM = 'LPN') and (StorageType = 'P'/* Cases */) and (coalesce(FinalQty, 0) <= MinReplenishLevelInnerPacks)) or
                                   (ReplenishType = 'F' and (ReplenishUoM = 'EA')  and (coalesce(FinalQty, 0) < MaxReplenishLevelUnits)) or
                                   (ReplenishType = 'F' and (ReplenishUoM = 'CS')  and (coalesce(FinalQty, 0) < MaxReplenishLevelUnits)) or
                                   (ReplenishType = 'F' and (ReplenishUoM = 'LPN') and (StorageType = 'U'/* Units */) and (coalesce(FinalQty, 0) < MaxReplenishLevelUnits)) or
                                   (ReplenishType = 'F' and (ReplenishUoM = 'LPN') and (StorageType = 'P'/* Cases */) and (coalesce(FinalQty, 0) < MaxReplenishLevelInnerPacks)) or
                                   (HotReplenish  = 'H' and (ReplenishUoM = 'EA')  and (coalesce(FinalQty, 0) < OrderedUnits)) or
                                   (HotReplenish  = 'H' and (ReplenishUoM = 'CS')  and (coalesce(FinalQty, 0) < OrderedUnits)) or
                                   (HotReplenish  = 'H' and (ReplenishUoM = 'LPN') and (coalesce(FinalQty, 0) < OrderedUnits))))));

ReturnData:
  /* Verify whether the caller requested to only capture the data
      There are instance when the caller will create the # table and access the data through the # table
      in such instances, do not run this select */
  if (coalesce(@SaveToTempTable, 'N') = 'N')
    select * from #ResultDataSet;

ErrorHandler:
  if (@ErrorMessage is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @ErrorMessage;

end try
begin catch
  /* Generate error LOG here */
end catch

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Replenish_LocationsToReplenish */

Go
