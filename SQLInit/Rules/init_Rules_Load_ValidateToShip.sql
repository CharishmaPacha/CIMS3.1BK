/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/17  RIA     Made changes to the  rule to evaluate DesiredShipDate (OB2-781)
  2018/11/23  CK/AY   Initial version (OB2-683)
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
/* Rules for : Validate the Load to Ship */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Load_ValidateToShip';

delete from @RuleSets;
delete from @Rules;

/*******************************************************************************/
/* Rule Set - Ensure Client Load is specified for some Loads */
/*******************************************************************************/
select @vRuleSetName        = 'Load_ValidateToShip',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to validate if the Load can be shipped',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Ensure Load DesiredShipDate is not a future date */
select @vRuleCondition   = null,
       @vRuleDescription = 'Ensure Load DesiredShipDate is not a future date',
       @vRuleQuery       = 'select ''LoadShip_Has_FutureShipDate''
                            from Loads
                            where LoadId = ~LoadId~ and
                                  cast (DesiredShipDate as date) > getdate()',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For some customers, ClientLoad is required */
select @vRuleCondition   = '~ClientLoad~ is null or ~ClientLoad~ = ''''',
       @vRuleDescription = 'Ensure Client Loads exists for Customers that require it',
       @vRuleQuery       = 'select ''LoadShip_MissingClientLoad''
                            from vwOrdersForLoads
                            where LoadId = ~LoadId~ and
                                  SoldToId = ''XYZ''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
