/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/15  SDC     Resolve duplicate RuleDescription issues (CID-387)
  2018/04/03  TK      Changes to print PTL wave packing list (S2G-535)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/12/28  TK      Initial version
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
/* Rules for : Task_GenerateLabels */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Task_GenerateLabels';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Replenish Waves - No labels are needed */
/******************************************************************************/
select @vRuleSetName        = 'TaskCreation_ReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Task Creation Replenish Waves',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Generic */
select @vRuleCondition   = null,
       @vRuleDescription = 'Do not need to generate labels for Replenish Wave',
       @vRuleQuery       = 'select ''NR''' /* Not Required */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - All other waves  - only Unit Picks need temp labels to be generated */
/******************************************************************************/
select @vRuleSetName        = 'TaskCreation_PickAndPackWaves',
       @vRuleSetFilter      = '~WaveType~ not in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Task Creation Pick & Pack Waves',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 2.1 - Unit Picks */
select @vRuleCondition   = '~PickType~ in (''U'', ''CS'')',
       @vRuleDescription = 'RuleDescription1',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 2.2 - LPN Picks */
select @vRuleCondition   = '~PickType~ = ''L''',
       @vRuleDescription = 'RuleDescription2',
       @vRuleQuery       = 'select ''I''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 2.3 - Pallet Picks */
select @vRuleCondition   = '~PickType~ = ''P''',
       @vRuleDescription = 'RuleDescription3',
       @vRuleQuery       = 'select ''I''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
