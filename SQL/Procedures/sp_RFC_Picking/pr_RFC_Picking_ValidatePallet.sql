/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/05  RKC     pr_RFC_Picking_ValidatePallet: Made changes to get the Valid pallet Type based on the control var (HA-1960)
  2018/10/12  VS      pr_RFC_Picking_ValidatePallet, pr_RFC_Picking_DropPickedPallet:
  2018/04/04  RV      pr_RFC_Picking_ValidatePallet: Made changes to get the drop pallet required based upon the rules (S2G-579)
  2018/03/30  RV      pr_RFC_Picking_ValidatePallet: Made changes to get the drop pallet required based upon the rules (S2G-534)
  2017/02/20  TK      pr_RFC_Picking_ValidatePallet: Validate whether the task is associated with pallet or not if atleast one pick is completed (HPI-1369)
  2017/02/07  TK      pr_RFC_Picking_ValidatePallet: Enhanced to use it for evaluating Drop Locations as well (HPI-1369)
              SV/VM   pr_RFC_Picking_ValidatePallet: Added, used to validate the picked Pallet which needs to be dropped (HPI-854)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ValidatePallet') is not null
  drop Procedure pr_RFC_Picking_ValidatePallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ValidatePallet: Used for validate the pallet when the
  user willing to drop the picked/picking pallet.

  @xmlInput:
  <ValidateDropPallet>
    <DropPalletInfo>
      <Pallet>C001</Pallet>
      <Operation>DropPallet</Operation>
      <DeviceId>POCKET-PC</DeviceId>
      <BusinessUnit>HPI</BusinessUnit>
      <UserId>rfcAdmin</UserId>
    </DropPalletInfo>
    <DropPalletResponse>
      <Pallet></Pallet>
      <SuggestedDropZone></SuggestedDropZone>
      <SuggestedDropLocation></SuggestedDropLocation>
    </DropPalletResponse>
  </ValidateDropPallet>

------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ValidatePallet
  (@xmlInput   xml,
   @xmlResult  xml  output)
As
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,

          @Pallet                      TPallet,
          @TaskId                      TRecordId,
          @Operation                   TOperation,
          @BusinessUnit                TBusinessUnit,
          @UserId                      TUserId,
          @DeviceId                    TDeviceId,

          @vPalletId                   TPallet,
          @vValidPallet                TPallet,
          @vPalletType                 TTypeCode,
          @vPalletStatus               TStatus,
          @vValidStatusesToDrop        TControlValue,
          @vValidPalletTypesToDrop     TControlValue,

          @vPickBatchNo                TPickBatchNo,
          @vTaskBatchNo                TPickBatchNo,
          @vPickBatchId                TRecordId,
          @vBatchType                  TLookUpCode,
          @vBatchDropLoc               TLocation,
          @vWaveCategory1              TCategory,

          @vTaskId                     TRecordId,
          @vTaskType                   TTypeCode,
          @vTaskDetailId               TRecordId,

          @vDestDropLoc                TLocation,
          @vDestDropZone               TZoneId,
          @vForcePalletToDrop          TFlags,
          @vPalletToDropRequired       TControlValue,
          @vKeepPalletInfoForNextPick  TControlValue,
          @vCompletedPicksCount        TCount,
          @vControlCategory            TCategory,

          @vXMLData                    TXML,
          @vActivityLogId              TRecordId;
