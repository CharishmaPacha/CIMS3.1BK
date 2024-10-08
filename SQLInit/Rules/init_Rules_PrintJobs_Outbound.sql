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
--  2020/05/21  VS      Initial version (HA-326)
--------------------------------------------------------------------------------*/
--
--declare @vRecordId            TRecordId,
--        @vRuleSetType         TRuleSetType,
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
--/* Rule Set : Determine which LPNs labels to print at Receiving */
--/******************************************************************************/
--/******************************************************************************/
--select @vRuleSetType = 'PrintJobs_Outbound';
--
--delete from @RuleSets;
--delete from @Rules;
--
--/******************************************************************************/
--/* Rule Set - Print labels/reports for the given Wave requested by Allocation */
--/******************************************************************************/
--select @vRuleSetName        = 'PrintJobs_Allocation',
--       @vRuleSetFilter      = null,
--       @vRuleSetDescription = 'Print Job Allocation: Break up the wave into more logical groups for printing',
--       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
--       @vStatus             =  'A' /* Active */;
--
--insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
--  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
--
--/*-------------------------------------------------------------------------------------------------------------*/
--/* Add record for each Task for PTS Wave  */
--/*-------------------------------------------------------------------------------------------------------------*/
--select @vRuleCondition   = null,
--       @vRuleDescription = 'Wave: Add Task record for each Task of PTS Wave',
--       @vRuleQuery       = 'insert into #PrintJobs(PrintJobType, PrintJobOperation, EntityType, EntityId, EntityKey, Reference1)
--                              select ''Label'', ETP.Operation, ''Task'', T.TaskId, T.TaskId, W.WaveNo
--                              from Waves W
--                                join #EntitiesToPrint ETP on ETP.EntityId = W.WaveId
--                                join Tasks T on T.WaveId = W.WaveId
--                              where (ETP.EntityType = ''Wave'') and
--                                    (W.WaveType in (''PTS''))',
--       @vRuleQueryType   = 'Update',
--       @vStatus          = 'A'/* Active */,
--       @vSortSeq        += 1;
--
--insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
--  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;
--
--/*-------------------------------------------------------------------------------------------------------------*/
--/* BCP/BPP: Process entire Wave as one job if less than 1000 labels  */
--/*-------------------------------------------------------------------------------------------------------------*/
--select @vRuleCondition   = null,
--       @vRuleDescription = 'Wave: BCP/BPP Waves processed as one job if less than 1000 labels',
--       @vRuleQuery       = 'insert into #PrintJobs(PrintJobType, PrintJobOperation, EntityType, EntityId, EntityKey, Reference1)
--                              select ''Label'', ETP.Operation, ''Wave'', W.WaveId, W.WaveNo, W.WaveNo
--                              from Waves W
--                                join #EntitiesToPrint ETP on ETP.EntityId = W.WaveId
--                              where (ETP.EntityType = ''Wave'') and
--                                    (W.WaveType in (''BCP'', ''BPP'')) and
--                                    (W.NumLPNs <= 1000)',
--       @vRuleQueryType   = 'Update',
--       @vStatus          = 'A'/* Active */,
--       @vSortSeq        += 1;
--
--insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
--  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;
--
--/*-------------------------------------------------------------------------------------------------------------*/
--/* BCP/BPP: Process each Order as a print job if Wave has more than 1000 labels  */
--/*-------------------------------------------------------------------------------------------------------------*/
--select @vRuleCondition   = null,
--       @vRuleDescription = 'Wave: BCP/BPP Waves with more than 1000 labels, process each Order separately',
--       @vRuleQuery       = 'insert into #PrintJobs (PrintJobType, PrintJobOperation, EntityType, EntityId, EntityKey, Reference1)
--                              select ''Label,Report'', ETP.Operation, ''Order'', OH.OrderId, OH.PickTicket, W.WaveNo
--                              from Waves W
--                                join #EntitiesToPrint ETP on ETP.EntityId = W.WaveId
--                                join OrderHeaders OH on (OH.PickBatchId = W.WaveId)
--                              where (ETP.EntityType = ''Wave'') and
--                                    (ETP.EntityId = ~EntityId~) and
--                                    (W.WaveType in (''BCP'', ''BPP'')) and
--                                    (W.NumLPNs > 1000)',
--       @vRuleQueryType   = 'Update',
--       @vStatus          = 'A'/* Active */,
--       @vSortSeq        += 1;
--
--insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
--  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;
--
--/******************************************************************************/
--exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;
--
--Go
--