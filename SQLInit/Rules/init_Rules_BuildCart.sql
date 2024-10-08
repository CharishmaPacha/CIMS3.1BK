/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/15  TK      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'BuildCart_AutoAssignLPNs';

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
/* Rule Set: Automatically Assign LPNs to cart positions */
/******************************************************************************/
select @vRuleSetName        = 'AutoAssignLPNs',
       @vRuleSetDescription = 'Automatically Assign LPNs to cart positions',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Default */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'By default, Auto assign LPNs to Cart',
       @vRuleQuery       = 'select ''Y''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
