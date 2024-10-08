/*==============================================================================
  VM_20201210 (CIMS-3140):
    Commented all lines of this file because while setting up of processing rule files via Folder instead of _init_All_Rules.sql to build blank DB,
    I found this file is eisther not listed or commented in _Init_All_Rules.sql.

    If it is require to be used, you can remove comments (==) from each line and use it
==============================================================================*/
--/*------------------------------------------------------------------------------
--  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved
--
--  Revision History:
--
--  Date        Person  Comments
--
--  2018/10/11  PK      Updated Validation not to consider Picklane locations (OB2-Support)
--  2018/08/27  DK      Initial version (OB2-646).
--------------------------------------------------------------------------------*/
--
--Go
--
--declare @vRecordId            TRecordId,
--        @vRuleSetName         TName,
--        @vRuleSetDescription  TDescription,
--        @vRuleSetFilter       TQuery,

--        @vBusinessUnit        TBusinessUnit,
--
--        @vRuleCondition       TQuery,
--        @vRuleQuery           TQuery,
--        @vRuleQueryType       TTypeCode,
--        @vRuleDescription     TDescription,
--
--        @vSortSeq             TSortSeq,
--        @vStatus              TStatus;
--
--declare @RuleSets             TRuleSetsTable,
--        @Rules                TRulesTable;
--
--/******************************************************************************/
--/******************************************************************************/
--/* Rules for : Validations while transfering Inventory */
--/******************************************************************************/
--/******************************************************************************/
--declare @vRuleSetType  TRuleSetType = 'TransferInvValidation';
--
--Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
--delete from RuleSets where RuleSetType = @vRuleSetType;
--delete from @RuleSets;
--delete from @Rules;
--
--/******************************************************************************/
--/* Rule Set #1: Get the error message */
--/******************************************************************************/
--select @vRuleSetName        = 'TransferInvValidation',
--       @vRuleSetFilter      = null,
--       @vRuleSetDescription = 'Validation rules for Inventory Transfer',
--       @vStatus             = 'A', /* Active */
--       @vSortSeq            = null;
--
--insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
--  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
--
--/*----------------------------------------------------------------------------*/
--/* Rule: Do not allow transfer from Received LPN to Putaway LPN */
--select @vRuleCondition   = '(~FromLPNStatus~ = ''R'') and (~ToLPNStatus~ = ''P'') and (~ToLocationType~ <> ''K'')',
--       @vRuleDescription = 'Do not allow transfer from Received LPN to Putaway LPN',
--       @vRuleQuery       = 'select ''TransferInv_NotValidFromReceivedToPutaway''',
--       @vRuleQueryType   = 'Select',
--       @vStatus          = 'A'/* Active */,
--       @vSortSeq         = 1;
--
--insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
--  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;
--
--/*----------------------------------------------------------------------------*/
--exec pr_Rules_Setup @RuleSets, @Rules;
--
--Go
--