/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/12  PKK     pr_Entities_ExecuteProcess: Made changes to update TrackingNo on Orders (BK-866)
  2021/08/18  AY      pr_Entities_RecalcCounts/pr_Entities_ExecuteProcess: Added StartTime to track performance (HA-3098)
  2021/08/18  VS      pr_Entities_ExecuteProcess: Pass the operation (BK-475)
  2021/03/01  VS      pr_Entities_ExecuteProcess: Do not need to rollback when Process is canceled (X) (CIMSV3-1371)
  2021/02/10  TD      pr_Entities_ExecuteProcess:Changes to cancel tasks (cIMSV3-1387)
  2020/01/27  OK      pr_Entities_ExecuteProcess: Enhanced to process the UIActions with action procedures (CIMSV3-1266)
  2020/09/24  VS      pr_Entities_ExecuteProcess: Excluded Already Shipped Load & Shipping-In Progress Load from BackgroundProcess (S2GCA-1183)
  2020/08/28  TK      pr_Entities_ExecuteProcess: Changes to release tasks (HA-1211)
  2020/06/23  VS      pr_Entities_ExecuteProcess: Excluded Unallocated LPN from Background process (FB-2030)
  2020/02/27  MS      pr_Entities_ExecuteProcess: Changes to recount & preprocess ReceiptHeaders (JL-130)
                      pr_Entities_ExecuteProcess: Changes to load Pallet/LPN (S2GCA-970)
                      pr_Entities_ExecuteProcess: Included ReceiptHdr to process PrepareForReceiving (CIMSV3-474)
  2019/04/20  VS      pr_Entities_ExecuteProcess: Added Modify Wave Conditioin (cIMSV3-433)
  2018/12/03  AY      pr_Entities_ExecuteProcess: Ship LPN as background process (FB-1202)
  2018/07/30  PK      pr_Entities_ExecuteInBackGround, pr_Entities_ExecuteProcess: Differed shipping loads to mark as shipped
  2018/07/25  AY      pr_Entities_ExecuteProcess, pr_Entities_ExecuteInBackground: New procedures for
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_ExecuteProcess') is not null
  drop Procedure pr_Entities_ExecuteProcess ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_ExecuteProcess: Procedure that is run in a job to process
    the background execution requests.
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_ExecuteProcess
  (@ProcessClass    TClass = 'Process',
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vRecordId           TRecordId,
          @vEntityRecId        TRecordId,
          @vEntityType         TTypeCode,
          @vEntityId           TRecordId,
          @vEntityKey          TEntityKey,
          @vEntityStatus       TStatus,
          @vExecProcedureName  TName,
          @vInputParams        TXML,
          @vRecalcOption       TFlags,
          @xmlData             xml,
          @vStatus             TStatus,
          @vOperation          TOperation,
          @vErrorMsg           TMessage,
          @vMessage            TMessage,
          @vActivityLogId      TRecordId,
          @vTransScope         TTransactionScope,
          @vStartTime          TDateTime,
          @vBusinessUnit       TBusinessUnit,
          @vReturnCode         TInteger;

  declare @ttTaskPicksInfo     TTaskDetailsInfoTable,
          @ttEntityKeys        TEntityKeysTable,
          @ttWaves             TEntityKeysTable,
          @ttSelectedEntities  TEntityValuesTable,
          @ttResultMessages    TResultMessagesTable;

  declare @ttProcessesToExecute table (EntityRecId       TRecordId,
                                       EntityType        TEntity,
                                       EntityId          TRecordId,
                                       EntityKey         TEntityKey,
                                       InputParams       TXML,
                                       EntityStatus      TStatus,
                                       ProcessClass      TClass,
                                       Operation         TOperation,
                                       TransactionScope  TTransactionScope,
                                       ExecProcedureName TName,
                                       BusinessUnit      TBusinessUnit,

                                       IsProcessed       TFlag     default 'N',

                                       RecordId          TRecordId identity(1,1)
                                       primary key(RecordId),
                                       unique (IsProcessed, RecordId),
                                       unique (EntityId, EntityKey, RecordId));
begin
  SET NOCOUNT ON;

  /* Create temp tables */
  select * into #ttSelectedEntities from @ttSelectedEntities;
  select * into #ResultMessages     from @ttResultMessages;

  /* select all the processes to execute */
  insert into @ttProcessesToExecute(EntityRecId, EntityType, EntityId, EntityKey, EntityStatus, ProcessClass,
                                    ExecProcedureName, InputParams, Operation, BusinessUnit)
    select RecordId, EntityType, EntityId, EntityKey, EntityStatus, ProcessClass,
           ExecProcedureName, InputParams, Operation, BusinessUnit
    from BackgroundProcesses
    where (Status       = 'N' /* Not Yet Processed */) and
          (ProcessClass = coalesce(@ProcessClass, ProcessClass)) and
          (BusinessUnit = @BusinessUnit)
    order by RecordId;

  set @vRecordId = 0;

  while exists(select * from @ttProcessesToExecute where (RecordId > @vRecordId) and
                                                         (IsProcessed = 'N'/* No */))
    begin
      /* Get the next recordid that needs to be processed */
      select top 1 @vRecordId          = RecordId,
                   @vEntityRecId       = EntityRecId,
                   @vEntityType        = EntityType,
                   @vEntityId          = EntityId,
                   @vEntityKey         = EntityKey,
                   @vEntityStatus      = nullif(EntityStatus, ''),
                   @vExecProcedureName = ExecProcedureName,
                   @vOperation         = Operation,
                   @vBusinessUnit      = BusinessUnit,
                   @vStartTime         = current_timestamp,
                   @vStatus            = null, -- clear
                   @vInputParams       = InputParams,
                   @vMessage           = null  -- clear
      from @ttProcessesToExecute
      where (RecordId > @vRecordId) and (IsProcessed = 'N' /* No */)
      order by RecordId;

      /* Log in ActivityLog */
      exec pr_ActivityLog_AddMessage @vOperation, @vEntityId, @vEntityKey, @vEntityType, @vEntityStatus,
                                     @@ProcId, null /* xml */, @vBusinessUnit, @UserId, @Value1 = @ProcessClass,
                                     @ActivityLogId = @vActivityLogId output;

      begin try
        /* Determine if transactions are internal to procedure or started here */
        select @vTransScope = case when (charindex('_', @vExecProcedureName) = 1) then 'Procedure' else 'Caller' end;

        if (@vTransScope = 'Caller')
          begin transaction

        /* Strip out _ in the exec procedure name */
        if (charindex('_', @vExecProcedureName) = 1)
          select @vExecProcedureName = substring(@vExecProcedureName, 2, len(@vExecProcedureName));

        if (@vExecProcedureName is not null) and (@vInputParams is not null)
          begin
            /* This procedure inserts the records into #ttSelectedEntities temp table */
            exec pr_Entities_GetSelectedEntities @vEntityType, @vInputParams, @BusinessUnit, @UserId;

            /* Execute the action procedure */
            exec @vExecProcedureName @vInputParams, @BusinessUnit, @UserId;

            if (exists(select * from #ResultMessages))
              begin
                exec pr_Entities_BuildMessagesXML @vMessage output;
                set @vStatus = case when exists(select * from #ResultMessages where MessageType = 'E') then 'E' else 'P' end;
              end
          end
        else
        if (@vEntityType = 'Wave')
          begin
            /* Confirm Task Picks for given wave */
            if (charindex('ConfirmTaskPicks', @vOperation) <> 0)
              begin
                /* Initialize */
                delete from @ttTaskPicksInfo;

                /* Get all the picks to be confirmed */
                insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, FromLPNId, FromLPNDetailId,
                                             FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked)
                  select PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, LPNId, LPNDetailId,
                         LocationId, TempLabelId, TempLabelDetailId, Quantity
                  from TaskDetails
                  where (WaveId = @vEntityId) and
                        (Status not in ('C', 'X'/* Completed, Canceled */));

                /* Invoke procedure to confirm picks */
                exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, default/* Debug */;
              end

            /* Compute Dependencies on the Wave */
            if (charindex('UpdateDependencies' /* DependencyFlags */, @vOperation) <> 0)
              exec pr_Wave_UpdateDependencies default, @vEntityId, 'N'/* No - Don't compute TDs */;

            /* Cancel the Wave */
            if (charindex('CancelWave' /* Cancel Wave */, @vOperation) <> 0)
              exec pr_PickBatch_Cancel @vEntityKey, @UserId, @BusinessUnit, @vOperation, null /* MessageName */;

            /* Release Wave for Picking */
            if (charindex('ReleaseForPicking', @vOperation) <> 0)
              begin
                delete from @ttWaves;
                insert into @ttWaves (EntityId, EntityKey) select @vEntityId, @vEntityKey;

                exec pr_Wave_ReleaseForPicking @ttWaves, @xmldata /* Future use */, @BusinessUnit, @UserId;
              end
          end
        else
        if (@vEntityType = 'Task')
          begin
            /* Confirm Task Picks for given Task */
            if (charindex('ConfirmTaskPicks', @vOperation) <> 0)
              begin
                /* Initialize */
                delete from @ttTaskPicksInfo;

                /* Get all the picks to be confirmed */
                insert into @ttTaskPicksInfo(PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, FromLPNId, FromLPNDetailId,
                                              FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked)
                  select PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, LPNId, LPNDetailId,
                         LocationId, TempLabelId, TempLabelDetailId, Quantity
                  from TaskDetails
                  where (TaskId = @vEntityId) and
                        (Status not in ('C', 'X'/* Completed, Canceled */));

                /* Invoke procedure to confirm picks */
                exec pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPicks', @BusinessUnit, @UserId, default/* Debug */;
              end

            /* Task release */
            if (charindex('TaskRelease', @vOperation) <> 0)
              exec pr_Tasks_Release default, @vEntityId, null /* BatchNo */, default, @BusinessUnit, @UserId;

            /* Task Cancel */
            if (charindex('TaskCancel', @vOperation) <> 0)
              begin
                insert into @ttEntityKeys (EntityId) select @vEntityId;

                exec pr_Tasks_Cancel @ttEntityKeys, null /* TaskId */, null /* WaveNo */, @BusinessUnit, @UserId, @vMessage out;
              end
          end
        else
        if (@vEntityType = 'Load')
          begin
            /* Mark the Load as shipped */
            if (charindex('ConfirmLoadAsShipped', @vOperation) <> 0)
              exec @vReturnCode = pr_Load_MarkAsShipped @vEntityId, @BusinessUnit, @UserId, null, @Operation = 'BackgroundProcess';

            /* Exclude Already Shipped Load & Shipping_in Progress from the Background Process */
            if (@vReturnCode = 2 /* Load is Already shipped, or Shipping-In Progress */)
              select @vStatus = 'X' /* Cancelled */;
          end
        else
        if (@vEntityType = 'Location')
          begin
            /* If a Replenish Picked LPN is being putaway into other than dest Location then transfer reserved quantities to
               new picklane */
            if (charindex('ReplenishLPNPutawayToDiffLoc', @vOperation) <> 0)
              begin
                /* Transfer Reserved Quantities */
                exec pr_Locations_TransferReservation @vInputParams;
              end
          end /* End If - Location Entity */
        else
        if (@vEntityType = 'LPN')
          begin
            /* Load LPN */
            if (charindex('LoadPalletOrLPN', @vOperation) <> 0)
              exec pr_Loading_LoadPalletOrLPN null/* LoadId */, null/* PalletId */, @vEntityId, 'BackgroundProcess', @BusinessUnit, @UserId;

            /* Ship the LPN */
            if (charindex('LPNShip', @vOperation) <> 0)
              begin
                /* Check if LPN is already shipped or not, if shipped then exclude calling LPN_Ship */
                exec @vReturnCode = pr_LPNs_Ship @vEntityId, @vEntityKey, @BusinessUnit, @UserId, @UpdateOption = 'O$WL' /* Update Wave later */, @Operation = 'BackgroundProcess';

                /* Exclude Unallocated LPNs from the Background process */
                if (@vReturnCode = 2 /* Already shipped, or LPN not allocated anymore */)
                  select @vStatus = 'X' /* Cancelled */;
              end
          end
        else
        if (@vEntityType = 'Pallet')
          begin
            /* Load Pallet */
            if (charindex('LoadPalletOrLPN', @vOperation) <> 0)
              exec pr_Loading_LoadPalletOrLPN null/* LoadId */, @vEntityId, null/* LPNId */, 'BackGroundProcess', @BusinessUnit, @UserId;

            /* Explode the Pallet */
            if (charindex('Pallet_ExplodeForShipping', @vOperation) <> 0)
              exec pr_Pallets_ExplodeForShipping @vEntityId, @vEntityKey, default, @vOperation, @BusinessUnit, @UserId;
          end
        else
        if (@vEntityType in ('Receipt', 'ReceiptHdr'))
          begin
            if (charindex('Preprocess', @vOperation) <> 0)
              begin
                select @vOperation = replace(@vOperation, 'Preprocess_', '');

                exec pr_ReceiptHeaders_Preprocess @vEntityId, @vOperation, @BusinessUnit;
              end
            else
            if (charindex('PrepareForReceiving', @vOperation) <> 0)
              exec pr_Receipts_PrepareForReceiving @vEntityId /* Receipt Id */, @vEntityKey /* Receipt Number */,
                                                   null /* ReceiverId */, null /* ReceiverNumber */,
                                                   Default /* LPNs */, @vOperation, @BusinessUnit, @UserId,
                                                   @vMessage output;
          end /* End If - ReceiptHdr Entity */
        else
        if (@vEntityType = 'Receiver')
          begin
            if (charindex('PrepareForReceiving', @vOperation) <> 0)
              exec pr_Receipts_PrepareForReceiving null /* Receipt Id */, null /* Receipt Number */,
                                                   @vEntityId /* ReceiverId */, @vEntityKey /* ReceiverNumber */,
                                                   Default /* LPNs */, @vOperation, @BusinessUnit, @UserId,
                                                   @vMessage output;

          end /* End If - Receiver Entity */
        else
        if (@vEntityType = 'Order')
          begin
            if (@vOperation = 'UpdateTrackingNos')
              exec pr_OrderHeaders_UpdateTrackingNo @vEntityId;
          end

        /* set IsProcessed flag to 'Y' on processed entity such that it won't be processed again */
        update @ttProcessesToExecute
        set IsProcessed = 'Y' /* Yes */
        where (RecordId = @vRecordId);

        /* Update Status of the entity after processing */
        update BackgroundProcesses
        set Status        = coalesce(@vStatus, 'P' /* Processed */),
            ResultMessage = @vMessage,
            StartTime     = @vStartTime,
            ProcessedTime = current_timestamp
        where (Recordid = @vEntityRecId) and (Status = 'N');

        /* Close the Log to denote end time */
        exec pr_ActivityLog_AddMessage @vOperation, @vEntityId, @vEntityKey, @vEntityType, @vEntityStatus,
                                       @ActivityLogId = @vActivityLogId output;

        /* Clear the temp tables */
        delete from #ResultMessages;

      if (@vTransScope = 'Caller')
        commit transaction;
      end try
      begin catch
        if (@@trancount > 0) rollback transaction;

        select @vErrorMsg = ERROR_MESSAGE();

        /* Close the Log to denote end time */
        exec pr_ActivityLog_AddMessage @vOperation, @vEntityId, @vEntityKey, @vEntityType, @vErrorMsg,
                                       @ActivityLogId = @vActivityLogId output;

        exec pr_ReraiseError; -- quit
      end catch
    end /* while .. more records to process */
end/* pr_Entities_ExecuteProcess */

Go
