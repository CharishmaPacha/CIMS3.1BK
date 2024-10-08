/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/21  TK      Changes to insert Ownership & DestWarehouse (BK-73)
  2020/12/16  SK      RuleSet - Populating To LPNs: Include InventoryClass fields to #ToLPNDetails (HA-1789)
  2020/11/27  SK      Remove rule for considering maximum waves to process (HA-1125)
  2020/11/25  SK      Initiate ReservedQty for #FromLPNDetails table (HA-1673)
  2020/11/13  SK      Consider Picked FromLPNs for Auto activation (HA-1673)
  2020/06/24  SK      Initial version (HA-906)
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
        @vRuleSetType         TRuleSetType,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleQueryType       TTypeCode,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/******************************************************************************/
/* Rules for: Auto activation process */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType   = 'AutoActivation';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Popualting Waves list */
/******************************************************************************/
select @vRuleSetName        = 'AutoActivation_Waves',
       @vRuleSetFilter      = '~Operation~ = ''SelectWaves''',
       @vRuleSetDescription = 'Rules for populating waves',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules - Fetch waves to consider for auto-activation */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Fetch Waves to consider for auto activation',
       @vRuleQuery       = 'insert into #Waves (WaveId, WaveNo, WaveType, WaveStatus, Ownership, Warehouse, BusinessUnit)
                              select W.WaveId, W.WaveNo, W.WaveType, W.Status, W.Ownership, W.Warehouse, W.BusinessUnit
                              from Waves W
                              where (W.Archived = ''N'') and /* for performance */
                                    (W.NumOrders > 0) and
                                    (dbo.fn_IsInList(W.Warehouse, ~Warehouse~) > 0) and
                                    (W.BusinessUnit = ~BusinessUnit~) and
                                    (charindex(W.Status, ''ERPK'') > 0); /* Include: ReadyToPick, Picking, Picked */
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Wave types to consider for auto-activation */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Filter specific Wave types',
       @vRuleQuery       = 'delete W
                            from #Waves W
                            where (dbo.fn_IsInList(W.WaveType, ''CP,BCP,PP,BPP'') = 0); /* Bulk Case pick & Bulk Pick Pack */
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*---------------------------------------------------------------------------------------------*/
/* Rules - Eliminate the Wave: When reserved against Bulk Order
   if none of the SKUs associated with the bulk order has been assigned completely
   Logic Below:
    Inner loop checks if there is at least 1 SKU for which units have been assigned completely */
/*---------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Filter waves that do not have any SKU assigned completely',
       @vRuleQuery       = 'delete W
                            from #Waves W
                              left outer join (
                                                select distinct OH.PickBatchId as WaveId
                                                from #Waves IW
                                                  join OrderHeaders OH on IW.WaveId  = OH.PickBatchId
                                                  join OrderDetails OD on OH.OrderId = OD.OrderId
                                                where OH.OrderType = ''B'' /* Bulk Order */
                                                group by OH.PickBatchId, OD.OrderId, OD.SKUId
                                                having (sum(OD.UnitsAuthorizedToShip) > 0) and (sum(OD.UnitsToAllocate) = 0)
                                              ) TT on W.WaveId = TT.WaveId
                            where (TT.WaveId is null);
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Eliminate Waves for which there are no Ship Cartons generated      */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Filter waves based on lpn quantities',
       @vRuleQuery       = 'delete W
                            from #Waves W
                              left outer join (
                                                select distinct IW.WaveId as WaveId
                                                from #Waves IW
                                                  join LPNs L         on IW.WaveId = L.PickBatchId
                                                  join LPNDetails LD  on L.LPNId   = LD.LPNId
                                                where (L.LPNType = ''S'') and /* Ship Carton */
                                                      (L.Status in (''N'', ''F'')) and /* New or New Carton */
                                                      (L.Onhandstatus = ''U'') /* Unavailable */
                                              ) TT on W.WaveId = TT.WaveId
                            where (TT.WaveId is null);
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Update exclusion criteria */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Exclusion criteria',
       @vRuleQuery       = 'Update #Waves
                            set UDF1 = ''ByWave'';
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Populate the final From LPN list from the wave id                  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Populate Initial From LPN List',
       @vRuleQuery       = 'insert into #WaveFromLPNEntities (EntityId)
                              select distinct LPNId
                              from #Waves W
                                join LPNs L on W.WaveId = L.PickBatchId
                              where (L.LPNType not in (''S'',''L'')) and /* Consider Inventory LPNs */
                                    (L.Status = ''K'' /* Picked */);
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Populate the final From LPN list from the wave id                  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Populate Initial To LPN List',
       @vRuleQuery       = 'insert into #WaveToLPNEntities (EntityId)
                              select distinct LPNId
                              from #Waves W
                                join LPNs L on W.WaveId = L.PickBatchId
                              where (L.LPNType = ''S''); /* Consider Ship Cartons */
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Populating From LPNs */
/******************************************************************************/
select @vRuleSetName        = 'AutoActivation_FromLPNs',
       @vRuleSetFilter      = '~Operation~ = ''SelectFromLPNs''',
       @vRuleSetDescription = 'Rules for possible From LPNs list',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules - Fetch From LPNs for auto-activation */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Fetch From LPNs for auto activation',
       @vRuleQuery       = 'insert into #FromLPNDetails (WaveId, LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                                                         ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO, Ownership, Warehouse,
                                                         InventoryClass1, InventoryClass2, InventoryClass3, SortOrder)
                              select L.PickBatchId, LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
                                     LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO, L.Ownership, L.DestWarehouse,
                                     L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, null
                              from #WaveFromLPNEntities TT
                                join LPNs L on TT.EntityId = L.LPNId
                                join LPNDetails LD on L.LPNId  = LD.LPNId
                              where (L.PickBatchId = ~WaveId~) and
                                    (LD.Quantity > 0); /* Inventory available to activate */
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Populating To LPNs */
/******************************************************************************/
select @vRuleSetName        = 'AutoActivation_ToLPNs',
       @vRuleSetFilter      = '~Operation~ = ''SelectToLPNs''',
       @vRuleSetDescription = 'Rules for possible To LPNs list',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules - Fetch To LPNs for auto-activation */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Fetch To LPNs for auto activation',
       @vRuleQuery       = 'insert into #ToLPNDetails (LPNId, LPNDetailId, LPNLines, SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
                                                       InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                                                       ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Ownership, Warehouse,
                                                       WaveId, Lot, CoO, ProcessedFlag)
                              select LD.LPNId, LD.LPNDetailId, L.NumLines, LD.SKUId, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3,
                                     LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
                                     LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId,  L.Ownership, L.DestWarehouse,
                                     L.PickBatchId, LD.Lot, LD.CoO, ''N'' /* No */
                              from #WaveToLPNEntities TT
                                join LPNs L on TT.EntityId = L.LPNId
                                join LPNDetails LD on L.LPNId  = LD.LPNId
                              where (L.PickBatchId = ~WaveId~) and
                                    (L.Status in (''N'', ''F'')) and /* New or New Carton */
                                    (L.OnhandStatus = ''U''); /* Unavailable */
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go