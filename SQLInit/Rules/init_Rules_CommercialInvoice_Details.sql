/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/06  RV      Added default rule to for service terms (BK-911)
  2021/12/15  PHK     Initial version (FB-2225)
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
/* Rules for : Commercial Invoice Info */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'CommercialInvoiceInfo';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Commercial Invoice Details */
/******************************************************************************/
select @vRuleSetName        = 'CommercialInvoiceDetails',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Commercial Invoice Details',
       @vStatus             = 'A' /* A-Active , I-InActive , NA-Not applicable */,
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update info based upon OH Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LPNId~ is not null',
       @vRuleDescription = 'CI-Tems: Update based upon OrderHeader info',
       @vRuleQuery       = 'update CI
                            set CI.Terms = OH.UDF12
                            from #CIInfo CI
                              join OrderHeaders OH on (CI.OrderId = OH.OrderId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update CI-Tersm as DDP (Duty Prepaid) */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'CI-Terms: Default to DDP',
       @vRuleQuery       = 'update #CIInfo
                            set Terms = ''DDP''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
