/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/24  RKC     pr_Picking_ValidateSubstitution: Added validations for Substitutions process
                        pr_Picking_SwapLPNsDataForSubstitution; Changes to Substitute the LPNs in different cases (BK-819)
  2015/12/18  DK      pr_Picking_SwapLPNsDataForSubstitution: Bug fix to Swap LoadId and ShipmentId on LPNs during Substitution (FB-572).
  2015/02/26  VM      pr_Picking_SwapLPNsDataForSubstitution: Recount all Tasks of Actual and Substituted LPNs
  2015/02/04  VM      pr_Picking_SwapLPNsDataForSubstitution, pr_Picking_ValidateSubstitution: Introduced
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_SwapLPNsDataForSubstitution') is not null
  drop Procedure pr_Picking_SwapLPNsDataForSubstitution;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_SwapLPNsDataForSubstitution:
    What it does - 1. Identify the task and task detail for Actual LPN
                   2. Identify the task for Substituted LPN
                   3. Swap between Actual LPN Details and Substituted LPN Details
                     3.1 Both the LPN Qty Match then Swap the LPNDetails between LPNs
                     3.2 Both the LPN total Reserved Qty Matches then Swap the Reserved lines between the LPNs
                     3.3 Both the LPNDetail Reserved Line Qty Match then Swap the respective R- Lines LPNDetails
                     3.4 Substituted LPN Total Available Quantity is greater than or equal to the TaskDetail Qunatity then
                      a)Move the Respective actual LPN R line to Substituted LPN
                      b)Added the transfer Quantity to Actual LPN available Line Quantity
                        1)If no available line then create the new line with the transfer Quantity
                      c)Reduce the transfer Quantity on Substitute LPN Avilable line
                   4. Swap PickBatchId, PickBatchNo on LPNs
                   5. update Tasks Details of Actual LPN task(single task) with Substituted LPN and vice versa
                   6. Swap Task SubType
                   7. Recount Actual and Substituted LPNs
                   8. Recount Actual and Substituted Tasks
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_SwapLPNsDataForSubstitution
  (@ActualLPN       TLPN,
   @SubstitutedLPN  TLPN,
   @TaskDetailId    TRecordId /* Picking Order detail */,
   @UserId          TUserId   = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vRecordId          TRecordId,

          @vSKUId                   TRecordId,

          @vActualLPNId             TRecordId,
          @vActualLPNQuantity       TCount,
          @vActualLPNNewStatus      TStatus,
          @vActualLPNOrderId        TRecordId,
          @vActualLPNPickBatchId    TRecordId,
          @vActualLPNPickBatchNo    TPickBatchNo,
          @vActualLPNShipmentId     TShipmentId,
          @vActualLPNLoadId         TLoadId,
          @vActualLPNLoadNumber     TLoadNumber,
          @vActualLPNTotalAQty      TQuantity,
          @vActualLPNTotalRQty      TQuantity,

          @vActualLPNTaskId         TRecordId,
          @vActualLPNTaskSubType    TTypeCode,
          @vActualLPNTaskDetailId   TRecordId,
          @vActualLDRQty            TQuantity,
          @vAvlbLPNDetailId         TRecordId,

          @vSubstitutedLPNId          TRecordId,
          @vSubstitutedLPNQuantity    TCount,
          @vSubstitutedLPNNewStatus   TStatus,
          @vSubstitutedLPNPickBatchId TRecordId,
          @vSubstitutedLPNPickbatchNo TPickBatchNo,
          @vSubstitutedLPNShipmentId  TShipmentId,
          @vSubstitutedLPNLoadId      TLoadId,
          @vSubstitutedLPNLoadNumber  TLoadNumber,
          @vSubstitutedLPNTaskId      TRecordId,
          @vSubstitutedLPNTaskSubType TTypeCode,
          @vSubstitutedLPNTotalAQty   TQuantity,
          @vSubstitutedLPNTotalRQty   TQuantity,

          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vWavetype                  TTypeCode,

          @vTaskDetailId              TRecordId,
          @vTaskId                    TRecordId,
          @vTaskSubType               TTypeCode,
          @vTDQuantity                TQuantity,
          @vTDLPNId                   TRecordId,
          @vTDLPNDetailId             TRecordId,
          @vBusinessUnit              TBusinessUnit,
          @ttSubstituteLPNPicks       TEntityKeysTable,
          @ttActualLPNPicks           TEntityKeysTable,
          @Criteria                   TString;

  declare @ttLPNDetails table
          (LPNDetailId      TRecordId,
           LPNId            TRecordId,
           LPN              TLPN,
           OnhandStatus     TStatus,
           Quantity         TQuantity,
           ProcessFlag      TFlags,
           RecordId         TRecordId identity(1,1)
          )

begin /* pr_Picking_SwapLPNsDataForSubstitution */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Create temp tables */
  select * into #SubstitutedLPNDetails from @ttLPNDetails;
  select * into #ActualLPNDetails      from @ttLPNDetails;

  /* 1. 1. Identify the task and task detail for Actual LPN */
  /* Get actual LPN Task & Task Detail
  ***  Assumption - Currently works for LPN pick task ONLY. So, the following returns ONE task detail and task only *****/
  select @vActualLPNId           = L.LPNId,
         @vSKUId                 = L.SKUId,
         @vActualLPNQuantity     = L.Quantity,
         @vActualLPNOrderId      = L.OrderId,
         @vActualLPNPickBatchId  = L.PickBatchId,
         @vActualLPNPickBatchNo  = L.PickBatchNo,
         @vActualLPNShipmentId   = L.ShipmentId,
         @vActualLPNLoadId       = L.LoadId,
         @vActualLPNLoadNumber   = L.LoadNumber,
         @vActualLPNTaskId       = T.TaskId,
         @vActualLPNTaskSubType  = T.TaskSubType,
         @vActualLPNTaskDetailId = TD.TaskDetailId,
         @vBusinessUnit          = L.BusinessUnit
  from LPNs L
    join TaskDetails TD on (L.LPNId = TD.LPNId) and (TD.TaskDetailId = coalesce(@TaskDetailId /* suggested(passedin) task detail */, TD.TaskDetailId)) and
                           (TD.Status not in ('X', 'C'))
    join Tasks       T  on (TD.TaskId = T.TaskId)
  where (L.LPN = @ActualLPN);

    /* Get the Actuval LPN Details Qty's */
  select @vActualLPNTotalRQty = sum(case when OnhandStatus in ('R'/* Reserved */) then Quantity else 0 end),
         @vActualLPNTotalAQty = sum(case when OnhandStatus in ('A'/* Avilable */) then Quantity else 0 end)
  from LPNDetails
  where (LPNId = @vActualLPNId);

  /* 2. Identify the task for Substituted LPN */
  /* Get Substituted LPN Task
     There is a possibility that there are no tasks for substituted LPN - hence left join used */
  select top 1 -- As there could be multiple tasks there for Substituted LPN
           @vSubstitutedLPNId           = L.LPNId,
           @vSubstitutedLPNQuantity     = L.Quantity,
           @vSubstitutedLPNPickBatchId  = L.PickBatchId,
           @vSubstitutedLPNPickbatchNo  = L.PickBatchNo,
           @vSubstitutedLPNShipmentId   = L.ShipmentId,
           @vSubstitutedLPNLoadId       = L.LoadId,
           @vSubstitutedLPNLoadNumber   = L.LoadNumber,
           @vSubstitutedLPNTaskSubType  = T.TaskSubType,
           @vSubstitutedLPNTaskId       = T.TaskId
  from LPNs L
    left join TaskDetails TD on (L.LPNId = TD.LPNId) and
                                (TD.Status not in ('X', 'C'))
    left join Tasks       T  on (TD.TaskId = T.TaskId)
  where L.LPN = @SubstitutedLPN;

  /* Get the Sub LPNDetails Qty's */
  select @vSubstitutedLPNTotalRQty = sum(case when OnhandStatus in ('R'/* Reserved */) then Quantity else 0 end),
         @vSubstitutedLPNTotalAQty = sum(case when OnhandStatus in ('A'/* Avilable */) then Quantity else 0 end)
  from LPNDetails
  where (LPNId = @vSubstitutedLPNId);

  /* Get the task info */
  select @vTaskDetailId  = TaskDetailId,
         @vTaskId        = TaskId,
         @vTaskSubType   = PickType,
         @vWaveId        = WaveId,
         @vTDQuantity    = Quantity,
         @vTDLPNId       = LPNId,
         @vTDLPNDetailId = LPNDetailId
  from TaskDetails
  where (TaskDetailId = @TaskDetailId)

  /* Get Actual and Substituted LPNs picks to recount them later below */
  insert into @ttActualLPNPicks (EntityId)
    select distinct TaskId from TaskDetails  where LPNId = @vActualLPNId;

  insert into @ttSubstituteLPNPicks (EntityId)
    select distinct TaskId from TaskDetails where LPNId = @vSubstitutedLPNId;

  /* Get the Actual LPN Details */
  insert into #ActualLPNDetails  (LPNDetailId, LPNId, OnhandStatus, Quantity, ProcessFlag)
    select LPNDetailId, LPNId, OnhandStatus, Quantity, 'N' from LPNDetails where (LPNId = @vActualLPNId);

  /* Get the Substituted LPN Details */
  insert into #SubstitutedLPNDetails (LPNDetailId, LPNId, OnhandStatus, Quantity, ProcessFlag)
    select LPNDetailId, LPNId, OnhandStatus, Quantity, 'N' from LPNDetails where (LPNId = @vSubstitutedLPNId);

  /********  3. Swap between Actual LPN Details and Substituted LPN Details  *******/

  /* 3.1 If both the LPNs Quantities Match then Swap the both LPNs Details */
  if (@vSubstitutedLPNQuantity = @vActualLPNQuantity)
    begin
      select @Criteria = 'SwapAllLines';

      update #ActualLPNDetails      set ProcessFlag = 'Swap';
      update #SubstitutedLPNDetails set ProcessFlag = 'Swap';
    end
  else
  /* 3.2 If both LPN's Reserved line Quantities Match then Swap the all the Reserved lines on both the LPNs */
  if (@vSubstitutedLPNTotalRQty = @vActualLPNTotalRQty)
    begin
      select @Criteria = 'SwapRLines';

      update #ActualLPNDetails      set ProcessFlag = 'Swap' where OnhandStatus = 'R';
      update #SubstitutedLPNDetails set ProcessFlag = 'Swap' where OnhandStatus = 'R';
    end

  /* Get the Matched reserved lines on the both the LPNs */
  select ALD.LPNDetailId ALDDetailId, SLD.LPNDetailId SLDDetailId
  into #MatchingReservedLines
  from #ActualLPNDetails ALD
    join #SubstitutedLPNDetails SLD on (ALD.Quantity     = SLD.Quantity) and
                                       (ALD.Onhandstatus = 'R') and
                                       (SLD.Onhandstatus = 'R')
  where (ALD.LPNId = @vActualLPNId) and (SLD.LPNId = @vSubstitutedLPNId)

  /* 3.3 If both LPN's Reserved Line Quantities are matched then Swap the respective R- Lines between the LPNs */
  if exists (select * from #MatchingReservedLines)
    begin
      select @Criteria = 'SwapRLine';

      update #ActualLPNDetails      set ProcessFlag = 'Swap' where LPNDetailId in (select ALDDetailId from #MatchingReservedLines);
      update #SubstitutedLPNDetails set ProcessFlag = 'Swap' where LPNDetailId in (select SLDDetailId from #MatchingReservedLines);
    end

  /* Swap between Actual LPN Details and Substituted LPN Details
     set Actual LPN Details LPN Id to Substituted LPN Id */

  if exists (select * from #ActualLPNDetails where ProcessFlag = 'Swap')
    begin
      update LPNDetails
      set LPNId = @vSubstitutedLPNId
      from LPNDetails LD join #ActualLPNDetails ALD on (LD.LPNDetailId = ALD.LPNDetailId) and
                                                       (LD.LPNId       = ALD.LPNId)
      where (LD.LPNId = @vActualLPNId) and (ProcessFlag = 'Swap');

      /* Set Substituted LPN Details LPN Id to Actual LPN Id */
      update LPNDetails
      set LPNId = @vActualLPNId
      from LPNDetails LD join #SubstitutedLPNDetails SLD on (LD.LPNDetailId = SLD.LPNDetailId) and
                                                            (LD.LPNId       = SLD.LPNId)
      where (LD.LPNId = @vSubstitutedLPNId) and (ProcessFlag = 'Swap');

    end
  else
  /* 3.4 Substituted LPN Total Avilable Quantity is grater than or equal to the TaskDetail Qunatity then
         a)Move the Respective actuval LPNDetail R line to Substituted LPN
         b)Added the transfer Quantity to Actuval LPN avilable Line Quantity
          1) If no avilable line then create the new line with the transfer Quantity
         C)Reduce the transfer Quantity on Substitute LPN Avilable line
  */
  if (@vSubstitutedLPNTotalAQty >= @vTDQuantity)
    begin
      update #ActualLPNDetails set ProcessFlag = 'Swap'
      where (LPNId = @vActualLPNId) and (LPNDetailId = @vTDLPNDetailId) and (OnhandStatus = 'R');

      update LPNDetails
      set @vActualLDRQty      = LD.Quantity,
          @vSKUId             = SKUId,
          LPNId               = @vSubstitutedLPNId
      from LPNDetails LD join #ActualLPNDetails ALD on (LD.LPNDetailId = ALD.LPNDetailId) and
                                                       (LD.LPNId = ALD.LPNId)
      where (LD.LPNId = @vActualLPNId) and (ProcessFlag = 'Swap');

      /* Reduce the transfer Quantity on Substitute LPN Available line */
      update LD
      set Quantity -= coalesce(@vActualLDRQty, 0)
      from LPNDetails LD
       join #SubstitutedLPNDetails SLD on (LD.LPNDetailId = SLD.LPNDetailId) and (LD.LPNId = SLD.LPNId)
      where (LD.LPNId = @vSubstitutedLPNId) and (LD.OnhandStatus = 'A');

      /* If Avilable Details exists then update the substituted Qty on the Actual LPN*/
      if exists (select * from #ActualLPNDetails where (LPNId = @vActualLPNId) and (OnHandStatus = 'A'))
        begin
          update LPNDetails
          set Quantity += @vActualLDRQty
          from LPNDetails LD
            join #ActualLPNDetails ALD on (LD.LPNDetailId = ALD.LPNDetailId) and (LD.LPNId = ALD.LPNId)
          where (LD.LPNId = @vActualLPNId) and (LD.OnHandStatus = 'A');
        end
      else
        /* If Avilable lines does not exists then create new line with substituted Qty on the Actual LPN*/
        begin
          exec @vReturnCode = pr_LPNDetails_AddOrUpdate @vActualLPNId, null /* LPNLine */, null /* CoO */,
                                                       @vSKUId, null /* SKU */, null /* innerpacks */, @vActualLDRQty,
                                                       0 /* ReceivedUnits */, null /* ReceiptId */,  null /* ReceiptDetailId */,
                                                       null /* OrderId */, null /* OrderDetailId */, null /* OnHandStatus */,
                                                       null /* Operation */, null /* Weight */, null /* Volume */, null /* Lot */,
                                                       @vBusinessUnit /* BusinessUnit */, @vAvlbLPNDetailId output;

          /* Log audit here */
          exec pr_AuditTrail_Insert 'LPNSubstitute_AddNewLine', @UserId, null /* ActivityTimestamp */,
                            @SKUId           = @vSKUId,
                            @LPNId           = @vActualLPNId,
                            @Note1           = @vActualLDRQty;
        end
    end
  else
    begin
      /* If any of above conditions not staticfied then send a message to RF saying Unsupported Substitution process Not Possible*/
      set @vMessageName = 'SubstitutionNotPossible';
      goto ErrorHandler;
    end;

  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* 4. If Swap Criteria is All lines then only we need to update the respective PickBatchId, PickBatchNo on both the LPNs */
  if (@Criteria = 'SwapAllLines')
    begin
      update LPNs
      set PickBatchId = @vSubstitutedLPNPickBatchId,
          PickBatchNo = @vSubstitutedLPNPickbatchNo,
          ShipmentId  = @vSubstitutedLPNShipmentId,
          LoadId      = @vSubstitutedLPNLoadId,
          LoadNumber  = @vSubstitutedLPNLoadNumber,
          TaskId      = @vSubstitutedLPNTaskId
      where (LPNId = @vActualLPNId);

      update LPNs
      set PickBatchId = @vActualLPNPickBatchId,
          PickBatchNo = @vActualLPNPickBatchNo,
          ShipmentId  = @vActualLPNShipmentId,
          LoadId      = @vActualLPNLoadId,
          LoadNumber  = @vActualLPNLoadNumber,
          TaskId      = @vActualLPNTaskId
      where (LPNId = @vSubstitutedLPNId);
    end

  /* 5. update Tasks Details of Actual LPN task with Substituted LPN and vice versa */
  update TD
  set LPNId  = @vSubstitutedLPNId
  from TaskDetails TD
    join #ActualLPNDetails ALD on (TD.LPNDetailId = ALD.LPNDetailId) and (TD.LPNId = ALD.LPNId)
  where (TD.LPNId = @vActualLPNId) and
        (Status not in('C', 'X' /* Completed, Cancelled */)) and
        (ALD.ProcessFlag = 'Swap');

  update TD
  set LPNId = @vActualLPNId
  from TaskDetails TD
      join #SubstitutedLPNDetails SLD on (TD.LPNDetailId = SLD.LPNDetailId) and (TD.LPNId = SLD.LPNId)
  where (TD.LPNId = @vSubstitutedLPNId) and
        (Status not in('C', 'X' /* Completed, Cancelled */)) and
        (SLD.ProcessFlag = 'Swap');

  /*  There might be multiple tasks on Actual LPN or Substition LPN
      hence, we need to identify all those TaskIds and recount */
  select @vRecordId = 0;

  /* 7A. Recount Actual Tasks */
  while (exists(select * from @ttActualLPNPicks where RecordId > @vRecordId))
    begin
      select top 1
             @vRecordId        = RecordId,
             @vActualLPNTaskId = EntityId
      from @ttActualLPNPicks
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_Tasks_ReCount @vActualLPNTaskId;
    end

  select @vRecordId = 0;

  /* 7B. Recount Substituted Tasks */
  while (exists(select * from @ttSubstituteLPNPicks where RecordId > @vRecordId))
    begin
      select top 1
             @vRecordId             = RecordId,
             @vSubstitutedLPNTaskId = EntityId
      from @ttSubstituteLPNPicks
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_Tasks_ReCount @vSubstitutedLPNTaskId;
    end

  /* 8. Recount Actual and Substituted LPNs */
  exec pr_LPNs_Recount @vActualLPNId, @UserId, @vActualLPNNewStatus output;
  exec pr_LPNs_Recount @vSubstitutedLPNId, @UserId, @vSubstitutedLPNNewStatus output;

  if (@vSubstitutedLPNNewStatus = 'P' /* Putaway */)
    update LPNs
    set OrderId      = null,
        TaskId       = null,
        ShipmentId   = 0,
        LoadId       = 0,
        LoadNumber   = null,
        BoL          = null,
        PickBatchId  = null,
        PickBatchNo  = null,
        ModifiedDate = current_timestamp,
        ModifiedBy   = @UserId
    where (LPNId = @vSubstitutedLPNId);

  if (@vActualLPNNewStatus = 'P' /* Putaway */)
    update LPNs
    set OrderId      = null,
        TaskId       = null,
        ShipmentId   = 0,
        LoadId       = 0,
        LoadNumber   = null,
        BoL          = null,
        PickBatchId  = null,
        PickBatchNo  = null,
        ModifiedDate = current_timestamp,
        ModifiedBy   = @UserId
    where (LPNId = @vActualLPNId);

  /* Log audit here */
  exec pr_AuditTrail_Insert 'LPNSubstitute', @UserId, null /* ActivityTimestamp */,
                            @SKUId           = @vSKUId,
                            @LPNId           = @vActualLPNId,
                            @ToLPNId         = @vSubstitutedLPNId,
                            @OrderId         = @vActualLPNOrderId,
                            @PickBatchId     = @vActualLPNPickBatchId,
                            @Note1           = @vActualLPNQuantity,
                            @Note2           = @vSubstitutedLPNQuantity;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Picking_SwapLPNsDataForSubstitution */

Go

/*------------------------------------------------------------------------------
  Proc pr_Picking_UnitPickResponse: This Procedure returns the details of the
    Pick to be issued for Unit Picking as an XML String.

  Parameters:
    LPNIdToPickFrom - LPNId of the LPN
    LPNToPickFrom   - LPN (why do we need both of these parms? LPNId is the unique
                      field that identifies the LPN that will be picked (LPN is
                      not unique, however in AX we do not have LPNId and so we
                      use LPN)

    PickType        - U for Units
------------------------------------------------------------------------------*/
