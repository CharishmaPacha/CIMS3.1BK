/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/05  TK      Rules to update TDCategory2 with CartType (HA-1137)
  2019/08/31  AY      Process VAS Orders as PTS (CID-924)
  2019/08/20  TD      Category2 for RU- Consolidate picks from Reserve locations (CID-952)
  2019/07/09  AY      LB is also VAS as per client (CID-GoLive)
  2019/07/01  AY      Inactivated rules that split tasks by pick zone
  2019/06/26  VS      Corrected rule to update VAS on TD.TDCategory2 (CID-642)
  2019/06/08  AY      update TDCategories to split a PTC order > 300 units into multiple carts (CID-542)
  2019/05/30  AY      Corrected rule to update VAS on TaskDetails (CID-451)
  2019/05/29  AY      Single line Wave: Do not break up by Pick Zone (CIDUAT-Onsite)
  2019/05/28  AY      PTC Tasks are to be grouped by Order (CIDUAT-Onsite)
  2019/05/08  AY      TDCategory2: Compute with Carrier + Zone (Order/TempLabel) for PTS/PTC waves
                      TDCategory2: OrderId + LocationType + PickType for CP Waves (S2GCA-749)
  2019/04/22  TK      Separate Picks by Order pick zones (CID-265)
  2019/04/12  VS      Separate task to be created based on PickZone (CID-265)
  2019/04/12  VS      TDCategory2, TDCategory5 to be VAS Orders (CID-206)
  2018/12/09  TK      Latest rules migrated from S2G and made changes to suit for HPI (HPI-2049)
  2017/07/26  TK      Initial version
------------------------------------------------------------------------------*/

Go

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
/* Rules for : Rules to update Task Detail Categories */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateTDCategory1';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* TD Category1 is used to group taskdetails. i.e. All task details within
   a Task will ALWAYS be same TDCategory1. This is therefore defined to
   split or group Task details into separate tasks */
