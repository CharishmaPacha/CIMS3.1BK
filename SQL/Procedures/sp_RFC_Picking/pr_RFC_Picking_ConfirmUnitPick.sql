/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/09/02  SV      pr_RFC_Picking_ConfirmUnitPick, pr_RFC_Picking_ConfirmLPNPick: Passed new param to pr_Exports_OrderData (HPI-566)
  2015/12/11  SV      pr_RFC_Picking_ConfirmBatchPick, pr_RFC_Picking_ConfirmUnitPick: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2014/04/09  PV      pr_RFC_Picking_ConfirmBatchPick,pr_RFC_Picking_ConfirmLPNPick, pr_RFC_Picking_ConfirmUnitPick
  2013/03/15  PKS     pr_RFC_Picking_ConfirmUnitPick: Used function fn_SKUs_GetSKU to fetch SKU Information
  2012/06/29  AY      pr_RFC_Picking_GetUnitPick, pr_RFC_Picking_ConfirmUnitPick: Enahncements
  2012/06/23  PK      pr_RFC_Picking_ConfirmLPNPick, pr_RFC_Picking_ConfirmUnitPick: Updating PickBatch Status.
  2011/11/03  PK      pr_RFC_Picking_ConfirmUnitPick : Fix for scaning Same LPN in Source and Destination.
  2011/04/06  VM      pr_RFC_Picking_ConfirmUnitPick, pr_RFC_Picking_ConfirmLPNPick:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ConfirmUnitPick') is not null
  drop Procedure pr_RFC_Picking_ConfirmUnitPick;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ConfirmUnitPick:
    During Confirm Unit Picking, user can confirm the pick by scanning the SKU
    or the Location as suggested by the earlier response.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ConfirmUnitPick
  (/* Standard params */
   @DeviceId               TDeviceId,
   @UserId                 TUserId,
   @BusinessUnit           TBusinessUnit,
   /* User keyed criteria */
   @PickTicket             TPickTicket,
   @PickZone               TZoneId,
   @PickingPallet          TPallet,
-- @OrderType              TTypeCode,
   /* Info from earlier response */
   @OrderDetailId          TRecordId,
   @FromLPN                TLPN,
   @FromLPNId              TRecordId,
   /* User confirmed values */
   @ToLPN                  TLPN,
   @UnitsPicked            TInteger,
   @ScannedEntity          TLocation,   /* This could be SKU, LPN or LOC */
   @ShortPick              TFlag = 'N', /* Default it set to 'N'...Caller will send the required value */
   /* output */
   @xmlResult              xml        output)
As
  declare @ValidPickZone                         TZoneId,
          /* From LPN */
          @vWarehouse                            TWarehouse,
          @vLPNLocation                          TLocation,
          @LPNPalletId                           TPallet,
          @vFromLPNSKUId                         TRecordId,
          @vLPNQuantity                          TInteger,
          @vValidFromLPN                         TLPN,
          @vLocationSKUCount                     TInteger,
          /* To LPN */
          @vValidToLPN                           TLPN,
          @vToLPNId                              TRecordId,
          @vToLPNType                            TTypeCode,
          @vToLPNOrderId                         TRecordId,
          @vToLPNStatus                          TStatus,
          @vToLPNPallet                          TPallet,
          /* Order Detail */
          @vUnitsToAllocate                      TInteger,
          /* Picked */
          @vPickedSKUId                          TRecordId,
          @vPickedFromLPNId                      TRecordId,
          /* Pallet */
          @vPickingPalletId                      TRecordId,
          /* Next Pick */
          @vNextLPNToPickFrom                    TLPN,
          @vNextLPNIdToPickFrom                  TRecordId,
          @vNextLocationToPickFrom               TLocation,
          @vSKUToPick                            TSKU,
          @vUnitsToPick                          TInteger,

          @vValidPickTicket                      TPickTicket,
          @vOrderId                              TRecordId,
          @vValidPickingPallet                   TPallet,
          @OrderStatus                           TStatus,
          @vOrderSKUId                           TRecordId,
          @vPickBatchId                          TRecordId,
          @vPickBatchNo                          TPickBatchNo,
          /* @OrderDetailId                         TRecordId, */
          @UnitsAuthorizedToShip                 TInteger,
          @UnitsAssigned                         TInteger,
          @ConfirmUnitPickMessage                TMessageName,
          @vConfirmPick                          TControlValue,
          @ActivityType                          TActivityType,
          @vActivityLogId                        TRecordId;

  declare @ReturnCode                            TInteger,
          @MessageName                           TMessageName,
          @CCMessage                             TDescription,
          @Message                               TDescription,
          @xmlResultvar                          TVarchar;
