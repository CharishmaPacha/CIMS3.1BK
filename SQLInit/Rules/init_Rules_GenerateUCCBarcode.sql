/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/04  VM      Resolve duplicate RuleDescription issues (S2GCA-715)
  2016/05/04  RV      Added and optimised the rules for Ship Label, Small Package Label, Packing List, Content Label and return label (NBD-470)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2016/03/16  DK      Initial version
------------------------------------------------------------------------------*/

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
/* Rules for : Generate UCCBarcode */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'GenerateUCCBarcode'

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Generate UCCBarcode */
/******************************************************************************/
select @vRuleSetName        = 'GenerateUCCBarcode',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Generate UCCBarcode',
       @vStatus             = 'A',
       @vSortSeq            = '1';

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule ..... */
select @vRuleCondition   = '~LabelType~ = ''SL''',
       @vRuleDescription = 'Generate UCC Barcode for SL',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A',
       @vSortSeq         = '1'

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule ..... */
select @vRuleCondition   = '~LabelType~ in (''SPL'', ''PL'', ''CL'', ''RL'')',
       @vRuleDescription = 'Generate UCC Barcode other Labels',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A',
       @vSortSeq         = '2'

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
