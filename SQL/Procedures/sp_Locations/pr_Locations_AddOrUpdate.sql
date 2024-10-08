/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/01  SJ      pr_Locations_AddOrUpdate : Made changes to CreateLocations for Entity Trail log window showing wrong user Id (HA-1402)
  2020/09/29  KBB     pr_Locations_AddOrUpdate : Added new validation for Creating the special characters (HA-1401)
  2020/05/14  SK      pr_Locations_AddOrUpdate: use fn_IsInList instead of charindex (HA-482)
  2018/01/10  OK      pr_Locations_AddOrUpdate: Bug fix to update the proper Location type for Static and Dynamic Locations (S2G-71, S2G-76)
  2018/01/09  OK      pr_Locations_AddOrUpdate, pr_Locations_Generate: Bug fixed to get the valid storage type for Static and dynamic picklanes (S2G-56)
  2017/10/29  PK      pr_Locations_AddOrUpdate: Added IsReplenishable field (HPI-1730).
  2016/03/01  AY      pr_Locations_AddOrUpdate: Clean up.
  2016/02/04  KL      pr_Locations_AddOrUpdate: Update the LocationSubType while creating new Location (NBD-125)
  2014/07/05  AK      pr_Locations_AddOrUpdate, pr_Locations_Generate: Set to show error for invalid storage type for reserve location.
                      pr_Locations_AddOrUpdate:Changes to validate Locationtype and LocationSubType while creating
  2013/10/30  PK      pr_Locations_AddOrUpdate: Fix for not creating Logical LPNs when creating Picklane Location,
  2013/09/02  TD      pr_Locations_AddOrUpdate:Added new param AllowMultipleKSUs.
  2013/05/24  PK      pr_Locations_AddOrUpdate, pr_Locations_AddSKUToPicklane: Passing Warehouse
  2011/02/23  VM      pr_Locations_Generate, pr_Locations_AddOrUpdate:
  2011/02/15  VM      pr_Locations_AddOrUpdate: Included PickingZone, PutawayZone.
  2011/02/03  VK      Added Warehouse field to pr_Locations_AddOrUpdate
  2011/01/21  VM      pr_Locations_Generate, pr_Locations_AddOrUpdate:
                      pr_Locations_AddOrUpdate: Create a Logical LPN on creating a Picklane and also set status to Putaway.
  2010/11/26  PK      Modified file added Error Handler in pr_Locations_AddOrUpdate,
  2010/10/18  SHR     pr_Locations_AddOrUpdate: Changed input and output parameters,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_AddOrUpdate') is not null
  drop Procedure pr_Locations_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_AddOrUpdate
  (@Location           TLocation,
   @LocationType       TLocationType,
   @LocationSubType    TLocationType,
   @StorageType        TStorageType,
   @Status             TStatus,
   @NumPallets         TCount,
   @NumLPNs            TCount,
   @InnerPacks         TInnerPacks,
   @Quantity           TQuantity,
   @Barcode            TBarcode,
   @PutawayPath        TLocationPath,
   @PickPath           TLocationPath,

   @PickingZone        TLookUpCode,
   @PutawayZone        TLookUpCode,

   @AllowMultipleSKUs  TFlag = 'N' /* No */,

   @BusinessUnit       TBusinessUnit,
   @Warehouse          TWarehouse,
   @UserId             TUserId,
   -----------------------------------------
   @LocationId         TRecordId output,
   @CreatedDate        TDateTime output,
   @ModifiedDate       TDateTime output,
   @CreatedBy          TUserId   output,
   @ModifiedBy         TUserId   output)

