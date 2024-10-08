/*-----------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/19  OK      Create Unit picks for PTC wave even complete LPN qty is requied to process them through Packing (BK-437)
  2021/06/10  AJM/AY  Fix to update Pick Sequence (HA-2860)
  2021/04/09  VS      Do not update PickPosition while Reallocate the Wave (HA-2521)
  2020/08/06  MS      Generate Units Picks for Transfer Waves (HA-1273)
  2020/08/05  TK      Rules to update CartType (HA-1137)
  2020/07/08  TK      Fix to update pick positions properly - migrated from HPI (HA-1114)
  2020/07/03  TK      Exclude Canceled & Completed picks while computing pick positions (HA-Support)
  2020/06/30  SK      Minor change (HA-1058)
  2020/06/30  TK      Pick Position should show Shelf (HA-1039)
  2019/04/10  TK      Added rules to update PickSequence & PickType (CID-227 & 238)
  2018/12/10  TK      Added rules to update Pick Type (HPI-2049)
  2018/12/07  TK      Added rules to update pick position for PTS Waves (HPI-2049)
  2017/10/17  TK      Corrected comments and some rules (HPI-1615)
  2017/07/26  TK      Initial version
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* The following RuleSets are included in this file

TaskDtl_IsLabelGenerated
TaskDtl_UpdateStatus
TaskDtl_UpdatePickPositions
TaskDtl_UpdatePickType
TaskDtl_UpdatePickSequence
TaskDtl_UpdateCartType

*/
/******************************************************************************/

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
/* Rules to update TaskDetail.IsLabelGenerated

 *   NR - Not Required: No Label required to Print
 *   T  - Temp Label: Temp Label needs to be Generated & Printed
 *   L  - LPN Label: New LPNs needs to be Generated & Printed
*/
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_IsLabelGenerated';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Replenish Waves - No labels are needed */
/******************************************************************************/
select @vRuleSetName        = 'TaskCreation_ReplenishWavesLabelFlag',
       @vRuleSetFilter      = '~WaveType~ in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'No labels required for Replenish Waves',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Generic */
select @vRuleCondition   = null,
       @vRuleDescription = 'Replenish Waves: No Task Labels are required',
       @vRuleQuery       = 'Update TD
                            set TD.IsLabelGenerated = ''NR''
                            from TaskDetails TD
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Pick To Cart, Single Line, Overstock Pick waves don't require any labels */
/******************************************************************************/
select @vRuleSetName        = 'TaskCreation_WavesLabelFlagNotRequired',
       @vRuleSetFilter      = '~WaveType~ in (''PTC'', ''SLB'')',
       @vRuleSetDescription = 'No labels required for Pick To Cart, Single Line Waves',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Generic */
select @vRuleCondition   = null,
       @vRuleDescription = 'PTC/SLB Waves: No Task Labels are required',
       @vRuleQuery       = 'Update TD
                            set TD.IsLabelGenerated = ''NR''
                            from TaskDetails TD
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set - Pick To ship waves */
/******************************************************************************/
select @vRuleSetName        = 'TaskCreation_PickAndPackWavesLabelFlag',
       @vRuleSetFilter      = '~WaveType~ in (''PTS'')',
       @vRuleSetDescription = 'Labels to be generated for Pick to Ship',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Unit Picks need temp labels to be generated */
select @vRuleCondition   = null,
       @vRuleDescription = 'PTS Waves: Temp labels to be generated',
       @vRuleQuery       = 'Update TD
                            set TD.IsLabelGenerated = ''Y''
                            from TaskDetails TD
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.PickType in (''U'', ''L'')) and
                                  (TD.BusinessUnit = ~BusinessUnit~)' /* Generate temp Label */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Pallet Picks */
