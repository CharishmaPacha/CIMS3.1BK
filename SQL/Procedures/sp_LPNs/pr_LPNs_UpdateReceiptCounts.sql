/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/06/16  TK      pr_LPNs_UpdateReceiptCounts: Bug fix to update Receipt counts considering LPN Status
                      pr_LPNs_Void: Pass in LPN Status to pr_LPNs_UpdateReceiptCounts (HPI-1570)
  2014/01/29  TD      Added new procedures pr_LPNs_ReverseReceiving, pr_LPNs_UpdateReceiptCounts.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_UpdateReceiptCounts') is not null
  drop Procedure pr_LPNs_UpdateReceiptCounts;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_UpdateReceiptCounts:  This procedure will update receipts which
    are on the given LPNs. This will reduce/add num units to receipt details
    based on the action.
    If PrevLPNStatus = T then we reduce the IntransitQty on the ROD
    If PrevLPNStatus = R then we reduce the ReceivedQty on the ROD
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_UpdateReceiptCounts
  (@LPNId            TRecordId,
   @PrevLPNStatus    TStatus      = null,
   @Action           TDescription = null)
as
  declare @vRecordId               TRecordId,
          @vLPNDetailId            TRecordId,
          @vLPNLine                TDetailLine,
          @vReceiptId              TRecordId,
          @vReceiptDetailId        TRecordId,
          @vLPNQuantity            TQuantity,
          @vQuantity               TQuantity,
          @vQtyReceived            TQuantity,
          @vLPNStatus              TStatus,
          @vNumLPNs                TCount,
          @vUpdateReceivedOption   TFlags,
          @vUpdateIntransitOption  TFlags;

  declare @ttLPNDetails table (LPNId               TRecordId,
                               LPNDetailId         TRecordId,
                               ReceiptId           TRecordId,
                               ReceiptDetailId     TRecordId,

                               Quantity            TQuantity,

                               RecordId            TRecordId identity (1, 1));
begin
  select @vRecordId = 0,
         @vNumLPNs  = 1; /* We do not need to send -ve values, while we are passing multiplier as -ve */

  /* Get the LPN info to update Receipt Counts */
  insert into @ttLPNDetails (LPNId, LPNDetailId, ReceiptId, ReceiptDetailId, Quantity)
    select LPNId, LPNDetailId, ReceiptId, ReceiptDetailId, Quantity
    from LPNDetails
    where (LPNId = @LPNId);

  select @vLPNStatus = Status
  from LPNs
  where (LPNId = @LPNId);

  if (@PrevLPNStatus = 'R' /* Received */) and (@vLPNStatus = 'V' /* Void */)
    select @vUpdateReceivedOption = '-';

  /* If LPN was in transit before and isn't anymore, then reduce the Intransit count */
  if (@PrevLPNStatus = 'T' /* Intransit */) and (@vLPNStatus <> 'T' /* Intransit */)
    select @vUpdateIntransitOption = '-';

  /* If LPN was in transit before and now is Received, then increaase the Received count */
  if (@PrevLPNStatus = 'T' /* Intransit */) and (@vLPNStatus = 'R' /* Received */)
    select @vUpdateReceivedOption = '+';

  /* Loop thru each detail and update receipt detail counts accordingly */
  while exists(select * from @ttLPNDetails where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId        = RecordId,
                   @vLPNDetailId     = LPNDetailId,
                   @vReceiptId       = ReceiptId,
                   @vReceiptDetailId = ReceiptDetailId,
                   @vLPNQuantity     = Quantity
      from @ttLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_ReceiptDetails_UpdateCount @ReceiptId             = @vReceiptId,
                                         @ReceiptDetailId       = @vReceiptDetailId,
                                         @UpdateReceivedOption  = @vUpdateReceivedOption,
                                         @QtyReceived           = @vLPNQuantity,
                                         @LPNsReceived          = @vNumLPNs,
                                         @UpdateIntransitOption = @vUpdateIntransitOption,
                                         @QtyIntransit          = @vLPNQuantity,
                                         @LPNsIntransit         = @vNumLPNs;

      select @vNumLPNs = 0; -- we need to reduce only once, not for each LPN detail.
    end
end /* pr_LPNs_UpdateReceiptCounts */

Go
