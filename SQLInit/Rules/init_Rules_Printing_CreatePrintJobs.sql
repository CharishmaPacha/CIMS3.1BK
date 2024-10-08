/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/18  MS      Changes to update #Reports & #Labels on PrintjobDetails (BK-156)
  2021/02/01  MS      Insert PrintJobDetails (BK-67)
  2020/01/21  AY      Setup PrintJob.Reference3 = Wave.AccountName (HA-1945)
  2020/12/17  VS      update the PrintJob Status based operation (HA-1375)
  2020/10/21  PK      Bugfix: Update the PrintJobStatus when Entity is Task - Port back from HA Prod/Stag by VM (HA-1483)
  2020/10/19  RKC     Made changes to update the Warehouse code on the print jobs for loads (HA-1591)
  2020/09/05  PK      Udpating WH on PrintJob for user to identify WH specific PrintJobs (HA-1233)
  2020/08/12  PK      Added update rules step in allocation for Entities (Task, Order & Wave) HA-1017
  2020/08/28  SAK     Addded Reference2,Count1 and Count2 fields (HA-887)
  2020/08/03  PK      PrintJobs_Outbound, PrintJobs_Tasks: Inserting NumLabels, NumReports & stock sizes for
                        reports & labels (HA-1017)
  2020/07/08  TK      PrintJobs_Allocation: Exclude cancelled tasks (HA-1114)
  2020/06/30  VS      Correcte rules to generate Printjobs for Load (HA-984)
  2020/06/24  AJ      Added rules to generate Printjobs for Load (HA-984)
  2020/06/17  MS      Added rules to generate printjobs for Task (HA-853)
  2020/05/29  VS      Exclude PrintJob if already PrintJob is created for the given Entity (HA-668)
  2020/05/21  VS      Initial version (HA-326)
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
/* Rule Set : Determine which LPNs labels to print at Receiving */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintJobs_Outbound';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Print labels/reports for the given Wave requested by Allocation */
/******************************************************************************/
select @vRuleSetName        = 'PrintJobs_Allocation',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Print Job Allocation: Break up the wave into more logical groups for printing',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for each Task for PTS Wave  */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave-PTS: Add Task record for each Task of PTS Wave',
       @vRuleQuery       = 'insert into #PrintJobs(PrintJobType, PrintJobOperation, EntityType, EntityId, EntityKey)
                              select ''Label,Report'', ETP.Operation, ''Task'', T.TaskId, T.TaskId
                              from Waves W
                                join #EntitiesToPrint ETP on (ETP.EntityId   = W.WaveId)
                                join Tasks            T   on (T.WaveId       = W.WaveId)
                              where (ETP.EntityType = ''Wave'') and
                                    (W.WaveType in (''PTS'')) and
                                    (T.Status not in (''C'', ''X''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* BCP/BPP: Process entire Wave as one job if less than 1000 labels  */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave-BCP/BPP: Processed as one job if less than 1000 labels',
       @vRuleQuery       = 'insert into #PrintJobs(PrintJobType, PrintJobOperation, EntityType, EntityId, EntityKey)
                              select ''Label,Report'', ETP.Operation, ''Wave'', W.WaveId, W.WaveNo
                              from Waves W
                                join #EntitiesToPrint ETP on (ETP.EntityId   = W.WaveId)
                              where (ETP.EntityType = ''Wave'') and
                                    (W.WaveType in (''BCP'', ''BPP'')) and
                                    (W.NumLPNs <= 1000)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* BCP/BPP: Large waves to be processed s multiple printjobs depends on threshold value
   Insert all the Orders into #PrintJobDetails and then group them to create multiple Print Jobs */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave-BCP/BPP: Large waves (>1000 labels) are split into multiple jobs with several orders per job',
       @vRuleQuery       = 'insert into #PrintJobDetails(PrintRequestId, PrintJobType, PrintJobOperation, ParentEntityType, ParentEntityId, ParentEntityKey,
                                                         EntityType, EntityId, EntityKey, BusinessUnit)
                              select ~PrintRequestId~, ''Label,Report'', ETP.Operation, ETP.EntityType, ETP.EntityId, ETP.EntityKey,
                                      ''Order'', OH.OrderId, OH.PickTicket, OH.BusinessUnit
                              from OrderHeaders OH
                                join Waves            W   on (OH.PickBatchId = W.WaveId)
                                join #EntitiesToPrint ETP on (ETP.EntityId   = W.WaveId)
                              where (ETP.EntityType = ''Wave'') and
                                    (W.WaveType in (''BCP'', ''BPP'')) and
                                    (W.NumLPNs > 1000) and
                                    (OH.OrderType not in (''B''/* Bulk */));

                            exec pr_Printing_GroupPrintJobDetails 200 /* NumDetailsPerJob */;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Print labels/reports for the given Task                         */
/******************************************************************************/
select @vRuleSetName        = 'PrintJobs_Tasks',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Print Job Tasks: Print labels / reports for the given task',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for given Task */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Task: Add Task record for given Task',
       @vRuleQuery       = 'insert into #PrintJobs(PrintJobType, PrintJobOperation, PrintJobStatus, EntityType, EntityId, EntityKey, Reference1,
                                                   LabelPrinterName, LabelPrinterName2, ReportPrinterName)
                              select ''Label,Report'', ETP.Operation, ''R'', ''Task'', T.TaskId, T.TaskId, T.BatchNo,
                                     ETP.LabelPrinterName, ETP.LabelPrinterName2, ETP.ReportPrinterName
                              from Tasks T
                                join #EntitiesToPrint ETP on ETP.EntityId = T.TaskId
                              where (ETP.EntityType = ''Task'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Print reports for the given Load                         */
/******************************************************************************/
select @vRuleSetName        = 'PrintJobs_Load',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Print Job Loads: Print reports for the given load',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for given Load */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Load: Add one record for each Load',
       @vRuleQuery       = 'insert into #PrintJobs(PrintJobType, PrintJobOperation, PrintJobStatus, EntityType, EntityId, EntityKey, Reference1,
                                                   LabelPrinterName, LabelPrinterName2, ReportPrinterName)
                              select ''Report'', ETP.Operation, ''R'', ''Load'', ETP.EntityId, ETP.EntityKey, ETP.EntityKey,
                                     ETP.LabelPrinterName, ETP.LabelPrinterName2, ETP.ReportPrinterName
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''Load'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Update Print JobDetails */
/******************************************************************************/
select @vRuleSetName        = 'PrintJobDetails_Updates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Print Job Details',
       @vSortSeq            = 0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job details with no of labels & reports for Entity - Order */
