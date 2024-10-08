/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/25  TK      pr_CrossDock_ASNLPNs: Changes to Allocation_AllocateLPN proc signature (S2GCA-390)
  2018/01/29  TK      pr_CrossDock_ASNLPNs: Changed Picking_AllocateLPN to Allocation_AllocateLPN (S2G-152)
  2012/09/18  PKS     pr_CrossDock_ASNLPNs: Missed top clause is added to fetch LPN whose qty equal or
                      which is less than and near to "Units to allocate".
  2012/08/17  PKS     pr_CrossDock_ASNLPNs:'top 1' is used to fetch highest qty of LPN for CrossDock
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CrossDock_ASNLPNs') is not null
  drop Procedure pr_CrossDock_ASNLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_CrossDock_ASNLPNs:
------------------------------------------------------------------------------*/
Create Procedure pr_CrossDock_ASNLPNs
  (@LPNs            TEntityKeysTable ReadOnly,
   @OrderDetails    TEntityKeysTable ReadOnly,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @CrossDockedLPNs TCount output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,

          @vLPNId           TRecordId,
          @vLPN             TLPN,
          @vLPNDetailId     TRecordId,
          @vLPNQty          TQuantity,
          @vOrderId         TRecordId,
          @vOrderDetailId   TRecordId,
          @vOrderLineCount  TCount,
          @vSKUId           TRecordId,
          @vUnitsToAllocate TQuantity,
          @vReceiptId       TRecordId,
          @vOrderCustPO     TCustPO,
          @vReceiptCustPO   TCustPO,
          @vCDRecordId      TRecordId,
          @vLPNRecordId     TRecordId,
          @vASNCustPO       TCustPO,
          @Mode             TString,
          @vOrderDetailsCount TCount,
          @vLPNsCount         TCount,

          @ttExportLPNs     TEntityKeysTable;

declare @ttCrossDockOrders table
        (RecordId        TRecordId  identity (1,1),
         OrderId         TRecordId,
         OrderDetailId   TRecordId,
         SKUId           TRecordId,
         UnitsToAllocate TQuantity,
         Priority        TPriority,
         CancelDate      TDateTime,
         DesiredShipDate TDateTime,
         CustPO          TCustPO,
         Processed       TFlag      Default 'N');

declare @ttCrossDockLPNs table
        (RecordId        TRecordId  identity (1,1),
         LPNId           TRecordId,
         LPN             TLPN,
         LPNDetailId     TRecordId,
         SKUId           TRecordId,
         SKU             TSKU,
         Quantity        TQuantity,
         CustPO          TCustPO,
         ReceiptId       TRecordId,
         Processed       TFlag      Default 'N');

begin
  /* Depending upon the number of LPNs and OrderDetails, it would be more efficient
     to loop thru on one or the other, so determine the counts and the mode of
     looping */
  select @vOrderDetailsCount = count(*)
  from @OrderDetails;

  select @vLPNsCount = count(*)
  from @LPNs;

  if (@vOrderDetailsCount <= @vLPNsCount)
    set @Mode = 'Order';
  else
    set @Mode = 'LPN';

  /* Get all lines that need to be cross docked along with additional information */
  insert into @ttCrossDockOrders(OrderId, OrderDetailId, SKUId, UnitsToAllocate,
                                 Priority, CancelDate, DesiredShipDate, CustPO)
    select OD.OrderId, OD.OrderDetailId, OD.SKUId, OD.UnitsToAllocate,
           OH.Priority, OH.CancelDate, OH.DesiredShipDate, nullif(OH.CustPO, '')
    from @OrderDetails TOD join OrderDetails OD on (OD.OrderDetailId = TOD.EntityId)
                           join OrderHeaders OH on (OH.OrderId       = OD.OrderId)
    order by Priority, CancelDate, DesiredShipdate;

  set @vOrderLineCount = @@rowcount;

  /* select the LPNs, SKUs and its Qty from LPNDetails which has the ASN ReceiptIds. */
  insert into @ttCrossDockLPNs(LPNId, LPN, LPNDetailId, SKUId, SKU, Quantity,
                               ReceiptId, CustPO)
    select LD.LPNId, L.LPN, LD.LPNDetailId, LD.SKUId, L.SKU, LD.Quantity,
           L.ReceiptId, nullif(RH.UDF1, '') /* Temporarily assuming this would be in UDF1 */
    from @LPNs TL join LPNDetails LD     on (TL.EntityId  = LD.LPNId)
                  join LPNs L            on (LD.LPNId     = L.LPNId)
                  join ReceiptHeaders RH on (LD.ReceiptId = RH.ReceiptId)
    order by RH.DateExpected, L.LPN;

  while (1 = 1) /* Continuesly execute this loop to until there no record in either @ttCrossDockOrders or @ttCrossDockLPNs. */
    begin
      if (@Mode = 'Order')
        begin
          /* select the Order and its details from the temptable order by Priority and CancelDate */
          select top 1 @vCDRecordId      = RecordId,
                       @vOrderId         = OrderId,
                       @vOrderDetailId   = OrderDetailId,
                       @vSKUId           = SKUId,
                       @vUnitsToAllocate = UnitsToAllocate,
                       @vOrderCustPO     = CustPO
          from @ttCrossDockOrders
          where (Processed = 'N' /* No */) and (UnitsToAllocate > 0)
          order by RecordId;

          /* If there are no more qualifying order details to cross dock against, then quit */
          if @@rowcount = 0 break;

          /* Fetch LPNs on the above SKU and matching CustPO */
          select top 1 @vLPNRecordId = RecordId,
                       @vLPNId       = LPNId,
                       @vLPN         = LPN,
                       @vLPNDetailId = LPNDetailId,
                       @vLPNQty      = Quantity,
                       @vReceiptId   = ReceiptId
              from @ttCrossDockLPNs
          where (SKUId     = @vSKUId) and
                (Quantity  <= @vUnitsToAllocate) and
                (Processed = 'N'/* No */) and
                (coalesce(CustPO, '') = coalesce(@vOrderCustPO, ''))
          order by Quantity desc, RecordId;
        end
      else
      if (@Mode = 'LPN')
        begin
          /* Fetch LPNs on the above SKU and matching CustPO */
          select top 1 @vLPNRecordId = RecordId,
                       @vLPNId       = LPNId,
                       @vLPN         = LPN,
                       @vLPNDetailId = LPNDetailId,
                       @vLPNQty      = Quantity,
                       @vReceiptId   = ReceiptId,
                       @vASNCustPO   = CustPO,
                       @vSKUId       = SKUId
          from @ttCrossDockLPNs
          where (Processed = 'N'/* No */)
          order by Quantity desc, RecordId;

          /* If there are no more qualifying order details to cross dock against, then quit */
          if @@rowcount = 0 break;

          /* select the Order and its details from the temptable order by Priority and CancelDate */
          select top 1 @vCDRecordId      = RecordId,
                       @vOrderId         = OrderId,
                       @vOrderDetailId   = OrderDetailId,

                       @vUnitsToAllocate = UnitsToAllocate,
                       @vOrderCustPO     = CustPO
          from @ttCrossDockOrders
          where (Processed = 'N' /* No */) and
                (UnitsToAllocate >= @vLPNQty) and
                (coalesce(CustPO, '') = coalesce(@vASNCustPO, '')) and
                (SKUId = @vSKUId)
          order by RecordId;
        end

      /* If an LPN is found allocate it */
      if (@vLPNId is not null) and (@vOrderDetailId is not null)
        begin
         /* In pr_Picking_AllocateLPN -> pr_LPNDetails_SplitLine error will raise when no LPN exist
            with given LPNId and SKUId, and loop breaks, to avoid that I used try..catch block*/
          begin try
            /* 4. update LPNs with the OrderId and LPNDetails with the OrderDetailId based on the SKU. */
            /* use pr_Picking_AllocateLPN procedure here which would update the LPNDetails, LPN, Order Header, Details */
            exec pr_Allocation_AllocateLPN @LPNId           = @vLPNId,
                                           @OrderId         = @vOrderId,
                                           @OrderDetailId   = @vOrderDetailId,
                                           @TaskDetailId    = 0,
                                           @SKUId           = @vSKUId,
                                           @UnitsToAllocate = @vLPNQty;

            exec pr_AuditTrail_Insert 'CrossDockLPN', 'System', null /* ActivityTimestamp */,
                                      @LPNId     = @vLPNId,
                                      @OrderId   = @vOrderId,
                                      @ReceiptId = @vReceiptId;

            /* Change the flag to the processed for the LPNs which are processed */
            update @ttCrossDockLPNs
            set Processed = 'Y' /* Yes */
            output Inserted.LPNId, Inserted.LPN
            into @ttExportLPNs
            where (RecordId = @vLPNRecordId);
          end try
          begin catch
          end catch

          /* Reduce units to allocate - do not mark it processed as there may be more LPNs
             that would have to be cross docked */
          update @ttCrossDockOrders
          set UnitsToAllocate = UnitsToAllocate - @vLPNQty
          where (RecordId = @vCDRecordId);
        end
      else
        begin
          /* There are no LPNs to cross dock, so mark them as processed for this run
             they will be revisited again in next run */
          if (@Mode = 'Order')
            update @ttCrossDockOrders
            set Processed = 'Y' /* Yes */
            where (RecordId = @vCDRecordId);

          if (@Mode = 'LPN')
            update @ttCrossDockLPNs
            set Processed = 'Y' /* Yes */
            where (RecordId = @vLPNRecordId);
        end

      /* Reset all values to null which are used in the loop */
      select @vCDRecordId = null, @vOrderId = null, @vOrderDetailId = null,
             @vSKUId = null, @vUnitsToAllocate = null, @vLPNRecordId = null,
             @vLPNId = null, @vLPN = null, @vLPNDetailId = null, @vReceiptId = null;
    end

  select @CrossDockedLPNs = count(*)
  from @ttExportLPNs;

  /* Export to Panda all Cross Dock LPNs */
  exec pr_PandA_AddLPNForExport null /* LPN */, @ttExportLPNs,
                                default /* LabelType */, default /* Label format */,
                                null /* PandAStation */, null /* ProcessMode */,
                                default /* DeviceId */, @BusinessUnit, @UserId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end/* pr_CrossDock_ASNLPNs */

Go
