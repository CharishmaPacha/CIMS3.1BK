/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/17  VS      Initial Revision (CIMSV3-1387)
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
/* Rules required to Cancel the Wave */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Task_DeferCancelTask';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to determine if Tasks should be deferred or not */
/******************************************************************************/
select @vRuleSetName        = 'Task_DeferCancelTask',
       @vRuleSetDescription = 'Determine if the Task cancel is to be processsed immediately or in background',
       @vRuleSetFilter      = null,
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Task Cancel: if Task has more than 150 TaskDetails then defer processing to Background */
select @vRuleCondition   = null,
       @vRuleDescription = 'Task Cancel: if Task has more than 150 picks then process in background - defer it',
       @vRuleQuery       = 'update TDC
                            set TDC.ProcessFlag = ''D'' /* Defer */
                            from #TaskDetailsToCancel TDC
                            where (TDC.TDCount >= 150);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
