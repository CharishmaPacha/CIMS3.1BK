/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/06  RT      pr_Cubing_Execute: Removed the fields as they are exists in the table type (BK-306)
  2021/03/28  TK      pr_Cubing_AddCartons, pr_Cubing_AddCartonDetails & pr_Cubing_Execute:
                        Code optimization for UCC barcode generation (HA-2471)
  2021/03/17  TK      pr_Cubing_Execute: Bug Fix in evaluating carton & SKU dimensions
                      pr_Cubing_GetDetailsToCube: Populate ShipPack (HA-GoLive)
  2021/03/05  TK      pr_Cubing_Execute: Changes to update SortIndex on CartonHeaders table (HA-2127)
  2021/02/16  TK      pr_Cubing_Execute & pr_Cubing_GetDetailsToCube:
                        Changes to use SKU dimensions based upon control variable (HA-1964)
  2020/10/11  TK      pr_Cubing_Execute & pr_Cubing_FindOptimalCarton:
                        Changes to cube standard units separately (HA-1568)
  2020/10/06  TK      pr_Cubing_Execute & pr_Cubing_GetCartonTypes:
                        Changes to cube single carton carton orders to improve performance
                      pr_Cubing_CubeSingleCartonOrders: Initial Revision (HA-1487)
  2020/09/16  TK      pr_Cubing_Execute: Changes to  mark Task Details temp table as cubed & code refractoring
                      pr_Cubing_FindAvailableCarton: Code refractoring
                      pr_Cubing_FindOptimalCarton: Changes to consider max of SKU dimensions while findng optimal carton
                      pr_Cubing_GetDetailsToCube: Changes to load SKUs dimensions into temp table (HA-1446)
  2020/08/26  TK      pr_Cubing_Execute: Changes to cube each unit to a carton when SKU carton group is 'STD_UNIT' (S2GCA-1252)
  2020/06/05  TK      pr_Cubing_Execute & pr_Cubing_GetDetailsToCube:
                        Changes to update inventory class on Ship Cartons (HA-829)
  2020/04/25  TK      pr_Cubing_AddCartonDetails, pr_Cubing_Execute, pr_Cubing_FindOptimalCarton:
                        Changes to cube either order details or task details & performance improvements
                      pr_Cubing_GetDetailsToCube: Initial Revision (HA-171)
  2019/10/07  TK      pr_Cubing_Execute, pr_Cubing_AddCartonDetails & pr_Cubing_FindAvailableCarton:
                        Performance improvements
                      pr_Cubing_PrepareToCubePicks & pr_Cubing_AddCartons: Initial Revision (CID-883)
  2019/09/07  SK      pr_Cubing_Execute: Introduce transaction for every task detail (CID-833)
  2019/08/29  TD      pr_Cubing_Execute:Cube the details based on the pickpath (CID-953)
  2019/05/04  TK      pr_Cubing_Execute, pr_Cubing_FindAvailableCarton & pr_Cubing_FindOptimalCarton:
                        Changes to consider packing group while cubing (S2GCA-677)
  2019/04/20  TK      pr_Cubing_Execute: Cube picks in the order of pick zone (S2GCA-265)
  2018/10/05  VM      pr_Cubing_Execute: Include markers (S2G-353)
              AY      pr_Cubing_Execute: Fix issue with IPVolume being zero (S2GCA-356)
  2018/10/01  TK/RT   pr_Cubing_Execute: Recalculate the Orders once after adding the Carton Details (S2GCA-306)
  2018/06/12  TK      pr_Cubing_Execute: Don't default UnitsPerInnerpack value (S2G-925)
  2018/04/09  TK      pr_Cubing_AddCartonDetails & pr_Cubing_Execute: Changes to ignore canceled task details (S2G-568)
  2018/03/15  TK      pr_Cubing_Execute: Enhanced to split task details if a task detail is cubed into multiple cartons (S2G-423)
                      pr_Cubing_AddCartonDetails: Initial Revision (S2G-423)
  2018/02/08  TD      pr_Cubing_Execute,pr_Cubing_GetCartonTypes,pr_Cubing_FindAvailableCarton:Changes to cube based on
                        cases and unit picks (S2G-107)
  2017/08/28  TK      pr_Cubing_Execute: Changes to consider only Task Details which are not cubed (HPI-1648)
  2017/01/23  TK      pr_Cubing_Execute: Changes to update TempLabelDetailId on Task Details (HPI-1274)
  2016/10/08  AY/TK   pr_Cubing_Execute & pr_Cubing_FindAvailableCarton: Enhanced to consider nesting factor on SKUs (HPI-705)
  2016/08/02  TK      pr_Cubing_Execute: Fixed issue with updating newly created temp label on Older task details (HPI-291)
  2016/06/28  AY/TK   pr_Cubing_Execute: Cube tasks already in TaskDetails table when none passed in HPI-162
  2015/12/03  TK      pr_Cubing_Execute: Skip cubing if no CartonTypes for an Order(ACME-422)
  2015/05/06  TK      pr_Cubing_Execute & pr_Cubing_FindAvailableCarton:
                        Consider Order types while cubing certin order types have
                          some constriants for example same SKU/Case or same Style/Case.
  2015/05/05  TK      pr_Cubing_Execute: Enhanced to created LPNDetails.
  2015/05/02  TK      pr_Cubing_Execute: Enhanced to generate temp labels for cubed cartons.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_Execute') is not null
  drop Procedure pr_Cubing_Execute;
