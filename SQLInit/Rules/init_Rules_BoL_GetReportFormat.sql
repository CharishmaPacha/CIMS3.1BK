/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/01  AY      Rules set for various scenarios based upon active defined formats (HA-2098)
  2019/12/17  SAK     Changed in standard format (CIMS-2778)
  2018/07/09  RT      Made minor corrections and Added to Rules to get the BoL report type to print, changed the RuleSet Type and made Minor changes (S2GCA-112)
  2018/07/02  VS      Initial version
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
select @vRuleSetType = 'VICSBoLFormat';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Get the VICSBoL Report format */
/******************************************************************************/
select @vRuleSetName        = 'VICSBoL Report Format',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Determine VICSBoL Report format',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 10; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* VICSBoL Report specific for the BU/Owner */
select @vRuleCondition   = null,
       @vRuleDescription = 'VICS BoL Report: Use the BU/Owner specific format if one exists',
       @vRuleQuery       = 'select ReportName
                            from Reports
                            where (ReportName like ''VICSBoLMaster_'' + ~BusinessUnit~ + ''_'' + ~Owner~) and
                                  (Status = ''A'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* VICSBoL Report specific for the BU/WH */
select @vRuleCondition   = null,
       @vRuleDescription = 'VICS BoL Report: Use the BU/WH specific format if one exists',
       @vRuleQuery       = 'select ReportName
                            from Reports
                            where (ReportName like ''VICSBoLMaster_'' + ~BusinessUnit~ + ''_'' + ~Warehouse~) and
                                  (Status = ''A'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* VICSBoL Report specific for the BU/Account */
select @vRuleCondition   = null,
       @vRuleDescription = 'VICS BoL Report: Use the BU/Account specific format if one exists',
       @vRuleQuery       = 'select ReportName
                            from Reports
                            where (ReportName like ''VICSBoLMaster_'' + ~BusinessUnit~ + ''_A'' + ~Account~) and
                                  (Status = ''A'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* VICSBoL Report specific for the BU/SoldTo */
select @vRuleCondition   = null,
       @vRuleDescription = 'VICS BoL Report: Use the BU/SoldTo specific format if one exists',
       @vRuleQuery       = 'select ReportName
                            from Reports
                            where (ReportName like ''VICSBoLMaster_'' + ~BusinessUnit~ + ''_ST'' + ~SoldToId~) and
                                  (Status = ''A'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* VICSBoL Report specific to BU */
select @vRuleCondition   = null,
       @vRuleDescription = 'VICS BoL Report: Use the BU specific format if one exists',
       @vRuleQuery       = 'select ReportName
                            from Reports
                            where (ReportName like ''VICSBoLMaster_'' + ~BusinessUnit~) and
                                  (Status = ''A'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default VICSBoL Report */
select @vRuleCondition   = null,
       @vRuleDescription = 'VICS BoL Report: Standard format',
       @vRuleQuery       = 'select ''VICSBoLMaster''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
