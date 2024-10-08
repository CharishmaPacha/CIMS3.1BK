/*==============================================================================
  VM_20201210 (CIMS-3140):
    Commented all lines of this file because while setting up of processing rule files via Folder instead of _init_All_Rules.sql to build blank DB,
    I found this file is either not listed or commented in _Init_All_Rules.sql.

    If it is require to be used, you can remove comments (==) from each line and use it
==============================================================================*/
--/*------------------------------------------------------------------------------
--  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved
--
--  Revision History:
--
--  Date        Person  Comments
--
--  2018/05/29  TK      Drop Pallet is not required for PTLC (S2G-534)
--  2018/05/05  RV      Initial version (S2G-534)
--------------------------------------------------------------------------------*/
--
--declare @vRuleSetType  TRuleSetType = 'DropPalletRequired';
--
--Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
--delete from RuleSets where RuleSetType = @vRuleSetType;
--
--declare @vRecordId            TRecordId,
--        @vRuleSetId           TRecordId,
--        @vRuleSetName         TName,
--        @vRuleDescription     TDescription,
--        @vRuleSetDescription  TDescription,
--        @vRuleSetFilter       TQuery,

--        @vBusinessUnit        TBusinessUnit,
--
--        @vRuleCondition       TQuery,
--        @vRuleQuery           TQuery,
--
--        @vSortSeq             TSortSeq,
--        @vStatus              TStatus;
--
--declare @RuleSets             TRuleSetsTable,
--        @Rules                TRulesTable;
--
--/******************************************************************************/
--/* Determine whether the Drop Pallet screen navigation is required or not after picking */
--/******************************************************************************/
--select @vRuleSetName        = 'DropPallet_Required',
--       @vRuleSetDescription = 'Drop Pallet required or not after picking',
--       @vRuleSetFilter      = null,
--       @vSortSeq            = null,
--       @vStatus             = 'A'  /* Active */;
--
--insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
--  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
--
--/*----------------------------------------------------------------------------*/
--/* Rule: If wave is PTL not required to drop explicitly */
--select @vRuleCondition   = '~BatchType~ in (''PTL'', ''PTLC'')',
--       @vRuleDescription = 'If wave type is PTL not required to show drop screen',
--       @vRuleQuery       = 'select ''N''', /* No */
--       @vStatus          = 'A'/* Active */,
--       @vSortSeq         = null;
--
--insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
--  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;
--
--/*----------------------------------------------------------------------------*/
--/* Rule: Default rule to show drop screen */
--select @vRuleCondition   = null,
--       @vRuleDescription = 'Default rule to show drop screen',
--       @vRuleQuery       = 'select ''Y''',
--       @vStatus          = 'A'/* Active */,
--       @vSortSeq         = null;
--
--insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
--  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;
--
--/******************************************************************************/
--exec pr_Rules_Setup @RuleSets, @Rules;
--
--Go
--