/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/22  VS   Initial version (HA-520)
------------------------------------------------------------------------------*/

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
/* Rules evaulate LPN Move Validations */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'LPN_ValidateInventoryMovement';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Prevent PA of LPNs picked for Rework Orders */
/******************************************************************************/
select @vRuleSetName        = 'LPN_ValidateInventoryMovement',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Inventory movement validations',
       @vSortSeq            = 10,
       @vStatus             = 'A' /* Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Prevent PA of LPNs picked for Rework Orders */
select @vRuleCondition   = '(~OrderId~ is not null) and (~ToLocationType~ in (''R'', ''B'', ''K''))',
       @vRuleDescription = 'Do not move the LPN into inventory until Rework order is closed',
       @vRuleQuery       = 'select ''LPNPA_ReworkOrderIsNotYetClosed''
                            from OrderHeaders
                            where (OrderId = ~OrderId~) and (OrderType = ''RW'') and
                                  (Status <> ''D'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Not applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
