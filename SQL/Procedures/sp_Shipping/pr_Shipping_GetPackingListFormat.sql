/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2103/10/23  TD      pr_Shipping_GetPackingListFormat: Added LoadId to procedure.
  2012/06/20  AY      pr_Shipping_GetPackingListFormat: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetPackingListFormat') is not null
  drop Procedure pr_Shipping_GetPackingListFormat;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetPackingListFormat: Determines the format of the Packing
    list to be printed for the Order/LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetPackingListFormat
  (@PackingListType  TTypeCode,
   @OrderId          TRecordId,
   @LPNId            TRecordId,
   @LoadId           TRecordId,
   @BusinessUnit     TBusinessUnit,
   @ReportName       TDescription output)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @vLPN                 TLPN,
          @vShipVia             TShipVia,
          @vTrackingNo          TTrackingNo,
          @vCarriersIntegration TFlag;
begin
  select @ReturnCode  = 0,
         @Messagename = null,
         @ReportName  = null;

  /* This procedure is deprecated and not used anymore. We use rules instead */
  return;

  if (@OrderId is null) and (@LPNId is null) and (@LoadId is null)
    return;

  select @vShipVia = ShipVia
  from OrderHeaders
  where (OrderId = @OrderId);

  if (@LPNId is not null)
    select @vLPN = LPN
    from LPNs
    where (LPNId = @LPNId);

  if (@PackingListType  = 'ORD')
    set @ReportName = @BusinessUnit + 'OrderPackingList_Generic';
  else
  if (@PackingListType  = 'Load')
    set @ReportName = @BusinessUnit + 'LoadShippingManifest_Generic';
  else
  if (@PackingListType = 'LPN')
    begin
      /* Check if the LPN already has TrackingNo */
      select @vTrackingNo = TrackingNo
      from ShipLabels
      where (EntityType = 'L' /* LPN */) and (EntityKey = @vLPN) and (BusinessUnit = @BusinessUnit);

      /* get carrier integration status */
      select @vCarriersIntegration = dbo.fn_Controls_GetAsString('ShipLPNOnPack', 'CarriersIntegration',
                                                             '', @BusinessUnit, '');

      if ((@vCarriersIntegration = 'Y') and @vShipVia in ('FEDX1','FEDX2','FEDXG', 'FEDXSP') and (coalesce(@vTrackingNo, '') <> ''))
        set @ReportName = 'PackingList_FEDEX';
      else
      /* Ship Via is one among the FEDEX Services, and No Tracking Number yet */
      if ((@vCarriersIntegration = 'Y') and @vShipVia in ('FEDX1','FEDX2','FEDXG', 'FEDXSP'))
        set @ReportName = 'PackingList_FEDEX_NoLabel';
      else
      if ((@vCarriersIntegration = 'Y') and @vShipvia in ('USPS', 'USPSL'))
        set @ReportName = 'PackingList_'+@vShipVia;
      else
        /* Any other carriers or services, we print the Generic Packing List
           Users are expected to print the respective ShipLabels for those Carrier Services manually */
        set @ReportName = @BusinessUnit + 'PackingList_Generic';
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_GetPackingListFormat */

Go
