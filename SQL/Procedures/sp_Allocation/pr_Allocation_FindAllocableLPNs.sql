/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/27  AY      pr_Allocation_FindAllocableLPNs: Only consider active Allocation Rules
  2018/11/06  AY      fn_Allocation_GetAllocationRules, pr_Allocation_FindAllocableLPN, pr_Allocation_FindAllocableLPNs:
  pr_Allocation_FindAllocableLPNs: removed HPI specific code
  pr_Picking_FindAllocableLPNs => pr_Allocation_FindAllocableLPNs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_FindAllocableLPNs') is not null
  drop Procedure pr_Allocation_FindAllocableLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_FindAllocableLPNs:

  This procedure will all the allocable inventory based on the allocation rules.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_FindAllocableLPNs
  (@SKUId             TRecordId,
   @Warehouse         TWarehouse,
   @WaveType          TTypecode,
   @SearchSet         TDescription  = null,
   @SearchType        TTypeCode     = null,
   @RuleAllocateGroup TDescription  = null,
   @Ownership         TOwnership    = null,
   @Lot               TLot          = null,
   @WaveId            TRecordId     = null)
as
  declare @vWavePickZone TZoneId;
begin /* pr_Allocation_FindAllocableLPNs */

  /* gather wave info */
  select @vWavePickZone = PickZone
  from PickBatches
  where (RecordId = @WaveId);

  /* Insert all the available inventory for the SKU into temp Table */
  select distinct LOI.PickingZone, LOI.Location, LOI.LocationType, LOI.LocationSubType, LOI.StorageType, LOI.PickPath,
                  LOI.LPNId, LOI.LPN, LOI.LPNDetailId, LOI.NumLines,
                  LOI.OnhandStatus, LOI.SKUId, LOI.SKU, LOI.ABCClass, LOI.ReplenishClass, LOI.AllocableInnerPacks, LOI.AllocableQuantity, LOI.TotalQuantity, UnitsPerPackage,
                  datediff(d, getdate(), LOI.ExpiryDate) ExpiresInDays, datepart(month, LOI.ExpiryDate) ExpiryMonth,
                  LOI.ExpiryDate,
                  Case
                    when LOI.Locationtype = 'K' and LOI.Storagetype = 'P' then 120
                    when LOI.Locationtype = 'K' and LOI.StorageType = 'U'  then 999
                    when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 30  then 30
                    when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 60  then 60
                    when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 90  then 90
                    when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 120 then 120
                    when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 180 then 180
                    when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 360 then 360
                    else datediff(d, getdate(), LOI.ExpiryDate)
                  end ExpiryWindow,
                  'N' /* no */ ProcessFlag, LOI.PickingClass,
                  LOI_UDF1, LOI_UDF2, LOI_UDF3, LOI_UDF4, LOI_UDF5
   from vwLPNOnhandInventory LOI
     join AllocationRules AR on (LOI.Warehouse = AR.Warehouse) and
                                (AR.LocationType    is null or AR.LocationType    = LOI.LocationType   ) and
                                (AR.LocationSubType is null or AR.LocationSubType = LOI.LocationSubtype) and
                                (AR.Storagetype     is null or AR.StorageType     = LOI.StorageType    ) and
                                (AR.PickingClass    is null or AR.PickingClass    = LOI.PickingClass   ) and
                                (AR.UDF1            is null or AR.UDF1            = LOI.LOI_UDF1       ) and
                                (AR.UDF2            is null or AR.UDF2            = LOI.LOI_UDF2       ) and
                                (AR.UDF3            is null or AR.UDF3            = LOI.LOI_UDF3       )
   where (AR.SearchSet  = coalesce(@SearchSet,  AR.SearchSet )) and
         (AR.SearchType = coalesce(@SearchType, AR.SearchType)) and
         (AR.WaveType   = coalesce(@WaveType,   AR.WaveType  )) and
         (AR.Warehouse  = coalesce(@Warehouse,  AR.Warehouse )) and
         (AR.Status     = 'A' /* Active */                    ) and
         (LOI.SKUId     = @SKUId                              ) and
         (LOI.Warehouse = @Warehouse                          ) and
         (LOI.PickingClass is not null                        ) and
         (LOI.Ownership = coalesce(@Ownership, LOI.Ownership) ) and
         (coalesce(LOI.Lot, '') = coalesce(@Lot, LOI.Lot, '') ) and
         (LOI.AllocableQuantity > 0);  -- Consider Details which has Allocable quantity against it

   /* Note: If LPNPickingClass is null, then we wouldn't know if it is a full or partial or open case
      and therefore we may create the wrong type of task. To prevent this, we are not allocating when
      PickingClass is null */
end /* pr_Allocation_FindAllocableLPNs */

Go
