/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/21  AY      pr_LPNs_UndoReceipt: Void Received counts only if LPN still associated with Receiver (HA-2795)
                      pr_LPNs_Delete & pr_LPNs_UndoReceipt: Clear ReceiverId on LPNs (S2GMI-140)
  2018/06/06  AY      pr_LPNs_UndoReceipt: Void the ReceivedCounts when Receipt is undone (S2G-879)
  2017/05/17  AY      pr_LPNs_UndoReceipt: New implementation in place of LPNs_UpdateReceiptCounts (CIMS-1405)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_UndoReceipt') is not null
  drop Procedure pr_LPNs_UndoReceipt;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_UndoReceipt:  After an LPN has been received against a RO, we may
    have to undo the receipt because it is voided before PA or it is being reversed
    after putaway. Procedure pr_LPNs_UpdateReceiptCounts was originally implemented
    for this but only partially and used cursors, so it is being re-written.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_UndoReceipt
  (@LPNId   TRecordId,
   @Action  TDescription = null)
as
  declare @vLPNId           TRecordId,
          @vLPNStatus       TStatus,
          @vReceiptId       TRecordId,
          @vReceiverId      TRecordId;
begin
  /* Get LPN Info */
  select @vLPNId      = LPNId,
         @vLPNStatus  = Status,
         @vReceiptId  = ReceiptId,
         @vReceiverId = ReceiverId
  from LPNs
  where (LPNId = @LPNId);

  /* Remove LPN from RO, so it doesn't get included in list of LPNs of the RO. If LPN was already PA, we
     don't clear ReceiptId and ReceiverNumber because we want to show the reversed LPNs against the RO */
  if (@vLPNStatus in ('T', 'R' /* InTransit Received */))
    update LPNs
    set ReceiptId      = null,
        ReceiptNumber  = null,
        ReceiverId     = null,
        ReceiverNumber = null
    where (LPNId = @vLPNId);

  /* Remove ReceiptDetailId from LPN Details, so it doesn't get included to count received quantity */
  update LPNDetails
  set ReceiptId       = case
                          when (@vLPNStatus in ('T', 'R' /* InTransit Received */)) then null
                          else ReceiptId
                        end,
      ReceiptDetailId = null
  where (LPNId = @vLPNId);

  /* Void the ReceivedCount for the LPN if it was still associated with the Receiver */
  update ReceivedCounts
  set Status = 'V'
  where (LPNId = @vLPNId) and (@vReceiverId = @vReceiverId);

  /* Update all counts on ROD and ROH */
  exec pr_ReceiptHeaders_Recount @vReceiptId;
end /* pr_LPNs_UndoReceipt */

Go
