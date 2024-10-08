/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/08  RT      Initial version
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
/* Rules for : Shipping Pallet Tag */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'PTag_GetFormat';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Pallet Tag */
/******************************************************************************/
select @vRuleSetName        = 'Shipping Pallet Tag',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get Pallet Tag to print',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Shipping PalletTag*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Get Pallet Tag to Print',
       @vRuleQuery       = 'select ''Shipping_PalletTag''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
