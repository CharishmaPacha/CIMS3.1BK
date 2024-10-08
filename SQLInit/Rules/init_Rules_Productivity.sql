/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/30  SK      New RuleSetType ProductivityGetEntityInfo (HA-2937)
  2020/10/01  SK      New RuleSetType ProductivityAssignmentsTime (HA-1478)
  2020/01/06  SK      Initial version
------------------------------------------------------------------------------*/

declare  @vRecordId           TRecordId,
         @vRuleSetId          TRecordId,
         @vRuleSetName        TName,
         @vRuleSetDescription TDescription,
         @vRuleSetFilter      TQuery,

         @vBusinessUnit       TBusinessUnit,

         @vRuleCondition      TQuery,
         @vRuleQuery          TQuery,
         @vRuleQueryType      TTypeCode,
         @vRuleDescription    TDescription,

         @vSortSeq            TSortSeq,
         @vStatus             TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/*******************************************************************************
  Productivity Assignments:

    Rules for evaluating user productivity
*******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'ProductivityAssignments';

delete from @RuleSets;
delete from @Rules;


/*----------------------------------------------------------------------------*/
/* Rule Set - For deciding on the assignment number */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'NewAssignment',
       @vRuleSetDescription = 'Rules to decide whether a new task assignment is needed',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* First Assignment - Should get initiated the very first time */
select @vRuleCondition   = '(~PrevOperation~ = ''none'')',
       @vRuleDescription = 'Prod Assignments: First assignment',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Ignorables - Cannot be considered as an assignment
   This occurs when the end activity of an operation is executed after re login of
   device or some other operation in the middle.
   The single end operation cannot be treated as an assignment */
select @vRuleCondition   = '(~PrevOperation~ <> ~Operation~) and (~Mode~ = ''E'')',
       @vRuleDescription = 'Prod Assignments: Discontinued end operation',
       @vRuleQuery       = 'select ''I''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Previous Activity type's mode indicated end of operation */
select @vRuleCondition   = '(~PrevMode~ = ''E'')',
       @vRuleDescription = 'Prod Assignments: End of Previous operation, create new assignment',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Start of every operation */
select @vRuleCondition   = '(~Mode~ = ''S'')',
       @vRuleDescription = 'Prod Assignments: Start of an Operation',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Different Operation - when start and end is not defined */
select @vRuleCondition   = '(~PrevOperation~ <> ~Operation~)',
       @vRuleDescription = 'Prod Assignments: Operational activity changed',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Job code related rules */
/*----------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------*/
/* Difference between previous and current activity exceeds threshold set */
select @vRuleCondition   = '(~!TimeElapsed~ > ~!TimeAllowedInSecs~)',
       @vRuleDescription = 'Prod Assignments: Time threshold between consecutive activities',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default */
select @vRuleCondition   = null,
       @vRuleDescription = 'Prod Assignments: Default - Not a new assignment',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*******************************************************************************
  Productivity Assignments Time:

    Rules for evaluating user productivity start time
*******************************************************************************/
select @vRuleSetType = 'ProductivityAssignmentsTime';

/*----------------------------------------------------------------------------*/
/* Rule Set - For deciding on the start time of a new assignment */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'AssignmentTime',
       @vRuleSetDescription = 'Rules to decide whether the start time of a new assignment',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* New Assignment - Consider previous activity Start time within the permissible time limit */
/* Because in some cases the current activity does not have a start operation and its previous operation has not ended */
select @vRuleCondition   = '(~!TimeElapsed~ < ~!TimeAllowedInSecs~) and (~Mode~ = ''D'')',
       @vRuleDescription = 'Prod Assignments Time: Consider Previous activity type time',
       @vRuleQuery       = 'select ''Y''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*******************************************************************************
  Productivity Entity info:

    Rules for processing productivity entity info
*******************************************************************************/
select @vRuleSetType = 'Productivity_UpdateEntityInfo';

/*----------------------------------------------------------------------------*/
/* Rule Set - Process wave Info */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'UpdateEntityInfo',
       @vRuleSetDescription = 'Update related info for Wave etc.',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update Wave info  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Wave info',
       @vRuleQuery       = 'Update P
                            set P.WaveNo       = coalesce(W.WaveNo, P.WaveNo),
                                P.WaveType     = W.WaveType,
                                P.WaveTypeDesc = W.WaveTypeDesc
                            from #Productivity P
                              join vwWaves W on P.WaveId = W.WaveId
                            where (P.WaveId is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update Order info  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Order info',
       @vRuleQuery       = 'Update P
                            set P.PickTicket = OH.PickTicket
                            from #Productivity P
                              join OrderHeaders OH on P.OrderId = OH.OrderId
                            where (P.OrderId is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go