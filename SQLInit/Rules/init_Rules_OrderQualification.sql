/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/18  VS      Modified the Rules to latest version (BK-475)
  2018/08/17  AY/RV   Added rules to un wave disqualified orders (OB2-553)
  2016/05/18  TK      Initial version
------------------------------------------------------------------------------*/

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
/* Rules required for OrderQualification */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OrderQualification';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Default set of rules that are applicable for most Orders */
/******************************************************************************/
select @vRuleSetName        = 'OrderQualifiedToProcess',
       @vRuleSetDescription = 'Rules to determine if Order is Qualified for Waving or not',
       @vRuleSetFilter      = '~Operation~ = ''OrderQualifiedToProcess''',
       @vSortSeq            = 100,
       @vStatus             = 'NA' /* Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Other than Ship complete Orders */
select @vRuleCondition   = null,
       @vRuleDescription = 'Disqualify Order if nothing is allocated',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''N''
                            where UnitsAssigned = 0' /* Disqualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ship complete Orders that are past due */
select @vRuleCondition   = null, -- '~ShipComplete~ = ''Y'''   -- ShipComplete is now Percentage
       @vRuleDescription = 'Ship Complete Order that is past due qualifies regardless of Fulfill percent',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''N''
                            where cast(~ShipCompletePercent~ as integer) > 0 and
                                  datediff(d, OrderDate, current_timestamp) > ~ShipCompleteThreshold~' /* Qualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ship complete Orders */
select @vRuleCondition   = null, -- '~ShipComplete~ = ''Y'''   -- ShipComplete is now Percentage
       @vRuleDescription = 'Ship Complete Order with ship complete percentage is less than Order Allocation Percentage ',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''N''
                            where cast(FillRatePercent as integer) < cast(ShipCompletePercent as integer)' /* Disqualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ship complete Orders */
select @vRuleCondition   = null, -- '~ShipComplete~ = ''Y'''   -- ShipComplete is now Percentage,
       @vRuleDescription = 'Ship Complete Order with ship complete percentage is greated than or equal to Order Allocation Percentage ',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''Y''
                            where cast(FillRatePercent as integer) >= cast(ShipCompletePercent as integer)' /* Qualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Other than Ship complete Orders */
select @vRuleCondition   = null, -- '~ShipComplete~ = ''Y'''   -- ShipComplete is now Percentage,
       @vRuleDescription = 'Other that Ship Complete order with no units allocated',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''N''
                            where cast(FillRatePercent as integer) = 0' /* Disqualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set : Evaluate if the orders are qualified to remain on Wave after allocation */
/******************************************************************************/
select @vRuleSetName        = 'OrderQualifiedToRemainOnWave',
       @vRuleSetDescription = 'Orders which have some units allocated can remain on Wave',
       @vRuleSetFilter      = '~Operation~ = ''UnWaveDisQualifiedOrders''',
       @vSortSeq            = 200,
       @vStatus             = 'I' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Unwave order if no units allocated */
select @vRuleCondition   = null,
       @vRuleDescription = 'UnWave order if nothing is allocated',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''N''
                            where UnitsAssigned = 0' /* Disqualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: UnWave order if not filled at least to be shipped */
select @vRuleCondition   = null,
       @vRuleDescription = 'UnWave if FillRate is less than ShipComplete percent',
       @vRuleQuery       = 'Update #OrdersToEvaluate
                            set IsOrderQualified = ''N''
                            where cast(FillRatePercent as integer) < cast(ShipCompletePercent as integer)' /* Qualified */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
