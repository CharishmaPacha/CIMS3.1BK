/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  AY      Change to get the total inventory required and not for just one ToLPN (HA-2642)
  2020/07/15  TK      Initial Revision (HA-1030)
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
/* Rules to identify inventory to deduct to activate ship cartons */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'ActivateShipCartons_GetInventoryToDeduct';

/******************************************************************************/
/* Rule Set to update defaults on PreProcess */
/******************************************************************************/
select @vRuleSetName        = 'ActivateShipCartons_GetInventoryToDeduct',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Identify inventory to deduct to activate ship cartons',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 10;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* If there is a bulk order then get the inventory that is picked for bulk order to deduct */
select @vRuleCondition   = null,
       @vRuleDescription = 'If there is a bulk order then get the inventory that is picked for bulk order to deduct',
       @vRuleQuery       = 'insert into #FromLPNDetails (LPNId, LPNDetailId, LPNLines, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                                                         ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Ownership, Warehouse, Lot,
                                                         InventoryClass1, InventoryClass2, InventoryClass3)
                              select distinct FLD.LPNId, FLD.LPNDetailId, FL.NumLines, FLD.SKUId, FLD.InnerPacks, FLD.UnitsPerPackage, FLD.Quantity, 0,
                                     FLD.ReceiptId, FLD.ReceiptDetailId, FLD.OrderId, FLD.OrderDetailId, FL.Ownership, FL.DestWarehouse, FLD.Lot,
                                     FL.InventoryClass1, FL.InventoryClass2, FL.InventoryClass3
                              from #SKUsToActivate STA
                                join LPNDetails FLD on (STA.SKUId = FLD.SKUId)
                                join LPNs FL on (FLD.LPNId           = FL.LPNId          ) and
                                                (STA.Ownership       = FL.Ownership      ) and
                                                (STA.DestWarehouse   = FL.DestWarehouse  ) and
                                                (STA.InventoryClass1 = FL.InventoryClass1) and
                                                (STA.InventoryClass2 = FL.InventoryClass2) and
                                                (STA.InventoryClass3 = FL.InventoryClass3)
                                join #BulkOrders BO on (FL.OrderId     = BO.OrderId) and
                                                       (FL.PickBatchId = BO.WaveId)
                              where (FL.LPNType not in (''S'' /* Ship cartons */)) and
                                    (FLD.Quantity > 0)
                              order by FLD.Quantity asc',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Get the inventory that is directly reserved for Wave */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the inventory that is directly reserved for Wave',
       @vRuleQuery       = 'insert into #FromLPNDetails (LPNId, LPNDetailId, LPNLines, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                                                         ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Ownership, Warehouse, Lot,
                                                         InventoryClass1, InventoryClass2, InventoryClass3)
                              select distinct FLD.LPNId, FLD.LPNDetailId, FL.NumLines, FLD.SKUId, FLD.InnerPacks, FLD.UnitsPerPackage, FLD.Quantity, 0,
                                     FLD.ReceiptId, FLD.ReceiptDetailId, FLD.OrderId, FLD.OrderDetailId, FL.Ownership, FL.DestWarehouse, FLD.Lot,
                                     FL.InventoryClass1, FL.InventoryClass2, FL.InventoryClass3
                              from #SKUsToActivate STA
                                join LPNDetails FLD on (STA.SKUId = FLD.SKUId)
                                join LPNs FL on (FLD.LPNId           = FL.LPNId          ) and
                                                (STA.Ownership       = FL.Ownership      ) and
                                                (STA.DestWarehouse   = FL.DestWarehouse  ) and
                                                (STA.InventoryClass1 = FL.InventoryClass1) and
                                                (STA.InventoryClass2 = FL.InventoryClass2) and
                                                (STA.InventoryClass3 = FL.InventoryClass3)
                                join #BulkOrders BO on (FL.OrderId     = BO.OrderId) and
                                                       (FL.PickBatchId = BO.WaveId  )
                              where (FL.PickBatchId = STA.WaveId) and
                                    (FL.LPNType not in (''S'' /* Ship cartons */)) and
                                    (FL.OrderId is null) and  -- Inventory reserved against wave
                                    (FLD.Quantity > 0)
                              order by FLD.Quantity asc',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

Go
