/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/08  TK      Revised Rules to process all LPNs once (HA-468)
  2018/09/03  RV      Made changes to decide is carrier small package or not based on the IsSmallPackageCarrier flag
                        instead of mention each carrier (S2GCA-236)
  2018/02/23  RV      Initial version (S2G-255)
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
/* Rules to decide whether to insert ship labels or not */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Allocation_InsertShipLabels';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Check whether ship labels required or not based on wave type */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabels required for Wave?',
       @vRuleSetFilter      = '~Validation~ = ''WaveType''',
       @vRuleSetDescription = 'ShipLabels required for Wave?',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Yes, for BCP, BPP & PTS wave types */
select @vRuleCondition   = '~WaveType~ in (''BCP'', ''BPP'', ''PTS'')',
       @vRuleDescription = 'Yes, for BCP, BPP & PTS wave types',
       @vRuleQuery       = 'select ''Y'''/* Yes */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: No, by default */
select @vRuleCondition   = null,
       @vRuleDescription = 'No, by default',
       @vRuleQuery       = 'select ''N'''/* No */,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Check whether ship labels required or not based on Carrier */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabels required for Carrier?',
       @vRuleSetFilter      = '~Validation~ = ''Carrier''',
       @vRuleSetDescription = 'ShipLabels required for Carrier?',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* InsertRequired: Yes, for SPG carrier and No, for others */
select @vRuleCondition   = null,
       @vRuleDescription = 'InsertRequired: Yes, for SPG carrier and No, for others',
       @vRuleQuery       = 'Update #ShipLabelsToInsert
                            set InsertRequired = case when IsSmallPackageCarrier = ''Y'' then ''Y'' else ''N'' end',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