select @vRuleCondition   = null,
       @vRuleDescription = 'Pallet Picks: No Task Labels are required',
       @vRuleQuery       = 'Update TD
                            set TD.IsLabelGenerated = ''NR''
                            from TaskDetails TD
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.PickType = ''P'' /* Pallet */) and
                                  (TD.BusinessUnit = ~BusinessUnit~)' /* Not Required */,
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Task Status */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateStatus';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'TaskDetail_DefaultStatus',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Task Detail with default Status',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Replenish Orders */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''RU'', ''RP'', ''R'')',
       @vRuleDescription = 'Release all replenishments tasks',
       @vRuleQuery       = 'Update TD
                            set TD.Status = ''N''
                            from TaskDetails TD
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for other than Replenish orders */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ not in (''RU'', ''RP'', ''R'')',
       @vRuleDescription = 'Task Status on hold for other than Replenish Waves',
       @vRuleQuery       = 'Update TD
                            set TD.Status = ''O''
                            from TaskDetails TD
                            where (TD.PickBatchNo = ~WaveNo~) and (TD.TaskId = 0) and
                                  (TD.Status = ''NC'') and
                                  (TD.BusinessUnit = ~BusinessUnit~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Update Task Pick Positions */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdatePickPositions';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'TaskDtl_UpdatePickPositions',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Task Detail Pick Positions',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* For PTS Waves we establish positions on the cart. During creation of the Pick
   Tasks, we establish the level only and here we give a sequence number for each
   carton in that level. However, we shouldn't do this again on re-allocation
   so, only process where the task details whose PickPosition is a single char */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'PTS: Assign each temp label to a position for the Waves which are cubed',
       @vRuleQuery       = 'with TaskPickingPositions(TaskDetailId, PickPosition) as
                            (
                              select TD.TaskDetailId, right(''00'' + cast(dense_rank() over (partition by TD.TaskId, left(PickPosition, 1) order by left(TD.PickPosition, 1), TD.TempLabelId) as varchar(2)), 2)
                              from TaskDetails TD
                              where (coalesce(TD.TempLabelId, 0) <> 0) and
                                    (WaveId = ~WaveId~) and
                                    (Status not in (''X'', ''C'') and
                                    (len(PickPosition) = ''1'')) /* Do not update the PickPosition when we reallocate the wave */
                            )
                            update TD
                            set PickPosition = left(TD.PickPosition, 1) + TPP.PickPosition
                            from TaskDetails TD
                              join TaskPickingPositions TPP on (TD.TaskDetailId = TPP.TaskDetailId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Waves which are cubed */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'PTS: Update LPN.AlternateLPN with Pick Position',
       @vRuleQuery       = 'Update L
                            set L.AlternateLPN = TD.PickPosition
                            from LPNs L
                              join TaskDetails TD on (L.LPNId = TD.TempLabelId)
                            where (TD.WaveId = ~WaveId~) and
                                  (TD.Status not in (''X'', ''C''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Update Task Detail Pick Pick */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdatePickType';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'TaskDtl_UpdatePickType',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Task Detail Pick Type',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Waves which are cubed */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'Waves which are cubed, treat all picks as unit picks',
       @vRuleQuery       = 'Update TD
                            set TD.PickType = ''U''
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and
                                  (Status not in (''X'', ''C''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for PTC Waves */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTC'')',
       @vRuleDescription = 'For PTC, Consider all the picks as Unit picks to process them through Packing',
       @vRuleQuery       = 'Update TD
                            set TD.PickType = ''U''
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and
                                  (Status not in (''X'', ''C''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Transfer Wave: For example at HA, transfer to Contractor
   requires each carton be labeled, so the workflow is better if we do a Unit Pick
   and print label for each pick */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''XFER'')',
       @vRuleDescription = 'All Picks will be Units Picks for Transfers, to Label the cartons',
       @vRuleQuery       = 'Update TD
                            set TD.PickType = ''U''
                            from TaskDetails TD
                            where (TD.WaveId = ~WaveId~) and
                                  (TD.Status not in (''X'', ''C''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for TD Pick Sequence : This is the criteria to sort the task details when issuing picks */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdatePickSequence';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Update PickSequesnce for Replenishment details */
/******************************************************************************/
select @vRuleSetName        = 'TaskDetailUpdatePickSequence',
       @vRuleSetDescription = 'Update Task Detail Pick Sequence',
       @vRuleSetFilter      = null,
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* If Wave.PickSequence = Order, then pick by Order & then Pick Path */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~PickSequence~ in (''Order'')',
       @vRuleDescription = 'If Wave pick sequence is by Order then picks are issued by Order-PickPath',
       @vRuleQuery       = 'Update TD
                            set TD.PickSequence = concat_ws(''-'', TD.OrderId, LOC.PickPath. LOC.Location, S.SKUSortOrder, S.SKU)
                            from TaskDetails TD
                              join Locations    LOC on (TD.LocationId = LOC.LocationId)
                              join SKUs           S on (TD.SKUId      = S.SKUId)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status in (''O'', ''NC'', ''N''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Pick Sequence by default will be by PickPath-Location-SKU for Customers who use
   SKU Sort Order. So, in that case, instead of picking size L, M and S, we would
   issue pick to user for S, M, L */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule: Pick in sequence of PickPath-Location-SKUSortOrder',
       @vRuleQuery       = 'Update TD
                            set TD.PickSequence = concat_ws(''-'', LOC.PickPath, LOC.Location, S.SKUSortOrder, S.SKU, TD.OrderDetailId)
                            from TaskDetails TD
                              join Locations    LOC on (TD.LocationId = LOC.LocationId)
                              join SKUs           S on (TD.SKUId      = S.SKUId)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status in (''O'', ''NC'', ''N'')) and
                                  (TD.PickSequence is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Pick Sequence by default will be by PickPath-Location-SKU */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule: Pick in sequence of PickPath-Location-SKU',
       @vRuleQuery       = 'Update TD
                            set TD.PickSequence = concat_ws(''-'', LOC.PickPath, LOC.Location, S.SKUSortOrder, S.SKU, TD.OrderDetailId)
                            from TaskDetails TD
                              join Locations    LOC on (TD.LocationId = LOC.LocationId)
                              join SKUs           S on (TD.SKUId      = S.SKUId)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status in (''O'', ''NC'', ''N'')) and
                                  (TD.PickSequence is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Update CartType on Task Detail */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'TaskDtl_UpdateCartType';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'TaskDtl_UpdateCartType',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Task Detail Cart Type',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = null;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for PTS Waves */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ in (''PTS'')',
       @vRuleDescription = 'PTS Waves: Check if there is mapping set up for Cart Type',
       @vRuleQuery       = 'Update TD
                            set TD.CartType = nullif(dbo.fn_GetMappedValue(''CIMS'', OH.Account, ''CIMS'', ''CartType'', ''ProcessTaskDetails'', ~BusinessUnit~), OH.Account)
                            from TaskDetails TD
                              join OrderHeaders OH on (TD.OrderId = OH.OrderId)
                            where (TD.WaveId = ~WaveId~) and (TD.TaskId = 0) and
                                  (TD.Status in (''O'', ''NC'', ''N''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

Go
