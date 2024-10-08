/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/19  TK      pr_Setup_AllocationRules: Do not clean up #AllocationRules, caller will take care of it (HA-2631)
  2021/02/12  TK      pr_Setup_AllocationRules: If SearchSet is not passed then use the one from temp table (BK-181)
  2020/06/20  MS      pr_Setup_AllocationRules: Corrections to insert AllocationRules (HA-265)
  2020/01/13  AY      pr_Setup_AllocationRules: New procedure (CIMS-2886)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Setup_AllocationRules') is not null
  drop Procedure pr_Setup_AllocationRules;
Go
/*------------------------------------------------------------------------------
  pr_Setup_AllocationRules: Insert the rules from the #Allocation rules into
    the actual table
------------------------------------------------------------------------------*/
Create Procedure pr_Setup_AllocationRules
  (@WaveType      TTypeCode,
   @SearchSet     TLookUpCode,
   @Warehouses    TWarehouse,
   @Action        TAction,
   @BusinessUnit  TBusinessUnit = null,
   @UserId        TUserId       = null)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName;

  declare @ttWarehouses table (Warehouse    TWarehouse,
                               BusinessUnit TBusinessUnit);
begin /* pr_Setup_AllocationRules */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @UserId       = coalesce(@UserId, 'cimsdba');

  /* Check whether the #AllocationRules exists */
  if (object_id('tempdb..#AllocationRules') is null) return;

  /* Get all valid Warehouses and BusinessUnits */
  insert into @ttWarehouses(Warehouse, BusinessUnit)
    select L.LookUpCode, BU.BusinessUnit
    from vwLookups L join vwBusinessUnits BU on L.BusinessUnit = BU.BusinessUnit
    where (L.LookUpCategory = 'Warehouse') and
          ((@Warehouses is null) or (dbo.fn_IsInList(L.LookupCode, @Warehouses) > 0)) and
          (BU.BusinessUnit = coalesce(@BusinessUnit, BU.BusinessUnit));

  /* Delete existing records, if user so desires
     Operation column always getting null, if in future we set to the Operation column value then we have to consider */
  if (charindex('D', @Action) > 0)
    delete AR from AllocationRules AR
      inner join #AllocationRules TAR on (AR.WaveType     = @WaveType   ) and
                                         (AR.SearchSet    = coalesce(TAR.SearchSet, @SearchSet)) and
                                         (AR.RuleGroup    = TAR.RuleGroup  ) and
                                         (AR.SearchOrder  = TAR.SearchOrder)
            join @ttWarehouses W on      (AR.Warehouse    = W.Warehouse    ) and
                                         (AR.BusinessUnit = W.BusinessUnit );

  /* Insert data into AllocationRules table from temptable */
  if (charindex('I', @Action) > 0)
    insert into AllocationRules (SearchOrder, RuleGroup, LocationType, StorageType, OrderType, PickingZone,PickingClass,
                                 SearchType, QuantityCondition, SKUABCClass, OrderByField, OrderByType, Status, SearchSet,
                                 WaveType, Warehouse, BusinessUnit)
      select SearchOrder, RuleGroup, LocationType, StorageType, OrderType, PickingZone,PickingClass,
             SearchType, QuantityCondition, SKUABCClass, OrderByField, OrderByType, Status, coalesce(SearchSet, @SearchSet),
             @WaveType, W.Warehouse, W.BusinessUnit
      from #AllocationRules TAR, @ttWarehouses W;

  /* If the records already exist in the table, Update them */
  if (charindex('U', @Action) > 0)
    update AR
    set RuleGroup           = TAR.RuleGroup,
        SearchOrder         = TAR.SearchOrder,
        LocationType        = TAR.LocationType,
        StorageType         = TAR.StorageType,
        OrderType           = TAR.OrderType,
        PickingZone         = TAR.PickingZone,
        PickingClass        = TAR.PickingClass,
        SearchType          = TAR.SearchType,
        QuantityCondition   = TAR.QuantityCondition,
        SKUABCClass         = TAR.SKUABCClass,
        OrderByField        = TAR.OrderByField,
        OrderByType         = TAR.OrderByType,
        Status              = TAR.Status
    from AllocationRules AR
      join #AllocationRules TAR on (AR.WaveType     = @WaveType      ) and
                                   (AR.SearchSet    = coalesce(TAR.SearchSet, @SearchSet)) and
                                   (AR.RuleGroup    = TAR.RuleGroup  ) and
                                   (AR.SearchOrder  = TAR.SearchOrder)
      join @ttWarehouses W on      (AR.Warehouse    = W.Warehouse    ) and
                                   (AR.BusinessUnit = W.BusinessUnit );

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_Setup_AllocationRules */

Go
