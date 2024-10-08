/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2020/05/12  TK      Added default drop locations for all wave types (HA-503)
  2020/05/06  AY      Setup default locations (HA-227)
  2019/06/03  VS      Created Pause and Hold Locations (CID-468)
  2019/04/09  VS      Created VAS Drop Locations (CID-206)
  2019/03/26  VS      Created Drop Locations (CID-220)
  2015/04/20  AY      Changed to create sample/test Locations for any client
  2014/06/16  NY      Initial Revision
------------------------------------------------------------------------------*/

Go

/* This script in CIMS which is copied to several projects will be used to create
   few sample locations for the install. It may later be enhanced to create the
   exact locations that are needed for the particular installation.
*/

declare @BusinessUnit TBusinessUnit;
declare @Warehouse    TWarehouse;
declare @UserId       TUserId;

/* Most implementations have only one BU, so get the first one and use it */
select top 1 @BusinessUnit = BusinessUnit
from vwBusinessUnits
order by SortSeq;

select top 1 @Warehouse = LookupCode
from vwLookUps
where (LookupCategory = 'Warehouse')
order by SortSeq;

/*------------------------------------------------------------------------------
 Static Picklane Locations:
 ------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'K'  /* Picklanes */,       --@LocationType     TLocationType,
  'U'  /*  Units */,          --@StorageType      TStorageType,
  '<Row>-<Level>-<Section>',  --@LocationFormat   TControlValue

  @StartRow         = '101',
  @EndRow           = '105',
  @RowIncrement     = '1',
  @RowCharSet       = 'N',

  @StartLevel       = '1',
  @EndLevel         = '1',
  @LevelIncrement   = '1',
  @LevelCharSet     = 'N',

  @StartSection     = '1',
  @EndSection       = '5',
  @SectionIncrement = '1',
  @SectionCharSet   = 'N';

/*------------------------------------------------------------------------------
 Reserve Locations:
 ------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'R'  /* Reserve */,           --@LocationType     TLocationType,
  'LA'  /*  LPNs & Pallets */,  --@StorageType      TStorageType,
  '<Row>-<Level>-<Section>',    --@LocationFormat   TControlValue

  @StartRow         = '201',
  @EndRow           = '205',
  @RowIncrement     = '1',
  @RowCharSet       = 'N',

  @StartLevel       = '1',
  @EndLevel         = '1',
  @LevelIncrement   = '1',
  @LevelCharSet     = 'N',

  @StartSection     = '1',
  @EndSection       = '5',
  @SectionIncrement = '1',
  @SectionCharSet   = 'N';

/*------------------------------------------------------------------------------
 Bulk Locations:
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'B'  /* Bulk */,              --@LocationType     TLocationType,
  'LA'  /*  LPNs & Pallets */,  --@StorageType      TStorageType,
  '<Row>-<Level>-<Section>',

  @StartRow         = '301',
  @EndRow           = '305',
  @RowIncrement     = '1',
  @RowCharSet       = 'N',

  @StartLevel       = '1',
  @EndLevel         = '1',
  @LevelIncrement   = '1',
  @LevelCharSet     = 'N',

  @StartSection     = '1',
  @EndSection       = '5',
  @SectionIncrement = '1',
  @SectionCharSet   = 'N';

/*------------------------------------------------------------------------------
Dock Locations:
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'D'  /* Dock */,            --@LocationType     TLocationType,
  'LA' /*  LPNs */,           --@StorageType      TStorageType,
  'RecvDock-<Row>',

  @StartRow         = '01',
  @EndRow           = '10',
  @RowIncrement     = '1',
  @RowCharSet       = 'N';

exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'D'  /* Dock */,            --@LocationType     TLocationType,
  'LA' /*  LPNs */,           --@StorageType      TStorageType,
  'ShipDock-<Row>',

  @StartRow         = '01',
  @EndRow           = '10',
  @RowIncrement     = '1',
  @RowCharSet       = 'N';

/*------------------------------------------------------------------------------
 Staging Locations:
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S'  /* Staging */,         --@LocationType     TLocationType,
  'LA' /*  LPNs */,           --@StorageType      TStorageType,
  'RecvLane-<Row>',

  @StartRow         = '01',
  @EndRow           = '10',
  @RowIncrement     = '1',
  @RowCharSet       = 'N';

update Locations set PutawayZone = 'RecvStaging' where Location like 'RecvLane%';

exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S'  /* Staging */,         --@LocationType     TLocationType,
  'LA' /*  LPNs */,           --@StorageType      TStorageType,
  'ShipLane-<Row>',

  @StartRow         = '01',
  @EndRow           = '10',
  @RowIncrement     = '1',
  @RowCharSet       = 'N';

update Locations set PutawayZone = 'ShipStaging' where Location like 'ShipLane%';

/*------------------------------------------------------------------------------
 Default Drop Locations for Bulk Case Pick Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'BCPDrop-<Row>',                      --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-BCP',
    PickingZone       = 'Drop-BCP',
    AllowMultipleSKUs = 'Y'
where Location like 'BCPDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Default Drop Locations for Bulk Pick & Pack Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'BPPDrop-<Row>',                      --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-BPP',
    PickingZone       = 'Drop-BPP',
    AllowMultipleSKUs = 'Y'
where Location like 'BPPDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Default Drop Locations for PTS Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'PTSDrop-<Row>',                      --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-PTS',
    PickingZone       = 'Drop-PTS',
    AllowMultipleSKUs = 'Y'
where Location like 'PTSDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for PTC Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'PTCDrop-<Row>',                      --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-PTC',
    PickingZone       = 'Drop-PTC',
    AllowMultipleSKUs = 'Y'
where Location like 'PTCDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for SLB Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'SLBDrop-<Row>',                      --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-SLB',
    PickingZone       = 'Drop-SLB',
    AllowMultipleSKUs = 'Y'
where Location like 'SLBDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for LTL Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'LTLDrop-<Row>',                     --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-LTL',
    PickingZone       = 'Drop-LTL',
    AllowMultipleSKUs = 'Y'
where Location like 'LTLDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for Rework Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'ReworkDrop-<Row>',                  --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-RW',
    PickingZone       = 'Drop-RW',
    AllowMultipleSKUs = 'Y'
where Location like 'ReworkDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for Transfer Waves
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'TransferDrop-<Row>',                  --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '05',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-XFER',
    PickingZone       = 'Drop-XFER',
    AllowMultipleSKUs = 'Y'
where Location like 'TransferDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for Paused Tasks
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'PauseDrop-<Row>',                   --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '03',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-Pause',
    PickingZone       = 'Drop-Pause',
    AllowMultipleSKUs = 'Y'
where Location like 'PauseDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Drop Locations for Incomplete Orders
------------------------------------------------------------------------------*/
exec pr_Locations_Generate
  @BusinessUnit,
  @Warehouse,
  @UserId,

  'S',                                 --@LocationType     TLocationType,
  'LA',                                --@StorageType      TStorageType,
  'HoldDrop-<Row>',                    --@LocationFormat   TControlValue

  @StartRow         = '01',
  @EndRow           = '03',
  @RowIncrement     = '1';

update Locations
set LocationSubType   = 'D',
    PutawayZone       = 'Drop-Hold',
    PickingZone       = 'Drop-Hold',
    AllowMultipleSKUs = 'Y'
where Location like 'HoldDrop%' and LocationType = 'S' and StorageType = 'LA';

/*------------------------------------------------------------------------------
 Receiving Staging locations for each active Warehouse
------------------------------------------------------------------------------*/
insert into Locations (Location, LocationType, LocationSubType, StorageType,
                       LocationRow, LocationBay, LocationLevel, LocationSection, LocationClass,
                       MinReplenishLevel, MaxReplenishLevel, ReplenishUoM, AllowMultipleSKUs, Barcode,
                       PutawayPath, PickPath, PickingZone, PutawayZone,
                       Ownership, LOC_UDF1, LOC_UDF2, LOC_UDF3, LOC_UDF4, LOC_UDF5,
                       BusinessUnit, Warehouse, CreatedDate, CreatedBy)
select 'RIP-' + LU.LookUpCode, 'S' /* Staging */, 'D' /* Dynamic */, 'LA' /* LPNs/Pallets */,
       null, null, null, null, null,
       null, null, null, 'Y', 'RIP-' + LU.LookUpCode /* Barcode - Same as Location */,
       null, null, null, 'RecvStaging',
       @BusinessUnit /* Ownership */, null, null, null, null, null,
       @BusinessUnit, LU.LookUpCode, coalesce(CreatedDate, current_timestamp), coalesce(CreatedBy, System_User)
from vwLookUps LU
where (LU.LookUpCategory = 'Warehouse');

Go

