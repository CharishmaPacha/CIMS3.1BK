/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/07  RT      pr_Receipts_PrepareForReceiving: Update PrepareToRecv to 'Y' (CID-510)
  2019/02/21  RV      pr_Receipts_PrepareForReceiving: Initial version (CID-125)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_PrepareForReceiving') is not null
  drop Procedure pr_Receipts_PrepareForReceiving;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_PrepareForReceiving:
   Prepare for Receiving: This means need to prepare LPNs for QC or Update the DestZone to do not call procedure
     to update the Dest Zone at the time of ASN LPNs receiving.
   This procedure first select the the LPNs for QC on Receipt or Receiver.
   After LPNs are selected for QC updating DestZone on remaining LPNs to increase the performance
   while ASN Receiving.
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_PrepareForReceiving
  (@ReceiptId       TRecordId        = null,
   @ReceiptNumber   TReceiptNumber   = null,
   @ReceiverId      TRecordId        = null,
   @ReceiverNumber  TReceiverNumber  = null,
   @ttLPNsToPrepare TEntityKeysTable READONLY,
   @Operation       TOperation,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   -----------------------------------------
   @Message         TMessage         output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vReceiptId         TRecordId,
          @vReceiverId        TRecordId,
          @vReceiverNumber    TReceiverNumber,
          @vLPNId             TRecordId,
          @vLPNDestZone       TZoneId,
          @vLPNDestLocation   TLocation,

          @xmlRulesData       TXML;

declare @ttLPNsToPrepareForReceive TEntityKeysTable;
begin
begin try
  select @vRecordId = 0;

  /* Get the ReceiptHeader information if ReceiptId/ReceiptNumber sent */
  if (@ReceiptId is not null) or (@ReceiptNumber is not null)
    select @vReceiptId   = ReceiptId
    from ReceiptHeaders
    where (ReceiptId = @ReceiptId) or ((ReceiptNumber = @ReceiptNumber) and (BusinessUnit = @BusinessUnit));
  else
  /* Get the Receiver information if ReceiverId/ReceiverNumber sent */
  if (@ReceiverId is not null) or (@ReceiverNumber is not null)
    select @vReceiverId     = ReceiverId,
           @vReceiverNumber = ReceiverNumber
    from Receivers
    where (ReceiverId = @ReceiverId) or (ReceiverNumber = @ReceiverNumber) and (BusinessUnit = @BusinessUnit);

  /* Call procedure to first select the LPNs for QC */
  exec pr_QCInbound_SelectLPNs @ReceiptId, @ReceiptNumber, @ReceiverId, @ReceiverNumber, @ttLPNsToPrepare /* LPNs */,
                               @Operation, @BusinessUnit, @UserId, @Message output;

  if (exists (select * from @ttLPNsToPrepare))
    insert into @ttLPNsToPrepareForReceive (EntityId, EntityKey)
      select L.LPNId, L.LPN
      from LPNs L
        join @ttLPNsToPrepare LTP on (LTP.EntityId = L.LPNId) and (coalesce(L.DestZone, '') = '')
  else
  if (@vReceiptId is not null)
    insert into @ttLPNsToPrepareForReceive (EntityId, EntityKey)
      select L.LPNId, L.LPN
      from LPNs L
      where (L.ReceiptId = @vReceiptId) and (coalesce(L.DestZone, '') = '');
  else
  if (@vReceiverId is not null)
    insert into @ttLPNsToPrepareForReceive (EntityId, EntityKey)
      select L.LPNId, L.LPN
      from LPNs L
      where (L.ReceiverNumber = @vReceiverNumber) and (coalesce(L.DestZone, '') = '');

  while (exists(select * from @ttLPNsToPrepareForReceive where RecordId > @vRecordId))
    begin
      select top 1 @vLPNId           = EntityId,
                   @vRecordId        = RecordId,
                   @vLPNDestZone     = null,
                   @vLPNDestLocation = null
      from @ttLPNsToPrepareForReceive
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get the LPN DestLocation and DestZone */
      exec pr_LPNs_UpdateDestLocationAndZone @vLPNId, 'PrepareForReceiving' /* Operation */,
                                             @vLPNDestZone      output,
                                             @vLPNDestLocation  output;
    end

  /* Update the PrepareRecvFlag to 'Y' */
  if (@ReceiptId is not null)
    update ReceiptHeaders
    set PrepareRecvFlag = 'Y'
    where (ReceiptId = @ReceiptId);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch

  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_PrepareForReceiving */

Go
