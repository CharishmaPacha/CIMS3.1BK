/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/28  TK      pr_Allocation_GetAllocableLPNs, pr_Allocation_GetAllocationRules, pr_Allocation_PrepareAllocableLPNs &
                      pr_Allocation_GetOrderDetailsToAllocate & pr_Allocation_PrepareToAllocateInventory: Initial Revision
                      pr_Allocation_AllocateInventory: Code revamp - WIP Changes (HA-86)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GetAllocableLPNs') is not null
  drop Procedure pr_Allocation_GetAllocableLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GetAllocableLPNs returns all LPNs that can be allocated for given criteria
    i,e. the SKU which needs to be allocated and according to the pre-defined allocation criteria
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GetAllocableLPNs
  (@WaveId           TRecordId,
   @SKURecordId      TRecordId,
   @Warehouse        TWarehouse,
   @Operation        TOperation   = null,
   @BusinessUnit     TBusinessUnit,
   @Debug            TFlags       = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Initialize temp table */
  delete from #AllocableLPNs;

  /* First get all the LPNs that can be allocated as per defined allocation rules into a temp table */
  insert into #AllocableLPNs (LocationId, Location, LocationType, LocationSubType, StorageType, PickZone, PickPath,
                              LPNId, LPN, LPNDetailId, NumLines, OnhandStatus,
                              SKUId, SKU, SKUABCClass, Ownership, PickingClass, ReplenishClass,
                              AllocableInnerPacks, AllocableQuantity, TotalQuantity, UnitsPerPackage, UnitsToAllocate,
                              ExpiryInDays, ExpiryMonth, ExpiryDate, ExpiryWindow,
                              Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                              Warehouse, AL_UDF1, AL_UDF2, AL_UDF3, AL_UDF4, AL_UDF5)
    select distinct LOI.LocationId, LOI.Location, LOI.LocationType, LOI.LocationSubType, LOI.StorageType, LOI.PickingZone, LOI.PickPath,
                    LOI.LPNId, LOI.LPN, LOI.LPNDetailId, LOI.NumLines, LOI.OnhandStatus,
                    LOI.SKUId, LOI.SKU, LOI.ABCClass, LOI.Ownership, LOI.PickingClass, LOI.ReplenishClass,
                    LOI.AllocableInnerPacks, LOI.AllocableQuantity, LOI.TotalQuantity, LOI.UnitsPerPackage, SOD.UnitsToAllocate,
                    datediff(d, getdate(), LOI.ExpiryDate) /* ExpiresInDays */, datepart(month, LOI.ExpiryDate) /* ExpiryMonth */, LOI.ExpiryDate,
                    case
                      when LOI.Locationtype = 'K' and LOI.Storagetype = 'P'   then 120
                      when LOI.Locationtype = 'K' and LOI.StorageType = 'U'   then 999
                      when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 30  then 30
                      when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 60  then 60
                      when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 90  then 90
                      when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 120 then 120
                      when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 180 then 180
                      when datediff(d, getdate(), LOI.ExpiryDate) * 30 <= 360 then 360
                      else datediff(d, getdate(), LOI.ExpiryDate)
                    end /* ExpiryWindow */,
                    LOI.Lot, LOI.InventoryClass1, LOI.InventoryClass2, LOI.InventoryClass3,
                    LOI.Warehouse, LOI_UDF1, LOI_UDF2, LOI_UDF3, LOI_UDF4, LOI_UDF5
     from vwLPNOnhandInventory LOI
       join #SKUOrderDetailsToAllocate SOD on (LOI.SKUId             = SOD.SKUId            ) and
                                              (LOI.Ownership         = SOD.Ownership        ) and
                                              (coalesce(LOI.Lot, '') = coalesce(SOD.Lot, '')) and
                                              (LOI.InventoryClass1   = SOD.InventoryClass1  ) and
                                              (LOI.InventoryClass2   = SOD.InventoryClass2  ) and
                                              (LOI.InventoryClass3   = SOD.InventoryClass3  )
       join #AllocationRules AR on (AR.LocationType    is null or LOI.LocationType    = AR.LocationType   ) and
                                   (AR.LocationSubType is null or LOI.LocationSubType = AR.LocationSubType) and
                                   (AR.Storagetype     is null or LOI.StorageType     = AR.StorageType    ) and
                                   (AR.PickingClass    is null or LOI.PickingClass    = AR.PickingClass   ) and
                                   (AR.ReplenishClass  is null or LOI.ReplenishClass  = AR.ReplenishClass ) and
                                   (AR.PickingZone     is null or LOI.PickingZone     = AR.PickingZone    ) and
                                   (AR.AR_UDF1         is null or LOI.LOI_UDF1        = AR.AR_UDF1        ) and
                                   (AR.AR_UDF2         is null or LOI.LOI_UDF2        = AR.AR_UDF2        ) and
                                   (AR.AR_UDF3         is null or LOI.LOI_UDF3        = AR.AR_UDF3        )
     where (LOI.Warehouse = @Warehouse) and
           (SOD.RecordId  = @SKURecordId) and
           (LOI.PickingClass is not null) and
           (LOI.AllocableQuantity > 0);

  if (charindex('D' /* Display */, @Debug) > 0) select 'Allocable LPNs' as AllocableLPNs, * from #AllocableLPNs order by RecordId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GetAllocableLPNs */

Go
