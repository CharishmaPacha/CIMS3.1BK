/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/12  RKC     pr_ShipLabel_OnPrintingDocsForLPN:.Added the Audit log for LPN is marked as packed at Shipping Docs (CID-787)
  2019/07/11  AY      pr_ShipLabel_OnPrintingDocsForLPN: Remove Packed LPNs off Cart (CID-771)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_OnPrintingDocsForLPN') is not null
  drop Procedure pr_ShipLabel_OnPrintingDocsForLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_OnPrintingDocsForLPN: After shipping docs are printed, we
    may need to change status of LPN or other things, this procedure wraps up
    such updates.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_OnPrintingDocsForLPN
  (@LPNId            TRecordId,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vLPNStatus              TStatus,
          @vNewLPNStatus           TStatus,
          @vOrderId                TRecordId,
          @vTrackingNo             TTrackingNo,
          @vUCCBarcode             TBarcode,
          @vWaveType               TTypeCode,
          @vLPNPalletId            TRecordId,
          @vPalletType             TTypeCode,
          @vOrderStatus            TStatus,
          @vShipVia                TShipVia,
          @vCarrier                TCarrier,
          @vIsSmallPackageCarrier  TFlag,

          @xmlRulesData       TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

 if (@LPNId is null) return;

 select @vLPNId       = LPNId,
        @vLPN         = LPN,
        @vLPNStatus   = Status,
        @vOrderId     = OrderId,
        @vTrackingNo  = TrackingNo,
        @vUCCBarcode  = UCCBarcode,
        @vLPNPalletId = PalletId
 from LPNs
 where (LPNId = @LPNId);

 select @vWaveType    = WaveType,
        @vOrderStatus = Status,
        @vShipVia     = ShipVia
 from vwOrderHeaders
 where (OrderId = @vOrderId);

 /* Get Pallet info */
 if (@vLPNPalletId is not null)
   select @vPalletType = PalletType
   from Pallets
   where (PalletId = @vLPNPalletId);

 /* Get Shipvia info for rules */
 select @vCarrier               = Carrier,
        @vIsSmallPackageCarrier = IsSmallPackageCarrier
 from ShipVias
 where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

 /* Build the rules data to evaluate the LPN Status */
 select @xmlRulesData = (select @vOrderId               as OrderId,
                                @vLPNId                 as LPNId,
                                @vLPN                   as LPN,
                                @vLPNStatus             as LPNStatus,
                                @vOrderStatus           as OrderStatus,
                                @vTrackingNo            as TrackingNo,
                                @vUCCBarcode            as UCCBarcode,
                                @vShipVia               as ShipVia,
                                @vCarrier               as Carrier,
                                @vIsSmallPackageCarrier as IsSmallPackageCarrier,
                                @vWaveType              as WaveType,
                                @Operation              as Operation,
                                @BusinessUnit           as BusinessUnit
                         for xml raw('RootNode'), elements);

 /* Set the Order Status to Packed when LPNs is printed from ShippingDocs page for PTS Wave */
 exec pr_RuleSets_Evaluate 'LPN_SetStatus', @xmlRulesData, @vNewLPNStatus output;

 /* If LPN status has to be changed, do so */
 if (@vNewLPNStatus <> @vLPNStatus)
   begin
     exec pr_LPNs_SetStatus @vLPNId, @vNewLPNStatus output;

     /* If LPN Status changed, the could be order status changed as well, so re-evaluate
        We cannot do this in background as the change in order status may affect further
        rules on what we print */
     exec pr_OrderHeaders_SetStatus @vOrderId;
   end

   /* Packed LPNs cannot still be on carts, so remove it */
  if (@vPalletType = 'C' /* Cart */) and
     (coalesce(@vNewLPNStatus, @vLPNStatus) in ('D', 'E', 'L', 'S' /* packed or loaded */))
    exec pr_LPNs_SetPallet @vLPNId, null, @UserId;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'LPNPackedAtShippingdoc', @UserId, null /* ActivityTimestamp */,
                             @LPNId   = @vLPNId,
                             @OrderId = @vOrderId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_OnPrintingDocsForLPN */

Go
