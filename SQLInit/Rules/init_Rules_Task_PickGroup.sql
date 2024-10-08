/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/17  TK      Case picks will be picked using Case/Unit picking menu which allows pick group 'CU' only (BK-213)
  2020/09/04  SK      Modified Rule for Replenish case pick to accommodate unit pick (HA-1398)
  2018/04/03  OK/RV   Added Rule for PTL Waves (S2G-560)
  2018/02/08  TD      Initial version (S2G-218)
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'Task_PickGroup';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare @vRecordId            TRecordId,
          @vRuleSetId           TRecordId,
          @vRuleSetName         TName,
          @vRuleSetDescription  TDescription,
          @vRuleSetFilter       TQuery,

          @vBusinessUnit        TBusinessUnit,

          @vRuleCondition       TQuery,
          @vRuleDescription     TDescription,
          @vRuleQuery           TQuery,

          @vSortSeq             TSortSeq,
          @vStatus              TStatus;

  declare @RuleSets             TRuleSetsTable,
          @Rules                TRulesTable;

/******************************************************************************/
/* Rule Set #1: Get the Task Pick Group   */
/******************************************************************************/
select @vRuleSetName        = 'TaskPickGroup',
       @vRuleSetDescription = 'Get the Task Pick Group',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for  Replenish LPN Pick */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~WaveType~ in (''R'', ''RU'', ''RP'', ''REP'') and ~PickType~ = ''L''',
         @vRuleDescription = 'PickGroup for replenish LPN Pick will be RL',
         @vRuleQuery       = 'select ''RL''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for replenish case/unit pick */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~WaveType~ in (''R'', ''RU'', ''RP'', ''REP'') and ~PickType~ in (''CS'', ''U'')',
         @vRuleDescription = 'PickGroup for replenish case/unit Pick will be RCSU',
         @vRuleQuery       = 'select ''RCSU''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for replenish case pick */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~WaveType~ in (''R'', ''RU'', ''RP'', ''REP'') and ~PickType~ = ''CS''',
         @vRuleDescription = 'PickGroup for replenish case Pick will be RL',
         @vRuleQuery       = 'select ''RCS''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for WSS Waves*/
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~WaveType~ in ('''')',
         @vRuleDescription = 'PickGroup for Automation/ColdFusion/ZoneC Unit Picks will be WSS',
         @vRuleQuery       = 'select ''WSS''',
         @vStatus          = 'NA'/* Non Applicable */,
         @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Confirm Pick Tasks */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~WaveType~ in ('''')',
         @vRuleDescription = 'PickGroup for some waves would be CTP',
         @vRuleQuery       = 'select ''CTP''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for PTL Waves */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTL'', ''PTLC'')',
       @vRuleDescription = 'PickGroup for PTL Waves will be CU',
       @vRuleQuery       = 'select ''CU''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for non automation LPN picks */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~PickType~ = ''L''',
         @vRuleDescription = 'Default PickGroup for LPN Picks will be CL',
         @vRuleQuery       = 'select ''CL''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq         = 96;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for non automation case picks */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~PickType~ = ''CS''',
         @vRuleDescription = 'Default PickGroup for Casepicks will be CCS',
         @vRuleQuery       = 'select ''CU''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq         = 97;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for non automation unit picks */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = '~PickType~ = ''U''',
         @vRuleDescription = 'Default Pick Group for Units Picks will be CU',
         @vRuleQuery       = 'select ''CU''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default will be C - Customer order   */
/*----------------------------------------------------------------------------*/
  select @vRuleCondition   = null,
         @vRuleDescription = 'By Default pick Group will be C',
         @vRuleQuery       = 'select ''C''',
         @vStatus          = 'A'/* Active */,
         @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
