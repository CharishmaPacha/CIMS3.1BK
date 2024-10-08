/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/29  PK      pr_Imports_Locations: Bug fix to update 0 in Min/Max replenishment levels.(HPI-1798)
  2017/10/27  YJ      Migrated from Onsite Prod: pr_Imports_Locations: Updating LocationSubType (HPI-1558)
                      pr_Imports_Locations: clean up of document handle creation and removal code. this is now handled in ImportRecord
  2017/05/12  OK      pr_Imports_Locations, pr_Imports_ValidateLocations: Added for Location imports
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_Locations') is not null
  drop Procedure pr_Imports_Locations;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_Locations:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_Locations
  (@xmlData              Xml             = null,
   @documentHandle       TInteger        = null,
   @InterfaceLogId       TRecordId       = null,
   @Action               TFlag           = null,
   @Location             TLocation       = null,
   @LocationType         TLocationType   = null,
   @LocationSubType      TTypeCode       = null,
   @StorageType          TStorageType    = null,
   @LocationRow          TRow            = null,
   @LocationBay          TBay            = null,
   @LocationLevel        TLevel          = null,
   @LocationSection      TSection        = null,
   @LocationClass        TCategory       = null,
   @MinReplenishLevel    TQuantity       = null,
   @MaxReplenishLevel    TQuantity       = null,
   @ReplenishUoM         TUoM            = null,
   @SKU                  TSKU            = null,
   @AllowMultipleSKUs    TFlag           = null,
   @Barcode              TBarcode        = null,
   @PutawayPath          TLocationPath   = null,
   @PickPath             TLocationPath   = null,
   @PickingZone          TLookUpCode     = null,
   @PutawayZone          TLookUpCode     = null,
   @Ownership            TOwnership      = null,
   @UDF1                 TUDF            = null,
   @UDF2                 TUDF            = null,
   @UDF3                 TUDF            = null,
   @UDF4                 TUDF            = null,
   @UDF5                 TUDF            = null,
   @BusinessUnit         TBusinessUnit   = null,
   @Warehouse            TWarehouse      = null,
   @CreatedBy            TUserId         = null)

