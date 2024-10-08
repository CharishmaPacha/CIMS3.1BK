/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/30  TK      pr_PickBatch_GenerateBatches & pr_PickBatch_AddOrders: Added transactions (S2G-730)
  2014/03/03  NY      pr_PickBatch_AddOrders: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  2013/09/17  TD      pr_PickBatch_AutoGenerateBatches, pr_PickBatch_GenerateBatches, pr_PickBatch_AddOrder,
                      pr_PickBatch_AddOrders : Batchgeneration changes.
  2012/11/23  PKS     pr_PickBatch_AddOrders: Return the result as a message
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_AddOrders') is not null
  drop Procedure pr_PickBatch_AddOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_AddOrders: Adds the given Orders or Order Details to the Pick
    Batch by calling pr_PickBatch_AddOrder proc for each order or order detail
    <Orders>
      <OrderHeader>
        <OrderId>22583</OrderId>
      </OrderHeader>
      <OrderHeader>
        <OrderId>22584</OrderId>
      </OrderHeader>
      <OrderHeader>
        <OrderId>22585</OrderId>
      </OrderHeader>
      <OrderDetails>
        <OrderDetailId>22585</OrderId>
      </OrderDetails>
    </Orders>
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_AddOrders
  (@PickBatchNo      TPickBatchNo,
   @Orders           TXML,
   @BatchingLevel    TDescription,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Message          TMessage output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vEntity             TEntity   = 'PickBatch',

          @vOrders             XML,
          @vOrderId            TRecordId,
          @vEntityId           TRecordId,
          @vPickBatchid        TRecordId,
          @vBatchStatus        TStatus,
          @vBatchWarehouse     TWarehouse,
          @vBatchOwner         TOwnership,
          @vPickBatchGroup     TWaveGroup,
          @vOrderGroup         TWaveGroup,
          @vNumOrders          TCount,
          @vRecordsAddedCount  TCount,
          @vTotalRecordCount   TCount,
          @vOrderDetailId      TRecordId,
          @vActivity           TActivityType,
          @vAuditActivity      TActivityType;

  declare @ttOrders table (OrderId        TRecordId,
                           OrderDetailId  TRecordId,
                           Warehouse      TWarehouse,
                           Ownership      TOwnership,
                           PickBatchGroup TWaveGroup);
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vTotalRecordCount    = 0,
         @vRecordsAddedCount   = 0;

  /* validations  validate pick batch,  Order */
  select @vPickBatchId    = RecordId,
         @vBatchStatus    = Status,
         @vBatchWarehouse = Warehouse,
         @vBatchOwner     = Ownership,
         @vPickBatchGroup = PickBatchGroup,
         @vNumOrders      = NumOrders
  from PickBatches
  where (BatchNo      = @PickBatchNo) and
        (BusinessUnit = @BusinessUnit);

  if (@vPickBatchId is null)
    set @MessageName = 'PickBatchIsInvalid';
  else
  if (@vBatchStatus <> 'N' /* New */ )
    set @MessageName = 'InvalidBatch';

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vOrders  = convert(xml, @Orders)

  if (@BatchingLevel = 'OD' /* OrderDetails */)
    begin
      select @vActivity      = 'AddOrderDetails',
             @vAuditActivity = 'PickBatchOrderDetailsAdded';

      insert into @ttOrders (OrderDetailId)
        select Record.Col.value('(OrderDetailId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderDetails') as Record(Col)

        /* Fetch the Warehouse, Ownership for the orders. This information could be
           passed from UI also, but it is not desirable because the customizations
           for clients would mean that we keep changing the XSD all the time. So,
           instead, it would be best to pass only OrderIds from UI and then figure
           out the rest from here */
        update @ttOrders
        set OrderId        = OB.OrderId,
            Warehouse      = OB.Warehouse,
            Ownership      = OB.Ownership,
            PickBatchGroup = OB.PickBatchGroup
        from @ttOrders TT
        join vwOrderDetails OB on TT.OrderDetailId = OB.OrderDetailId;
      end
    else
    begin
      select @vActivity      = 'AddOrders',
             @vAuditActivity = 'PickBatchOrdersAdded';

      insert into @ttOrders (OrderId)
        select Record.Col.value('(OrderId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderHeader') as Record(Col);

         /* Fetch the Warehouse, Ownership for the orders. This information could be
           passed from UI also, but it is not desirable because the customizations
           for clients would mean that we keep changing the XSD all the time. So,
           instead, it would be best to pass only OrderIds from UI and then figure
           out the rest from here */
        update @ttOrders
        set Warehouse      = OB.Warehouse,
            Ownership      = OB.Ownership,
            PickBatchGroup = OB.PickBatchGroup
        from @ttOrders TT
        join vwOrdersToBatch OB on TT.OrderId = OB.OrderId;
    end

  select @vTotalRecordCount = @@rowcount;

  /* If new batch, then ensure all orders are from same Warehouse. If it is
     a batch that already has existing orders, then we can add whatever orders
     that match the batch and leave others alone */
  if (@vBatchWarehouse is null) and
     ((select count(distinct Warehouse) from @ttOrders) > 1)
    set @MessageName = 'PickBatch_AddOrders_MultipleWarehouses';
  else
  if (@vPickBatchGroup is null) and
     ((select count(distinct PickBatchGroup) from @ttOrders) > 1)
    set @MessageName = 'PickBatch_AddOrders_MultipleGroups';

  /* for TD, this may not be required as CustPO itself is never across multiple owners */
--  if (@vBatchOwner is null) and
--     ((select distinct count(Ownership) from @ttOrders) > 1)
--    set @MessageName = 'PickBatch_AddOrders_MultipleOwners';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Unless it is a new batch, select orders that match the Warehouse of the batch */
  declare curOrders Cursor Local Forward_Only Static Read_Only
    For select TT.OrderId, TT.OrderDetailId, TT.PickBatchGroup
        from @ttOrders TT
        where (@vBatchWarehouse is null or TT.Warehouse = @vBatchWarehouse) and
              (@vPickBatchGroup is null or TT.PickBatchGroup = @vPickBatchGroup);

  Open curOrders;
  Fetch next from curOrders into @vOrderId, @vOrderDetailId, @vOrderGroup;

  /* Iterate thru the Orders and add each one to the Pick Batch */
  while (@@fetch_status = 0)
    begin
      /* Do not update the counts, it will all be done at once after all orders
         are added to the batch */
      exec pr_PickBatch_AddOrder @vPickBatchId, @PickBatchNo, @vOrderId, @vOrderDetailId, @BatchingLevel, 'N' /* Update Counts */,
                                 @vOrderGroup, @UserId;

      select @vRecordsAddedCount = @vRecordsAddedCount + 1;

      Fetch next from curOrders into @vOrderId, @vOrderDetailId, @vOrderGroup;
    end

  Close curOrders;
  Deallocate curOrders;

  /* If this is the first time orders are being added to batch, then
     set the Group on the batch, so that in future, only orders of that
     group are added */
  if (@vPickBatchGroup is null)
    select top 1 @vPickBatchGroup = PickBatchGroup
    from @ttOrders;

  /* Update the summary fields and counts on the batch */
  exec pr_PickBatch_UpdateCounts @PickBatchNo, 'O' /* Options */, @vPickBatchGroup;

  /* Auditing */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null,
                            @PickBatchId = @vPickBatchId,
                            @NumOrders   = @vRecordsAddedCount;

  /* Based upon the number of Orders that have been added to PickBatch, giving an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vActivity, @vRecordsAddedCount, @vRecordsAddedCount;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;

end catch;
end /* pr_PickBatch_AddOrders */

Go
