/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/13  RKC   Initial version (HA-1610)
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
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
/* Rules used for Load Generation process */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Loads_Generate';

delete from @RuleSets;
delete from @Rules;

/*******************************************************************************/
/* Rule Set - To determine the Load Group for various types of Orders */
/*******************************************************************************/
select @vRuleSetName        = 'LoadsGenerate_SetLoadGroup',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to set Orders.LoadGroup prior to Load generation',
       @vStatus             = 'NA' /* A-Active, I-In-Active, NA-Not applicable */,
       @vSortSeq            = 30;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*******************************************************************************/
/* Rule Set - To do final updates before the Loads are generated */
/*******************************************************************************/
select @vRuleSetName        = 'LoadsGenerate_Finalize',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to do any final updates prior to Load Generation',
       @vStatus             = 'NA' /* A-Active, I-In-Active, NA-Not applicable */,
       @vSortSeq            = 40;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
