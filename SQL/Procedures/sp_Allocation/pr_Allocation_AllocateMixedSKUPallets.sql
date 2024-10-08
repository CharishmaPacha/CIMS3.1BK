/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/12/01  VM      Mixed SKU Pallet Allocation changes (FB-826)
                        pr_Allocation_AllocatePallets => pr_Allocation_AllocateSolidSKUPallets.
                        pr_Allocation_AllocateWave: Changes due to modified rule name and newly added rule.
                        pr_Allocation_CreatePalletPick: Introduced.
                        pr_Allocation_AllocateMixedSKUPallets: Introduced.
                        fn_PickBatches_GetOrderDetailsToAllocate: Return Warehouse as well.
                        pr_Allocation_FindAllocablePallets: Introduced.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AllocateMixedSKUPallets') is not null
  drop Procedure pr_Allocation_AllocateMixedSKUPallets;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AllocateMixedSKUPallets: Procedure to allocate mixed SKU
    pallets for a wave. It considers allocation rules to identify the pallets
    as well as only considers pallets which have SKUs of interest.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AllocateMixedSKUPallets
  (@WaveId         TRecordId,
   @WaveNo         TPickBatchNo = null,
   @PickTicket     TPickTicket  = null,
   @Operation      TOperation   = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @Debug          TFlags = 'N' /* No */)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vRecordId        TRecordId,

          @vWaveId          TRecordId,
          @vWaveNo          TPickBatchNo,
          @vWaveType        TTypeCode,
          @vWaveWarehouse   TWarehouse,

          @vOrderId         TRecordId,

          @vPalletId        TRecordId,
          @vPallet          TPallet,
          @vUnitsToAllocate TQuantity,
          @vRuleGroup       TDescription,

          @vSearchSet       TDescription,
          @vPalletAllocated TFlag;

  declare @ttOrderDetailsToAllocate    TOrderDetailsToAllocateTable,
          @ttAllocationRules           TAllocationRulesTable,
          @ttSKUOrderDetailsToAllocate TOrderDetailsToAllocateTable;

  declare @ttAllocablePallets Table
          (PalletId          TRecordId,
           Pallet            TPallet,
           MinLPNId          TRecordId,
           RecordId          TRecordId identity (1,1));

  declare @ttAllocablePalletsByRule Table
          (PalletId          TRecordId,
           Pallet            TPallet,
           RecordId          TRecordId identity (1,1));

  declare @ttAllocableUnitsOnPallet Table
          (SKUId             TRecordId,
           Ownership         TOwnership,
           Lot               TLot,
           Warehouse         TWarehouse,
           KeyValue          as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' + coalesce(Lot, ''),
           UnitsAvailable    TQuantity);
