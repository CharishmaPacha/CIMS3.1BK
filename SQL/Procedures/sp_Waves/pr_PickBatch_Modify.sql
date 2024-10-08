/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/18  VS      pr_PickBatch_Cancel, pr_PickBatch_Modify, pr_PickBatch_RemoveOrder, pr_PickBatch_RemoveOrders,
  2020/12/23  KBB     pr_PickBatch_Modify: Made changes to Modify Wave updated the required fields(HA-1825)
  2020/09/04  VS      pr_PickBatch_Modify, pr_Waves_Action_CancelWave: Made changes to Cancel the Wave based upon TDCount (CIMSV3-1078)
  2020/05/21  RKC     pr_PickBatch_Modify: Changed action name (HA-624)
                      pr_PickBatch_Modify: For V3 'ReleaseForAllocation' -> 'Waves_ReleaseForAllocation' (HA-608)
  2019/09/13  VS/AY   pr_Wave_ReleaseForAllocation, pr_PickBatch_Modify: Made the changes to enhance validation message with more details (CID-860)
  2018/08/06  AY/PK   pr_PickBatch_Modify: Added changes to update WCSStatus on PickBatches
              AY      pr_PickBatch_Modify, pr_Wave_ReleaseForPicking, pr_Wave_ReleaseForPickingValidation: Changed
                      pr_PickBatch_Modify:ModifyPriority: Added shipdate & droplocation to Modifywave (S2G-104)
  2018/02/16  AJ      pr_PickBatch_Modify: Added action ReleaseForPicking & Modify action ReleasePicking to ReleaseForAllocation (S2G-231)
  2015/07/28  OK      pr_PickBatch_Modify: Made the changes in ReleaseWave to display error message with AccountName(ACME-269).
  2015/07/27  TK      pr_PickBatch_Modify: Enhanced to cancel multiple Waves selected.
  2015/01/12  PKS     pr_PickBatch_Modify: Validate Release pick Batches based up on Rules.
  2014/09/22  TK      Updated pr_PickBatch_Modify and pr_PickBatch_PlanBatch to log proper Audit Trail.
  2014/06/05  TD      pr_PickBatch_Modify:Changes to avoid null exception, so inserting 0 into temptable.
  2014/04/11  AK/AY   pr_PickBatch_Modify:Added actions UnplanBatch, PlanBatch.
  2013/12/13  TD      pr_PickBatch_Modify: Changes to update cancel date.
  2013/11/28  TD      pr_PickBatch_Modify:Changes to show right messages.
  2013/11/19  TD      pr_PickBatch_Modify: Updating assignedto with username instead of ID.
  2013/02/06  SP      pr_PickBatch_ModifyBatch:Added validation for batches in  canceled, shipped, completed  statuses.
  2012/12/17  YA      pr_PickBatch_Modify: Included code for cancel batch.
  2012/10/17  SP      "pr_PickBatch_ModifyBatch" corrected the "UDF1" to "UDF3".
  2012/10/15  SP      Added "pr_PickBatch_ModifyBatch".
  2012/08/01  AY      pr_PickBatch_Modify: output variable 'Message' datatype changed to TMessage
  2012/06/30  SP      Placed the transaction controls in 'pr_PickBatch_Modify' and 'pr_PickBatch_RemoveOrders'.
  2012/06/08  AA      pr_PickBatch_Modify: added functionality for Modify Priority
  2012/05/16  PK      Modified pr_PickBatch_Modify on BatchRelease option to create Bulk order
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_Modify') is not null
  drop Procedure pr_PickBatch_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_Modify
  XML Sturcture

<ModifyPickBatches>
  <Action>UserBatchAssignments/ModifyPriority</Action>
  <Data>
    <AssignUser>7</AssignUser>
    <Priority>1</Priority>
  </Data>
  <Batches>
    <BatchNo>0906002</BatchNo>
    <BatchNo>0830004</BatchNo>
    <BatchNo>0910002</BatchNo>
  </Batches>
