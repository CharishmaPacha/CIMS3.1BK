/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/08  TK      pr_Allocation_GenerateShipCartonsForPrepacks: Use UnitsPerCarton if there is one on the order detail (BK-563)
  2021/06/11  TK      pr_Allocation_GenerateShipCartonsForPrepacks: Bug fix in adding details to wrong carton (HA-2891)
  2021/05/21  TK      pr_Allocation_AllocateWave: Pass cartonization model to evaluate rules
                      pr_Allocation_GetWavesToAllocate: Changes return CaronizationModel
                      pr_Allocation_GenerateShipCartonsForPrepacks: Initial Revision (HA-2664)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GenerateShipCartonsForPrepacks') is not null
  drop Procedure pr_Allocation_GenerateShipCartonsForPrepacks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GenerateShipCartonsForPrepacks generates ship cartons for the orders according
   in bundle of Prepacks

  OD.UnitsPerInnerpack defines how many units of the OD.SKU make up a prepack
  and OD.PrepackCode defines which lines make up the prepack. If order has multiple
  prepacks, each group of lines would be identified with a diff. prepack code
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GenerateShipCartonsForPrepacks
  (@WaveId             TRecordId,
   @TransactionScope   TTransactionScope,
   @Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Debug              TFlags     = null)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vWaveId                TRecordId,
          @vWaveNo                TPickBatchNo,
          @vWaveType              TTypeCode,

          @vOrderId               TRecordId,
          @vPickTicket            TPickTicket,
          @vSalesOrder            TSalesOrder,
          @vOwnership             TOwnership,
          @vWarehouse             TWarehouse,

          @vMaxUnitsPerCarton     TInteger,
          @vUnitsRemaining        TInteger,
          @vKitsToCreate          TInteger,
          @vKitsToAdd             TInteger,
          @vKitQuantity           TInteger,
          @vKitsToFit             TInteger,
          @vPrepackCode           TCategory,
          @vSortOrder             TSortOrder,

          @vCartonId              TRecordId,
          @vCartonType            TCartonType,
          @vInputXML              TXML,

          @vInventoryClass1       TInventoryClass,
          @vInventoryClass2       TInventoryClass,
          @vInventoryClass3       TInventoryClass;

  declare @ttCartonDims           TCartonDims,
          @ttOrderDetails         TOrderDetails,
          @ttCubeCartonHdrs       TCubeCartonHdr,
          @ttCreateLPNDetails     TLPNDetails,
          @ttLPNsToRecount        TRecountKeysTable,
          @ttLPNShipLabelData     TLPNShipLabelData;
