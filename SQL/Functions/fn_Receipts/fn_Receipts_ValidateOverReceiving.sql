/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/27  RV      fn_Receipts_ValidateOverReceiving: Bug fixed to return validations properly for over receiving and exceed max quantity (HA-1179)
  2018/05/08  OK      fn_Receipts_ValidateOverReceiving: Added to validate the over receiving,
                      pr_Receipts_UI_ReceiveToLPN: moved the over receiving related changes to function (S2G-811)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Receipts_ValidateOverReceiving') is not null
  drop Function dbo.fn_Receipts_ValidateOverReceiving;
Go
/*------------------------------------------------------------------------------
  Function fn_Receipts_ValidateOverReceiving:

    function validates whether we are receiving more than qty receiving or not. It will return the error message
      if we are trying to receive more than qty required if the user does not have permissions.
------------------------------------------------------------------------------*/
Create Function fn_Receipts_ValidateOverReceiving
  (@ReceiptDetailId   TRecordId,
   @ReceivingQty      TQuantity,
   @UserId            TUserId)
  --------------------------------
   returns            TMessageName
as
begin
  declare @MessageName          TMessageName,
          @vQtyOrdered          TQuantity,
          @vQtyPrevReceived     TQuantity,
          @vMaxAllowedQtyToRecv TQuantity;

  /* get the required details from ReceiptDetail */
  select @vQtyOrdered          = QtyOrdered,
         @vQtyPrevReceived     = QtyReceived,
         @vMaxAllowedQtyToRecv = QtyOrdered + ExtraQtyAllowed
  from ReceiptDetails
  where (ReceiptDetailId = @ReceiptDetailId);

  /* Consider an OD containing 100 QtyToReceive and 10 ExtraQtyAllowed, hence max of 110 Qty can be received
     Case 1: While creating the LPNs to receive for the 1st time itself if we create 10 LPNs with 20 Qty, the following condition validates and notify it
     Case 2: While creating the LPNs for the
                 a) 1st time 5 LPNs  with 10 Qty each  --> Creates it
                 b) 2nd time 10 LPNs with 10 Qty each  --> Restricts as it exceeding the max Qty(110) as it already created LPNs in 1st case

     However, in another situation, if OverrideMaxQty permission is ON, they can receive more than 110 units

     Permission: Receivers.OverrideMaxQty is TRUE for user  - Allow any quantity. Does not matter whether user has Receivers.ReceiveExtraQty permission or not
                 Receivers.ReceiveExtraQty is TRUE for user - Allow quantity until MaxQtyAllowed (including Extra quantity allowed)
     */
  if (@vQtyPrevReceived + @ReceivingQty > @vMaxAllowedQtyToRecv) and (dbo.fn_Permissions_IsAllowed(@UserId, 'Receivers.OverrideMaxQty') <> 1)
    set @MessageName = 'ExceedingMaxQtyToReceive';
  else
  if (@vQtyPrevReceived + @ReceivingQty > @vQtyOrdered) and (dbo.fn_Permissions_IsAllowed(@UserId, 'Receivers.ReceiveExtraQty') <> 1)
    set @MessageName = 'ExceedingQtyToReceive';

  return @MessageName;
end /* fn_Receipts_ValidateOverReceiving */

Go