as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @Message            TDescription,

          @LPNId              TRecordId,
          @vLogicalLPNFormat  TControlValue,
          @vUserId            TUserId,
          @vActivityType      TActivityType,

          @vControlCategory   TCategory,
          @vValidStorageType  TControlValue,
          @vLocationType      TLocationType;

  declare @Inserted table (LocationId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode         = 0,
         @MessageName        = null,
         @vControlCategory   = 'Location_' + left(@LocationType, 1), -- For Static and Dynamic picklanes we are having two charectes for Location types.
         @vValidStorageType  = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStorageType', 'LA',
                                                           @BusinessUnit, null /* UserId */);

  /* Determine LocationType, SubType - Temporary mechanism */
  select @vLocationType    = substring(@LocationType, 1, 1);

  if (@Location is null)
    set @MessageName = 'LocationIsInvalid';
  else
  if (@LocationId is null) and
     (exists(select *
             from Locations
             where Location = @Location))
    set @MessageName = 'LocationAlreadyExists';  /* trying to add an existing Location */
  else
  if (@LocationType is null)
    set @MessageName = 'LocationTypeIsInvalid';
  else
  if (@StorageType is null)
    set @MessageName = 'StorageTypeIsInvalid';
  else
  if(@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';
  else
  if(@Warehouse is null)
    set @MessageName = 'WarehouseIsInvalid';
  else
  /* Should not allow to create a Picklane locations with Storage type other than "Units" */
  if ((@vLocationType = 'K' /* Picklane */) and (dbo.fn_IsInList(@StorageType, @vValidStorageType) = 0))
    set @MessageName = 'PicklaneStorageTypeIsInvalid';
  else
  /* Should not allow to create a Reserve locations with Storage type other than LPNs or Pallets & LPNs */
  if ((dbo.fn_IsInList(@StorageType, @vValidStorageType) = 0))
    set @MessageName = 'LocationTypeStorageTypeIsInvalid';
  else
  /* Validate if user entered any special characters on New locations*/
  if (@Location Like '%[^a-zA-Z0-9*-]%')
    set @MessageName = 'CreateLocations_SpecialCharsNotAllowed';

  /* If MessageName is not null then go to ErrorHandler */
  if (@MessageName is not null)
    goto ErrorHandler;

  /* if there are no errors then insert the location or Update it if it is already exists */
  if (not exists(select *
                 from Locations
                 where LocationId = @LocationId))
    begin
      select @vActivityType = 'CreateLocation';

      insert into Locations(Location,
                            LocationType,
                            LocationSubType,
                            StorageType,
                            Status,
                            NumPallets,
                            NumLPNs,
                            InnerPacks,
                            Quantity,
                            IsReplenishable,
                            Barcode,
                            Putawaypath,
                            PickPath,
                            PickingZone,
                            PutawayZone,
                            AllowMultipleSKUs,
                            BusinessUnit,
                            Warehouse,
                            CreatedBy)
                     output inserted.LocationId, inserted.CreatedDate, inserted.CreatedBy
                       into @Inserted
                     select @Location,
                            @vLocationType,
                            case
                              when @vLocationType = 'K' then
                                @LocationSubType
                              else
                                'D' /* Dynamic */
                            end,
                            @StorageType,
                            coalesce(@Status, 'E' /* Empty */),
                            coalesce(@NumPallets, 0),
                            coalesce(@NumLPNs, 0),
                            @InnerPacks,
                            @Quantity,
                            case
                              when @vLocationType = 'K' /* Picklane */ then
                                'Y' /* Yes */
                              when @LocationType = 'R' /* Reserve */ then
                                'N' /* No */
                              else
                                'N' /* No */
                            end,
                            coalesce(@Barcode, @Location),
                            coalesce(@PutawayPath, @Location),
                            coalesce(@PickPath, @Location),
                            @PickingZone,
                            @PutawayZone,
                            @AllowMultipleSKUs,
                            @BusinessUnit,
                            @Warehouse,
                            coalesce(@UserId, System_User);

       select @LocationId  = LocationId,
              @CreatedDate = CreatedDate,
              @CreatedBy   = CreatedBy
       from @Inserted;

       /* Logical LPNs are created when SKU is added to the Location */
    end
  else
    begin
      select @vActivityType = 'UpdateLocation';

      update Locations
      set
        LocationType      = coalesce(@LocationType, LocationType),
        --LocationSubType   = coalesce(@LocationSubType, LocationSubType),
        StorageType       = coalesce(@StorageType, StorageType),
        Status            = coalesce(@Status, Status),
        NumPallets        = coalesce(@NumPallets, NumPallets),
        NumLPNs           = coalesce(@NumLPNs, NumLPNs),
        InnerPacks        = coalesce(@InnerPacks, InnerPacks),
        Quantity          = coalesce(@Quantity, Quantity),
        Putawaypath       = coalesce(@PutawayPath, PutawayPath),
        PickPath          = coalesce(@PickPath, PickPath),
        PickingZone       = coalesce(@PickingZone, PickingZone),
        PutawayZone       = coalesce(@PutawayZone, PutawayZone),
        AllowMultipleSKUs = coalesce(@AllowMultipleSKUs, AllowMultipleSKUs),
        @ModifiedDate     = ModifiedDate = current_timestamp,
        @ModifiedBy       = ModifiedBy   = coalesce(@ModifiedBy, System_User)
      where (LocationId = @LocationId);
    end

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @CreatedBy, null /* ActivityTimestamp */,
                            @LocationId = @LocationId;

  exec @Message = dbo.fn_Messages_Build @vActivityType, @Location;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_AddOrUpdate */

Go
