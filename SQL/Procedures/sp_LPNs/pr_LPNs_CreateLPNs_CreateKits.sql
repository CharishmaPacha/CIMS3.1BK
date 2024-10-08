/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/28  NKL     pr_LPNs_RecalculateWeightVolume, pr_LPNs_CreateTempLabels, pr_LPNs_CreateLPNs_CreateKits,pr_LPNs_AddOrUpdate, pr_LPNDetails_UnallocatePendingReserveLine,
                      pr_LPNs_CreateLPNs_CreateKits, pr_LPNs_CreateLPNs_MaxKitsToCreate, pr_LPNs_Locate:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateLPNs_CreateKits') is not null
  drop Procedure pr_LPNs_CreateLPNs_CreateKits;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateLPNs_CreateKits: This procedure add Kit SKUs to the LPNs and locate them
    by reducing the picked inventory of component SKUs of that particular order for which
    user is trying to generate kits

    Exports: This proc will be generating positive inventory changes for Kit SKUs and
    negative inventory changes transactions for component SKUs
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateLPNs_CreateKits
  (@InputXML             xml)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,

          @OrderId                    TRecordId,
          @OrderDetailId              TRecordId,
          @SKUId                      TRecordId,
          @Quantity                   TQuantity,
          @NumLPNsToCreate            TInteger,
          @Lot                        TLot,
          @Ownership                  TOwnership,
          @Warehouse                  TWarehouse,
          @ReasonCode                 TReasonCode,
          @Reference                  TReference,
          @InventoryClass1            TInventoryClass,
          @InventoryClass2            TInventoryClass,
          @InventoryClass3            TInventoryClass,
          @Action                     TAction,
          @BusinessUnit               TBusinessUnit,
          @UserId                     TUserId,

          @vInvRecordId               TRecordId,
          @vCompRecId                 TRecordId,

          @vOrderId                   TRecordId,
          @vCompOrderDetailId         TRecordId,
          @vCompSKUId                 TRecordId,

          @vLPNId                     TRecordId,
          @vKitLPNId                  TRecordId,
          @vKitLPN                    TLPN,
          @vLPNDetailId               TRecordId,
          @vSplitLPNDetailId          TRecordId,
          @vLDQty                     TQuantity,
          @vLPNQuantity               TQuantity,

          @vKitsToCreate              TQuantity,
          @vQtyAllocated              TQuantity,
          @vQtyToReduce               TQuantity,
          @vComponentQtyPerKit        TQuantity,

          @vDropLocationId            TRecordId,
          @vDropLocation              TLocation;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vCompRecId   = 0;

  /* If no LPNs were created or there is no inventory to consume then return */
  if not exists (select * from #CreateLPNs) or
     not exists (select * from #InventoryToConsume)
    return;

  /* Get the XML User inputs into the local variables */
  select @OrderId          = Record.Col.value('OrderId[1]'            , 'TRecordId'),
         @OrderDetailId    = Record.Col.value('OrderDetailId[1]'      , 'TRecordId'),
         @SKUId            = Record.Col.value('SKUId[1]'              , 'TRecordId'),
         @Quantity         = Record.Col.value('UnitsPerLPN[1]'        , 'TQuantity'),
         @NumLPNsToCreate  = Record.Col.value('NumLPNsToCreate[1]'    , 'TQuantity'),
         @Ownership        = Record.Col.value('Owner[1]'              , 'TOwnership'),
         @Warehouse        = Record.Col.value('Warehouse[1]'          , 'TWarehouse '),
         @Lot              = Record.Col.value('Lot[1]'                , 'TLot'),
         @ReasonCode       = Record.Col.value('ReasonCode[1]'         , 'TReasonCode'),
         @Reference        = Record.Col.value('Reference[1]'          , 'TReasonCode'),
         @InventoryClass1  = Record.Col.value('InventoryClass1[1]'    , 'TInventoryClass'),
         @InventoryClass2  = Record.Col.value('InventoryClass2[1]'    , 'TInventoryClass'),
         @InventoryClass3  = Record.Col.value('InventoryClass3[1]'    , 'TInventoryClass')
  from @InputXML.nodes('Root/Data') as Record(Col);

  select @Action       = Record.Col.value('Action[1]'                    , 'TAction'),
         @BusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @UserId       = Record.Col.value('(SessionInfo/UserId)[1]'      , 'TUserId')
  from @InputXML.nodes('Root') as Record(Col);

  /* Get how many Kits user wants to create */
  select @vKitsToCreate = Quantity * @NumLPNsToCreate from #LPNDetails;

  /*---------------  Inventory Updates  -----------------*/
  /* Reduce component inventory from Picked LPNs */
  while exists (select * from #KitComponentsInfo where RecordId > @vCompRecId)
    begin
      select top 1 @vCompRecId          = RecordId,
                   @vOrderId            = OrderId,
                   @vCompOrderDetailId  = OrderDetailId,
                   @vCompSKUId          = SKUId,
                   @vComponentQtyPerKit = UnitsPerCarton
      from #KitComponentsInfo
      where (RecordId > @vCompRecId)
      order by RecordId;

      /* compute component qty to be reduced */
      select @vQtyToReduce = @vKitsToCreate * @vComponentQtyPerKit,
             @vInvRecordId = 0;

      /* Loop thru each picked LPN Detail and reduce qty */
      while (exists (select * from #InventoryToConsume where RecordId > @vInvRecordId)) and
            (@vQtyToReduce > 0)
        begin
          select top 1 @vInvRecordId = RecordId,
                       @vLPNId       = LPNId,
                       @vLPNDetailId = LPNDetailId,
                       @vLDQty       = Quantity
          from #InventoryToConsume
          where (RecordId > @vInvRecordId) and
                (SKUId = @vCompSKUId)
          order by RecordId;

          /* If Picked LPN Detail quantity is greater than quantity to reduce then split LPN detail and reduce qty */
          if (@vLDQty > @vQtyToReduce)
            begin
              /* invoke proc to split LPN detail */
              exec pr_LPNDetails_SplitLine @vLPNDetailId,
                                           0,  /* Inner Packs */
                                           @vQtyToReduce,  /* Units To Split */
                                           @vOrderId,
                                           @vCompOrderDetailId,
                                           @vSplitLPNDetailId output;

              /* Generate negative inventory exports */
              select @vLPNDetailId  = @vSplitLPNDetailId,
                     @vQtyAllocated = @vQtyToReduce,
                     @vQtyToReduce  = 0;
            end
          else
            begin
              /* compute qty to generate negative exports */
              select @vQtyAllocated = @vLDQty,
                     @vQtyToReduce  -= @vLDQty;
            end

          /* delete component LPN Detail */
          delete from LPNDetails where LPNDetailId = @vLPNDetailId;

          /* Reduce UATS on component Order Detail */
          update OrderDetails
          set UnitsAuthorizedToShip -= @vQtyAllocated,
              UnitsAssigned         -= @vQtyAllocated
          where (OrderDetailId = @vCompOrderDetailId);

          /* Update Qty consumed to log in exports */
          update #InventoryToConsume
          set ConsumedQty = coalesce(ConsumedQty, 0) + @vQtyAllocated
          where (RecordId = @vInvRecordId);

          /* Recount LPN */
          exec pr_LPNs_Recount @vLPNId;
        end /* while InventoryToConsume ... */
    end /* while KitComponents... */

  /*-----------------  Add Kit SKUs to LPNs  -------------------*/
  /* Once the component quantity is reduced, add kit SKUs to the LPNs generated earlier */
  insert into LPNDetails(LPNId, OnhandStatus, SKUId, InnerPacks, Quantity, UnitsPerPackage,
                         Weight, Volume, Lot, CoO, Reference, BusinessUnit, CreatedBy)
    select LPNId, 'A' /* Available */, SKUId, InnerPacks, Quantity, UnitsPerPackage,
           Weight, Volume, Lot, CoO, Reference, BusinessUnit, CreatedBy
    from #LPNDetails;

  /* Update UnitsAssigned on the Kit Order Detail. UATS to begin with would be zero
     on these lines, so have to increment that as well */
  update OrderDetails
  set UnitsAuthorizedToShip += @vKitsToCreate,
      UnitsAssigned         += @vKitsToCreate
  where (OrderDetailId = @OrderDetailId);

  /*--------------------  Generate Exports  ----------------------*/

  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Generate the transactional changes for all LPNs */
  insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, PalletId, LocationId, OrderId, OrderDetailId, Ownership, ReasonCode,
                              Lot, InventoryClass1, InventoryClass2, InventoryClass3, Warehouse, CreatedBy)
    /* Generate positive InvCh transactions for the Kit SKUs */
    select 'InvCh', Quantity, LPNId, SKUId, PalletId, LocationId, OrderId, OrderDetailId, @Ownership, @ReasonCode,
           @Lot, @InventoryClass1, @InventoryClass2, @InventoryClass3, @Warehouse, @UserId
    from #LPNDetails
    /* Generate negative InvCh transactions for component SKUs */
    union
    select 'InvCh', -1 * ConsumedQty, LPNId, SKUId, PalletId, LocationId, OrderId, OrderDetailId, Ownership, @ReasonCode,
           Lot, InventoryClass1, InventoryClass2, InventoryClass3, Warehouse, @UserId
    from #InventoryToConsume;

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'InvCh', 'LPN' /* TransEntity - LPN */, @BusinessUnit;

  /*---------------  Locating LPNs and/or Pallets  -----------------*/

  /* Get the Staging location to drop the created LPNs */
  select top 1 @vDropLocationId = LocationId
  from Locations
  where (LocationType = 'S'/* Staging */) and
        (Warehouse    = @Warehouse)
  order by Status;  -- Empty Location comes first

  /* If there is a location to then drop them */
  if (@vDropLocationId is not null)
    begin
      select EntityId as LPNId into #LPNsToLocate from #CreateLPNs;

      /* Invoke proc to locate LPNs & associated pallets */
      exec pr_LPNs_Locate @vDropLocationId, @BusinessUnit, @UserId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_CreateLPNs_CreateKits */

Go