/******************************************************************************/
select @vRuleSetName        = 'TaskDetailUpdateCategory1',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Task Detail Category1',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Task Category 1 = Wave only for some types of Waves  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''XYZ''',
       @vRuleDescription = 'Separate out all tasks by Wave only',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory1 = OH.PickBatchNo
                            from TaskDetails TD
                              left outer join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* InActive */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Task Category 1 = Wave + PickTicket for some types of Waves  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''PTLC''',
       @vRuleDescription = 'Separate out all tasks by Wave and Pick Ticket',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory1 = OH.PickBatchNo + OH.PickTicket
                            from TaskDetails TD
                              left outer join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Task Category 1 = Wave + Pick Type by default for all Waves  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Separate out all tasks by Wave and Pick Type',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory1 = OH.PickBatchNo + TD.PickType
                            from TaskDetails TD
                              left outer join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and (TD.TDCategory1 is null) and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for TD Category2: Split tasks by Order Category as well */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateTDCategory2';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'TaskDetailUpdateCategory2',
       @vRuleSetDescription = 'Update Task Detail Category2',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Rule Condition for Replenish orders which can be split into multiple tasks based on Pick and Puawayzone */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''RU''' /* Replenish */,
       @vRuleDescription = 'Replenish Orders: Group by Pick, Putaway Zones and Replenish Class (min-max vs ondemand)',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 = dbo.fn_GetMappedValue(''CIMS'', LOC.PickingZone, ''CIMS'', ''PickZones'', ''ZoneGrouping'', ~BusinessUnit~) + ''-'' +
                                                 TD.DestZone + ''-'' + coalesce(OH.OrderCategory2, '''')
                            from TaskDetails TD
                              left outer join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                              join            Locations    LOC on (TD.LocationId = LOC.LocationId)
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;


insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition: Separate bagged/boxes orders for PTS/PTC */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'',''PTC'')',
       @vRuleDescription = 'Separate Bagged and boxed orders into separate tasks for Pick To Ship/Cart',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 = coalesce(OH.CartonGroups, '''')
                            from TaskDetails TD
                              left outer join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* For PTC, TDCategory2 will be Order Pick Zone */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTC'')',
       @vRuleDescription = 'For PTC Waves, TDCategory2 should be Order Pick zone',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 += ''-'' + dbo.fn_TaskDetails_SummarizePickZones(TD.OrderId, null, null, ''UNIQUE'')
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* For PTS, TDCategory2 will be Temp Label Pick Zone */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'For PTC Waves, TDCategory2 should be Pick zone of the picks going into cubed carton',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 += ''-'' + dbo.fn_TaskDetails_SummarizePickZones(null, TD.TempLabelId, null, ''UNIQUE'')
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* PTS Waves: Update Cart Type to TDCategory2 */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'PTS Waves: Update Cart Type to TDCategory2',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 += ''-'' + coalesce(TD.CartType, '''')
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for VAS orders: If VASCodes has a value, then it is a VAS Order, then create separate task for it */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTC'', ''PTS'')',
       @vRuleDescription = 'If VasCodes are specified, create separate task for VAS Orders',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 += ''-VAS''
                            from TaskDetails TD
                              join OrderHeaders OH on (TD.OrderId = OH.OrderId) and (coalesce(OH.VASCodes, '''') not in (''''))
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule: Single Line wave - Group tasks by Pick Group */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''SLB'')',
       @vRuleDescription = 'Single line Wave: Do not split Tasks by Pick Zone',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 = TD.PickType
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and (TDCategory2 is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule: If all else fails, then update to Empty string else we could have an infinite loop when creating tasks  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default TDCategory2 to Pick Zone',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 = LOC.PickingZone
                            from TaskDetails TD
                              join Locations LOC on (TD.LocationId = LOC.LocationId)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and (TD.TDCategory2 is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule: If all else fails, then update to Empty string else we could have an infinite loop when creating tasks  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If none of the other rules apply, then just set TDCategory2 to blank',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory2 = ''''
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and (TD.TDCategory2 is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for TD Category3: This is the criteria to sort the task details */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateTDCategory3';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'TaskDetailUpdateCategory3',
       @vRuleSetDescription = 'Update Task Detail Category3',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* For PTC, TDCategory3 will be Order Pick Zone */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTC'')',
       @vRuleDescription = 'For PTC Waves, TDCategory3 should be Order Pick zone',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory3 = dbo.fn_TaskDetails_SummarizePickZones(TD.OrderId, null, null, ''UNIQUE'')
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* For PTC, if it is large order and would be split into multiple tasks, add OrderId to TDCategory3
   so that most of the order would be together. Why 'z' - so that */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTC'')',
       @vRuleDescription = 'For PTC Waves, If there are large Orders, then group by them so it stays together',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory3 += ''z'' + OH.PickTicket
                            from TaskDetails TD
                              left outer join OrderHeaders OH on TD.OrderId = OH.OrderId
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (OH.NumUnits > 300)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* For PTS, TDCategory3 will be Temp Label Pick Zone */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'For PTC Waves, TDCategory3 should be Pick zone of the picks going into cubed carton',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory3 = dbo.fn_TaskDetails_SummarizePickZones(null, TD.TempLabelId, null, ''UNIQUE'')
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* TDCategory3 will be CartonType for cartons which are cubed as like cartons
   would most likely be in the same Task  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If details are cubed, then order by Carton Types so that like cartons end up on same task',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory3 += cast(CT.SortSeq as varchar) + ''-'' + CT.CartonType
                            from TaskDetails TD
                              join LPNs L on (TD.TempLabelId = L.LPNId)
                              join CartonTypes CT on (L.CartonType = CT.CartonType)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (coalesce(TD.TempLabel, '''') <> '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* For tasks that are not cubed, TaskCategory3 will be PickPath and FromLPN  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If details are not cubed then add PickPath to the Order',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory3 = coalesce(TD.TDCategory3, '''') + ''-'' + LOC.PickPath + ''-'' + L.LPN
                            from TaskDetails TD
                              join Locations    LOC on (TD.LocationId = LOC.LocationId)
                              join LPNs           L on (TD.LPNId      = L.LPNId)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (coalesce(TD.TempLabel, '''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for TD Category4: This is the criteria to sort the task details */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateTDCategory4';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'TaskDetailUpdateCategory4',
       @vRuleSetDescription = 'Update Task Detail Category4',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'NA' /* Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Set up TDCategory 4 if required */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = null,
       @vRuleQuery       = null,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA'/* Not-Applicable */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for TD Category5. TaskCategory5 is used as a cluster. i.e. all
   Task Details with same TDCategory5 would be added to same Task :

   TempLabel : If cubing is used and TDs are cubed
   PickTicket: When an Order is to be all in one Task
   null      : Otherwise
*/
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateTDCategory5';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'TaskDetailUpdateCategory5',
       @vRuleSetDescription = 'Update Task Detail Category5',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* TD category5: If cubed, then setup as Temp Label */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'If details are cubed, then setup by TempLabel so each Templabel will be on one Task',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory5 = TD.TempLabel
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (coalesce(TD.TempLabel, '''') <> '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* TD category5: If not cubed and Order is not to be split, then setup as OrderId  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTC'')',
       @vRuleDescription = 'If details are not cubed, then setup by Order so each Order will be in one Task',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory5 = OH.PickTicket
                            from TaskDetails TD
                              left outer join OrderHeaders OH on TD.OrderId = OH.OrderId
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (coalesce(TD.TempLabel, '''') = '''') and
                                  (OH.NumUnits <= 300)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for all Tasks  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default TDCategory5 is blank and these details may get split into multiple tasks',
       @vRuleQuery       = 'Update TD
                            set TD.TDCategory5 = ''''
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.TDCategory5 is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

Go
