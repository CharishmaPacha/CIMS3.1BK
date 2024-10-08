/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/03  RV      Made changes to decide is carrier small package or not based on the IsSmallPackageCarrier flag
                        instead of mention each carrier (S2GCA-236)
  2015/07/10  RV      Initial version (S2G-113)
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
select @vRuleSetType = 'ShiplabelImageTypes';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
select @vRuleSetName        = 'ShipLabelImageTypes',
       @vRuleSetFilter      = '~IsSmallPackageCarrier~ = ''Y''',
       @vRuleSetDescription = 'Get default label image type for small package carriers',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule PTS/Combo Packing list - For some PTS waves we would print combo packing list, so request PNG */
select @vRuleCondition   = '~WaveType~ in (''PTS'') and ~Account~ in (''000'')',
       @vRuleDescription = 'Get PNG Label for PTS waves/orders which require combo packing list',
       @vRuleQuery       = 'select ''PNG''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule PTS individual Packing list - For some PTS waves we would print shipping labels separately, request ZPL for such scenarios */
select @vRuleCondition   = '~WaveType~ in (''PTS'') and ~Account~ in (''000'')',
       @vRuleDescription = 'Get ZPL Label for PTS waves/orders which do not require combo packing list',
       @vRuleQuery       = 'select ''ZPL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule ZPL - Default rule to get ZPL image label */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default label image type as ZPL',
       @vRuleQuery       = 'select ''ZPL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
