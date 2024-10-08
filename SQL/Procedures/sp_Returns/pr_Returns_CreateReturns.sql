/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/01/10  DK      pr_Returns_CreateReturns: Enhanced to insert ReasonCode in ReceiptDetails (FB-596).
  2015/10/12  OK      pr_Returns_CreateReturns: Update Receipt Details with Ownership (FB-438)
  2015/09/30  DK      pr_Returns_CreateReturns: Enhanced to include PickTicket, Warehouse and Ownership in newly created Receipt Header (FB-416).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Returns_CreateReturns') is not null
  drop Procedure pr_Returns_CreateReturns;
Go
/*------------------------------------------------------------------------------
  Proc pr_Returns_CreateReturns:
  CreateReturns XMLInput:
  <Root>
    <Entity>Returns</Entity>
    <Action>CreateReturns</Action>
    <OrderId></OrderId>
    <ReceiptId></ReceiptId>
    <ReturnContents>
      <ReturnDetail>
        <SKU></SKU>
        <ReturnedQty><ReturnedQty>
      </ReturnDetail>
      <ReturnDetail>
        <SKU></SKU>
        <ReturnedQty><ReturnedQty>
      </ReturnDetail>
      <ReturnDetail>
        <SKU></SKU>
        <ReturnedQty><ReturnedQty>
      </ReturnDetail>
    </ReturnContents>
  </Root>

 output XML:
 <SUCCESSDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SUCCESSINFO>
    <ReturnCode>0</ReturnCode>
    <Message>RA0001 created with LPN RO00001 successfully</Message>
  </SUCCESSINFO>
</SUCCESSDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_Returns_CreateReturns
  (@XMLInput      xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML output)
as
  declare @vReturnCode        TInteger,
          @vMessage           TMessage,
          @vAction            TAction,
          @vRecordId          TRecordId,
          @vOrderId           TRecordId,
          @vReturnedQty       TQuantity,
          @vReceiptFormat     TReceiptType,
          @LPNDetailId        TRecordId,
          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vSKU               TSKU,
          @vEntity            TEntity,
          @vWarehouse         TWarehouse,
          @vPickTicket        TPickTicket,
          @vTrackingNoOrPickTicket
                              TTrackingNo,
          @vOwnership         TOwnership,
          @vOrderReceiptNo    TReceiptNumber,
          @vReceiptNo         TReceiptNumber,
          @vMessageName       TMessageName,
          @vReceiptId         TRecordId,
          @vReceiptDetailId   TRecordId,
          @vSKUId             TRecordId,
          @vProcessedQty      TQuantity,
          @vLPNDetailId       TRecordId,
          @vFirstLPN          TLPN,
          @vLastLPN           TLPN,
          @xmlResult          xml,
          @xmlData            xml;

  declare @ttReturnContents table (RecordId        TRecordId identity (1,1),
                                   SKUId           TRecordId,
                                   SKU             TSKU,
                                   ReturnedQty     TQuantity,
                                   ReasonCode      TReasonCode,
                                   ProcessedQty    TQuantity default 0,
                                   ReceiptDetailId TRecordId);

  declare @ttReceiptsToExport      TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

    select @vRecordId     = 0,
           @vProcessedQty = 0,
           @vFirstLPN     = null;

   /* Return if there is no XMLInput sent */
  if (@XMLInput is null)
    return;

  /* Get the Action, OrderId from params */
  select @vEntity   = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction   = Record.Col.value('Action[1]', 'TAction'),
         @vOrderId  = Record.Col.value('OrderId[1]','TRecordId'),
         @vTrackingNoOrPickTicket
                    = Record.Col.value('TrackingNoOrPickTicket[1]','TTrackingNo')
  from @xmlInput.nodes('/Root') as Record(Col);

  /* Insert all the return contents to temp table */
  insert into @ttReturnContents (SKU, ReturnedQty, ReasonCode)
    select  Record.Col.value('SKU[1]',              'TSKU'),
            Record.Col.value('ReturnedQuantity[1]', 'TQuantity'),
            Record.Col.value('ReasonCode[1]', 'TReasonCode')
    from @xmlInput.nodes('/Root/ReturnContents/ReturnDetail') as Record(Col);

  /* Get the Warehouse and PickTicket details */
  select @vWarehouse      = Warehouse,
         @vPickTicket     = PickTicket,
         @vOwnership      = Ownership,
         @vOrderReceiptNo = ReceiptNumber
  from OrderHeaders
  where (OrderId  = @vOrderId);

  /* Get the Receipt format and Next SeqNo to create receipt */
  exec pr_Controls_GetNextSeqNoStr 'Receipts_Return', 1, @UserId, @BusinessUnit,
                                   @vReceiptNo output;

  /* Create the ReceiptHeader */
  exec pr_Imports_ReceiptHeaders @Action        = 'I',
                                 @ReceiptNumber = @vReceiptNo,
                                 @ReceiptType   = 'R' /* Return */,
                                 @BusinessUnit  = @BusinessUnit,
                                 @PickTicket    = @vPickTicket,
                                 @Warehouse     = @vWarehouse,
                                 @Ownership     = @vOwnership,
                                 @CreatedBy     = @UserId;

  /* Build the XML import the Receipt Details input Details */
  select @xmlData  = (select   'I'               as Action,
                               @vReceiptNo       as ReceiptNumber,
                               SKU               as SKU,
                               ReturnedQty       as QtyOrdered,
                               ReasonCode        as ReasonCode,
                               @vOwnership       as Ownership,
                               @BusinessUnit     as BusinessUnit
                      from @ttReturnContents
                      for xml raw('Record'), elements);
  select @XMLData = dbo.fn_XMLNode('msgBody', convert(varchar(max), @xmlData) );
  select @XMLData = dbo.fn_XMLNode('msg', convert(varchar(max), @xmlData) );

  /* Update Receipt details */
  exec @vReturnCode = pr_Imports_ReceiptDetails @xmlData = @xmlData;

  /* Get the ReceiptId to update on LPNDetails */
  select @vReceiptId = RH.ReceiptId
  from ReceiptHeaders RH
  where (RH.ReceiptNumber = @vReceiptNo) and (BusinessUnit = @BusinessUnit);

  /* Call procedure here to export data */
  exec pr_Exports_ROData 'Return' /* TransType */, default, @vReceiptId /* ReceiptId */,
                         @BusinessUnit, @UserId;

  /* Verify whether TrackingNo exists - Update UDF9 on ExportsTable  */
  if (exists(select TrackingNo from shiplabels where (TrackingNo= @vTrackingNoOrPickTicket) and (LabelType = 'RL' /* Return label */)))
    update Exports
    set UDF9 = 'Y' /* Yes */
    where ReceiptId   = @vReceiptId and
          TransEntity = 'RD' /* Receipt Details */;

  /* Update the SKUId & ReceiptDetailId on temptable */
  update RC
  set SKUId           = S.SKUId,
      ReceiptDetailId = RD.ReceiptDetailId
  from @ttReturnContents RC
    join SKUs S on (S.SKU = RC.SKU)
    join ReceiptDetails RD on (RD.ReceiptId  = @vReceiptId) and
                              (RD.SKUId      = S.SKUId) and
                              (RD.ReasonCode = RC.ReasonCode);

  /* Loop through all the Returned SKUs to Create LPNs for each SKU/Item */
  while exists (select * from @ttReturnContents where ReturnedQty > ProcessedQty)
    begin
      /* If we use @vProcessedQty = 1 we would create an LPN for each Unit, if we use
         @vProcessedQty = RC.ReturnedQty then we would create an LPN for ech SKU */
      select top 1 @vRecordId        = RC.RecordId,
                   @vSKU             = RC.SKU,
                   @vSKUId           = S.SKUId,
                   @vReturnedQty     = RC.ReturnedQty,
                   @vProcessedQty    = 1, -- RC.ReturnedQty,
                   @vReceiptDetailId = RC.ReceiptDetailId
      from @ttReturnContents RC
           join SKUs S on (S.SKU = RC.SKU)
      where (ReturnedQty > ProcessedQty)
      order by RecordId;

      exec @vReturnCode = pr_LPNs_Generate Default /* @LPNType */,
                                           1       /* @NumLPNsToCreate */,
                                           null    /* @LPNFormat - will take default */,
                                           @vWarehouse,  /* @Warehouse */
                                           @BusinessUnit,
                                           @UserId,
                                           @vLPNId output,
                                           @vLPN   output;

      /* Update Ownership on the LPN */
      update LPNs
      set Status        = 'R' /* Received */, -- Consider it as Received LPN
          Ownership     = @vOwnership,
          ReceiptNumber = @vReceiptNo
      where (LPNId  = @vLPNId);

      /* Insert/Update the LPN Detail */
      exec @vReturnCode = pr_LPNDetails_AddOrUpdate @vLPNId,
                                                    null /* LPNLine */,
                                                    null /* CoO */,
                                                    null /* SKUId */,
                                                    @vSKU /* SKU */,
                                                    null /* innerpacks */,
                                                    @vProcessedQty /* Qty */,
                                                    @vProcessedQty /* ReceivedUnits */,
                                                    @vReceiptId /* ReceiptId */,
                                                    @vReceiptDetailId /* ReceiptDetailId */,
                                                    null /* OrderId */,
                                                    null /* OrderDetailId */,
                                                    null /* OnHandStatus */,
                                                    null /* Operation */,
                                                    null /* Weight */,
                                                    null /* Volume */,
                                                    null /* Lot */,
                                                    @BusinessUnit /* BusinessUnit */,
                                                    @LPNDetailId  output;

      /* Audit Trail */
      exec pr_AuditTrail_Insert 'CreateReturns', @UserId, null /* ActivityTimestamp */,
                                @LPNId     = @vLPNId,
                                @ReceiptId = @vReceiptId,
                                @OrderId   = @vOrderId;

      /* Update the ProcessedQty on temptable */
      update @ttReturnContents
      set ProcessedQty += @vProcessedQty
      where (RecordId = @vRecordId);

      /* Get the FirstLPN and Last LPN */
      select @vFirstLPN   = coalesce(@vFirstLPN, @vLPN),
             @vLastLPN    = @vLPN,
             /* Initializing */
             @LPNDetailId = null;
    end

  /* Recount ReceiptDetails to update the status */
  exec pr_ReceiptHeaders_Recount @vReceiptId;

  /* Update the Receipt details on Order/PickTicket */
  if (@vOrderReceiptNo is null)
    update OrderHeaders
    set ReceiptNumber = @vReceiptNo
    where (OrderId = @vOrderId);
  else
  if (@vOrderReceiptNo <> @vReceiptNo)
    update OrderHeaders
    set ReceiptNumber = null
    where (OrderId = @vOrderId);

  /* Build the message with Created RA and LPN */
  if (coalesce(@vMessage, '') = '')
    exec @vMessage = dbo.fn_Messages_Build 'CreateReturns_Successful', @vReceiptNo, @vFirstLPN/* @vFirstLPN */ ,@vLastLPN /* @vLastLPN */;

  /* Bulding the XML */
  set @xmlResult = (select 0         as ReturnCode,
                           @vMessage as Message
                    FOR XML RAW('SUCCESSINFO'), TYPE, ELEMENTS XSINIL, ROOT('SUCCESSDETAILS'));

  select @ResultXML = convert(varchar(max), @xmlResult);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, null;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Returns_CreateReturns */

Go