begin /* pr_RFC_Picking_ConfirmUnitPick */
begin try
  SET NOCOUNT ON;

  /* Make null if empty strings are passed */
  select @PickTicket    = nullif(@PickTicket,    ''),
         @PickZone      = nullif(@PickZone,      ''),
         @PickingPallet = nullif(@PickingPallet, ''),
--         @OrderType        = nullif(@OrderType,     '');
         @ToLPN         = nullif(@ToLPN,         ''),
         @ScannedEntity = nullif(@ScannedEntity, ''),
         @ActivityType  = 'UnitPick';

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @FromLPNId, @FromLPN, 'LPN',
                      @Value1 = @ToLPN, @Value2 = @UnitsPicked, @Value3 = @PickingPallet,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given PickTicket is valid */
  exec pr_Picking_ValidatePickTicket @PickTicket,
                                     @vOrderId         output,
                                     @vValidPickTicket output;

  /* Verify whether the given PickZone is valid, if provided only */
  exec pr_ValidatePickZone @PickZone, @ValidPickZone output;

  /* Validating the Pallet */
  if (@PickingPallet is not null)
    exec pr_Picking_ValidatePallet @PickingPallet, 'U' /* Pallet in Use */,
                                   0 /* Pick Batch No */,
                                   @vValidPickingPallet output,
                                   null /* TaskId */, null /* TaskDetailId */;

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get ToLPN Info to validate against FromLPN Info */
  select @vToLPNId       = LPNId,
         @vValidToLPN    = LPN,
         @vToLPNOrderId  = OrderId,
         @vToLPNType     = LPNType,
         @vToLPNStatus   = Status,
         @vToLPNPallet   = Pallet
  from vwLPNs
  where (LPN          = @ToLPN) and
        (BusinessUnit = @BusinessUnit);

  /* select OrderId, SKUId to validate while picking and placing the Order into LPN */
  select @vOrderId         = OrderId,
         @vOrderSKUId      = SKUId,
         @vUnitsToAllocate = UnitsToAllocate
  from OrderDetails
  where (OrderDetailId = @OrderDetailId);

  /* Check if the user scanned the SKU or UPC */
  select top 1 @vPickedSKUId = SS.SKUId
  from dbo.fn_SKUs_GetScannedSKUs (@ScannedEntity, @BusinessUnit) SS
    join vwLPNDetails LD on (SS.SKUId = LD.SKUId) and (LD.LPN = @FromLPN);

  if (@@rowcount > 0) set @vConfirmPick = 'SKU';

  /* If it wasn't the SKU that was scanned, check if it is a picklane */
  if (@vPickedSKUId is null)
    begin
      /* Get all info to ensure that if it is NOT a multi SKU picklane as
         scanning the Location is not sufficient in that scenario */
      select @vPickedFromLPNId  = Min(LPNId),
             @vPickedSKUId      = Min(SKUId),
             @vLocationSKUCount = count(*)
      from vwLPNs
      where (Location     = @ScannedEntity) and
            (BusinessUnit = @BusinessUnit);

      if (@@rowcount > 0) set @vConfirmPick = 'LOC';
    end

  /* Check if the scanned Entity is an LPN */
  if (@vPickedSKUId is null)
    begin
      select @vPickedFromLPNId = LPNId,
             @vPickedSKUId     = SKUId
      from LPNs
      where (LPN          = @ScannedEntity) and
            (BusinessUnit = @BusinessUnit);

      if (@@rowcount > 0) set @vConfirmPick = 'LPN';
    end

  /* Get From LPN Information - */
  select @vLPNQuantity   = Quantity,
         @vValidFromLPN  = LPN,
         @vLPNLocation   = Location,
         @vWarehouse     = DestWarehouse,
         @vFromLPNSKUId  = SKUId
  from vwLPNs
  where (LPNId        = coalesce(@vPickedFromLPNId, @FromLPNId)) and
        (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vValidFromLPN is null)
    set @MessageName = 'InvalidFromLPN';
  else
  if (@vValidToLPN is null)
    set @MessageName = 'InvalidToLPN';
  else
  if (@vConfirmPick is null)
    set @MessageName = 'ScannedInvalidEntity'
  else
  if (@vToLPNType = 'L' /* Logical */)
    set @MessageName = 'CannotPickToPickLane';
  else
  if (dbo.fn_LPNs_ValidateStatus(@vToLPNId, @vToLPNStatus, 'NFU') <> 0) and
     (@vToLPNType <> 'A'/* Cart */)
    set @MessageName = 'LPNClosedForPicking';
  else
  if (@vPickedSKUId is null)
    set @MessageName = 'InvalidPickingSKU';
  else
  if (@vPickedSKUId <> @vOrderSKUId)
    set @MessageName = 'PickingSKUNotRequested';
  else
  if (@vConfirmPick = 'LOC') and (@vLocationSKUCount > 1)
    set @MessageName = 'MultiSKUPicklane-ScanSKU';
  else
  if (@vConfirmPick = 'SKU') and (@vPickedSKUId <> @vFromLPNSKUId)
    set @MessageName = 'PickingWrongSKU';
  else
  if (@vPickedFromLPNId <> @FromLPNId)
    set @MessageName = 'PickingFromDifferentLPN';
  else
  if (@UnitsPicked > @vUnitsToAllocate)
    set @MessageName = 'PickedUnitsGTRequiredQty';
  else
  if ((@vToLPNOrderId is not null) and
      (@vOrderId <> coalesce(@vToLPNOrderId, @vOrderId)))
    set @MessageName = 'PickingToWrongOrder';
  else
  if (@PickingPallet <> @vToLPNPallet)
    set @MessageName = 'PickingToAnotherPallet';
  else
  if (@vValidFromLPN = @vValidToLPN)
    set @MessageName = 'CannotPickToSameLPN';
  else
