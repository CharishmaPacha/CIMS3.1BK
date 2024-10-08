/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/03  VS      Initial version (CID-327)
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
/* Rules for : Describe the RuleSet Type here */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Task_UpdatePriority';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'Task_UpdatePriority',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Task Priority value',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update Task priority with the highest priority of the Orders on the task */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Task Priority value with highest OH.Priority',
       @vRuleQuery       = 'Update Tasks
                            set Priority = SQ.HighPriority
                            from Tasks T join (select TD.TaskId TaskId, Min(OH.Priority) HighPriority 
                                               from TaskDetails TD
                                                 join OrderHeaders OH on OH.OrderId = TD.OrderId
                                               where (TD.WaveId = ~WaveId~) and (TD.Status <>''X'')
                                               group by TD.TaskId) SQ on T.TaskId = SQ.TaskId
                            where T.WaveId = ~WaveId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
