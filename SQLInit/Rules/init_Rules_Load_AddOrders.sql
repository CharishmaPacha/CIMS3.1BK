/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  TK      MultiShipment orders cannot be added to load, they gets added only when LPN or Pallet is loaded (HA-2641)
  2020/11/13  RKC     Initial version (HA-1610)
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
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
/* Rules used for Load Generation process */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Loads_AddOrders';

delete from @RuleSets;
delete from @Rules;

/*******************************************************************************/
/* Rule Set - Updates to be done prior to the Load Generation process */
/*******************************************************************************/
select @vRuleSetName        = 'Loads_AddOrders_Prepare',
       @vRuleSetFilter      = '~Operation~ in (''Loads_AutoBuild'',''UI_Loads_AddOrders'', ''Loads_Generate'')',
       @vRuleSetDescription = 'Rules to update the selected Orders prior to adding them to a Load',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 10;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update the DesiredShip date on the Order Headers; if there is no Wave.ShipDate then use the current date */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Desired Ship date on Orders based on the W.ShipDate',
       @vRuleQuery       = 'Update OH
                            set DesiredShipDate = cast(coalesce(W.ShipDate, current_timestamp) as date)
                            from OrderHeaders OH
                              join #Load_OrdersToAdd LO on (OH.OrderId     = LO.OrderId)
                              join Waves             W  on (OH.PickBatchId = W.RecordId  );',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*******************************************************************************/
/* Rule Set - Validations to be done prior to the Load Generation process */
/*******************************************************************************/
select @vRuleSetName        = 'Loads_AddOrders_Validations',
       @vRuleSetFilter      = '~Operation~ in(''Loads_AutoBuild'',''UI_Loads_AddOrders'',''Loads_Generate'')',
       @vRuleSetDescription = 'Rules to validate or eliminate the orders prior to Load generation',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 20;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Remove orders which are not waved yet */
select @vRuleCondition   = null,
       @vRuleDescription = 'Load Add Orders Validate: Ensure All selected Orders are waved',
       @vRuleQuery       = 'delete LO
                            output ''E'', ''Loads_AddOrders_OrderNotWaved'', OH.PickTicket
                            into #ResultMessages (MessageType, MessageName, Value1)
                            from #Load_OrdersToAdd LO
                              join OrderHeaders OH on (LO.OrderId = OH.OrderId)
                            where (OH.PickBatchId = 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Remove orders which have outstanding picks */
select @vRuleCondition   = null,
       @vRuleDescription = 'Load Add Orders Validate: Ensure the Order is completely picked and there aren''t any outstanding picks',
       @vRuleQuery       = 'delete LO
                            output ''E'', ''Loads_AddOrders_OrderHasOpenpicks'', OH.PickTicket
                            into #ResultMessages (MessageType, MessageName, Value1)
                            from #Load_OrdersToAdd LO
                              join OrderHeaders OH on (LO.OrderId = OH.OrderId)
                              join TaskDetails  TD on (TD.OrderId  = LO.OrderId) and
                                                      (TD.Status not in (''X'' /* Cancelled */, ''C'' /* Completed */))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Remove orders from temp table which do not have the ShipVia */
select @vRuleCondition   = null,
       @vRuleDescription = 'Load Add Orders Validate: Ensure the all orders should haves the valid ShipVia',
       @vRuleQuery       = 'delete LO
                            output ''E'', ''Loads_AddOrders_ShipViaNull'', OH.PickTicket
                            into #ResultMessages (MessageType, MessageName, Value1)
                            from #Load_OrdersToAdd LO
                              join OrderHeaders OH on (LO.OrderId = OH.OrderId)
                            where coalesce(OH.ShipVia, '''') = ''''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* MultiShipment orders cannot be added to load, they get added only when LPN or Pallet is loaded */
select @vRuleCondition   = null,
       @vRuleDescription = 'MultiShipment orders cannot be added to load, they gets added only when LPN or Pallet is loaded',
       @vRuleQuery       = 'delete LO
                            output ''E'', ''Loads_AddOrders_MultiShipmentOrder'', OH.PickTicket
                            into #ResultMessages (MessageType, MessageName, Value1)
                            from #Load_OrdersToAdd LO
                              join OrderHeaders OH on (LO.OrderId = OH.OrderId)
                            where (OH.IsMultiShipmentOrder = ''Y'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