--  if (@LPNLocation <> @PickedFromLocation)
--    set @MessageName = 'LocationDiffFromSuggested';
--  else
  if (@UnitsPicked > @vLPNQuantity)
    set @MessageName = 'PickedUnitsGTLPNQty';

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* get Picking Pallet Id here */
 if (@PickingPallet is not null)
   select @vPickingPalletId = PalletId
   from Pallets
   where (Pallet = @PickingPallet);

  /* If Error, then return Error Code/Error Message */

  /* Call ConfirmUnitPick */
  exec pr_Picking_ConfirmUnitPick @PickTicket, @OrderDetailId, @FromLPN, @ToLPN,
                                  @vPickedSKUId, @UnitsPicked, null /* TaskId */, null /* TaskDetail Id */,
                                  @BusinessUnit, @UserId, null /* ActivityType */, @vPickingPalletId;

    /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  select @ConfirmUnitPickMessage = dbo.fn_Messages_GetDescription('UnitPickSuccessful'),
         @OrderDetailId          = null /* To store next OrderDetailId */;

  /* Create a cycle counting task, if there is a short pick */
  if (@ShortPick = 'Y')
    exec @ReturnCode = pr_Locations_CreateCycleCountTask @vLPNLocation,
                                                         'ShortPick' /* Operation */,
                                                         @UserId,
                                                         @BusinessUnit,
                                                         @CCMessage output;

  if (@ReturnCode > 0 )
    begin
      select @Message = @CCMessage;
      goto ErrorHandler;
    end

  /* Call FindLPN */
  exec pr_Picking_FindLPN @vOrderId,
                          @ValidPickZone,
                          'P', /* Partially Allocable LPN Search */
                          default, /* SKU Id */
                          @vNextLPNToPickFrom      output,
                          @vNextLPNIdToPickFrom    output,
                          @vNextLocationToPickFrom output,
                          @vSKUToPick              output,
                          @vUnitsToPick            output,
                          @OrderDetailId           output;

  if (@vNextLPNToPickFrom is not null)
    begin
      exec pr_Picking_UnitPickResponse @vValidPickingPallet,
                                       @vNextLPNIdToPickFrom,
                                       @vNextLPNToPickFrom,
                                       null /* LPNDetailId */,
                                       @OrderDetailId,
                                       @vUnitsToPick,
                                       @vNextLocationToPickFrom,
                                       'U' /* Pick Type */,
                                       @ConfirmUnitPickMessage,
                                       @BusinessUnit,
                                       @UserId,
                                       @xmlResult output;
    end
  else
    begin
      exec pr_BuildRFSuccessXML @ConfirmUnitPickMessage, @xmlResult output;

      /* Find the latest Status of the Order.
         If 'Picked', we need to export picked info to host */
      select @OrderStatus = Status
      from OrderHeaders
      where OrderId = @vOrderId;

      if (@OrderStatus = 'P' /* Picked */)
        exec @ReturnCode = pr_Exports_OrderData 'Pick' /* Picked */,
                                                @OrderId       = @vOrderId,
                                                @OrderDetailId = null,
                                                @LoadId        = null,
                                                @BusinessUnit  = null,
                                                @UserId        = @UserId;
    end

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ConfirmUnitPick', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Add to RF Log */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ConfirmUnitPick */

Go
