/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/27  MS       Get Default Logo (CIMSV3-1234)
  2020/06/07  RKC      Initial version (HA-743)
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
/* Rules for : Rules to get the Logo to print on the PL */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ReportLogo';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Rules to get the Logo to print on the PL */
/******************************************************************************/
select @vRuleSetName        = 'ReportLogo',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Get logo to print on reports',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 1; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set to get the RecordId of  Logo to print based upon the ShipFrom */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to get the custom logo to print based on the ShipFrom',
       @vRuleQuery       = 'select RecordId
                            from ContentImages
                            where (EntityKey  = ~ShipFrom~) and
                                  (EntityType = ''ShipFrom'') and
                                  (Status     = ''A'' /* Active */) and
                                  (BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Set to get the Default logo to print for CIMS Reports based upon BusinessUnit */
select @vRuleCondition   = '~DocumentType~ in (''SM'', ''PL'')',
       @vRuleDescription = 'Rule to get the Default logo to print for CIMS Reports based upon BusinessUnit',
       @vRuleQuery       = 'select RecordId
                            from ContentImages
                            where (EntityType = ''BU'') and
                                  (Status = ''A'' /* Active */) and
                                  (BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Set to get the CIMS logo to print as a last resort */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to get the Default logo to print for CIMS Reports',
       @vRuleQuery       = 'select top 1 RecordId
                            from ContentImages
                            where (EntityType = ''CIMS'') and
                                  (Status = ''A'' /* Active */)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