begin /* pr_Allocation_AllocateMixedSKUPallets */

  /* ------------------------------------------------------------------------*/
  /* Initialize variables */
  /* ------------------------------------------------------------------------*/
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vRuleGroup   = '00';

  /* ------------------------------------------------------------------------*/
  /* Get values from tables */
  /* ------------------------------------------------------------------------*/
  /* Get the Pick Batch Details */
  select @vWaveId        = RecordId,
         @vWaveNo        = BatchNo,
         @vWaveType      = BatchType,
         @vWaveWarehouse = Warehouse
  from PickBatches
  where (RecordId = @WaveId) or
        (BatchNo  = @WaveNo);

  /* Get Order Details  */
  select @vOrderId    = OrderId
  from OrderHeaders
  where (PickTicket   = @PickTicket  ) and
        (BusinessUnit = @BusinessUnit);

  /* ------------------------------------------------------------------------*/
  /* Get Allocation Rules */
  /* ------------------------------------------------------------------------*/
  select @vSearchSet = case
                         when (@Operation = 'Replenish') then
                           @vWaveType + '_MP_REP' /* (M)ixed (P)allet (REP)lenish */
                         when (@Operation = 'BPTAllocation') then
                           @vWaveType + '_MP_BO'  /* (M)ixed (P)allet (B)PT(O)rder set */
                         when (@vWaveType in ('R', 'RP', 'RU' /* Replenish Cases, Units */)) then
                           @vWaveType + '_MP'     /* (M)ixed (P)allet */
                         else
                           @vWaveType + '_MP_CO'  /* (M)ixed (P)allet (C)lient (O)rder set */
                       end;

  insert into @ttAllocationRules
    select * from dbo.fn_Allocation_GetAllocationRules(@vWaveType, @vSearchSet, @vWaveWarehouse, @BusinessUnit);

  if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: Rules' Message, * from @ttAllocationRules order by RecordId;

  /* ------------------------------------------------------------------------*/
  /* Get wave/order details to allocate & Summarize */
  /* ------------------------------------------------------------------------*/

  /* Get all the details for the wave which needd to be allocated into a temp table.
     Reduce the UnitsToAllocate so that it is in multiples of innerpacks - VM: I am not sure what it means */
  insert into @ttOrderDetailsToAllocate
    select * from dbo.fn_PickBatches_GetOrderDetailsToAllocate(@vWaveId, @vWaveType, null, @Operation)
    where (@vOrderId is null) or (OrderId = @vOrderId);

  if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: OrderDetailsToAllocate' Message, * from @ttOrderDetailsToAllocate

  /* Insert all the summarized data into a temp table */
  insert into @ttSKUOrderDetailsToAllocate(SKUId, DestZone, SKUABCClass, Ownership, Lot, Account, Warehouse, UnitsToAllocate)
    select SKUId, DestZone, SKUABCClass, Ownership, coalesce(Lot, ''), Account, Warehouse, sum(UnitsToAllocate)
    from @ttOrderDetailsToAllocate
    group by SKUId, DestZone, SKUABCClass, Ownership, Lot, Account, Warehouse;

  if (charindex('D', @Debug) > 0) select 'Allocate Mixed SKU Pallets: SKUOrderDetailsToAlloc' Message, * from @ttSKUOrderDetailsToAllocate;

  /* ------------------------------------------------------------------------*/
  /* Get all the potential pallets that can be allocated */
  /* ------------------------------------------------------------------------*/
  insert into @ttAllocablePallets(PalletId, Pallet, MinLPNId)
    exec pr_Allocation_FindAllocablePallets @ttAllocationRules, @ttSKUOrderDetailsToAllocate, 'N' /* No */; -- Cannot send Debug as 'Y' as expected return dataset becomes different!

  if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: AllocablePallets' Message, * from @ttAllocablePallets;

  if (not exists(select * from @ttAllocablePallets)) goto ExitHandler;

  /* ------------------------------------------------------------------------*/
  /* Loop through all allocation rules and gather all pallets which are satisfied by rule */
  /* ------------------------------------------------------------------------*/
  while (exists(select * from @ttAllocationRules where RuleGroup > @vRuleGroup))
    begin
      /* Get the rule Id */
      select top 1 @vRuleGroup = RuleGroup from @ttAllocationRules where RuleGroup > @vRuleGroup order by RuleGroup;

      /* Gather all Pallets which are satisfied by the curent rule. If FIFO, then allocate the pallets with the OldestLPNId first
         else order by Search order in the rule group and then the pick path */
      delete from @ttAllocablePalletsByRule;
      insert into @ttAllocablePalletsByRule
        select AP.PalletId, AP.Pallet
        from @ttAllocablePallets AP
          join vwPallets           P on (P.PalletId = AP.PalletId)
          join @ttAllocationRules AR on (AR.RuleGroup = @vRuleGroup) and
                                        (coalesce(P.LocationType, '') = coalesce(AR.LocationType, P.LocationType, '')) and
                                        (coalesce(P.StorageType,  '') = coalesce(AR.StorageType,  P.StorageType,  '')) and
                                        (coalesce(P.PickingClass, '') = coalesce(AR.PickingClass, P.PickingClass, '')) and
                                        (coalesce(P.PickingZone,  '') = coalesce(AR.PickingZone,  P.PickingZone,  ''))
        group by AP.PalletId, AP.Pallet
        order by case when coalesce(min(AR.OrderByField), '') = 'FIFO' then min(AP.MinLPNId) end,
                 min(AR.SearchOrder),
                 min(P.PickPath),
                 min(AP.MinLPNId);

      if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: AllocablePalletsPerRule' Message, @vRuleGroup, * from @ttAllocablePalletsByRule;

      /* ------------------------------------------------------------------------*/
      /* Loop through all rule satisfied pallets and try to allocate */
      /* ------------------------------------------------------------------------*/
      while (exists(select * from @ttAllocablePalletsByRule where RecordId > @vRecordId)) and
            (exists(select * from @ttSKUOrderDetailsToAllocate where UnitsToAllocate > 0))
        begin
          if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: SKUOrderDetailsToAllocAfterAlloc' Message, * from @ttSKUOrderDetailsToAllocate;

          /* Get the next pallet to allocate */
          select top 1
                 @vPalletId        = PalletId,
                 @vPallet          = Pallet,
                 @vRecordId        = RecordId,
                 @vPalletAllocated = 'N' /* No */
          from @ttAllocablePalletsByRule
          where (RecordId > @vRecordId)
          order by RecordId;

          /* Get the total units of the Pallet to reduce units in ODA.UnitsToAllocate, if allocated */
          delete from @ttAllocableUnitsOnPallet;
          insert into @ttAllocableUnitsOnPallet(SKUId, Ownership, Lot, Warehouse, UnitsAvailable)
            select SKUId, Ownership, coalesce(Lot, ''), DestWarehouse, sum(Quantity)
            from vwLPNs
            where (PalletId = @vPalletId)
            group by SKUId, Ownership, Lot, DestWarehouse;

