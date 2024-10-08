/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/29  VS      pr_RFC_ValidatePutawayByLocation: Made changes to improve the Performance (S2GCA-1210)
  2016/11/02  AY      pr_RFC_ValidatePutawayByLocation: Allow PA to Pallets & LPNs location (HPI-GoLive)
  2016/10/28  AY      pr_RFC_ValidatePutawayByLocation: Allow Putaway by Location for all Staging Locs (HPI-GoLive)
  2016/10/26  ??      pr_RFC_ValidatePutawayByLocation: Modified check to consider LocationType (Location = '1GAINS-RET') as well (HPI-GoLive)
  2016/07/12  YJ      pr_RFC_ValidatePutawayByLocation: Restrict to allow putaway to Pallet storage type locations (HPI-196)
  2015/05/05  OK      pr_RFC_ConfirmPutawayLPN, pr_RFC_ValidatePutawayLPN, pr_RFC_ValidatePutawayByLocation,
                        pr_RFC_PA_ConfirmPutawayPallet: Made system compatable to accept either Location or Barcode.
  2011/10/08  PK      pr_RFC_ValidatePutawayByLocation: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidatePutawayByLocation') is not null
  drop Procedure pr_RFC_ValidatePutawayByLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidatePutawayByLocation:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidatePutawayByLocation
  (@LocationId    TRecordId,
   @Location      TLocation,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,
          @DeviceId         TDeviceId,
          @vStatus          TStatus,
          @vLocationId      TRecordId,
          @vLocation        TLocation,
          @vLocationType    TLocationType,
          @vStorageType     TTypeCode,
          @vActivityLogId   TRecordId,
          @NumLPNs          TCount;
begin
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @LocationId, @Location, 'Location',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  select @vLocationId   = LocationId,
         @vLocation     = Location,
         @vStatus       = Status,
         @vLocationType = LocationType,
         @vStorageType  = StorageType
  from  Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (@LocationId, @Location, null /* DeviceId */, @UserId, @BusinessUnit));

  if (@vLocationId is null)
    set @MessageName = 'LocationDoesNotExist';
  else
  if (@vStatus = 'I' /* InActive */)
    set @MessageName = 'LocationIsNotActive';
  else
  /* Confirm LPN Putaway (the next procedure that is called only handles L, U & P storage types,
     so give error here itself */
  if (@vStorageType in ('A', 'LA' /* Pallets, Pallets & LPNs */))
    set @MessageName = 'PAByLocation_InvalidStorageType';

  if (@MessageName is not null)
     goto ErrorHandler;

  select @NumLPNs = count(*)
  from LPNs
  where (LocationId = @vLocationId);

  select @vLocation as Location, @NumLPNs as LPNCount, @vLocationType as LocationType;

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

  /* Log the error */
  exec pr_RFLog_End null, @@ProcId, @EntityId = @vLocationId, @ActivityLogId = @vActivityLogId output;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidatePutawayByLocation */

Go