/*----------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print Job details with NumLabels&Reports for Entity - Order',
       @vRuleQuery       = ';with NumLablesInfo(NumLabels, NumCartons, OrderId)
                            as
                            (
                             select (
                                     sum(OH.LPNsAssigned * (case when (OH.UCC128LabelFormat is not null) and (OH.UCC128LabelFormat <> '') then 1 else 0 end)) +
                                     sum(OH.LPNsAssigned * (case when (OH.ContentsLabelFormat is not null) and (OH.ContentsLabelFormat <> '') then 1 else 0 end)) +
                                     sum(OH.LPNsAssigned * (case when (SV.IsSmallPackageCarrier = ''Y'') then 1 else 0 end))
                                    ) /* NumLabels */, min(OH.LPNsAssigned) /* NumCartons */, min(OH.OrderId)
                             from OrderHeaders OH
                               join #PrintJobDetails PJD on (OH.OrderId = PJD.EntityId)
                               join ShipVias         SV  on (OH.ShipVia = SV.ShipVia)
                             where (OH.PickBatchId = PJD.ParentEntityId) and
                                   (OH.OrderType not in (''B''/* Bulk */)) and
                                   (PJD.EntityType = ''Order'')
                             group by OH.OrderId
                            )
                            update PJD
                            set PJD.Count1        = 1, /* Orders */
                                PJD.Count2        = NLI.NumCartons, /* Cartons */
                                PJD.Count3        = 1, /* Reports */
                                PJD.RunningCount1 = NLI.NumLabels
                            from #PrintJobDetails PJD join NumLablesInfo NLI on (PJD.EntityId = NLI.OrderId)
                            where (PJD.EntityType = ''Order'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Update Print Jobs */
/******************************************************************************/
select @vRuleSetName        = 'PrintJobs_Updates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Print Jobs',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with ReportStockSizes for Entity - Task */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job ReportStockSizes for Entity - Task',
       @vRuleQuery       = 'Update PJ
                            set PJ.ReportStockSizes = (select distinct case when M.TargetValue = ''Combo'' then ''Combo/8.5 x 14'' else ''8.5 x 11'' end
                                                       from TaskDetails  TD
                                                                    join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                                                         left outer join Mapping      M  on (OH.Account = M.SourceValue) and
                                                                                            (M.TargetValue = ''Combo'')
                                                       where (PJ.EntityId = TD.TaskId))
                            from #PrintJobs PJ
                            where (PJ.EntityType = ''Task'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*--------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with PrintJobStatus, LabelStockSizes, NumLabels, NumReports, Count1, Count2 for Entity - Task */
/*--------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job PrintJobStatus, LabelStockSizes, NumLabels, NumReports, Count1 & Count 2 for Entity - Task',
       @vRuleQuery       = 'Update PJ
                            set PJ.PrintJobStatus  = case when (T.PrintStatus = ''ReadyToPrint'') and (~Operation~ = ''PrintTasks'') then ''R''
                                                          when (T.PrintStatus = ''OnHold'') and (~Operation~ = ''PrintTasks'') then ''O'' else PrintJobStatus end,
                                PJ.LabelStockSizes = case when (PJ.ReportStocksizes = ''Combo/8.5 x 14'') then ''NA'' else ''4 x 8'' end,
                                PJ.NumLabels       = case when (PJ.ReportStocksizes = ''Combo/8.5 x 14'') then 0 else T.NumTempLabels end,
                                PJ.NumReports      = case when (PJ.ReportStocksizes = ''Combo/8.5 x 14'') then T.NumTempLabels else T.OrderCount end,
                                PJ.NumOrders       = T.OrderCount,
                                PJ.NumCartons      = T.NumTempLabels,
                                PJ.Warehouse       = T.Warehouse
                            from #PrintJobs PJ
                              join Tasks T on (PJ.EntityId = T.TaskId)
                            where (PJ.EntityType = ''Task'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with Reference1, Reference2 for Entity - Task */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job Reference1, Reference2 for Entity - Task',
       @vRuleQuery       = 'Update PJ
                            set PJ.Reference1 = W.WaveNo,
                                PJ.Reference2 = W.WaveType,
                                PJ.Reference3 = W.AccountName
                            from #PrintJobs PJ
                              join Tasks T on (PJ.EntityId = T.TaskId)
                              join Waves W on (T.WaveId    = W.WaveId)
                            where (PJ.EntityType = ''Task'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with no of labels for Entity - Wave */
/*----------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job with NumLabels for Entity - Wave',
       @vRuleQuery       = 'Update PJ
                            set PJ.NumLabels = (select (sum(OH.LPNsAssigned * (case when ((OH.UCC128LabelFormat is not null) and (OH.UCC128LabelFormat <> '''')) then 1 else 0 end)) +
                                                        sum(OH.LPNsAssigned * (case when ((OH.ContentsLabelFormat is not null) and (OH.ContentsLabelFormat <> '''')) then 1 else 0 end)) +
                                                        sum(OH.LPNsAssigned * (case when (SV.IsSmallPackageCarrier = ''Y'') then 1 else 0 end))) /* NumLabels */
                                                from OrderHeaders OH
                                                  join ShipVias   SV on (OH.ShipVia = SV.ShipVia)
                                                where (OH.PickBatchId = PJ.EntityId) and
                                                      (OH.OrderType not in (''B''/* Bulk */)))
                            from #PrintJobs PJ
                            where (PJ.EntityType = ''Wave'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*--------------------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with report stock size, label stock size, NumReports, Reference1, Reference2, Count1 & Count2 for Entity - Wave */
/*--------------------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job with LabelStockSizes, ReportStockSizes, NumReports, Ref1, Ref2, Count1, Count2 for Entity - Wave',
       @vRuleQuery       = 'Update PJ
                            set PJ.LabelStockSizes  = case when W.WaveType in (''BCP'', ''BPP'') then ''4 x 6'' end,
                                PJ.ReportStockSizes = case when W.WaveType in (''BCP'', ''BPP'') then ''8.5 x 11'' end,
                                PJ.NumReports       = W.NumOrders,
                                PJ.NumOrders        = W.NumOrders,
                                PJ.NumCartons       = W.LPNsAssigned,
                                PJ.Reference1       = W.WaveNo,
                                PJ.Reference2       = W.WaveType,
                                PJ.Reference3       = W.AccountName,
                                PJ.Count1           = W.NumOrders,
                                PJ.Count2           = W.NumLPNs,
                                PJ.Warehouse        = W.Warehouse
                            from #PrintJobs PJ
                              join Waves W on (PJ.EntityId   = W.WaveId) and
                                              (PJ.EntityType = ''Wave'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with no of labels for Entity - Order */
/*----------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job with NumLabels for Entity - Order',
       @vRuleQuery       = 'Update PJ
                            set PJ.NumReports = 1,
                                PJ.NumLabels = (select (sum(OH.LPNsAssigned * (case when ((OH.UCC128LabelFormat is not null) and (OH.UCC128LabelFormat <> '''')) then 1 else 0 end)) +
                                                        sum(OH.LPNsAssigned * (case when ((OH.ContentsLabelFormat is not null) and (OH.ContentsLabelFormat <> '''')) then 1 else 0 end)) +
                                                        sum(OH.LPNsAssigned * (case when (SV.IsSmallPackageCarrier = ''Y'') then 1 else 0 end))) /* NumLabels */
                                                from OrderHeaders OH
                                                  join ShipVias SV on (OH.ShipVia = SV.ShipVia)
                                                where (PJ.EntityId = OH.OrderId) and
                                                      (OH.OrderType not in (''B''/* Bulk */)))
                            from #PrintJobs PJ
                            where (PJ.EntityType = ''Order'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with report stock size and label stock size, NuReports, Reference1, Reference2, Count1, Count2 for Entity - Order */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job with NumReports, ReportStockSizes, LabelStockSizes, Ref1, Ref2, Count1, Count2 for Entity - Order',
       @vRuleQuery       = 'Update PJ
                            set PJ.LabelStockSizes  = case when W.WaveType in (''BCP'', ''BPP'') then ''4 x 6'' end,
                                PJ.ReportStockSizes = case when W.WaveType in (''BCP'', ''BPP'') then ''8.5 x 11'' end,
                                PJ.NumReports       = ''1'',
                                PJ.Reference1       = W.WaveNo,
                                PJ.Reference2       = W.WaveType,
                                PJ.Reference3       = OH.AccountName,
                                PJ.Count1           = ''1'',
                                PJ.Count2           = OH.NumLPNs,
                                PJ.NumOrders        = ''1'',
                                PJ.NumCartons       = OH.NumLPNs,
                                PJ.Warehouse        = OH.Warehouse
                            from #PrintJobs PJ
                              join OrderHeaders OH on (PJ.EntityId = OH.OrderId) and
                                                      (PJ.EntityType = ''Order'')
                              join Waves        W  on (OH.PickBatchId   = W.WaveId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with report Warehouse for Entity - Load */
/*----------------------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Print job with Warehouse for Entity - Load',
       @vRuleQuery       = 'Update PJ
                            set PJ.Warehouse = L.FromWarehouse
                            from #PrintJobs PJ
                              join Loads L on (PJ.EntityId   = L.LoadId) and
                                              (PJ.EntityType = ''Load'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Exclude PrintJob if already PrintJob is created for the given Entity and active */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Exclude PrintJob if already PrintJob is created for the given Entity and active',
       @vRuleQuery       = 'Delete P
                            from #PrintJobs P
                              join PrintJobs PJ on P.EntityId = PJ.EntityId
                            where (PJ.PrintJobStatus not in (''C'', ''X'')) and
                                  (PJ.PrintJobOperation = P.PrintJobOperation);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - AutoRelease Print Jobs */
/******************************************************************************/
select @vRuleSetName        = 'PrintJobs_AutoRelease',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'AutoRelease Print Jobs',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*--------------------------------------------------------------------------------------------------------------------------------------*/
/* Update the Print job with LabelPrinterName and ReportPrinterName for Entity - Wave */
/*--------------------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update LabelPrinterName and ReportPrinterName - Wave',
       @vRuleQuery       = 'declare @vReportPrinterName TName,
                                    @vLabelPrinterName  TName;

                            /* Get ReportPrinterName based on WH */
                            select top 1 @vReportPrinterName = P.PrinterName
                            from #PrintJobs PJ
                              join vwPrinters P on (PJ.Warehouse = P.Warehouse) and (P.PrinterType = ''Report'')
                            where (P.Status = ''A'')
                            order by P.SortSeq;

                            /* Get LabelPrinterName based on WH */
                            select top 1 @vLabelPrinterName = P.Printername
                            from #PrintJobs PJ
                              join vwPrinters P on (PJ.Warehouse = P.Warehouse) and (P.PrinterType = ''Label'')
                            where (P.Status = ''A'')
                            order by P.SortSeq;

                            update PJ
                            set PJ.ReportPrinterName = case when dbo.fn_IsInList(''Report'', PJ.PrintJobType) = 1
                                                            then @vReportPrinterName else null end,
                                PJ.LabelPrinterName  = case when dbo.fn_IsInList(''Label'', PJ.PrintJobType) = 1
                                                            then @vLabelPrinterName else null end
                            from #PrintJobs PJ
                            where (PJ.EntityType = ''Wave'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA'/* Not-Applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*--------------------------------------------------------------------------------------------------------------------------------------*/
/* AutoRelease the Print job only if LabelPrinterName and ReportPrinterName are assigned for Entity - Wave */
/*--------------------------------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'AutoRelease the Print job only if LabelPrinterName and ReportPrinterName are assigned - Wave',
       @vRuleQuery       = 'Update PJ
                            set PJ.PrintJobStatus = case when (W.PrintStatus = ''ReadyToPrint'') and
                                                              (dbo.fn_IsInList(''Report'', PJ.PrintJobType) = 1) and
                                                              (PJ.ReportPrinterName is null) then ''NR''
                                                         when (W.PrintStatus = ''ReadyToPrint'') and
                                                              (dbo.fn_IsInList(''Label'', PJ.PrintJobType) = 1) and
                                                              (PJ.LabelPrinterName is null) then ''NR''
                                                         when (W.PrintStatus = ''OnHold'') then ''O''
                                                         else ''R''
                                                    end
                            from #PrintJobs PJ join Waves W on (W.WaveNo = PJ.EntityKey)
                            where (PJ.EntityType = ''Wave'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA'/* Not-Applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