-- I thought we were supposed to check here again to see if all units of this pallet are needed or not

          if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: AllocableUnitsOnPallet' Message, * from @ttAllocableUnitsOnPallet;

          /* Try to allocate the pallet */
          exec pr_Allocation_IsPalletAllocable @vWaveId,
                                               @vOrderId,
                                               @ttOrderDetailsToAllocate,
                                               @vPalletId,
                                               @BusinessUnit,
                                               @vPalletAllocated output;

          /* If not this pallet, then continue with next one */
          if (@vPalletAllocated = 'N') continue;

          /* ------------------------------------------------------------------------*/
          /* Create pallet pick */
          /* ------------------------------------------------------------------------*/
          exec pr_Allocation_CreatePalletPick @vPalletId, @vWaveNo, @Operation, @BusinessUnit, @UserId, 'N' /* Debug */;

          /* ------------------------------------------------------------------------*/
          /* Update UnitsToAllocate */
          /* ------------------------------------------------------------------------*/
          /* Reduce UnitsToAllocate from @ttSKUOrderDetailsToAllocate, if Pallet is allocated */
          update ODA
          set ODA.UnitsToAllocate = ODA.UnitsToAllocate - AUP.UnitsAvailable
          from @ttSKUOrderDetailsToAllocate ODA
            join @ttAllocableUnitsOnPallet AUP on (AUP.KeyValue = ODA.KeyValue);

          /*------------------------------------------------------------------------*/
          /* If Pallet allocated, remove it from allocable pallets pool */
          /*------------------------------------------------------------------------*/
          delete from @ttAllocablePallets where PalletId = @vPalletId;

          if (charindex('D', @Debug) > 0) select 'AllocateMixedSKUPallets: Allocated Pallet' Message, * from Pallets where PalletId = @vPalletId;
        end /* Allocable Pallets by rule */
    end /* Allocation rules */
ErrorHandler:
  exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AllocateMixedSKUPallets */

Go
