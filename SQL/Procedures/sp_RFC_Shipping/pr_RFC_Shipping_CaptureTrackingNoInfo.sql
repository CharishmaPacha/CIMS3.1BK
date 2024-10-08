/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/03  VS      pr_RFC_Shipping_CaptureTrackingNoInfo: Do not update Extra spaces on LPN.Trackingnumber (CID-1250)
  2019/08/31  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Void the old Shiplabel (CID-1009)
  2019/07/23  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Even if Freight Charge is given for non small package carrier
  2018/11/05  CK/TD   pr_RFC_Shipping_CaptureTrackingNoInfo: Changes made to restrict dot(.) and dash(-) for frieght charge (HPI-2108)
  2018/05/02  TK      pr_RFC_Shipping_CaptureTrackingNoInfo: Bug fix - Don't update LPN status when it is picked, packed, staged or Loaded (S2G-798)
  2017/06/05  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Encapsulate HPI specific changes with control vars for potential
  2017/01/23  VM      pr_RFC_Shipping_CaptureTrackingNoInfo: Do not update tracking number on all order LPNs (HPI-1309)
  2016/11/29  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Do not capture tracking nos on Cart Position/Picklane or Tote (HPI-GoLive)
  2016/10/27  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Save tracking no for all LPNs of the Order (HPI-GoLive)
  2016/10/24  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Capture freight charges as Actual and List charges (HPI-GoLive)
  2016/10/04  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Not retrieving the LPN when user scans TrkNo (HPI-GoLive)
  2016/03/10  DK      pr_RFC_Shipping_CaptureTrackingNoInfo: Migrated changes from Prod and
  2016/09/23  AY      pr_RFC_Shipping_CaptureTrackingNoInfo: Change LPN to Staged status.
  2016/08/24  PK      pr_RFC_Shipping_CaptureTrackingNoInfo: Bug fix to pass in LISTNETCHARGES.
  2014/04/05  DK      pr_RFC_Shipping_CaptureTrackingNoInfo: Added Procedure.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Shipping_CaptureTrackingNoInfo') is not null
  drop Procedure pr_RFC_Shipping_CaptureTrackingNoInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Shipping_CaptureTrackingNoInfo:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Shipping_CaptureTrackingNoInfo
  (@xmlInput   TXML,
   @xmlResult  xml          output)
As
  declare @xmlInputInfo     xml,
          @vDeviceId        TDeviceId,
          @vUserId          TUserId,
          @vBusinessUnit    TBusinessUnit,
          @vActivityLogId   TRecordId,
          @vLPN             TLPN,
          @vLPNId           TRecordId,
          @vNewLPNStatus    TStatus,
          @vUCCBarcode      TBarcode,
          @vTrackingNo      TTrackingNo,
          @vFreightCharge   TVarchar,
          @Message          TDescription,
          @vOrderId         TRecordId,
          @ShippingLPNData  TXML,
          @vResponseLPNData TXML,
          @vShipViaData     TXML,
          @vLPNHeaderData   TXML,
          @vOrderHeaderData TXML,
          @vOperation       TOperation,
          @vShipVia         TShipvia,
          @vCarrier         TCarrier,
          @vLPNStatus       TStatus,
          @MessageName      TMessageName,
          @ReturnCode       TInteger;

  declare @IsSmallPackageCarrier TFlags;
  declare @vApplyTrkNoOnAllLPNs  TControlValue;

