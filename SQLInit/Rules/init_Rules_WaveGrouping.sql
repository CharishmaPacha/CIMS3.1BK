/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/04  MS      Transfer Orders WaveGrouping (HA-1231)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/10/20  TK      Initial version
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
/* Rules to set up Wave groupping on orders */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'WaveGrouping';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Grouping of Waves */
/******************************************************************************/
select @vRuleSetName        = 'Group waves by given criteria',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Wave Grouping',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Group by Warehouse & Ship To */
select @vRuleCondition   = '~OrderType~ = ''T''',
       @vRuleDescription = 'Wave Grouping by Warehouse & Ship To',
       @vRuleQuery       = 'select ~Warehouse~ + ''-'' + coalesce(~ShipToId~, '''')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/******************************************************************************/
/* Rule Set: Grouping of Waves */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'WaveGrouping:ByWarehouse',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Wave Grouping - Group by Warehouse',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1: Group by Warehouse */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Grouping by Warehouse',
       @vRuleQuery       = 'select ~Warehouse~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/******************************************************************************/
/* Rule Set: Grouping by Account, Ship Date and WH */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'WaveGrouping:ByAccount-ShipDate-WH',
       @vRuleSetFilter      = '~Account~ in (''----'')',
       @vRuleSetDescription = 'Wave Grouping by Account, Ship Date and WH',
       @vStatus             = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to group waves by Account, ShipDate and DC */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Grouping by Account Shipdate, DC',
       @vRuleQuery       = 'select ~Account~ + ''-'' + ~ShipDate~ + ''-'' + ~Warehouse~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/******************************************************************************/
/* Rule Set -  Grouping by Account and Ship Date */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'WaveGrouping:ByAccount-ShipDate',
       @vRuleSetFilter      = '~Account~ in (''----'')',
       @vRuleSetDescription = 'Wave Grouping by Account and Ship Date',
       @vStatus             = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to group waves by Account and ShipDate */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Grouping by Account and Ship Date',
       @vRuleQuery       = 'select ~Account~ + ''-'' + ~ShipDate~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/******************************************************************************/
/* Rule Set - Grouping by Account and WH */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'WaveGrouping:ByAccount-WH',
       @vRuleSetFilter      = '~Account~ in (''----'')',
       @vRuleSetDescription = 'Wave Grouping by Account and WH',
       @vStatus             = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to group waves by Account and WH */
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave Grouping by Account, WH',
       @vRuleQuery       = 'select ~Account~ + ''-'' + ~Warehouse~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