Go
/*------------------------------------------------------------------------------
  Proc pr_Cubing_Execute: The highest level of cubing procedure which will cube
    and cartonize for the give Wave. Based upon the operation, it would either
    cube A. The pick task details created for the wave or B. Cube the order details
    for orders on thee wave
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_Execute
  (@WaveId                TRecordId,
   @TransactionScope      TTransactionScope,
   @Operation             TOperation,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @Warehouse             TWarehouse    = null,
   @Debug                 TFlag         = null)
as
  /* Declare local variables */
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vRecordId               TRecordId,
          @vDebug                  TFlags,

          @vSKUId                  TRecordId,
          @vSKU                    TSKU,
          @vSKUStyle               TSKU,
          @vSpacePerIP             TFloat,
          @vSpacePerUnit           TFloat,
          @vWeightPerIP            TWeight,
          @vWeightPerUnit          TWeight,
          @vNestingFactor          TFloat,

          @TempLPNId               TRecordId,
          @vLPNId                  TRecordId,
          @vLPNDetailId            TRecordId,
          @TempLPN                 TLPN,
          @vUCCBarcode             TBarcode,

          @vOrderId                TRecordId,
          @vOrderDetailId          TRecordId,
          @vPrevOrderId            TRecordId,
          @vOrderType              TTypecode,
          @vPickTicket             TPickTicket,
          @vSalesOrder             TSalesOrder,
          @vOwnership              TOwnership,
          @vWarehouse              TWarehouse,
          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vWaveType               TTypeCode,

          @vCubeCartonId           TRecordId,
          @vCartonType             TCartonType,

          @vUniqueId               TRecordId,
          @vPackingGroup           TCategory,
          @vPrevPackingGroup       TCategory,
          @vInventoryClass1        TInventoryClass,
          @vInventoryClass2        TInventoryClass,
          @vInventoryClass3        TInventoryClass,

          @vQtyToCube              TQuantity,
          @vUnitsToCube            TQuantity,
          @vNumLPNsAssigned        TInteger,
          @vNumUnits               TQuantity,
          @vNumSKUs                TCount,
          @Quantity                TQuantity,
          @vUnitsPerIP             TInteger,

          @vSpaceUsed              TFloat,
          @vWeightUsed             TWeight,
          @vEmptyCartonSpace       TFloat,
          @vMaxUnitsPerCarton      TCount,
          @vMaxUnitsToCubeToCarton TCount,
          @vMaxWeightPerCarton     TWeight,
          @vMaxCartonDimension     TFloat,
          @vFirstDimension         TFloat,
          @vSecondDimension        TFloat,
          @vThirdDimension         TFloat,

          @vUseSKUDimensions       TControlValue;

  declare @ttDetailsToCube         TDetailsToCube,
          @ttCubedTaskDetails      TTaskInfoTable,
          @ttCubeCartonHdrs        TCubeCartonHdr,  -- Holds the list of cartons that are being used for cubing
          @ttCubeCartonDtls        TCubeCartonDtls, -- Holds details of each carton that is being cubed
          @ttOrdersToCube          TOrdersToCube,
          @ttCartonTypes           TCartonTypes,
          @ttOrders                TEntityKeysTable,
          @ttSKUs                  TEntityKeysTable,
          @ttMarkers               TMarkers,
          @ttLPNsToRecount         TRecountKeysTable,
          @ttLPNShipLabelData      TLPNShipLabelData;
