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
--  2015/07/10  RV      Initial version (S2G-113)
--------------------------------------------------------------------------------*/
--
--declare @vRuleSetType  TRuleSetType = 'LabelImageTypes';
--
--Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
--delete from RuleSets where RuleSetType = @vRuleSetType;
--
--  declare @vRecordId           TRecordId,
--          @vRuleSetId          TRecordId,
--          @vRuleSetName        TName,
--          @vRuleSetDescription TDescription,
--          @vRuleSetFilter      TQuery,

--          @vBusinessUnit       TBusinessUnit,
--
--          @vRuleCondition      TQuery,
--          @vRuleQuery          TQuery,
--          @vRuleDescription    TDescription,
--
--          @vSortSeq            TSortSeq,
--          @vStatus             TStatus;
--
--  declare @RuleSets            TRuleSetsTable,
--          @Rules               TRulesTable;
--
--/******************************************************************************/
--/* Rule Set #1 - LabelImageTypes */
--/******************************************************************************/
--select @vRuleSetName        = 'Label Image Types',
--       @vRuleSetDescription = 'Get default label image type for small package carriers',
--       @vRuleSetFilter      = '~Carrier~ in (''UPS'', ''USPS'', ''FedEx'', ''DHL'')',
--       @vSortSeq            = null,
--       @vStatus             = 'A';
--
--insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
--  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
--
--/*----------------------------------------------------------------------------*/
--/* Rule 1.1 - Get ZPL image label for Automation waves */
--select @vRuleCondition   = '~BatchType~ in (''XYZ'', ''XYZ'', ''XYZ'')',
--       @vRuleDescription = 'Get ZPL Label for Automation waves',
--       @vRuleQuery       = 'select ''ZPL''',
--       @vSortSeq         = null,
--       @vStatus          = 'A';
--
--insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
--  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;
--
--  ----------------------------------------------------------------------------*/
--/* Rule 1.2 - Default rule to get PNG image label */
--select @vRuleCondition   = null,
--       @vRuleDescription = 'Default label image type as PNG',
--       @vRuleQuery       = 'select ''PNG''',
--       @vSortSeq         = null,
--       @vStatus          = 'A';
--
--insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
--  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;
--
--/******************************************************************************/
--exec pr_Rules_Setup @RuleSets, @Rules;
--
--Go
--