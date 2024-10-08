/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/16  MS      pr_Receipts_ReceiveInventory,pr_Receipts_ReceiveSKUs: Changes to update WH &Location (HA-187)
  2018/07/14  VM      pr_Receipts_ReceiveSKUs: Do not send Location to pr_Receipts_ReceiveInventory if inventory to be received to picklane (OB2-294)
  2018/06/21  SV      pr_Receipts_ReceiveSKUs, pr_ReceivedCounts_AddOrUpdate: In case of ReceiveInv action from UI, we are not passing Receiver# currently.
                        Hence using the AUTO create receiver to associate the receiver# while receiving the Inv (OB2-99)
  2017/09/26  SV      pr_Receipts_ReceiveSKUs: Corrections for the earlier signature change for pr_RFC_TransferInventory (OB-587)
  2016/09/20  YJ      pr_Receipts_ReceiveSKUs: Change to caller pr_RFC_TransferInventory to build xml (CIMS-1096)
  2016/02/25  NY      pr_Receipts_ReceiveSKUs : Use  fn_Messages_BuildActionResponse to display messages
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ReceiveSKUs') is not null
  drop Procedure pr_Receipts_ReceiveSKUs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_ReceiveSKUs:
  /* <Receiving>
        <ReceiptNumber>RA_1</ReceiptNumber>
        <Location>RECVDOCK001</Location>
        <ReceiptDetails>
          <Item>
            <ReceiptDetailId>4</ReceiptDetailId>
            <SKUId>1</SKUId>
            <SKU>SKUA-10</SKU>
            <QtyToReceive>20</QtyToReceive>
            <ReceiveToLocation>RECVDOCK001</ReceiveToLocation>
          </Item>
          <Item>
            <ReceiptDetailId>4</ReceiptDetailId>
            <SKUId>1</SKUId>
            <SKU>SKUA-12</SKU>
            <QtyToReceive>10</QtyToReceive>
            <ReceiveToLocation>RECVDOCK001</ReceiveToLocation>
          </Item>
          <Item>
            <ReceiptDetailId>4</ReceiptDetailId>
            <SKUId>1</SKUId>
            <SKU>SKUA-14</SKU>
            <QtyToReceive>15</QtyToReceive>
            <ReceiveToLocation>RECVDOCK001</ReceiveToLocation>
          </Item>
        </ReceiptDetails>
    </Receiving> */
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ReceiveSKUs
  (@ReceivingInfo      TXML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Message            TMessageName output)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,

          @vRecordId              TRecordId,
          @vReceiptId             TRecordId,
          @vReceiptNumber         TReceiptNumber,
          @vReceiptDetailId       TRecordId,
          @vReceiptLine           TReceiptLine,
          @vReceiptType           TReceiptType,
          @vReceiverId            TRecordId,
          @vReceiverNumber        TReceiverNumber,
          @vSKUId                 TRecordId,
          @vSKU                   TSKU,
          @vInnerPacks            TQuantity,
          @vQuantity              TQuantity,
          @vLocationId            TRecordId,
          @vLocation              TLocation,
          @vLocationType          TLocationType,
          @vReceiveToLocationId   TRecordId,
          @vCustPO                TCustPO,

          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vLPNDetailId           TRecordId,
          @vTotalRODetailCount    TCount,
          @vUpdatedRODetailCount  TCount,

          @vControlCategory       TCategory,
          @vIsReceiverRequired    TControlValue,

          @vTIXMLInput      XML,
          @xmlRODetails     xml,
          @XmlResult        XML;

  declare @ttReceiptDetails table(RecordId          TRecordId Identity(1,1),
                                  SKUId             TRecordId,
                                  SKU               TSKU,
                                  ReceiptDetailId   TRecordId,
                                  Quantity          TQuantity,
                                  Processed         TFlag);
begin
begin try
  begin transaction;
  SET NOCOUNT ON;
  select @xmlRODetails = convert(xml, @ReceivingInfo);

  /* Read the xml, loop throught each detail and call pr_RFC_ReceiveToLocation */
  insert into @ttReceiptDetails (SKUId, SKU, ReceiptDetailId, Quantity, Processed)
    select Record.Col.value('SKUId[1]',           'TRecordId'),
           Record.Col.value('SKU[1]',             'TSKU'),
           Record.Col.value('ReceiptDetailId[1]', 'TRecordId'),
           Record.Col.value('QtyToReceive[1]',    'TQuantity'),
           'N'
    from @xmlRODetails.nodes('Receiving/ReceiptDetails/Item') as Record(Col);

  /* Fetch the initail count on of the RO lines which is to be updated */
  select @vTotalRODetailCount = count(*)
  from @ttReceiptDetails
  where (Processed = 'N');

  select @vReceiptNumber = Record.Col.value('ReceiptNumber[1]', 'TSKU'),
         @vLocation      = Record.Col.value('Location[1]', 'TLocation')
  from @xmlRODetails.nodes('Receiving') as Record(Col);

  /* Fetch the receipt information */
  select @vReceiptId   = ReceiptId,
         @vReceiptType = ReceiptType
  from ReceiptHeaders
  where (ReceiptNumber = @vReceiptNumber) and
        (BusinessUnit  = @BusinessUnit);

  /* Fetch the location information */
  select @vLocationId   = LocationId,
         @vLocationType = LocationType
  from Locations
  where (Location = @vLocation) and
        (BusinessUnit = @BusinessUnit);

  /* set the control category based on the control type */
  select @vControlCategory = 'Receiving_' + @vReceiptType;

  select @vIsReceiverRequired = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsReceiverRequired', 'AUTO', @BusinessUnit, @UserId);

  /* Validations */
  if (@vReceiptId is null)
    set @MessageName = 'ReceiptIsInvalid';
  else
  if (@vLocationId is null)
    set @MessageName = 'LocationIsInvalid';