begin
SET NOCOUNT ON;

begin try
  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @vPrevOrderId      = 0,
         @vPrevPackingGroup = '';

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;
  select @vDebug = coalesce(nullif(@Debug, ''), @vDebug);

  /* Get controls */
  select @vUseSKUDimensions = dbo.fn_Controls_GetAsString('Cubing', 'UseSKUDimensions', 'Y' /* Yes */, @BusinessUnit, system_user);

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_Cubing_Wave';

  /* Get PickBatchNo */
  select @vWaveId   = RecordId,
         @vWaveNo   = BatchNo,
         @vWaveType = WaveType
  from Waves
  where (RecordId = @WaveId);

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_CreateCartonTypes#Table';

  /* Create temp table for pr_Cubing_GetCartonTypes as we cannot do a nested insert into exec */
  select * into #CartonTypes from @ttCartonTypes;
  select * into #DetailsToCube from @ttDetailsToCube;
  select * into #CubeCartonHdrs from @ttCubeCartonHdrs;
  select * into #CubeCartonDtls from @ttCubeCartonDtls;
  select * into #OrdersToCube from @ttOrdersToCube;

  select * into #LPNShipLabels from @ttLPNShipLabelData;
  alter table #LPNShipLabels add ShipFrom           varchar(50),
                                 LabelFormatName    varchar(128),
                                 RecordId           integer;

  /* Invoke proc to prepare hash tables with required computed columns and indices */
  exec pr_Cubing_PrepareToCubePicks @vWaveId, null /* Operation */, @BusinessUnit, @UserId;

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_InsertTaskDetailsToCube';

  /* Get all the order details or task details to be cubed for the given wave
     executing following procedure will insert order details or task details to be cubed into #DetailsToCube table */
  exec pr_Cubing_GetDetailsToCube @vWaveId, @Operation, @BusinessUnit;

  /* If tasks need to be processed in a certain sequence, then sort them here by updating
     SortSeq of the tasks, if not they would be processed in the order inserted above */

  if (charindex('D', @vDebug) > 0) select 'DetailsToCube', OrderId, AllocatedQty, PackingGroup, * from #DetailsToCube;

  /* To avoid hitting SKUs table again and again, let us use a # table for all SKUs */
  insert into @ttSKUs(EntityId) select distinct SKUId from #DetailsToCube;

  select SKUId, SKU, SKU1, SKU2, UnitVolume as SpacePerUnit,
         coalesce(nullif(InnerPackVolume, '0'), UnitVolume * UnitsPerInnerPack, UnitVolume) as SpacePerIP,
         UnitWeight, InnerPackWeight, coalesce(UnitsPerInnerPack, 0) as UnitsPerIP, NestingFactor, ShipPack,
         UnitLength, UnitWidth, UnitHeight,
         dbo.fn_MaxOfThree(UnitLength, UnitWidth, UnitHeight) as MaxUnitDimension,
         dbo.fn_MaxOfThree(InnerPackLength, InnerPackWidth, InnerPackHeight) as MaxIPDimension,
         case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.FirstNumber  else 0.1 end as FirstDimension, /* If SKU dims cannot be used then insert with least value */
         case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.SecondNumber else 0.1 end as SecondDimension,
         case when @vUseSKUDimensions = 'Y' /* Yes */ then FN.ThirdNumber  else 0.1 end as ThirdDimension
  into #SKUs
  from SKUs S
    join @ttSKUs TS on S.SKUId = TS.EntityId
    cross apply dbo.fn_SortValuesAscending(S.UnitLength, S.UnitWidth, S.UnitHeight) FN;

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_CubeSingleCartonOrders';

  /* Get the Orders/PackingGroups that needs to be cubed */
  insert into #OrdersToCube (OrderId, PickTicket, OrderCartonGroup, PackingGroup, TotalQtyToCube, TotalSpaceRequired, TotalWeight,
                             MaxFirstDimension, MaxSecondDimension, MaxThirdDimension)
    select OrderId, PickTicket, OrderCartonGroup, PackingGroup, sum(QtyToCube), sum(SpaceRequired), sum(TotalWeight),
           max(FirstDimension), max(SecondDimension), max(ThirdDimension)
    from #DetailsToCube
    where (Status = 'A'/* Active */)
    group by OrderId, PickTicket, OrderCartonGroup, PackingGroup;

  /* Get the types of cartons that are applicable for this order */
  exec pr_Cubing_GetCartonTypes null, @vWaveId, @BusinessUnit;

  /* Ignore the orders that don't have any carton types */
  update DTC
  set Status = 'I' /* Ignore */
  from #DetailsToCube DTC
    left outer join #OrdersToCube OTC on (DTC.OrderId = OTC.OrderId)
  where (OTC.OrderCartonGroup is null);

  /* Invoke proc to cube single carton orders */
  exec pr_Cubing_CubeSingleCartonOrders @vWaveId, @Operation, @BusinessUnit;

  /* There are chances that some SKUs may not fit in any of the allowed cartons of the Order,
     system will cube each unit of that SKU into a STD_UNIT carton so identify such SKUs ahead */
  update DTC
  set SKUCartonGroup = 'STD_UNIT',
      PackingGroup   = 'STD_UNIT'
  from #DetailsToCube DTC
    join #OrdersToCube OTC on (DTC.OrderId = OTC.OrderId)
    left outer join #CartonTypes  CT  on (OTC.OrderCartonGroup = CT.CartonGroup) and
                                         ((SpacePerUnit * ShipPack < CT.EmptyCartonSpace) and
                                          (DTC.FirstDimension      < CT.FirstDimension ) and
                                          (DTC.SecondDimension     < CT.SecondDimension) and
                                          (DTC.ThirdDimension      < CT.ThirdDimension ))
  where CT.RecordId is null;

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_ProcessEachTaskDetailToCube';

  /* Loop thru the task details and process each task detail id */
  while (exists (select * from #DetailsToCube
                 where (QtyToCube > 0) and
                       (Status = 'A'/* Active */)))
    begin
      /* Get the first task detail to cube */
      select top 1 @vRecordId        = RecordId,
                   @vUniqueId        = UniqueId,
                   @vOrderId         = OrderId,
                   @vSKUId           = SKUId,
                   @vSKU             = SKU,
                   @vPickTicket      = PickTicket,
                   @vSalesOrder      = SalesOrder,
                   @vQtyToCube       = QtyToCube,
                   @vSpacePerIP      = SpacePerIP,
                   @vSpacePerUnit    = SpacePerUnit,
                   @vWeightPerIP     = InnerPackWeight,
                   @vWeightPerUnit   = UnitWeight,
                   @vNestingFactor   = NestingFactor,
                   @vUnitsPerIP      = UnitsPerIP,
                   @vOwnership       = Ownership,
                   @vWarehouse       = Warehouse,
                   @vPackingGroup    = PackingGroup,
                   @vInventoryClass1 = InventoryClass1,
                   @vInventoryClass2 = InventoryClass2,
                   @vInventoryClass3 = InventoryClass3
      from #DetailsToCube
      where (QtyToCube > 0) and (Status = 'A' /* Available to Cube */)
      order by SortSeq, RecordId;

      if (charindex('D', @vDebug) > 0) print 'Cubing OD/TD ' + cast(@vUniqueId as varchar);

      select @vCubeCartonId = null, @vUnitsToCube = 0, @vEmptyCartonSpace = 0, @vCartonType = null;

      /* If SKU Carton Group is defined as STD_UNIT then each unit will goes into a
         standard carton by itself */
      if (@vPackingGroup = 'STD_UNIT')
        begin
          select @vCartonType  = 'STD_UNIT',
                 @vUnitsToCube = 1;

          goto AddCartons;
        end

      /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_FindAvailableCarton';

      /* Find a carton that into which we can pack at least one unit of the given SKU. If the
         packing group of this Task detail has changed, then we can skip this as all previously
         cubed cartons have a different packing group */
      if (@vPrevPackingGroup = @vPackingGroup)
        exec pr_Cubing_FindAvailableCarton @vOrderId,
                                           @vPackingGroup,
                                           @vSKUId,
                                           @vQtyToCube,
                                           @vCubeCartonId     output,
                                           @vUnitsToCube      output,
                                           @vEmptyCartonSpace output;

      if (charindex('D', @vDebug) > 0) print 'Available Carton ' + cast(@vCubeCartonId as varchar);

      /* If no existing carton was found then we need to create a new carton. The new carton
         may be able to accommodate the entire inventory or some of it */
      if (@vCubeCartonId is null)
        begin
          /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_FindOptimalCarton';

          /* Find an empty carton to use */
          exec pr_Cubing_FindOptimalCarton @vOrderId,
                                           @vPackingGroup,
                                           @vSKUId,
                                           @vCartonType         output,
                                           @vEmptyCartonSpace   output,
                                           @vMaxUnitsPerCarton  output,
                                           @vMaxWeightPerCarton output;

          /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'End_FindOptimalCarton';
          if (charindex('D', @vDebug) > 0) print 'New Carton ' + coalesce(@vCartonType, '');

          /* Determine how many units (which could be multiple of IPs) to be cubed into the available space */
          exec pr_Cubing_ComputeUnitsToCube @vSKUId, @vCartonType, @vQtyToCube, @vEmptyCartonSpace,
                                            @vMaxUnitsPerCarton, @vMaxWeightPerCarton, @vUnitsToCube output;

          if (charindex('D', @vDebug) > 0) select @vCartonType CartonType, @vEmptyCartonSpace AvailableSpace, @vSpacePerUnit SpacePerUnit, @vSpacePerIP SpacePerIP,
                                                  @vNestingFactor NF, @vMaxUnitsToCubeToCarton MaxUnits, @vUnitsToCube UnitsToCube, @vQtyToCube TaskDetailQty,
                                                  @vPackingGroup PackingGroup;

          /* If at least one unit of the SKU cannot be cubed into an empty carton then ignore the
             task and move onto next task. This could happen if the item cannot fit into any of
             the available cartons */
          if (@vCartonType is null) or (@vUnitsToCube = 0)
            begin
              update #DetailsToCube
              set Status = 'I'
              where UniqueId = @vUniqueId;

              if (charindex('D', @vDebug) > 0) print 'Unable to cube Task';
              continue;
            end
        end

