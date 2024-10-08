/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/12  RV      pr_LPNs_MarkAsReceived: LPNs mark as Received (HPI-1044)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_MarkAsReceived') is not null
  drop Procedure pr_LPNs_MarkAsReceived;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_MarkAsReceived: This procedure will consider LPNs in Transit only
    and will update the LPN Details' Received Qty and  the LPN status to Received.
    It will update counts on ROH as well.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_MarkAsReceived
  (@LPNId          TRecordId,
   @ReceiptId      TRecordId = null)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vLPNStatus        TStatus,
          @vNewLPNStatus     TStatus,

          @Message           TMessageName;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vLPNStatus = Status,
         @ReceiptId  = coalesce(@ReceiptId, ReceiptId)
  from LPNs
  where (LPNId = @LPNId);

  /* If LPN not in InTransit, then nothing to be done */
  if (coalesce(@vLPNStatus, '') <> 'T' /* In Transit */) goto ErrorHandler;

  select @vNewLPNStatus = 'R'; /* Received */

  /* Update ReceivedUnits = Quantity as the LPN is now received */
  update LPNDetails
  set ReceivedUnits = Quantity
  where (LPNId = @LPNId);

  /* Change LPN Status to Received */
  exec pr_LPNs_SetStatus @LPNId, @vNewLPNStatus;

  /* Recount Receipt */
  exec pr_ReceiptHeaders_Recount @ReceiptId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_MarkAsReceived */

Go
