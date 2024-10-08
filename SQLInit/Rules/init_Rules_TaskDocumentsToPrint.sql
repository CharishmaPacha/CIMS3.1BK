/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/07/27  TK      PC Wave should print Employee Labels if required (HPI-379)
  2016/07/25  TK      Rules for OverStock Wave (HPI-267)
  2016/06/13  TK      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'TaskDocumentsToPrint';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare @vRecordId           TRecordId,
          @vRuleSetId          TRecordId,
          @vRuleSetName        TName,
          @vRuleSetFilter      TQuery,
          @vRuleSetDescription TDescription,

          @vBusinessUnit       TBusinessUnit,

          @vRuleCondition      TQuery,
          @vRuleQuery          TQuery,
          @vRuleDescription    TDescription,

          @vSortSeq            TSortSeq,
          @vStatus             TStatus;

  declare @RuleSets            TRuleSetsTable,
          @Rules               TRulesTable;

/*******************************************************************************
 * Documents To Print:
 *   SL  - Ship Label
 *   SPL - Small Package Label
 *   CL  - Contents Label
 *   PL  - Packing Lists
 *   LPN - LPN Label
 *   TL  - Task Header Label
 *   TDL - Task Detail Label ex. Employee Label 
 ******************************************************************************/

/******************************************************************************/
/* Rule Set #1 - Replenish Waves - No labels are needed */
/******************************************************************************/
select @vRuleSetName        = 'TaskLabels_ReplenishWaves',
       @vRuleSetFilter      = '~WaveType~ in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Task Labels for Replenish Waves',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Print Task Header Label */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print Task header Label only for Replenish Waves',
       @vRuleQuery       = 'select ''TL''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - Pick & Pack waves */
/******************************************************************************/
select @vRuleSetName   = 'TaskLabels_PickAndPackWaves',
       @vRuleSetFilter = '~WaveType~ in (''PP'', ''SW'', ''SP'')',
       @vSortSeq       = null,
       @vStatus        = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Print Task Header label and Packing List only (as HPI packing list has shipped label embedded into it) */
select @vRuleCondition = null,
       @vRuleQuery     = 'select ''TL,PL''',
       @vStatus        = 'A'/* Active */,
       @vSortSeq       = null;

insert into @Rules (RuleSetName, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #3 - Single Line Waves */
/******************************************************************************/
select @vRuleSetName   = 'TaskLabels_SingleLineWaves',
       @vRuleSetFilter = '~WaveType~ in (''SLB'')',
       @vSortSeq       = null,
       @vStatus        = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For Single line Waves, print Task Header label only, they will be picked to pallet or Cart */
select @vRuleCondition = null,
       @vRuleQuery     = 'select ''TL''',
       @vStatus        = 'A'/* Active */,
       @vSortSeq       = null;

insert into @Rules (RuleSetName, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #4 - Pick To Cart waves */
/******************************************************************************/
select @vRuleSetName   = 'TaskLabels_PickToCartWaves',
       @vRuleSetFilter = '~WaveType~ in (''PC'')',
       @vSortSeq       = null,
       @vStatus        = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Print Task Header label only, for PC waves. TDL is also defined and will be printed
   if there is any data for it */
select @vRuleCondition = null,
       @vRuleQuery     = 'select ''TL,TDL''',
       @vStatus        = 'A'/* Active */,
       @vSortSeq       = null;

insert into @Rules (RuleSetName, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #5 - Overstock Pick waves */
/******************************************************************************/
select @vRuleSetName   = 'TaskLabels_OverstockPickWaves',
       @vRuleSetFilter = '~WaveType~ in (''OP'')',
       @vSortSeq       = null,
       @vStatus        = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Print Task Header label only for PC waves */
select @vRuleCondition = null,
       @vRuleQuery     = 'select ''TL''',
       @vStatus        = 'A'/* Active */,
       @vSortSeq       = null;

insert into @Rules (RuleSetName, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;  

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
