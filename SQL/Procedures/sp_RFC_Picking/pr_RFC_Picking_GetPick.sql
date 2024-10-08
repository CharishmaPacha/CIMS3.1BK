/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_GetPick') is not null
  drop Procedure pr_RFC_Picking_GetPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_GetPick:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_GetPick
  (@DeviceId        TDeviceId,
   @UserId          TUserId,
   @WarehouseId     TWarehouseId,
   @PickTicket      TPickTicket,
   @PickZone        varchar(10),  /* TZoneId */
   @SkipFieldValue  TVarchar  = null,
   @xmlResult       xml           output)
As
  declare @ValidPickZone                          varchar(10), /* TZoneId */
          @LPNToPick                              TLPN,
          @LocationToPick                         TLocation,
          @SKUToPick                              TSKU,
          @UnitsToPick                            TInteger,
          @LPNLocationId                          TLocation,
          @LPNLocation                            TLocation,
          @LPNPalletId                            TPallet,
          @LPNSKUId                               TSKU,
          @LPNSKU                                 TSKU,
          @LPNQuantity                            TInteger,
          @ValidPickTicket                        TPickTicket,
          @OrderId                                TRecordId,
          @OrderDetailId                          TRecordId,
          @OrderLine                              TOrderLine,
          @HostOrderLine                          THostOrderLine,
          @UnitsAuthorizedToShip                  TInteger,
          @UnitsAssigned                          TInteger,
          @SalesOrder                             TSalesOrder,
          @PickType                               TLookUpCode,
          @vBusinessUnit                          TBusinessUnit,
          @vActivityLogId                         TRecordId;

  declare @ReturnCode                             TInteger,
          @MessageName                            TMessageName,
          @Message                                TDescription,
          @xmlResultvar                           TVarchar;
