/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/06/29  AY      pr_Picking_UnitPickResponse: New procedure to stream line response.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_UnitPickResponse') is not null
  drop Procedure pr_Picking_UnitPickResponse;
Go

Create Procedure pr_Picking_UnitPickResponse
  (@PickPallet      TPallet,
   @LPNIdToPickFrom TRecordId,
   @LPNToPickFrom   TLPN,
   @LPNDetailId     TRecordId, /* Future use - as of now all LPNs have only one detail */
   @OrderDetailId   TRecordId,
   @UnitsToPick     TInteger,
   @LocToPickFrom   TLocation,
   @PickType        TLookUpCode,
   @PrevMessage     TDescription,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @xmlResult       xml        output)
as
  declare @PickZone                              TZoneId,
          @ToLPN                                 TLPN,
          @vLPNType                              TTypeCode,
          @PickPalletId                          TRecordId,
          @PalletToPickFrom                      TPallet,
          /* Order Header */
          @OrderId                               TRecordId,
          @ValidPickTicket                       TPickTicket,
          @vOrderType                            TTypeCode,
          @PickBatchNo                           TPickBatchNo,
          @UnitsAssigned                         TInteger, -- what for?
          /* Order Detail and SKU */
          @vOrderDetailSKUId                     TRecordId,
          @vHostOrderLine                        THostOrderLine,
          @vSKUToPick                            TSKU,
          @SKU1                                  TSKU,
          @SKU2                                  TSKU,
          @SKU3                                  TSKU,
          @SKU4                                  TSKU,
          @SKU5                                  TSKU,
          @UPC                                   TUPC,
          @UOM                                   TSKU,
          /* DropPallet */
          @PickBatchRuleId                       TRecordId,
          @DestDropZone                          TZoneId,
          @DestDropLoc                           TLocation,
          /* Display */
          @PickFromDisplay                       TVarChar,
          @PickTicketDisplay                     TPickTicket,
          @vBatchType                            TLookUpCode,
          @xmlUnitPickInfo                       TXML,
          @xmlOptions                            TXML,
          @xmlPrevResult                         TXML,
          @xmlDropInfo                           TXML,
          /* Picking Options */
          @vControlCategory                      TCategory,
          @vDefaultQty                           TControlValue,
          @vQtyEnabled                           TControlValue,
          @vConfirmPick                          TControlValue,
          @vPickBatchRuleId                      TRecordId;