</ModifyPickBatches>
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_Modify
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @PickBatchContents TXML,
   @Message           TMessage output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @ErrorMsgParam1   TDescription = null,
          @ErrorMsgParam2   TDescription = null,

          @vAction          TAction,
          @vRecordId        TRecordId,
          @vBatches         TNVarChar,
          @vAssignToUserId  TUserId,
          @xmlData          xml,
          @vBatchesCount    TCount,
          @vBatchesUpdated  TCount,
          @vPickBatchNo     TPickBatchNo,
          @vBusinessUnit    TBusinessUnit,
          @vBatchType       TTypeCode,
          @vPriority        TPriority,
          @vPickBatchId     TRecordId,
          @vAuditActivity   TActivityType,
          @vAuditRecordId   TRecordId,
          @vAuditNote1      TDescription,
          @vModifiedDate    TDateTime,
          @vUserName        TUserId,
          @vDropLocation    TLocation,
          @vShipDate        TDate,
          @vCancelDate      TDate,
          @vNotes           TNote,

          @vValidStatusesToRelease
                            TControlValue,
          @vInvalidStatusesToReallocate
                            TControlValue,
          @vControlCategory TCategory,
          @vXMLData         TXML,
          @vOperation       TOperation,
          @vMessage         TMessage;

  /* Temp table to hold all the batches to be updated */
  declare @ttPickBatches         TEntityKeysTable;
  declare @ttPickBatchesUpdated  TEntityKeysTable;
  declare @ttWavesToRFP          TRecountKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  set @xmlData            = convert(xml, @PickBatchContents);
  select @vRecordId       = 0,
         @vBatchesCount   = 0,
         @vBatchesUpdated = 0,
         @vAuditActivity  = 'PickBatchModify',
         @vAuditNote1     = '';

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/ModifyPickBatches') as Record(Col);

  if exists (select * from #ttSelectedEntities)
    insert into @ttPickBatches (EntityId, EntityKey)
      select EntityId, EntityKey from #ttSelectedEntities;
  else
    /* Load all the Batches into the temp table which are to be updated in PickBatches table */
    insert into @ttPickBatches (EntityId, EntityKey)
      select row_number() over(order by (select null)) AS RowNumber,
             Record.Col.value('.', 'TPickBatchNo') BatchNo
      from @xmlData.nodes('/ModifyPickBatches/Batches/BatchNo') as Record(Col);

  /* Get number of rows inserted */
  select @vBatchesCount   = @@rowcount,
         @vBatchesUpdated = 0;

  /* Fetch the control values */
  set @vControlCategory = 'PickBatch_' + @vAction;
  select @vValidStatusesToRelease      = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStatusesToRelease', 'NBRPUKAC' /* Statuses other than Ready To Pull, Being Pulled, Staged, Loaded, Shipped, Completed, Canceled */,
                                                                     @BusinessUnit, @UserId),
         @vInvalidStatusesToReallocate = dbo.fn_Controls_GetAsString(@vControlCategory, 'InvalidStatusesToReallocate', 'XSD' /* Canceled, Shipped, Completed */, @BusinessUnit, @UserId);

  if (@vAction in ('ReleaseForAllocation', 'Waves_ReleaseForAllocation'))
    begin
      exec pr_Wave_ReleaseForAllocation @ttPickBatches, @xmlData ,@UserId, @BusinessUnit, @vBatchesUpdated output, @vNotes output;

      select @vAuditActivity = null; /* The above procedure would have done it already */
    end
  else
  if (@vAction in ('Waves_Reallocate', 'ReallocateBatch'))
    begin
      /* Do not Reallocate Batches in these list of defined statuses. So,remove those Batchno.s from temp table */
      Delete  ttPB
      from @ttPickBatches ttPB
           join PickBatches PB on (PB.BatchNo = ttPB.EntityKey)
      where (charindex(PB.Status, @vInvalidStatusesToReallocate) > 0);

      exec pr_PickBatch_ReAllocateBatches @ttPickBatches, @UserId, @BusinessUnit, @vBatchesUpdated output;

      select @vAuditActivity = null; /* The above procedure would have done it already */
    end
  else
  if (@vAction in ('Waves_ReleaseForPicking', 'ReleaseForPicking'))
    begin
      select @vAuditActivity = null; /* The above procedure would have done it already */

      /* Validate */
      exec pr_Wave_ReleaseForPickingValidation @ttPickBatches, @xmldata, @BusinessUnit, @UserId, @Message output;

      if (@Message is not null)
        goto ErrorHandler;

      /* Setup temp table to pass for ExecuteInBackGroup */
      insert into @ttWavesToRFP (EntityId, EntityKey) select EntityId, EntityKey from @ttPickBatches;

      /* invoke ExecuteInBackGroup to defer Release for Picking process */
      exec pr_Entities_ExecuteInBackGround 'Wave', null, null/* WaveNo */, 'RFP'/* ProcessCode - Release for Picking */,
                                           @@ProcId, 'ReleaseForPicking'/* Operation */, @BusinessUnit, @ttWavesToRFP;

      update PB
      set WCSStatus = 'Export To WSS In-Progress'
      from PickBatches PB
      join @ttPickBatches TPB on (PB.BatchNo = TPB.EntityKey);

      /* If there are any validation errors then pr_Wave_ReleaseForPickingValidation will return error message
         if there are no errors then consider that all waves have been released for picking successfully,
         update BatchesUpdated to selected batches count */
      set @vBatchesUpdated = @@rowcount;
    end
  else
  if (@vAction in ('ModifyPriority', 'Waves_Modify'))
    begin
      select @vPriority     = Record.Col.value('Priority[1]',          'TPriority'),
             @vDropLocation = Record.Col.value('DropLocation[1]',      'TLocation'),
             @vShipDate     = nullif(Record.Col.value('ShipDate[1]',   'TDate'), ''),
             @vCancelDate   = nullif(Record.Col.value('CancelDate[1]', 'TDate'), '')
      from @xmlData.nodes('/ModifyPickBatches/Data') as Record(Col);

      /* Check if the UserName is passed or not */
      if (@vPriority is null)
       set @MessageName = 'PriorityIsRequired';

      if (@MessageName is not null)
         goto ErrorHandler;

      /* temporary- from UI if the user did not selected any value it sends the below value, so need to set it null if that is
        the case */
      select @vShipDate    = case when @vShipDate = '0001-01-01' then null else @vShipDate end;
      select @vCancelDate  = case when @vCancelDate = '0001-01-01' then null else @vCancelDate end;

      /* Update all batches in the temp table */
      update PB
      set Priority       = @vPriority,
          DropLocation   = coalesce(@vDropLocation, DropLocation),
          ShipDate       = coalesce(@vShipDate, ShipDate),
          CancelDate     = coalesce(@vCancelDate, CancelDate),
          @vModifiedDate =
          ModifiedDate   = current_timestamp,
          ModifiedBy     = coalesce(@UserId, System_User),
          @vPickBatchId  = PB.RecordId
      output Deleted.RecordId, Deleted.BatchNo into @ttPickBatchesUpdated
      from PickBatches PB
          join @ttPickBatches TPB on (PB.BatchNo = TPB.EntityKey)
      where (PB.BusinessUnit = @BusinessUnit) and
            (charindex(PB.Status, 'SDX' /* 'Shipped', 'Completed', 'Canceled' */)=0); -- do not update batches with status S, D, X

      select @vBatchesUpdated = @@rowcount,
             @vAuditActivity  = 'PickBatchModifyPriority',
             @vAuditNote1     = @vPriority;
    end
  else
  if (@vAction in ('Waves_Cancel', 'CancelBatch'))
    begin
      /* Loop through and cancel all the waves one by one */
      while (exists(select * from @ttPickBatches where RecordId > @vRecordId))
        begin
          /* select the top record from pickbatches */
          select top 1 @vPickBatchNo    = EntityKey,
                       @vRecordId       = RecordId,
                       @vAuditActivity  = null
          from @ttPickBatches
          where (RecordId > @vRecordId)
          order by RecordId;

        begin try
          exec pr_PickBatch_Cancel @vPickBatchNo, @UserId, @BusinessUnit, @vOperation, null /* MessageName */;

          set @vBatchesUpdated = @vBatchesUpdated + 1;
        end try
        begin catch
          /* Handles nothing and proceeds with the other batch */
        end catch
          /* If there are multiple batches then we cannot return the error message of one Batch,
             so clear it as we only can say how many batches failed or were successful. If it is
             a single batch, then we can return the specific message */
          if (@vBatchesUpdated > 1) select @MessageName = null;
        end
    end
  else
  if (@vAction = 'Waves_Plan')
    begin
      /* Update Wave as planned.
         batch Planned action will update the status of the batches as planned
         for the given batches which are in New status */
      update PB
      set Status         = 'B' /* Planned  */,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Inserted.RecordId, Inserted.BatchNo into @ttPickBatchesUpdated
      from PickBatches PB
        join @ttPickBatches ttPB on (ttPB.EntityKey = PB.BatchNo)
      where (PB.Status = 'N' /* New */)

      select @vBatchesUpdated = @@rowcount,
             @vAuditActivity  = 'PickBatchPlanned';
    end
  else
  if (@vAction = 'Waves_Unplan')
    begin
      /* Get the PickBatchId to log Audit Trail*/
      select @vPickBatchId = PB.RecordId
      from @ttPickBatches ttB
        join PickBatches PB on (PB.BatchNo = ttB.EntityKey);

      /* Update Wave as planned.
         batch Planned action will update the status of the batches as planned
         for the given batches which are in New status */
      update PB
      set Status         = 'N' /* New  */,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Inserted.RecordId, Inserted.BatchNo into @ttPickBatchesUpdated
      from PickBatches PB
        join @ttPickBatches ttPB on (ttPB.EntityKey = PB.BatchNo)
      where (PB.Status = 'B' /* Planned */)

      select @vBatchesUpdated = @@rowcount,
             @vAuditActivity  = 'PickBatchUnPlanned';
    end
  else
    /* If the action is other then 'UserBatchAssignments', send a message to UI saying Unsupported Action*/
    set @Message = 'UnsupportedAction';

  /* Audit trail */
  if (@vAuditActivity is not null)
    begin
      /* Multiple Batches would have been updated, we will generate one Audit Record
         and link all the updated batches to it */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, @vModifiedDate,
                                @PickBatchId   = @vPickBatchId,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vAuditNote1,
                                @AuditRecordId = @vAuditRecordId output;

      if (@vPickBatchId is null)
        exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Wave', @ttPickBatchesUpdated, @BusinessUnit;
    end;

  exec @Message = dbo.fn_Messages_BuildActionResponse 'Wave', @vAction, @vBatchesUpdated, @vBatchesCount, @Value1 = @vNotes;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @ErrorMsgParam1, @ErrorMsgParam2;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_Modify */

Go
