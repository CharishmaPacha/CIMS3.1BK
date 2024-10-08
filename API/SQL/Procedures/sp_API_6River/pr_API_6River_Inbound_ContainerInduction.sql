/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/07  TK      pr_API_6River_Inbound_ContainerInduction: Update TaskId on ship carton (CID-1690)
  2020/11/28  TK      pr_API_6River_Inbound_ContainerInduction: Fixed issues while processing the response received from 6Rvier (CID-1542)
  2020/11/06  TK      pr_API_6River_Inbound_ContainerInduction & pr_API_6River_ProcessInboundTransactions:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_ContainerInduction') is not null
  drop Procedure pr_API_6River_Inbound_ContainerInduction;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_ContainerInduction: When a container has been added to the
   cart in 6 River, we would get a container inducted message indicating which
   container has been added to which cart. The procedure takes all the task
   details of the given container and creates a new task or adds to an existing
   task of the wave.
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_ContainerInduction
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vRawInput               TVarchar,

          @vPalletId               TRecordId,
          @vPallet                 TPallet,

          @vLPNId                  TRecordId,
          @vLPN                    TLPN,

          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vOwnership              TOwnership,
          @vWarehouse              TWarehouse,
          @vPriority               TPriority,
          @vPickMethod             TPickMethod,
          @vTaskId                 TRecordId,
          @vTaskSubType            TTypeCode,
          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId;

  declare @ttPalletsToRecalc       TRecountKeysTable;
begin /* pr_API_6River_Inbound_ContainerInduction */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Transaction Info */
  select @vRawInput     = RawInput,
         @vBusinessUnit = BusinessUnit
  from APIInboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Read input JSON data & extract necessary info */
  select @vPallet = json_value(@vRawInput, '$.induct.deviceID'),
         @vLPN    = json_value(@vRawInput, '$.container.containerID'),
         @vUserId = json_value(@vRawInput, '$.induct.userID');

  /* Get the confirmed picks info into temp table from JSON data */
  select * into #PicksInfo
  from openjson(@vRawInput, '$.picks')
  with (TaskDetailId          TVarchar     '$.pickID',
        UnitsToPick           TInteger     '$.eachQuantity',
        SourceLocation        TLocation    '$.sourceLocation');

  /* Get the Pallet info */
  if (@vPallet is not null)
    select @vPalletId = PalletId
    from Pallets
    where (Pallet = @vPallet) and (BusinessUnit = @vBusinessUnit);

  /* Get LPN info */
  if (@vLPN is not null)
    select @vLPNId = LPNId
    from LPNs
    where (LPN = @vLPN) and (BusinessUnit = @vBusinessUnit);

  /* Validations */
  if (@vLPN is null)
    set @vMessageName = 'LPNIsRequired';
  else
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vPallet is null)
    set @vMessageName = 'PalletIsRequired';
  else
  if (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get required info to task the task details */
  select top 1 @vTaskSubType = TD.PickType,
               @vWaveId      = W.WaveId,
               @vWaveNo      = W.WaveNo,
               @vWarehouse   = W.Warehouse,
               @vOwnership   = W.Ownership,
               @vPriority    = W.Priority,
               @vPickMethod  = W.PickMethod
  from TaskDetails TD
    join #PicksInfo PI on (TD.TaskDetailId = PI.TaskDetailId)
    join Waves W on (TD.WaveId = W.WaveId);

  /* check if there is already task that is associated with Pallet */
  select @vTaskId = TaskId
  from Tasks
  where (PalletId = @vPalletId) and
        (Status   = 'I' /* In-Progress */);

  /* If there is no active task then create new task */
  if (@vTaskId is null)
    exec pr_Tasks_Add 'PB',                    /* PickBatch  */
                      @vTaskSubType,           /* Task Type  */
                      null,                    /* TaskDesc */
                      'N',                     /* Status */
                      0,                       /* DetailCount */
                      0,                       /* CompletedCount */
                      @vWaveId,
                      @vWaveNo,
                      null,                    /* PickZone */
                      null,                    /* PutawayZone */
                      @vWarehouse,
                      @vPriority,              /* Priority */
                      null,                    /* scheduleddate */
                      'Y',                     /* IsTaskAllocated */
                      @vBusinessUnit,
                      @vOwnership,
                      @vTaskId output,
                      @CreatedBy = @vUserId;

  /* Update TaskId on Task Details */
  update TD
  set TaskId = @vTaskId
  from TaskDetails TD
    join #PicksInfo PI on (TD.TaskDetailId = PI.TaskDetailId);

  /* Confirm Inventory reservation for the tasks which are released */
  exec pr_Tasks_ConfirmReservation default, @vTaskId, null/* Batch No */, @vBusinessUnit, @vUserId;

  /* Update Task Id on ship carton. This is needed to handle short picks if there are any */
  update LPNs
  set TaskId = @vTaskId
  where (LPNId = @vLPNId) and
        (LPNType = 'S' /* Ship Carton */);

  /* Update PalletId on tasks and mark task status to In-Progress */
  update Tasks
  set Status    = 'I' /* InProgress */,
      PalletId  = @vPalletId,
      Pallet    = @vPallet,
      PickGroup = @vPickMethod
  where (TaskId = @vTaskId);

  /* Mark task details status to In-Progress */
  update TD
  set Status = 'I' /* InProgress */
  from TaskDetails TD
    join #PicksInfo PI on (TD.TaskDetailId = PI.TaskDetailId)
  where (Status in ('O', 'N' /* OnHold, Ready To Start */));

  /* Add Ship Carton/Tote to Cart/Pallet */
  update L
  set PalletId = @vPalletId,
      Pallet   = @vPallet
  output inserted.PalletId into @ttPalletsToRecalc (EntityId)
  from LPNs L
    join TaskDetails TD on (L.LPNId = TD.TempLabelId)
    join #PicksInfo  PI on (TD.TaskDetailId = PI.TaskDetailId)
  where (TD.TaskId = @vTaskId);

  /* Recount task to update count on it */
  exec pr_Tasks_Recount @vTaskId;

  /* Recalc Pallets */
  exec pr_Pallets_Recalculate @ttPalletsToRecalc, '$C' /* Counts only */, @vBusinessUnit, @vUserId

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Inbound_ContainerInduction */

Go
