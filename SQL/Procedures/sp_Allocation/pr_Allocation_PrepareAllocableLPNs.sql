/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/05  TK      pr_Allocation_PrepareAllocableLPNs: Changes to sort allocable LPNs correctly (HA-814)
  2020/04/28  TK      pr_Allocation_GetAllocableLPNs, pr_Allocation_GetAllocationRules, pr_Allocation_PrepareAllocableLPNs &
                      pr_Allocation_GetOrderDetailsToAllocate & pr_Allocation_PrepareToAllocateInventory: Initial Revision
                      pr_Allocation_AllocateInventory: Code revamp - WIP Changes (HA-86)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_PrepareAllocableLPNs') is not null
  drop Procedure pr_Allocation_PrepareAllocableLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_PrepareAllocableLPNs: For each SKU, after the Allocable LPNs
    are retrieved as we proceed each Allocation Rule group, we need to select
    the applicable LPNs within the list of all allocable LPNs for this particular
    Allocation Rule Group and update the SortOrder so we can allocate the LPN
    is that order.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_PrepareAllocableLPNs
  (@WaveId                TRecordId,
   @AllocationRuleGroup   TDescription,
   @KeyValue              TDescription,
   @Operation             TOperation,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @Debug                 TFlags   =  null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Update SortOrder and ProcessFlag on the Allocable LPNs */
  /* SortOrder: this will be used to allocate the LPNs in the order as defined in allocation
     ProcessFlag: N - Need to process the LPNs that matches the criteria defined in allocation rules
                  X - Don't need to be processed, when there are no LPNs that matches the criteria defined in allocation rules */
  ;with ALSortOrder as
  (
   select AL.RecordId,
          row_number() over (order by case when coalesce(AR.OrderByField, '') = 'ExpiryDate'   then AL.ExpiryWindow end,
                                      case when coalesce(AR.OrderByField, '') = 'AllocableQty' then AL.AllocableQuantity end,
                                      case when coalesce(AR.OrderByField, '') = 'FIFO'         then AL.LPNId end,
                                      case when coalesce(AR.OrderByField, '') = 'LIFO'         then AL.LPNId end desc,
                                      AR.SearchOrder, AL.PickPath,
                                      case when coalesce(AR.OrderByField, '') = ''             then AL.LPNId end) as SortSeq
   from #AllocableLPNs AL
     join #AllocationRules AR on (coalesce(AL.LocationType,   '') = coalesce(AR.LocationType,      AL.LocationType,     '')) and
                                 (coalesce(AL.LocationSubType,'') = coalesce(AR.LocationSubType,   AL.LocationSubType,  '')) and
                                 (coalesce(AL.StorageType,    '') = coalesce(AR.StorageType,       AL.StorageType,      '')) and
                                 (coalesce(AL.PickingClass,   '') = coalesce(AR.PickingClass,      AL.PickingClass,     '')) and
                                 (coalesce(AL.ReplenishClass, '') = coalesce(AR.ReplenishClass,    AL.ReplenishClass,   '')) and
                                 (coalesce(AL.PickZone,       '') = coalesce(AR.PickingZone,       AL.PickZone,         '')) and
                                 (coalesce(AL.AL_UDF1,        '') = coalesce(AR.AR_UDF1,           AL.AL_UDF1,          '')) and
                                 (coalesce(AL.AL_UDF2,        '') = coalesce(AR.AR_UDF2,           AL.AL_UDF2,          '')) and
                                 (coalesce(AL.AL_UDF3,        '') = coalesce(AR.AR_UDF3,           AL.AL_UDF3,          ''))
   where (AR.RuleGroup = @AllocationRuleGroup) and
         (AL.KeyValue  = @KeyValue) and
         (AL.AllocableQuantity > 0)
  )
  update AL
  set SortSeq     = SO.SortSeq,
      ProcessFlag = case when (SO.RecordId is null) then 'X' else 'N' end /* N - Need to be processed, X - Don't need to be processed */
  from #AllocableLPNs AL
    left outer join ALSortOrder SO on (AL.RecordId = SO.RecordId);

  if (charindex('D' /* Display */, @Debug) > 0) select 'Prep Allocable LPNs' as AllocableLPNs, * from #AllocableLPNs order by SortSeq;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_PrepareAllocableLPNs */

Go
