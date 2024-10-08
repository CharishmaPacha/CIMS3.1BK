/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/28  RT      pr_RFC_PA_ConfirmPutawayPallet, pr_RFC_PutawayLPNsGetNextLPN: Added Logs
  2015/05/05  OK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayByLocation,
                        pr_RFC_PA_ConfirmPutawayPallet: Made system compatable to accept either Location or Barcode.
  2012/09/13  VM      pr_RFC_PA_ConfirmPutawayPallet: InvalidLocationTypeToPutaway => PA_InFvalidLocationType
  2012/09/12  SP/VM   pr_RFC_PA_ConfirmPutawayPallet: Validated not to drop in conveyor location, added more restricted locations as well
  2012/08/28  AY      pr_RFC_PA_ConfirmPutawayPallet: Validate that NewLocation is not same
                        as old one and also fix issue with not showing units in message.
  2012/06/04  PK      pr_RFC_PA_ConfirmPutawayPallet: Generating Audit Records for Pallet LPNs as well.
  2012/03/16  PK      Added pr_RFC_PA_ValidatePutawayPallet, pr_RFC_PA_ConfirmPutawayPallet.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_PA_ConfirmPutawayPallet') is not null
  drop Procedure pr_RFC_PA_ConfirmPutawayPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_PA_ConfirmPutawayPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_PA_ConfirmPutawayPallet
  (@Pallet             TPallet,
   @PutawayLocation    TLocation,
   @ScannedLocation    TLocation,
   @PutawayZone        TLookUpCode,
   @PAInnerPacks       TInnerPacks, /* Future Use */
   @PAQuantity         TQuantity,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @DeviceId           TDeviceId,
   @xmlResult          xml       output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,
          @ConfirmMessage      TDescription,

          @vPalletId           TRecordId,
          @vPallet             TPallet,
          @vNumLPNs            TCount,
          @vPalletType         TTypeCode,
          @vPalletLocation     TLocation,
          @vPalletLocationId   TRecordId,
          @vPalletStatus       TStatus,
          @vQuantity           TQuantity,
          @vNumLPNsOnPallet    TCount,
          @vLocationId         TRecordId,
          @vScannedLocation    TLocation,
          @vLocationType       TLocationType,

          @xmlresultvar        varchar(max),
          @ttPalletLPNs        TEntityKeysTable,
          @vAuditRecordId      TRecordId,
          @vActivityLogId      TRecordId;

begin
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @Pallet, 'Pallet', @Value1 = @ScannedLocation,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get Pallet Info */
  select @vPalletId          = P.PalletId,
         @vPallet            = P.Pallet,
         @vNumLPNs           = P.NumLPNs,
         @vPalletType        = P.PalletType,
         @vPalletLocation    = L.Location,
         @vPalletStatus      = P.Status,
         @vQuantity          = P.Quantity,
         @vPalletLocationId  = P.LocationId
  from Pallets P left outer join Locations L on P.LocationId = L.LocationId
  where ((P.Pallet       = @Pallet      ) and
         (P.BusinessUnit = @BusinessUnit))

    /* Count the number of Cases and the number of cases used on the pallet/Carts
     are treated in the system as pallets and they have a number of LPNs
     on them, however, they may not be in use all the time, hence for that
     purpose we would need to check the number of empty cases on the pallet */
  select @vNumLPNsOnPallet = count(*)
  from LPNs
  where (PalletId = @vPalletId) and
        (Quantity > 0);

  select @vLocationId      = LocationId,
         @vScannedLocation = Location,
         @vLocationType    = LocationType
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @ScannedLocation, @DeviceId, @UserId, @BusinessUnit));

  /* Validations */
  /* Validations for Pallet as it is not validated by ConfirmPutawayLPN */

  if (@vPalletId is null)
    set @MessageName = 'PalletDoesNotExist';
  else
  if (@vNumLPNsOnPallet = 0) -- or (@vPalletStatus = 'E' /* Empty */)
    set @MessageName = 'PalletIsEmpty';
  else
  if (charindex(@vPalletStatus, '?') <> 0) /* Currently not enforced */
    set @MessageName = 'PalletStatusInvalid';
  else
  if (charindex(@vPalletType, 'RI' /* Receiving, Inventory */) = 0)
    set @MessageName = 'NotaPutawayPallet';
  else
  if (@vLocationId is null)
    set @MessageName = 'InvalidLocation';
  else
  if (@vLocationId = @vPalletLocationId)
    set @MessageName = 'PalletAlreadyAtLocation';
  else
  if (charindex(@vLocationType, 'CD' /* Conveyor, Dock */) <> 0)
    set @MessageName = 'PA_InvalidLocationType';

  if (@MessageName is not null)
     goto ErrorHandler;

  /* This procedure will Putaway the Cases on the Pallet  */
  exec @ReturnCode = pr_Putaway_ConfirmPutawayPallet @vPalletId,
                                                     @PutawayZone,
                                                     @PutawayLocation,
                                                     @vScannedLocation,
                                                     @PAInnerPacks,
                                                     @PAQuantity,
                                                     @BusinessUnit,
                                                     @UserId,
                                                     @DeviceId;

  /* If there is an exception in ConfirmPutawayPallet an exception is raised, so
     no additional error checking is required here, Catch block does
     what is needed */
  if (@ReturnCode = 0)
    begin
      insert into @ttPalletLPNs(EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (PalletId = @vPalletId);

      /* Auditing */
      exec pr_AuditTrail_Insert 'PutawayPallet', @UserId, null /* ActivityTimestamp */,
                                @PalletId      = @vPalletId,
                                @LocationId    = @vLocationId,
                                @Quantity      = @vQuantity,
                                @AuditRecordId = @vAuditRecordId output;

      /* Now insert all the LPNs on Pallet into Audit Entities i.e link above Audit Record
         to all the Putaway LPNs on the Pallet */
      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttPalletLPNs, @BusinessUnit;

      select @ConfirmMessage = Description
      from Messages
      where (MessageName = 'PutawayPalletComplete');

      set @xmlResult = (select 0                                                  as ErrorNumber,
                               coalesce(@ConfirmMessage, 'PutawayPalletComplete') as ErrorMessage
                       FOR XML RAW('PutawayPallet'), TYPE, ELEMENTS XSINIL, ROOT('PAPalletDetails'));

    end

  /* Update Device Current Operation Details, etc... */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ConfirmPutawayPallet', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vPalletId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_PA_ConfirmPutawayPallet */

Go
