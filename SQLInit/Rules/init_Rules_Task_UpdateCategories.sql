/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/16  MS      Initial version (CID-367)
------------------------------------------------------------------------------*/

Go

declare @vRuleSetType  TRuleSetType = 'Task_UpdateCategories';

  declare @vRecordId            TRecordId,
          @vRuleSetId           TRecordId,
          @vRuleSetName         TName,
          @vRuleSetDescription  TDescription,
          @vRuleSetFilter       TQuery,

          @vBusinessUnit        TBusinessUnit,

          @vRuleCondition       TQuery,
          @vRuleDescription     TDescription,
          @vRuleQuery           TQuery,
          @vRuleQueryType       TTypeCode,

          @vSortSeq             TSortSeq,
          @vStatus              TStatus;

  declare @RuleSets             TRuleSetsTable,
          @Rules                TRulesTable;

/******************************************************************************/
/* Update TaskCategories */
/******************************************************************************/
select @vRuleSetName        = 'TaskUpdateCategory',
       @vRuleSetDescription = 'Update Task Categories',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Rule to update the Task Categories on Tasks */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Task Categories based on the TaskDetails',
       @vRuleQuery       = ';with TaskCategories(TaskId, TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5) as
                               (
                                select TD.TaskId,
                                       Min(TD.TDCategory1),
                                       Min(TD.TDCategory2),
                                       Min(TD.TDCategory3),
                                       Min(TD.TDCategory4),
                                       Min(TD.TDCategory5)
                                from TaskDetails TD
                                where (WaveId = ~WaveId~)
                                group by TD.TaskId
                               )
                               update T
                               set    T.TaskCategory1 = TC.TDCategory1,
                                      T.TaskCategory2 = TC.TDCategory2,
                                      T.TaskCategory3 = TC.TDCategory3,
                                      T.TaskCategory4 = TC.TDCategory4,
                                      T.TaskCategory5 = TC.TDCategory5
                               from Tasks T join TaskCategories TC on T.TaskId = TC.TaskId;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleQueryType, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleQueryType, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

Go
