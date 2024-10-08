/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/16  TK      pr_Locations_Action_Create & pr_Locations_Generate: Changes to initialize LocationArea with LocationType description (S2GCA-1645)
                      pr_Locations_GenerateLogicalLPN: Consider Lot for uniqueness (S2GCA-216)
  2018/08/22  VS      pr_Locations_Generate: New enhancement done for the Generate/View Locations (Modified changes as per AY suggestion) (S2GCA-13)
  2018/03/14  TK      pr_Locations_AddSKUToPicklane & pr_Locations_GenerateLogicalLPN: Changes to preprocess Logical LPN after adding SKU (S2G-367)
  2018/01/15  TD      pr_Locations_Generate:Changes to update AllowOperations field based on the LocationType(CIMS-1717)
  2018/01/09  OK      pr_Locations_AddOrUpdate, pr_Locations_Generate: Bug fixed to get the valid storage type for Static and dynamic picklanes (S2G-56)
  2017/12/04  TD      pr_Locations_Generate:Changes to update LocationClass  and maxlimits on locations while
  2016/10/31  AY      pr_Locations_GenerateLogicalLPN: By default setup picking class on Picklane as U (HPI-GoLive)
  2016/04/07  AY      pr_Locations_GenerateLogicalLPN: Preprocess the logical LPN to have picking class on it.
  2016/03/02  NY      pr_Locations_Generate: Setup pickpath and putaway path (SRI-446)
  2016/01/28  AY      pr_Locations_Generate: Allow multiple SKUs configured by Location Type
  2016/01/19  NY      pr_Locations_ChangeLocationStorageType,pr_Locations_Generate :
  2015/10/14  PK/SV   pr_Locations_Build, pr_Locations_Generate: Included Bay in the location format.
                      pr_Locations_GenerateLogicalLPN: Initial Revision
  2015/02/20  AK      pr_Locations_Generate: Set AllowMultipleSKUs based on a control var
  2014/07/05  AK      pr_Locations_AddOrUpdate, pr_Locations_Generate: Set to show error for invalid storage type for reserve location.
  2014/04/18  PKS     pr_Locations_Generate: AT logged on newly generated Locations.
                      pr_Locations_Generate:validating Case storage while location generation.
  2013/11/07  TD      pr_Locations_Generate:setting default value to Locationsubtype.
                      pr_Locations_Generate: Fix for passing in Location storage Type.
  2013/04/09  PKS     pr_Locations_Generate: Error message changed at validation of picklane locations.
  2013/03/27  AY      pr_Locations_Generate: Enhanced to create Static/Dynamic Picklanes
  2012/12/24  SP      pr_Locations_Generate: Retrieving LocationRow, LocationLevel.
  2012/11/06  YA      pr_Locations_Generate: Should not allow to create a Picklane locations with Storage type other than "Units".
  2012/07/25  PK      pr_Locations_Generate: Modify to update Locations with the Row, Level and Section
  2011/07/30  AY      pr_Locations_Generate: Handled a situation with creating
  2011/02/23  VM      pr_Locations_Generate, pr_Locations_AddOrUpdate:
  2011/02/08  VK      Added Warehouse field to pr_Locations_Generate.
  2011/01/27  VM      pr_Locations_Generate:
  2011/01/25  PK      pr_Locations_Generate : Changed to make display the decription instead of flag.
  2011/01/21  VM      pr_Locations_Generate, pr_Locations_AddOrUpdate:
  2011/01/18  VM      pr_Locations_Generate, pr_Locations_Build: Added.
                      pr_Locations_Generate: Generate Logical LPNs for Picklanes.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Generate') is not null
  drop Procedure pr_Locations_Generate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Generate:
    As the name is itself self explanatory, it is used to generate Locations
    based on the given format. It assumes that the caller passes a valid LocationType,
    LocationFormat. It also assumes that the caller passes appropriate parameters
    for Row, Section, Level, if they are used in LocationFormat (for example, if the caller
    wants to use Row, LocationFormat should contain in it some where like this <Row>).
    It assumes that the caller uses Row in LocationFormat, if starting value is passed
    for Row, ie @StartRow. Likewise for Section and Level. So the caller needs
    to validate those before calling this procedure.

    ** Currently we would like to use @RowCharSet as 'A' for 'Alphabets only' or
      'N' for 'Numerics only' and leave 'AN' - 'Alpha Numeric' for now. We can
      do that later enhancements. So the caller should take care of using either only
      alphabets or Numerics in @StartRow and @EndRow. Likewise for Section, Level.

    ** It inserts the Locations, which are not avaialble and
       it returns the created LPN's list and existing LPN's list within the specified range

  This procedure will have to be enhanced to accept LocationSubType - until then,
  we will pass in LocationType + LocationSubType in one variable LocationType and
  treat first char to be LocationType and second char to be LocationSubType.

  LocationClass and Max* fields.
    We will fill these Max* fields from selected location class. We will get these
    values from controls for the given location class and will update those.
    Generate option for the Generate Location and Preview for the View the  Location
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Generate
  (@BusinessUnit     TBusinessUnit,
   @Warehouse        TWarehouse,
   @UserId           TUserId,

   @LocationType     TLocationType,
   @StorageType      TStorageType,
   @LocationFormat   TControlValue,

   @LocationClass    TCategory  = null,
   @Operation        TOperation = 'Generate',

   /* Row */
   @StartRow         TRow     = null,
   @EndRow           TRow     = null,
   @RowIncrement     TRow     = '1',
   @RowCharSet       TCharSet = null, /* A - Alphabets only, N - Numerics only */

   /* Section */
   @StartSection     TSection = null,
   @EndSection       TSection = null,
   @SectionIncrement TSection = '1',
   @SectionCharSet   TCharSet = null, /* A - Alphabets only, N - Numerics only */

   /* Level */
   @StartLevel       TLevel   = null,
   @EndLevel         TLevel   = null,
   @LevelIncrement   TLevel   = '1',
   @LevelCharSet     TCharSet = null,

   /* Bay */
   @StartBay         TBay     = null,
   @EndBay           TBay     = null,
   @BayIncrement     TBay     = '1',
   @BayCharSet       TCharSet = null) /* A - Alphabets only, N - Numerics only */
