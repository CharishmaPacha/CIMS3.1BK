/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/26  RIA     pr_RFC_Inv_AddLPNToPallet: Added validation (HA-1245)
  2018/11/03  KSK     Added RFLogActivity for pr_RFC_Inv_AddLPNToPallet,pr_RFC_Inv_DropBuildPallet
  2015/07/18  AY      pr_RFC_Inv_AddLPNToPallet: Change Pallet type when adding LPN to empty Pallet (ACME-231.5)
  2015/05/25  DK      pr_RFC_Inv_AddLPNToPallet: Enahanced to show confirmation message based on controlvariable.
                      pr_RFC_Inv_AddLPNToPallet: Fix on audit message to show on LPNs previous location.
                      pr_RFC_Inv_AddLPNToPallet: Validate not to add Empty LPNs, and Audit message related changes to show message in previous pallet.
  2012/09/06  YA      pr_RFC_Inv_AddLPNToPallet: Users should be able to add staged LPNs to pallets. but not to pallets in Reserve/Bulk Locations.
              VM      pr_RFC_Inv_AddLPNToPallet: Do not allow to add LPNs to Pallet when they differ in their loads
  2012/07/23  PK      pr_RFC_Inv_AddLPNToPallet: Added a Validation for not allowing to add an LPN to
  2012/06/04  PK      pr_RFC_Inv_AddLPNToPallet: Validating LPNStatuses and Types while building Pallet.
                      Added procedures pr_RFC_Inv_ValidatePallet, pr_RFC_Inv_AddLPNToPallet,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inv_AddLPNToPallet') is not null
  drop Procedure pr_RFC_Inv_AddLPNToPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inv_AddLPNToPallet:
  output XML Structure of pr_RFC_Inv_AddLPNToPallet

  <PALLETDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <PALLETINFO>
    <Pallet>RF007</Pallet>
    <PalletId>302</PalletId>
    <LPN>047000000027</LPN>
    <LPNId>4</LPNId>
    <NumLPNs>7</NumLPNs>
    <Quantity>2</Quantity>
    <Location>E-001-1-0101</Location>
    <OrderId>123</OrderId>
    <PalletSKU>353275201010003</PalletSKU>
    <LPNSKU>353275201010004</LPNSKU>
    <ErrorNumber>0</ErrorNumber>
    <ErrorMessage>LPNADDEDSUCCESSFULLY</ErrorMessage>
  </PALLETINFO>
</PALLETDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inv_AddLPNToPallet
  (@Pallet       TPallet,
   @LPN          TLPN,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @DeviceId     TDeviceId,
   @xmlResult    xml       output)
as
  declare @ReturnCode              TInteger,
          @MessageName             TMessageName,
          @Message                 TDescription,
          @vActivityLogId          TRecordId,

          @vPalletId               TRecordId,
          @vPallet                 TPallet,
          @vNumLPNs                TCount,
          @vPalletQty              TInteger,
          @vPalletStatus           TStatus,
          @vPalletLocation         TLocation,
          @vPalletLocationType     TTypeCode,
          @vPalletSKUId            TRecordId,
          @vPalletSKU              TSKU,
          @vPalletType             TTypeCode,
          @vPalletOrderId          TRecordId,
          @vPalletLoadId           TLoadId,
          @vLPNLocationId          TRecordId,
          @vLocationId             TRecordId,
          @vDisplayLPNsQty         TDescription,
          @vPalletWarehouse        TWarehouse,

          @vLPNId                  TRecordId,
          @vLPN                    TLPN,
          @vLPNPalletId            TRecordId,
          @vLPNSKU                 TSKU,
          @vLPNSKUId               TRecordId,
          @vLPNStatus              TStatus,
          @vLPNType                TTypeCode,
          @vLPNQuantity            TQuantity,
          @vLPNLoadId              TLoadId,
          @vLPNWarehouse           TWarehouse,

          @xmlResultvar            TXML,
          @xmlPalletInfo           TXML,
          @xmlPalletLPNsInfo       XML,
          @vStatusControlCategory  TCategory,
          @vTypeControlCategory    TCategory,
          @vInValidLPNStatuses     TStatus,
          @vInValidLPNTypes        TTypeCode,
          @vShowConfirmationMsg    TFlag;
