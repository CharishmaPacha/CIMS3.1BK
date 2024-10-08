/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/21  TK      pr_Picking_GetNextWaveAndTaskToPick: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_GetNextWaveAndTaskToPick') is not null
  drop Procedure pr_Picking_GetNextWaveAndTaskToPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_GetNextWaveAndTaskToPick:
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_GetNextWaveAndTaskToPick
  (@PickZone      TZoneId      = null,
   @BatchType     TTypeCode    = null,
   @PickPallet    TPallet,
   @Warehouse     TWarehouse,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @PickBatchNo   TPickBatchNo        output,
   @TaskId        TRecordId    = null output)
as
  declare @PalletId                 TRecordId,
          @vPalletType              TTypeCode,

          @vValidWaveAndTaskTypes   TVarchar,
          @xmlRulesData             TXML;

  declare @ttValidWaveAndTaskTypes  TEntityKeysTable;
begin /* pr_Picking_GetNextWaveAndTaskToPick */

  /* If both WaveNo and Task is given then we wouldn't be here, this procedure will be executed
     if Wave No or Task is not provided */

  /* Get the Pallet type */
  select @vPalletType = PalletType
  from Pallets
  where (Pallet       = @PickPallet) and
        (BusinessUnit = @BusinessUnit);

  /* Prepare XML to evaluate rules */
  select @xmlRulesData = '<RootNode>' +
                             dbo.fn_XMLNode('PalletType', @vPalletType) +
                         '</RootNode>';

  /* Find valid Wave Types to Pick based upon Pallet scanned */
  exec pr_RuleSets_Evaluate 'ValidWave&TaskTypesToPick' /* RuleSetType */, @xmlRulesData, @vValidWaveAndTaskTypes output;

  /* RuleSet would return comma separated values, convert them to dataset and insert
     into temp table for processing */
  insert into @ttValidWaveAndTaskTypes (EntityKey)
    select Value from dbo.fn_ConvertStringToDataSet(@vValidWaveAndTaskTypes, ',');

  /* if Nothing scanned other than Pallet/Cart then find the Batch Associsted the Pallet
     and then find next task */
  if (@PickPallet is not null)
    begin
    /* If there is already a batch associated with the pallet, then return it */
      select @PickBatchNo = PickBatchNo
      from Pallets
      where (Pallet       = @PickPallet) and
            (Status       in ('P' /* Picking */, 'U' /* Paused */)) and
            (BusinessUnit = @BusinessUnit) and
            (Warehouse    = @Warehouse   );

      /* if there is Wave associsted with the Pallet then find task to pick */
      if (@PickBatchNo is not null)
        select top 1 @TaskId = TaskId
        from Tasks
        where (BatchNo    = @PickBatchNo) and
              (Status     in ('I', 'N'/* In Progress, New */)) and
              (AssignedTo = @UserId or AssignedTo is null) and
              (BusinessUnit = @BusinessUnit)
        order by Status, AssignedTo desc, Priority asc;
    end

  /* Exit if next wave and task to pick are identified */
  if (@PickBatchNo is not null) and (@TaskId is not null)
    return;

  /* If the Pallet/Cart is not associated with any Wave, then return the Task with the scanned criteria */
  select top 1 @TaskId      = TaskId,
               @PickBatchNo = BatchNo
  from vwTasksToPick vwTP
    join @ttValidWaveAndTaskTypes ttWT on (vwTP.vwTP_UDF1 = ttWT.EntityKey)
  where (TaskId       = coalesce(@TaskId, TaskId)) and
        (BatchNo      = coalesce(@PickBatchNo, BatchNo)) and
        (PickZone     = coalesce(@PickZone, PickZone)) and
        (TaskStatus   = 'N') and -- in ('I', 'N'/* In Progress, New */)) and
        (TaskAssignedTo = @UserId or TaskAssignedTo is null) and
        (BusinessUnit = @BusinessUnit) and
        (Warehouse    = @Warehouse   )
  order by TaskStatus, TaskAssignedTo desc, TaskPriority asc;

end /* pr_Picking_GetNextWaveAndTaskToPick */

Go

/*------------------------------------------------------------------------------
  Proc pr_Picking_GetPickTaskForPickZone: This procedure will take input as Zone,
    Pickbacth and gives the task for that Zone
------------------------------------------------------------------------------*/
