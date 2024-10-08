/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/08  TK      pr_Allocation_GenerateShipCartonsForPrepacks: Use UnitsPerCarton if there is one on the order detail (BK-563)
  2021/06/11  TK      pr_Allocation_GenerateShipCartonsForPrepacks: Bug fix in adding details to wrong carton (HA-2891)
  2021/05/21  TK      pr_Allocation_AllocateWave: Pass cartonization model to evaluate rules
                      pr_Allocation_GetWavesToAllocate: Changes return CaronizationModel
                      pr_Allocation_GenerateShipCartonsForPrepacks: Initial Revision (HA-2664)
  2021/03/29  TK      pr_Allocation_GenerateShipCartons: Changes to generate UCCBarcodes and recount LPNs in a separate transaction (HA-2471)
  2021/03/05  AY/TK   pr_Allocation_GenerateShipCartons: Generate Ship cartons in Sequence (HA-2127)
  2021/02/21  TK      pr_Allocation_GenerateShipCartons: Minor corrections (HA-2033)
  2021/01/12  TK      pr_Allocation_GenerateShipCartons: Generate Cartons for residual Units (HA-1899)
  2020/05/31  TK      pr_Allocation_GenerateShipCartons: Update latest wave info on ship cartosn (HA-722)
  2020/05/30  TK      pr_Allocation_GenerateShipCartons: Bug Fix in adding LPNDetails of one order to other
                        Exclude Voided & Consumed LPNs (HA-646)
                      pr_Allocation_GenerateShipCartons: Changes to update inventory class on ship cartons (HA-703)
  2020/05/25  TK      pr_Allocation_CreateConsolidatedPT: Create BPT for Released status waves as well (HA-646)
                      pr_Allocation_GenerateShipCartons: Changes to generate cartons for each order line separately
                        when packing group is 'SOLID' (HA-648)
  2020/05/04  TK      pr_Allocation_GenerateShipCartons: Initial Revision
                      pr_Allocation_AllocateWave: Added step to generate ship cartons (HA-172)
                      pr_Allocation_AllocateWave &  pr_Allocation_GetWavesToAllocate:
                        Allocate inventory based upon InvAllocationModel (HA-385)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GenerateShipCartons') is not null
  drop Procedure pr_Allocation_GenerateShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GenerateShipCartons generates ship cartons for the orders according
   to packing group explained with an example below

Example 1:
OrderDetails:
  SKU     UnitsToAllocate     UnitsPerCarton     PackingGroup

  S1      10                  1                  PG1
  S2      20                  2                  PG1
  S3      10                  1                  PG1

Ship Cartons will be generated as below

  LPN     SKU         Quantity

  LPN1    S1          1
          S2          2
          S3          1
  LPN2    S1          1
          S2          2
          S3          1
  .
  .
  LPN10   S1          1
          S2          2
          S3          1

  But when it comes to the order details with packing group as 'SOLID', each line is treated as
  solid case explained with an example below

Example 2:
OrderDetails:
  SKU     UnitsToAllocate     UnitsPerCarton     PackingGroup

  S1      20                  2                  SOLID
  S2      20                  4                  SOLID
  S3      30                  5                  SOLID

Ship Cartons will be generated as below

  LPN     SKU         Quantity

  LPN1    S1          2
  LPN2    S1          2
  .
  .
  LPN10   S1          2

  LPN11   S2          4
  LPN12   S2          4
  .
  .
  LPN15   S2          4

  LPN16   S3          5
  LPN17   S3          5
  .
  .
  LPN21   S3          5

