/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/14  AY      pr_ReceiptHeaders_SetStatus: Changed to use table instead of vw to optimize (FB-Support)
  2018/02/28  YJ      pr_ReceiptHeaders_SetStatus: Added changes to update QtyToReceive on ReceiptHeaders (S2G-298)
  2013/04/17  AY      pr_ReceiptDetails_UpdateCount: New procedure to update counts
                      pr_ReceiptHeaders_SetStatus: Revised to be accurate and update more counts on ROH
  2012/06/27  AY      pr_ReceiptHeaders_SetStatus: Enhance to show Intransit Status
              YA      pr_Receipts_ReceiveASNLPN: To Receive ASN LPNs
  2011/01/21  VM      pr_Receipts_ReceiveInventory: Receive to default receiving location, if the LPN is not in Location.
                      pr_ReceiptHeaders_SetStatus: Correction in Case order
  2010/12/10  VM      pr_ReceiptHeaders_SetStatus: Added and modified other procedures to call it in required places.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_SetStatus') is not null
  drop Procedure pr_ReceiptHeaders_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_SetStatus:
    This procedure is used to change/set the 'Status' of the Receipts.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it calculates the status updates.

   Status Progression:
     Initial/New             If nothing has been received yet and none in transit
                             then RO is in an Initial Status
     InTransit               If nothing has been received yet and some in transit
                             then RO is in an InTransit Status
     Receiving               If there is more to be received, then it is in Receiving Status
     Received                If there is no more to be received, then it is in Received Status
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_SetStatus
  (@ReceiptId TRecordId,
   @Status    TStatus = null output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,

          @vTotalQtyOrdered   TQuantity,
          @vTotalQtyToReceive TQuantity,
          @vQtyInTransit      TQuantity,
          @vQtyReceived       TQuantity;
begin
  SET NOCOUNT ON;

  select @ReturnCode         = 0,
         @MessageName        = null,

         @vTotalQtyOrdered   = null,
         @vTotalQtyToReceive = null,
         @vQtyInTransit      = null,
         @vQtyReceived       = null;

  /* Calculate Status, if not provided */
  if (@Status is null)
    begin
      select @vTotalQtyOrdered   = sum(QtyOrdered),
             @vTotalQtyToReceive = sum(QtyToReceive),
             @vQtyInTransit      = sum(QtyIntransit),
             @vQtyReceived       = sum(QtyReceived)
      from ReceiptDetails
      where (ReceiptId = @ReceiptId);

      /* See comments above */
      set @Status = Case
                      when (@vTotalQtyToReceive = @vTotalQtyOrdered) and
                           (@vQtyInTransit = 0)                      then 'I' /* Initial    */
                      when (@vTotalQtyToReceive = @vTotalQtyOrdered) and
                           (@vQtyInTransit > 0)                      then 'T' /* In Transit */
                      when (@vTotalQtyToReceive = 0)                 then 'E' /* Received   */
                      when (@vTotalQtyToReceive < @vTotalQtyOrdered) then 'R' /* Receiving  */
                    end
    end

  /* Update ReceiptHeaders */
  update ReceiptHeaders
  set NumUnits       = coalesce(@vTotalQtyOrdered,  NumUnits),
      UnitsReceived  = coalesce(@vQtyReceived,      UnitsReceived),
      QtyToReceive   = coalesce(@vTotalQtyToReceive,QtyToReceive),
      UnitsInTransit = coalesce(@vQtyIntransit,     UnitsIntransit),
      Status         = coalesce(@Status,            Status),
      ModifiedDate   = current_timestamp
  where (ReceiptId = @ReceiptId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ReceiptHeaders_SetStatus */

Go
