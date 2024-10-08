/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/28  TK      pr_PickBatch_AddOrder, pr_PickBatch_CreateBatch & pr_PickBatch_UpdateCounts:
                        Fixed Wave generation issues (HA-86)
  2018/04/30  TK      pr_PickBatch_GenerateBatches & pr_PickBatch_AddOrders: Added transactions (S2G-730)
  2014/03/03  NY      pr_PickBatch_AddOrders: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  2013/09/17  TD      pr_PickBatch_AutoGenerateBatches, pr_PickBatch_GenerateBatches, pr_PickBatch_AddOrder,
                      pr_PickBatch_AddOrders : Batchgeneration changes.
  2012/11/23  PKS     pr_PickBatch_AddOrders: Return the result as a message
  2012/06/27  NY      pr_PickBatch_AddOrder: calling directly pr_PickBatch_UpdateCounts to update counts

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_AddOrder') is not null
  drop Procedure pr_PickBatch_AddOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_AddOrder: Adds the given Order to the PickBatch by updating
    the PickBatchNo on the Order and then recalcs the fields on the PickBatch
    and increments the counts with those of the newly added order.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_AddOrder
  (@PickBatchId      TRecordId,
   @PickBatchNo      TPickBatchNo,
   @OrderId          TRecordId,
   @OrderDetailId    TRecordId,
   @BatchingLevel    TDescription = 'OH',
   @UpdateCounts     TFlag = 'Y',
   @PickBatchGroup   TWaveGroup,
   @UserId           TUserId)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,
          @vSoldToCount     TCount,
          @vSoldToId        TCustomerId,
          @vShipToCount     TCount,
          @vShipToId        TShipToId,
          @vShipViaToCount  TCount,
          @vShipVia         TShipVia,
          @vPickZone        TLookUpCode,
          @vOrderPriority   TPriority,
          @NumLinesOnOrder  TCount,
          @NumSKUsOnOrder   TCount,
          @NumUnitsOnOrder  TCount,
          @vModifiedDate    TDateTime,
          @vAuditEntity     TDescription,
          @vBusinessUnit    TBusinessUnit;
begin
  /* If the batching level is OrderHeaders level then we need to update OrderHeaders here */
  if (@BatchingLevel = 'OH')
    begin
      /* Update OrderHeaders with BatchNo and Status To Batched */
      update OrderHeaders
      set PickBatchNo      = @PickBatchNo,
          PickBatchId      = @PickBatchId,
          Status           = 'W'  /* Waved */,
          @vModifiedDate   =
          ModifiedDate     = current_timestamp,
          ModifiedBy       = coalesce(@UserId, System_User),
          @NumLinesOnOrder = NumLines,
          @NumSKUsOnOrder  = NumSKUs,
          @NumUnitsOnOrder = NumUnits,
          @vAuditEntity    = 'PickBatchAddOrder'
      where (OrderId = @OrderId);

      /* Add all details of the Order to PickBatchDetails table */
      insert into PickBatchDetails(PickBatchId, PickBatchNo, WaveId, WaveNo, OrderId, OrderDetailId, BusinessUnit, CreatedBy)
        select @PickBatchId, @PickBatchNo, @PickBatchId, @PickBatchNo, @OrderId, OrderDetailId, BusinessUnit, coalesce(@UserId, System_user)
        from vwOrderDetails
        where (OrderId = @OrderId);
    end
  else
    begin
      /* Update OrderDetails here */
      update OrderDetails
      set ModifiedDate   = current_timestamp,
          ModifiedBy     = coalesce(@UserId, System_User),
          @vAuditEntity  = 'PickBatchAddOrderDetail',
          @vBusinessUnit = BusinessUnit
      where (OrderDetailId = @OrderDetailId);

      /* Add Order detail to PickBatchDetails table */
      insert into PickBatchDetails(PickBatchId, PickBatchNo, WaveId, WaveNo, OrderId, OrderDetailId, BusinessUnit, CreatedBy)
        select @PickBatchId, @PickBatchNo, @PickBatchId, @PickBatchNo, @OrderId, @OrderDetailId, @vBusinessUnit, coalesce(@UserId, System_user)

      /* Call set Status: Even though only one detail is added, it may change status of the Order */
      exec pr_OrderHeaders_SetStatus @OrderId, null /* Status */, @UserId;
    end

  if (@UpdateCounts <> 'N')
    exec pr_PickBatch_UpdateCounts @PickBatchNo, 'O' /* Options */, @PickBatchGroup;

  /* Auditing */
  exec pr_AuditTrail_Insert @vAuditEntity, @UserId, @vModifiedDate,
                            @OrderId = @OrderId, @OrderDetailId = @OrderDetailId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_AddOrder */

Go
