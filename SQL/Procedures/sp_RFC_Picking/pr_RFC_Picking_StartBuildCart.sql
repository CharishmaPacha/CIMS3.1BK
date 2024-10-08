/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/29  RKC     pr_RFC_Picking_StartBuildCart: Display TaskId while validating the BuildCart , if Cart is already assigned to antoher Task (CID-866)
  2019/07/11  VS      pr_RFC_Picking_StartBuildCart: When build the cart need to update the task info on Pallet (CID-766)
  2019/05/06  TK      pr_RFC_Picking_StartBuildCart: Do not add voided LPNs to cart (S2GCA-GoLive)
  2019/03/08  OK      pr_RFC_Picking_StartBuildCart: bug fix to do not build cart if task is completed (HPI-2504)
  2019/02/05  HB      pr_RFC_Picking_StartBuildCart : Added Audit Trail (HPI-2381)
                      pr_RFC_Picking_StartBuildCart: Don't consider num positions on cart if LPNs as to be auto assigned (S2GCA-CRP)
  2018/06/19  TK      pr_RFC_Picking_StartBuildCart: Changes to auto assign LPNs to cart positions (S2GCA-71)
  2017/01/12  PSK     pr_RFC_Picking_StartBuildCart:Added Dependenton field to show the value on message.(HPI-602)
  2016/11/28  PSK     pr_RFC_Picking_StartBuildCart: Changed the message.(HPI-602)
  2016/11/26  SV/TK   pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_StartBuildCart: Clearing up the earlier AlternateLPN info over the cart LPNs for the new pick (HPI-891)
  2016/11/03  ??      pr_RFC_Picking_StartBuildCart: Commented out lines between 6536 to 6556 (HPI-GoLive)
  2016/11/02  AY      pr_RFC_Picking_StartBuildCart,pr_RFC_Picking_AddCartonToCart: Disregard voided LPNs, show proper messages on voided
  2016/10/24  SV/TK   pr_RFC_Picking_GetBatchPick, pr_RFC_Picking_StartBuildCart: Clearing up the earlier AlternateLPN info over the cart LPNs for the new pick (HPI-891)
  2016/09/28  ??      pr_RFC_Picking_StartBuildCart: Modified check condition to consider TaskStatus in ('I') and (@vTaskPalletId <> @vPalletId) (HPI-GoLive)
  2016/09/27  ??      pr_RFC_Picking_StartBuildCart: Modified check condition to consider (@vPalletQuantity > 0) (HPI-GoLive)
  2016/09/26  PSK     pr_RFC_Picking_StartBuildCart: Added validation to not allow Buildcart if task is pending Replenishment(HPI-602)
  2016/09/13  AY      pr_RFC_Picking_StartBuildCart: Do not allow building if Task is awaiting replenishments (HPI-GoLive).
                      pr_RFC_Picking_StartBuildCart: Allow user to re-use cart for same Task
  2015/08/12  TK      pr_RFC_Picking_AddCartonToCart & pr_RFC_Picking_StartBuildCart:
  2015/06/10  TK      pr_RFC_Picking_StartBuildCart: Added validation
  2015/06/02  DK/TK   pr_RFC_Picking_StartBuildCart & pr_RFC_Picking_AddCartonToCart: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_StartBuildCart') is not null
  drop Procedure pr_RFC_Picking_StartBuildCart;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_StartBuildCart: This procedure validates the Scanned cart and Batch.

    @xmlInput XML Structure:
    <BuildCart>
      <Cart></Cart>
      <Batch></Batch>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
    </BuildCart>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_StartBuildCart
  (@xmlInput       xml,
   @xmlResult      xml   output)
As
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TMessage,

          @vWaveId             TRecordId,
          @vWaveType           TTypeCode,

          @vTaskId             TRecordId,
          @vTask               TRecordId,
          @vPickType           TTypeCode,
          @vTaskStatus         TStatus,
          @vTaskPalletId       TRecordId,
          @vTaskDependencyFlags TFlags,
          @vDependentOn        TDescription,
          @vDependentOnLen     TInteger,

          @vPickCart           TPallet,
          @vPalletId           TRecordId,
          @vPallet             TPallet,
          @vPalletType         TTypeCode,
          @vPalletStatus       TStatus,
          @vPalletTaskId       TRecordId,

          @vNumLPNsOnTask      TCount,
          @vNumLPNsOnCart      TCount,
          @vNumOrders          TCount,
          @vNumTempLabels      TCount,
          @vTotalCartPos       TCount,
          @vNote1              TDescription,
          @vNote2              TDescription,

          @vPalletQuantity     TQuantity,

          @vDeviceId           TDeviceId,
          @vUserId             TUserId,
          @vBusinessUnit       TBusinessUnit,
          @vActivityLogId      TRecordId,
          @vAuditId            TRecordId,
          @xmlRulesData        TXML,
          @vAutoAssignLPNs     TFlag;

  declare @ttLPNsOnTask          TEntityKeysTable,
          @ttLPNsAssignedToCart  TEntityKeysTable;

