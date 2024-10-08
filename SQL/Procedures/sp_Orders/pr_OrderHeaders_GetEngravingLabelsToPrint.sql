/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/03/03  PSK     pr_OrderHeaders_GetEngravingLabelsToPrint:some changes in code and added AT for reprinting (HPI-792)
  2017/01/06  PSK     pr_OrderHeaders_GetEngravingLabelsToPrint: Made changes to display the Audittrail along with Generated LPN(HPI-792)
  2016/09/27  PSK     pr_OrderHeaders_GetEngravingLabelsToPrint: Added Audittrail for LPNs (HPI-792)
  2016/09/01  TK      pr_OrderHeaders_GetEngravingLabelsToPrint: Print Engraving labels for the SKUs which are pre-allocated (HPI-561)
  2016/07/29  AY      pr_OrderHeaders_GetEngravingLabelsToPrint: Maintain Engraving status using UDF10 instead of UDF5 (HPI-393)
  2016/07/08  OK      pr_OrderHeaders_GetEngravingLabelsToPrint: Enhanced to log the AT against the Orders and LPNs (HPI-245)
  2016/06/29  AY      pr_OrderHeaders_GetEngravingLabelsToPrint: Update LotNo to be PT + HostOrderLine
  2016/06/29  TK      pr_OrderHeaders_GetEngravingLabelsToPrint: Initial Revision (HPI-176)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_GetEngravingLabelsToPrint') is not null
  drop Procedure pr_OrderHeaders_GetEngravingLabelsToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_GetEngravingLabelsToPrint:

  Input:

  <Root>
    <Orders>
      <Order> </Order>
      ...
    </Orders>
    <Options>
      <ReprintLabels> </ReprintLabels>
    </Options>
  </Root>

  output:

  <Root>
    <LPNs>
      <LPN> </LPN>
      ..
    </LPNs>
    <LabelFormatName> </LabelFormatName>
    <ResultMessage> </ResultMessage>
  </Root>

  Notes:

  OH.UDF10 will be used to track of 'Engraving status'

    null/Blank - Engraving not needed (Default)
    NQ (Not qualified)
    ToPrint
    Printed
    Completed
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_GetEngravingLabelsToPrint
  (@Orders         TXML,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @LPNsToPrint    TXML output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TMessage,

          @OrderData          xml,
          @vReprintLabels     TFlag,
          @vOrderId           TRecordId,
          @vSalesOrder        TSalesOrder,
          @vPickTicket        TPickTicket,
          @vOrderWH           TWarehouse,
          @vEngravingStatus   TUDF,

          @vLPNDetailId       TRecordId,
          @vTempLPNId         TRecordId,
          @vTempLPN           TLPN,
          @vQuantity          TQuantity,
          @vSKUId             TRecordId,
          @vLot               TLot,

          @vLPNIdForAT        TRecordId,

          @vDtlRecId          TRecordId,
          @vRecordId          TRecordId,
          @vAuditId           TRecordId,
          @vAuditActivity     TActivityType;

  declare @vSelectedOrderCount  TCount,
          @vAlreadyPrintedCount TCount,
          @vInvalidStatusCount  TCount,
          @vOrdersProcessed     TCount;

  declare @ttLPNsToBePrinted  TEntityKeysTable,
          @ttOrdersUpdated    TEntityKeysTable,
          @ttLPNsNewlyPrinted TEntityKeysTable;

  /* Temp table to hold all the Orders to be updated */
  declare @ttOrders table (OrderId         TRecordId,
                           PickTicket      TPickTicket,
                           Warehouse       TWarehouse,
                           EngravingStatus TUDF,

                           RecordId        TRecordId Identity(1,1));

  declare @ttOrderDetails table (OrderId        TRecordId,
                                 OrderDetailId  TRecordId,
                                 HostOrderLine  THostOrderLine,
                                 SKUId          TRecordId,
                                 Quantity       TQuantity,

                                 RecordId       TRecordId identity(1,1));

begin
begin try
  SET NOCOUNT ON;

  select @OrderData = convert(xml, @Orders);

  /* Return if there is no xmlData sent */
  if (@OrderData is null)
    return;

  /* Get the Reprint Option from the xml */
  select @vReprintLabels = Record.Col.value('ReprintLabels[1]', 'varchar(100)')
  from @OrderData.nodes('/Root/Options') as Record(Col);

  /* Load all the Orders into the temp table for which labels are to be generated */
  insert into @ttOrders (OrderId, PickTicket, Warehouse, EngravingStatus)
    select OH.OrderId,
           Record.Col.value('.', 'TPickTicket'),
           OH.Warehouse,
           coalesce(OH.UDF10, '')
    from @OrderData.nodes('/Root/Orders/Order') as Record(Col)
      join OrderHeaders OH on (OH.PickTicket   = Record.Col.value('.' , 'TPickTicket')) and
                              (OH.BusinessUnit = @BusinessUnit);

  select @vSelectedOrderCount = @@rowcount;

  /* If user selected Orders which are already printed and re-print option is No then delete them */
  delete TTO
  from @ttOrders TTO
  where (EngravingStatus  = 'Printed') and
        (@vReprintLabels  = 'N' /* No */);

  select @vAlreadyPrintedCount = @@rowcount;

  /* Remove the orders which are not to ToPrint and Printed but user wants to print labels again */
  delete TTO
  from @ttOrders TTO
  where (EngravingStatus not in ('ToPrint', 'Printed'));

  select @vInvalidStatusCount = @@rowcount;

  begin transaction;

    select @vRecordId        = 0,
           @vOrdersProcessed = 0;

    /* Loop thru all the Orders and generate temp labels if needed */
    while exists (select * from @ttOrders where RecordId > @vRecordId)
      begin
        select top 1 @vRecordId        = RecordId,
                     @vOrderId         = OrderId,
                     @vPickTicket      = PickTicket,
                     @vOrderWH         = Warehouse,
                     @vEngravingStatus = EngravingStatus
        from @ttOrders
        where (RecordId > @vRecordId)
        order by RecordId;

        /* If the Temp Labels are already generated and we are reprinting, then insert
           the LPN into the temp table */
        if (@vEngravingStatus = 'Printed') and (@vReprintLabels = 'Y')
          begin
            /* The LPN is not associated with an Order, so cannot fetch by OrderId. Each engraving
               order will have only one LPN by Lot, so get that LPN */
              select @vTempLPNId = LPNId,
                     @vTempLPN   = LPN
              from LPNs
              where ((Lot = @vSalesOrder) or (Lot = @vPickTicket)) and (Status not in ('S', 'V', 'C' /* Shipped, voided, consumed */));   -- add index by Lot on LPNs table.

            /* Get the LPN to Log AT */
            insert into @ttLPNsToBePrinted (EntityId, EntityKey)
              select @vTempLPNId, @vTempLPN;

              select @vAuditActivity ='VAS_RePrintEngravingLabels';

          end
        else
          /* Generate temp labels and print them */
          begin
            select @vAuditActivity ='VAS_PrintEngravingLabels';

            /* Generate LPNs */
            exec @vReturnCode = pr_LPNs_Generate 'C',       /* LPNType      */
                                                 1,         /* LPNsToCreate */
                                                 null,      /* @LPNFormat   */
                                                 @vOrderWH,
                                                 @BusinessUnit,
                                                 @UserId,
                                                 @vTempLPNId   output,
                                                 @vTempLPN     output;

            /* Save the LPNs generated to print them */
            insert into @ttLPNsToBePrinted (EntityId, EntityKey)
              select @vTempLPNId, @vTempLPN;

             /* Get the Orders info for which Labels are generated */
             insert into @ttOrdersUpdated (EntityId, EntityKey)
               select @vOrderId, @vPickTicket

            /* Clear temp table */
            delete from @ttOrderDetails;

            /* Get the details which requires Engraving and those whose UnitsPreAllocated in greter than Zero */
            insert into @ttOrderDetails(OrderId, OrderDetailId, HostOrderLine, SKUId, Quantity)
              select OrderId, OrderDetailId, HostOrderLine, SKUId, UnitsPreAllocated
              from OrderDetails
              where (OrderId = @vOrderId  ) and
                    (UnitsPreAllocated > 0) and
                    (charindex('[', UDF4) > 0) and
                    (UDF5 = 'BDGE');

            /* Intialize Variables */
            select @vDtlRecId = 0, @vLPNIdForAT = @vTempLPNId;

            /* Loop thru all the details and add LPNDetails */
            while exists(select * from @ttOrderDetails where RecordId > @vDtlRecId)
              begin
                select top 1 @vDtlRecId = RecordId,
                             @vSKUId    = SKUId,
                             @vQuantity = Quantity,
                             @vLot      = @vPickTicket + '.' + HostOrderLine
                from @ttOrderDetails
                where (RecordId > @vDtlRecId)
                order by RecordId;

                /* Add details to LPNs */
                exec pr_LPNDetails_AddOrUpdate @vTempLPNId, null /* LPNLine */, null /* CoO */,
                                               @vSKUId, null /* SKU */, null /* innerpacks */, @vQuantity,
                                               0 /* ReceivedUnits */, null /* ReceiptId */, null /* ReceiptDetailId */,
                                               null /* OrderId */, null /* OrderDetailId */, 'U' /* OnHandStatus */, null /* Operation */,
                                               null /* Weight */, null /* Volume */, @vLot /* Lot */,
                                               @BusinessUnit /* BusinessUnit */, @vLPNDetailId  output;

                set  @vLPNDetailId = null;
              end

            /* Update Temp Labels with Lot */
            update LPNs
            set Lot = @vPickTicket
            where LPNId = @vTempLPNId;

            /* Update Order.UDF10 */
            update OrderHeaders
            set UDF10 = 'Printed'
            where (PickTicket = @vPickTicket);

          end /* End generate temp label */

        /* Log AT */
        exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                  @LPNId         = @vTempLPNId,
                                  @OrderId       = @vOrderId,
                                  @BusinessUnit  = @BusinessUnit;

          select @vLPNIdForAT = null,  @vOrdersProcessed += 1;
      end /* End processing each order */

  /* Build result xml with all LPNs for which labels have to be printed */
  set @LPNsToPrint = (select EntityKey as LPN
                      from @ttLPNsToBePrinted
                      order by EntityKey
                      for XML raw(''), ELEMENTS)

  /* Log AT for LPNs */
  exec pr_AuditTrail_Insert 'VAS_PrintEngravingLabels_LPNs', @UserId, null /* ActivityTimestamp */,
                            @LPNId         = @vTempLPNId,
                            @BusinessUnit  = @BusinessUnit;

  /* Log AT */
  exec pr_AuditTrail_Insert 'VAS_PrintEngravingLabels', @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditId output;

  --exec pr_AuditTrail_InsertEntities @vAuditId, 'LPN', @ttLPNsNewlyPrinted, @BusinessUnit;

  exec pr_AuditTrail_InsertEntities @vAuditId, 'PickTicket', @ttOrdersUpdated, @BusinessUnit;

  /* Based upon the number of Orders Processed, give an appropriate message */
  exec @vMessage = dbo.fn_Messages_BuildActionResponse 'Order', 'PrintEngravingLabels', @vOrdersProcessed, @vSelectedOrderCount;

  /* Append label fromat name to be printed */
  set @LPNsToPrint = dbo.fn_XMLNode('Root',
                        dbo.fn_XMLNode('LPNs', @LPNsToPrint) +
                        dbo.fn_XMLNode('LabelFormatName', 'LPN_4x3EngravingLabel') +
                        dbo.fn_XMLNode('ResultMessage', @vMessage));

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_GetEngravingLabelsToPrint */

Go

