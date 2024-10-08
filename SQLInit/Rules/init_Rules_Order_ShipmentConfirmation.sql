/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/28  VM      Suppress confirmations for specific accounts (HPI-2059)
  2018/09/28  AY      Initial version (HPI-2059)
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
/* Rules for : Rule to determine if shipment confirmation is to be suppressed */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Order_ShipConfirm_SuppressEmail';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;
delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this RuleSet */
/******************************************************************************/
select @vRuleSetName        = 'Order_ShipConfirmSuppressEmail',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Supress ship confirmation for some Accounts',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Suppress confirmations for specific accounts  */
select @vRuleCondition   = '~Account~ in ('''')',
       @vRuleDescription = 'Suppress ship confirmations for specific accounts',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default is to send ship confirmation to all clients */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default: Send shipment confirmations to all clients',
       @vRuleQuery       = 'select ''N''' ,
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