begin /* pr_RFC_Shipping_CaptureTrackingNoInfo */
begin try
  SET NOCOUNT ON;
  /* convert into xml */
  select @xmlInputInfo = convert(xml, @xmlInput);

   /* Get UserId, BusinessUnit, LPN and other stuff  from InputParams XML */
  select @vDeviceId      = Record.Col.value('DeviceId[1]',       'TDeviceId'),
         @vUserId        = Record.Col.value('UserId[1]',         'TUserId'),
         @vBusinessUnit  = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
         @vOperation     = Record.Col.value('Operation[1]',      'TDescription'),
         @vLPN           = Record.Col.value('LPN[1]',            'TLPN'),
         @vUCCBarcode    = Record.Col.value('UCCBarcode[1]',     'TBarcode'),
         @vTrackingNo    = nullif(Record.Col.value('TrackingNumber[1]', 'TTrackingNo'), ''),
         @vFreightCharge = nullif(Record.Col.value('FreightCharge[1]',  'TVarchar'), '')
  from @xmlInputInfo.nodes('CAPTURETRACKINGNOINFO') as Record(Col);

  /* Add to RF Log */
  exec pr_RFLog_Begin @xmlInputInfo, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vLPNId, @vLPN, 'LPN',
                      @Value1 = @vTrackingNo, @Value2 = @vUCCBarcode, @Value3 = @vFreightCharge,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get LPNStatus to update the tracking number */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vOrderId       = OrderId,
         @vLPNStatus     = Status
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, default /* Options */));

  /* Get Shipvia of the Order */
  select @vShipVia = ShipVia
  from Orderheaders
  where (OrderId = @vOrderId);

  /* Get carrier for the shipvia */
  select @vCarrier              = Carrier,
         @IsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia);

  /* Validations */
  if (@vLPNStatus = 'S'/* Shipped */)
    set @MessageName = 'LPNAlreadyShipped';
  else
  if (@vTrackingNo is null) and (@IsSmallPackageCarrier = 'Y' /* Yes */)
    set @MessageName = 'CaptureTrackingNo_TrackingNoRequired';
  else
  if (@vFreightCharge is null) -- if this is sent as empty from RF, it is nulled above
    set @MessageName = 'CaptureTrackingNo_FreightChargeRequired';
  else
  /* If user enter only . or - then we need to raise an error */
  if (((charindex(@vFreightCharge, '.'/* dot */) = 1) or (charindex(@vFreightCharge, '-' /* Dash */) = 1)) and
       (len(@vFreightCharge) = 1))
    set @MessageName = 'CaptureTrackingNo_FreightSpecialCharsNotAllowed';
  else
  /* Make sure user enter the numeric value */
  if (IsNumeric(@vFreightCharge) = 0)
    set @MessageName = 'CaptureTrackingNo_FreightShouldBeNumeric';
  else
  if (@IsSmallPackageCarrier = 'N' /* No */) and (cast(@vFreightCharge as money) > 0)
    set @MessageName = 'CaptureTrackingNo_FreightChargesOnlyforSPGCarrier'

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get the new LPN Status to update to when tracking no is captured */
  select @vNewLPNStatus = dbo.fn_Controls_GetAsString('Shipping_CaptureTrackingInfo', 'UpdateStatus', 'E' /* Staged */, @vBusinessUnit, @vUserId),
         @vApplyTrkNoOnAllLPNs = dbo.fn_Controls_GetAsString('Shipping_CaptureTrackingInfo', 'ApplyTrkNoOnAllLPNs', 'N' /* No */, @vBusinessUnit, @vUserId);

  if (@vOperation = 'UpdateTrackingNoInfo')
    begin
      /* Update LPN Status only if it has already been picked, if not leave it alone */
      if (charindex(@vLPNStatus, 'KGDEL' /* Picked, Packing, Packed, Staged, Loaded */) = 0)
        set @vNewLPNStatus = '';

      /* Update Tracking No on LPN along with Status. For some clients (like HPI), this is an indicator
         that the LPNs are ready to be added to the Load */
      update LPNs
      set TrackingNo = ltrim(rtrim(coalesce(@vTrackingNo, TrackingNo))),
          Status     = coalesce(nullif(@vNewLPNStatus, ''), Status)
      where (LPNId = @vLPNId);

      /* HPI wants the tracking number to be updated on all LPNs of the order if they don't have them
         because users are missing trk nos on the cartons which is causing them to physically be
         shipped but systemically remain open. User can still choose to update the tracking no on these cartons
         Freight charge will be applied on the given LPN Only */
      if (@vApplyTrkNoOnAllLPNs = 'Y')
        update LPNs
        set TrackingNo = case when coalesce(TrackingNo, '') in ('', '-') then rtrim(ltrim(@vTrackingNo)) else TrackingNo end,
            Status     = coalesce(nullif(@vNewLPNStatus, ''), Status)
        where (OrderId = @vOrderId) and
              (charindex(Status, 'KGDEL' /* Picked, Packing, Packed, Staged, Loaded */) > 0) and
              (LPNType not in ('L', 'A', 'TO' /* Picklane, Cart, Tote */));

      /* Recalculate the order status if the LPN status has changed above */
      if (@vNewLPNStatus <> '')
        exec pr_OrderHeaders_Recount @vOrderId;

      /* Take backup of existing record on shiplabel - we will create a fresh record later */
      update Shiplabels
      set EntityKey = EntityKey + cast(RecordId as varchar),
          Status    = 'V' /* Void */
      where (EntityKey = @vLPN);

      set @vResponseLPNData =  (select @vTrackingNo    as TRACKINGNO,
                                       @vFreightCharge as ACCTNETCHARGES,
                                       @vFreightCharge as LISTNETCHARGES
                                for xml raw('RESPONSE'), elements );
      set @vLPNHeaderData   =  (select @vBusinessUnit as BusinessUnit
                                for xml raw('LPNHEADER'), elements );
      set @vOrderHeaderData =  (select @vShipVia as ShipVia
                                for xml raw('ORDERHEADER'), elements );
      set @vShipViaData     =  (select @vCarrier as CARRIER
                                for xml raw('SHIPVIA'), elements );

      /* Build the total xml here */
      select  @ShippingLPNData = dbo.fn_XMLNode('SHIPPINGLPNINFO',
                                   @vResponseLPNData  +
                                   dbo.fn_XMLNode('REQUEST',
                                     coalesce(@vLPNHeaderData,   '')  +
                                     coalesce(@vOrderHeaderData, '')  +
                                     coalesce(@vShipViaData,     '')));

      /* Create a new shiplabel record */
      exec pr_Shipping_SaveLPNData @vLPN, @vLPNId, @ShippingLPNData;

      set @Message = 'CaptureTrackingNo_Update_Successful';
      exec @Message = dbo.fn_Messages_Build @Message, @vTrackingNo, @vFreightCharge, @vLPN;

      set @xmlResult = (select 0        as ErrorNumber,
                               @Message as ErrorMessage
                        for XML PATH(''),
                        root('CAPTURETRACKINGNOINFO'));

      /* Audit Trail */
      exec pr_AuditTrail_Insert 'CaptureTrackingNo', @vUserId, null /* ActivityTimestamp */,
                                @LPNId = @vLPNId, @Note1 = @vFreightCharge;
  end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  /* Handling transactions in case if it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

end catch;
 return(coalesce(@ReturnCode, 0));
end /* pr_RFC_Shipping_CaptureTrackingNoInfo */

Go
