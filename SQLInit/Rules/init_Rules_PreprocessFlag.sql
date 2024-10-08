/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/23  TK      Initial version
------------------------------------------------------------------------------*/
declare @vRuleSetType  TRuleSetType = 'PreprocessFlag';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare @vRecordId            TRecordId,
          @vRuleSetName         TName,
          @vRuleSetDescription  TDescription,
          @vRuleSetFilter       TQuery,

          @vBusinessUnit        TBusinessUnit,

          @vRuleCondition       TQuery,
          @vRuleQuery           TQuery,
          @vRuleDescription     TDescription,

          @vSortSeq             TSortSeq,
          @vStatus              TStatus;

  declare @RuleSets             TRuleSetsTable,
          @Rules                TRulesTable;

/******************************************************************************/
/* Rule Set #1 - Default set of rules that are applicable for most Orders */
/******************************************************************************/
select @vRuleSetName        = 'PreprocessFlag',
       @vRuleSetDescription = 'Rule Set to evaluate PreprocessFlag for Orders',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Replenish Orders */
select @vRuleCondition   = null,
       @vRuleDescription = 'Ignore for Replenish Orders',
       @vRuleQuery       = 'select ''I''
                            where ~OrderType~ in (''R'', ''RU'', ''RP'')',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Regular/Deafault Orders */
select @vRuleCondition   = null,
       @vRuleDescription = 'Set Flag to ''Y'' if the Order isn''t pre-processed earlier',
       @vRuleQuery       = 'select ''Y''
                            where ~PreprocessFlag~ = ''N''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default Rule */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default PreProcessFlag',
       @vRuleQuery       = 'select ''''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 100;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