Apart from the above if there are any residual units then system will generate separate for each SKU
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GenerateShipCartons
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
          @vPrevOrderId           TRecordId,
          @vPickTicket            TPickTicket,
          @vSalesOrder            TSalesOrder,
          @vOwnership             TOwnership,
          @vWarehouse             TWarehouse,

          @vOrderDetailId         TRecordId,
          @vSKUId                 TRecordId,
          @vUnitsToAllocate       TInteger,
          @vUnitsPerInnerpack     TInteger,
          @vUnitsPerCarton        TInteger,
          @vNumCartonsToCreate    TInteger,
          @vQuantity              TInteger,
          @vPackingGroup          TCategory,
          @vPrevPackingGroup      TCategory,
          @vSortOrder             TSortOrder,

          @vCartonId              TRecordId,
          @vCartonType            TCartonType,
          @vInputXML              TXML,

          @vInventoryClass1       TInventoryClass,
          @vInventoryClass2       TInventoryClass,
          @vInventoryClass3       TInventoryClass;

  declare @ttOrderDetails         TOrderDetails,
          @ttCubeCartonHdrs       TCubeCartonHdr,
          @ttCreateLPNDetails     TLPNDetails,
          @ttLPNsToRecount        TRecountKeysTable,
          @ttLPNShipLabelData     TLPNShipLabelData;
