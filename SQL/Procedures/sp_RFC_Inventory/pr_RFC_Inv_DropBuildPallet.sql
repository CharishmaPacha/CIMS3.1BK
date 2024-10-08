/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/03  KSK     Added RFLogActivity for pr_RFC_Inv_AddLPNToPallet,pr_RFC_Inv_DropBuildPallet
  2017/05/29  SV      pr_RFC_Inv_DropBuildPallet: Bug fix to SetStatus over the Pallet if the build Pallet is dropped to same Location
  2016/11/04  OK      pr_RFC_Inv_DropBuildPallet: Enhanced to log the AT the built LPNs on Pallet drop
  2016/06/28  AY      pr_RFC_Inv_DropBuildPallet: Fixed NumLPN in Audit Trail (HPI-212)
  2015/05/05  OK      pr_RFC_AddSKUToLocation, pr_RFC_AdjustLocation, pr_RFC_ConfirmCreateLPN, pr_RFC_Inv_DropBuildPallet,
  2012/09/17  YA      pr_RFC_Inv_DropBuildPallet: Enforce dropping a pallet in to a picklane location and dropping an empty pallet to Reserve or Bulk locations.
  2012/08/31  VM      pr_RFC_Inv_DropBuildPallet: Bugfix - use coalesce as you might end up with null location for empty pallets
  2012/08/28  AY      pr_RFC_Inv_DropBuildPallet: Fixed issue of dropping pallet at same Location.
                      pr_RFC_Inv_DropBuildPallet, pr_RFC_Inv_MovePallet on 21-Feb-2012.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inv_DropBuildPallet') is not null
  drop Procedure pr_RFC_Inv_DropBuildPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inv_DropBuildPallet:
   output XML Structure of pr_RFC_Inv_DropBuildPallet

  <DROPPEDBUILDPALLETDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <DROPPEDBUILDPALLETINFO>
    <ErrorNumber>0</ErrorNumber>
    <ErrorMessage>DroppedPalletComplete</ErrorMessage>
   </DROPPEDBUILDPALLETINFO>
  </DROPPEDBUILDPALLETDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inv_DropBuildPallet
  (@Pallet       TPallet,
   @Location     TLocation,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @DeviceId     TDeviceId,
   @xmlResult    xml      output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vPalletId          TRecordId,
          @vPalletNumLPNs     TQuantity,
          @vNewLocationId     TRecordId,
          @vPalletLocationId  TRecordId,
          @vNewLocation       TLocation,
          @vNewLocationType   TLocationType,
          @vAuditRecordId     TRecordId,
          @vActivityLogId     TRecordId,

          @xmlResultvar       varchar(Max);

  declare @ttAuditEntities    TEntityKeysTable;

begin
begin try
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @vPalletId, @Pallet, 'Pallet', @Value1 = @Location,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  select @vPalletId         = PalletId,
         @vPalletLocationId = LocationId,
         @vPalletNumLPNs    = NumLPNs
  from Pallets
  where (Pallet       = @Pallet) and
        (BusinessUnit = @BusinessUnit);

  select @vNewLocationId   = LocationId,
         @vNewLocation     = Location,
         @vNewLocationType = LocationType
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Location, @DeviceId, @UserId, @BusinessUnit));

  /* Validations */
  if (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  if (@vNewLocationId is null)
    set @vMessageName = 'LocationDoesNotExist';
  else
  if (@vPalletNumLPNs = 0)
    set @vMessageName = 'DropPallet_EmptyPallet';

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@vNewLocationId <> coalesce(@vPalletLocationId, ''))
    begin
      /* If build pallet dropped at LPNs storage then All the LPNs will clear on Pallet after pr_Pallets_SetLocation call.
         So get the LPN details before that call */
      /* Get the LPNs on the Pallet to log AT on drop Pallet */
      insert into @ttAuditEntities (EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (PalletId = @vPalletId);

      /* Move Pallet to the dropped location */
      exec pr_Pallets_SetLocation @vPalletId, @vNewLocationId, 'Y' /* Yes - Update LPNs */, @BusinessUnit, @UserId;

      /* Audit Trail */
      exec pr_AuditTrail_Insert 'PalletDropped', @UserId, null /* ActivityTimestamp */,
                                @PalletId      = @vPalletId,
                                @NumLPNs       = @vPalletNumLPNs,
                                @LocationId    = @vNewLocationId,
                                @AuditRecordId = @vAuditRecordId output;

      /* Log AT on LPNs */
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttAuditEntities, @BusinessUnit;
    end

  /* Update Pallet status always */
  exec @vReturnCode = pr_Pallets_SetStatus @vPalletId, default, @UserId;

  if (@vReturnCode > 0)
    goto ErrorHandler;

  /* Get Confirmation Message */
  if (@vNewLocationId = @vPalletLocationId)
    set @vMessage = 'DropBuildPallet_AlreadyAtLocation';
  else
    set @vMessage = 'DropBuildPallet_Successful';

  /* XmlMessage to RF, after Pallet is Moved to a Location */
  exec pr_BuildRFSuccessXML @vMessage, @xmlResult output, @vNewLocation;

   /* Update Device details */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'DroppedPallet', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResultvar, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Inv_DropBuildPallet */

Go
