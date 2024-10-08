/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/04  SK      Modified Rule for Replenish case pick to accommodate unit pick (HA-1398)
  2020/08/28  AJM     Rule for LPN Picking (Migrated from OB) (HA-1321)
  2020/05/15  TK      Migrated from CID (HA-543)
  2019/06/07  VS      Changed customer order rule to accept the Partial picked Tasks (CID-519)
  2018/04/26  TK      Added rule for Confirm Task Picks (S2G-732)
  2018/04/18  TK      Added rules for Case Picks from Reserve/Bulk (S2G-CRP)
  2018/03/29  TD/RV   Added rule to Customer order case and unit picks (S2G-519)
  2018/02/10  TD      Initial version (S2G-218)
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
/* Picking: Get the Task Pick Group  */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Task_GetValidTaskPickGroup';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Task Pick Group for Replenish Picking */
/******************************************************************************/
select @vRuleSetName        = 'TaskPickGroup_ReplenishWave',
       @vRuleSetFilter      = '~Operation~ = ''Replenishment''',
       @vRuleSetDescription = 'Get the Task Pick Group for Replenishment',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type Replenishment and picktype is LPNPick */
select @vRuleCondition   = '~PickGroup~ = ''RF-R-L''',
       @vRuleDescription = 'For Replenishment LPN picking type it will be RL',
       @vRuleQuery       = 'select ''RL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type Replenishment and pick type is case pick */
select @vRuleCondition   = '~PickGroup~ = ''RF-R-CS''',
       @vRuleDescription = 'For Replenishment case picking type it will be RCS',
       @vRuleQuery       = 'select ''RCS''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type Replenishment and pick type is case/unit pick */
select @vRuleCondition   = '~PickGroup~ = ''RF-R-CSU''',
       @vRuleDescription = 'For Replenishment case/unit picking type it will be RCSU',
       @vRuleQuery       = 'select ''RCSU''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type replenishment - Default rule */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default for Replenishment Order case picking type it will be R',
       @vRuleQuery       = 'select ''R''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Task Pick Group for Customer Order Picking */
/******************************************************************************/
select @vRuleSetName        = 'TaskPickGroup_CustomerOrderPicking',
       @vRuleSetFilter      = '~Operation~ = ''CustomerOrderPicking''',
       @vRuleSetDescription = 'Get the Task Pick Group for Order Picking',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 10;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type customer order and pick type is LPN pick */
select @vRuleCondition   = '~PickGroup~ = ''RF-C-L''',
       @vRuleDescription = 'For Customer Order LPN picking type it will be CL',
       @vRuleQuery       = 'select ''CL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type customer order and pick type is case pick */
select @vRuleCondition   = '~PickGroup~ = ''RF-C-CS''',
       @vRuleDescription = 'For Customer Order case picking type it will be CCS',
       @vRuleQuery       = 'select ''CCS''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type customer order and pick type is unit pick */
select @vRuleCondition   = '~PickGroup~ = ''RF-C-U''',
       @vRuleDescription = 'For Customer Order unit picking type it will be CU',
       @vRuleQuery       = 'select ''CU''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type customer order and pick type is case & unit pick */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PickGroup~ = ''RF-C-CSU''',
       @vRuleDescription = 'For Customer Order case & unit picking type it will be CU',
       @vRuleQuery       = 'select ''CU''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type customer order and pick type Confirm Pick Tasks */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PickGroup~ = ''RF-C-CPT''',
       @vRuleDescription = 'For Customer Order Confirm Task picking, it will be CU',
       @vRuleQuery       = 'select ''CU''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for picking type customer order and pick type is LPN pick */
select @vRuleCondition      = '~PickGroup~ = ''RF-C-L''',
       @vRuleDescription    = 'For Customer Order LPN picking type the pick group will be CL',
       @vRuleQuery          = 'select ''CL''',
       @vStatus             = 'A'/* Active */,
       @vSortSeq           += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default will be C - Customer order */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'By default pick group will be C',
       @vRuleQuery       = 'select ''C''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
