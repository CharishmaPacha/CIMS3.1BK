/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/23  TK      pr_API_6River_Inbound_ContainerPickComplete: Update PickGroup as CIMSRF-<PickType> for short picks (CID-1787)
  2021/04/13  TD      pr_API_6River_Inbound_ContainerPickComplete: Get the TaskId with fullQualified name.
  2021/03/05  TK      pr_API_6River_Inbound_ContainerPickComplete: Changes to create new tasks for short picks (CID-1723)
  pr_API_6River_Inbound_ContainerPickComplete: Changes to update PickGroup on shprt picks (CID-1672)
  2021/01/28  TK      pr_API_6River_Inbound_ContainerPickComplete: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_ContainerPickComplete') is not null
  drop Procedure pr_API_6River_Inbound_ContainerPickComplete;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_ContainerPickComplete: When container pick complete message is received
    system will mark the ship carton/tote as picked, computes order & wave statuses
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_ContainerPickComplete
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vErrorMsg                    TMessage,
          @vTranCount                   TCount,

          @vRawInput                    TVarchar,

          @vToLPNId                     TRecordId,
          @vToLPN                       TLPN,

          @vOrderId                     TRecordId,
          @vWaveId                      TRecordId,
          @vWaveNo                      TWaveNo,
          @vWaveType                    TTypeCode,
          @vWaveWH                      TWarehouse,

          @vOldTaskId                   TRecordId,
          @vPickType                    TTypeCode,
          @vTemplabelId                 TRecordId,

          @vUserId                      TUserId,
          @vBusinessUnit                TBusinessUnit,

          @xmlRulesData                 TXML;

  declare @ttTaskDetailsInfo            TTaskDetailsInfoTable,
          @ttTasksToRelease             TEntityKeysTable,
          @ttWavesToUpdate              TEntityKeysTable;