begin /* pr_RFC_Picking_StartBuildCart */
begin try

  SET NOCOUNT ON;

  /* Get the XML User inputs in to the local variables */
  select @vTask         = Record.Col.value('Batch[1]'          , 'TRecordId'),
         @vPickCart     = Record.Col.value('Cart[1]'           , 'TPallet'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]'   , 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]'         , 'TUserId'),
         @vDeviceId     = Record.Col.value('DeviceId[1]'       , 'TDeviceId')
  from @xmlInput.nodes('BuildCart') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vTask, @vPickCart, 'TaskId-Pallet',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction

  /* get the Task Details */
  select @vTaskId              = TaskId,
         @vPickType            = TaskSubType,
         @vWaveId              = WaveId,
         @vTaskStatus          = Status,
         @vTaskPalletId        = PalletId,
         @vNumOrders           = NumOrders,
         @vNumTempLabels       = NumTempLabels,
         @vTaskDependencyFlags = DependencyFlags,
         @vDependentOn         = left(DependentOn, 50)
  from Tasks
  where (TaskId       = @vTask        )and
        (BusinessUnit = @vBusinessUnit);

  select @vWaveType = BatchType
  from PickBatches
  where (RecordId = @vWaveId);

  /* Trim the DependentOn value from last comma to end */
  select @vDependentOnLen = Len(@vDependentOn) - charindex(',', Reverse(@vDependentOn)) + 1;
  select @vNote2          = substring(@vDependentOn, 0, @vDependentOnLen);

  /* get the Pallet/Cart Details */
  select @vPalletId       = PalletId,
         @vPallet         = Pallet,
         @vPalletStatus   = Status,
         @vPalletType     = PalletType,
         @vPalletQuantity = Quantity,
         @vPalletTaskId   = nullif(TaskId, 0)
  from Pallets
  where (Pallet       = @vPickCart    ) and
        (BusinessUnit = @vBusinessUnit);

  select @vTotalCartPos = count(*)
  from LPNs
  where (PalletId = @vPalletId   ) and
        (LPNType = 'A' /* Cart */);

  /* Build the data for evaluation of rules to get pickgroup */
  select @xmlRulesData = '<RootNode>' +
                           dbo.fn_XMLNode('PickType',  @vPickType) +
                           dbo.fn_XMLNode('WaveType',  @vWaveType) +
                           dbo.fn_XMLNode('WaveId',    @vWaveId)   +
                           dbo.fn_XMLNode('TaskId',    @vTaskId)   +
                           dbo.fn_XMLNode('PalletId',  @vPalletId) +
                           dbo.fn_XMLNode('PickCart',  @vPickCart) +
                         '</RootNode>'

  /* Get the valid pickGroup here to find the task  */
  exec pr_RuleSets_Evaluate 'BuildCart_AutoAssignLPNs', @xmlRulesData, @vAutoAssignLPNs output;

  /* Get the LPNs on the Task */
  insert into @ttLPNsOnTask (EntityId, EntityKey)
    select distinct L.LPNId, L.AlternateLPN
    from LPNTasks LT
      join LPNs L on LT.LPNId = L.LPNId
    where (LT.TaskId = @vTaskId) and (L.Status not in ('V' /* Voided */, 'C' /* Consumed */));

  select @vNumLPNsOnTask = count(EntityId),
         @vNumLPNsonCart = sum(case when nullif(EntityKey, '') is not null then 1 else 0 end)
  from @ttLPNsOnTask;

  /* Validations */
  if (@vTaskId is null)
    set @vMessageName = 'BuildCart_InvalidTaskId';
  else
  if (@vPalletId is null)
    set @vMessageName = 'BuildCart_InvalidCart';
  else
  if (exists (select *
              from Tasks
              where (PalletId = @vPalletId) and
                    (TaskId  <> @vTaskId  ) and
                    ((Status not in ('C', 'X'/* Completed/Canceled */)) and
                     (@vPalletQuantity > 0))))
    begin
      select @vMessageName = 'BuildCart_PalletInUseForAnotherTask',
             @vNote1       = @vPalletTaskId;
    end
  else
  if (@vPalletStatus <> 'E' /* Empty */) and (@vPalletQuantity > 0)
    set @vMessageName = 'BuildCart_InvalidCartStatus';
  else
  if (@vPalletType <> 'C' /* Picking Cart */)
    set @vMessageName = 'BuildCart_InvalidCartType';
  else
  if (@vTaskStatus not in ('O' /* OnHold */, 'N' /* Ready To Start */) or
      (@vTaskStatus in ('I') and  (@vTaskPalletId <> @vPalletId)))
    set @vMessageName = 'BuildCart_InvalidTaskStatus';
  else
  if (@vTaskPalletId is not null) and (@vTaskPalletId <> @vPalletId)
    begin
      select @vMessageName = 'TaskAssociatedWithAnotherCart';
      select @vNote1       = Pallet from Pallets where PalletId = @vTaskPalletId;
    end
  else
  if (@vTotalCartPos < @vNumLPNsOnTask) and (@vAutoAssignLPNs = 'N'/* No */)
    select @vMessageName = 'NotEnoughPositionsToBuildCart';
  else
  /* Do not allow to build the cart if there are tasks pending replenishment - need
     to make this permission based */
  if (@vTaskDependencyFlags = 'R')
    select @vMessageName = 'BuildCart_TaskPendingReplenish';

  if (@vMessageName is not null)
     goto ErrorHandler;

  /* If we are here then Pallet status must be Empty and if there is any task associated with this pallet should be
     completed or canceled and hence we need to clear Alternate LPN on cart positions and corresponding Temp LPNs if Pallet is not associated with the task */
  if (@vPalletId <> coalesce(@vTaskPalletId, ''))
    begin
      /* clear alternate LPN on temp labels, if temp labels are not present on cart */
      update TL
      set TL.AlternateLPN = null
      from LPNs TL
        join LPNs CP on (TL.LPN     = CP.AlternateLPN) and
                        (CP.LPNType = 'A'/* Cart */  )
      where (CP.PalletId = @vPalletId   ) and
            (TL.AlternateLPN is not null);

      update LPNs
      set AlternateLPN = null
      where (PalletId = @vPalletId) and
            (LPNType  = 'A' /* Cart */);
    end

  /* Assign Pallet to Task */
  update Tasks
  set PalletId = @vPalletId,
      Pallet   = @vPallet
  where (TaskId = @vTaskId);

  update Pallets
  set TaskId = @vTaskId
  where PalletId = @vPalletId;

  /* If LPNs needs to be auto assigned then add LPNs to cart positions and exit without promting next screen */
  if (@vAutoAssignLPNs = 'Y'/* Yes */)
    begin
      /* At the end of allocation, pick position will be decided and each templabel will be assigned
         as position, assign Temp LPNs to that position on the scanned Pallet */
      /* Update scanned cart position on the LPN */
      update L
      set L.AlternateLPN = PickPosition,
          L.PalletId     = @vPalletId,
          L.Pallet       = @vPallet
      output inserted.LPNId, inserted.LPN into @ttLPNsAssignedToCart(EntityId, EntityKey)
      from LPNs L
        join LPNTasks LT on (L.LPNId = LT.LPNId)
        join TaskDetails TD on (LT.TaskDetailId = TD.TaskDetailId)
      where (TD.TaskId = @vTaskId) and
            (L.Status <> 'V'/* Voided */);  -- There may be some task details that are cancelled, so consider LPN status

      /* Assign Pallet to Task */
      update Tasks
      set PalletId = @vPalletId,
          Pallet   = @vPallet
      where (TaskId = @vTaskId);

      /* Audit Trail on LPNs */
      exec pr_AuditTrail_Insert 'BuildCartAddLPN', @vUserId, null /* ActivityTimestamp */,
                                @Note1 = @vPallet, @Note2 = @vTaskId, @BusinessUnit = @vBusinessUnit,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'LPN', @ttLPNsAssignedToCart, @vBusinessUnit;

      /* Update counts on the Pallet */
      exec pr_Pallets_UpdateCount @vPalletId, @UpdateOption = '*';

      select @vMessage = dbo.fn_Messages_GetDescription('BuildCart_AllLPNsBuilt');
    end

  /* Audit Trail on Pallet */
  exec pr_AuditTrail_Insert 'BuildCart', @vUserId, null /* ActivityTimestamp */,
                            @TaskId = @vTaskId, @PalletId = @vPalletId;

  /* Build output XML result */
  set @xmlResult = (select @vPickCart       as Cart,
                           @vTaskId         as Batch,
                           @vNumLPNsonCart  as NumLPNsOnCart,
                           @vNumLPNsonTask  as NumLPNsonTask,
                           @vAutoAssignLPNs as AutoAssignLPNs,
                           @vNumOrders      as NumOrders,
                           @vNumTempLabels  as NumTempLabels,
                           @vMessage        as Message
                           for XML raw('BuildCart'), elements);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vNote2;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_StartBuildCart */

Go
