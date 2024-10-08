/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  SK      Initial version (HA-2972)
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
  Productivity Data set:

    Rules for generating data set to display to user on screen
*******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'Productivity_DataSet';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set - to populate the data set */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'PopulateProductivityDataSet',
       @vRuleSetDescription = 'Rules to populate data set for productivity screen',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Send out all details when user request not to summarize with anything */
select @vRuleCondition   = '(~SummarizeBy~ = ''None'')',
       @vRuleDescription = 'Prod DataSet: Default',
       @vRuleQuery       = 'insert into #ProductivityDS (ProductivityId, Operation, SubOperation, JobCode, Assignment, ActivityDate,
                                                         NumAssignments, NumWaves, NumOrders, NumLocations, NumPallets, NumLPNs, NumTasks, NumPicks, NumSKUs, NumUnits,
                                                         Weight, Volume, EntityType, EntityId, EntityKey,
                                                         SKUId, SKU, LPNId, LPN, LocationId, Location, PalletId, Pallet, ReceiptId, ReceiptNumber, ReceiverId, ReceiverNumber,
                                                         OrderId, PickTicket, WaveNo, WaveId, WaveType, WaveTypeDesc, TaskId, TaskDetailId,
                                                         DayNumber, Day, DayMonth, WeekNumber, Week, MonthWeek, MonthNumber, MonthShort, Month, Year,
                                                         StartDateTime, EndDateTime, Duration, DurationInSecs, DurationInMins, DurationInHrs,
                                                         UnitsPerMin, UnitsPerHr, Comment, Status, Archived, DeviceId, UserId, UserName,
                                                         ParentRecordId, BusinessUnit, Warehouse, Ownership,
                                                         CreatedDate, ModifiedDate, CreatedBy, ModifiedBy)
                              select P.ProductivityId, P.Operation, P.SubOperation, P.JobCode, P.Assignment, P.ActivityDate,
                                     P.NumAssignments, P.NumWaves, P.NumOrders, P.NumLocations, P.NumPallets, P.NumLPNs, P.NumTasks, P.NumPicks, P.NumSKUs, P.NumUnits,
                                     P.Weight, P.Volume, P.EntityType, P.EntityId, P.EntityKey,
                                     P.SKUId, P.SKU, P.LPNId, P.LPN, P.LocationId, P.Location, P.PalletId, P.Pallet, P.ReceiptId, P.ReceiptNumber, P.ReceiverId, P.ReceiverNumber,
                                     P.OrderId, P.PickTicket, P.WaveNo, P.WaveId, P.WaveType, P.WaveTypeDesc, P.TaskId, P.TaskDetailId,
                                     P.DayNumber, P.Day, P.DayMonth, P.WeekNumber, P.Week, P.MonthWeek, P.MonthNumber, P.MonthShort, P.Month, P.Year,
                                     P.StartDateTime, P.EndDateTime, P.Duration, P.DurationInSecs, P.DurationInMins, P.DurationInHrs,
                                     P.UnitsPerMin, P.UnitsPerHr, P.Comment, P.Status, P.Archived, P.DeviceId, P.UserId, P.UserName,
                                     P.ParentRecordId, P.BusinessUnit, P.Warehouse, P.Ownership,
                                     P.CreatedDate, P.ModifiedDate, P.CreatedBy, P.ModifiedBy
                              from #ttProdIds TT
                                join vwProductivity P on TT.EntityId = P.ProductivityId
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Summarize by User only */
select @vRuleCondition   = '(~SummarizeBy~ = ''User'')',
       @vRuleDescription = 'Prod DataSet: Summarize by User',
       @vRuleQuery       = 'insert into #ProductivityDS (UserId, NumAssignments,
                                                         NumWaves, NumOrders, NumLocations, NumPallets,
                                                         NumLPNs, NumTasks, NumPicks, NumSKUs,
                                                         Archived, BusinessUnit)
                              select P.UserId, count(distinct P.ProductivityId),
                                     count(distinct AD.WaveId), count(distinct AD.OrderId), count(distinct AD.LocationId), count(distinct AD.PalletId),
                                     count(distinct AD.LPNId), count(distinct AD.TaskId), count(distinct AD.TaskDetailId), count(distinct AD.SKUId),
                                     min(P.Archived), min(P.BusinessUnit)
                             from #ttProdIds TT
                              join Productivity         P on TT.EntityId      = P.ProductivityId
                              join ProductivityDetails PD on P.ProductivityId = PD.ProductivityId
                              left join AuditDetails   AD on PD.AuditId       = AD.AuditId
                              left join SKUs            S on AD.SKUId         = S.SKUId
                             group by P.UserId;
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Updates for Summarize by User only */
select @vRuleCondition   = '(~SummarizeBy~ = ''User'')',
       @vRuleDescription = 'Prod DataSet: Update to summary by User',
       @vRuleQuery       = ';with cte_byUser(UserId, NumUnits, NumPicks, Weight, Volume, DurationInSecs)
                            as
                            (
                              select P.UserId, sum(P.NumUnits), sum(P.NumPicks), sum(P.Weight), sum(P.Volume), sum(P.DurationInSecs)
                              from #ttProdIds TT
                                join Productivity P on TT.EntityId = P.ProductivityId
                              group by P.UserId
                            )
                            update PTT
                            set PTT.NumUnits       = CTE.NumUnits,
                                PTT.NumPicks       = CTE.NumPicks,
                                PTT.Weight         = CTE.Weight,
                                PTT.Volume         = CTE.Volume,
                                PTT.DurationInSecs = CTE.DurationInSecs,
                                PTT.DurationInHrs  = (CTE.DurationInSecs/3600),
                                PTT.DurationInMins = (CTE.DurationInSecs%3600)/60
                            from #ProductivityDS PTT
                              join cte_byUser CTE on PTT.UserId = CTE.UserId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Summarize by User & Date */
