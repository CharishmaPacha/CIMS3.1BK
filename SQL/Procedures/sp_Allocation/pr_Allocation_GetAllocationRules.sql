/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/28  TK      pr_Allocation_GetAllocableLPNs, pr_Allocation_GetAllocationRules, pr_Allocation_PrepareAllocableLPNs &
                        pr_Allocation_GetOrderDetailsToAllocate & pr_Allocation_PrepareToAllocateInventory: Initial Revision
                      pr_Allocation_AllocateInventory: Code revamp - WIP Changes (HA-86)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GetAllocationRules') is not null
  drop Procedure pr_Allocation_GetAllocationRules;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GetAllocationRules returns all allocation rules for
    the given wavetype and search set into temp table.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GetAllocationRules
  (@WaveType             TTypeCode,
   @SearchSet            TLookUpCode,
   @Warehouse            TWarehouse,
   @BusinessUnit         TBusinessUnit,
   @Debug                TFlags     = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Initialize */
  delete from #AllocationRules;

  /* Get all the Active Allocation rules here */
  insert into #AllocationRules (RuleId, SearchOrder, SearchSet, SearchType, WaveType, SKUABCClass, ReplenishClass, RuleGroup,
                                LocationType, LocationSubType, StorageType, OrderType, PickingClass, PickingZone, PutawayClass, QuantityCondition,
                                OrderByField, OrderByType, Status, AR_UDF1, AR_UDF2, AR_UDF3, AR_UDF4, AR_UDF5)
    select RecordId as RuleId, SearchOrder, SearchSet, SearchType, WaveType, SKUABCClass, ReplenishClass, RuleGroup,
           LocationType, LocationSubType, StorageType, OrderType, PickingClass, PickingZone, PutawayClass, QuantityCondition,
           OrderByField, OrderByType, Status, AR_UDF1, AR_UDF2, AR_UDF3, AR_UDF4, AR_UDF5
    from vwAllocationRules
    where (WaveType     = @WaveType       ) and
          (BusinessUnit = @BusinessUnit   ) and
          (Warehouse    = @Warehouse      ) and
          (SearchSet    = @SearchSet      ) and
          (Status       = 'A' /* Active */)
    order by RuleGroup, SearchOrder;

  if (charindex('D' /* Display */, @Debug) > 0) select 'Allocate Inv: Rules', * from #AllocationRules order by RecordId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GetAllocationRules */

Go
