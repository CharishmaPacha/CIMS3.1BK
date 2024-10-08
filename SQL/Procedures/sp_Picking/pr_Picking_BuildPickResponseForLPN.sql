/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/06  SRP     pr_Picking_BatchPickResponse and pr_Picking_BuildPickResponseForLPN: Changed datatype For SKUImageURL (BK-832)
  2014/05/20  TD      Added pr_Picking_BuildPickResponseForLPN, pr_Picking_FindNextTaskForLPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_BuildPickResponseForLPN') is not null
  drop Procedure pr_Picking_BuildPickResponseForLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_BuildPickResponseForLPN: This procedure will take the inputs and
       will build the response based on the given input.

------------------------------------------------------------------------------*/
Create Procedure pr_Picking_BuildPickResponseForLPN
  (@PickPallet           TPallet  = null,
   @LPNIdToPickFrom      TRecordId,
   @LPNToPickFrom        TLPN,
   @LPNDetailIdToPick    TRecordId,
   @LocationToPickFrom   TLocation,
   @OrderDetailIdToPick  TRecordId,
   @PickBatchNo          TPickBatchNo,
   @PickZone             TZoneId,
   @SKUIdToPick          TRecordId,
   @TaskIdToPick         TRecordId,
   @TaskDetailIdToPick   TRecordId,
   @UnitsToPick          TQuantity,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId,
   @xmlResult            xml output)
as
  declare @ToLPN                      TLPN,
          @vLPNType                   TTypeCode,
          @PickPalletId               TRecordId,
          @PalletToPickFrom           TPallet,

          /* Order Header */
          @vOrderId                   TRecordId,
          @ValidPickTicket            TPickTicket,
          @vOrderType                 TTypeCode,
          @UnitsAssigned              TQuantity,

          /* Order Detail and SKU */
          @vOrderDetailId             TRecordId,
          @vOrderDetailSKUId          TRecordId,
          @vHostOrderLine             THostOrderLine,
          @vUnitsAssigned             TQuantity,
          @vSKUToPick                 TSKU,
          @SKU1                       TSKU,
          @SKU2                       TSKU,
          @SKU3                       TSKU,
          @SKU4                       TSKU,
          @SKU5                       TSKU,
          @UPC                        TUPC,
          @UOM                        TSKU,
          @vSKUImageURL               TURL,
          /* DropPallet */
          @PickBatchRuleId            TRecordId,
          @DestDropZone               TZoneId,
          @DestDropLoc                TLocation,

          @xmlUnitPickInfo            TXML,
          @xmlOptions                 TXML,
          @xmlPrevResult              TXML,
          @xmlDropInfo                TXML,

          @vDefaultQty                TControlValue,
          @vQtyEnabled                TFlags,
          @vConfirmPick               TControlValue,

          /* Display */
          @PickFromDisplay            TVarChar,
          @PickTicketDisplay          TPickTicket,
          @vBatchType                 TLookUpCode,
          @PickType                   TTypeCode,
          @vSKUDesc                   TDescription,

          @ConfirmUnitPickMessage     TDescription;

begin /* pr_Picking_BuildPickResponseForLPN */
  /* get LPN Info */
  select @vLPNType      = LPNType,
         @LPNToPickFrom = LPN
  from LPNs
  where (LPNId = @LPNIdToPickFrom);

  if (@LPNToPickFrom is null)
    begin
      set @ConfirmUnitPickMessage = dbo.fn_Messages_GetDescription('NoUnitsToPick');

      exec pr_BuildRFSuccessXML @ConfirmUnitPickMessage, @xmlResult output;
      return;
    end

  /* Get PickTicket Line Information */
  select @vOrderDetailId    = OrderDetailId,
         @vOrderId          = OrderId,
         @vUnitsAssigned    = UnitsAssigned,
         @vHostOrderLine    = HostOrderLine,
         @vOrderDetailSKUId = SKUId,
         @ValidPickTicket   = PickTicket,
         @vOrderType        = OrderType,
         @PickBatchNo       = PickBatchNo
  from vwPickBatchDetails
  where (OrderDetailId = @OrderDetailIdToPick);

  /* select PalletId  */
  if (@PickPallet is not null)
    select @PickPalletId = PalletId
    from Pallets
    where (Pallet = @PickPallet);

  /* Get SKU Information */
  select @vSKUToPick   = SKU,
         @vSKUDesc     = Description,
         @UPC          = coalesce(UPC,  ''),
         @UoM          = coalesce(UoM,  ''),
         @SKU1         = coalesce(SKU1, ''),
         @SKU2         = coalesce(SKU2, ''),
         @SKU3         = coalesce(SKU3, ''),
         @SKU4         = coalesce(SKU4, ''),
         @SKU5         = coalesce(SKU5, ''),
         @vSKUImageURL = SKUImageURL
  from SKUs
  where (SKUId = @SKUIdToPick);

  /* Adding both Location and Zone to display in RF
    PickFrom can be a Location or Location/LPN */
  select @PickFromDisplay   = Case
                                when (coalesce(@LPNToPickFrom, '') = '') or
                                     (@vLPNType = 'L' /* Logical */) then
                                  @LocationToPickFrom + coalesce('/' + @PickZone, '')
                                else
                                  @LocationToPickFrom + coalesce('/' + @LPNToPickFrom, '')
                              end,
         @PickTicketDisplay = @ValidPickTicket,
         @PickType          = coalesce(@PickType, 'U'/* Unit Pick */);

  set @xmlUnitPickInfo = (select @ValidPickTicket      as PickTicket,
                                 @PickTicketDisplay    as PickTicketDisplay,
                                 @vOrderId             as OrderId,
                                 @OrderDetailIdToPick  as OrderDetailId,
                                 @vHostOrderLine       as OrderDetailLine,          -- Not used
                                 @UnitsAssigned        as OrderDetailUnitsAssigned, -- Not used
                                 /* Pick from Details */
                                 @LPNToPickFrom        as PickFromLPN,
                                 @LPNIdToPickFrom      as PickFromLPNId,
                                 coalesce(@LPNDetailIdToPick, '')
                                                       as PickFromLPNDetailId,
                                 @PalletToPickFrom     as PickFromPallet,
                                 @LocationToPickFrom   as PickFromLocation,
                                 @PickFromDisplay      as PickFromDisplay,
                                 @PickZone             as PickZone,

                                 /* Pick Details */
                                 @vSKUToPick           as SKU,
                                 @vSKUDesc             as SKUDescription,
                                 @SKU1                 as SKU1,
                                 @SKU2                 as SKU2,
                                 @SKU3                 as SKU3,
                                 @SKU4                 as SKU4,
                                 @SKU5                 as SKU5,
                                 @UPC                  as UPC,
                                 @UoM                  as UoM,
                                 @vSKUImageURL         as SKUImageURL,
                                 @UnitsToPick          as UnitsToPick,

                                 @TaskIdToPick         as TaskId,
                                 @TaskDetailIdToPick   as TaskDetailId,

                                 coalesce(@ToLPN, 'New Temp Label')
                                                       as ToLPN,
                                 'U' /* Units */       as PickType,
                                 @PickPallet           as PickToPallet
                                 FOR XML raw('UNITPICKINFO'), elements );

  /* Fetching ControlValues as string and storing it in another xml variable 'xmlOptions'*/
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
                                '<DROPINFO>' +
                                  coalesce(@xmlDropInfo, '') +
                                '</DROPINFO>' +
                            '</UNITPICKDETAILS>')
end /* pr_Picking_BuildPickResponseForLPN */

Go
