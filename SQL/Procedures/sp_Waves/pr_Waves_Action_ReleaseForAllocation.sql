/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/24  TD      pr_Waves_Action_ReleaseForAllocation:Corrected the Planned Status (Support)
  2022/08/01  VM      pr_Waves_Action_ReleaseForAllocation: Update WaveStatus as well along with Status (OBV3-945)
  2021/06/30  OK      pr_Waves_Action_ReleaseForAllocation: Changes to pass CartonizationModel to Rules (HA-2934)
  2021/05/22  PKK     pr_Waves_Action_ReleaseForAllocation: Updated CartonizationModel and MaxUnitsPerCarton (HA-2813)
  2021/03/04  AJM     pr_Waves_Action_ReleaseForAllocation: Intial revision (CIMSV3-1326)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_ReleaseForAllocation') is not null
  drop Procedure pr_Waves_Action_ReleaseForAllocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_ReleaseForAllocation: This procedure used to Release the
    waves specified in the input table param
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_ReleaseForAllocation
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vShipDate                   TDate,
          @vDropLocation               TLocation,
          @vPickMethod                 TPickMethod,
          @vPickSequence               TPickSequence,
          @vPriority                   TPriority,
          @vInvAllocationModel         TTypeCode,
          @vCartonizationModel         TDescription,
          @vMaxUnitsPerCarton          TInteger,
          /* Process variables */
          @vxmlRulesData               TXML,
          @vDebug                      TFlag,
          @vWaveId                     TRecordId,
          @vWaveNo                     TWaveNo,
          @vWaveType                   TTypeCode,
          @vWaveTypeDesc               TName,
          @vWaveStatus                 TStatus,
          @vWaveNumOrders              TCount,
          @vWaveNumUnits               TCount,
          @vWaveNumCases               TCount,
          @vWaveRemainingUnits         TCount,
          @vWaveWCSDependencyFlags     TFlags,
          @vDropLocationId             TRecordId,
          @vDropLocationWH             TWarehouse,
          @vBusinessUnit               TBusinessUnit,
          @vTasksCreated               TCount,
          @vModifiedDate               TDateTime,
          @vExportSrtrDetails          TControlValue,
          @vCreateBPT                  TFlag,
          @vGenerateLoadForWave        TFlag,
          @vPromptOnRelease            TFlag,
          @vAllocateInventory          TControlValue,
          @vCasePickZonesToReplenish   TControlValue,
          @vControlCategory            TCategory,
          @vWavesCount                 TCount,
          @vValidWaveStatus            TControlValue;

  declare @ttWaves                     TEntityKeysTable;
  declare @ttOrdersOnWave              TEntityKeysTable;
  declare @ttValidations               TValidations;
