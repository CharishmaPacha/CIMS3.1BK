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

if object_id('dbo.pr_Allocation_FindAllocablePallets') is not null
  drop Procedure pr_Allocation_FindAllocablePallets;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_FindAllocablePallets:

  This procedure is to identify & return potential pallets
   - for the passed in set of SKU Order details
   - verifying by passed in allocation rules

  It uses different steps to identify the potential pallets, which are commented below...
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_FindAllocablePallets
  (@AllocationRules           TAllocationRulesTable readonly,
   @SKUOrderDetailsToAllocate TOrderDetailsToAllocateTable readonly,
   @Debug                     TFlag = 'N' /* No */)
as
  declare @ttAllocablePallets Table
                              (PalletId         TRecordId,
                               Pallet           TPallet,
                               SKUId            TRecordId,
                               MinLPNId         TRecordId,
                               KeyValue         TDescription,
                               MixedSKULPNCount TCount,
                               ReservedQty      TQuantity,
                               UnitsAvailable   TQuantity,

                               RecordId         TRecordId identity(1,1),

                               Unique (MixedSKULPNCount, RecordId),
                               Unique (ReservedQty, RecordId),
                               Unique (KeyValue, RecordId),
                               Unique (PalletId, RecordId),
                               Primary Key (RecordId)
                               );

  declare @ttIneligiblePallets Table (PalletId TRecordId);

  declare @vLogActivity  TFlag,
          @vxmlData      TXML;
begin /* pr_Allocation_FindAllocablePallets */

  /*------------------------------------------------------------------------*/
  /* Initialize variables */
  /*------------------------------------------------------------------------*/
  --select @vLogActivity = 'Y' /* Yes */;

  /*------------------------------------------------------------------------*/
  /* Activity Log */
  /*------------------------------------------------------------------------*/
  if (charindex('L' /* Log */, @Debug) > 0)
    begin
      /* Allocation Rules logging */
      select @vxmlData = (select * from @AllocationRules for XML raw('AllocationRules'), elements );
      exec pr_ActivityLog_AddMessage 'Allocation_FindAllocablePallets_Inputs', null, null, 'AllocationRules',
                                     'Inputs' /* Message */, @@ProcId, @vxmlData;

      /* SKU Order details logging */
      select @vxmlData = (select * from @SKUOrderDetailsToAllocate for XML raw('SKUOrderDetailsToAllocate'), elements );
      exec pr_ActivityLog_AddMessage 'Allocation_FindAllocablePallets_Inputs', null, null, 'SKUOrderDetailsToAllocate',
                                     'Inputs' /* Message */, @@ProcId, @vxmlData;
    end;

  /*------------------------------------------------------------------------*/
  /* Get all Mixed SKU Pallets which are satisfied by the allocation rules  */
  /*------------------------------------------------------------------------*/
  with AllocableLPNs (PalletId, Pallet, SKUId, LPNId, KeyValue, LPNQty, ReservedQty, MixedSKULPNCount) as
  (
    select distinct
           P.PalletId, P.Pallet, L.SKUId, L.LPNId,
           (cast(L.SKUId as varchar) + '-' + L.Ownership + '-' + L.DestWarehouse + '-' + coalesce(L.Lot, '')) /* KeyValue */,
           L.Quantity, L.ReservedQty,
           case when L.SKUId is null then 1 else 0 end /* Mixed SKU LPN Count */
    from vwPallets P
      join LPNs L on (L.PalletId = P.PalletId)
      join @AllocationRules AR on (coalesce(P.LocationType, '') = coalesce(AR.LocationType, P.LocationType, '')) and
                                  (coalesce(P.StorageType,  '') = coalesce(AR.StorageType,  P.StorageType,  '')) and
                                  (coalesce(P.PickingClass, '') = coalesce(AR.PickingClass, P.PickingClass, '')) and
                                  (coalesce(P.PickingZone,  '') = coalesce(AR.PickingZone,  P.PickingZone,  ''))
    where (P.Status = 'P' /* Putaway */) and (P.SKUId is null /* Consider Mixed SKU Pallets and avoid Solid SKU Pallets */)
  )
  insert into @ttAllocablePallets(PalletId, Pallet, SKUId, MinLPNId, KeyValue, MixedSKULPNCount,
                                  ReservedQty, UnitsAvailable)
    select AL.PalletId, AL.Pallet, AL.SKUId, min(AL.LPNId), AL.KeyValue, sum(AL.MixedSKULPNCount),
          sum(AL.ReservedQty), sum(AL.LPNQty)
    from AllocableLPNs AL
    group by AL.PalletId, AL.Pallet, AL.SKUId, AL.KeyValue;

  if (charindex('D', @Debug) > 0) select 'FindAllocablePallets: Pallets satisfied by Rules' Message, * from @ttAllocablePallets order by RecordId;

  /*------------------------------------------------------------------------*/
  /* Gather all pallets to eliminate, which have mixed SKU LPNs */
  /* Gather all pallets to eliminate, which are partially allocated */
  /*------------------------------------------------------------------------*/
  insert into @ttIneligiblePallets
    select distinct PalletId
    from @ttAllocablePallets
    where (MixedSKULPNCount > 0) or (ReservedQty > 0);

  /*------------------------------------------------------------------------*/
  /* Gather all pallets to eliminate, which have SKUs other than required SKUs */
  /*------------------------------------------------------------------------*/
  insert into @ttIneligiblePallets
    select distinct PalletId
    from @ttAllocablePallets
    where KeyValue not in (select KeyValue from @SKUOrderDetailsToAllocate);

  /*------------------------------------------------------------------------*/
  /* Gather all pallets which have more quantity than required  /SKU */
  /*------------------------------------------------------------------------*/
  insert into @ttIneligiblePallets
    select distinct AP.PalletId
    from @ttAllocablePallets AP
      join @SKUOrderDetailsToAllocate ODA on (ODA.KeyValue = AP.KeyValue)
    where (AP.UnitsAvailable > ODA.UnitsToAllocate);

  /*------------------------------------------------------------------------*/
  /* Eliminate all gathered pallets
    -- which have mixed SKU LPNs */
    -- which are partically allocated */
    -- which have SKUs other than required SKUs or pallets
    -- which have more qty than required for the SKU */
  /*------------------------------------------------------------------------*/
  delete @ttAllocablePallets
  from @ttAllocablePallets AP
    join @ttIneligiblePallets IP on (IP.PalletId = AP.PalletId);

  /*------------------------------------------------------------------------*/
  /* Return all remaining potential Pallets for allocation */
  /*------------------------------------------------------------------------*/
  select PalletId, Pallet, min(MinLPNId) from @ttAllocablePallets group by PalletId, Pallet;

  if (charindex('D', @Debug) > 0) select 'FindAllocablePallets: Potential Pallets' Message, * from @ttAllocablePallets order by RecordId;

  /*------------------------------------------------------------------------*/
  /* Activity Log */
  if (charindex('L' /* Log */, @Debug) > 0)
    begin
      /* Potential allocable pallets */
      select @vxmlData = (select * from @ttAllocablePallets for XML raw('AllocablePallets'), elements );
      exec pr_ActivityLog_AddMessage 'Allocation_FindAllocablePallets_output', null, null, 'AllocablePallets',
                                     'output' /* Message */, @@ProcId, @vxmlData;
    end

end /* pr_Allocation_FindAllocablePallets */

Go
