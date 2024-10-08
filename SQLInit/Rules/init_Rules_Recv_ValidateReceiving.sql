/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/23  RIA     Updated the status to NA as these are client specific (JL-271)
  2020/07/21  SPP     Added in Rule for Validating InventoryClass1 for receiving (HA-1091)
  2020/04/13  VM      Initial revision
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
/* Rules for : To validate receiving */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Receiving_Validations';

delete from @RuleSets;
delete from @Rules;

/*******************************************************************************/
/* Rule Set - Rules to validate receiving */
/*******************************************************************************/
select @vRuleSetName        = 'Recv_Validations',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to validate while receiving inventory',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = null; -- as we update RecordId, we do not need to specify this

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Validate for InventoryClass1 */
select @vRuleCondition   = '~ReceiptId~ is not null',
       @vRuleDescription = 'Validation for InventoryClass1',
       @vRuleQuery       = 'select ''ReceiptDetails_InvalidLabelCode''
                              from ReceiptDetails RD
                                where (RD.ReceiptId = ~ReceiptId~) and
                                      (dbo.fn_IsValidLookUp(''InventoryClass1'',RD.InventoryClass1, ~BusinessUnit~, null) is not null)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/* --------------------------------------------------------- */
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
