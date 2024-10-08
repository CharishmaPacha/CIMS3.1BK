/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/14  RKC     pr_Receipts_PutawayInventory: Made changes to Recalculate the pallet (HA-507)
  2020/05/06  VS      pr_Receipts_PutawayInventory: Made the changes to send Consolidated Exports based on RO Type (HA-339)
  2018/04/17  AY      pr_Receipts_PutawayInventory: Added to update the Onhandstatus of LPNDetails as well (S2G-659)
  2013/09/04  PK      Added pr_Receipts_PutawayInventory to mark all received LPNs as Putaway when RO is closed.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_PutawayInventory') is not null
  drop Procedure pr_Receipts_PutawayInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_PutawayInventory: It marks all LPNs that are not yet
    Putaway as Putaway and generates exports for them.
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_PutawayInventory
  (@ReceiverNo    TReceiverNumber = null,
   @ReceiptId     TRecordId,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode                TInteger,
          @MessageName               TMessageName,

          @vRecordId                 TRecordId,
          @vLPNId                    TRecordId,
          @vSendConsolidatedExports  TControlValue,
          @vLPNStatus                TStatus,
          @vReceiptType              TReceiptType,
          @vDetailExportStatus       TStatus = null,
          @vQuantity                 TQuantity,

          @vExportRODsOnClose        TString;

  /* Temp table to store received LPNs */
  declare @ttReceivedLPNs Table
          (RecordId              TRecordId  identity (1,1),
           LPNId                 TRecordId,
           LPN                   TLPN,
           Status                TStatus,
           Quantity              TQuantity,
           ReceiverNo            TReceiverNumber,
           PalletId              TRecordId);

  declare @ttPalletsToRecount    TRecountKeysTable;
begin
begin try
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Get Receipt Info */
  select @vReceiptType = ReceiptType
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* Insert the Received LPNs against Receipt into temp table */
  insert into @ttReceivedLPNs (LPNId, LPN, Status, Quantity, PalletId)
    select LPNId, LPN, Status, Quantity, PalletId
    from LPNs
    where (ReceiverNumber = @ReceiverNo) and
          (ReceiptId      = @ReceiptId) and
          (BusinessUnit = @BusinessUnit) and
          (Status       in ('N' /* New */, 'R'/* Received */)) and
          (OnhandStatus = 'U'/* Unavailable */);

  /* Get the Pallets to recount further */
  insert into @ttPalletsToRecount(EntityId) select distinct PalletId from @ttReceivedLPNs

  /* Get Control vars for the type of RO in consideration */
  select @vExportRODsOnClose = dbo.fn_Controls_GetAsString('ExportRODOnClose', @vReceiptType, 'LPN', @BusinessUnit, @UserId);

  /* Get the Control option whether to Send Consolidated Exports */
  select @vSendConsolidatedExports = dbo.fn_Controls_GetAsString('Receiver', 'SendConsolidatedExports', 'PO' /* PO */,
                                                                  @BusinessUnit, @UserId);

  /* Validate the control var - Send Consolidated Exports */
  if (dbo.fn_IsInList(@vReceiptType, @vSendConsolidatedExports) > 0) /* Send Consolidated exports */
    set @vDetailExportStatus  = 'I' /* Ignore */

  /* Loop through each LPN and generate exports if the LPN is in received status */
  while (exists(select * from @ttReceivedLPNs where RecordId > @vRecordId))
    begin
      /* Get the next top 1 LPN info from the list */
      select top 1 @vRecordId  = RecordId,
                   @vLPNId     = LPNId,
                   @vLPNStatus = Status,
                   @vQuantity  = Quantity
      from @ttReceivedLPNs
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Update the LPN status to Putaway, if the LPN Status is Received */
      exec pr_LPNs_SetStatus @vLPNId, 'P'/* Status - Putaway */, 'A' /* OnhandStatus - Available */;

      /* Update the Onhandstatus of LPNDetails as well */
      update LPNDetails
      set OnhandStatus = 'A'
      where (LPNId = @vLPNId);

      /* Generating Exports for the LPNs which are in Intransit and Received Status. If consoldiated exports
         are being generated then we can ignore exports by each LPN */
      if (@vDetailExportStatus <> 'I' /* Ignore */)
        exec pr_Exports_LPNReceiptConfirmation @LPNId         = @vLPNId,
                                               @PAQuantity    = @vQuantity,
                                               @CreatedBy     = @UserId;
    end

  /*------------- Recalc Pallets -------------*/
  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'CS' /* Recalculate Counts & Status */, @BusinessUnit, @UserId;

end try
begin catch

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Receipts_PutawayInventory */

Go