begin
begin try
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @vPalletId, @vPallet, 'Pallet', @Value1 = @LPN,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /*
     I) Validations:
     1. check all parameters are having data or not.
     2. Check Pallet is exist or not.
     3. Check LPN exist or not.
     4. Check whether pallet is in Built status or not.
     5. Check LPN status is either in Received or in Putaway status or not.
     Corresponding error message will be return if any point was failed.
  */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vLPNPalletId   = PalletId,
         @vLPNSKU        = SKU,
         @vLPNQuantity   = Quantity,
         @vLPNStatus     = Status,
         @vLPNType       = LPNType,
         @vLPNLoadId     = LoadId,
         @vLPNLocationId = LocationId,
         @vLPNWarehouse  = DestWarehouse
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@LPN, @BusinessUnit, default));

  select @vPalletId           = PalletId,
         @vPallet             = Pallet,
         @vPalletType         = PalletType,
         @vPalletStatus       = Status,
         @vNumLPNs            = NumLPNs,
         @vLocationId         = LocationId,
         @vPalletLocation     = Location,
         @vPalletLocationType = LocationType,
         @vPalletOrderId      = OrderId,
         @vPalletSKUId        = SKUId,
         @vPalletSKU          = SKU,
         @vPalletLoadId       = LoadId,
         @vPalletWarehouse    = Warehouse
  from vwPallets
  where (Pallet       = @Pallet) and
        (BusinessUnit = @BusinessUnit);

  select @vStatusControlCategory = 'BuildPallet_' + @vPalletType,
         @vTypeControlCategory   = 'BuildPallet_' + @vPalletType;

  /* Invalid LPN Status/Types */
  select @vInValidLPNStatuses  = dbo.fn_Controls_GetAsString(@vStatusControlCategory, 'InvalidLPNStatuses', 'SIHVC' /* S:Shipped, I:Inactive, H:ShortPicked, V:Voided, C:Consumed */, @BusinessUnit, @UserId),
         @vInValidLPNTypes     = dbo.fn_Controls_GetAsString(@vTypeControlCategory, 'InvalidLPNTypes', 'LAS' /* L:PickLane, A:Cart, S:ShippedCarton */, @BusinessUnit, @UserId),
         @vShowConfirmationMsg = dbo.fn_Controls_GetAsBoolean('BuildPallet', 'ShowConfirmationMessage', 'N' /* No */, @BusinessUnit, @UserId /* UserId */);

  if (@vPalletId is null)
    set @MessageName = 'PalletDoesNotExist';
  else
  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (charindex(@vLPNStatus , @vInvalidLPNStatuses) <> 0)
    set @MessageName = 'LPNStatusIsInvalid';
  else
  if (@vLPNQuantity = 0)
    set @MessageName = 'LPNIsEmpty';
  else
  if (@vLPNPalletId = @vPalletId)
    set @MessageName = 'LPNAlreadyOnPallet';
  else
  if (charindex(@vLPNType, @vInvalidLPNTypes) <> 0)
    set @MessageName = 'AddLPNToPallet_LPNTypeIsInvalid';
  else
  /* Users should be able to add staged LPNs to pallets. However, not to pallets in Reserve/Bulk Locations */
  if ((@vPalletLocationType in ('R' /* Reserve */, 'B' /* Bulk */)) and (@vLPNStatus in ('E' /* Staged */)))
    set @MessageName = 'InvalidLocationTypeForStagedLPNs';
  else
  if ((@vLPNLoadId > 0) or (@vPalletLoadId > 0)) and (@vPalletStatus <> 'E' /* Emtpy */) and
     (@vLPNLoadId <> @vPalletLoadId)
    set @MessageName = 'LPNSetPallet_LoadMismatch';
  else
  if ((@vPalletWarehouse is not null) and (@vPalletWarehouse <> @vLPNWarehouse))
    set @MessageName = 'AddLPNToPallet_WarehouseMismatch';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* If LPN is being added to an empty pallet and the LPN Status is in Picked, Packed, Staged, Loaded
     then change Pallet Type to be a Picking Pallet */
  if (@vPalletStatus = 'E' /* Empty */) and
     (charindex(@vLPNStatus, 'KDEL') <> 0)
    update Pallets
    set PalletType = 'P' /* Picking Pallet */
    where (PalletId = @vPalletId);

  /* Set Pallet on LPN and update old and new pallets */
  exec pr_LPNs_SetPallet @vLPNId, @vPalletId, @UserId;

  /* Get updated info */
  select @vNumLPNs        = NumLPNs,
         @vPalletQty      = Quantity,
         @vPalletSKUId    = SKUId,
         @vPalletSKU      = SKU
  from vwPallets
  where (PalletId = @vPalletId);

  select @vDisplayLPNsQty = coalesce(cast(@vNumLPNs as varchar), '') + coalesce('/'+ cast(@vPalletQty as varchar), ''),
         @Message = case
                     when (@vShowConfirmationMsg = 'Y' /* Yes */) then
                       dbo.fn_Messages_GetDescription('LPNAddedSuccessfully')
                    else
                     ''
                    end

  set @xmlPalletInfo =  (select @vPallet         as Pallet,
                                @vPalletId       as PalletId,
                                @vNumLPNs        as NumLPNs,
                                @vPalletQty      as PalletQty,
                                @vDisplayLPNsQty as DisplayLPNsQty,
                                @vPalletLocation as Location,
                                @vPalletOrderId  as OrderId,
                                @vPalletSKU      as PalletSKU,
                                @Message         as Message,
                                0                as ReturnCode
                           for XML raw('PALLETINFO'), elements );

  set @xmlPalletLPNsInfo = (select LPN      as LPN,
                                   LPNId    as LPNId,
                                   Quantity as Quantity,
                                   SKU      as LPNSKU
                            from vwLPNs
                            where (PalletId = @vPalletId)
                            for XML raw('LPNINFO'), type, elements xsinil, root('PALLETLPNDETAILS'));

  /* Build XML, The return dataset is used for RF to show Pallet info, Pallet Details in seperate nodes */
  set @xmlResult = (select '<PALLETDETAILS>' +
                               /* <PALLETINFO> */
                                  coalesce(@xmlPalletInfo, '') +
                               /* <PALLETLPNINFO> */
                                  coalesce(convert(varchar(max), @xmlPalletLPNsInfo), '') +
                           '</PALLETDETAILS>');

  /* Save Device State, Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'AddLPNToPallet', @xmlResultvar, @@ProcId;

  /* Audit Trail */
  select @vLPNSKUId  = SKUId
  from SKUs
  where SKU = @vLPNSKU;

  exec pr_AuditTrail_Insert 'LPNAddedToPallet', @UserId, null /* ActivityTimestamp */,
                            @LPNId        = @vLPNId,
                            @PalletId     = @vLPNPalletId,
                            @ToPalletId   = @vPalletId,
                            @LocationId   = @vLPNLocationId,
                            @ToLocationId = @vLocationId,
                            @SKUId        = @vLPNSKUId,
                            @Quantity     = @vLPNQuantity;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vLPN, @vPallet;

  /* Log the result */
  exec pr_RFLog_End @xmlResultvar, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  /* Calling this to handle error messages as we are getting mismatch of begin and commit */
  exec pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end  /* pr_RFC_Inv_AddLPNToPallet */

Go
