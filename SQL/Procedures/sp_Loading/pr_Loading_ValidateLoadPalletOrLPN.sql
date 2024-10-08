/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/07  PHK     pr_Loading_ValidateLoadPalletOrLPN: Made changes to validate when adding Bulk orders to Load (HA-1941)
  2021/04/26  RIA     pr_Loading_ValidateLoadPalletOrLPN: Commented a validation temporarily (HA-2675)
  2021/04/20  AY      pr_Loading_ValidateLoadPalletOrLPN: Change to give valid error message on Loading of Pallets (HA Go Live)
  2021/02/16  AY      pr_Loading_ValidateLoadPalletOrLPN: Revised LPN validations (HA-2002)
  2020/07/21  RKC     pr_Loading_ValidateLoadPalletOrLPN1:Changes to Validate if add LPN to the Load when Load.FromWH is not matched with LPN.DestWH (HA-1073)
  2020/06/30  TK      pr_Loading_LoadPalletOrLPN & pr_Loading_ValidateLoadPalletOrLPN: Changes to load LPNs that are not associated to any order (HA-830)
  2020/01/21  TK      pr_Loading_LoadPalletOrLPN & pr_Loading_ValidateLoadPalletOrLPN: Initial Revision
                      pr_Shipping_GetLoadInfo renamed to pr_Loading_GetLoadInfo and migrated from sp_Shipping (S2GCA-970)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loading_ValidateLoadPalletOrLPN') is not null
  drop Procedure pr_Loading_ValidateLoadPalletOrLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loading_ValidateLoadPalletOrLPN: Validates the Pallet/LPN that is being loaded
