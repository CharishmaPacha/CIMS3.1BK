/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/14  AJM     pr_OrderDetails_Modify : Made changes to log messages appropriately (HA-612)
  pr_OrderDetails_Modify: Removed updating Modify Pack Combination changes (HA-775)
  2020/07/07  SAK     pr_OrderDetails_Modify Commented validation for Modify Ship Details action (HA-1108)
  2020/07/06  MS      pr_OrderDetails_Modify: Added validation for CancelPTLine (HA-958)
  2020/05/27  RV      pr_OrderDetails_Modify: Made changes to get selected entities from temp table instead of input xml (HA-581)
  2020/05/15  RT      pr_OrderDetails_Modify: Included PackingGroup (HA-382)
  2020/04/23  RT      pr_OrderDetails_Modify: Included UnitsPerCarton to update in the OrderDetails (HA-287)
  2019/12/08  RKC     pr_OrderDetails_Modify:Added SoldToId ,ShipToId params (CID-1175)
  2018/04/08  SV      pr_OrderDetails_Modify, pr_OrderHeaders_AfterClose, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close, pr_OrderHeaders_Modify (HPI-1842)
  2016/04/14  TK      pr_OrderDetails_Modify: User should be able to modify even if there are multiple order details of same SKU (NBD-360)
  2015/08/08  YJ      pr_OrderDetails_Modify: Allow partial line cancel based on control var
  pr_OrderDetails_Modify:  Entity and Action was provided separately to fn_Messages_BuildActionResponse.
  2014/04/03  NY      pr_OrderDetails_Modify : Added condition to not to cancel partial quantity.
  2014/03/18  NY      pr_OrderDetails_Modify : Adding Warehouse to export when we cancel PT Line.
  2014/01/28  TD      pr_OrderDetails_Modify: Bug Fix: Recalculate Orders and Batches counts once Orderdetails are modified.
  2014/01/07  TD      pr_OrderDetails_Modify: bug fix- Looping thru all the given details.
  2013/12/16  TD      pr_OrderDetails_Modify: Changes to cancel all the lines at once.
  2013/12/12  TD      pr_OrderDetails_Modify: Changes to generate valid exports if we cancel order line..
  2013/11/25  NY      pr_OrderDetails_Modify: Changed to Read null value from xml string.
  2013/11/08  TD      pr_OrderDetails_Modify:Validating Order Status.
  2103/10/23  TD      pr_OrderDetails_Modify:Small fix process order details which have not on PickBatches.
  2013/10/07  TD      pr_OrderDetails_Modify: Changes to PTcancel.
  2012/12/14  PKS     pr_OrderDetails_Modify: Modified Procedure such that it to update UnitsOrdered as well
  2012/11/28  PKS     pr_OrderDetails_Modify: Changes are reverted from SVN Version No 5645
  2012/11/24  PKS     Added AT functionality to pr_OrderDetails_Modify, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close
  2012/11/21  PKS     pr_OrderDetails_Modify: Filtered ODs which are having UnitsOrdered less than UnitsAuthorizedToShip.
  2012/11/07  PKS     pr_OrderDetails_Modify: signature changed.
  2012/11/01  PKS     Added pr_OrderDetails_Modify.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_Modify') is not null
  drop Procedure pr_OrderDetails_Modify;
