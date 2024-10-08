/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  TK      pr_Wave_ReleaseForAllocation: Pass wave status in rules data (HA-2646)
  2021/02/18  MS      pr_Wave_ReleaseForAllocation: Changes to do post release functions in rules (BK-174)
  2020/10/08  VS      pr_Wave_ReleaseForAllocation: Clear the previous Notifications for WaveRelease operation (HA-1513)
  2020/10/05  RBV     pr_Wave_ReleaseForAllocation: Made changes to update the PickMethod on the Waves table (CID-1488)
  2020/08/06  RKC     pr_Wave_ReleaseForAllocation:Made changes to revert the wave status back to new if wave is not valid to release after generation (HA-886)
  2020/06/10  KBB     pr_Wave_ReleaseForAllocation: Including the Priority(HA-792)
  2020/06/05  VS      pr_PickBatch_GenerateBatches, pr_Wave_ReleaseForAllocation: When wave is create with Released Status validate the Wave (HA-671)
              TK      pr_Wave_ReleaseForAllocation: Bug fix in drop location validation (HA-859)
  2020/06/03  RKC     pr_Wave_ReleaseForAllocation: Allocation Model for PTS Waves should be system reservation (HA-787)
  2020/05/28  RKC     pr_Wave_ReleaseForAllocation:Show the error messages using #ResultMessages (HA-685)
  2020/05/27  VS      pr_PickBatch_ReleaseBatches, pr_PickBatch_GenerateBatches, pr_Wave_ReleaseForAllocation: Need to InventoryAllocationModel When we create wave with Released status (HA-668)
  2020/05/26  TK      pr_Wave_ReleaseForAllocation: EntityType should be wave to Log AT (HA-646)
  2020/05/22  KBB     pr_Wave_ReleaseForAllocation/pr_PickBatch_ReleaseBatches:Changed the  entity type PickTicket (HA-384)
  2020/05/15  TK      pr_Wave_ReleaseForAllocation & pr_PickBatch_SetStatus:
  2020/05/12  RT      pr_Wave_ReleaseForAllocation: Included InvAllocationModel (HA-312)
  2019/09/13  VS/AY   pr_Wave_ReleaseForAllocation, pr_PickBatch_Modify: Made the changes to enhance validation message with more details (CID-860)
  2018/09/10  TK      pr_Wave_ReleaseForAllocation: Changed RuleSet Type ZonesToReplenish -> ReplenishToZones (S2GCA-239)
  2018/08/09  RV      pr_Wave_ReleaseForAllocation: Update null when ShipDate is invalid (Support)
  2018/04/11  AY/TK   pr_Wave_ReleaseForAllocation: Change to send CasesToShip and RemUnitsToShip for Rules
  2018/03/17  TK      pr_Wave_ReleaseForAllocation: Ignore cancelled tasks (S2G-394)
                      pr_Wave_ReleaseForAllocation: Update color code while Wave is released for allocation
              TK      pr_Wave_ReleaseForAllocation: Wave release validations (S2G-382)
  2018/03/06  CK      pr_Wave_ReleaseForAllocation: Introduce PromptOnRelease to update shipdate & droplocation on Wave (S2G-104)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_ReleaseForAllocation') is not null
  drop Procedure pr_Wave_ReleaseForAllocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_ReleaseForAllocation: Releases the waves specified in the
    input table param.
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_ReleaseForAllocation
  (@PickBatches      TEntityKeysTable ReadOnly,
   @xmlData          xml,
   @UserId           TUserId,
   @BusinessUnit     TBusinessUnit,
   @BatchesUpdated   TCount  = null output,
   @Notes            TNote   = null output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vDebug               TFlag,
          @vActivityLogId       TRecordId,
          @vxmlData             TXML,
          @xmlRulesData         TXML,

          @vRecordId            TRecordId,
          @vWaveId              TRecordId,
          @vWaveNo              TWaveNo,
          @vWaveNos             TWaveNo,
          @vWaveType            TTypeCode,
          @vWaveTypeDesc        TName,
          @vWaveStatus          TStatus,
          @vWaveNumOrders       TCount,
          @vWaveNumUnits        TCount,
          @vWaveNumCases        TCount,
          @vWaveRemainingUnits  TCount,
          @vWaveWCSDependencyFlags
                                TFlags,
          @vShipDate            TDate,
          @vDropLocation        TLocation,
          @vDropLocationId      TRecordId,
          @vDropLocationWH      TWarehouse,
          @vPickSequence        TPickSequence,
          @vPriority            TPriority,
          @ttPickBatches        TEntityKeysTable,
          @vBusinessUnit        TBusinessUnit,
          @vTasksCreated        TCount,
          @vModifiedDate        TDateTime,
          @vAuditRecordId       TRecordId,
          @vExportSrtrDetails   TControlValue,
          @vCreateBPT           TFlag,
          @vGenerateLoadForWave TFlag,
          @vPromptOnRelease     TFlag,
          @vOrdersToLoad        TXML,
          @vAllocateInventory   TControlValue,
          @vInvAllocationModel  TTypeCode,
          @vCasePickZonesToReplenish
                                TControlValue,
          @vControlCategory     TCategory,
          @ttOrdersOnWave       TEntityKeysTable,
          @vErrorMsgParam1      TDescription = null,
          @vErrorMsgParam2      TDescription = null,
          @vWavesCount          TCount,
          @vPickMethod          TPickMethod;

 declare  @ttValidations   TValidations;
begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vWaveNos       = null,
         @BatchesUpdated = 0,
         @vWavesCount    = 0;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

  /*------------------------------------------------------------------------*/
  /* Activity Log */
  /*------------------------------------------------------------------------*/
  if (charindex('L' /* Log */, @vDebug) > 0)
    begin
      select @vxmlData = (select OH.PickBatchNo, OH.WaveType, OH.PickTicket, OH.OrderType, OH.OrderCategory1
                          from vwOrderHeaders OH join @PickBatches PB on OH.PickBatchNo = PB.EntityKey
                          where OrderType <> 'RU' /* Replenish */
                          order by PickBatchNo
                          for XML raw('PickTickets'), elements);
      exec pr_ActivityLog_AddMessage 'ReleaseWaves' /* Operation */, null /* EntityId */, null /* EntityKey */, 'PickTicket' /* Entity */,
                                     'StartReleaseWaves' /* Message */, @@ProcId, @vxmlData, @BusinessUnit, @UserId;
    end

  /* Get the ShipDate and DropLocation from the xml */
  select @vShipDate           = Record.Col.value('ShipDate[1]',           'TDate'),
         @vDropLocation       = Record.Col.value('DropLocation[1]',       'TLocation'),
         @vPickMethod         = Record.Col.value('PickMethod[1]',         'TPickMethod'),
         @vPickSequence       = Record.Col.value('PickSequence[1]',       'TPickSequence'),
         @vPriority           = Record.Col.value('Priority[1]',           'TPriority'),
         @vInvAllocationModel = Record.Col.value('InvAllocationModel[1]', 'TTypeCode')
  from @xmlData.nodes('/ModifyPickBatches/Data') as Record(Col);

  select @vDropLocationId = LocationId,
         @vDropLocationWH = Warehouse
  from Locations
  where (Location     = @vDropLocation) and
        (BusinessUnit = @BusinessUnit);

  /* Get the Total Wave count */
  select @vWavesCount = count(*) from @PickBatches;

  /* Loop the batches and perform OnRelease, Allocation and AfterRelease on each Batch */
  while (exists (select * from @PickBatches where RecordId > @vRecordId))
    begin
      /* select Top 1 BatchNo from temp table */
      select top 1 @vWaveNo   = EntityKey,
                   @vRecordId = RecordId
      from @PickBatches
      where (RecordId > @vRecordId)
      order by RecordId;

      /* select BatchType to eliminate other than Bulk Batches */
      select @vWaveId        = PB.RecordId,
             @vWaveType      = PB.BatchType,
             @vWaveTypeDesc  = PB.BatchTypeDesc,
             @vWaveStatus    = PB.Status,
             @vWaveNumOrders = PB.NumOrders,
             @vWaveNumUnits  = PB.NumUnits
      from vwPickBatches PB
      where (BatchNo      = @vWaveNo) and
            (BusinessUnit = @BusinessUnit);

      /* If there are invalid waves, then skip them */
      if (@vWaveStatus not in ('N' /* New */, 'E'/* Released */, 'B' /* Planned */, 'R' /* ReadyToPick */, 'P' /* Picking */)) or
         (@vWaveNumOrders = 0)
        continue;

      /* Build the data for evaluation of rules to get Wave release dependency flags to export data to WSS */
      select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                               dbo.fn_XMLNode('Operation',           'ReleaseForAllocation') +
                               dbo.fn_XMLNode('WaveType',            @vWaveType            ) +
                               dbo.fn_XMLNode('WaveId',              @vWaveId              ) +
                               dbo.fn_XMLNode('WaveNo',              @vWaveNo              ) +
                               dbo.fn_XMLNode('WaveStatus',          @vWaveStatus          ) +
                               dbo.fn_XMLNode('ShipDate',            @vShipDate            ) +
                               dbo.fn_XMLNode('WaveNumOrders',       @vWaveNumOrders       ) +
                               dbo.fn_XMLNode('WaveNumCases',        0                     ) +
                               dbo.fn_XMLNode('WaveNumUnits',        @vWaveNumUnits        ) +
                               dbo.fn_XMLNode('WaveRemainingUnits',  0                     ) +
                               dbo.fn_XMLNode('DropLocation',        @vDropLocation        ) +
                               dbo.fn_XMLNode('DropLocationId',      @vDropLocationId      ) +
                               dbo.fn_XMLNode('DropLocationWH',      @vDropLocationWH      ) +
                               dbo.fn_XMLNode('InvAllocationModel',  @vInvAllocationModel  ) +
                               dbo.fn_XMLNode('BusinessUnit',        @BusinessUnit         ) +
                               dbo.fn_XMLNode('UserId',              @UserId               ));

     /* Evaluate rules and find out Case pick zones to replenish */
     exec pr_RuleSets_Evaluate 'ReplenishToZones', @xmlRulesData, @vCasePickZonesToReplenish output;

     /* Compute the number of cases and remaining units */
     /* If there are no case storage locations set up for SKU then consider CasesToShip as zero
        and RemainingUnitsToShip as UnitsAuthrizedToShip */
     select @vWaveNumCases       = sum(case when (L.LPNId is not null) then CasesToShip else 0 end),
            @vWaveRemainingUnits = sum(case when (L.LPNId is not null) then RemainingUnitsToShip else UnitsAuthorizedToShip end)
     from vwPickBatchDetails PBD
       left outer join vwLPNs L on (PBD.SKUId     = L.SKUId        ) and
                                   (PBD.Ownership = L.Ownership    ) and
                                   (PBD.Warehouse = L.DestWarehouse) and
                                   (L.StorageType = 'P'/* Cases */  ) and
                                   (charindex(',' + L.PickingZone + ',', @vCasePickZonesToReplenish) > 0)
     where (PBD.PickBatchId = @vWaveId);

     select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'WaveNumCases', @vWaveNumCases);
     select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'WaveRemainingUnits', @vWaveRemainingUnits);

      /* Insert the Error messages into temp table */
      delete from #Validations;
      exec pr_RuleSets_ExecuteRules 'WaveRelease', @xmlRulesData;

      /* Insert the validations into Audit trail */
      if exists (select * from #Validations)
        begin
          /* Add the Wave to the list of Waves which are not Released */
          select @vWaveNos = coalesce(@vWaveNos + ', ', '') + @vWaveNo;

          /* Save Validations to AuditTrail */
          exec pr_Notifications_SaveValidations 'Wave', @vWaveId, @vWaveNo, 'NO', 'WaveRelease', @BusinessUnit, @UserId;

          /* Show the validations messages in UI */
          insert into #ResultMessages (MessageType, MessageText)
            select coalesce(MessageType, 'E' /* Error */), dbo.fn_messages_Build(MessageName, Value1, Value2, Value3, Value4, Value5)
            from #Validations

          /* Revert the Wave status back to New if wave is not valid to be released */
          update Waves
          set Status          = 'N',
              WaveStatus      = 'N',
              AllocateFlags   = 'N'
          where (WaveId = @vWaveId);

          continue;
        end
      else
        /* Clear the previous notifications of WaveRelease Operation for current wave */
        exec pr_Notifications_Clear 'Wave', @vWaveId, @vWaveNo, 'NO', 'WaveRelease', @BusinessUnit, @UserId;

      /* Get the valid WCSDependency for the task  */
      exec pr_RuleSets_Evaluate 'SetWCSDependency', @xmlRulesData, @vWaveWCSDependencyFlags output;

      /* Get Control category for the wave type or other attributes of the wave */
      exec pr_RuleSets_Evaluate 'WaveControlCategory', @xmlRulesData, @vControlCategory output;

      /* If no category returned then build the Control category */
      select @vControlCategory = coalesce(@vControlCategory, 'PickBatch_' + @vWaveType);

      /* get control values that depend upon the Batch Type */
      select @vExportSrtrDetails   = dbo.fn_Controls_GetAsString(@vControlCategory, 'ExportToSorter',      'Y', @BusinessUnit, @UserId),
             @vAllocateInventory   = dbo.fn_Controls_GetAsString(@vControlCategory, 'AllocateOnRelease',   'J' /* By Job */, @BusinessUnit, @UserId),
             @vCreateBPT           = dbo.fn_Controls_GetAsString(@vControlCategory, 'CreateBPT',           'N' /* No */, @BusinessUnit, @UserId),
             @vGenerateLoadForWave = dbo.fn_Controls_GetAsString(@vControlCategory, 'GenerateLoadForWave', 'N' /* No */, @BusinessUnit, @UserId),
             @vPromptOnRelease     = dbo.fn_Controls_GetAsString(@vControlCategory, 'PromptOnRelease',     'O' /* Optional */, @BusinessUnit, @userId);

      /* Update Batch with ShipDate & Dock Location as they would be validated */
      update W
      set DropLocation       = case
                                 when @vPromptOnRelease in ('R' /* Required */ ,'O' /* Optional */ ) then
                                   coalesce(@vDropLocation, DropLocation)
                                 else
                                   DropLocation
                               end,
          ShipDate           = case
                                 when @vPromptOnRelease in ('R' /* Required */ ,'O' /* Optional */ ) then
                                   coalesce(nullif(@vShipDate, '0001-01-01'), ShipDate)
                                 else
                                   ShipDate
                               end,
          WCSDependency      = coalesce(@vWaveWCSDependencyFlags, WCSDependency),
          ColorCode          =   case
                                 when coalesce(@vWaveWCSDependencyFlags, WCSDependency) = ''  then 'G' -- Dependency resolved, so show in green
                                 when coalesce(@vWaveWCSDependencyFlags, WCSDependency) <> '' then 'R' -- Still there is dependency, show in red
                                 else null -- default color
                               end,
          PickSequence       = @vPickSequence,
          Priority           = coalesce(@vPriority, Priority),
          InvAllocationModel = coalesce(@vInvAllocationModel, 'SR'),
          PickMethod         = coalesce(@vPickMethod, 'CIMSRF' /* default */)
      from Waves W
      where (W.WaveId = @vWaveId);

      /* Update Batch status to indicate it is released, set allocate flag */
      update W
      set @vWaveStatus    =
          Status          = case when Status = 'P' /* Picking */ then Status else  'E' /* Released */ end,
          AllocateFlags   = 'Y',
          ReleaseDateTime = current_timestamp,
          @vModifiedDate  =
          ModifiedDate    = current_timestamp,
          ModifiedBy      = @UserId
      from Waves W
      where (WaveId = @vWaveId) and
            (dbo.fn_IsInList(Status, 'NERBP' /* New, Released, Planned, ReadyToPick, Picking */) > 0) and
            (NumOrders > 0);

      /* Update the count */
      select @BatchesUpdated += 1;

      /* Insert Audit trail for the Batch */
      exec pr_AuditTrail_Insert 'PickBatchReleased', @UserId, @vModifiedDate,
                                @PickBatchId   = @vWaveId,
                                @AuditRecordId = @vAuditRecordId output;

      /* There may be several things to do when a wave has been released, use the rules to do them in the needed sequence */
      exec pr_RuleSets_ExecuteAllRules 'WaveOnRelease', @xmlRulesData, @BusinessUnit;

      delete from @ttOrdersOnWave;
      insert into @ttOrdersOnWave(EntityId, EntityKey)
        select OrderId, PickTicket
        from OrderHeaders
        where (PickBatchId = @vWaveId);

      /* Now insert all the Waves released into Audit Entities i.e link above Audit Record
         to all the Waves */
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttOrdersOnWave, @BusinessUnit;
    end

  set @Notes = @vWaveNos;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Wave_ReleaseForAllocation */

Go