AddCartons:
      /* If an optimal carton is found then generate a Temp label */
      if (@vCartonType is not null) and (@vCubeCartonId is null)
        begin
          select @vMaxCartonDimension = MaxCartonDimension,
                 @vFirstDimension     = FirstDimension,
                 @vSecondDimension    = SecondDimension,
                 @vThirdDimension     = ThirdDimension
          from #CartonTypes
          where CartonType = @vCartonType;

          /* Start a new carton */
          insert into #CubeCartonHdrs(CartonType, WaveId, WaveNo, OrderId, PickTicket, SalesOrder, Ownership,
                                      Status, EmptyCartonSpace, MaxUnits, MaxWeight, Warehouse, PackingGroup,
                                      InventoryClass1, InventoryClass2, InventoryClass3, MaxDimension,
                                      FirstDimension, SecondDimension, ThirdDimension)
            select @vCartonType, @vWaveId, @vWaveNo, @vOrderId, @vPickTicket, @vSalesOrder, @vOwnership,
                   'O', @vEmptyCartonSpace, @vMaxUnitsPerCarton, @vMaxWeightPerCarton, @vWarehouse, @vPackingGroup,
                   @vInventoryClass1, @vInventoryClass2, @vInventoryClass3, @vMaxCartonDimension,
                   @vFirstDimension, @vSecondDimension, @vThirdDimension;

          /* Get the CartonId */
          select @vCubeCartonId = SCOPE_IDENTITY();
        end

      /* There is available space for vUnitsToCube in vCubeCartonId */
      insert into #CubeCartonDtls (CartonId, SKUId, SKU, SpacePerIP, SpacePerUnit, WeightPerIP, WeightPerUnit, UnitsPerIP, NestingFactor, UnitsCubed, UniqueId)
        select @vCubeCartonId, @vSKUId, @vSKU, @vSpacePerIP, @vSpacePerUnit, @vWeightPerIP, @vWeightPerUnit, @vUnitsPerIP, @vNestingFactor, @vUnitsToCube, @vUniqueId;

      /* get the NumUnits and NumSKUs in the carton to update carton hdr */
      select @vNumUnits   = sum(UnitsCubed),
             @vNumSKUs    = count(distinct SKUId),
             @vSpaceUsed  = sum(SpaceUsed),
             @vWeightUsed = sum(WeightUsed)
      from #CubeCartonDtls
      where (CartonId = @vCubeCartonId);

      /* Recompute Availablespace on carton hdr */
      update #CubeCartonHdrs
      set NumUnits   = @vNumUnits,
          NumSKUs    = @vNumSKUs,
          SpaceUsed  = @vSpaceUsed,
          WeightUsed = @vWeightUsed
      where (CartonId = @vCubeCartonId);

      /* Update TaskDetailsToCube to reflect how many units are cubed */
      update #DetailsToCube
      set CubedQty = CubedQty + @vUnitsToCube,
          Status   = case when QtyToCube - @vUnitsToCube = 0 then 'C' /* Cubed */ else Status end
      where (RecordId = @vRecordId);

      /* Set Prev Packing Group */
      set @vPrevPackingGroup = @vPackingGroup;
    end /* while.. cube next task */

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_AddCartons';

  /* Update SortIndex on the hash tables so that LPN creation and UCC generation will be done in the same order */
  ;with CHSortOrder as
  (
   select CartonId,
          row_number() over (order by SortOrder, CartonId) as SortIndex
   from #CubeCartonHdrs
  )
  update CH
  set SortIndex = SO.SortIndex
  from #CubeCartonHdrs CH
    join CHSortOrder SO on (CH.CartonId = SO.CartonId);

  /* If this procedure handles the transactions, then start one for each order */
  if (@TransactionScope = 'Procedure')
    begin transaction;

  /* Invoke proc to create Ship Cartons*/
  exec pr_Cubing_AddCartons @vWaveId, @Operation, @BusinessUnit, @UserId;

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Start_AddCartonDetails';

  /* Invoke proc to add details to TempLables and link them to Task Details for the current order */
  exec pr_Cubing_AddCartonDetails @vWaveId, @Operation, @BusinessUnit, @UserId;

  /* If this procedure handles the transactions, then commit for the last Order */
  if (@TransactionScope = 'Procedure') and (@@trancount > 0) -- if there is an existing transaction, then commit it, it must be for the previous order
     commit;

  /*-------- Generate UCC Barcodes ---------*/

  /* Get all the LPNs to geneate UCC bacrcodes */
  insert into #LPNShipLabels (LPNId) select LPNId from #CubeCartonHdrs order by LPNId;

  if (@TransactionScope = 'Procedure')
    begin transaction;

  /* generate uccbarcode for the generated TempLabels */
  exec pr_ShipLabel_GenerateUCCBarcodes @UserId, @BusinessUnit;

  if (@TransactionScope = 'Procedure') and (@@trancount > 0)
    commit;

  /*------------- Recount LPNs -------------*/
  /* Get all the LPNs to Recount */
  insert into @ttLPNsToRecount(EntityId) select LPNId from #CubeCartonHdrs order by LPNId;
  exec pr_LPNs_Recalculate @ttLPNsToRecount, 'C' /* Update Counts */, @UserId;

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'End_Cubing_Wave';
  if (charindex('L', @Debug) > 0) exec pr_Markers_Log @ttMarkers, 'Wave', @vWaveId, @vWaveNo, 'Cubing_Execute', @@ProcId, 'Markers_Cubing_Execute';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_Execute */

Go