Go
/*------------------------------------------------------------------------------
Proc pr_OrderDetails_Modify: This procedure will update the Order lines with given
                             data after validating it.
  This Procedure is designed such that it will note which are processed and which are not
  with reason. This will be helpful when UI was designed to show result in Tree view with
  success and failed items.
  <Root>
    <Entity>OrderDetails</Entity>
    <Action></Action>
    <data>
      <ToShip></ToShip>
    </data>
    <OrderDetails>
      <OrderDetail>
        <OrderDetailId></OrderDetailId>
      </OrderDetail>
    </OrderDetails>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_Modify
  (@OrderDetailContent  XML,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   @xmlResult           TXML           output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,

          @xmlData               xml,
          @vAction               TAction,
          @vOrderId              TRecordId,
          @vSKUId                TRecordId,
          @vOrderDetailId        TRecordId,
          @vOrderLines           TCount,
          @vUnitsAssigned        TQuantity,
          @vPrevUnitsToShip      TQuantity,
          @vPrevUnitsOrdered     TQuantity,
          @vUnitsToShip          TQuantity,
          @vPrevOrderStatus      TStatus,
          @vNewUnitsToShip       TQuantity,
          @vNewUnitsOrdered      TQuantity,
          @vNewOrderStatus       TStatus,
          @vTotalOrderDetails    TQuantity,
          @vUnitsToCancel        TQuantity,
          @vUnitsCanceled        TQuantity,
          @vOrderDetailsCount    TCount,
          @vOrderDetailsUpdated  TCount,
          @Count                 TCount,
          @vSameLinesCount       TCount,
          @vBatchNo              TPickBatchNo,
          @vActivityType         TActivityType,
          @vActivityDateTime     TDateTime,
          @Message               TDescription,
          @vWarehouse            TWarehouse,
          @vValidStatusesToCancelPTLine
                                 TDescription,
          @vPartialLineCancel    TFlags,
          @vSoldToId             TCustomerId,
          @vShipToId             TShipToId;

  declare @ttOrderDetails table
          (OrderDetailId             TRecordId,
           OrderId                   TRecordId,
           PickTicket                TPickTicket,
           SKUId                     TRecordId,
           OrderLine                 TDetailLine,
           PrevUnitsToShip           TQuantity,
           PrevUnitsOrdered          TQuantity,
           PrevOrderStatus           TStatus,
           UnitsToCancel             TQuantity,
           ProcessFlag               TFlag,
           Status                    TStatus,
           ReasonCode                TMessageName,
           Reason                    TMessage);
begin
begin try
  begin transaction;

  select @Count       = 1,
         @ReturnCode  = 0,
         @MessageName = null;

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @OrderDetailContent.nodes('/Root') as Record(Col);

  /* insert all the OrderDetails into the temp table which are to be updated in Order Details */
  insert into @ttOrderDetails (OrderDetailId, OrderId, PickTicket, SKUId, PrevUnitsToShip, PrevUnitsOrdered, PrevOrderStatus,
                               ProcessFlag)
    select OD.OrderDetailId,
           OD.OrderId,
           OD.PickTicket,
           OD.SKUId,
           OD.UnitsAuthorizedToShip,
           OD.UnitsOrdered,
           OD.Status,
           'N'/* Process Flag - Not Processed */
    from  #ttSelectedEntities ttSE
      join vwOrderDetails OD on (OD.OrderDetailId = ttSE.EntityId );

  /* Get the row count into a variable */
  select @vOrderDetailsCount = @@rowcount,
         @vTotalOrderDetails = @@rowcount;

  /* Modifying OrderDetails according to the action. */
  if (@vAction in ('ModifyOrderDetails', 'OrderDetails_Modify'))
    begin
      /* Get the User input value of UnitsToShip */
      select @vNewUnitsToShip    = cast(nullif(Record.Col.value('ToShip[1]',    'varchar(10)'),'') As integer),
             @vNewUnitsOrdered   = nullif(Record.Col.value('ToOrdered[1]',      'TQuantity'), 0)
      from @OrderDetailContent.nodes('/Root/Data') as Record(Col);

      if (@vNewUnitsToShip is not null) and
         (@vNewUnitsOrdered is not null) and
         (@vNewUnitsToShip > @vNewUnitsOrdered)
        set @MessageName = 'ToShipQtyIsGreaterThanOrderedQty';

      if (@MessageName is not null)
        goto ErrorHandler;

      /* Marking items as failed which are not authorized to modify */
      update TOD
      set OrderLine   = OD.OrderLine,
          ProcessFlag = 'D',
          Status      = 'FAILED',
          ReasonCode  = 'UnitsAuthorizedToShipIsInvalid'
      from @ttOrderDetails TOD
        join OrderDetails OD on (OD.OrderDetailId = TOD.OrderDetailId)
      where ((OD.UnitsAssigned > coalesce(@vNewUnitsToShip, OD.UnitsAuthorizedToShip)) or
             (coalesce(@vNewUnitsToShip, OD.UnitsAuthorizedToShip) > coalesce(@vNewUnitsOrdered, OD.UnitsOrdered))) and
            (TOD.ProcessFlag = 'N'/* No */);

      /* Update the variable by removing the count of failed orders count */
      set @vOrderDetailsCount = @vOrderDetailsCount - @@rowcount;

      /* Get the order and SKU from the temp table */
      select @vOrderId = OrderId,
             @vSKUId   = SKUId
      from (select row_number() over (order by OrderDetailId ASC) as rownumber, OrderId , SKUId, ProcessFlag
            from @ttOrderDetails) as OD
      where (Rownumber   = @Count) and
            (ProcessFlag = 'N' /* No */);

      /* Loop - each individual items to verify whether the PickTicket is valid or not */
      while (@vOrderDetailsCount >= @Count)
        begin
          select @vOrderLines    = count(*),
                 @vUnitsAssigned = UnitsAssigned
          from OrderDetails
          where (OrderId = @vOrderId) and
                (SKUId   = @vSKUId)
          group by UnitsAssigned;

          /* Marking items as failed whose PT are not in Valid Status to change SHIPTO value.*/
          update TOD
          set TOD.ProcessFlag = 'D',
              TOD.Status      = 'FAILED',
              TOD.ReasonCode  = 'PickTicketIsInvalid'
          from @ttOrderDetails TOD
            join OrderHeaders OH on (TOD.OrderId = OH.OrderId)
          where --(OH.OrderId      = @vOrderId) and
                (OH.BusinessUnit = @BusinessUnit) and
                (OH.Status in ('S' /* Shipped */,
                               'X' /* Cancelled */,
                               'D' /* Completed */)) and
                (TOD.ProcessFlag = 'N');

          /* Updating OrderDetail count with respect to Invalid PT Count */
          set @vOrderDetailsCount = @vOrderDetailsCount - @@rowcount;

          --/* Finding for Same Lines (Same SKU) in Order Details */
          --select @vSameLinesCount = count(*)
          --from OrderDetails
          --where (OrderId = @vOrderId) and
          --      (SKUId   = @vSKUId);

          --if (@vSameLinesCount > 1)
          --  begin
          --    /* Marking Items as failed which are having same SKU more than once. */
          --    update TOD
          --    set TOD.ProcessFlag = 'D',
          --        TOD.Status      = 'FAILED',
          --        TOD.ReasonCode  = 'OrderContainsSameLines'
          --    from @ttOrderDetails TOD
          --    where (TOD.ProcessFlag = 'N');

          --    /* Updating OrderDetail count with respect to count of Same Line (Same SKU) */
          --    select @vOrderDetailsCount = @vOrderDetailsCount - @@rowcount;
          --  end

          /* Update the Count */
          select @Count = @Count + 1;

          /* Get the next Order from the temp table */
          select @vOrderId = OrderId,
                 @vSKUId   = SKUId
          from (select row_number() over (order by OrderDetailId ASC) as rownumber, OrderId , SKUId, ProcessFlag
                from @ttOrderDetails ) as OD
          where (Rownumber   = @Count) and
                (ProcessFlag = 'N'   );
        end

      /* Updating OrderDetails with given values. */
      /* Need to enhance the output xml such that it has to show success items and failed items with reason. */
      update OD
      set OD.UnitsAuthorizedToShip =  coalesce(@vNewUnitsToShip,    OD.UnitsAuthorizedToShip),
          OD.UnitsOrdered          =  coalesce(@vNewUnitsOrdered,   OD.UnitsOrdered),
          OD.ModifiedBy            =  @UserId,
          OD.ModifiedDate          =  current_timestamp
      --output deleted.OrderDetailId,Deleted.OrderLine, 'Y', 'SUCCESS' into @ttOrderDetails(OrderDetailId,OrderLine,  ProcessFlag, Status)
      from  OrderDetails OD
        join @ttOrderDetails TOD on (TOD.OrderDetailId = OD.OrderDetailId)
      where (TOD.ProcessFlag = 'N');

      /* Update the records as processed in the temp table which are not yet processed */
      update @ttOrderDetails
      set ProcessFlag = 'Y'
      where ProcessFlag = 'N';

      /* Get the updated row count */
      set @vOrderDetailsUpdated = @@rowcount;

      /* Get the top 1 Order DetailId to log the audit trail */
      select Top 1 @vOrderDetailId    = OD.OrderDetailId,
                   @vOrderId          = OD.OrderId,
                   @vPrevUnitsToShip  = OD.PrevUnitsToShip,
                   @vPrevUnitsOrdered = OD.PrevUnitsOrdered,
                   @vPrevOrderStatus  = OD.PrevOrderStatus,
                   @vBatchNo          = PBD.PickBatchNo
      from @ttOrderDetails OD
      left outer join PickBatchDetails PBD on (OD.OrderDetailId = PBD.OrderDetailId)
      where (ProcessFlag = 'Y' /* Yes */)
      order by OD.OrderDetailId;

      /* Loop through and insert the audit trail for each order */
      while(@@rowcount > 0)
        begin
          /* Update Order Headers numunits here */
          exec pr_OrderHeaders_Recount @vOrderId, default /* PickTicket */, @vNewOrderStatus output;

          /* If the order is now shipped, then do the afterclose */
          if (charindex(@vNewOrderStatus, 'SDX' /* Shipped, Completed or Canceled */) <> 0) and
             (charindex(@vPrevOrderStatus, 'SDX' /* Shipped, Completed or Canceled */) = 0)
            exec pr_OrderHeaders_AfterClose @vOrderId, default /* Order Type */, default /* Status */, default /* LoadId */,
                                            @BusinessUnit, @UserId, 'Y'/* GenerateExports */, 'ModifyOrderDetails'/* Operation */;

          /* Update Batch counts here if the order detail is already on batch. */
          if (coalesce(@vBatchNo, '') <> '')
            begin
              exec pr_PickBatch_UpdateCounts @vBatchNo;
              exec pr_PickBatch_SetStatus @vBatchNo;
            end

          /* Framing AT ActivityType */
          if ((@vNewUnitsToShip <> 0) and (@vNewUnitsOrdered <>0) and
              (@vNewUnitsToShip <> @vPrevUnitsToShip) and (@vNewUnitsOrdered <> @vPrevUnitsOrdered))
            set @vActivityType = 'ODModified_UnitsOrderedAndToShip';
          else
          if ((@vNewUnitsToShip <> 0) and (@vNewUnitsToShip <> @vPrevUnitsToShip))
            set @vActivityType = 'ODModified_UnitsToShip';
          else
          if ((@vNewUnitsOrdered <> 0) and (@vNewUnitsOrdered <> @vPrevUnitsOrdered))
            set @vActivityType = 'ODModified_UnitsOrdered';

          /* Log the Audit Trail */
          set @vActivityDateTime = current_timestamp;
          exec pr_AuditTrail_Insert @ActivityType     = @vActivityType,
                                    @UserId           = @UserId,
                                    @Note1            = @vPrevUnitsToShip, /* Note1 is used to set Previous Units To Ship value in AT message */
                                    @Note2            = @vPrevUnitsOrdered,
                                    @ActivityDateTime = @vActivityDateTime,
                                    @OrderDetailId    = @vOrderDetailId;

          /* Retreving the top 1 OrderDetailId from the temp table to log the
             audit trail */
          select top 1 @vOrderDetailId    = OD.OrderDetailId,
                       @vOrderId          = OD.OrderId,
                       @vPrevUnitsToShip  = OD.PrevUnitsToShip,
                       @vPrevUnitsOrdered = OD.PrevUnitsOrdered,
                       @vBatchNo          = PBD.PickBatchNo
          from @ttOrderDetails  OD
          left outer join PickBatchDetails PBD on (OD.OrderDetailId = PBD.OrderDetailId)
          where ((ProcessFlag   = 'Y' /* Yes */) and
                 (OD.OrderDetailId > @vOrderDetailId))
          order by OD.OrderDetailId;
        end;
    end
  else
  if (@vAction = 'CancelPTLine')
    begin
      /* Get the User input value of Units To Cancel */
      select @vUnitsToCancel = nullif(Record.Col.value('ToCancel[1]',  'TQuantity'), 0),
