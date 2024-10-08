/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/04  OK      pr_Allocation_IsValidToAddTaskDetail: changes to pass MaxTempLabels value to Rules (S2GCA-720)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_IsValidToAddTaskDetail') is not null
  drop Procedure pr_Allocation_IsValidToAddTaskDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_IsValidToAddTaskDetail: This procedure will return flag like Y - Yes
       N- No.
       This Procedure will take the LPNWeight and Volume to validate add detail to
       the existign task or create new one based on the control variable.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_IsValidToAddTaskDetail
  (@PickBatchId   TRecordId,
   @TaskId        TRecordId,
   @PickWeight    TWeight,
   @PickVolume    TVolume,
   @TaskDetails   TCount,
   @PickCases     TInnerPacks,
   @PickGrabs     TCount,
   @PickOrders    TCount,
   @TempLabels    TCount,
   @Result        TFlag output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,

          @vWaveType        TTypeCode,
          @vTaskDestZone    TZoneId,
          @vTaskType        TTypeCode,
          @vTaskSubType     TTypeCode,
          @vMaxWeight       TWeight,
          @vMaxVolume       TVolume,
          @vMaxPicks        TCount,
          @vMaxCases        TInnerPacks,
          @vMaxGrabs        TQuantity,
          @vMaxOrders       TCount,
          @vMaxTempLabels   TCount,
          @vTaskPickGroup   TPickGroup,
          @vTaskCategory3   TCategory,

          @vControlCategory TCategory,
          @xmlRulesData     TXML,
          @UserId           TUserId,
          @vBusinessUnit    TBusinessUnit;

begin /* pr_PickBatch_IsValidToAddTaskDetail */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @Result       = 'N';

  /* Get Warehouse and WaveType here */
  select @vWaveType     = BatchType,
         @vBusinessUnit = BusinessUnit
  from PickBatches
  where (RecordId = @PickBatchId);

  /* Get the task information */
  select @vTaskType      = TaskType,
         @vTaskSubType   = TaskSubType,
         @vTaskDestZone  = DestZone,
         @vTaskPickGroup = PickGroup,
         @vTaskCategory3 = TaskCategory3
  from Tasks
  where (TaskId = @TaskId);

  /* Using OrderCategory to determine the TaskConfigs is not right here. i think We need to have a different PickBatchGroup for PTS-SmallOrders. So that based on the PickBatchGroup
     we can return valid ControlCategory from Rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('WaveType',            @vWaveType) +
                           dbo.fn_XMLNode('TaskCategory3',       @vTaskCategory3));

  exec pr_RuleSets_Evaluate 'Allocation_TaskConfigurations', @xmlRulesData, @vControlCategory output;

  /* Get MaxWeight and MaxVolume for Controls here */
  select @vMaxWeight = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxWeight', 500, @vBusinessUnit, @UserId),
         @vMaxVolume = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxVolume', 90,  @vBusinessUnit, @UserId),
         @vMaxPicks  = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxPicks',  150, @vBusinessUnit, @UserId),
         @vMaxCases  = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxCases',  20,  @vBusinessUnit, @UserId),

         @vMaxGrabs  = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxGrabs',  200, @vBusinessUnit, @UserId),
         @vMaxOrders     = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxOrders',      50, @vBusinessUnit, @UserId),
         @vMaxTempLabels = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'MaxTempLabels', 100, @vBusinessUnit, @UserId);

  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('WaveType',       @vWaveType      ) +

                           dbo.fn_XMLNode('TaskType',       @vTaskType      ) +
                           dbo.fn_XMLNode('TaskSubType',    @vTaskSubType   ) +
                           dbo.fn_XMLNode('DestZone',       @vTaskDestZone  ) +
                           dbo.fn_XMLNode('PickGroup',      @vTaskPickGroup ) +
                           dbo.fn_XMLNode('TaskCategory3',  @vTaskCategory3 ) +

                           dbo.fn_XMLNode('TaskMaxWeight',  @vMaxWeight     ) +
                           dbo.fn_XMLNode('TaskMaxVolume',  @vMaxVolume     ) +
                           dbo.fn_XMLNode('TaskMaxCases',   @vMaxCases      ) +
                           dbo.fn_XMLNode('TaskMaxGrabs',   @vMaxGrabs      ) +
                           dbo.fn_XMLNode('TaskMaxOrders',  @vMaxOrders     ) +
                           dbo.fn_XMLNode('MaxTempLabels',  @vMaxTempLabels ) +

                           dbo.fn_XMLNode('PickWeight',     @PickWeight     ) +
                           dbo.fn_XMLNode('PickVolume',     @PickVolume     ) +
                           dbo.fn_XMLNode('PickCases',      @PickCases      ) +
                           dbo.fn_XMLNode('PickGrabs',      @PickGrabs      ) +
                           dbo.fn_XMLNode('PickOrders',     @PickOrders     ) +
                           dbo.fn_XMLNode('TempLabelCount', @TempLabels     ));

  exec pr_RuleSets_Evaluate 'Task_IsValidToAddTaskDetail', @xmlRulesData, @Result output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_IsValidToAddTaskDetail */

Go
