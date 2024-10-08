/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/24  TK      pr_RFC_ValidateLPN: User should be able to adjust an empty LPN if the SKU is set up (S2GCA-302)
                      pr_RFC_ValidateLPN: Allow user to adjust picklane LPN as well, If it is a picklane then return all SKUs in that location (S2GCA-212)
  2018/03/09  OK      pr_RFC_ValidateLPN: Made changes to allow move Intransit LPNs (S2G-331)
  2017/10/10  TK      pr_RFC_ValidateLPN: Changes to return LPN.SKU and LPN.Quantity (HPI-1705)
  2017/04/10  TK      pr_RFC_TransferInventory & pr_RFC_ValidateLPN:
  2017/02/08  ??      pr_RFC_ValidateLPN: Modified where clause to get LPNStatus new as well (HPI-GoLive)
  2016/12/28  RV      pr_RFC_ValidateLPN: Do not show the unavailable line while Adjust LPN, except Received LPN (HPI-1222)
  2016/11/21  VM      pr_RFC_ValidateLPN: Do not allow adjust any replenish LPN (HPI-1069)
  2016/11/07  KL      pr_RFC_ValidateLPN: Validating LPN when scan the from LPN in transfer inventory functionality (HPI-1000)
                      pr_RFC_ValidateLPN: Enhanced to restrict the ReplenishLPN for TransferInventory(HPI Go- Live)
  2016/10/26  RV      pr_RFC_ValidateLPN: Allow any allocated LPN as well move to a new location (HPI-936)
  2016/05/18  AY      pr_RFC_ValidateLPN: Allow moving allocated LPNs if they have already been picked.
                      pr_RFC_ValidateLPN: Modified to return EnableUoM and DefualtUoM.
  2014/07/29  AK      pr_RFC_ValidateLPN: Set not to Adjust LPN quantity for Received Status.
  2014/05/16  PV      pr_RFC_ValidateLocation, pr_RFC_ValidateLPN: Enhanced to return reserved quantity and PickTicket number.
  2014/05/08  PKS     pr_RFC_ValidateLPN: Added DisplayDestination
  2014/05/05  PV      pr_RFC_ValidateLocation, pr_RFC_ValidateLPN: Enhanced to return DisplayQuantity.
  2014/04/28  PV      pr_RFC_ValidateLPN: Enhanced to validate FromLPN for transfer inventory operation.
  2014/04/17  PV      pr_RFC_ValidateLPN: Handled Divide By Zero Error.
  2014/04/11  TD      pr_RFC_ValidateLPN:Changes to pass default UoM.
  2014/02/28  PK      pr_RFC_AdjustLPN, pr_RFC_ValidateLPN: Added validations for not allowing to adjust allocated LPN/Line.
  2014/02/20  PK      pr_RFC_ValidateLPN: Included a validation for not allowing to transfer allocated LPN.
  2014/02/04  TD      pr_RFC_ValidateLPN: raise error when the user
  2013/12/12  TD      pr_RFC_ValidateLPN: Changes to validate the given LPN is allocated for
  2013/08/24  PK      pr_RFC_ValidateLPN: Added a Validation to not to add more than one SKU to LPN.
  2103/06/01  TD      pr_RFC_ValidateLPN: Allow users to movepallet for Cart Type where it is not on any pallet.
  2103/05/23  TD      pr_RFC_ValidateLPN, pr_RFC_ValidateLocation: Added UPC.
  2012/09/14  AY      pr_RFC_ValidateLPN: Limit operation on Logical/Cart LPNs
  2012/09/11  YA      pr_RFC_ValidateLPN: Restricting to move LPNs of with status Allocated, Picking.
  2012/08/24  AY      pr_RFC_ValidateLPN: Changed to give specific error messages
  2012/07/27  YA      pr_RFC_ValidateLPN: Allow adjust LPN in case quantity <> 0.
  2012/07/17  YA/AY   pr_RFC_ValidateLocation, pr_RFC_ValidateLPN: Added new param
                      pr_RFC_ValidateLPN: Return LPN details which are having inventory
                      pr_RFC_ValidateLPN: Modified for coding standards
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateLPN') is not null
  drop Procedure pr_RFC_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateLPN: Validate an LPN for a specific operation

  Assumption: LPN has only one SKU
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateLPN
  (@LPNId         TRecordId,
   @LPN           TLPN,
   @Operation     TDescription = null,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode                  TInteger,
          @MessageName                 TMessageName,
          @Message                     TDescription,
          @vMsgParam1                  TDescription,
          @vStatus                     TStatus,
          @vStatusDesc                 TDescription,
          @vLPNId                      TRecordId,
          @vLPNType                    TTypeCode,
          @vLPNSKUId                   TRecordId,
          @vLPNSKU                     TSKU,
          @vQuantity                   TQuantity,
          @vOrderType                  TTypeCode,
          @vLPNPalletId                TRecordId,
          @vLPNOnhandStatus            TStatus,
          @vLPNInvalidStatuses_Adjust  TStatus,
          @vLPNLocationId              TRecordId,
          @vLPNLocation                TLocation,
          @vLPNLocationType            TTypeCode,
          @vInvalidFromLPNStatuses     TControlValue,
          @vSKUCount                   TCount,
          @vAllowMultipleSKUs          TFlag,
          @vLPNInnerPacks              TQuantity,
          @vLPNReservedQty             TQuantity,
          @vLostLocation               TLocation,
          @vDefaultUoM                 TUoM,
          @vSKUUoM                     TUoM,
          @vEnableUoM                  TControlValue,
          @vUOMCSDescription           TDescription,
          @vUOMEADescription           TDescription,
          @vLPNPickingClass            TPickingClass;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vLPNId           = LPNId,
         @vStatus          = Status,
         @vStatusDesc      = StatusDescription,
         @vQuantity        = Quantity,
         @vLPNSKUId        = SKUId,
         @vLPNSKU          = SKU,
         @vLPNType         = LPNType,
         @vOrderType       = OrderType,
         @vLPNPalletId     = PalletId,
         @vLPNReservedQty  = ReservedQty,
         @vLPNLocationId   = LocationId,
         @vLPNLocation     = Location,
         @vLPNLocationType = LocationType,
         @vLPNOnhandStatus = OnhandStatus,
         @vLPNInnerPacks   = InnerPacks,
         @vSKUUoM          = UoM,
         @vLPNPickingClass = PickingClass
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, default /* Options */));

  /* Get the control value whether to allow multiple SKUs or not */
  select @vAllowMultipleSKUs         = dbo.fn_Controls_GetAsString('Inventory', 'AllowMultiSKULPNs', 'N' /* No */,
                                                                   @BusinessUnit, @UserId),
         @vLostLocation              = dbo.fn_Controls_GetAsString('ShortPick', 'MoveToLocation', 'LOST',
                                                                   @BusinessUnit, @UserId),
         @vLPNInvalidStatuses_Adjust = dbo.fn_Controls_GetAsString('LPN_Adjust', 'LPNInvalidStatus', 'TSCOV' /* In Transit , Shipped, Consumed, Lost, Voided */,
                                                                   @BusinessUnit, @UserId),