-- ensure ROH.Warehouse = Location.Warehouse

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vRecordId = 0;

  while (exists (select * from @ttReceiptDetails where RecordId > @vRecordId))
    begin
      /* fetch the next detail line to be received */
      select top 1 @vRecordId        = RecordId,
                   @vReceiptDetailId = ReceiptDetailId,
                   @vSKUId           = SKUId,
                   @vSKU             = SKU,
                   @vQuantity        = Quantity,
                   @vLPNDetailId     = null /* Reset */
      from @ttReceiptDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Fetch the receipt details */
      select @vReceiptId       = ROD.ReceiptId,
             @vReceiptNumber   = ROH.ReceiptNumber,
             @vReceiptDetailId = ROD.ReceiptDetailId,
             @vReceiptLine     = ROD.ReceiptLine,
             @vCustPO          = ROD.CustPO
      from ReceiptHeaders ROH
        join ReceiptDetails ROD on (ROH.ReceiptId = ROD.ReceiptId)
      where (ROH.ReceiptNumber   = @vReceiptNumber) and
            (ROD.ReceiptDetailId = @vReceiptDetailId) and
            (ROD.BusinessUnit    = @BusinessUnit);

      /* Get the ReceiverId value to log the Receiver# over AT */
      if (@vReceiverNumber is not null)
        select @vReceiverId = ReceiverId
        from Receivers
        where (ReceiverNumber = @vReceiverNumber) and
              (BusinessUnit   = @BusinessUnit);
      else
      if (@vIsReceiverRequired = 'AUTO' /* Auto Create */)
        exec pr_Receivers_AutoCreateReceiver @vReceiptId, @vCustPO, @vLocationId, @BusinessUnit, @UserId,
                                             @vReceiverId output, @vReceiverNumber output;

      /* Receive Inventory - send selected location if it is not picklane location as pr_Receipts_ReceiveInventory tries to call LPNs_Move to the given location,
         which is not allowed function for picklane. However, if we pass null, it moves the LPN to a default receiving location,
         and then we will use the created LPN (output) to transfer inventory from it to the given picklane further below code */
      select @vReceiveToLocationId = case when (@vLocationType <> 'K') then @vLocationId else null end;

      exec @ReturnCode = pr_Receipts_ReceiveInventory @vReceiptId,
                                                      @vReceiptDetailId,
                                                      @vReceiverId /* ReceiverId */,
                                                      @vSKUId,
                                                      @vInnerPacks,
                                                      @vQuantity,
                                                      @vReceiveToLocationId, /* if null, receives to default receiving location of the receipt Warehouse */
                                                      null, /* Warehouse */
                                                      @vCustPO,
                                                      @BusinessUnit,
                                                      @UserId,
                                                      @vLPNId output,
                                                      @vLPNDetailId output;

      /* Update temp table by setting processed flag when particular receipt is processed */
      if (@ReturnCode = 0)
        update @ttReceiptDetails
        set Processed = 'Y' /* Yes */
        where (ReceiptDetailId = @vReceiptDetailId);
    end

  /* Now, move or transfer contents of received LPN to destination Location based on Location type */
  if (@vLocationType = 'K' /* Picklane */)
    begin
      /* Fetch the details from the LPN details table */
      select top 1 @vLPNDetailId = LPNDetailId,
                   @vLPN         = LPN,
                   @vSKUId       = SKUId,
                   @vSKU         = SKU,
                   @vInnerPacks  = 0,
                   @vQuantity    = Quantity
      from vwLPNDetails
      where (LPNId = @vLPNId)
      order by LPNDetailId;

      while (@@rowcount > 0)
        begin
          select @vTIXMLInput = (select @vLPNId           as FromLPNId,
                                        @vLPN             as FromLPN,
                                        @vSKUId           as CurrentSKUId,
                                        @vSKU             as CurrentSKU,
                                        @vInnerPacks      as NewInnerPacks,
                                        @vQuantity        as TransferQuantity,
                                        @vLocationId      as ToLocationId,
                                        @vLocation        as ToLocation,
                                        @BusinessUnit     as BusinessUnit,
                                        @UserId           as UserId
                                 for xml raw('TransferInventory'), elements);

          exec @ReturnCode = pr_RFC_TransferInventory @vTIXMLInput,
                                                      @XmlResult  output;

          /* Fetch the details from the LPN details table */
          select top 1 @vLPNDetailId = LPNDetailId,
                       @vLPN         = LPN,
                       @vSKUId       = SKUId,
                       @vSKU         = SKU,
                       @vInnerPacks  = 0,
                       @vQuantity    = Quantity
          from vwLPNDetails
          where (LPNId = @vLPNId) and (LPNDetailId > @vLPNDetailId)
          order by LPNDetailId;
        end
    end
    --else
      /* Reserve or Bulk - We should move LPN directly */

  /* Fetch the count of updated RO lines */
  select @vUpdatedRODetailCount = count(*)
  from @ttReceiptDetails
  where (Processed = 'Y' /* Yes */);

  exec @Message  = dbo.fn_Messages_BuildActionResponse 'Receipt', 'ReceiveSKUs', @vUpdatedRODetailCount, @vTotalRODetailCount;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'ReceiveToLocation', @UserId, null /* ActivityTimestamp */,
                            @LPNId      = @vLPNId,
                            @SKUId      = @vSKUId,
                            @Quantity   = @vQuantity,
                            @LocationId = @vLocationId,
                            @ReceiptId  = @vReceiptId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Receipts_ReceiveSKUs */

Go
