/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/09  TK      pr_Tasks_GenerateTempLabels: Recount order so that NumLPNs infor will be updated on the Order (S2G-1005)
  2018/06/14  YJ      pr_Tasks_GenerateTempLabels: Changes to get the control value of UCC128Required, BarcodeType : Migrated from staging (S2G-727)
  RV      pr_Tasks_GenerateTempLabels: Update dummy carton with for Temp LPNs (S2G-655)
  2018/04/14  TK      pr_Tasks_GenerateTempLabels: Changes to print temp LPNs from PTLC waves (S2G-619)
  2014/08/20  TK      pr_Tasks_GenerateTempLabels: Updated to Generate Temp Labels for tasks 'On Hold' Status.
  2014/06/05  TD      pr_Tasks_GenerateTempLabels:Changes to update UCCbarcode for the
  2014/05/12  TD      Added pr_Tasks_GenerateTempLabelsForEcomWave.
  2014/04/18  TD      pr_Tasks_GenerateTempLabels:Changes to generate temp labels.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_GenerateTempLabels') is not null
  drop Procedure pr_Tasks_GenerateTempLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_GenerateTempLabels:
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_GenerateTempLabels
  (@PickBatchNo    TPickBatchNo = null,
   @Tasks          TEntityKeysTable readonly,
   @TaskId         TRecordId    = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vRecordId          TRecordId,
          @vTaskId            TRecordId,
          @vPrevTaskId        TRecordId,
          @vTaskDetailId      TRecordId,
          @vTaskSubType       TTypeCode,
          @vDestZone          TZoneId,
          @vWarehouse         TWarehouse,
          @vLPNId             TRecordId,
          @vLPNDetailId       TRecordId,
          @vTempLPNId         TRecordId,
          @vTempLPN           TLPN,
          @vPrevBatchNo       TPickBatchNo,
          @vUCCBarcode        TBarcode,
          @vNextPackageSeqNo  TInteger,

          @vTDRecordId        TRecordId,
          @vSKUId             TRecordId,
          @vNumCases          TCount,
          @vQtyPerTempLabel   TQuantity,
          @vCasesPerTempLabel TQuantity,
          @vOrderId           TRecordId,
          @vOrderDetailId     TRecordId,
          @vTempLPNDetailId   TRecordId,
          @vPickBatchNo       TPickBatchNo,
          @vPickBatchId       TRecordId,
          @vTDGroupSet        TCategory,
          @vPrevTDGroupSet    TCategory,
          @vUCC128Required    TControlValue,
          @vBarcodeType       TTypeCode,
          @vControlCategory   TCategory;

  declare @ttLPNTasks         TLPNTasksTable,
          @ttTasks            TEntityKeysTable,
          @ttOrdersToRecount  TEntityKeysTable;

  declare @ttTaskDetails table
           (RecordId       TRecordId identity(1, 1),
            BatchNo        TPickBatchNo,
            TaskId         TRecordId,
            TaskDetailId   TRecordId,
            LPNId          TRecordId,
            LPNDetailId    TRecordId,
            SKUId          TRecordId,
            NumCases       TCount,
            Quantity       TQuantity,
            OrderId        TRecordId,
            OrderDetailId  TRecordId,
            DestZone       TZoneId,
            Warehouse      TWarehouse,

            TDGroupSet     TCategory);

begin /* pr_Tasks_GenerateTempLabels */
  SET NOCOUNT ON;

  /* set default values here */
  select @vPrevBatchNo       = '',
         @vCasesPerTempLabel = 1,
         @vPrevTaskId        = 0,
         @vPrevTDGroupSet    = 0,
         @vRecordId          = 0;

  /* Assumption: User will Pass TaskId or List of tasks */
  /* get the Tasks into temp table if the user has given the TaskId */
  if (coalesce(@TaskId, 0) > 0)
    begin
      insert into @ttTasks (EntityId)
        select TaskId
        from Tasks
        where ((TaskId   = @TaskId             ) and
               (TaskType = 'PB' /* PickBatch */) and
               (TaskSubType in ('L', 'CS')     ) and
               (Status in ('N','O') /* New, OnHold */) and
               (BusinessUnit = @BusinessUnit)  );
    end
  else
  if (@PickBatchNo is not null)
    begin
      insert into @ttTasks (EntityId)
        select TaskId
        from Tasks
        where (BatchNo  = @PickBatchNo        ) and
              (TaskType = 'PB' /* PickBatch */) and
              (TaskSubType in ('L', 'CS')     ) and
              (Status in ('N','O') /* New, OnHold */) and
              (BusinessUnit = @BusinessUnit   );
    end
  else
    begin
      insert into @ttTasks (EntityId)
        select T.TaskId
        from @Tasks TT
        join Tasks T on (T.TaskId = TT.Entityid)
        where ((T.TaskType = 'PB' /* PickBatch */) and
               (T.TaskSubType in ('L', 'CS')     ) and
               (T.Status in ('N','O') /* New, OnHold */) and
               (T.BusinessUnit = @BusinessUnit   ));
    end

  if (@@rowcount = 0)
    return;

  /* insert all details into temp table to create temp labels
     This is only for LPN Type and Case type picks
     For replenishment, we have to set the TDGroupSet to TaskId as we have to generate
     packageseqno by task. For Other regular orders, it is by order */
  insert into @ttTaskDetails (BatchNo, TaskId, TaskDetailId, LPNId, LPNDetailId,
                              SKUId, NumCases, Quantity, OrderId, OrderDetailId,
                              DestZone, Warehouse, TDGroupSet)
    select PT.BatchNo, PT.TaskId, PT.TaskDetailId, PT.LPNId, PT.LPNDetailId, PT.SKUId,
           PT.DetailInnerPacks, PT.DetailQuantity, PT.OrderId, PT.OrderDetailId,
           PT.DestZone, PT.Warehouse,
           case when PT.BatchType in ('R', 'RU', 'RP'/* Replenish */)
                  then PT.TaskId
                else PT.OrderId
           end /* TDGroupSet */
    from vwPickTasks PT
    join @ttTasks TT on TT.EntityId = PT.TaskId
    where (coalesce(PT.DetailInnerPacks, 0) > 0) and
          (coalesce(PT.IsLabelGenerated, 'T') = 'T' /* Temp Label */)
    order by case when PT.BatchType in ('R', 'RU', 'RP'/* Replenish */)
                    then PT.TaskId + PT.PickPath + PT.TaskDetailId
                  else PT.OrderId
             end;  -- The order is important as we have to print the seq no on the labels

  /* loop through taskdetails and generate a temp table for each InnerPack */
  while (exists(select * from @ttTaskDetails where RecordId > @vRecordId))
    begin
      /* get the top 1 record from the temp table */
      select top 1 @vRecordId        = RecordId,
                   @vTaskId          = TaskId,
                   @vTaskDetailId    = TaskDetailId,
                   @vNumCases        = NumCases,
                   @vLPNId           = LPNId,
                   @vLPNDetailId     = LPNDetailId,
                   @vSKUId           = SKUId,
                   @vDestZone        = DestZone,
                   @vWarehouse       = Warehouse,
                   @vOrderId         = OrderId,
                   @vOrderDetailId   = OrderDetailId,
                   @vPickBatchNo     = BatchNo,
                   @vQtyPerTempLabel = case
                                         when NumCases > 0 then (Quantity / NumCases)
                                         else Quantity
                                       end,
                  @vTDGroupSet       = TDGroupSet
      from @ttTaskDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get PickBacthId here */
      if (@vPrevBatchNo <> @vPickBatchNo)
        select @vPickBatchId     = RecordId,
               @vControlCategory = 'PickBatch_' + BatchType
        from PickBatches
        where (BatchNo      = @vPickBatchNo) and
              (BusinessUnit = @BusinessUnit)

      /* Get the control value to see if the cartons/packages on this wave requires to generate UCC128 barcode or not */
      select @vUCC128Required = dbo.fn_Controls_GetAsString (@vControlCategory, 'UCC128Required?', 'N' /* Default */, @BusinessUnit, @UserId),
             @vBarcodeType    = dbo.fn_Controls_GetAsString (@vControlCategory, 'BarcodeType', 'UCC128' /* Default */, @BusinessUnit, @UserId);

      /* if the order has changed, then reset the seq number */
      if (@vPrevTDGroupSet <> @vTDGroupSet)
        select @vNextPackageSeqNo = 0;

      /* We need to generate temp labels for each case, so we need
        to loop that until all cases done */
      while (@vNumCases > 0)
        begin
          /* Create temp label here */
          exec @vReturnCode = pr_LPNs_Generate 'C',              /* @LPNType - Carton */
                                                1,               /* @NumLPNsToCreate  */
                                                null,            /* @LPNFormat        */
                                                @vWarehouse,     /* Warehouse         */
                                                @BusinessUnit,   /* TBusinessUnit     */
                                                @UserId,         /* TUserId           */
                                                @vTempLPNId   output,
                                                @vTempLPN     output;

          /* if LPNId is not null then insert the details */
          if (@vTempLPNId is not null)
            exec @vReturnCode = pr_LPNDetails_AddOrUpdate @vTempLPNId, null /* LPN Line */,
                                                          null /* Coo */, @vSKUId, null /* SKU */,
                                                          @vCasesPerTempLabel, @vQtyPerTempLabel, /* Quantity */
                                                          null /* rec units*/, null,
                                                          null, /* Receiptid , receiptdetailid */
                                                          @vOrderId, @vOrderDetailId, null /* OnHandStatus */, null /* Operation */,
                                                          null, null, null, /* Weight, Volume , Lot */
                                                          @BusinessUnit, @vTempLPNDetailId output;

          /* insert details into LPNTasks Table */
          insert into @ttLPNTasks(PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId,
                                  LPNDetailId, DestZone, Warehouse, BusinessUnit)
            select @vPickBatchId, @vPickBatchNo, @vTaskId, @vTaskDetailId, @vTempLPNId,
                   @vTempLPNDetailId, @vDestZone, @vWarehouse, @BusinessUnit;

          /* Increment the package seqno for each LPN created */
          select @vNextPackageSeqNo += 1;

          /* if the destinationzone is shipdock then need to generate uccbarcode here */
          if (@vUCC128Required = 'Y'/* Yes */)
            begin
              exec pr_ShipLabel_GetSSCCBarcode @UserId, @BusinessUnit, @vTempLPN,  @vBarcodeType,
                                               @vUCCBarcode output;

              /* get the max seq number generated for the Order  -- this works for orders, but for
                 batch labels we have to print sequence number for each task
              select @vNextPackageSeqNo = Max(coalesce(PackageSeqNo, 0)) + 1
              from LPNs
              where (OrderId = @vOrderId);
              */

              /* Update LPNs here */
              update LPNs
              set UCCBarcode   = @vUCCBarcode,
                  PackageSeqNo = @vNextPackageSeqNo
              where (LPNId = @vTempLPNId);
            end
          else
            begin
              /* Update LPNs here */
              update LPNs
              set PackageSeqNo = @vNextPackageSeqNo
              where (LPNId = @vTempLPNId);
            end

          /* unassign the variables */
          select @vTempLPNDetailId  = null, @vTempLPNId = null, @vTempLPN = null,
                 @vUCCBarcode = null, @vNumCases -= 1; /* Need to decrement by 1 each time */
        end

      /* unassign the variables */
      select @vPrevTaskId = @vTaskId, @vPrevTDGroupSet = @vTDGroupSet;
      select @vTaskId    = null, @vLPNId   = null, @vLPNDetailId   = null,
             @vWarehouse = null, @vOrderId = null, @vOrderDetailId = null,
             @vDestZone  = null, @vSKUId   = null, @vPrevbatchNo   = @vPickBatchNo;
    end

  /* All temp labels have been created for each TaskDetail, now insert the
      relation of LPN-Task in the table */
  insert into LPNTasks(PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId,
                       LPNDetailId, DestZone, Warehouse, BusinessUnit)
    select PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId,
           LPNDetailId, DestZone, Warehouse, BusinessUnit
    from @ttLPNTasks;

  /* Update Taskdetail here that temp label has been created for that task details case  */
  update TD
  set IsLabelGenerated = 'Y' /* yes */
  from TaskDetails TD
    join @ttLPNTasks TLT on (TLT.TaskDetailId = TD.TaskDetailId ) and
                            (TLT.BusinessUnit = TD.BusinessUnit )

  /* Update all Temp Labels generated with PickBatchInfo */
  update L
  set TaskId       = TLT.TaskId,
      PickBatchId  = TLT.PickBatchId,
      PickBatchNo  = TLT.PickBatchNo,
      Status       = 'F' /* Temp label */,
      OnhandStatus = 'U' /* Unavailable */,
      DestZone     = TLT.DestZone,
      CartonType   = 'STD_BOX' /* Temp fix: Label generation we need carton type, So we have updating with dummy carton type */
  from LPNs L
    join @ttLPNTasks TLT on (TLT.LPNId = L.LPNId);

  /* Update LPNDetails onhand status here */
  update LD
  set OnhandStatus = 'U' /* UnAvailable */
  from LPNDetails LD
  join @ttLPNTasks TLT on (TLT.LPNDetailId = LD.LPNDetailId)

  /* Delete from temp table @ttLPNTasks */
  delete from @ttLPNTasks;

  /* Get the orders to recount */
  insert into @ttOrdersToRecount(EntityId)
    select distinct OrderId from @ttTaskDetails;

  exec pr_OrderHeaders_Recalculate @ttOrdersToRecount, 'C'/* Recount - Order */, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Tasks_GenerateTempLabels */

Go