as
  declare @vReturnCode              TInteger,

          /* Table variables for CartonTypes, CartonType Validations and AuditTrail */
          @ttLocationImports        TLocationImportType,
          @ttLocationsValidation    TImportValidationType,
          @ttAuditInfo              TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]',  'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Populate the temp table */
  if (@documentHandle is not null)
    begin
      insert into @ttLocationImports (
        InputXML,
        RecordType,
        RecordAction,
        Location,
        LocationType,
        LocationSubType,
        StorageType,
        LocationRow,
        LocationBay,
        LocationLevel,
        LocationSection,
        LocationClass,
        MinReplenishLevel,
        MaxReplenishLevel,
        ReplenishUoM,
        SKU,
        AllowMultipleSKUs,
        Barcode,
        PutawayPath,
        PickPath,
        PickingZone,
        PutawayZone,
        Ownership,
        LOC_UDF1,
        LOC_UDF2,
        LOC_UDF3,
        LOC_UDF4,
        LOC_UDF5,
        BusinessUnit,
        Warehouse,
        CreatedBy)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="LOC"]', 2) -- condition forces to read only Records with RecordType LOC
      with (InputXML              nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType            TRecordType,
            Action                TFlag      'Action',
            Location              TLocation,
            LocationType          TLocationType,
            LocationSubType       TTypeCode,
            StorageType           TStorageType,
            LocationRow           TRow,
            LocationBay           TBay,
            LocationLevel         TLevel,
            LocationSection       TSection,
            LocationClass         TCategory,
            MinReplenishLevel     TQuantity,
            MaxReplenishLevel     TQuantity,
            ReplenishUoM          TUoM,
            SKU                   TSKU,
            AllowMultipleSKUs     TFlag,
            Barcode               TBarcode,
            PutawayPath           TLocationPath,
            PickPath              TLocationPath,
            PickingZone           TLookUpCode,
            PutawayZone           TLookUpCode,
            Ownership             TOwnership,
            LOC_UDF1              TUDF,
            LOC_UDF2              TUDF,
            LOC_UDF3              TUDF,
            LOC_UDF4              TUDF,
            LOC_UDF5              TUDF,
            BusinessUnit          TBusinessUnit,
            Warehouse             TWarehouse,
            CreatedBy             TUserId);
    end
  else
    begin
      insert into @ttLocationImports (
        RecordAction, Location, LocationType, LocationSubType, StorageType,
        LocationRow, LocationBay, LocationLevel, LocationSection, LocationClass,
        MinReplenishLevel, MaxReplenishLevel, ReplenishUoM, SKU, AllowMultipleSKUs,
        Barcode, PutawayPath, PickPath, PickingZone, PutawayZone, Ownership,
        LOC_UDF1, LOC_UDF2, LOC_UDF3, LOC_UDF4, LOC_UDF5, BusinessUnit, Warehouse, CreatedBy)
      select
        @Action, @Location, @LocationType, @LocationSubType, @StorageType,
        @LocationRow, @LocationBay, @LocationLevel, @LocationSection, @LocationClass,
        @MinReplenishLevel, @MaxReplenishLevel, @ReplenishUoM, @SKU, @AllowMultipleSKUs,
        @Barcode, @PutawayPath, @PickPath, @PickingZone, @PutawayZone, @Ownership,
        @UDF1, @UDF2, @UDF3, @UDF4, @UDF5, @BusinessUnit, @Warehouse, @CreatedBy;
    end

  /* Update with LocationId of Locations */
  update ttL
  set ttL.LocationId = LOC.LocationId,
      ttl.Status     = LOC.Status
  from @ttLocationImports ttL
    join Locations LOC on (LOC.Location = ttL.Location);

  /* Validating the Locations */
  insert @ttLocationsValidation
    exec pr_Imports_ValidateLocations @ttLocationImports;

  /* Set RecordAction for Location Records  */
  update ttL
  set ttL.RecordAction = LV.RecordAction
  from @ttLocationImports ttL
    join @ttLocationsValidation LV on (LV.RecordId = ttL.RecordId);

  /* Insert update or Delete based on Action */
  if (exists(select * from @ttLocationImports where (RecordAction = 'I' /* Insert */)))
    insert into Locations (
      Location,
      LocationType,
      LocationSubType,
      StorageType,
      LocationRow,
      LocationBay,
      LocationLevel,
      LocationSection,
      LocationClass,
      MinReplenishLevel,
      MaxReplenishLevel,
      ReplenishUoM,
      AllowMultipleSKUs,
      Barcode,
      PutawayPath,
      PickPath,
      PickingZone,
      PutawayZone,
      Ownership,
      LOC_UDF1,
      LOC_UDF2,
      LOC_UDF3,
      LOC_UDF4,
      LOC_UDF5,
      BusinessUnit,
      Warehouse,
      CreatedDate,
      CreatedBy)
    select
      Location,
      LocationType,
      LocationSubType,
      StorageType,
      LocationRow,
      LocationBay,
      LocationLevel,
      LocationSection,
      LocationClass,
      MinReplenishLevel,
      MaxReplenishLevel,
      ReplenishUoM,
      AllowMultipleSKUs,
      Barcode,
      PutawayPath,
      PickPath,
      PickingZone,
      PutawayZone,
      Ownership,
      LOC_UDF1,
      LOC_UDF2,
      LOC_UDF3,
      LOC_UDF4,
      LOC_UDF5,
      BusinessUnit,
      Warehouse,
      coalesce(CreatedDate, current_timestamp),
      coalesce(CreatedBy, System_User)
    from @ttLocationImports
    where ( RecordAction = 'I' /* Insert */);

  if (exists(select * from @ttLocationImports where (RecordAction = 'U' /* Update */)))
    update L1
    set L1.LocationType         = coalesce(nullif(L2.LocationType,      ''), L1.LocationType),
        L1.LocationSubType      = coalesce(nullif(L2.LocationSubType,   ''), L1.LocationSubType),
        L1.StorageType          = coalesce(nullif(L2.StorageType,       ''), L1.StorageType),
        L1.LocationRow          = coalesce(nullif(L2.LocationRow,       ''), L1.LocationRow),
        L1.LocationBay          = coalesce(nullif(L2.LocationBay,       ''), L1.LocationBay),
        L1.LocationLevel        = coalesce(nullif(L2.LocationLevel,     ''), L1.LocationLevel),
        L1.LocationSection      = coalesce(nullif(L2.LocationSection,   ''), L1.LocationSection),
        L1.LocationClass        = coalesce(nullif(L2.LocationClass,     ''), L1.LocationClass),
        L1.MinReplenishLevel    = coalesce(nullif(cast(L2.MinReplenishLevel as varchar(max)), ''), L1.MinReplenishLevel),
        L1.MaxReplenishLevel    = coalesce(nullif(cast(L2.MaxReplenishLevel as varchar(max)), ''), L1.MaxReplenishLevel),
        L1.ReplenishUoM         = coalesce(nullif(L2.ReplenishUoM,      ''), L1.ReplenishUoM),
        L1.AllowMultipleSKUs    = coalesce(nullif(L2.AllowMultipleSKUs, ''), L1.AllowMultipleSKUs),
        L1.Barcode              = coalesce(nullif(L2.Barcode,           ''), L1.Barcode),
        L1.PutawayPath          = coalesce(nullif(L2.PutawayPath,       ''), L1.PutawayPath),
        L1.PickPath             = coalesce(nullif(L2.PickPath,          ''), L1.PickPath),
        L1.PickingZone          = coalesce(nullif(L2.PickingZone,       ''), L1.PickingZone),
        L1.PutawayZone          = coalesce(nullif(L2.PutawayZone,       ''), L1.PutawayZone),
        L1.Ownership            = coalesce(nullif(L2.Ownership,         ''), L1.Ownership),
        L1.LOC_UDF1             = coalesce(nullif(L2.LOC_UDF1,          ''), L1.LOC_UDF1),
        L1.LOC_UDF2             = coalesce(nullif(L2.LOC_UDF2,          ''), L1.LOC_UDF2),
        L1.LOC_UDF3             = coalesce(nullif(L2.LOC_UDF3,          ''), L1.LOC_UDF3),
        L1.LOC_UDF4             = coalesce(nullif(L2.LOC_UDF4,          ''), L1.LOC_UDF4),
        L1.LOC_UDF5             = coalesce(nullif(L2.LOC_UDF5,          ''), L1.LOC_UDF5),
        L1.BusinessUnit         = coalesce(L2.BusinessUnit,                  L1.BusinessUnit),
        L1.Warehouse            = coalesce(nullif(L2.Warehouse,         ''), L1.Warehouse),
        L1.ModifiedDate         = coalesce(nullif(L2.ModifiedDate,      ''), current_timestamp),
        L1.ModifiedBy           = coalesce(nullif(L2.ModifiedBy,        ''), System_User)
    /* output to audit info */
    output 'Location', Inserted.LocationId, L2.Location, null, 'AT_LocationModified' /* Audit Activity */, L2.RecordAction /* Action */,
           null /* Comment */, Inserted.BusinessUnit, Inserted.ModifiedBy, null, null, null, null, null,
           null /* Audit Id */ into @ttAuditInfo
    from Locations L1
      join @ttLocationImports L2 on (L1.Location     = L2.Location) and
                                    (L1.BusinessUnit = L2.BusinessUnit)
    where (L2.RecordAction = 'U' /* Update */);

  /* process deletes by just marking them as inactive */
  if (exists(select * from @ttLocationImports where (RecordAction = 'D' /* Delete */)))
    begin
      /* Capture audit info */
      insert into @ttAuditInfo (EntityType, EntityKey, ActivityType, Action, BusinessUnit, UserId)
        select 'Location', Location, 'LocationDeleted', RecordAction, BusinessUnit, ModifiedBy
        from @ttLocationImports
        where (RecordAction = 'D');

      update L1
      set L1.Status = 'I' /* Inactive */
      from Locations L1
        join @ttLocationImports L2 on (L1.Location = L2.Location)
      where (L2.RecordAction = 'D');
    end

  /* Verify if Audit Trail should be updated */
  if (exists(select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update @ttAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'Location', EntityKey /* Location */, null, null, null, null, null, null, null, null, null, null);

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttLocationsValidation;

end /* pr_Imports_Locations */

Go

/*------------------------------------------------------------------------------
  Proc pr_Imports_LogError: Logs the description of the given error into the
    Errors temp table.
------------------------------------------------------------------------------*/