------------------------------------------------------------------------------*/
Create Procedure pr_Loading_ValidateLoadPalletOrLPN
  (@LoadId               TRecordId,
   @PalletId             TRecordId,
   @LPNId                TRecordId,
   @DockLocation         TLocation,
   @Operation            TOperation,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId,
   @Message              TMessage = null   output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,

          @vLoadId               TRecordId,
          @vLoadNumber           TLoadNumber,
          @vLoadType             TTypeCode,
          @vLoadDockLocation     TLocation,
          @vLoadStatus           TStatus,
          @vLoadWarehouse        TWarehouse,
          @vLoadShipToId         TShipToId,
          @vAnotherLoadId        TRecordId,

          @vLPNId                TRecordId,
          @vLPN                  TLPN,
          @vLPNStatus            TStatus,
          @vLPNWarehouse         TWarehouse,
          @vLPNLoadId            TRecordId,
          @vLPNShipmentId        TRecordId,
          @vShipToId             TShipToId,

          @vPalletId             TRecordId,
          @vPallet               TPallet,
          @vPalletLoadId         TRecordId,
          @vPalletStatus         TStatus,
          @vPalletWarehouse      TWarehouse,
          @vNumLPNs              TCount,

          @vShipToCount          TCount,
          @vNumTempStatusLPNs    TCount,
          @vLPNShipToId          TShipToId,
          @vNote1                TDescription,
          @vOrderType            TTypeCode,

          @vValidLPNStatus       TControlValue,
          @vValidPalletStatus    TControlValue,
          @vFluidLoading         TControlValue,
          @vLoadingControlCategory
                                 TCategory;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  /* Get the Load Info */
  select @vLoadId             = LoadId,
         @vLoadNumber         = LoadNumber,
         @vLoadType           = LoadType,
         @vLoadDockLocation   = DockLocation,
         @vLoadStatus         = Status,
         @vLoadWarehouse      = FromWarehouse,
         @vLoadShipToId       = ShipToId
  from Loads
  where (LoadId = @LoadId);

  /* Build Loading Control Category */
  select @vLoadingControlCategory = case when (@vLoadType = 'Transfer' /* Contractor Transfer */)
                                         then 'Loading_' + @vLoadType
                                         else 'Loading'
                                    end

  /* Get the valid LPNs statuses */
  select @vValidLPNStatus    = dbo.fn_Controls_GetAsString(@vLoadingControlCategory, 'ValidLPNStatus', 'KDE'/* Picked, Packed, Staged */, @BusinessUnit, @UserId),
         @vValidPalletStatus = dbo.fn_Controls_GetAsString(@vLoadingControlCategory, 'ValidPalletStatus', 'SG,K,D'/* Staged, Picked, Packed */, @BusinessUnit, @UserId),
         @vFluidLoading      = dbo.fn_Controls_GetAsString('Loading', 'FluidLoading',      'N', @BusinessUnit, @UserId);

    /* Check whether the user scanned LPN or Pallet */
  if (@LPNId is not null)
    select @vLPNId         = LPNId,
           @vLPN           = LPN,
           @vLPNStatus     = Status,
           @vLPNWarehouse  = DestWarehouse,
           @vLPNLoadId     = LoadId,
           @vLPNShipmentId = ShipmentId
    from LPNs
    where (LPNId = @LPNId);
  else
  /* If LPN is null then assuming that User has scanned Pallet */
  if (@PalletId is not null)
    select @vPalletId         = PalletId,
           @vPallet           = Pallet,
           @vPalletStatus     = Status,
           @vPalletWarehouse  = Warehouse,
           @vNumLPNs          = NumLPNs,
           @vPalletLoadId     = LoadId
    from Pallets
    where (PalletId = @PalletId);

  /* Get the distinct ShipTo count */
  select @vShipToCount       = count(distinct(ShipToId)),
         @vLPNShipToId       = min(ShipToId),
         @vNumTempStatusLPNs = sum(case when LPNStatus = 'F' then 1 else 0 end)
  from #LPNsToLoad;

  /* Validations */
  if (@LoadId is null)
    select @vMessageName = 'InvalidLoad';
  else
  if (@vLoadStatus = 'S' /* Shipped */)
    select @vMessageName = 'LoadAlreadyShipped';
  else
  if (@vLoadStatus = 'X' /* Canceled */)
    select @vMessageName = 'LoadCancelled';
  else
  if (exists (select * from #LPNsToLoad where dbo.fn_IsInList(OrderType, 'B,R,RU,RP') <> 0))
    select @vMessageName = 'RFLoad_BulkOrderCannotBeLoaded';
  else
  if (@vLPN is null) and (@vPallet is null)
    set @vMessageName = 'InvalidLPNOrPallet';
  else
  if (@vLoadDockLocation <> @DockLocation) and (@Operation <> 'BuildLoad')
    select @vMessageName = 'RFLoad_ScannedDockLocationInvalid';
  else
  if (@vPallet is not null) and (@vPalletStatus = 'L' /* Loaded */)
    select @vMessageName = 'RFLoad_PalletAlreadyLoaded';
  else
  if (@vLPN is not null) and (@vLPNStatus = 'L' /* Loaded */)
    select @vMessageName = 'RFLoad_LPNAlreadyLoaded';
  else
  if (@vPallet is not null) and
     (dbo.fn_IsInList(@vPalletStatus, @vValidPalletStatus) = 0)
    select @vMessageName = 'RFLoad_InvalidPalletStatus',
           @vNote1       = dbo.fn_Status_GetDescription('Pallet', @vPalletStatus, @BusinessUnit)
  else
  if (exists (select * from #LPNsToLoad where dbo.fn_IsInList(LPNStatus, @vValidLPNStatus) = 0))
    select @vMessageName = 'RFLoad_InvalidLPNStatus';
  else
  if (@vNumLPNs = 0)
    select @vMessageName = 'RFLoad_EmptyPallet';
  else
  if (@vPallet is not null) and (@vPalletLoadId > 0) and (@vPalletLoadId <> @vLoadId)
    select @vMessageName = 'RFLoad_PalletOnDifferentLoad', @vAnotherLoadId = @vPalletLoadId;
  else
  if (@vLPN is not null) and (@vLPNLoadId > 0) and (@vLPNLoadId <> @vLoadId)
    select @vMessageName = 'RFLoad_LPNOnDifferentLoad', @vAnotherLoadId = @vLPNLoadId;
  else
  if (@vLPN is not null) and (@vLPNWarehouse <> @vLoadWarehouse)
    select @vMessageName = 'RFLoad_LPNWarehouseMismatch';
  else
  if (@vPallet is not null) and (@vPalletWarehouse <> @vLoadWarehouse)
    select @vMessageName = 'RFLoad_PalletWarehouseMismatch';
  else
  if (@vPallet is not null) and (@vPalletLoadId > 0) and (@vFluidLoading = 'Y')
    select @vMessageName   = 'PalletIsAlreadyOnALoad', @vAnotherLoadId = @vPalletLoadId;
  else
  if (@vLPNLoadId > 0) and (@vLPNShipmentId > 0) and (@vFluidLoading = 'Y')
    select @vMessageName = 'LPNIsAlreadyOnALoad', @vAnotherLoadId = @vLPNLoadId;
  else
  /* If user scanned pallet, then ensure all LPNs on it are for same ShipTo */
  if (@vPalletId is not null) and (@vShipToCount > 1) and (@vLoadType = 'SINGLEDROP')
    select @vMessageName = 'PalletHasMultipleShipTos';
  else
  if (coalesce(@vLPNShipToId, '') <> @vLoadShipToId) and (@vLoadShipToId <> 'Multiple') and (@vLoadType = 'SINGLEDROP')
    select @vMessageName = 'LoadForDifferentShipment';

ErrorHandler:
 /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    begin
      if (@vAnotherLoadId is not null)
        select @vNote1 = LoadNumber
        from Loads
        where (LoadId = @vAnotherLoadId);

      exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vNote1, @vLoadNumber;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loading_ValidateLoadPalletOrLPN */

Go