select @vRuleCondition   = '(~SummarizeBy~ = ''UserDate'')',
       @vRuleDescription = 'Prod DataSet: Summarize by User and Date',
       @vRuleQuery       = 'insert into #ProductivityDS (UserId, ActivityDate, NumAssignments,
                                                         NumWaves, NumOrders, NumLocations, NumPallets,
                                                         NumLPNs, NumTasks, NumPicks, NumSKUs,
                                                         Archived, BusinessUnit)
                              select P.UserId, P.ActivityDate, count(distinct P.ProductivityId),
                                     count(distinct AD.WaveId), count(distinct AD.OrderId), count(distinct AD.LocationId), count(distinct AD.PalletId),
                                     count(distinct AD.LPNId), count(distinct AD.TaskId), count(distinct AD.TaskDetailId), count(distinct AD.SKUId),
                                     min(P.Archived), min(P.BusinessUnit)
                             from #ttProdIds TT
                              join Productivity         P on TT.EntityId      = P.ProductivityId
                              join ProductivityDetails PD on P.ProductivityId = PD.ProductivityId
                              left join AuditDetails   AD on PD.AuditId       = AD.AuditId
                              left join SKUs            S on AD.SKUId         = S.SKUId
                             group by P.UserId, P.ActivityDate;
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Updates for Summarize by User & Date */
select @vRuleCondition   = '(~SummarizeBy~ = ''UserDate'')',
       @vRuleDescription = 'Prod DataSet: Update to summary by user and date',
       @vRuleQuery       = ';with cte_byUser(UserId, ActivityDate, NumUnits, NumPicks, Weight, Volume, DurationInSecs)
                            as
                            (
                              select P.UserId, P.ActivityDate, sum(P.NumUnits), sum(P.NumPicks), sum(P.Weight), sum(P.Volume), sum(P.DurationInSecs)
                              from #ttProdIds TT
                                join Productivity P on TT.EntityId = P.ProductivityId
                              group by P.UserId, P.ActivityDate
                            )
                            update PTT
                            set PTT.NumUnits       = CTE.NumUnits,
                                PTT.NumPicks       = CTE.NumPicks,
                                PTT.Weight         = CTE.Weight,
                                PTT.Volume         = CTE.Volume,
                                PTT.DurationInSecs = CTE.DurationInSecs,
                                PTT.DurationInHrs  = (CTE.DurationInSecs/3600),
                                PTT.DurationInMins = (CTE.DurationInSecs%3600)/60
                            from #ProductivityDS PTT
                              join cte_byUser CTE on PTT.UserId = CTE.UserId and PTT.ActivityDate = CTE.ActivityDate',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Summarize by Date */
