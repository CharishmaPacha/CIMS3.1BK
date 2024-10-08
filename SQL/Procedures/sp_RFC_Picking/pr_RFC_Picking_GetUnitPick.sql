/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/10  PK      pr_RFC_Picking_GetLPNPick, pr_RFC_Picking_GetUnitPick, pr_RFC_Picking_GetBatchPalletPick,
  2012/06/29  AY      pr_RFC_Picking_GetUnitPick, pr_RFC_Picking_ConfirmUnitPick: Enahncements
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_GetUnitPick') is not null
  drop Procedure pr_RFC_Picking_GetUnitPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_GetUnitPick:

   @xmlInput Contains                        XML:
                                       <SelectionCriteria>
   1. @StartRow                          <StartRow></StartRow>
   2. @EndRow                            <EndRow></EndRow>
   3. @StartLevel                        <StartLevel></StartLevel>
   4. @EndLevel                          <EndLevel></EndLevel>
   5. @StartSection                      <StartSection></StartSection>
   6. @EndSection                        <EndSection></EndSection>
                                       </SelectionCriteria>

------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_GetUnitPick
  (/* Standard Params */
   @DeviceId       TDeviceId,
   @UserId         TUserId,
   @BusinessUnit   TBusinessUnit,
   /* User inputs */
   @PickTicket     TPickTicket,
   @PickZone       TZoneId,
   @PickingPallet  TPallet,
   @OrderType      TTypeCode, /* Future Use */
   @xmlInput       xml         = null,
   /* output */
   @xmlResult      xml         output)
As
  declare @ValidPickZone                         TZoneId,
          @LPNToPickFrom                         TLPN,
          @LPNIdToPickFrom                       TRecordId,
          @LocationToPickFrom                    TLocation,
          @SKUToPick                             TSKU,
          @UnitsToPick                           TInteger,
          @LPNLocationId                         TLocation,
          @LPNLocation                           TLocation,
          @LPNPalletId                           TPallet,
          @LPNSKUId                              TSKU,
          @LPNSKU                                TSKU,
          @LPNQuantity                           TInteger,
          @ValidPickTicket                       TPickTicket,
          @vValidPickingPallet                   TPallet,
          @OrderId                               TRecordId,
          @OrderDetailId                         TRecordId,
          @OrderLine                             TOrderLine,
          @HostOrderLine                         THostOrderLine,
          @UnitsAuthorizedToShip                 TInteger,
          @UnitsAssigned                         TInteger,
          @vActivityLogId                        TRecordId;

  declare @ReturnCode                            TInteger,
          @MessageName                           TMessageName,
          @Message                               TDescription,
          @xmlResultvar                          TVarchar;
begin /* pr_RFC_Picking_GetUnitPick */
begin try

  SET NOCOUNT ON;

  /* Make null if empty strings are passed */
  select @PickTicket    = nullif(@PickTicket,    ''),
         @PickZone      = nullif(@PickZone,      ''),
         @PickingPallet = nullif(@PickingPallet, ''),
         @OrderType     = nullif(@OrderType,     '');

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @PickTicket, 'Order',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given PickTicket is valid for picking */
  exec pr_Picking_ValidatePickTicket @PickTicket,
                                     @OrderId         output,
                                     @ValidPickTicket output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* Validating the Pallet */
  if (@PickingPallet is not null)
    exec pr_Picking_ValidatePallet @PickingPallet, 'U' /* Pallet in Use */, 0,
                                   @vValidPickingPallet output,
                                   null /* TaskId */, null /* TaskDetailId */;

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Call FindLPN */
  exec pr_Picking_FindLPN @OrderId,
                          @ValidPickZone,
                          'P', /* Partially Allocable LPN Search */
                          default, /* SKU Id */
                          @LPNToPickFrom       output,
                          @LPNIdToPickFrom     output,
                          @LocationToPickFrom  output,
                          @SKUToPick           output,
                          @UnitsToPick         output,
                          @OrderDetailId       output;

  if (@LPNToPickFrom is null)
    begin
      set @MessageName = 'NoUnitsAvailToPickForPickTicket';
      goto ErrorHandler;
    end

  /* Prepare response for the Pick to send to RF Device */
  exec pr_Picking_UnitPickResponse @vValidPickingPallet,
                                   @LPNIdToPickFrom,
                                   @LPNToPickFrom,
                                   null /* LPNDetailId - Future Use */,
                                   @OrderDetailId,
                                   @UnitsToPick,
                                   @LocationToPickFrom,
                                   'U'  /* Pick Type */,
                                   null /* Prev Message */,
                                   @BusinessUnit,
                                   @UserId,
                                   @xmlResult output;

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'GetUnitPick', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Add to RF Log */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @OrderId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @OrderId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_GetUnitPick */

Go
