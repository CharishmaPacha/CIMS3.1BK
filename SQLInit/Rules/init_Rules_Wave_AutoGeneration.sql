/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/02  VS      Initial version (CID-804)
  2018/11/20  AY      Initial version (OB2-745)
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
/* Rules for : Selecting Orders for Auto Waving */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Wave_AutoGeneration';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'WaveAutoGen_SingleLine',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Auto generate Single Line Waves',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule select Single line orders to auto wave */
select @vRuleCondition   = null,
       @vRuleDescription = 'select the Single Line Orders to auto wave',
       @vRuleQuery       = 'insert into #RuleResultDataSet (EntityId, EntityKey, EntityType, UDF1)
                            select OrderDetailId, PickTicket + HostOrderLine + SKU, ''OD'', ''Y''
                            from vwOrderDetailsToBatch OD
                            where (OD.BusinessUnit = ~BusinessUnit~) and
                                  (OD.OrderType not in (''R'', ''RU'', ''RP''/* Replenish Orders */)) and
                                  (charindex(coalesce(WaveFlag, ''''), ''UMR'' /* Unwaved, Manual, Removed */) = 0) and
                                  (OrderCategory1 = ''Single Line'')',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - select orders for auto wave generation */
/******************************************************************************/
select @vRuleSetName        = 'Wave_AutoGeneration',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to generate waves automatically',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule select Single line orders to auto wave */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Priority 1 orders',
       @vRuleQuery       = 'insert into #RuleResultDataSet (EntityId, EntityKey, EntityType, UDF1)
                              select distinct OrderId, PickTicket, ''OH'', ''Y''
                              from vwOrdersToBatch OH
                              where (OH.BusinessUnit = ~BusinessUnit~) and
                                    (OH.OrderType not in (''R'', ''RU'', ''RP''/* Replenish Orders */)) and
                                    (charindex(coalesce(WaveFlag, ''''), ''UMR'' /* Unwaved, Manual, Removed */) = 0) and
                                    (Priority = 1)',
       @vRuleQueryType   = 'DataSet',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