begin /* pr_Picking_UnitPickResponse */

  /* Get LPN Information */
  select @LPNToPickFrom    = LPN,
         @LPNIdToPickFrom  = LPNId,
         @vLPNType         = LPNType,
         @PalletToPickFrom = coalesce(Pallet, ''),
         @LocToPickFrom    = coalesce(@LocToPickFrom, Location),
         @PickZone         = coalesce(PickingZone, '')
  from vwLPNs
  where (LPNId = @LPNIdToPickFrom) or
        ((@LPNIdToPickFrom is null) and (LPN = @LPNToPickFrom));

  --select @vLPNDetailId = RecordId
  --from LPNDetails
  --where (LPNId = @LPNIdToPickFrom);

  /* Get PickTicket Line Information */
  select @OrderDetailId     = OrderDetailId,
         @OrderId           = OrderId,
         @UnitsAssigned     = UnitsAssigned,
         @vHostOrderLine    = HostOrderLine,
         @vOrderDetailSKUId = SKUId
  from vwOrderDetails
  where (OrderDetailId = @OrderDetailId);

  /* select PickTicket Information */
  select @ValidPickTicket = PickTicket,
         @vOrderType      = OrderType,
         @PickBatchNo     = PickBatchNo
  from OrderHeaders
  where (OrderId = @OrderId);

  /* select PalletId  */
  if (@PickPallet is not null)
    select @PickPalletId = PalletId
    from Pallets
    where (Pallet = @PickPallet);

  /* Get SKU Information */
  select @vSKUToPick = SKU,
         @UPC        = coalesce(UPC,  ''),
         @UoM        = coalesce(UoM,  ''),
         @SKU1       = coalesce(SKU1, ''),
         @SKU2       = coalesce(SKU2, ''),
         @SKU3       = coalesce(SKU3, ''),
         @SKU4       = coalesce(SKU4, ''),
         @SKU5       = coalesce(SKU5, '')
  from SKUs
  where (SKUId = @vOrderDetailSKUId);

  /* Find an LPN to pick to. Of course, it should always be an LPN on the same
     Order. If picking to pallet, then it has to be on the same pallet as well.
     Unit Picking may or may not use a pallet, so this is optional.
     Also, unless picking to a cart, LPN should be in Picking status as well */
  select top 1 @ToLPN = LPN
  from LPNs
  where (OrderId = @OrderId) and
        (coalesce(PalletId, '') = coalesce(@PickPalletId, '')) and
        (LPNType = 'A' /* Cart */ or Status = 'U' /* Picking */)
  order by Quantity;

  /* Adding both Location and Zone to display in RF
     PickFrom can be a Location or Location/LPN */
  select @PickFromDisplay   = Case
                                when (coalesce(@LPNToPickFrom, '') = '') or
                                     (@vLPNType = 'L' /* Logical */) then
                                  @LocToPickFrom
                                else
                                  @LocToPickFrom + coalesce('/' + @LPNToPickFrom, '')
                              end,
         @PickTicketDisplay = @ValidPickTicket,
         @PickType          = coalesce(@PickType, 'U'/* Unit Pick */);

  set @xmlUnitPickInfo = (select @ValidPickTicket    as PickTicket,
                                 @PickTicketDisplay  as PickTicketDisplay,
                                 @OrderId            as OrderId,
                                 @OrderDetailId      as OrderDetailId,
                                 @vHostOrderLine     as OrderDetailLine,          -- Not used
                                 @UnitsAssigned      as OrderDetailUnitsAssigned, -- Not used
                                 /* Pick from Details */
                                 @LPNToPickFrom      as PickFromLPN,
                                 @LPNIdToPickFrom    as PickFromLPNId,
                                 coalesce(@LPNDetailId, '')
                                                     as PickFromLPNDetailId,
                                 @PalletToPickFrom   as PickFromPallet,
                                 @LocToPickFrom      as PickFromLocation,
                                 @PickFromDisplay    as PickFromDisplay,
                                 @PickZone           as PickZone,

                                 /* Pick Details */
                                 @vSKUToPick         as SKU,
                                 @SKU1               as SKU1,
                                 @SKU2               as SKU2,
                                 @SKU3               as SKU3,
                                 @SKU4               as SKU4,
                                 @SKU5               as SKU5,
                                 @UPC                as UPC,
                                 @UoM                as UoM,
                                 @UnitsToPick        as UnitsToPick,

                                 coalesce(@ToLPN, 'New Temp Label')
                                                     as ToLPN,
                                 'U' /* Units */     as PickType,
                                 @PickPallet         as PickToPallet
                               FOR XML raw('UNITPICKINFO'), elements );

  /* Fetching ControlValues as string and storing it in another xml variable 'xmlOptions'*/
  select @vControlCategory = 'UnitPicking'  -- + @vOrderType;
  select @vDefaultQty  = dbo.fn_Controls_GetAsString('UnitPicking', 'DefaultQty', '1',
                                                      @BusinessUnit, @UserId),
         @vQtyEnabled  = dbo.fn_Controls_GetAsString('UnitPicking', 'QtyEnabled', 'N',
                                                      @BusinessUnit, @UserId),
         @vConfirmPick = dbo.fn_Controls_GetAsString('UnitPicking', 'ConfirmPick', 'SKU',
                                                     @BusinessUnit, @UserId);

  /* Get Options from Controls */
  set @xmlOptions = (select @vDefaultQty      as DefaultPickQty,
                            @vQtyEnabled      as QuantityEnabled,
                            @vConfirmPick     as ConfirmPick /* LPN, LOC, SKU or LOCSKU */
                            for XML raw('UNITPICKING'), elements);

  /* Build the xml for the previous message */
  set @xmlPrevResult = (select 0                          as ReturnCode,
                               coalesce(@PrevMessage, '') as Message
                        for XML raw('UNITPICKING'), elements);

  /* Build xml for the drop zone and location if it is the last pick */
  set @xmlDropInfo = (select ''               as DestDropZone,
                             ''               as DestDropLocation
                            for XML raw('UNITPICKING'), elements);

  /* 5. Build XML, The return dataset is used for RF to show Locations info, Location Details and Options in seperate nodes */
  set @xmlresult = (select '<UNITPICKDETAILS>' +
                                 coalesce(@xmlUnitPickInfo, '') +
                               '<OPTIONS>' +
                                 coalesce(@xmlOptions, '') +
                               '</OPTIONS>' +
                               '<SUCCESSINFO>' +
                                 coalesce(@xmlPrevResult, '') +
                               '</SUCCESSINFO>' +
                               '<DROPINFO>' +
                                 coalesce(@xmlDropInfo, '') +
                               '</DROPINFO>' +
                           '</UNITPICKDETAILS>')
end /* pr_Picking_UnitPickResponse */

Go
