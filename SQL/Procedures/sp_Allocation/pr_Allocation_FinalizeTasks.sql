/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/05  TK      pr_Allocation_CartCubing_FindPositionToAddCarton, pr_Allocation_CreatePickTasks_PTS,
                      pr_Allocation_ProcessTaskDetails & pr_Allocation_AddDetailsToExistingTask:
                        Changes to use CartType that is defined in rules (HA-1137)
                      pr_Allocation_FinalizeTasks: Removed unnecessary code as updating dependices is being
                        done in pr_Allocation_UpdateWaveDependencies (HA-1211)
  2019/05/18  MS      pr_Allocation_FinalizeTasks: Changes to update TaskCategories on Tasks for PTS Wave (CID-367)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_FinalizeTasks') is not null
  drop Procedure pr_Allocation_FinalizeTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_FinalizeTasks: After Tasks are created, do the
    necessary finalization steps i.e. RecalcCounts, Task updates
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_FinalizeTasks
  (@TasksToFinailize      TRecountKeysTable readonly,
   @WaveId                TRecordId = null,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vMessage                TMessage,

          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vWaveType               TTypeCode,

          @xmlRulesData            TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* capture wave info */
  select @vWaveId   = RecordId,
         @vWaveNo   = BatchNo,
         @vWaveType = BatchType
  from PickBatches
  where (RecordId = @WaveId);

  /* Build the rules data */
  select @xmlRulesData = (select @vWaveId    as WaveId,
                                 @vWaveNo    as WaveNo,
                                 @vWaveType  as WaveType
                          for xml raw('RootNode'), elements xsinil);

  /* Evaulate Rules & Update task detail categories */
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdatePickPositions', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'Task_UpdatePriority', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'Task_UpdateCategories', @xmlRulesData;

  /* Update the counts on all the tasks */
  exec pr_Tasks_Recalculate @TasksToFinailize, 'CS' /* Counts & Status */, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_FinalizeTasks */

Go
