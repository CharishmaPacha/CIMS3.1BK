/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/06  AY      fn_Allocation_GetAllocationRules, pr_Allocation_FindAllocableLPN, pr_Allocation_FindAllocableLPNs:
                        Changed to use LocationSubType and UDFs in Allocation Rules to
                        have option to allcoate from Dynamic picklanes before static picklanes (HPI-2119)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Allocation_GetAllocationRules') is not null
  drop Function fn_Allocation_GetAllocationRules;
Go
/*------------------------------------------------------------------------------
  Proc fn_Allocation_GetAllocationRules:  This Function will returns the
    Allocationrules.
------------------------------------------------------------------------------*/
Create Function fn_Allocation_GetAllocationRules
  (@WaveType      TTypeCode,
   @SearchSet     TLookUpCode,
   @Warehouse     TWarehouse,
   @BusinessUnit  TBusinessUnit )
returns
  /* temp table to return data - this should be in sync with TAllocationRulesTable */
  @AllocationRules      table
    (RuleId               TRecordId,
     SearchOrder          TInteger,
     SearchSet            TLookUpCode,
     SearchType           TLookUpCode,
     WaveType             TTypeCode,
     SKUABCClass          TFlag,
     ReplenishClass       TCategory,
     RuleGroup            TDescription,
     LocationType         TLocationType,
     LocationSubType      TLocationSubType,
     StorageType          TTypeCode,
     OrderType            TTypeCode,
     PickingClass         TCategory,
     PickingZone          TLookUpCode,
     PutawayClass         TPutawayClass,
     QuantityCondition    TDescription,
     OrderByField         TDescription,
     OrderByType          TDescription,
     Status               TFlag,
     AR_UDF1              TUDF,
     AR_UDF2              TUDF,
     AR_UDF3              TUDF,
     AR_UDF4              TUDF,
     AR_UDF5              TUDF
    )
as
begin
  /* Get all active rules here  */
  insert into @AllocationRules
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

  return;
end /* fn_Allocation_GetAllocationRules */

Go
