/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/23  AY      pr_RFC_RemoveSKUFromLocation: Performance optimization (HA-3110)
  2021/06/15  VS      pr_RFC_RemoveSKUFromLocation: Passed Logical LPNId to remove exact SKU (HA-2877)
  2019/10/30  TK      pr_RFC_RemoveSKUFromLocation: Changes to get appropriate SKU (S2CGA-1028)
  2018/11/03  AJ      Added RFLogActivity for pr_RFC_RemoveSKUFromLocation
  2017/05/08  ??      pr_RFC_RemoveSKUFromLocation: Commented check to consider validation for Inactive SKUs (HPI-GoLive)
  2016/11/24  RV      pr_RFC_RemoveSKUFromLocation: Remove AT log, We logged in calling procedure (HPI-1066)
  2016/09/02  VM      pr_RFC_RemoveSKUFromLocation: Allow removing SKU only when it is not reserved (HPI-544)
  2015/12/11  SV      pr_RFC_AddSKUToLocation, pr_RFC_RemoveSKUFromLocation, pr_RFC_UpdateSKUAttributes, pr_RFC_ValidateLocation,
  2015/10/09  AY      pr_RFC_RemoveSKUFromLocation: Bug fixes - WIP (SRI-390)
                      pr_RFC_Inv_MovePallet, pr_RFC_MoveLPN, pr_RFC_RemoveSKUFromLocation, pr_RFC_TransferInventory,
  2015/02/14  DK      pr_RFC_RemoveSKUFromLocation:Implemented AT for operation 'RemoveAllSKUs'.
                      pr_RFC_RemoveSKUFromLocation: Added procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_RemoveSKUFromLocation') is not null
  drop Procedure pr_RFC_RemoveSKUFromLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_RemoveSKUFromLocation:
    This Procedure is to remove SKU from location. There are two operations which use this procedure
    1. RemoveSKU - To remove SKUs with or without quantity
    2. RemoveSKUS - To remove SKUs with only zero quantity in static picklanes

    Operation 2 is mostly used by clients as there is a situation where static location
      is empty after a season and they would want to remove all SKUs associated with it.
      for this operation, from RF user has capability of selecting the SKU from the list provided.
      whereas, for first operation, the user is provided with no list and they just need to scan SKU
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_RemoveSKUFromLocation
  (@LocationId     TRecordId,
   @Location       TLocation,
   @LPNId          TRecordId,
   @SKUId          TRecordId,
   @SKU            TSKU,
   @InnerPacks     TInnerPacks, /* Future Use */
   @Quantity       TQuantity,
   @ReasonCode     TReasonCode = null,
   @Operation      TOperation = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vLPNId            TRecordId,
          @LPN               TLPN,
          @vLocationId       TRecordId,
          @vLocation         TLocation,
          @vSKUId            TRecordId,
          @vSKUStatus        TStatus,
          @vQuantity         TQuantity,

          @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,
          @vAuditActivity    TActivityType,
          @vActivityLogId    TRecordId;
begin
begin try
  SET NOCOUNT ON;

  select @SKUId         = nullif(@SKUId, 0);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, null,
                      @vLocationId, @Location, 'Location', @Value1 = @SKU,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Location Info */
  select @vLocation   = Location,
         @vLocationId = LocationId
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  /* Get SKU Info */
  if (@SKUId is not null)
    select @vSKUId     = SKUId,
           @vSKUStatus = Status
    from SKUs
    where (SKUId = @SKUId);
  else
    /* Get the latest SKU Info */
    /* Function may return multiple SKUs but select appropriate SKU that exists in the Location */
    select @vSKUId     = SS.SKUId,
           @vSKUStatus = SS.Status
    from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit) SS
      join LPNs L on (LPNId = @LPNId) and (L.SKUId = SS.SKUId);

  /* Get Quantity Info - Check the total qty */
  select @vLPNId    = min(LPNId),
         @vQuantity = sum(Quantity)
  from LPNDetails
  where (LPNId = @LPNId) and
        (SKUId = @vSKUId);

  /* Validations */
  if (@vLocationId is null)
    set @MessageName = 'LocationDoesNotExist';
  else
  if (@vSKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  /* If we have to skip this validation for any operation, then we need to exclude those operations, by default
     for any operation this check applies */
  if (@vQuantity > 0) --and (@Operation like 'RemoveSKU%')
    set @MessageName = 'SKURemove_InventoryExists_CannotRemove';
  else
  --if (@vSKUStatus = 'I' /* Inactive */)
  --  set @MessageName = 'SKUIsInactive';
  --else
  if (exists (select L.* from LPNs L
              where (L.LPNId = @LPNId) and
                    (L.SKUId = @vSKUId) and
                    (L.OnhandStatus in ('R', 'D', 'DR' /* Reserved, Directed, Directed Reserved */))))
    set @MessageName = 'LocationRemoveSKU_DirRes_Lines';

  if (@MessageName is not null)
    goto ErrorHandler;

  exec @Returncode = pr_Locations_RemoveSKUFromPicklane @vSKUId,
                                                        @vLocationId,
                                                        @LPNId,
                                                        @InnerPacks,
                                                        @Quantity,
                                                        @Operation,
                                                        @UserId,
                                                        @ReasonCode;

  select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU, SKU1,
         SKU2, SKU3, SKU4, SKU5, UOM, OnhandStatus, OnhandStatusDescription,
         InnerPacks, Quantity, UnitsPerPackage, ReceivedUnits, ShipmentId,
         LoadId, ASNCase, LocationId, Location, Barcode, OrderId, PickTicket,
         SalesOrder, OrderDetailId, OrderLine, ReceiptId, ReceiptNumber,
         ReceiptDetailId, ReceiptLine, Weight, Volume, Lot, LastPutawayDate,
         UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit
  from vwLPNDetails
  where (LocationId = @vLocationId) and (Quantity = 0);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End null, @@ProcId, @EntityId = @vLocationId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;

  /* Log the error result */
  exec pr_RFLog_End null, @@ProcId, @EntityId = @vLocationId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_RemoveSKUFromLocation */

Go
