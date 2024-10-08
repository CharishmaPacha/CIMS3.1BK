/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateTempLabels') is not null
  drop Procedure pr_LPNs_CreateTempLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateTempLabels: This procedure will create lpns as bulk based
        on the given input. We need to enhance it.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateTempLabels
  (@LabelsToGenerate TLPNsToGenerate readonly,
   @Operation        TDescription,
   @Warehouse        TWarehouse,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  /* Declare local variables */
  declare @vPallet            TPallet,
          @MessageName        TMessageName,
          @ReturnCode         TInteger,

          @vRecordId          TRecordId,
          @LPNId              TRecordId,
          @LPN                TLPN,
          @LPNDetailId        TRecordId,
          @vLPNType           TTypeCode,

          @vLPNSeqNum         TLPN,

          @vSKUId             TRecordId,
          @vOrderId           TRecordId,
          @vOrderDetailId     TRecordId,
          @vTaskId            TRecordId,
          @vTaskDetailId      TRecordId,

          @vCasesPerLabel     TInnerPacks,
          @vQtyPerLabel       TQuantity,
          @vPickBatchId       TRecordId,
          @vPickBatchNo       TPickBatchNo,
          @vOnHandStatus      TStatus,
          @vStatus            TStatus,
          @vDestZone          TZoneId,
          @vFromLPNId         TRecordId,

          @ttLabelsToGenerate TLPNsToGenerate,
          @ttLPNTasks         TLPNTasksTable,
          @ActivityType       TActivityType;
begin
  select @ReturnCode     = 0,
         @MessageName    = null,
         @LPNDetailId    = null,
         @LPNId          = null,
         @LPN            = null,
         @vLPNSeqNum     = '',
         @vRecordId      = 0;

  if (@MessageName is not null)
    goto ErrorHandler;

  /* insert all data into temp table */
  insert into @ttLabelsToGenerate(LPNSeqNo, LPNType, SKUId, OrderId, OrderDetailId, TaskId, TaskDetailId,
                                  OnHandStatus, Status, PickBatchId, PickBatchNo, InnerPacks, Quantity,
                                  FromLPNId, DestZone)
    select LPNSeqNo, LPNType, SKUId, OrderId, OrderDetailId, TaskId, TaskDetailId,
           OnHandStatus, Status, PickBatchId, PickBatchNo, InnerPacks, Quantity, FromLPNId, DestZone
    from @LabelsToGenerate;

  if (@@rowcount = 0)
    return;

  /* Loop thru all the record here and Create LPNs and LPNDetails */
  while (exists (select *
                 from @ttLabelsToGenerate
                 where (LPNSeqNo > @vLPNSeqNum)))
    begin
      select top 1
         @vRecordId      = RecordId,
         @vLPNSeqNum     = LPNSeqNo,
         @vLPNType       = LPNType,
         @vTaskId        = TaskId,
         @vTaskDetailId  = TaskDetailId,
         @vStatus        = Status,
         @vOnhandStatus  = OnhandStatus,
         @vPickBatchId   = PickBatchId,
         @vPickBatchNo   = PickBatchNo,
         @vFromLPNId     = FromLPNId,
         @vDestZone      = DestZone
      from @ttLabelsToGenerate
      where (LPNSeqNo > @vLPNSeqNum)
      order by LPNSeqNo;

      /* First, create an empty LPN ?? Or do we need to use create INV  */
      exec @ReturnCode = pr_LPNs_Generate @vLPNType      /* LPNType */,
                                          1              /* NumLPNsToCreate */,
                                          null           /* LPNFormat - Use default format based upon LPNType */,
                                          @Warehouse,
                                          @BusinessUnit,
                                          @UserId,
                                          @LPNId   output,
                                          @LPN     output;

      /* Insert all the details for the particular LPN */
      insert into LPNDetails(LPNId, LPNLine, OnhandStatus, CoO,
                             SKUId, InnerPacks, Quantity, UnitsPerPackage,
                             ReceivedUnits, ReceiptId, ReceiptDetailId,
                             OrderId, OrderDetailId,
                             Weight, Volume, Lot, ReferenceLocation,
                             BusinessUnit, CreatedBy)
        select @LPNId, RecordId, OnhandStatus, null /* Coo */,
               L.SKUId, L.InnerPacks, L.Quantity,
               Case /* Units Per Package */
                 when ((coalesce(InnerPacks, 0) > 0) and (Quantity > 0)) then
                   (Quantity/InnerPacks)
                 else
                   0
               end,
               0, null, null,  -- future use Receiver, ReceiptId, ReceiptDetailId
               L.OrderId, L.OrderDetailId,
               case  /* Weight */
                 when InnerPacks > 0 and S.InnerPackWeight > 0 then
                   S.InnerPackWeight * InnerPacks
                 else
                   S.UnitWeight * Quantity
               end,
               case /* Volume */
                 when InnerPacks > 0 and S.InnerPackVolume > 0 then
                   S.InnerPackVolume * InnerPacks
                 else
                   S.UnitVolume * Quantity
               end,
               null /* LotNo */, FromLPNId,
               @BusinessUnit, coalesce(@UserId, System_User)
        from @ttLabelsToGenerate L join SKUs S on L.SKUId = S.SKUId
        where (LPNSeqNo = @vLPNSeqNum);

      /* insert details into LPNTasks Table */
      if (@Operation = 'EcomLabelCreation')
        insert into @ttLPNTasks(PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId,
                                LPNDetailId, DestZone, FromLPNId,  Warehouse, BusinessUnit)
          select @vPickBatchId, @vPickBatchNo, @vTaskId, @vTaskDetailId, @LPNId,
                 LPNDetailId, @vDestZone, @vFromLPNId, @Warehouse, @BusinessUnit
          from LPNDetails
          where LPNId = @LPNId;

      /* recount the LPN */
      exec pr_LPNs_Recount @LPNId;

      /* reset the values here */
      select @LPNDetailId = null;
    end

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* After creating an empty LPN update that LPN with the values in i/p variables */
  update L
  set DestWarehouse = Warehouse,
      Status        = @vStatus,
      OnhandStatus  = @vOnhandStatus,
      L.DestZone    = TL.DestZone,
      PickBatchId   = L.PickBatchId,
      PickBatchNo   = L.PickBatchNo,
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  from LPNs L
  join @ttLPNTasks TL on TL.LPNId = L.LPNId;

  if (@Operation = 'EcomLabelCreation')
    begin
      /* Update Taskdetail here that temp label has been created for that task details case  */
      update TD
      set IsLabelGenerated = 'Y' /* yes */
      from TaskDetails TD
      join @ttLPNTasks TLT on (TLT.TaskDetailId = TD.TaskDetailId ) and
                              (TLT.BusinessUnit = TD.BusinessUnit )

      insert into LPNTasks(PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId,
                           LPNDetailId, DestZone, Warehouse, BusinessUnit)
        select PickBatchId, PickBatchNo, TaskId, TaskDetailId, LPNId,
               LPNDetailId, DestZone, Warehouse, BusinessUnit
        from @ttLPNTasks;
    end

  if (@ReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_CreateTempLabels */

Go
