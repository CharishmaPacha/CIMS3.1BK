/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/05  AY      Receipts: UD1 = AIR, send the whole receipt to QC (CID-177)
  2019/02/08  RV      Initial version (CID-53)
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
/* Rules for selecting percentage of LPNs to be QC */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'QCInboundPercentage'; -- Move to single

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to return QC percentage */
/******************************************************************************/
select @vRuleSetName        = 'QCInbound_Percentage',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'LPNs select percentage for QC',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: 100% QC AIR shipments */
select @vRuleCondition   = null,
       @vRuleDescription = 'For AIR shipments, we have to QC 100%',
       @vRuleQuery       = 'select ''100''
                            from ReceiptHeaders
                            where (ReceiptId = ~ReceiptId~) and (UDF1 = ''AIR'')',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to return percentage to QC check */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule to QC check 5 percent of LPNs',
       @vRuleQuery       = 'select ''5''',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
