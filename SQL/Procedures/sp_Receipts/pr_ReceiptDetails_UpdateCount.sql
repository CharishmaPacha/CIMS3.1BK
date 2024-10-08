/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/08  AY      pr_ReceiptDetails_UpdateCount: Updated RH.NumLPNs (HA-190)
  2020/04/05  AY      pr_ReceiptDetails_UpdateCount, pr_Receipts_ReceiveInventory: Bug fixes
  2020/02/18  AY      pr_ReceiptHeaders_Recalculate: New procedure (JL-58)
                      pr_ReceiptDetails_UpdateCount: Changed to not make updates when there are no changes
  2017/06/15  TK      pr_ReceiptDetails_UpdateCount: QtyReceived need not be mandatory (HPI-1570)
  2014/04/05  PV      pr_ReceiptDetails_UpdateCount: Added UnitsInTransit and LPNsInTransit counts to
                         ReceiptHeaders.
                      pr_Receipts_ReceiveASNLPN: Enhanced for mulitsku lpn receiving.
  2013/12/06  NY      pr_ReceiptDetails_UpdateCount: Updating ModifiedDate on receipts while reciving.
  2013/04/17  AY      pr_ReceiptDetails_UpdateCount: New procedure to update counts
                      pr_ReceiptHeaders_SetStatus: Revised to be accurate and update more counts on ROH
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptDetails_UpdateCount') is not null
  drop Procedure pr_ReceiptDetails_UpdateCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptDetails_UpdateCount:
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptDetails_UpdateCount
  (@ReceiptId              TRecordId,
   @ReceiptDetailId        TRecordId,
   @UpdateReceivedOption   TFlag       = '+',
   @QtyReceived            TQuantity   = 0,
   @LPNsReceived           TCount      = 0,
   @UpdateIntransitOption  TFlag       = '-',
   @QtyIntransit           TQuantity   = 0,
   @LPNsIntransit          TCount      = 0)
as
declare @vReturnCode                 TInteger,
        @vMessageName                TMessageName,
        @vMessage                    TDescription,

        @vCurrentIntransitMultiplier TInteger,
        @vNewIntransitMultiplier     TInteger,
        @vCurrentReceivedMultiplier  TInteger,
        @vNewReceivedMultiplier      TInteger;

begin /* pr_ReceiptDetails_UpdateCount */
  SET NOCOUNT ON;

  select @vReturnCode = 0,
         @vMessageName = null;

  if (@UpdateIntransitOption = '=' /* Exact */)
   select @vCurrentIntransitMultiplier = '0',
          @vNewIntransitMultiplier     = '1';
  else
  if (@UpdateIntransitOption = '+' /* Add */)
    select @vCurrentIntransitMultiplier = '1',
           @vNewIntransitMultiplier     = '1';
  else
  if (@UpdateIntransitOption = '-' /* Subtract */)
    select @vCurrentIntransitMultiplier = '1',
           @vNewIntransitMultiplier     = '-1';
  else
    /* No change */
    select @vCurrentIntransitMultiplier = '1',
           @vNewIntransitMultiplier     = '0';

  if (@UpdateReceivedOption = '=' /* Exact */)
   select @vCurrentReceivedMultiplier = '0',
          @vNewReceivedMultiplier     = '1';
  else
  if (@UpdateReceivedOption = '+' /* Add */)
    select @vCurrentReceivedMultiplier = '1',
           @vNewReceivedMultiplier     = '1';
  else
  if (@UpdateReceivedOption = '-' /* Subtract */)
    select @vCurrentReceivedMultiplier = '1',
           @vNewReceivedMultiplier     = '-1';
  else
    /* No change */
    select @vCurrentReceivedMultiplier = '1',
           @vNewReceivedMultiplier     = '0';

  /* Update ROD  */
  update ReceiptDetails
  set QtyIntransit   = case
                         when (coalesce((QtyIntransit  * @vCurrentIntransitMultiplier) +
                                (@QtyIntransit * @vNewIntransitMultiplier), QtyIntransit) < 0)
                           then 0
                       else
                         coalesce((QtyIntransit  * @vCurrentIntransitMultiplier) +
                                  (@QtyIntransit * @vNewIntransitMultiplier), QtyIntransit)
                       end,
      LPNsIntransit  = case
                         when (coalesce((LPNsIntransit * @vCurrentIntransitMultiplier) +
                                (@LPNsIntransit * @vNewIntransitMultiplier), LPNsIntransit) < 0)
                           then 0
                       else
                         coalesce((LPNsIntransit * @vCurrentIntransitMultiplier) +
                                  (@LPNsIntransit * @vNewIntransitMultiplier), LPNsIntransit)
                       end,
      QtyReceived    = coalesce((QtyReceived  * @vCurrentReceivedMultiplier) +
                                (@QtyReceived * @vNewReceivedMultiplier), QtyReceived),
      LPNsReceived   = coalesce((LPNsReceived * @vCurrentReceivedMultiplier) +
                                (@LPNsReceived * @vNewReceivedMultiplier), LPNsReceived),
      ModifiedDate   = current_timestamp
  where (ReceiptDetailId = @ReceiptDetailId);

  /* Update ROH */
  update ReceiptHeaders
  set UnitsIntransit = coalesce((UnitsIntransit  * @vCurrentIntransitMultiplier) +
                                (@QtyIntransit * @vNewIntransitMultiplier), UnitsIntransit),
      LPNsIntransit  = case when (LPNsInTransit = 0 and @vNewIntransitMultiplier = '-1') then
                         LPNsInTransit
                       else
                         coalesce((LPNsIntransit * @vCurrentIntransitMultiplier) +
                                  (@LPNsIntransit * @vNewIntransitMultiplier), LPNsIntransit)
                       end,
      UnitsReceived  = coalesce((UnitsReceived  * @vCurrentReceivedMultiplier) +
                                (@QtyReceived * @vNewReceivedMultiplier), UnitsReceived),
      LPNsReceived   = case when (LPNsReceived = 0 and @vNewReceivedMultiplier = '-1') then
                         LPNsReceived
                       else
                         coalesce((LPNsReceived * @vCurrentReceivedMultiplier) +
                                  (@LPNsReceived * @vNewReceivedMultiplier), LPNsReceived)
                       end,
      NumLPNs        = LPNsInTransit + LPNsReceived,
      ModifiedDate   = current_timestamp
  where (ReceiptId = @ReceiptId);

  /* Updates status */
  exec pr_ReceiptHeaders_SetStatus @ReceiptId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ReceiptDetails_UpdateCount */

Go
