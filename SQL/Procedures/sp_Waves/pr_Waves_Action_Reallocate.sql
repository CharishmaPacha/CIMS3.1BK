/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/02  AJM     pr_Waves_Action_Reallocate : Initial Revision (CIMSV3-1474)
  2021/06/14  AJM     pr_Waves_Action_Reallocate : Initial Revision (CIMSV3-1474)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_Reallocate') is not null
  drop Procedure pr_Waves_Action_Reallocate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_Reallocate: This procedure used to Reallocate the waves
    specified in the input table param
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_Reallocate
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TDescription,
          @vRecordId                    TRecordId,
          /* Audit & Response */
          @vAuditActivity               TActivityType,
          @ttAuditTrailInfo             TAuditTrailInfo,
          @vRecordsUpdated              TCount,
          @vTotalRecords                TCount,
          /* Input variables */
          @vEntity                      TEntity,
          @vAction                      TAction,
          /* Process variables */
          @vWaveId                      TRecordId,
          @vWaveNo                      TWaveNo,
          @vWaveType                    TTypeCode,
          @vCreateBPT                   TFlag,
          @vAllocateInventory           TControlValue,
          @vValidWaveStatus             TControlValue;

  declare @ttWaves                      TEntityKeysTable;

  declare @ttBatchControls table (WaveType    TTypeCode,
                                  CreateBPT   TFlag)

begin /* pr_Waves_Action_Reallocate */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vRecordsUpdated = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vAuditActivity  = '';

  select @vEntity  = Record.Col.value('Entity[1]',         'TEntity'),
         @vAction  = Record.Col.value('Action[1]',         'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vValidWaveStatus =  dbo.fn_Controls_GetAsString('Reallocate', 'ValidWaveStatus', 'NBLERPUKACGO' /* New */ /* Planned */ /* Ready To Pull */ /* Released */ /* ReadyToPick */ /* Picking */ /* Paused */ /* Picked */ /* Packing */ /* Packed */ /* Staged */ /* Loaded */, @BusinessUnit, null/* UserId */);

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the total count of Wave from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get all the required info from Waves for validations to avoid hitting the Waves
     table again and again */
  select W.WaveId, W.WaveNo, W.WaveStatus as WaveStatus, W.WaveStatusDesc,
  case when (charindex(W.WaveStatus, @vValidWaveStatus) = 0) then 'Waves_Reallocate_InvalidWaveStatus'
       when (W.WaveStatus <> 'N' /* New */) and
            (W.AllocateFlags = 'I' /* Inprogress */)         then 'Waves_Reallocate_AllocationInprogress'
  end ErrorMessage
  into #InvalidWaves
  from vwWaves W join #ttSelectedEntities ttSE on (W.RecordId = ttSE.EntityId);

  /* Exclude the Waves that are determined to be invalid above */
  delete from SE
  output 'E', IW.WaveId, IW.WaveNo, IW.ErrorMessage, IW.WaveStatusDesc
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE join #InvalidWaves IW on SE.EntityId = IW.Waveid
  where (IW.ErrorMessage is not null);

  /*---- Do updates ------*/

  /* Update the AllocateFlags to Yes, so that it will allocate through job or below statement */
  update W
  set AllocateFlags = 'Y'  /* Yes */
  from #ttSelectedEntities SE join Waves W on (SE.EntityId = W.WaveId);

  set @vRecordsUpdated = @@rowcount;

  /* turn off the replenishment flag so it will trigger again if needed */
  update WA
  set IsReplenished = 'N'
  from #ttSelectedEntities SE join WaveAttributes WA on (SE.EntityId = WA.PickBatchId)
  where (WA.IsReplenished = 'Y');

  /* For ReplenishWave we will do over allocation so when we reallocate the Wave we are trying update UnitsAssigned value with OrigUnitsAuthourzedToShip
     and update will be failed in this case so we added below condition
      where (OD.UnitsAssigned < OD.UnitsAuthorizedToShip) */
  update OD
  set OD.UnitsAuthorizedToShip = OD.OrigUnitsAuthorizedToShip
  from OrderDetails OD
    join OrderHeaders OH on (OD.OrderId = OH.OrderId)
    join #ttSelectedEntities SE on (OH.PickBatchId = SE.EntityId)
    join Waves W on (SE.EntityId = W.WaveId) and (W.WaveType in ('R', 'RU', 'RP'/* Replenish */))
  where (OD.UnitsAssigned < OD.OrigUnitsAuthorizedToShip);

  /* Loop thru all the selected waves and allocate them */
  while (exists (select * from #ttSelectedEntities where RecordId > @vRecordId))
    begin
      /* select Top 1 WaveNo from temp table */
      select top 1 @vWaveId   = EntityId,
                   @vWaveNo   = EntityKey,
                   @vRecordId = RecordId
      from #ttSelectedEntities
      where (RecordId > @vRecordId)
      order by RecordId;

      select @vWaveType = W.WaveType
      from Waves W
      where (W.WaveId = @vWaveId);

      /* Get the control variable */
      select @vAllocateInventory = dbo.fn_Controls_GetAsString('PickBatch_' +@vWaveType, 'AllocateOnReallocate', 'J' /* By Job */,  @BusinessUnit, null /* UserId */);

      /* If we to allocate immediately upon reallocate, then do so. Otherwise Inventory will get allocate on next job run */
      if (charindex(@vAllocateInventory, 'R' /* ReAllocate */) > 0)
        exec pr_Allocation_AllocateWave @vWaveNo, null /* Operation */, @BusinessUnit, @UserId;
    end

  /*----------------- Audit Trail ----------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Wave', EntityId, EntityKey, 'WaveReAllocation', @BusinessUnit, @UserId,
           dbo.fn_Messages_Build('AT_WaveReAllocation', EntityKey, null, null, null, null) /* Comment */
    from #ttSelectedEntities

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_Reallocate */

Go