begin /* pr_Wave_Action_ReleaseForAllocation */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordsUpdated = 0,
         @vRecordId       = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_WaveReleased';

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

  select @vEntity             = Record.Col.value('Entity[1]',                      'TEntity'),
         @vAction             = Record.Col.value('Action[1]',                      'TAction'),
         @vShipDate           = Record.Col.value('(Data/ShipDate) [1]',            'TDate'),
         @vDropLocation       = Record.Col.value('(Data/DropLocation) [1]',        'TLocation'),
         @vPickMethod         = Record.Col.value('(Data/PickMethod) [1]',          'TPickMethod'),
         @vPickSequence       = Record.Col.value('(Data/PickSequence) [1]',        'TPickSequence'),
         @vPriority           = Record.Col.value('(Data/Priority) [1]',            'TPriority'),
         @vInvAllocationModel = Record.Col.value('(Data/InvAllocationModel) [1]',  'TCategory'),
         @vCartonizationModel = Record.Col.value('(Data/CartonizationModel) [1]',  'TCategory'),
         @vMaxUnitsPerCarton  = Record.Col.value('(Data/MaxUnitsPerCarton) [1]',   'TInteger')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vValidWaveStatus =  dbo.fn_Controls_GetAsString('ReleaseForAllocation', 'ValidWaveStatus', 'NEBRP' /* New */ /* Released */ /* Planned */ /* ReadyToPick */ /* Picking */, @BusinessUnit, null/* UserId */);

  select @vDropLocationId = LocationId,
         @vDropLocationWH = Warehouse
  from Locations
  where (Location     = @vDropLocation) and
        (BusinessUnit = @BusinessUnit);

  /* Get the total count of Wave from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* If there are invalid waves, then skip them */
  delete ttSE
  output 'E', 'ReleaseForAllocation_InvalidWaveStatus', W.WaveNo, W.WaveStatusDesc
  into #ResultMessages(MessageType, MessageName, Value1, Value2)
  from vwWaves W join #ttSelectedEntities ttSE on (W.RecordId = ttSE.EntityId)
  where (charindex(W.WaveStatus, @vValidWaveStatus) = 0)

  /* If Wave has no orders, eliminate those waves */
  delete ttSE
  output 'E', 'ReleaseForAllocation_WaveHasNoOrders', W.WaveNo
  into #ResultMessages(MessageType, MessageName, Value1)
  from Waves W join #ttSelectedEntities ttSE on (W.RecordId = ttSE.EntityId)
  where (W.NumOrders = 0);

  /* Get the list of remaining waves into a temp table for processing */
  insert into @ttWaves (EntityId, EntityKey)
    select EntityId, EntityKey from #ttSelectedEntities;

  /* Validations */
  if (@@rowcount = 0)
    select @vMessageName = 'WaveRelease_NoQualifiedOrders';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Loop the Waves and perform OnRelease, Allocation and AfterRelease on each Wave */
  while (exists (select * from @ttWaves where RecordId > @vRecordId))
    begin
      /* select Top 1 WaveNo from temp table */
      select top 1 @vWaveId   = EntityId,
                   @vWaveNo   = EntityKey,
                   @vRecordId = RecordId
      from @ttWaves
      where (RecordId > @vRecordId)
      order by RecordId;

      /* select BatchType to eliminate other than Bulk Batches */
      select @vWaveId        = W.RecordId,
             @vWaveNo        = W.WaveNo,
             @vWaveType      = W.WaveType,
             @vWaveStatus    = W.WaveStatus,
             @vWaveNumOrders = W.NumOrders,
             @vWaveNumUnits  = W.NumUnits
      from Waves W
      where (WaveId = @vWaveId);

      /* Build the data for evaluation of rules to get Wave release dependency flags to export data to WSS */
      select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('Operation',           'ReleaseForAllocation') +
                              dbo.fn_XMLNode('WaveType',            @vWaveType            ) +
                              dbo.fn_XMLNode('WaveId',              @vWaveId              ) +
                              dbo.fn_XMLNode('WaveNo',              @vWaveNo              ) +
                              dbo.fn_XMLNode('ShipDate',            @vShipDate            ) +
                              dbo.fn_XMLNode('WaveNumOrders',       @vWaveNumOrders       ) +
                              dbo.fn_XMLNode('WaveNumCases',        0                     ) +
                              dbo.fn_XMLNode('WaveNumUnits',        @vWaveNumUnits        ) +
                              dbo.fn_XMLNode('WaveRemainingUnits',  0                     ) +
                              dbo.fn_XMLNode('DropLocationId',      @vDropLocationId      ) +
                              dbo.fn_XMLNode('DropLocation',        @vDropLocation        ) +
                              dbo.fn_XMLNode('DropLocationWH',      @vDropLocationWH      ) +
                              dbo.fn_XMLNode('InvAllocationModel',  @vInvAllocationModel  ) +
                              dbo.fn_XMLNode('WaveControlCategory', @vControlCategory     ) +
                              dbo.fn_XMLNode('CartonizationModel',  @vCartonizationModel  ) +
                              dbo.fn_XMLNode('BusinessUnit',        @BusinessUnit         ) +
                              dbo.fn_XMLNode('UserId',              @UserId               ));

      /* Get Control category for the wave type or other attributes of the wave */
      exec pr_RuleSets_Evaluate 'WaveControlCategory', @vxmlRulesData output, @vControlCategory output, @StuffResult = 'Y';

      /* Evaluate rules and find out Case pick zones to replenish */
      exec pr_RuleSets_Evaluate 'ReplenishToZones', @vxmlRulesData, @vCasePickZonesToReplenish output;

      /* Compute the number of cases and remaining units */
      /* If there are no case storage locations set up for SKU then consider CasesToShip as zero
         and RemainingUnitsToShip as UnitsAuthorizedToShip */
      select @vWaveNumCases       = sum(case when (L.LPNId is not null) then CasesToShip else 0 end),
             @vWaveRemainingUnits = sum(case when (L.LPNId is not null) then RemainingUnitsToShip else UnitsAuthorizedToShip end)
      from vwPickBatchDetails PBD
        left outer join vwLPNs L on (PBD.SKUId     = L.SKUId        ) and
                                    (PBD.Ownership = L.Ownership    ) and
                                    (PBD.Warehouse = L.DestWarehouse) and
                                    (L.StorageType = 'P'/* Cases */  ) and
                                    (charindex(',' + L.PickingZone + ',', @vCasePickZonesToReplenish) > 0)
      where (PBD.PickBatchId = @vWaveId);

      select @vxmlRulesData = dbo.fn_XMLStuffValue (@vxmlRulesData, 'WaveNumCases', @vWaveNumCases);
      select @vxmlRulesData = dbo.fn_XMLStuffValue (@vxmlRulesData, 'WaveRemainingUnits', @vWaveRemainingUnits);

      /* Insert the Error messages into temp table */
      delete from #Validations;
      exec pr_RuleSets_ExecuteRules 'WaveRelease', @vxmlRulesData;

      /* Save the validations for user to see later and also report back in #ResultMessages */
      if exists (select * from #Validations)
        begin
          /* Save Validations to AuditTrail */
          exec pr_Notifications_SaveValidations 'Wave', @vWaveId, @vWaveNo, 'NO', 'WaveRelease', @BusinessUnit, @UserId;

          /* Show the validations messages in UI */
          insert into #ResultMessages (MessageType, MessageText)
            select coalesce(MessageType, 'E' /* Error */), dbo.fn_messages_Build(MessageName, Value1, Value2, Value3, Value4, Value5)
            from #Validations

          /* Revert the Wave status back to New if wave is not valid to be released */
          update Waves
          set Status          = 'N' /* New */,
              WaveStatus      = 'N' /* New */,
              AllocateFlags   = 'N'
          where (RecordId = @vWaveId);

          continue;
        end
      else
        /* Clear the previous notifications of WaveRelease Operation for current wave */
        exec pr_Notifications_Clear 'Wave', @vWaveId, @vWaveNo, 'NO', 'WaveRelease', @BusinessUnit, @UserId;

     /* Get the valid WCSDependency for the task  */
     exec pr_RuleSets_Evaluate 'SetWCSDependency', @vxmlRulesData, @vWaveWCSDependencyFlags output;

     /* Update Batch with ShipDate & Dock Location as they would be validated */
     update W
     set DropLocation       = coalesce(@vDropLocation,                   DropLocation),
         ShipDate           = coalesce(nullif(@vShipDate, '0001-01-01'), ShipDate),
         WCSDependency      = coalesce(@vWaveWCSDependencyFlags,         WCSDependency),
         PickSequence       = coalesce(@vPickSequence,                   PickSequence),
         Priority           = coalesce(@vPriority,                       Priority),
         InvAllocationModel = coalesce(@vInvAllocationModel,             'SR' /* System Reservation */),
         CartonizationModel = coalesce(@vCartonizationModel,             'Default'),
         MaxUnitsPerCarton  = coalesce(@vMaxUnitsPerCarton,              9999),
         PickMethod         = coalesce(@vPickMethod,                     'CIMSRF' /* default */),
         ColorCode          = case
                                when coalesce(@vWaveWCSDependencyFlags, WCSDependency) = ''  then 'G' -- Dependency resolved, so show in green
                                when coalesce(@vWaveWCSDependencyFlags, WCSDependency) <> '' then 'R' -- Still there is dependency, show in red
                                else null -- default color
                              end
     from Waves W
     where (W.RecordId = @vWaveId);

     /* Update Wave status to indicate it is released, set allocate flag */
     update W
     set Status          = case when Status not in  ('N', 'B' /* New, Planned */) then Status else  'E' /* Released */ end,
         WaveStatus      = case when Status not in  ('N', 'B' /* New, Planned */) then Status else  'E' /* Released */ end,
         AllocateFlags   = 'Y',
         ReleaseDateTime = current_timestamp,
         @vModifiedDate  =
         ModifiedDate    = current_timestamp,
         ModifiedBy      = @UserId
     from Waves W
     where (RecordId = @vWaveId) and
           (dbo.fn_IsInList(Status, 'NERBP' /* New, Released, Planned, ReadyToPick, Picking */) > 0) and
           (NumOrders > 0);

     /* get the updated Wave count */
     select @vRecordsUpdated += 1;

     /* Insert Audit trail for the Batch */
     exec pr_AuditTrail_Insert 'WaveReleased', @UserId, @vModifiedDate,
                               @WaveId = @vWaveId, @AuditRecordId = @vAuditRecordId output;

     /* Get orders on Wave to create AT */
     delete from @ttOrdersOnWave;
     insert into @ttOrdersOnWave(EntityId, EntityKey)
       select OrderId, PickTicket from OrderHeaders where (PickBatchId = @vWaveId);

     /* Link the audit record to all the Orders on the Wave */
     exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttOrdersOnWave, @BusinessUnit;

     /* There may be several things to do when a wave has been released, use the rules to do them in the needed sequence */
     exec pr_RuleSets_ExecuteAllRules 'WaveOnRelease', @vxmlRulesData, @BusinessUnit;
  end

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_ReleaseForAllocation */

Go