as
  declare @ttLocations Table
    (RecordId          TRecordId,
     LocationId        TRecordId,
     Location          TLocation,
     LocationRow       TRow,
     LocationBay       TBay,
     LocationLevel     TLevel,
     LocationSection   TSection,
     LocationExists    TFlag);

  declare @ttAuditLocations    TEntityKeysTable,
          @vControlCategory    TCategory,
          @vLocClassCategory   TCategory;

  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vAuditRecordId      TRecordId,
          @vLocationId         TRecordId,
          @vLocation           TLocation,
          @vLocationType       TLocationType,
          @vLocationSubType    TTypeCode,
          @vLPNId              TRecordId,
          @vValidStorageType   TControlValue,
          @vAllowMultipleSKUs  TControlValue,
          @vAllowedOperations  TControlValue,

          @vMaxPallets         TCount,
          @vMaxLPNs            TCount,
          @vMaxInnerPacks      TCount,
          @vMaxUnits           TCount,
          @vMaxWeight          TWeight,
          @vMaxVolume          TVolume;

          --@vLogicalLPNFormat  TControlValue;
begin
  SET NOCOUNT ON;

  select @ReturnCode         = 0,
         @MessageName        = null,
         @vControlCategory   = 'Location_' + left(@LocationType, 1),  -- For Static and Dynamic picklanes we are having two characters for Location types.
         @vLocClassCategory  = 'LocationClass_' + coalesce(@LocationClass, ''),
         @vValidStorageType  = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStorageType', 'LA',
                                                           @BusinessUnit, null /* UserId */),
         @vAllowMultipleSKUs = dbo.fn_Controls_GetAsString(@vControlCategory, 'AllowMultipleSKUs', 'Y' /* Yes */,
                                                           @BusinessUnit, null /* UserId */),
         @vAllowedOperations = dbo.fn_Controls_GetAsString(@vControlCategory, 'AllowedOperations', 'N' /* None */,
                                                           @BusinessUnit, null /* UserId */),
         @vMaxPallets        = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxPallets', 99,
                                                            @BusinessUnit, null /* UserId */),
         @vMaxLPNs           = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxLPNs', 99,
                                                            @BusinessUnit, null /* UserId */),
         @vMaxInnerPacks     = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxInnerPacks', 99,
                                                            @BusinessUnit, null /* UserId */),
         @vMaxUnits          = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxUnits', 9999,
                                                            @BusinessUnit, null /* UserId */),
         @vMaxVolume         = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxVolume', 999,
                                                            @BusinessUnit, null /* UserId */),
         @vMaxWeight         = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxWeight', 999,
                                                            @BusinessUnit, null /* UserId */);

  /* Determine LocationType, SubType - Temporary mechanism */
  select @vLocationType    = substring(@LocationType, 1, 1),
         @vLocationSubType = nullif(substring(@LocationType, 2, 1), '');

  /* Should not allow to create a Picklane locations with Storage type other than Cases or Units */
  if ((@vLocationType = 'K'/* Picklane */) and (charindex(@StorageType, @vValidStorageType) = 0))
    set @MessageName = 'PicklaneStorageTypeIsInvalid';
  else
  /* Should not allow to create a Reserve locations with Storage type other than LPNs or Pallets & LPNs */
  if (charindex(@StorageType, @vValidStorageType) = 0)
    set @MessageName = 'LocationTypeStorageTypeIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* If Sublocation type is not specified then default it based on control var */
  if (@vLocationSubType is null)
    set @vLocationSubType = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultSubType', 'D',
                                                        @BusinessUnit, @UserId);

  insert into @ttLocations (RecordId, Location, LocationRow, LocationLevel, LocationSection, LocationBay, LocationExists)
    exec pr_Locations_Build @BusinessUnit,
                            @Warehouse,
                            @UserId,

                            @vLocationType,
                            @LocationFormat,

                            /* Row */
                            @StartRow,
                            @EndRow,
                            @RowIncrement,
                            @RowCharSet,

                            /* Section */
                            @StartSection,
                            @EndSection,
                            @SectionIncrement,
                            @SectionCharSet,

                            /* Level */
                            @StartLevel,
                            @EndLevel,
                            @LevelIncrement,
                            @LevelCharSet,

                            /* Bay */
                            @StartBay,
                            @EndBay,
                            @BayIncrement,
                            @BayCharSet;

  /* If you want to Generate location */
  if (@Operation = 'Generate')
    begin
      insert into Locations (Location, LocationType, LocationSubType, StorageType, Barcode,
                             LocationRow, LocationLevel, LocationSection, LocationBay, LocationClass,
                             MaxPallets, MaxLPNs, MaxInnerPacks, MaxUnits, MaxVolume, MaxWeight,
                             PutawayPath, PickPath, AllowMultipleSKUs, AllowedOperations,
                             BusinessUnit, Warehouse, CreatedBy)
      select Location, @vLocationType, @vLocationSubType, @StorageType, Location,
             LocationRow, LocationLevel, LocationSection, LocationBay, @LocationClass,
             @vMaxPallets, @vMaxLPNs, @vMaxInnerPacks, @vMaxUnits, @vMaxVolume, @vMaxWeight,
             Location, Location, @vAllowMultipleSKUs, @vAllowedOperations,
             @BusinessUnit, @Warehouse, @UserId
      from @ttLocations
      where (LocationExists = 'N' /* No */);

      update ttLoc
      set LocationId = L.LocationId
      from @ttLocations ttLoc
        join Locations L on (L.Location = ttLoc.Location);

      /* Set PickPath, Putaway path on location */
      update L
      set PickPath    = coalesce(dbo.fn_Locations_GetPath(L.Location, null, 'PickPath', @BusinessUnit, @Userid), L.Location),
          PutawayPath = coalesce(dbo.fn_Locations_GetPath(L.Location, null, 'PutawayPath', @BusinessUnit, @Userid), L.Location)
      from Locations L
        join @ttLocations ttLoc on (L.Location = ttLoc.Location);

      /* Logging AT for newly generated Locations. */
      insert into @ttAuditLocations(EntityId, EntityKey)
        select ttLoc.LocationId, ttLoc.Location
        from @ttLocations ttLoc
        where (ttLoc.LocationExists = 'N');

      /* Logging AuditTrail for newly created Locations */
      exec pr_AuditTrail_Insert 'GenerateLocation',
                                 @UserId,
                                 null /* ActivityTimestamp */,
                                 null /* DeviceId */,
                                 @BusinessUnit,
                                 @AuditRecordId = @vAuditRecordId output;

      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttAuditLocations, @BusinessUnit;

    end

  select Location, LocationRow, LocationLevel,
         case LocationExists
           when 'N' then
             case when @Operation = 'Generate' then
               'Created' /* When it is "Generate" mode it shows "Created" */
             else
               'Location does not exist' /* When it is "Preview" mode it shows "Location Does not exist" */
             end
           else
             'Location already exists'
         end as LocationExists
  from @ttLocations;

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_Generate */

Go
