/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/20  AY      pr_Receipts_ReceiveASNLPN: Change pr_LPNs_Move to not recount Pallet if not needed (HA-3009)
  2020/12/02  AY      pr_Receipts_ReceiveASNLPN: Changed to not update Locations of all LPNs on Pallet when only one is received (HA-1750)
  2020/11/25  RIA     pr_Receipts_ReceiveASNLPN: Changes to move LPN to Location if passed (JL-309)
  2020/11/24  MS      pr_Receipts_ReceiveASNLPN: Change to build success message (JL-306)
  2020/11/19  MS      pr_Receipts_ReceiveASNLPN: Changes to validate Receiver (JL-305)
  2020/11/16  MS      pr_Receipts_ReceiveASNLPN: Made changes to display PalletInfo in Confirmation Message (JL-306)
  2020/11/02  MS      pr_Receipts_ReceiveASNLPN: Changes to send ReceiverNumber (JL-291)
  2020/10/24  MS      pr_Receipts_ReceiveASNLPN: Changes to update LocationInfo on Pallet (JL-210)
  2020/10/23  MS      pr_Receipts_ReceiveASNLPN: Made changes to validate if user Palletizing the LPN on to another Pallet (JL-212)
  2020/04/29  RT      pr_Receipts_ReceiveASNLPN: Calling pr_Exports_LPNReceiptConfirmation in place of pr_Exports_LPNData (HA-111)
  2019/02/12  SV      pr_Receipts_ReceiveASNLPN: After receiving ASNLPN against a receiver, receiver info should be updated on LPN received (CID-83)
  2018/11/27  SV      pr_Receipts_ReceiveASNLPN: Made changes to update the ReceivedCount over RD rather than with LPN Qty (OB2-708)
  2018/06/23  VM      pr_Receipts_ReceiveASNLPN: Use Auto Receiver functionality here and update ReceivedCounts (OB2-154)
  2014/04/07  NB      pr_Receipts_ReceiveASNLPN: Fix to handle intransit lpn count correctly
  2014/04/05  PV      pr_ReceiptDetails_UpdateCount: Added UnitsInTransit and LPNsInTransit counts to
                         ReceiptHeaders.
                      pr_Receipts_ReceiveASNLPN: Enhanced for mulitsku lpn receiving.
  2014/03/24  VM      pr_Receipts_ReceiveASNLPN: Update Received Qty on LPNDetails
  2012/06/27  AY      pr_ReceiptHeaders_SetStatus: Enhance to show Intransit Status
              YA      pr_Receipts_ReceiveASNLPN: To Receive ASN LPNs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ReceiveASNLPN') is not null
  drop Procedure pr_Receipts_ReceiveASNLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_ReceiveASNLPN: This procedure is to acknowledge receipt of
    an ASN LPN and palletize and/or locate it appropriately.

  Status of LPN is changed from Transit to Received,
    * when the LPNs are received on the receipt, the receipt will be updated on qty received,
    qty Intransit, LPNs received, Intransit LPNs, and also the statuses of LPN and Receipt.
    * This procedure is to receive only ASNLPNs (ASN Orders).
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ReceiveASNLPN
  (@LPNId            TRecordId,
   @LPN              TLPN,
   @LPNDetailId      TRecordId       = null,
   @Quantity         TQuantity       = 0,
   @Pallet           TPallet         = null,
   @Location         TLocation       = null,
   @ExportOption     TFlag           = 'N',
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   -----------------------------------------
   @ReceiverNumber   TReceiverNumber output,
   @Message          TMessage        output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TMessage,
          /* Receipt/Receiver */
          @vReceiptId             TRecordId,
          @vReceiptNumber         TReceiptNumber,
          @vReceiptType           TReceiptType,
          @vReceiverId            TRecordId,
          @vReceiverNumber        TReceiverNumber,
          @vReceiverStatus        TStatus,
          @vReceiptdetailId       TRecordId,
          @vCustPO                TCustPO,
          /* LPN */
          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vLPNInnerPacks         TQuantity,
          @vLPNQuantity           TQuantity,
          @vLPNSKU                TSKU,
          @vLPNDetailId           TRecordId,
          @vSKUId                 TRecordId,
          @vLPNDtlQuantity        TQuantity,
          @vLPNStatus             TStatus,
          @vLPNPallet             TPallet,
          @vAllowAnotherPallet    TFlag,
          @vLPNReceiverId         TRecordId,
          /* Pallet */
          @vPalletId              TRecordId,
          @vPallet                TPallet,
          @vPalletType            TTypeCode,
          @vPalletStatus          TStatus,
          @vPalletLocationId      TRecordId,
          /* Location */
          @vLocationId            TRecordId,
          @vLocationType          TTypeCode,
          /* Others */
          @vIntransitLPNCnt       TInteger,
          @vControlCategory       TCategory,
          @vIsReceiverRequired    TControlValue;
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vIntransitLPNCnt = 0,
         @vReceiverNumber  = nullif(@ReceiverNumber, '');

  /* Fetch LPN info to update the LPN and ROD */
  select @vReceiptId     = L.ReceiptId,
         @vReceiptNumber = L.ReceiptNumber,
         @vReceiptType   = RH.ReceiptType,
         @vLPN           = L.LPN,
         @vLPNId         = L.LPNId,
         @vLPNQuantity   = L.Quantity,
         @vLPNSKU        = L.SKU,
         @vLPNInnerPacks = L.InnerPacks,
         @vLPNStatus     = L.Status,
         @vLPNPallet     = L.Pallet,
         @vLPNReceiverId = L.ReceiverId
  from LPNs L
       left join ReceiptHeaders RH on (L.ReceiptId = RH.ReceiptId)
  where (LPNId = coalesce(@LPNId, dbo.fn_LPNs_GetScannedLPN (@LPN, @BusinessUnit, 'LTU')));

  /* set the control category based on the control type */
  select @vControlCategory = 'Receiving_' + @vReceiptType;

  /* Get controls */
  select @vIsReceiverRequired = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsReceiverRequired', 'AUTO', @BusinessUnit, @UserId),
         @vAllowAnotherPallet = case when dbo.fn_Permissions_IsAllowed(@UserId, 'AllowToReceiveLPNToanotherPallet') = '1' then 'Y' else 'N' end;

  /* Fetch ReceiptDetailId on the LPN. */
  select @vReceiptDetailId = LD.ReceiptDetailId,
         @vCustPO          = RD.CustPO,
         @vSKUId           = LD.SKUId,
         @vLPNDtlQuantity  = LD.Quantity,
         @vLPNDetailId     = LD.LPNDetailId
  from LPNDetails LD
       left join ReceiptDetails RD on (LD.ReceiptDetailId = RD.ReceiptDetailId)
  where (LD.ReceiptId    = @vReceiptId) and
        (LD.LPNId        = @vLPNId) and
        (LD.LPNDetailId  = coalesce(@LPNDetailId, LD.LPNDetailId)) and
        (LD.BusinessUnit = @BusinessUnit);

  /* Change status of LPN to Received */
  if (@vLPNStatus = 'T' /* Intransit */)
    begin
      exec pr_LPNs_SetStatus @vLPNId, 'R' /* Received */;
      set @vIntransitLPNCnt = 1;
    end

  /* Get Pallet info */
  if (@Pallet is not null)
    select @vPalletId         = PalletId,
           @vPalletType       = PalletType,
           @vPalletStatus     = Status,
           @vPalletLocationId = LocationId
    from Pallets
    where (Pallet       = @Pallet) and
          (BusinessUnit = @BusinessUnit);

  /* If Location is given, then validate it */
  if (@Location is not null)
    select @vLocationId   = LocationId,
           @vLocationType = LocationType
    from Locations
    where (Location     = @Location) and
          (BusinessUnit = @BusinessUnit);

  /* Get the ReceiverId value to log the Receiver# */
  if (@vReceiverNumber is not null)
    select @vReceiverId     = ReceiverId,
           @vReceiverStatus = Status
    from Receivers
    where (ReceiverNumber = @vReceiverNumber) and
          (BusinessUnit   = @BusinessUnit);

  /* Validate Location and its Type */
  if (@Location is not null) and (@vLocationId is null)
    set @vMessageName = 'LocationdoesNotExist';
  else
  if (@vLocationType not in ('D' /* Dock */, 'S'/* Staging */))
    set @vMessageName = 'CannotReceiveToLocationType'
  else
  if (@vReceiverStatus = 'C' /* Closed */)
    set @vMessageName = 'ReceiveASNLPN_ReceiverIsClosed';
  else
  /* Validate Pallet, its type */
  if (@Pallet is not null) and  (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  /* If user don't have permissions to Receive LPN on to different Pallet
     than the Pallet associated with LPN, then raise error. Users would be
     able to re-palletize them after receipt */
  if (@vLPNStatus = 'T' /* InTransit */) and (@vLPNPallet <> @Pallet) and (@vAllowAnotherPallet = 'N')
    set @vMessageName = 'ReceiveASNLPN_OnlySuggestedPallet';
  else
  if (@vPalletStatus <> 'E' /* Empty */) and (@vPalletType <> 'R' /* Receiving Pallet */)
    set @vMessageName = 'NotaReceivingPallet';

  if (@vMessageName is not null) goto ErrorHandler;

  /* Set LPN on Pallet if pallet is passed in */
  if (@Pallet is not null)
    begin
      /* Set LPN on pallet */
      exec pr_LPNs_SetPallet @vLPNId, @vPalletId, @UserId;

      if (@vPalletStatus = 'E' /* Empty */)
        update Pallets
        set PalletType = 'R' /* Receiving Pallet */
        where (PalletId = @vPalletId);
    end

  /* Move Pallet into the Location if it already isn't in the Location */
  if (@vPalletId is not null) and (@vLocationId is not null) and
     (coalesce(@vPalletLocationId, '') <> coalesce(@vLocationId, ''))
    exec pr_Pallets_SetLocation @vPalletId, @vLocationId, 'NIT', /* Update LPNs Location, excluding Intransit ones */
                                @BusinessUnit, @UserId;

  /* Move LPN to the location passed and if pallet is not given */
  if (@vPalletId is null) and (@vLocationId is not null)
    exec @vReturnCode = pr_LPNs_Move @vLPNId,
                                     @LPN,
                                     @vLPNStatus,
                                     @vLocationId,
                                     @Location,
                                     @BusinessUnit,
                                     @UserId,
                                     'ELP' /* UpdateOption  */;

 if (@vReceiverId is null) and (@vIsReceiverRequired = 'AUTO' /* Auto Create */)
    exec pr_Receivers_AutoCreateReceiver @vReceiptId, @vCustPO, @vLocationId, @BusinessUnit, @UserId,
                                         @vReceiverId output, @vReceiverNumber output;

  /* Add the Received Info to ReceivedCounts table */
  exec pr_ReceivedCounts_AddOrUpdate @vLPNId, @vLPNDetailId, @vLPNInnerPacks, @Quantity,
                                     @vReceiptId, @vReceiverId, @vReceiptDetailId,
                                     null /* @vPalletId */, @vLocationId, @vSKUId,
                                     '=' /*@UpdateOption */, @BusinessUnit, @UserId;

  /* The received qty should be updated with User given qty and Intransit Qty should be
     reduced by the expected qty */
  exec pr_ReceiptDetails_UpdateCount @vReceiptId,
                                     @vReceiptdetailId,
                                     '+' /* Update Received Option */,
                                     @Quantity /* Qty Received */,
                                     1 /* LPNs Received */,
                                     '-' /* Update Intransit Option */,
                                     @vLPNDtlQuantity /* Qty Intransit */,
                                     @vIntransitLPNCnt /* LPNs InTransit */;

  /* Update received units on LPNs to compliance with the code present in pr_RFC_ReceiveASNLPN,
     to handle MultiSKU ASNLPNs */
  exec pr_LPNDetails_AddOrUpdate @vLPNId,
                                 null /* LPN Line */,
                                 null /* Coo*/,
                                 null /* SKUId*/,
                                 null /* SKU */,
                                 null /* Innerpacks */,
                                 @Quantity /* Quantity */,
                                 @Quantity /* Received Units*/,
                                 @vReceiptId,
                                 @vReceiptdetailId,
                                 null /* OrderId */,
                                 null /* OrderDetailId*/,
                                 null /* OnHandStatus */,
                                 null /* Operation */,
                                 null /* Weight */,
                                 null /* Volume */,
                                 null /* Lot */,
                                 @BusinessUnit,
                                 @vLPNDetailId /* LPNDetailId */;

  /* If LPN is not already on receiver or was on diff one, Update it */
  if (@vReceiverId is not null) and (coalesce(@vLPNReceiverId, 0) <> @vReceiverId)
    update LPNs
    set  ReceiverId     = @vReceiverId,
         ReceiverNumber = @vReceiverNumber
    where (LPNId = @vLPNId);

  /* Export if required, like in case of CrossDock LPNs */
  if (@ExportOption = 'Y')
    exec pr_Exports_LPNReceiptConfirmation @LPNId       = @vLPNId,
                                           @PAQuantity  = @vLPNQuantity,
                                           @CreatedBy   = @UserId;

  /* Build the SuccessMessage conditionally */
  select @vPallet  = coalesce(@Pallet, @vLPNPallet, '');
  select @vMessage = case when @vPallet <> ''
                          then 'ASNLPNPalletizedSuccessfully'
                     else 'ASNLPNReceivedSuccessfully'
                     end;

  /* output Params */
  select @Message        = dbo.fn_Messages_Build(@vMessage, @vLPN, @vReceiptNumber + '/' + @vReceiverNumber, @vLPNSKU, @vLPNQuantity, @vPallet),
         @ReceiverNumber = @vReceiverNumber;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_ReceiveASNLPN */

Go
