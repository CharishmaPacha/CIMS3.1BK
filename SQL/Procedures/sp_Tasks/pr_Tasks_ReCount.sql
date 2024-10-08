/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/11  AY      pr_Tasks_ReCount: Estimate Number of totes for PTC/SLB (CID-UAT)
  2019/06/07  AY      pr_Tasks_ReCount: Update OrderId on Tasks if it is for only one task (CID-329)
  2018/11/06  MS      pr_Tasks_ReCount: Changes to recompute UnitsCompleted & UnitsToPick (OB2-701)
  2018/03/23  OK      pr_Tasks_ReCount: Enhanced to update the DestZone on the task based on the TaskDetails (S2G-417)
  2018/02/09  TD      pr_Tasks_ReCount:Changes to update pickgroup (S2G-218)
  2017/12/28  RV      pr_Tasks_GetHeaderLabelData:TaskCategory5 update code moved to tasks recount to update the before print labels
                        pr_Tasks_ReCount: Changes to update the production information agains the Tasks based on the UDFs (HPI-1785)
  2015/06/30  YJ/VM   pr_Tasks_ReCount, pr_Tasks_SetStatus: to summaries distinct order count (SRI-328)
  2014/09/24  TK      pr_Tasks_ReCount: Update TaskCategory1 with the Pick Area.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_ReCount') is not null
  drop Procedure pr_Tasks_ReCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_ReCount:  This will update Total Quantity, Total Innerpacks on
      the Task.
      Infuture we need to enhance this to update other fields too

------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_ReCount
  (@TaskId         TRecordId,
   @UserId         TUserId = null,
   @Status         TStatus = null output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vTaskDetailCount  TCount,
          @vTaskDestZone     TZoneId,

          @vTotalInnerPacks  TInnerPacks,
          @vTotalQuantity    TQuantity,
          @vPickArea         TUDF,
          @vOrderId          TRecordId,
          @vNumOrders        TCount,
          @vNumLPNs          TCount,
          @vNumCases         TCount,
          @vNumTempLabels    TCount,
          @vNumLocations     TCount,
          @vNumDestinations  TCount,
          @vDestZoneCount    TCount,
          @vDestZone         TZoneId,
          @vMultipleDestZones
                             TZoneId,
          @vTempLabelCount   TCount,
          @vStartLocation    TLocation,
          @vEndLocation      TLocation,
          @vStartDestination TLocation,
          @vEndDestination   TLocation,
          @vTaskCategory1    TCategory,
          @vTaskCategory2    TCategory,
          @vTaskCategory5    TCategory,
          @vRuleDataXML      TXML,
          @vBatchType        TTypeCode,
          @vTaskSubType      TTypeCode,
          @vPickGroup        TPickGroup;
begin /* pr_Tasks_ReCount */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vTaskDetailCount = DetailCount,
         @vTaskDestZone    = DestZone
  from Tasks
  where (TaskId = @TaskId);

  /* Get the counts here from task details for the given task */
  select @vTotalInnerPacks  = sum(TD.Innerpacks),
         @vTotalQuantity    = sum(TD.Quantity),
         @vNumOrders        = count(distinct TD.OrderId),
         @vNumLPNs          = count(distinct TD.LPNId),
         @vNumTempLabels    = count(distinct TD.TempLabelId),
         @vNumLocations     = count(distinct TD.LocationId),
         @vNumDestinations  = count(distinct TD.DestLocation),
         @vDestZoneCount    = count(distinct TD.DestZone),
         @vOrderId          = Min(OrderId),
         @vDestZone         = Min(TD.DestZone),
         @vStartLocation    = Min(L.Location),
         @vEndLocation      = Max(L.Location),
         @vStartDestination = Min(TD.DestLocation),
         @vEndDestination   = Max(TD.DestLocation),
         @vTaskCategory2    = Max(TD.TDCategory2),
         @vTaskCategory5    = Max(TD.TDCategory5)
  from TaskDetails TD
       left outer join Locations L on (TD.LocationId = L.LocationId)
  where (TaskId = @TaskId) and
        (TD.Status not in ('X' /* cancelled */));

  /* When TDs have multiple DestZones compute the list of Zones. Hoever
     we don't need to do this every single time as TD.Destzone doesn't change
     once created. So, only do this if not set already */
  if (@vDestZoneCount > 1) and (coalesce(@vTaskDestZone, '') = '')
    select @vMultipleDestZones =  stuff((select distinct ',' + DestZone
                                         from TaskDetails
                                         where (TaskId = @TaskId) and
                                               (DestZone is not null)
                                         for XML PATH(''), type).value('.','TVarchar'), 1, 1,'');

  /* Get the distinct count, if the row count is greater than '1' then
     we update TaskCategory1 as null else with Pick Area */
  select @vBatchType   = min(BatchType),
         @vTaskSubType = min(TaskSubType),
         @vPickGroup   = min(PickGroup)
  from vwPickTasks
  where (TaskId = @TaskId);

  /* Build the XML for record with all data required for rules */
  select @vRuleDataXML = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation', 'TaskRecount')   +
                           dbo.fn_XMLNode('WaveType',  @vBatchType)   +
                           dbo.fn_XMLNode('PickType',  @vTaskSubType) +
                           dbo.fn_XMLNode('TaskId',    @TaskId));

  /* Get the valid pickGroup here to find the task  */
  if (@vPickGroup is null)
    exec pr_RuleSets_Evaluate 'Task_PickGroup', @vRuleDataXML, @vPickGroup output;

  exec pr_RuleSets_Evaluate 'Task_TaskCategory1', @vRuleDataXML, @vTaskCategory1 output;
  exec pr_RuleSets_Evaluate 'Task_TaskCategory5', @vRuleDataXML, @vTaskCategory5 output;

  /* Temp fix, need to move to rules. For PTC/SLB, if NumTemplabels is zero, then estimate it.
     It is one per order at least and could more more depending uon the total units */
  if (coalesce(@vNumTempLabels, 0) = 0)
    select @vNumTempLabels = sum(NumTotes)
    from (select dbo.fn_MaxInt (1, ceiling(1.0 * sum(TD.Quantity) /25.0)) as NumTotes
          from TaskDetails TD
          where (TaskId = @TaskId)
          group by OrderId) T;

  /* Udpate Tasks with valid data */
  update Tasks
  set TotalInnerPacks  = case when IsTaskAllocated = 'Y' then @vTotalInnerPacks else @vTempLabelCount end,
      TotalUnits       = @vTotalQuantity,
      NumOrders        = @vNumOrders,
      NumLPNs          = @vNumLPNs,
      NumTempLabels    = @vNumTempLabels,
      NumLocations     = @vNumLocations,
      NumDestinations  = @vNumDestinations,
      OrderCount       = @vNumOrders,  -- deprecated
      TaskCategory1    = @vTaskCategory1,
      TaskCategory2    = @vTaskCategory2,
      TaskCategory5    = @vTaskCategory5,
      OrderId          = case when @vNumOrders = 1 then @vOrderId else null end,
      StartLocation    = @vStartLocation,
      EndLocation      = @vEndLocation,
      StartDestination = @vStartDestination,
      EndDestination   = @vEndDestination,
      DestZone         = case when @vDestZoneCount = 1 then @vDestZone
                              else @vMultipleDestZones
                         end,
      PickGroup        = coalesce(PickGroup, @vPickGroup)  -- would update with new PickGroup only if it were null to begin with
  where (TaskId = @TaskId);

  --exec @ReturnCode = pr_Tasks_SetStatus @TaskId, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_ReCount */

Go
