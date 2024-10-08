/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/03/02  VM      pr_TaskDetails_MergeDuplicates: Bugfix - Update/delete exact lines on temp label details while merging (HPI-1415)
  2016/08/05  PK      Added new procedure pr_TaskDetails_MergeDuplicates.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_MergeDuplicates') is not null
  drop Procedure pr_TaskDetails_MergeDuplicates;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_MergeDuplicates: This procedure will merge the duplicate
    TaskDetails and also the duplicate lines on the temp label if the temp label
    is generated for the task.

  Generally, when replenish LPNs are putaway into picklanes, the following happens
  - Merging of Picklane lines (DR lines merging to R line)
  - Merging of Task details respective to picklane lines merging.
  - Merging of ToLPN (templabel) lines respective to Picklane & Task detail lines.

  Merging of Picklane lines:
  - Caller (pr_Locations_SplitReplenishQuantity) takes care of updating the picklane lines

  Merging of Task details respective to picklane lines merging:
  - When replenish Putaway is happening, we need to merge the EXACT DR line with R line and not the all DR lines.
  - Remember, Location may have multiple DR lines on the following situaion
    (say SKU ABC of order requires 10 units and location (picklane) has
      A (Available) line with 2 units,
      D (Directed) line with 5 units of Replenish order R1
     then order is tried to allocate location line ends up like below

     OHStatus   Qty   Replenish order    |  TaskDetailId
     R           2                       |  105
     DR          5    R1                 |  106
     DR          3    R2                 |  107

  Merging of ToLPN (templabel) lines respective to Picklane & Task detail lines:
  - When replenish Putaway is happening, we need to merge the EXACT ToLPN line relative to Task lines

     OHStatus   Qty |  TaskDetailId
     U          2   |  105
     U          5   |  106
     U          3   |  107

  ---------------------------------------
  On R1 LPN PA, it should merge as below
        Location LPN Detail            | Temp Label Detail  |
     OHStatus   Qty   Replenish order  |  OHStatus   Qty    |  TaskDetailId
     R           7                     |  U          7      |  106
     DR          3    R2               |  U          3      |  107

  On R1 LPN PA, it should merge as below
     OHStatus   Qty   Replenish order  |  OHStatus   Qty    |  TaskDetailId
     R           10                    |  U          10     |  106

** Smaller quantity lines quantities will be merged to high value quantities and smaller quantity lines are deleted.
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_MergeDuplicates
  (@TaskDetailId  TRecordId,
   @LPNDetailId   TRecordId, /* Reserved Picklane LPN Detail Id */
   @UserId        TUserId,
   @Operation     TOperation = null)
As
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vTaskId                TRecordId,
          @vTaskDetailId          TRecordId,
          @vSKUId                 TRecordId,
          @vLPNId                 TRecordId,
          @vQuantity              TQuantity,
          @vWeight                TWeight,
          @vVolume                TVolume,
          @vOrderDetailid         TRecordId,
          @vOrderId               TRecordId,
          @vTempLPNDetailId       TRecordId,
          @vTempLPNId             TRecordId,
          @vToLPNDetailIdToRetain TRecordId, /* Temp label detail id to retain */
          @vPickBatchNo           TPickBatchNo,
          @vIsLabelGenerated      TFlag;

  declare @ttDupTaskDetails table (RecordId          TRecordId identity(1,1),
                                   TaskId            TRecordId,
                                   TaskDetailId      TRecordId,
                                   SKUId             TRecordId,
                                   Quantity          TQuantity,
                                   LPNId             TRecordId,
                                   LPNDetailId       TRecordId,
                                   OrderId           TRecordId,
                                   OrderDetailId     TRecordId,
                                   TempLabelId       TRecordId,
                                   TempLabel         TLPN,
                                   TempLabelDetailId TRecordId);

  declare  @ttDupTempDetails table (RecordId      TRecordId identity(1,1),
                                    LPNId         TRecordId,
                                    LPNDetailId   TRecordId,
                                    SKUId         TRecordId,
                                    Quantity      TQuantity,
                                    OrderId       TRecordId,
                                    OrderDetailId TRecordId,
                                    Weight        TWeight,
                                    Volume        TVolume);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the Task detail information */
  select @vOrderDetailid    = OrderDetailId,
         @vOrderId          = OrderId,
         @vSKUId            = SKUId,
         @vLPNId            = LPNId,
         @vTaskId           = TaskId,
         @vIsLabelGenerated = IsLabelGenerated
  from TaskDetails
  where (TaskDetailId = @TaskDetailId) and -- ToMerge TaskDetailId
        (LPNDetailId  = @LPNDetailId);

  /* Get the BatchNo from the task to update NumPicks on the pickbatch/wave */
  select @vPickBatchNo = BatchNo
  from Tasks
  where TaskId = @vTaskId

  /* Insert the duplicate task details into the temp table */
  insert into @ttDupTaskDetails (TaskId, TaskDetailId, SKUId, Quantity, LPNId,
                                 LPNDetailId, OrderId, OrderDetailId, TempLabelId, TempLabel, TempLabelDetailId)
    select TaskId, TaskDetailId, SKUId, Quantity, LPNId, LPNDetailId, OrderId,
           OrderDetailId, TempLabelId, TempLabel, TempLabelDetailId
    from TaskDetails
    where (LPNDetailId   = @LPNDetailId) and
          (OrderId       = @vOrderId) and
          (OrderDetailId = @vOrderDetailId) and
          (SKUId         = @vSKUId) and
          (LPNId         = @vLPNId);

  /* If there are more than 1 record then merge the details lines into one line.
     Assuming that there will only be 2 duplicate lines per item */
  if (@@rowcount > 1)
    begin
      /* Get the top 1 record from the temp table, get a line which has less quantity to merge
         Also, get Templabel details to process (merge and delete) on the exact temp label details later in this procedure */
      select @vTaskDetailId     = TaskDetailId, -- Task Detail to delete
             @vTaskId           = TaskId,
             @vSKUId            = SKUId,
             @vQuantity         = Quantity,
             @vTempLPNId        = TempLabelId,
             @vTempLPNDetailId  = TempLabelDetailId
      from @ttDupTaskDetails
      where (TaskDetailId  = @TaskDetailId);

      /* Update the other taskdetail line to update the quantity - the caller update LPNDetailId on both the lines in Task details */
      update TaskDetails
      set Quantity                += @vQuantity,
          @vToLPNDetailIdToRetain  = TempLabelDetailId   /* Get the TempLabelDetailId which is on the retained task detail */
      where (LPNDetailId   = @LPNDetailId) and
            (TaskDetailId  <> @vTaskDetailId) and
            (TaskId        = @vTaskId) and
            (SKUId         = @vSKUId) and
            (OrderId       = @vOrderId) and
            (OrderDetailId = @vOrderDetailId);

      /* After updating the task details, delete the task detail since we have
         already updated other taskdetail */
      delete from TaskDetails where TaskDetailId = @vTaskDetailId;

      /* Recount the task to update the counts on task after merging the
         duplicate lines */
      exec pr_Tasks_ReCount @vTaskId;

      /* Recount the batch to update the correct counts(NumPicks) on the Pickbatch/Wave */
      exec pr_PickBatch_UpdateCounts @vPickBatchNo, 'T' /* T - Tasks (Options) */;
    end

  /* If there are temp labels generated for the task, then verify whether there
     are any duplicate LPN detail lines or not */
  if (@vIsLabelGenerated = 'Y')
    begin
      /* Insert all TempLPN details into a temp table to merge duplicate lines */
      insert into @ttDupTempDetails (LPNId, LPNDetailId, SKUId, Quantity,
                                     OrderId, OrderDetailId, Weight, Volume)
        select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.Quantity, LD.OrderId, LD.OrderDetailId, LD.Weight, LD.Volume
        from LPNDetails LD
          join @ttDupTaskDetails TTD on (LD.LPNId = TTD.TempLabelId)
        where (LD.OrderId       = @vOrderId) and
              (LD.OrderDetailId = @vOrderDetailId) and
              (LD.SKUId         = @vSKUId);

      /* If there are more than 1 record then merge the details lines into one line.
         Assuming that there will only be 2 duplicate lines per item

         VM_20170221: THE ABOVE STATEMENT IS NOT TRUE. THERE COULD BE MORE THAN 2 LINES: R Line, DR Lines FROM TWO DIFFERENT REPLENISH ORDERS
         So, we cannot update all other LPNDetails and it needs to be merged to the exact line where task detail is merged. */
      if (@@rowcount > 1)
        begin
          /* Get the details of of temp label detail, which is going to be merged with reserved line and then deleted later */
          select @vSKUId     = SKUId,
                 @vQuantity  = Quantity,
                 @vWeight    = Weight,
                 @vVolume    = Volume
          from @ttDupTempDetails
          where (LPNDetailId = @vTempLPNDetailId);

          /* Update the relative Temp label LPNDetail line to update the quantity, weight and volume */
          update LPNDetails
          set Quantity += @vQuantity,
              Weight   += @vWeight,
              Volume   += @vVolume
          where (LPNDetailId = @vToLPNDetailIdToRetain /* Reserved on picklane detail line (other than DR line) on Temp LPN */)

          /* Following is the just to reduce the risk of chance when @vToLPNDetailIdToRetain not found
             and hence still execute the old code */
          if (@@rowcount = 0)
            /* Update the other LPNDetail line to update the quantity, weight and volume */
            update LPNDetails
            set Quantity += @vQuantity,
                Weight   += @vWeight,
                Volume   += @vVolume
            where (LPNId         = @vTempLPNId) and
                  (LPNDetailId   <> @vTempLPNDetailId) and
                  (SKUId         = SKUId) and
                  (OrderId       = @vOrderId) and
                  (OrderDetailId = @vOrderDetailId);

          /* After updating the LPN details, delete the LPNDetail line since
             we have already updated other taskdetail */
          delete from LPNDetails where LPNDetailId = @vTempLPNDetailId;

          /* Recount the TempLPN to update the counts on LPN after merging the duplicate lines */
          exec pr_LPNs_Recount @vTempLPNId;
        end
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_TaskDetails_MergeDuplicates */

Go