begin /* pr_Allocation_GenerateShipCartons */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get Wave Info */
  select @vWaveId            = RecordId,
         @vWaveNo            = BatchNo,
         @vWaveType          = BatchType,
         @vWarehouse         = Warehouse,
         @vMaxUnitsPerCarton = MaxUnitsPerCarton
  from Waves
  where (RecordId = @WaveId);

  /* Create temp tables */
  select * into #OrderDetails from @ttOrderDetails;
  select * into #CreateLPNDetails from @ttCreateLPNDetails;
  select * into #CartonDims from @ttCartonDims;

  select * into #CubeCartonHdrs from @ttCubeCartonHdrs;
  alter table #CubeCartonHdrs drop column NumUnits, MaxUnits, UnitsRemaining;
  alter table #CubeCartonHdrs add NumUnits            integer  default 0,
                                  MaxUnits            integer  default 9999,
                                  UnitsRemaining      as (MaxUnits - NumUnits);

  select * into #LPNShipLabels from @ttLPNShipLabelData;
  alter table #LPNShipLabels add ShipFrom           varchar(50),
                                 LabelFormatName    varchar(128),
                                 RecordId           integer;

  /* Get all the Order Details to be processed */
  /* disregard the order details that are already labeled
     do not consider shipped orders */
  ;with LabeledUnits as
   (
    select OD.OrderId, OD.OrderDetailId, sum(LD.Quantity) as QtyLabeled
    from OrderHeaders OH
      join OrderDetails OD on (OD.OrderId = OH.OrderId)
      join LPNDetails   LD on (LD.OrderId = OD.OrderId) and (LD.OrderDetailId = OD.OrderDetailId) -- for performance
      join LPNs         L  on (L.LPNId = LD.LPNId)
    where (OH.PickBatchId = @WaveId) and
          (OH.OrderType <> 'B'/* Bulk */) and
          (OH.Status not in ('S', 'X', 'D' /* Shipped, Canceled, Completed */)) and
          (LD.OnhandStatus = 'U') and
          (L.Status not in ('S', 'V', 'C' /* Shipped, Voided, Consumed */))
    group by OD.OrderId, OD.OrderDetailId
   )
  insert into #OrderDetails(WaveId, WaveNo, OrderId, PickTicket, SalesOrder, OrderDetailId, SKUId, SKU,
                            UnitsToShip, UnitsAssigned, UnitsToAllocate, UnitsPerCarton, UnitsPerInnerPack,
                            InventoryClass1, InventoryClass2, InventoryClass3, PackingGroup, PrepackCode, Ownership, Warehouse, SortOrder, OD_UDF1, ProcessFlag)
    select OH.PickBatchId, OH.PickBatchNo, OH.OrderId, OH.PickTicket, OH.SalesOrder, OD.OrderDetailId, OD.SKUId, S.SKU,
           OD.UnitsAuthorizedToShip, OD.UnitsAssigned, (OD.UnitsToAllocate - coalesce(LU.QtyLabeled, 0)),
           coalesce(nullif(OD.UnitsPerCarton, 0), @vMaxUnitsPerCarton), OD.UnitsPerInnerPack,
           OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3, OD.PackingGroup, OD.PrepackCode, OH.Ownership, OH.Warehouse, SortOrder, coalesce(OH.UDF10, ''), 'N'
    from OrderHeaders OH
      join OrderDetails OD on (OH.OrderId = OD.OrderId)
      left outer join LabeledUnits LU on (OD.OrderDetailId = LU.OrderDetailId)
      join SKUs S on (OD.SKUId = S.SKUId)
    where (OH.PickBatchId = @WaveId) and
          (OH.OrderType <> 'B'/* Bulk */) and
          (OD.PrePackCode > '') and
          (OD.UnitsToAllocate - coalesce(LU.QtyLabeled, 0) > 0)
    order by OD.OrderId, OD.PackingGroup, OD.SortOrder;

  /* If there are no ODs to generate labels for i.e. none of them have prepacks or
     if the labels are already generated then exit */
  if not exists(select * from #OrderDetails)
    goto ExitHandler;

  /* Compute possible number of cartons for each line and residual units */
  ;with KitsPossible as
  (
    select OrderId, PrepackCode,
           min(UnitsToAllocate / UnitsPerInnerpack) as KitsPossible,
           sum(UnitsPerInnerpack) as KitQuantity
    from #OrderDetails
    group by OrderId, PrepackCode
  )
  update OD
  set KitsToCreate  = floor(UnitsToAllocate / UnitsPerInnerpack),
      KitsPossible  = KP.KitsPossible, -- Possible number of cartons that can be created for each packing group
      ResidualUnits = UnitsToAllocate - (UnitsPerInnerpack * KP.KitsPossible),  -- Units that may be left out after cartons for each packing group
      KitQuantity   = KP.KitQuantity
  from #OrderDetails OD
    join KitsPossible KP on (OD.OrderId = KP.OrderId) and (OD.PrepackCode = KP.PrepackCode);

  /* Get all Prepack combinations */
  select OrderId, PrepackCode, min(KitsPossible) as KitsToCreate,
         min(KitQuantity) as KitQuantity, max(UnitsPerCarton) as MaxUnitsPerCarton,
         min(SortOrder) as SortOrder, row_number() over (order by OrderId, PrepackCode) as RecordId
  into #PrepackCombinations
  from #OrderDetails
  group by OrderId, PrepackCode
  order by OrderId, PrepackCode, SortOrder;

  /* Delete the prepacks whose quantity is more than the max units per carton */
  delete PPC
  from #PrepackCombinations PPC
  where (KitQuantity > MaxUnitsPerCarton);

  /* loop through each prepack combintaion and add cartons and its details */
  while (exists(select * from #PrepackCombinations where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId          = RecordId,
                   @vOrderId           = OrderId,
                   @vPrepackCode       = PrepackCode,
                   @vKitsToCreate      = KitsToCreate,
                   @vKitQuantity       = KitQuantity,
                   @vMaxUnitsPerCarton = MaxUnitsPerCarton
      from #PrepackCombinations
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Iterate until KitsToCreate is greater than zero */
      while (@vKitsToCreate > 0)
        begin
          /* Check if there is an carton that can fit atleast one kit */
          if exists (select * from #CubeCartonHdrs where OrderId = @vOrderId and UnitsRemaining >= @vKitQuantity)
            begin
              select top 1 @vCartonId  = CartonId,
                           @vKitsToFit = floor(UnitsRemaining / @vKitQuantity)  -- max kits that can be added to carton
              from #CubeCartonHdrs
              where (OrderId = @vOrderId) and
                    (UnitsRemaining >= @vKitQuantity)
              order by UnitsRemaining desc;

              /* Based on the Kits that can be fit in the carton compute the number of kits that can be added */
              select @vKitsToAdd = dbo.fn_MinInt(@vKitsToFit, @vKitsToCreate)
            end

          /* If there is no carton found then create a new one */
          if (@vCartonId is null)
            begin
              /* Get reqired info to create new carton */
              select top 1 @vWaveId          = WaveId,
                           @vWaveNo          = WaveNo,
                           @vPickTicket      = PickTicket,
                           @vSalesOrder      = SalesOrder,
                           @vOwnership       = Ownership,
                           @vWarehouse       = Warehouse,
                           @vInventoryClass1 = InventoryClass1,
                           @vInventoryClass2 = InventoryClass2,
                           @vInventoryClass3 = InventoryClass3,
                           @vSortOrder       = SortOrder
              from #OrderDetails
              where (OrderId = @vOrderId) and
                    (PrepackCode = @vPrepackCode);

              /* Insert data to create a new carton */
              insert into #CubeCartonHdrs(WaveId, WaveNo, OrderId, PickTicket, SalesOrder, MaxUnits,
                                          InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, SortOrder, Status)
                select @vWaveId, @vWaveNo, @vOrderId, @vPickTicket, @vSalesOrder, @vMaxUnitsPerCarton,
                       @vInventoryClass1, @vInventoryClass2, @vInventoryClass3, @vOwnership, @vWarehouse, @vSortOrder, 'O' /* Open */;

              /* Get the CartonId created and compute the Kits that can be added to carton */
              select @vCartonId   = scope_identity(),
                     @vKitsToAdd = dbo.fn_MinInt(floor(@vMaxUnitsPerCarton / @vKitQuantity), @vKitsToCreate);
            end

          /* Add details to all cartons created above */
          insert into #CreateLPNDetails (SKUId, OnhandStatus, Quantity, OrderId, OrderDetailId, Reference, BusinessUnit, CreatedBy)
            select OD.SKUId, 'U'/* OnhandStatus */, (OD.UnitsPerInnerpack * @vKitsToAdd), OD.OrderId, OD.OrderDetailId, CH.CartonId, @BusinessUnit, @UserId
            from #OrderDetails OD, #CubeCartonHdrs CH
            where (OD.PrepackCode = @vPrepackCode) and
                  (OD.OrderId = @vOrderId) and
                  (CH.CartonId = @vCartonId);

          /* Update NumUnits on the carton */
          update #CubeCartonHdrs
          set NumUnits += @vKitQuantity * @vKitsToAdd
          where (CartonId = @vCartonId);

          /* Reduce the KitsCreated */
          select @vKitsToCreate -= @vKitsToAdd,
                 @vCartonId      = null;
        end /* while @vKitsToCreate */
    end /* while PrepackCombintaions */

  /* If there are any residual units then create separate carton for each SKU */
  if exists(select * from #OrderDetails where ResidualUnits > 0 and OD_UDF1 <> 'FULLCASE')
    begin
      /* create separate for each packing group that has residual Units */
      insert into #CubeCartonHdrs(WaveId, WaveNo, OrderId, PickTicket, SalesOrder, CartonType,
                                  InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, PackingGroup, SortOrder, Status)
        select min(WaveId), min(WaveNo), OrderId, min(PickTicket), min(SalesOrder), @vCartonType,
               min(InventoryClass1), min(InventoryClass2), min(InventoryClass3), min(Ownership), min(Warehouse), PrepackCode, min(SortOrder), 'O' /* Open */
        from #OrderDetails
        where (ResidualUnits > 0)
        group by OrderId, PrepackCode;

      /* Add details to all cartons created above */
      insert into #CreateLPNDetails (SKUId, OnhandStatus, Quantity, OrderId, OrderDetailId, Reference, BusinessUnit, CreatedBy)
        select OD.SKUId, 'U'/* OnhandStatus */, OD.ResidualUnits, OD.OrderId, OD.OrderDetailId, CH.CartonId, @BusinessUnit, @UserId
        from #OrderDetails OD
          join #CubeCartonHdrs CH on (OD.OrderId = CH.OrderId) and
                                     (OD.PrepackCode = CH.PackingGroup)
        where (ResidualUnits > 0) and
              (CH.Status = 'O'/* Open */);
    end

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

  /* If this procedure handles the transactions, then start transaction here */
  if (@TransactionScope = 'Procedure')
    begin transaction;

  /* Invoke proc to create Ship Cartons*/
  exec pr_Cubing_AddCartons @WaveId, @Operation, @BusinessUnit, @UserId;

  /* Update ship carton info on the details to be created */
  update CLD
  set LPNId = CH.LPNId,
      LPN   = CH.LPN
  from #CreateLPNDetails CLD
    join #CubeCartonHdrs CH on (CLD.Reference = CH.CartonId);

  /* If there exists records in CreateLPNDetails then just invoke CreateLPNs procedure
     which will create/insert details for generated ship cartons */
  if exists (select * from #CreateLPNDetails)
    begin
      select @vInputXML = dbo.fn_XMLNode('Root',
                            dbo.fn_XMLNode('Data',
                              dbo.fn_XMLNode('Operation',   @Operation)));

      exec pr_LPNs_CreateLPNs @vInputXML;
    end

  /* If this procedure handles the transactions, then commit here */
  if (@TransactionScope = 'Procedure') and (@@trancount > 0)
    commit;

  /*--------- Identify CartonType ----------*/
  /* Get all the LPNs to identify carton types, weight and their dims */
  insert into #CartonDims (LPNId) select LPNId from #CubeCartonHdrs order by LPNId;

  exec pr_LPNs_EstimateCartonDims @WaveId, @Operation, @BusinessUnit, @UserId;

  /* Update carton type on LPNs */
  update L
  set CartonType = CD.CartonType
  from LPNs L
    join #CartonDims CD on (L.LPNId = CD.LPNId);

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

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GenerateShipCartonsForPrepacks */

Go