begin /* pr_RFC_Picking_ValidatePallet */
begin try

  SET NOCOUNT ON;

  select @Pallet       = Record.Col.value('Pallet[1]',       'TPallet'),
         @Operation    = Record.Col.value('Operation[1]',    'TOperation'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]',       'TUserId'),
         @TaskId       = Record.Col.value('TaskId[1]',       'TRecordId'),
         @DeviceId     = Record.Col.value('DeviceId[1]',     'TDeviceId')
  from @xmlInput.nodes('/ValidateDropPallet/DropPalletInfo') as Record(Col); /* We need to do more changes in RF in order to use proper XML nodes. So we will work on this later */

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @TaskId, @Pallet, 'Task-Pallet', @Operation,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  select @vPalletId     = PalletId,
         @vValidPallet  = Pallet,
         @vPalletType   = PalletType,
         @vPalletStatus = Status,
         @vPickBatchNo  = PickBatchNo,
         @vPickBatchId  = PickBatchId,
         @vTaskId       = coalesce(@TaskId, TaskId)
  from  Pallets
  where (Pallet = @Pallet) and
        (BusinessUnit = @BusinessUnit);

  /* If user is dropping from the drop Menu then there would be no taskid given, so fetch the last one for the Pallet */
  if (nullif(@vTaskId, 0) is null)
    select top 1 @vTaskId = TaskId
    from vwTaskDetails
    where (PalletId = @vPalletId) and
          (Batchno  = @vPickBatchNo) and
          (TaskStatus not in ('X'/* Canceled */))
    order by TaskStatus desc, ModifiedDate desc;

  select @vTaskBatchNo = BatchNo,
         @vTaskType    = TaskSubType
  from Tasks
  where (TaskId = @vTaskId);

  /* get the completed picks count */
  select @vCompletedPicksCount = count(*)
  from TaskDetails
  where (TaskId = @vTaskId) and
        (Status in ('C'/* Completed */));

  /* If user trying to drop pallet without completing any picks then CompletedPicksCount would be zero from above */

  /* We need to get the latest completed TaskId on that Cart/Pallet - Assumption is we are updating the BatchNo on the pallet on start picking */
  -- if (@vCompletedPicksCount > 0)
  --   select top 1 @vTaskId = TaskId
  --   from vwPickTasks
  --   where (PalletId = @vPalletId) and
  --         (BatchNo  = @vPickBatchNo) and
  --         (TaskStatus in ('C', 'I' /* Completed, InProgress */))
  --   order by  TaskId desc;

  select @vPickBatchId   = RecordId,
         @vBatchType     = BatchType,
         @vBatchDropLoc  = DropLocation,
         @vWaveCategory1 = Category1
  from PickBatches
  where (BatchNo = coalesce(@vPickBatchNo, @vTaskBatchNo));

  select @vValidStatusesToDrop       = dbo.fn_Controls_GetAsString('DropPallet', 'ValidStatuses', 'CK' /* Picking, Picked */, @BusinessUnit, @UserId),
         @vValidPalletTypesToDrop    = dbo.fn_Controls_GetAsString('DropPallet', 'ValidPalletTypes', 'PCTS' /* Picking Pallet, Picking Cart, Trolley */, @BusinessUnit, @UserId),
         @vKeepPalletInfoForNextPick = dbo.fn_Controls_GetAsString('UnitPick_SingleOrderPick', 'KeepPalletInfoForNextPick', 'N', @BusinessUnit, @UserId)

  /* Validations */
  if (coalesce(@Operation, '') = '')
    select @vMessageName = 'DropPallet_InvalidOperation';
  else
  if (coalesce(@Pallet, '') = '')
    select @vMessageName = 'PalletIsRequired';
  else
  if (@BusinessUnit is null)
    select @vMessageName = 'BusinessUnitIsInvalid';
  else
  if (@vValidPallet is null)
    select @vMessageName = 'PalletDoesNotExist';
  else
  if (@Operation = 'DropPallet') and (charindex(@vPalletStatus, @vValidStatusesToDrop) = 0) --Also we should able to drop picking status Pallets/Carts
    select @vMessageName = 'DropPallet_InvalidPalletStatus';
  else
  if (@Operation = 'DropPallet') and (@vTaskId is null) and (@vCompletedPicksCount > 0)        -- that's the whole point of this function i.e. task is completed and the user did not drop the pallet.
    select @vMessageName = 'DropPallet_NoTaskAssociatedWithThePallet';
  else
  if (@Operation = 'DropPallet') and (dbo.fn_IsInList(@vPalletType, @vValidPalletTypesToDrop) = 0) and
     (@vPalletStatus <> 'E' /* Empty */)
    select @vMessageName = 'NotaPickingPallet';
  else
  /* Cannot drop a pallet which is InProgress and assigned to different user */
  if (exists(select * from Tasks where BatchNo = @vPickBatchNo and PalletId = @vPalletId and AssignedTo <> @UserId and Status = 'I' /* InProgress */))   -- what it task is completed but task detail is in progress, which is happening due to a bug?
    select @vMessageName = 'DropPallet_TasksInProgress';

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@Operation = 'DropPallet')
    begin
      /* Build xml to evaluate Rules */
      select @vXMLData = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('PickBatchId',    @vPickBatchId) +
                              dbo.fn_XMLNode('PickBatchNo',    @vPickBatchNo) +
                              dbo.fn_XMLNode('WaveType',       @vBatchType  ) +
                              dbo.fn_XMLNode('BatchType',      @vBatchType  ) +
                              dbo.fn_XMLNode('WaveCategory1',  @vWaveCategory1) +
                              dbo.fn_XMLNode('TaskId',         @vTaskId     ) +
                              dbo.fn_XMLNode('TaskType',       @vTaskType   ) +
                              dbo.fn_XMLNode('PalletId',       @vPalletId   ) +
                              dbo.fn_XMLNode('PalletType',     @vPalletType ));

      exec pr_RuleSets_Evaluate 'ForcePalletToDrop', @vXMLData, @vForcePalletToDrop output;

      exec pr_RuleSets_Evaluate 'PickingConfigurations', @vXMLData, @vControlCategory output;

      select @vKeepPalletInfoForNextPick = dbo.fn_Controls_GetAsString(@vControlCategory, 'KeepPalletInfoForNextPick', 'N', @BusinessUnit, @UserId)

      -- we don't need another rule, ForcePalletToDrop could return 'AUTODROP' or 'SKIPDROP' for PTL wave and
      -- that could be used going forward.
      exec pr_RuleSets_Evaluate 'DropPalletRequired', @vXMLData, @vPalletToDropRequired output;

      exec pr_Picking_FindDropLocationAndZone @vPickBatchNo, @vBatchType, @vBatchDropLoc, @vTaskId, 'BatchPicking_DropPallet' /* Operation */,
                                              @BusinessUnit, @UserId, @vDestDropLoc output, @vDestDropZone output;

      /* If drop is not required to be done by user, automatically drop the picked Pallet with LPNs */
      if (@vPalletToDropRequired = 'N' /* No */)
        exec pr_RFC_Picking_DropPickedPallet @DeviceId, @UserId, @BusinessUnit, @vValidPallet, @vDestDropLoc, @vTaskId, null /* xmlResult */

      select @xmlResult = dbo.fn_XMLNode('ValidateDropPallet',
                            dbo.fn_XMLNode('DropPalletResponse',
                              dbo.fn_XMLNode('PalletId',                  @vPalletId      ) +
                              dbo.fn_XMLNode('Pallet',                    @vValidPallet   ) +
                              dbo.fn_XMLNode('TaskId',                    @vTaskId        ) +
                              dbo.fn_XMLNode('BusinessUnit',              @BusinessUnit   ) +
                              dbo.fn_XMLNode('Operation',                 @Operation      ) +
                              dbo.fn_XMLNode('SuggestedDropZone',         @vDestDropZone  ) +
                              dbo.fn_XMLNode('SuggestedDropLocation',     @vDestDropLoc   ) +
                              dbo.fn_XMLNode('ForcePalletToDrop',         @vForcePalletToDrop)+
                              dbo.fn_XMLNode('PalletToDropRequired',      @vPalletToDropRequired) +
                              dbo.fn_XMLNode('KeepPalletInfoForNextPick', @vKeepPalletInfoForNextPick)));
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Mark the end of the transaction */
  exec pr_RFLog_End @xmlResult /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult /* xmlResult */, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ValidatePallet */

Go