begin /* pr_RFC_Picking_GetPick */
begin try

  /* Validate input values

  Check whether the Device is active
  Check whether the User is active
  Check whether the Device is associated with another User or User associated with Another Device
  Check whether the entered PickTicket or Sales Order is valid
  Check whether the entered PickZone, Warehouse are valid

  Validations are through..

  Process the Picking Search..

    Step 1 - Pallets which can be fully picked against the required Qty. Among the identified Pallets,
    the Pallets with Max Qty will be suggested. This would ensure that fewer number of pallets are picked.
    This process is repeated until there are no pallets to pick for the order quantity
    this could be because the rest of the pallets are larger than the required quantity or
    there is no inventory in Bulk Locations.

    Step 2 - If the remaining quantity could be picked from Picklane, then the user is directed to
    pick the item from Picklanes.

    Step 3 - If Picklane does not have sufficient quantity to satisfy the order, then user is instead
    directed to a Pallet in Bulk (if one exists) and to pick the units from the Pallet in Bulk
    this would help by having one pick from Bulk instead of One from Picklane and another from Bulk.
    We will issue the pick first from the location that can satisfy the entire order quantity.
    If that is not the case, then we will issue pick from Bulk  first followed by Picklane
    to satisfy the order to the extent possible. For ex: If order qty is 10 and Bulk has 5 units
    and Picklane has 8, we will consume 5 from Bulk and 5 from Picklane. If on the other hand
    Bulk has 5 and Picklane has 10, then it will direct to pick all 10 from Picklane.

  */
   select @PickZone       = nullif(@PickZone, ''),
          @SkipFieldValue = nullif(@SkipFieldValue, '');

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @vBusinessUnit, @UserId, @DeviceId,
                      null, @PickTicket, 'Order',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given PickTicket is valid */
  exec pr_Picking_ValidatePickTicket @PickTicket,
                                     @OrderId         output,
                                     @ValidPickTicket output;

  /* Verify whether the given PickZone is valid */
  /* select @ValidPickZone = ZoneId
  from vwPickingZones
  where (WarehouseZone = @PickZone);  */

  --if (@ValidPickZone is null)
  --  set @MessageName = 'InvalidPickZone';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Call FindLPN */
  exec pr_Picking_FindLPN @OrderId,
                          @PickZone,
                          'F', /* Full Search */
                          default, /* SKU Id */
                          @SkipFieldValue,
                          @LPNToPick       output,
                          @LocationToPick  output,
                          @SKUToPick       output,
                          @UnitsToPick     output,
                          @OrderDetailId   output;

  if (@LPNToPick is null)
    set @MessageName = 'NoLPNOrUnitsToPickForPickTicket';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* On Success, return Order Info, the Details of LPN to Pick */
  /* select LPN Information */
  select @LPNLocationId   = LocationId,
         @LPNPalletId     = PalletId,
         @LPNSKUId        = SKUId,
         @LPNQuantity     = Quantity
  from LPNs
  where (LPN = @LPNToPick);

  select @LPNSKU = SKU
  from SKUs
  where (SKUId = @LPNSKUId);

  if (@LPNSKU is null)
    select @LPNSKU = SKU,
           @LPNSKUId = SKUId
    from SKUs
    where (SKU = @SKUToPick);

  select @LPNLocation = Location
  from Locations
  where (LocationId = @LPNLocationId);

  /* select PickTicket Information */
  select @ValidPickTicket = PickTicket,
         @OrderId         = OrderId
  from OrderHeaders
  where (PickTicket = @PickTicket);

  /* select PickTicket Line Information */
  select @OrderDetailId         = OrderDetailId,
         @OrderLine             = OrderLine,
         @HostOrderLine         = HostOrderLine,
         @UnitsAuthorizedToShip = UnitsAuthorizedToShip,
         @UnitsAssigned         = UnitsAssigned
  from OrderDetails
  where (OrderDetailId = @OrderDetailId);

  if (@PickType = 'F' /* Full LPN Pick */)
    set @xmlResult =  (select @PickTicket       as PickTicket,
                              @OrderId          as OrderId,
                              @HostOrderLine    as OrderDetailId,
                              @UnitsAssigned    as OrderDetailUnitsAssigned,
                              @LPNToPick        as LPN,
                              coalesce(@LPNLocation, @LocationToPick) as LPNLocation,
                              @LPNPalletId      as LPNPallet,
                              coalesce(@LPNSKU, @SKUToPick)  as SKU,
                              coalesce(@LPNQuantity, @UnitsToPick) as LPNQuantity
                       FOR XML RAW('LPNPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('LPNPICKDETAILS'));
  else
  if (@PickType = 'P' /* Partial Pick */)
    set @xmlResult =  (select @PickTicket     as PickTicket,
                            @OrderId          as OrderId,
                            @HostOrderLine    as OrderDetailId,
                            @UnitsAssigned    as OrderDetailUnitsAssigned,
                            @LPNToPick        as LPN,
                            coalesce(@LPNLocation, @LocationToPick) as LPNLocation,
                            @LPNPalletId      as LPNPallet,
                            coalesce(@LPNSKU, @SKUToPick)  as SKU,
                            @UnitsToPick      as UnitsToPick
                     FOR XML RAW('UNITPICKINFO'), TYPE, ELEMENTS XSINIL, ROOT('UNITPICKDETAILS'));

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'GetLPNPick', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
  begin
    select @Message    = dbo.fn_Messages_GetDescription(@MessageName),
           @ReturnCode = 1;
    raiserror(@Message, 16, 1);
  end

  /* Add to RF Log */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @OrderId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback;

  set @xmlResult =  (select ERROR_NUMBER()    as ErrorNumber,
                            ERROR_SEVERITY()  as ErrorSeverity,
                            ERROR_STATE()     as ErrorState,
                            ERROR_PROCEDURE() as ErrorProcedure,
                            ERROR_LINE()      as ErrorLine,
                            ERROR_MESSAGE()   as ErrorMessage
                     FOR XML RAW('ERRORINFO'), TYPE, ELEMENTS XSINIL, ROOT('ERRORDETAILS'));

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @OrderId, @ActivityLogId = @vActivityLogId output;
end catch;

end /* pr_RFC_Picking_GetPick */

Go
