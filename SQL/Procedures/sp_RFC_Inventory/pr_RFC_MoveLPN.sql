/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  TK      pr_RFC_MoveLPN & pr_RFC_Inv_MovePallet: Pass Order info to log AT (HA-3031)
  2020/04/15  RT      pr_RFC_MoveLPN: Validate when LPN is already on the same Pallet (HA-182)
  2019/02/19  AY      pr_RFC_MoveLPN: Changed param for fn_LPNs_AllowNewInventory to be LocationId
  2018/06/12  RV      pr_RFC_MoveLPN: Restricted to move inventory before close receiver based upon the control variable (S2GCA-25)
  2018/06/11  TK      pr_RFC_MoveLPN: Validate SKU attributes while moving LPNs (S2GCA-26)
  2016/12/18  AY      pr_RFC_MoveLPN: Bug fix in moving LPN onto a Pallet (HPI-GoLive)
                      pr_RFC_Inv_MovePallet, pr_RFC_MoveLPN, pr_RFC_RemoveSKUFromLocation, pr_RFC_TransferInventory,
  2012/11/21  NY      pr_RFC_MoveLPN:Added validation for LPN not to move to same Location.
                      pr_RFC_MoveLPN: Modified to show previous Pallet of the LPN moved.
  2012/05/31  AY      pr_RFC_MoveLPN: Enhance to move to Pallet as well, fixed bug
  2011/01/21  VM      pr_RFC_MoveLPN: Corrected sending param to pr_LPNs_Move (@LPNId => @vLPNId)
  2010/12/31  VM      pr_RFC_MoveLPN, pr_RFC_ConfirmCreateLPN:
  2010/12/31  VK      Made Status validations to pr_RFC_MoveLPN,pr_RFC_AdjustLPN
  2010/12/27  PK      'pr_RFC_MoveLPN' Issues Resolved:  By Fetching LocationId and Location by declaring temp variable
                      pr_RFC_MoveLPN: Corrected signature.
  2010/11/19  PK      Created pr_RFC_MoveLPN, pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_MoveLPN') is not null
  drop Procedure pr_RFC_MoveLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_MoveLPN: Move an LPN onto a Location or a Pallet.
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_MoveLPN
  (@LPNId          TRecordId,
   @LPN            TLPN,
   @NewLocationId  TRecordId,
   @NewLocation    TLocation,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,

          @vLPNId            TRecordId,
          @vLPNSKUId         TRecordId,
          @vLPNStatus        TStatus,
          @vLPNOrderId       TRecordId,
          @vOldLocationId    TRecordId,
          @vOldLocation      TLocation,
          @vNewLocationId    TRecordId,
          @vNewLocation      TLocation,
          @vNewLocationType  TTypeCode,

          @vOldPalletId      TRecordId,
          @vNewPalletId      TRecordId,
          @vNewPallet        TPallet,
          @vPalletLocationId TRecordId,

          @vAuditActivity    TActivityType;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vLPNId         = L.LPNId,
         @vLPNStatus     = L.Status,
         @vLPNSKUId      = L.SKUId,
         @vOldLocationId = coalesce(L.LocationId, -1), -- This is used for Audit Trail only.
         @vOldLocation   = Loc.Location,
         @vOldPalletId   = L.PalletId,
         @vLPNOrderId    = L.OrderId
  from LPNs L
    left outer join Locations Loc on (L.LocationId = Loc.LocationId)
  where (L.LPNId = dbo.fn_LPNs_GetScannedLPN (@LPN, @BusinessUnit, default));

  select @vNewLocationId   = LocationId,
         @vNewLocation     = Location,
         @vNewLocationType = LocationType,
         @vAuditActivity   = 'LPNMovedToLocation'
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@NewLocationId, @NewLocation, null /* DeviceId */, @UserId, @BusinessUnit));

  /* If user did not scan a location, check if it may be a pallet. */
  if (@vNewLocationId is null)
    select @vNewPalletId      = PalletId,
           @vNewPallet        = Pallet,
           @vPalletLocationId = LocationId,
           @vAuditActivity    = 'LPNMovedToPallet'
    from Pallets
    where (Pallet       = @NewLocation) and
          (BusinessUnit = @BusinessUnit);

  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vNewPalletId is null) and (@vNewLocationId is null)
    set @vMessageName = 'InvalidLocationorPallet';
  else
  if (@vNewLocation = coalesce(@vOldLocation, ''))
    set @vMessageName = 'LPNIsAlreadyInSameLocation';
  else
  if (@vNewPalletId = coalesce(@vOldPalletId, 0))
    set @vMessageName = 'LPNIsAlreadyOnSamePallet';
  else
  /* Validate SKUs operations if user is trying to move LPN to other than Staging/Dock locations */
  if (@vNewLocationType in ('B', 'R'/* Bulk, Reserve */)) and
     (@vLPNStatus in ('N', 'T', 'R'/* New, In-Transit, Received */))
    begin
      /* Single SKU LPN */
      if (@vLPNSKUId is not null)
        set @vMessageName = dbo.fn_SKUs_IsOperationAllowed(@vLPNSKUId, 'MoveLPN');
      else
        /* Multi-SKU LPN */
        select @vMessageName = min(dbo.fn_SKUs_IsOperationAllowed(SKUId, 'MoveLPN'))
        from LPNDetails
        where (LPNId = @vLPNId);
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If user scanned a valid Location, move LPN into the location */
  if (@vNewLocationId is not null)
    begin
      /* LPN is moved into Location directly, so clear the pallet */
      exec pr_LPNs_SetPallet @vLPNId, null /* Pallet Id */, @UserId;

      exec @vReturnCode = pr_LPNs_Move @vLPNId,
                                       @LPN,
                                       @vLPNStatus,
                                       @vNewLocationId,
                                       @vNewLocation,
                                       @BusinessUnit,
                                       @UserId;

    end
  else
    begin
      /* Update Pallet of LPN. If the Location of Pallet is different, then
         it updates the Location of the LPN to be that of the Pallet as well */
      exec @vReturnCode = pr_LPNs_SetPallet @vLPNId, @vNewPalletId, @UserId;
    end

  /* Audit Trail */
  if (@vReturnCode = 0)
    exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                              @LPNId        = @vLPNId,
                              @PalletId     = @vOldPalletId,
                              @LocationId   = @vOldLocationId,
                              @ToPalletId   = @vNewPalletId,
                              @ToLocationId = @vNewLocationId,
                              @OrderId      = @vLPNOrderId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_MoveLPN */

Go