begin /* pr_Allocation_GenerateShipCartons */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vCartonType  = 'STD_BOX',
         @vPrevOrderId = '';

  /* Get Wave Info */
  select @vWaveId    = RecordId,
         @vWaveNo    = BatchNo,
         @vWaveType  = BatchType,
         @vWarehouse = Warehouse
  from Waves
  where (RecordId  = @WaveId);

  /* Create temp tables */
  select * into #OrderDetails from @ttOrderDetails;
  select * into #CubeCartonHdrs from @ttCubeCartonHdrs;
  select * into #CreateLPNDetails from @ttCreateLPNDetails;

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
                            InventoryClass1, InventoryClass2, InventoryClass3, PackingGroup, Ownership, Warehouse, SortOrder, ProcessFlag)
    select OH.PickBatchId, OH.PickBatchNo, OH.OrderId, OH.PickTicket, OH.SalesOrder, OD.OrderDetailId, OD.SKUId, S.SKU,
           OD.UnitsAuthorizedToShip, OD.UnitsAssigned, (OD.UnitsToAllocate - coalesce(LU.QtyLabeled, 0)), OD.UnitsPerCarton, S.UnitsPerInnerPack,
           OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3, OD.PackingGroup, OH.Ownership, OH.Warehouse, SortOrder, 'N'
    from OrderHeaders OH
      join OrderDetails OD on (OH.OrderId = OD.OrderId)
      left outer join LabeledUnits LU on (OD.OrderDetailId = LU.OrderDetailId)
      join SKUs S on (OD.SKUId = S.SKUId)
    where (OH.PickBatchId = @WaveId) and
          (OH.OrderType <> 'B'/* Bulk */) and
          (OD.UnitsToAllocate - coalesce(LU.QtyLabeled, 0) > 0)
    order by OD.OrderId, OD.PackingGroup, OD.SortOrder;

  /* If not LPNs found then continue with next SKU */
  if not exists(select * from #OrderDetails)
    goto ExitHandler;

  /* If Packing group is SOLID, then we have to pack each line separately */
  update #OrderDetails
  set PackingGroup = OrderDetailId
  where (PackingGroup = 'SOLID');

  /* Compute possible number of cartons for each line and residual units */
  ;with KitsPossible as
  (
    select OrderId, PackingGroup, min(UnitsToAllocate / UnitsPerCarton) as KitsPossible
    from #OrderDetails
    group by OrderId, PackingGroup
  )
  update OD
  set KitsToCreate  = floor(UnitsToAllocate / UnitsPerCarton),
      KitsPossible  = KP.KitsPossible, -- Possible number of cartons that can be created for each packing group
      ResidualUnits = UnitsToAllocate - (UnitsPerCarton * KP.KitsPossible)  -- Units that may be left out after cartons for each packing group
  from #OrderDetails OD
    join KitsPossible KP on (OD.OrderId = KP.OrderId) and (OD.PackingGroup = KP.PackingGroup);

  /* loop through Order Details and generate a ship cartons based upon packing group */
  while (exists(select * from #OrderDetails where RecordId > @vRecordId and ProcessFlag = 'N' /* Not yet processed */))
    begin
      /* get the top 1 record from the temp table */
      select top 1 @vRecordId           = RecordId,
                   @vWaveId             = WaveId,
                   @vWaveNo             = WaveNo,
                   @vOrderId            = OrderId,
                   @vPickTicket         = PickTicket,
                   @vSalesOrder         = SalesOrder,
                   @vOrderDetailId      = OrderDetailId,
                   @vSKUId              = SKUId,
                   @vUnitsToAllocate    = UnitsToAllocate,
                   @vUnitsPerCarton     = UnitsPerCarton,
                   @vNumCartonsToCreate = KitsPossible,
                   @vPackingGroup       = PackingGroup,
                   @vOwnership          = Ownership,
                   @vWarehouse          = Warehouse,
                   @vInventoryClass1    = InventoryClass1,
                   @vInventoryClass2    = InventoryClass2,
                   @vInventoryClass3    = InventoryClass3,
                   @vSortOrder          = SortOrder
      from #OrderDetails
      where (RecordId > @vRecordId) and
            (ProcessFlag = 'N' /* Not yet processed */)
      order by RecordId;

      /* create required number of cartons */
      insert into #CubeCartonHdrs(WaveId, WaveNo, OrderId, PickTicket, SalesOrder, CartonType,
                                  InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, SortOrder, Status)
        select @vWaveId, @vWaveNo, @vOrderId, @vPickTicket, @vSalesOrder, @vCartonType,
               @vInventoryClass1, @vInventoryClass2, @vInventoryClass3, @vOwnership, @vWarehouse, @vSortOrder, 'O' /* Open */
        from dbo.fn_GenerateSequence(1, @vNumCartonsToCreate, null); -- execute select statements as many as number of cartons to create

      /* Add details to all cartons created above */
      insert into #CreateLPNDetails (SKUId, OnhandStatus, Quantity, OrderId, OrderDetailId, Reference, BusinessUnit, CreatedBy)
        select OD.SKUId, 'U'/* OnhandStatus */, OD.UnitsPerCarton, OD.OrderId, OD.OrderDetailId, CH.CartonId, @BusinessUnit, @UserId
        from #OrderDetails OD, #CubeCartonHdrs CH
        where (OD.PackingGroup = @vPackingGroup) and
              (OD.OrderId = @vOrderId) and
              (CH.Status = 'O'/* Open */);

      /* Close the open cartons once the details are added to them */
      update #CubeCartonHdrs
      set Status = 'C' /* Closed */
      where Status = 'O' /* Open */;

      /* Update records as processed */
      update #OrderDetails
      set ProcessFlag = 'P' /* Processed */
      where (PackingGroup = @vPackingGroup) and
            (OrderId      = @vOrderId)

      /* set previous Packing Group */
      select @vPrevOrderId = @vOrderId, @vPrevPackingGroup = @vPackingGroup;
    end

  /* If there are any residual units then create separate carton for each SKU */
  if exists(select * from #OrderDetails where ResidualUnits > 0)
    begin
      /* create separate for each SKU that has residual Units */
      insert into #CubeCartonHdrs(WaveId, WaveNo, OrderId, PickTicket, SalesOrder, CartonType,
                                  InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, UDF1, SortOrder, Status)
        select WaveId, WaveNo, OrderId, PickTicket, SalesOrder, @vCartonType,
               InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, RecordId, SortOrder, 'O' /* Open */
        from #OrderDetails
        where (ResidualUnits > 0);

      /* Add details to all cartons created above */
      insert into #CreateLPNDetails (SKUId, OnhandStatus, Quantity, OrderId, OrderDetailId, Reference, BusinessUnit, CreatedBy)
        select OD.SKUId, 'U'/* OnhandStatus */, OD.ResidualUnits, OD.OrderId, OD.OrderDetailId, CH.CartonId, @BusinessUnit, @UserId
        from #OrderDetails OD
          join #CubeCartonHdrs CH on (OD.RecordId = CH.UDF1)
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
end /* pr_Allocation_GenerateShipCartons */

Go
