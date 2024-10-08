/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/11  TK      Rules to pouplate Inventory to Consume to create kit LPNs (HA-1238)
  2020/06/30  TK      Initial version (HA-830)
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
/* Rules to Get Source Inventory */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType   = 'CreateLPNs_GetSourceInventory';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* For Contractor Warehouses, when new LPNs are created then we need to deduct the same
   quantity of SKU from picklanes, we will not be creating LPNs if there are no
   enough inventory in the picklanes */
/******************************************************************************/
select @vRuleSetName        = 'CreateLPNs_GetSourceInventory',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Create Inventory: Get the source inventory to deduct on creating new inventory',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Create Kits: Get the source inventory to deduct on creating new inventory */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Operation~ = ''Orders_CreateKits''',
       @vRuleDescription = 'Create Kits: Get the source inventory to deduct on creating new inventory',
       @vRuleQuery       = 'insert into #InventoryToConsume (LPNId, LPN, LPNDetailId, SKU, SKUId, OrderId, OrderDetailId, InnerPacks, Quantity, PalletId, LocationId, Location,
                                                             Lot, Ownership, Warehouse, InventoryClass1, InventoryClass2, InventoryClass3)
                              select L.LPNId, L.LPN, LD.LPNDetailId, S.SKU, LD.SKUId, LD.OrderId, LD.OrderDetailId, LD.InnerPacks, LD.Quantity, L.PalletId, L.LocationId, L.Location,
                                     L.Lot, L.Ownership, L.DestWarehouse, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
                              from LPNs L
                                join LPNDetails   LD  on (L.LPNId = LD.LPNId)
                                join OrderDetails OD  on (LD.OrderDetailId = OD.OrderDetailId)
                                join OrderDetails KOD on (OD.ParentHostLineNo = KOD.HostOrderLine)
                                join SKUs         S   on (LD.SKUId = S.SKUId)
                              where (KOD.OrderId = ~OrderId~) and
                                    (KOD.OrderDetailId = ~OrderDetailId~) and
                                    (KOD.LineType = ''A'' /* KitAssembly */) and
                                    (L.Status  = ''K'' /* Picked */)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
