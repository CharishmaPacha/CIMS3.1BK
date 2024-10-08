/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/16  TK      pr_Allocation_ProcessTaskDetails: Changes to update ExportStatus on Task Details (CID-1498)
  2020/08/05  TK      pr_Allocation_CartCubing_FindPositionToAddCarton, pr_Allocation_CreatePickTasks_PTS,
                      pr_Allocation_ProcessTaskDetails & pr_Allocation_AddDetailsToExistingTask:
                        Changes to use CartType that is defined in rules (HA-1137)
                      pr_Allocation_FinalizeTasks: Removed unnecessary code as updating dependices is being
                        done in pr_Allocation_UpdateWaveDependencies (HA-1211)
  2020/05/13  TK      pr_Allocation_CreateConsolidatedPT: Code Revamp
                      pr_Allocation_ProcessTaskDetails: Migrated from CID (HA-86)
  2019/01/30  RIA     pr_Allocation_ProcessTaskDetails: Added PickSequence to pass it in XML (OB2-796)
  2017/07/26  TK      pr_Allocation_ProcessTaskDetails: Enhanced to use new methodology to execute rules (HPI-1615)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_ProcessTaskDetails') is not null
  drop Procedure pr_Allocation_ProcessTaskDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_ProcessTaskDetails: Once task details are created, Update
   the Task Categories and other information before the Details are grouped into
   actual Tasks.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_ProcessTaskDetails
  (@WaveId                TRecordId,
   @Operation             TOperation = null,
   @Warehouse             TWarehouse,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage,
          @vDebug            TFlags,

          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo,
          @vWaveType         TTypeCode,
          @vSplitOrder       TControlValue,
          @vOwnership        TOwnership,
          @vControlCategory  TCategory,
          @vWavePickSequence TPickSequence,
          @vWavePickMethod   TPickMethod,

          @xmlRulesData      TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null;

  /* Get Wave Details */
  select @vWaveId           = RecordId,
         @vWaveNo           = BatchNo,
         @vWaveType         = BatchType,
         @vControlCategory  = 'PickBatch_' + BatchType,
         @vOwnership        = Ownership,
         @vWavePickSequence = PickSequence,
         @vWavePickMethod   = PickMethod
  from PickBatches
  where (RecordId = @WaveId);

  /* Get default Task status from controls here */
  select @vSplitOrder  = dbo.fn_Controls_GetAsString (@vControlCategory, 'Task_SplitOrder',   'Y' /* Yes */,     @BusinessUnit, null /* UserId */);

  /* Build the rules data */
  select @xmlRulesData = (select @vWaveId           as WaveId,
                                 @vWaveNo           as WaveNo,
                                 @vWaveType         as WaveType,
                                 @BusinessUnit      as BusinessUnit,
                                 @Operation         as Operation,
                                 @vSplitOrder       as SplitOrder,
                                 @vWavePickSequence as PickSequence,
                                 @vWavePickMethod   as WavePickMethod
                          for xml raw('RootNode'), elements xsinil);

  /* Evaluate Rules & Update task detail categories */
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdatePickType',     @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateCartType',     @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_IsLabelGenerated',   @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdatePackingGroup', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDCategory1',  @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDCategory2',  @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDCategory3',  @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDCategory4',  @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDCategory5',  @xmlRulesData;

  /* Evaluate Rules to execute Merge Criteria on TDs */
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDMergeCriteria1', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDMergeCriteria2', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDMergeCriteria3', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDMergeCriteria4', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateTDMergeCriteria5', @xmlRulesData;

  /* Evaluate Rules & Update PickSequence and ExportStatus on task details */
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdatePickSequence', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateExportStatus', @xmlRulesData;

  /* This should be done last to mark that the Task Detail processing is complete.
     Until this point, the task detail is in NC status */
  exec pr_RuleSets_ExecuteRules 'TaskDtl_UpdateStatus', @xmlRulesData;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_ProcessTaskDetails */

Go