--             @vUnitsToShip   = nullif(Record.Col.value('ToShip[1]',  'TQuantity'), 0),
             @vUnitsAssigned = nullif(Record.Col.value('UnitsAssigned[1]',  'TQuantity'), 0)
      from @OrderDetailContent.nodes('/Root/Data') as Record(Col);

      /* Get the Units To Ship for the detail */
      select @vUnitsToShip = PrevUnitsToShip
      from @ttOrderDetails;

      select @vPartialLineCancel = dbo.fn_Controls_GetAsString('CancelPTLine', 'AllowPartialLineCancel',  'Y' /* Yes */, @BusinessUnit, @UserId);

      if ((@vUnitsToShip - @vUnitsAssigned) = 0)
        set @MessageName = 'CancelPTLine_CompletelyAllocated'
      else
      /* Cancel qty should not be zero */
      if (coalesce(@vUnitsToCancel, 0) = 0)
        set @MessageName = 'CancelPTLine_CancelQtyIsRequired'
      else
      /* Do not allow to cancel partial line Quantity */
      if (@vUnitsToCancel <> -1) and
         (@vPartialLineCancel = 'N') and
         (coalesce(@vUnitsToShip, 0) <> @vUnitsToCancel)
        set @MessageName = 'CancelPTLine_CannotCancelPartialQty';
      else
      /* Do not allow to cancel the PTLine, if Cancelled Qty is Greaterthan ToAllocate */
      if (coalesce(@vUnitsToCancel, 0) > (@vUnitsToShip - @vUnitsAssigned))
        set @MessageName = 'CancelPTLine_CannotCancelAllocatedQty'

      if (@MessageName is not null)
        goto ErrorHandler;

      /* if the vUnitsToCancel is -1 then it means user trying to cancel all the lines. so we need to
        set it to max value, so that below logic will take the min (UnitsToAllocate) to cancel the line. */
      if (@vUnitsToCancel = -1)
        select @vUnitsToCancel  = 9999;

        /* Log the Audit Trail */
      select @vActivityType                = 'ODModified_PTcancel',
             @vOrderDetailsUpdated         = 0,
             @vValidStatusesToCancelPTLine = dbo.fn_Controls_GetAsString('CancelPTLine', 'ValidStatuses', 'IWACN'/* InProgress,batched,Allocated,picking, New */, @BusinessUnit, null/* UserId */);

      /* Get the top 1 Order DetailId to log the audit trail and generate export */
      select Top 1 @vOrderDetailId = OD.OrderDetailId,
                   @vOrderId       = OD.OrderId,
                   @vSKUId         = OD.SKUId,
                   @vBatchNo       = PBD.PickBatchNo,
                   @vWarehouse     = OH.Warehouse,
                   @vSoldToId      = OH.SoldToId,
                   @vShipToId      = OH.ShipToId
      from @ttOrderDetails  OD
      left outer join PickBatchDetails PBD on (OD.OrderDetailId = PBD.OrderDetailId)
      left outer join OrderHeaders     OH  on (OD.OrderId       = OH.OrderId)
      where (ProcessFlag = 'N' /* No */) and
            (charindex(OH.Status, @vValidStatusesToCancelPTLine) <> 0)
      order by OD.OrderDetailId;

       while (@@rowcount > 0)
         begin
           /* Reduce the UnitsToShip by the cancel amount, however, we cannot reduce
              below already allocated level */
           update OrderDetails
           set @vUnitsCanceled       = dbo.fn_MinInt(coalesce(UnitsToAllocate, 0), @vUnitsToCancel),
               UnitsAuthorizedToShip = case when @vUnitsToCancel > UnitsToAllocate then
                                         UnitsAuthorizedToShip - UnitsToAllocate
                                       else
                                         UnitsAuthorizedToShip - @vUnitsToCancel
                                       end
           where (OrderDetailId  = @vOrderDetailId);

           /* We need to go below, if really we cancel any units. Assumption, caller will take care of these
              validations. I.E. if all the units are allocated then we are not cancel. we will cancel only the
              unallocated units. */
           if (@vUnitsCanceled > 0)
             begin
               /* Loop here to get updated lines count */
               select @vOrderDetailsUpdated = @vOrderDetailsUpdated  + 1;

               /* Update Order Headers numunits here */
               exec pr_OrderHeaders_Recount @vOrderId;

               /* If the Detail is on Batch, then we need to calculate the Batch */
               if (coalesce(@vBatchNo, '') <> '')
                 exec pr_PickBatch_UpdateCounts @vBatchNo;

               /* call procedure here to insert audit enity */
               exec pr_AuditTrail_Insert @ActivityType     = @vActivityType,
                                         @ActivityDateTime = @vActivityDateTime,
                                         @UserId           = @UserId,
                                         @Quantity         = @vUnitsCanceled,
                                         @OrderDetailId    = @vOrderDetailId;

               /* Generate Exports here */
               exec pr_Exports_AddOrUpdate @TransType = 'PTCancel', @TransEntity = 'OD' /* Order Detail */,
                                           @TransQty = @vUnitsCanceled, @BusinessUnit = @BusinessUnit, @SKUId = @vSKUId,
                                           @Warehouse = @vWarehouse, @OrderId = @vOrderId, @OrderDetailId = @vOrderDetailId,
                                           @SoldToId = @vSoldToId, @ShipToId = @vShipToId ,
                                           @CreatedDate = @vActivityDateTime, @CreatedBy = @UserId;
             end

           /* Update the records as processed in the temp table which are not yet processed */
           update @ttOrderDetails
           set ProcessFlag = 'Y'
           where OrderDetailId = @vOrderDetailId;

            /* Get the top 1 Order DetailId to log the audit trail and generate export */
           select Top 1 @vOrderDetailId = OD.OrderDetailId,
                        @vOrderId       = OD.OrderId,
                        @vSKUId         = OD.SKUId,
                        @vBatchNo       = PBD.PickBatchNo
           from @ttOrderDetails  OD
           left outer join PickBatchDetails PBD on (OD.OrderDetailId = PBD.OrderDetailId)
           where (ProcessFlag = 'N' /* No */)
           order by OD.OrderDetailId;
         end
    end

  /* Building success message response with counts */
  exec @xmlResult = dbo.fn_Messages_BuildActionResponse 'OrderDetails', @vAction, @vOrderDetailsUpdated, @vTotalOrderDetails;

  /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @xmlResult;

ErrorHandler:
  if (@MessageName is not null)
    begin
      select @xmlResult = dbo.fn_Messages_GetDescription(@MessageName);

      /* Inserted the messages information to display in V3 application */
      if (object_id('tempdb..#ResultMessages') is not null)
        insert into #ResultMessages (MessageType, MessageText) select 'E' /* Error */, @xmlResult;
    end

  commit transaction;
end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_OrderDetails_Modify */

Go
