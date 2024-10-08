/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/17  OK      Changes to insert Orders into EntitiesToPrint for PTS wave to allow printing LPN PL's (BK-762)
  2021/10/14  AY      Changed the finalization rules to be separate so that they can be executed by themselves (OB2-2081)
  2021/08/26  RT      Included BPP to print the Task Labels (BK-534)
  2021/04/05  AY      Populate the fields SKUSortOrder, Account (HA-2538)
  2021/03/09  MS      Changes to update SortOrder with WaveSeqNo (BK-268)
  2021/02/04  MS      Enable rules for all Operations (BK-150)
  2021/01/22  RBV     PortBack: Nullify the Rule Set filter for rulessetname ShippingDocs (HA-1758).
  2020/12/02  RV      Made changes to get and insert/update the Warehouse with respect to the entity type (HA-1704)
  2020/08/08  RT      Included CustPO and ShipToStore (HA-1193)
  2020/07/13  RV      EntitiesToPrint: Update ShipFrom on Orders and LPNs (HA-1075)
  2020/07/09  RV      Added rule to update IsValidTrackingNo (HA-1123)
  2020/06/22  AY      Changed rules to include Orders of Wave only for non-PTS Waves
                      Fixed issue: For PTS with an Order having multiple cartons - multiple PLs were printing
  2020/06/16  AJ      Print PLs for Orders and Task labels for PTS Waves (HA-910)
  2020/06/15  AY      Print PLs for Orders for Xfer Waves (HA-913)
  2020/06/04  PHK     Changes were made to get the wavetype (HA-597)
  2020/04/03  NB      Initial version (CIMSV3-221)
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
/* Rule Set : Determine entities and details for Printing */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'EntitiesToPrint';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Inserts into EntitiesToPrint for ShippingDocs Operation      */
/******************************************************************************/
select @vRuleSetName        = 'ShippingDocs',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Identify Info and insert into #EntitiesToPrint',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Capture Info for LPNs to print from #ttSelectedEntities, insert into #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'LPN: Capture Info for LPNs to print from #ttSelectedEntities',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey,
                                                           LPNId, LPN, LPNStatus, LPNType,
                                                           PackageSeqNo, PalletId, Ownership,
                                                           OrderId, WaveId, WaveNo, BusinessUnit)
                              select ~Operation~, tt.EntityType, L.LPNId, L.LPN,
                                     L.LPNId, L.LPN, L.LPNStatus, L.LPNType,
                                     L.PackageSeqNo, L.PalletId, L.Ownership,
                                     L.OrderId, L.PickBatchId, L.PickBatchNo, L.BusinessUnit
                              from vwLPNs L
                              join #ttSelectedEntities tt on (L.LPNId = tt.EntityId)
                              where (tt.EntityType = ''LPN'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Pallet */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Rule : Capture Info for Pallets to print from #ttSelectedEntities, insert into #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Pallet: Capture Info for Pallets to print from #ttSelectedEntities',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey,
                                                           PalletId, OrderId, WaveId, WaveNo,
                                                           LoadId, Ownership, Warehouse, BusinessUnit)
                              select ~Operation~, tt.EntityType, P.PalletId, P.Pallet,
                                     P.PalletId, P.OrderId, P.PickBatchId, P.PickBatchNo,
                                     P.LoadId, P.Ownership, P.Warehouse, P.BusinessUnit
                              from Pallets P
                              join #ttSelectedEntities tt on (P.PalletId = tt.EntityId)
                              where (tt.EntityType = ''Pallet'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Capture Info for Pallets to print from #ttSelectedEntities, insert into #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Pallet-LPNs: Capture Info for all LPNs on Pallets from #ttSelectedEntities',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey,
                                                         LPNId, LPN, BusinessUnit)
                              select ~Operation~, ''LPN'', tt.EntityId, tt.EntityKey,
                                     L.LPNId, L.LPN, L.BusinessUnit
                              from LPNs L
                              join #ttSelectedEntities tt on (L.PalletId = tt.EntityId)
                              where (tt.EntityType = ''Pallet'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Order */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Rule: If PT is selected, then add the PT to print docs at PT level = may be
         Packing list, Packing manifest, Commercial Invoice etc.
*/
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PickTicket: When PT is given, add the PT to print the PT relevant docs',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey,
                                                         OrderId, Ownership, BusinessUnit)
                              select ~Operation~, tt.EntityType, OH.OrderId, OH.PickTicket,
                                     OH.OrderId, OH.Ownership, OH.BusinessUnit
                              from OrderHeaders OH
                              join #ttSelectedEntities tt on (OH.OrderId = tt.EntityId)
                              where (tt.EntityType = ''Order'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : When PT is given, add all the LPNs on the order to print their labels and/or PLs  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PickTicket-LPNs: Capture Info for all LPNs on Orders from #ttSelectedEntities',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey,
                                                         LPNId, LPN, BusinessUnit)
                              select ~Operation~, ''LPN'', L.LPNId, L.LPN,
                                     L.LPNId, L.LPN, L.BusinessUnit
                              from LPNs L
                                join #ttSelectedEntities tt on (L.OrderId = tt.EntityId)
                              where (tt.EntityType = ''Order'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Wave */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Rule: When Wave is given, add the Wave */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave: Add Wave Entity',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, WaveId, WaveNo, WaveType,
                                                         SortOrder, BusinessUnit)
                              select ~Operation~, tt.EntityType, W.WaveId, W.WaveNo, W.WaveId, W.WaveNo, W.WaveType,
                                     ''1-'', W.BusinessUnit
                              from Waves W
                                join #ttSelectedEntities tt on (W.WaveId = tt.EntityId)
                              where (tt.EntityType = ''Wave'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: When Wave is given, add all the Orders on Wave */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave-Orders: Add all orders on the selected Waves',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, WaveId, OrderId,
                                                         SortOrder, BusinessUnit)
                              select ~Operation~, ''Order'', OH.OrderId, OH.PickTicket, W.WaveId, OH.OrderId,
                                     ''2-'', OH.BusinessUnit
                              from Waves W
                                join #ttSelectedEntities tt on (W.WaveId = tt.EntityId)
                                join OrderHeaders OH on (OH.PickbatchId = W.RecordId) and (OH.OrderType <> ''B'')
                              where (tt.EntityType = ''Wave'') and
                                    (OH.Status not in (''X''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: When PTS Wave is given, add all the Tasks when printing from Shipping Docs */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave-Tasks: Add all Tasks on the selected Waves to print header labels',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, WaveId, OrderId,
                                                         SortOrder, BusinessUnit)
                              select ~Operation~, ''Task'', T.TaskId, T.TaskId, W.WaveId, T.OrderId,
                                     ''3-'', W.BusinessUnit
                              from Waves W
                                join #ttSelectedEntities tt on (W.WaveId = tt.EntityId)
                                join Tasks T on (T.WaveId = W.RecordId)
                              where (tt.EntityType = ''Wave'') and
                                    (W.WaveType  in (''PTS'', ''BPP'')) and
                                    (T.Status not in (''X''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Not applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : When Wave is given, add all Shipping LPNs on the Wave  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave-LPNs: Add all shipping LPNs on the selected Waves',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey,
                                                         LPNId, WaveId, SortOrder, BusinessUnit)
                              select ~Operation~, ''LPN'', L.LPNId, L.LPN,
                                     L.LPNId, W.RecordId, ''4-'', L.BusinessUnit
                              from Waves W
                                join #ttSelectedEntities tt on (W.WaveId = tt.EntityId)
                                join LPNs L on (L.PickbatchId = W.RecordId)
                              where (tt.EntityType = ''Wave'') and
                                    (W.WaveType in (''PTS'', ''BCP'', ''BPP'')) and
                                    (L.LPNType = ''S'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Task */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Rule: When Task is given, add the Task always. For PTS, print PLs & SPL as well */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Task: Add Task Entity',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, WaveId, WaveNo, WaveType,
                                                         SortOrder, BusinessUnit)
                              select ~Operation~, tt.EntityType, T.TaskId, T.TaskId, W.WaveId, W.WaveNo, W.WaveType,
                                     ''1-'', T.BusinessUnit
                              from Tasks T
                                join #ttSelectedEntities tt on (tt.EntityId = T.TaskId)
                                join Waves W on (W.WaveId = T.WaveId)
                              where (tt.EntityType = ''Task'') and (T.Status not in (''X''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: For PTS tasks, add each Order */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PTS Task-Orders: Add all orders on the selected Tasks',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, WaveId, OrderId,
                                                         SortOrder, BusinessUnit)
                              select ~Operation~, ''Order'', OH.OrderId, OH.PickTicket, W.WaveId, OH.OrderId,
                                     ''2-'' + min(TD.PickPosition), OH.BusinessUnit
                              from TaskDetails TD
                                join Tasks T on (T.TaskId = TD.TaskId)
                                join #ttSelectedEntities tt on (tt.EntityId = TD.TaskId)
                                join Waves W on (W.WaveId = T.WaveId)
                                join OrderHeaders OH on (OH.OrderId = TD.OrderId)
                              where (tt.EntityType = ''Task'') and (W.WaveType in (''PTS''))
                              group by OH.OrderId, OH.PickTicket, W.WaveId, OH.BusinessUnit',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : For PTS Tasks, add each LPN  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PTS Task-Templabels: Add all LPNs on the selected Tasks',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, WaveId, OrderId, LPNId,
                                                         SortOrder, BusinessUnit)
                              select distinct ~Operation~, ''LPN'', TD.TempLabelId, TD.TempLabel, W.WaveId, TD.OrderId, TD.TempLabelId,
                                              ''3-'' + TD.PickPosition, T.BusinessUnit
                              from TaskDetails TD
                                join Tasks T on (T.TaskId = TD.TaskId)
                                join #ttSelectedEntities tt on (tt.EntityId = TD.TaskId)
                                join Waves W on (W.WaveId = T.WaveId)
                              where (tt.EntityType = ''Task'') and (W.WaveType in (''PTS''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Load */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Rule 6: Capture Info for Loads to print from #ttSelectedEntities, insert into #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Capture Info for Loads to print from #ttSelectedEntities, insert into #ttEntitiesToPrint',
       @vRuleQuery       = 'insert into #EntitiesToPrint(Operation, EntityType, EntityId, EntityKey, LoadId, Warehouse, BusinessUnit)
                              select ~Operation~, tt.EntityType, L.LoadId, L.LoadNumber,  L.LoadId, L.FromWarehouse, L.BusinessUnit
                              from Loads L
                              join #ttSelectedEntities tt on (L.LoadId = tt.EntityId)
                              where (tt.EntityType = ''Load'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Determine entities and details for Printing */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'EntitiesToPrint_Finalize';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Update all info of the Entity to Print */
/******************************************************************************/
select @vRuleSetName        = 'EntitiesToPrint_Finalize',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Complete the #EntitiesToPrint with all relevant fields',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: initialize the Id fields  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'ETP: Initialize Id fields',
       @vRuleQuery       = 'Update tt
                            set LPNId   = case when EntityType = ''LPN''   then EntityId end,
                                OrderId = case when EntityType = ''Order'' then EntityId end,
                                WaveId  = case when EntityType = ''Wave''  then EntityId end
                            from #EntitiesToPrint tt',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update Info for LPNs in #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'LPN Info: Update LPN info for all records',
       @vRuleQuery       = 'Update tt
                            set LPN             = L.LPN,
                                LPNType         = L.LPNType,
                                LPNStatus       = L.Status,
                                PackageSeqNo    = L.PackageSeqNo,
                                SKUSortOrder    = coalesce(S.SKUSortOrder, S.SKU1 + S.SKU2 + S.SKU3),
                                PalletId        = coalesce(tt.PalletId,    L.PalletId),
                                OrderId         = coalesce(tt.OrderId,     L.OrderId),
                                WaveId          = coalesce(tt.WaveId,      L.PickBatchId),
                                Ownership       = coalesce(tt.Ownership,   L.Ownership),
                                Warehouse       = coalesce(tt.Warehouse,   L.DestWarehouse)
                            from #EntitiesToPrint tt
                              join LPNs L on (tt.LPNId = L.LPNId)
                              left outer join SKUs S on (S.SKUId = L.SKUId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update Info for PickTickets in #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PickTicket Info: Update PickTicket info for all records',
       @vRuleQuery       = 'Update tt
                            set PickTicket      = OH.PickTicket,
                                CustPO          = OH.CustPO,
                                Account         = OH.Account,
                                AccountName     = OH.AccountName,
                                SoldToId        = OH.SoldToId,
                                ShipToId        = OH.ShipToId,
                                ShipToStore     = OH.ShipToStore,
                                WaveId          = coalesce(tt.WaveId, OH.PickBatchId),
                                OrderType       = OH.OrderType,
                                OrderStatus     = OH.Status,
                                LPNsAssigned    = OH.LPNsAssigned,
                                OrderCategory1  = OH.OrderCategory1,
                                OrderCategory2  = OH.OrderCategory2,
                                OrderCategory3  = OH.OrderCategory3,
                                OrderCategory4  = OH.OrderCategory4,
                                OrderCategory5  = OH.OrderCategory5,
                                WaveSeqNo       = OH.WaveSeqNo,
                                Ownership       = OH.Ownership,
                                ShipFrom        = OH.ShipFrom,
                                Warehouse       = OH.Warehouse,
                                ShipVia         = OH.ShipVia,
                                SourceSystem    = OH.SourceSystem
                            from #EntitiesToPrint tt
                            join OrderHeaders OH on (tt.OrderId = OH.OrderId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update Info for Waves in #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Info: Update Wave info for all records',
       @vRuleQuery       = 'Update tt
                            set WaveType  = W.WaveType,
                                WaveNo    = W.WaveNo,
                                Warehouse = W.Warehouse,
                                SortOrder = coalesce(tt.SortOrder, W.WaveNo)
                            from #EntitiesToPrint tt
                            join Waves W on (tt.WaveId = W.WaveId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update Info for ShipVia in #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'ShipVia Info: Update Shipvia info for all records',
       @vRuleQuery       = 'Update ETP
                            set Carrier               = SV.Carrier,
                                IsSmallPackageCarrier = SV.IsSmallPackageCarrier
                            from #EntitiesToPrint ETP
                            join vwShipVias SV on (ETP.ShipVia = SV.ShipVia)
                            where (ETP.ShipVia is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update IsValidTrackingNo in #ttEntitiesToPrint  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Small package label info: Update package have valid TrackingNo or not',
       @vRuleQuery       = 'Update ETP
                            set ETP.IsValidTrackingNo = coalesce(SL.IsValidTrackingNo, ''N'')
                            from #EntitiesToPrint ETP
                            left outer join ShipLabels SL on (ETP.EntityId = SL.EntityId) and (ETP.EntityType = ''LPN'') and (SL.Status = ''A'')
                            where (ETP.EntityType = ''LPN'') and (ETP.IsSmallPackageCarrier = ''Y'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: delete invalid entities */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Delete: Cancelled Orders/Tasks, Voided,Consumed LPNs',
       @vRuleQuery       = 'delete from #EntitiesToPrint
                            where (OrderStatus in (''X'')) or
                                  (LPNStatus in (''V'', ''C'')) --or
                                  --(TaskStatus in (''X''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         = 90;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update the sortorder as follows:
   the SortOrder Hierarchy is already set in the rules above. Here we are only
   establishing the order of the entities amongst themselves
   Orders are printed by WaveSeqNo-CustPO-ShipToStore(DC)-PickTicket. These are standard rules,
     most often the changes will be done in client version.
*/
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'SortOrder-Orders: Update the Sortorder for Orders',
       @vRuleQuery       = 'Update ETP
                            set SortOrder += ''-'' + coalesce(dbo.fn_LeftPadNumber(WaveSeqNo, 5), '''') +
                                             ''-'' + coalesce(CustPO, '''') +
                                             ''-'' + coalesce(ShipToStore, '''') +
                                             ''-'' + PickTicket
                            from #EntitiesToPrint ETP
                            where (EntityType = ''Order'')
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         = 100;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'SortOrder-LPNs: Update the Sortorder for LPNs',
       @vRuleQuery       = 'Update #EntitiesToPrint
                            set SortOrder += case when OrderId is not null then ''-'' + coalesce(dbo.fn_LeftPadNumber(WaveSeqNo, 5), CustPO, '''') + ''-'' + PickTicket + ''-''  + LPN
                                                  else LPN
                                             end
                            where (EntityType = ''LPN'')
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update the recordid */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'RecordId: Update the recordid for all records',
       @vRuleQuery       = 'declare @i int = 0;
                            update #EntitiesToPrint
                            set @i = RecordId = @i + 1',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         = 999;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