--         @vDefaultUoM                = dbo.fn_Controls_GetAsString('Inv_' + @Operation, 'DefaultUoM', null, @BusinessUnit, @UserId),
         @vEnableUoM                 = dbo.fn_Controls_GetAsString('Inv_' + @Operation, 'EnableUoM', 'N' /* No */,
                                                                   @BusinessUnit, @UserId),
         @vInvalidFromLPNStatuses    = dbo.fn_Controls_GetAsString('TransferInventory', 'InvalidFromLPNStatuses', 'CFISTOV' /* Consumed, New Temp, Inactive, Shipped, In Transit, Lost, Voided */,
                                                                   @BusinessUnit, @UserId);

  select @vSKUCount = count(distinct(SKUId))
  from LPNDetails
  where (LPNId = @vLPNId);

  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (@Operation = 'AdjustLPN') and (charindex(@vStatus , @vLPNInvalidStatuses_Adjust) <> 0)
    select @MessageName = 'LPNAdjust_InvalidStatus',
           @vMsgParam1  = @vStatusDesc;
  else
  if ((@Operation = 'AdjustLPN') and (@vLPNLocation = @vLostLocation))
    select @MessageName = 'LPNAdjust_CannotAdjustLOSTLPN';
  else
  if ((@Operation = 'AdjustLPN') and (@vStatus = 'A' /* Allocated */))
    select @MessageName = 'LPNAdjust_CannotAdjustAllocatedLPN';
  else
  /* Do not allow adjust any replenish LPN as its destination location DR line Qty mis-matches */
  if ((@Operation = 'AdjustLPN') and (@vOrderType in ('R', 'RU', 'RP' /* Replenish orders */)))
    select @MessageName = 'LPNAdjust_CannotAdjustReplenishLPN';
  else
  if (charindex(@vStatus , 'SCV' /* Shipped, Consumed, Voided */) <> 0)
    select @MessageName = 'LPNIsNotValidForAnyOperation',
           @vMsgParam1  = @vStatusDesc;
  else
  if (@vQuantity = 0) and (@Operation = 'MoveLPN')
    set @MessageName = 'LPNMove_EmptyLPN';
  else
  if (@Operation = 'MoveLPN') and (charindex(@vStatus, 'U' /* Picking */) <> 0)
    begin
      select @MessageName = 'LPNMove_InvalidStatus',
             @vMsgParam1  = @vStatusDesc;
    end
  else
  -- /* Allow move of allocated LPNs */
  -- if (@Operation = 'MoveLPN') and
  --    (coalesce(@vLPNReservedQty, 0) > 0) and
  --    (@vLPNLocationType in ('R', 'B' /* Reserve, Bulk */))
  --   set @MessageName = 'LPNMove_LPNIsAllocated';
  -- else
  if (@Operation = 'TransferInventory') and (@vStatus = 'A'/* Allocated */)
    set @MessageName = 'TransferInv_LPNIsAllocated';
  else
  if ((@Operation = 'TransferInventory') and
      (@vLPNOnhandStatus = 'U' /* Unavailable */) and
      (@vStatus not in ('N', 'R' /* New, Received */)))
    set @MessageName = 'TransferInv_FromLPNUnavailable';
  else
  if ((@Operation = 'TransferInventory') and (@vOrderType in ('RU', 'RP' /* ReplenishUnits, ReplenishCases */)))
    set @MessageName = 'ReplenishLPN_InValidOperation';
  else
  if (@Operation = 'TransferInventory') and
     (charindex(@vStatus, @vInvalidFromLPNStatuses) > 0)
    set @MessageName = 'TransferInv_LPNFromStatusIsInvalid';
  else
  /* User should be able to adjust an Picklane LPN if the SKU is set up even though Quantity is zero */
  if (@vSKUCount = 0) and (@vLPNType = 'L'/* Picklane */) and (@Operation = 'AdjustLPN')
    set @MessageName = 'LPNAdjust_EmptyLPN';
  else
  if (@vQuantity = 0) and (@vLPNType <> 'L'/* Picklane */) and (@Operation = 'AdjustLPN')
    set @MessageName = 'LPNAdjust_EmptyLPN';
  else
  /* For Adjust LPN user may scan Picklane location and he should be able to adjust picklane LPN */
  if (@vLPNType = 'L' /* Picklane */) and (@Operation <> 'AdjustLPN')
    set @MessageName = 'LogicalLPN_InvalidOperation';
  else
  if (@vLPNType = 'A' /* Cart */) and (@Operation = 'MoveLPN') and
     (@vLPNPalletId is not null)
    set @MessageName = 'CartLPN_InvalidOperation';
  else
  if ((@Operation = 'AddSKUToLPN') and (@vAllowMultipleSKUs = 'N') and (@vSKUCount >= 1))
    set @MessageName = 'MultiSKULPNsNotAllowed';

  if (@MessageName is not null)
     goto ErrorHandler;

  /* Default UoM is the UoM that will be shown to the RF user by default */
  select @vDefaultUoM = case
                          when (@vLPNInnerPacks > 0) then 'CS'
                          else coalesce(@vSKUUoM, 'EA')
                        end;

  /* Fetch the UOM descriptions */
  select @vUOMEADescription = dbo.fn_LookUps_GetDesc('UoM', coalesce(@vSKUUoM, 'EA'), @BusinessUnit, default),
         @vUOMCSDescription = dbo.fn_LookUps_GetDesc('UoM', 'CS', @BusinessUnit, default);

  /* If user has scanned a picklane LPN there are chances that the picklane may be a multi-SKU picklane
     so we need to display all SKUs in that location so that user can select SKU to be adjusted

     For example, let's say a picklane has two SKUs we will have two LPNs with same LPN number however LPNIds are different
        LPN1 with SKU1
        LPN1 with SKU2

     when User scans LPN1, we need to display both the SKUs in LPN1, so return all details from that picklane */
  /* Earlier we were using adjust location quantity to adjust zero quantity picklanes, now
     we have only one action to adjust location or LPN, so return details with zero qty as well */
  if (@vLPNType = 'L'/* Logical */) and (@Operation = 'AdjustLPN') and
     (exists(select * from vwLPNDetails where (LocationId = @vLPNLocationId)))
    select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU, UPC, SKU1,
           SKU2, SKU3, SKU4, SKU5, SKUDescription, UoM as UOM, OnhandStatus, OnhandStatusDescription,
           InnerPacks, Quantity, ReservedQuantity, UnitsPerPackage, ReceivedUnits, ShipmentId,
           LoadId, ASNCase, LocationId, Location, Barcode, OrderId, coalesce(PickTicket,'-') PickTicket/*This is to prevent RF crashing */,
           SalesOrder, OrderDetailId, OrderLine, DestZone, DestLocation,
           DisplayDestination,
           ReceiptId, ReceiptNumber,
           ReceiptDetailId, ReceiptLine, Weight, Volume, Lot,
           LastPutawayDate,UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, coalesce(@vDefaultUoM, DefaultUoM) DefaultUoM, @vEnableUoM EnableUoM,
           /* If LPN has InnerPacks, then show in Case/Units, else show in Qty and UoM */
           case when InnerPacks > 0 then convert(varchar(5),InnerPacks) + ' ' + @vUOMCSDescription + '/'+ convert(varchar(5),Quantity) + ' ' + @vUOMEADescription
                else convert(varchar(5),Quantity)    + ' ' + @vUOMEADescription
           end DisplayQuantity,
           /* Return LPN Qty and LPN SKU as well */
           coalesce(@vLPNSKU, 'Multiple SKUs') as LPNSKU, @vQuantity as LPNQuantity
     from vwLPNDetails
    where ((LocationId = @vLPNLocationId) and
          -- (Quantity > 0) and
           ((OnhandStatus <> 'U' /* Unavailable */) or (LPNStatus in ('T', 'R', 'N' /* InTransit, Received, New */))))
    order by SKU, LPNDetailId;
  else
  if (exists(select * from vwLPNDetails where (LPNId = @vLPNId) and (Quantity > 0)))
    select LPNId, LPN, LPNDetailId, LPNLine, LPNType, CoO, SKUId, SKU, UPC, SKU1,
           SKU2, SKU3, SKU4, SKU5, SKUDescription, UoM as UOM, OnhandStatus, OnhandStatusDescription,
           InnerPacks, Quantity, ReservedQuantity, UnitsPerPackage, ReceivedUnits, ShipmentId,
           LoadId, ASNCase, LocationId, Location, Barcode, OrderId, coalesce(PickTicket,'-') PickTicket/*This is to prevent RF crashing */,
           SalesOrder, OrderDetailId, OrderLine, DestZone, DestLocation,
           DisplayDestination,
           ReceiptId, ReceiptNumber,
           ReceiptDetailId, ReceiptLine, Weight, Volume, Lot,
           LastPutawayDate,UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit, coalesce(@vDefaultUoM, DefaultUoM) DefaultUoM, @vEnableUoM EnableUoM,
           /* If LPN has InnerPacks, then show in Case/Units, else show in Qty and UoM */
           case when InnerPacks > 0 then convert(varchar(5),InnerPacks) + ' ' + @vUOMCSDescription + '/'+ convert(varchar(5),Quantity) + ' ' + @vUOMEADescription
                else convert(varchar(5),Quantity)    + ' ' + @vUOMEADescription
           end DisplayQuantity,
           /* Return LPN Qty and LPN SKU as well */
           coalesce(@vLPNSKU, 'Multiple SKUs') as LPNSKU, @vQuantity as LPNQuantity
     from vwLPNDetails
    where ((LPNId = @vLPNId) and
           (Quantity > 0)    and
           ((OnhandStatus <> 'U' /* Unavailable */) or (LPNStatus in ('T', 'R', 'N' /* InTransit, Received, New */))))
    order by SKU, LPNDetailId;
  else
  if (@Operation = 'AddSKUToLPN')
    select @LPN as LPN, @vLPNLocation as Location, -1 as Quantity, @vDefaultUoM DefaultUoM, @vEnableUoM EnableUoM;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vMsgParam1;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidateLPN */

Go
