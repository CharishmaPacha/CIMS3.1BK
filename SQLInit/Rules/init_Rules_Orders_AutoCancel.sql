/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/24  VS      Initial version (CID-1400)
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
/* Rules to build dataset for Invalid Orders */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Orders_AutoCancel';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'Orders_AutoCancel_InvalidOrders',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Auto cancel orders which are invalid',
       @vStatus             = 'I', /* InActive */
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to get dataset for Invalid Carrier Type Orders */
select @vRuleCondition   = '~Operation~ = ''CancelInvalidOrders''',
       @vRuleDescription = 'AutoCancelOrder: Orders with invalid Carrier',
       @vRuleQuery       = 'insert into #OrdersToCancel(OrderId, PickTicket, ReasonCode)
                              select OrderId, PickTicket, 903
                              from vwOrderHeaders
                              where (Status = ''N'' /* new */) and (Carrier = ''Invalid'') and
                                    (OrderType = ''C'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to get dataset for unequal HostNumLines and NumLines Orders */
select @vRuleCondition   = '~Operation~ <> ''CancelInvalidOrders''',
       @vRuleDescription = 'AutoCancelOrder: Cancel incomplete orders i.e. all lines not downloaded',
       @vRuleQuery       = 'insert into #OrdersToCancel(OrderId, PickTicket, ReasonCode)
                              select OrderId, PickTicket, 900
                              from OrderHeaders
                              where (Status = ''O'' /* Downloaded */) and (PreprocessFlag = ''Y'') and
                                    (datediff(Mi /* Minutes */, ModifiedDate, getdate()) > 30) and
                                    (HostNumLines <> NumLines)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