select @vRuleCondition   = '(~SummarizeBy~ = ''Date'')',
       @vRuleDescription = 'Prod DataSet: Summarize by Date',
       @vRuleQuery       = 'insert into #ProductivityDS (ActivityDate, NumAssignments,
                                                         NumWaves, NumOrders, NumLocations, NumPallets,
                                                         NumLPNs, NumTasks, NumPicks, NumSKUs,
                                                         Archived, BusinessUnit)
                              select P.ActivityDate, count(distinct P.ProductivityId),
                                     count(distinct AD.WaveId), count(distinct AD.OrderId), count(distinct AD.LocationId), count(distinct AD.PalletId),
                                     count(distinct AD.LPNId), count(distinct AD.TaskId), count(distinct AD.TaskDetailId), count(distinct AD.SKUId),
                                     min(P.Archived), min(P.BusinessUnit)
                             from #ttProdIds TT
                              join Productivity         P on TT.EntityId      = P.ProductivityId
                              join ProductivityDetails PD on P.ProductivityId = PD.ProductivityId
                              left join AuditDetails   AD on PD.AuditId       = AD.AuditId
                              left join SKUs            S on AD.SKUId         = S.SKUId
                             group by P.ActivityDate;
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;


/*----------------------------------------------------------------------------*/
/* Updates for Summarize by Date */
select @vRuleCondition   = '(~SummarizeBy~ = ''Date'')',
       @vRuleDescription = 'Prod DataSet: Update to summary by date',
       @vRuleQuery       = ';with cte_byUser(ActivityDate, NumUnits, NumPicks, Weight, Volume, DurationInSecs)
                            as
                            (
                              select P.ActivityDate, sum(P.NumUnits), sum(P.NumPicks), sum(P.Weight), sum(P.Volume), sum(P.DurationInSecs)
                              from #ttProdIds TT
                                join Productivity P on TT.EntityId = P.ProductivityId
                              group by P.ActivityDate
                            )
                            update PTT
                            set PTT.NumUnits       = CTE.NumUnits,
                                PTT.NumPicks       = CTE.NumPicks,
                                PTT.Weight         = CTE.Weight,
                                PTT.Volume         = CTE.Volume,
                                PTT.DurationInSecs = CTE.DurationInSecs,
                                PTT.DurationInHrs  = (CTE.DurationInSecs/3600),
                                PTT.DurationInMins = (CTE.DurationInSecs%3600)/60
                            from #ProductivityDS PTT
                              join cte_byUser CTE on PTT.ActivityDate = CTE.ActivityDate',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;


/*******************************************************************************
  Productivity Data set Updates:

    Common Rules for updating the data set after populating
*******************************************************************************/
select @vRuleSetType = 'Productivity_DataSetUpdates';

/*----------------------------------------------------------------------------*/
/* Rule Set - to populate the data set */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'UpdateProductivityDataSet',
       @vRuleSetDescription = 'Rules to update data set for productivity screen',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Common Updates  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Prod DataSet: Common updates',
       @vRuleQuery       = 'Update PTT
                            set PTT.Operation  = ~Operation~,
                                PTT.Warehouse  = case when PTT.Warehouse is null then ~Warehouse~ else PTT.Warehouse end,
                                PTT.Duration   = (right(''0''+cast(DurationInSecs/3600 as varchar(2)),2)+'':''+
                                                  right(''0''+cast((DurationInSecs%3600)/60 as varchar(2)),2)+'':''+
                                                  right(''0''+cast((DurationInSecs%3600)%60 as varchar(2)),2)),
                                PTT.UnitsPerHr = case when DurationInSecs <> 0 then coalesce(NumUnits, 0)/(convert(float, DurationInSecs)/3600)
                                                      else 0
                                                 end
                            from #ProductivityDS PTT',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go