begin /* pr_API_6River_Inbound_ContainerPickComplete */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTranCount   = @@trancount;

  if (@vTranCount = 0) begin transaction;

  /* Prepare Hash table */
  select * into #PicksFromRawInput from @ttTaskDetailsInfo;

  /* Get Transaction Info */
  select @vRawInput     = RawInput,
         @vBusinessUnit = BusinessUnit
  from APIInboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Read input JSON data & extract necessary info */
  select @vToLPN = json_value(@vRawInput, '$.container.containerID');

  /* Get the confirmed picks info into temp table from JSON data */
  /* If nothing is picked against a pick then we will not have captured identifiers */
  insert into #PicksFromRawInput (TaskDetailId, TDQuantity, QtyPicked, FromLocation, CoO)
    select TaskDetailId, UnitsToPick, coalesce(CapturedUnits, UnitsPicked), SourceLocation, CoO
    from openjson(@vRawInput, '$.picks')
    with (TaskDetailId          TVarchar     '$.pickID',
          UnitsToPick           TInteger     '$.eachQuantity',
          UnitsPicked           TInteger     '$.pickedQuantity',
          SourceLocation        TLocation    '$.sourceLocation',
          capturedIdentifiers   nvarchar(max) as JSON)
    outer apply openjson(capturedIdentifiers)
    with (CoO             TVarchar     '$.COO',
          UPC             TUPC         '$.UPC',
          CapturedUnits   TInteger     '$.quantity')
    order by TaskDetailId;

  /* Get LPN info */
  select @vToLPNId = LPNId,
         @vOrderId = OrderId
  from LPNs
  where (LPN = @vToLPN) and (BusinessUnit = @vBusinessUnit);

  /* Get Order info */
  select @vWaveId = PickBatchId,
         @vWaveNo = PickBatchNo
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get Wave info */
  select @vWaveType = WaveType,
         @vWaveWH   = Warehouse
  from Waves
  where (WaveId = @vWaveId);

  /* Update LPN Status as picked
     For PTC & SLB waves inventory will be picked into totes so mark them as picked
     but for PTS inventory will be picked into cubed cartons mark it as picked only if all the details are reserved */
  if not exists (select * from LPNDetails where LPNId = @vToLPNId and OnhandStatus = 'U' /* Unavailable */)
    update L
    set Status = 'K' /* Picked */
    from LPNs L
    where (L.LPNId = @vToLPNId);

  /* For PTS waves */
  if (@vWaveType = 'PTS')
    begin
      /* For PTS update taskid with '0' and PickGroup to 'CIMSRF%' on the picks that are not yet completed or not yet tasked for the
         the ship carton that is dropped so that new task will be created and all necessary updates are done so that those picks can be completed using RF */
      update TD
      set @vOldTaskId = case when TaskId > 0 then TaskId end,
          TaskId      = 0,
          Status      = case when Status = 'I' then 'O' /* On-Hold */ else Status end,
          PickGroup   = 'CIMSRF-' + PickType,
          TDCategory2 = TDCategory2 + '-' + TempLabel
      from TaskDetails TD
      where (TempLabelId = @vToLPNId) and
            (TD.Status in ('I', 'O' /* In-Progress */));  -- There is a reson to include TDs with On-Hold status here because we will not export the picks from Reserve locations to 6River to they will be still On-Hold with TaskId as '0'

      /* If there are no open picks then goto UpdateCounts */
      if (@@rowcount = 0) goto UpdateCounts;

      /* Invoke procedure to create new pick task(s) */
      exec pr_Allocation_CreatePickTasks_PTS @vWaveId, 'ContainerShortPicks' /* Operation */, @vWaveWH, @vBusinessUnit, @vUserId;

      /* Get the newly created tasks to release them */
      insert into @ttTasksToRelease (EntityId) select distinct TaskId from TaskDetails where TempLabelId = @vToLPNId and Status = 'O' /* OnHold */
    end
  else
  /* For PTC & SLB Waves */
  if (@vWaveType in ('PTC', 'SLB'))
    begin
      /* For PTC & SLB update taskid with '0' and PickGroup to 'CIMSRF%' on the picks that are not yet completed so that
         new task will be created and all necessary updates are done so that those picks can be completed using RF */
      update TD
      set @vOldTaskId = TD.TaskId,
          TaskId      = 0,
          Status      = case when Status = 'I' then 'O' /* On-Hold */ else Status end,
          PickGroup   = 'CIMSRF-' + TD.PickType,
          TDCategory2 = TDCategory2 + '-' + cast(@vOldTaskId as varchar)
      from TaskDetails TD
        join #PicksFromRawInput PRI on (PRI.TaskDetailId = TD.TaskDetailId) and  -- For PTC & SLB waves, there may many picks that are inducted to different containers so consider only the picks that are inducted to dropped container, i,e. the picks in RawData
                                       (PRI.TDQuantity <> PRI.QtyPicked)
      where (TD.Status = 'I' /* In-Progress */);

      /* If there are no open picks then goto UpdateCounts */
      if (@@rowcount = 0) goto UpdateCounts;

      /* Invoke procedure to create new pick task(s) */
      exec pr_Allocation_CreatePickTasks @vWaveId, 'ContainerShortPicks' /* Operation */, @vWaveWH, @vBusinessUnit, @vUserId

      /* Get the newly created tasks to release them */
      insert into @ttTasksToRelease (EntityId)
        select distinct TD.TaskId
        from TaskDetails TD
          join #PicksFromRawInput PRI on (PRI.TaskDetailId = TD.TaskDetailId)
        where (TD.Status = 'O' /* On-Hold */);
    end

  /* Invoke proc to release tasks */
  if exists (select * from @ttTasksToRelease)
    exec pr_Tasks_Release @ttTasksToRelease, @BusinessUnit = @vBusinessUnit, @UserId = @vUserId;

  /* If new task is created and there are no more picks associated with old task then delete it */
  delete T
  from Tasks T
    left outer join TaskDetails TD on (TD.TaskId = T.TaskId)
  where (T.TaskId = @vOldTaskId) and
        (TD.TaskDetailId is null);

  /* If the task is not deleted then there may be more picks associated with it, so recount & set status */
  if (@@rowcount = 0) and (@vOldTaskId is not null)
    begin
      exec pr_Tasks_ReCount @vOldTaskId, @vUserId;
      exec pr_Tasks_SetStatus @vOldTaskId, @vUserId;
    end

UpdateCounts:
  /* Set Order Status */
  exec pr_OrderHeaders_SetStatus @vOrderId;

  /* Recount Wave */
  insert into @ttWavesToUpdate (EntityId, EntityKey) select @vWaveId, @vWaveNo;
  exec pr_PickBatch_Recalculate @ttWavesToUpdate, '$CS', @vUserId, @vBusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vTranCount = 0) commit transaction;
end try
begin catch
  if (@vTranCount = 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Inbound_ContainerPickComplete */

Go
