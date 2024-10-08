/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/27  VS      pr_Waves_Action_Cancel: Cannot cancel the wave if wave is allocted (HA-3099)
  2021/08/18  VS      pr_PickBatch_Cancel, pr_PickBatch_Modify, pr_PickBatch_RemoveOrder, pr_PickBatch_RemoveOrders,
                      pr_Waves_Action_Cancel, pr_Waves_RemoveOrders: Pass the operation to remove the Orders from Wave (BK-475)
  2021/06/17  RKC     pr_PickBatch_RemoveOrders: Cancel the batch if No of orders on batch is zero, and if user confirms to cancel the batch
                       pr_PickBatch_Cancel, pr_Waves_Action_Cancel: Changed the controlValue for ValidCancelBatchStatuses (CIMSV3-1508)
  2020/12/16  MS      pr_Waves_Action_Cancel: Bug fix to get recordid (HA-1795)
  2020/09/04  VS      pr_PickBatch_Modify, pr_Waves_Action_CancelWave: Made changes to Cancel the Wave based upon TDCount (CIMSV3-1078)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_Cancel') is not null
  drop Procedure pr_Waves_Action_Cancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_Cancel: Based upon TaskDetails count will cancel the wave
    immediately or defer for later
    Ex: TD.Count < 50 will cancel immediately
        TD.Count >= 50 will defer cancel
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_Cancel
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,

          @vWaveId                     TRecordId,
          @vWaveNo                     TWaveNo,
          @vxmlRulesData               TXML,
          @vOperation                  TOperation,
          @ttDeferWavesToCancel        TRecountKeysTable;
begin /* pr_Waves_Action_Cancel */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordsUpdated = 0,
         @vRecordId       = 0,
         @vOperation      = 'CancelWave',
         @vAuditActivity  = 'AT_DeferCancelWave';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /*----------- Remove ineligible records -----------*/
  /* Get all the required info from Waves for validations to avoid hitting the Waves
     table again and again */
  select W.WaveId, W.WaveNo, W.WaveType, cast(W.Status as varchar(30)) as WaveStatus,
  case when (W.Status = 'X')                                 then 'CancelWave_AlreadyCanceled'
       when (W.Status in ('S', 'D'))                         then 'CancelWave_AlreadyShippedOrCompleted'
       when (W.UnitsAssigned > 0)                            then 'CancelWave_UnallocateUnitsFirst'
       when (W.AllocateFlags in ('I' /* In process */))      then 'CancelWave_AllocationInProcess'
       when (dbo.fn_IsInList(W.Status,
               dbo.fn_Controls_GetAsString('CancelWave_' + W.WaveType, 'ValidStatuses', 'NBLERPUKACX',
                                           @BusinessUnit, @UserId)) = 0)
                                                             then 'CancelWave_InvalidStatus'
       when (W.Status in ('E', 'R')) and
            (dbo.fn_Permissions_IsAllowed(@UserId, 'Waves.Pri.CancelReleasedWave') <> '1')
                                                             then 'CancelWave_AlreadyReleased'
  end ErrorMessage
  into #InvalidWaves
  from #ttSelectedEntities SE join Waves W on (SE.EntityId = W.WaveId);

  /* Get the status description for the error message */
  update #InvalidWaves
  set WaveStatus = dbo.fn_Status_GetDescription('Wave', WaveStatus, @BusinessUnit);

  /* Exclude the Waves that are invalid */
  delete from SE
  output 'E', IW.WaveId, IW.WaveNo, IW.ErrorMessage, IW.WaveStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE join #InvalidWaves IW on SE.EntityId = IW.WaveId
  where (IW.ErrorMessage is not null);

  /*----------- Process eligible records -----------*/

  /* Load remaining valid Waves info to temp table to check whether the wave has more than 50 pick tasks
    Some waves may be processed in back ground and some immediately, so we need a flag to
    keep track of the same */
  select RecordId, EntityId, EntityKey, 'N' as BackgroundProcessFlag into #WavesToCancel from #ttSelectedEntities;

  /* Apply rules to determine if selected waves should be canceled immediately or defered */
  exec pr_RuleSets_ExecuteAllRules 'Wave_DeferCancelWave' /* RuleSetType */, @vxmlRulesData, @BusinessUnit;

  /* Insert Waves info which are to be deferred */
  insert into @ttDeferWavesToCancel (EntityId, EntityKey)
    select EntityId, EntityKey
    from #WavesToCancel
    where (BackgroundProcessFlag = 'Y');

  if (exists(select * from @ttDeferWavesToCancel))
    begin
      /* invoke ExecuteInBackGroup to defer Cancel Wave */
      exec pr_Entities_ExecuteInBackGround 'Wave', null, null /* WaveNo */, 'XI'/* ProcessCode - Cancel in Process */,
                                            @@ProcId, @vOperation, @BusinessUnit, @ttDeferWavesToCancel;

      /* Update Status for all Waves that are deferred */
      update W
      set Status       = 'XI',
          ModifiedBy   = @UserId,
          ModifiedDate = current_timestamp
      from Waves W
        join @ttDeferWavesToCancel DWTC on (W.WaveId = DWTC.EntityId);

      /* report deferred waves back to user */
      insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
        select 'I', DWTC.EntityId, DWTC.EntityKey, 'WaveCancel_Deferred'
        from @ttDeferWavesToCancel DWTC;

     /* Insert Defer Wave Audit Trail */
     insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
       select distinct 'Wave', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
              dbo.fn_Messages_Build(@vAuditActivity, EntityKey, null, null, null, null) /* Comment */
       from @ttDeferWavesToCancel;

     /* Insert records into AT */
     exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;
    end

  /* Cancel the remaining waves which are to be processed immediately */
  select @vRecordId = 0;

  /* Loop through and cancel all the Waves one by one */
  while (exists(select * from #WavesToCancel where RecordId > @vRecordId and (BackgroundProcessFlag = 'N')))
    begin
      /* select the next wave to cancel */
      select top 1 @vWaveId   = EntityId,
                   @vWaveNo   = EntityKey,
                   @vRecordId = RecordId
      from #WavesToCancel
      where (RecordId > @vRecordId) and (BackgroundProcessFlag = 'N')
      order by RecordId;

      /* AT is created by this proc, so don't need to do it here */
      exec pr_Waves_Cancel @vWaveId, @vOperation, @BusinessUnit, @UserId;

      set @vRecordsUpdated = @vRecordsUpdated + 1;
    end

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_Cancel */

Go
