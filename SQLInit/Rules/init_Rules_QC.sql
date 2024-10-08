/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/13  RIA     Initial version (HPI-2282)
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
/* Rules for : Quality Check Mode */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'QC_GetQCMode';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'QC_GetModeForScannedLPN',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Determine the Quality Check mode for the Scanned LPN',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: In some cases, users may be allowed to scan a SKU and enter the qty of the units of that SKU */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If user is allowed to scan a SKU and enter the qty for the SKU, then use this mode',
       @vRuleQuery       = 'select ''SQ''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: By default QC mode would be to Scan each unit in the LPN */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If none of the above rules get executed by default QC mode is to scan each unit',
       @vRuleQuery       = 'select ''SE''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for : Additional checks to be done at the end of scanning items */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'QC_AdditionalChecks';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Rules for the additional checks at the end of the QC for Pick To Ship */
/******************************************************************************/
select @vRuleSetName        = 'QC_AdditionalChecksPickedLPNs',
       @vRuleSetFilter      = 'charindex(~LPNStatus~, ''KDE'' /* Picked/Packed/Staged */) > 0',
       @vRuleSetDescription = 'Determine the additional checks for LPNs that have been Picked/Packed/Staged',
       @vStatus             = 'I' /* Active */,
       @vSortSeq            = 0; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Additional checks for Pick To Ship Cases */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''PTS''',
       @vRuleDescription = 'Fpr Pick To Ship cartons, have users confirm the Carton Size and Weight and verify Packing List',
       @vRuleQuery       = 'select ''VCS,VW,VPL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Additional checks for LTL - verify Labels */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''LTL''',
       @vRuleDescription = 'For LTL Orders, verify if the Labels are applied and positioned correctly on the cartons',
       @vRuleQuery       = 'select ''LA,LPC''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Additional checks by default is to verify all shipping docs i.e labels, packing list */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If none of the above rules get executed by default verify shipping docs',
       @vRuleQuery       = 'select ''VSD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
