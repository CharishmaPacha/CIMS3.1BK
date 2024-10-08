/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/09  KBB     TLocationsToCycleCountData: Added Warehouse filed (HA-1406)
  2020/07/16  MS      Added TLocationsToCycleCountData (CIMSV3-548)
  Create Type TLocationsToCycleCountData as Table (
  Grant References on Type:: TLocationsToCycleCountData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLocationsToCycleCountData as Table (
    RecordId                 TRecordId  identity (1,1) PRIMARY KEY,
    LocationId               TRecordId,
    Location                 TLocation,
    LocationType             TTypeCode,
    LocationTypeDesc         TDescription,
    LocationSubType          TTypeCode,
    LocationSubTypeDesc      TDescription,
    StorageType              TTypeCode,
    StorageTypeDesc          TDescription,
    LocationStatus           TStatus,
    LocationStatusDesc       TDescription,
    LocationRow              TRow,
    LocationLevel            TLevel,
    LocationSection          TSection,
    Warehouse                TWarehouse,
    PutawayZone              TLookUpCode,
    PickZone                 TLookUpCode,
    PutawayZoneDesc          TDescription,
    PickZoneDesc             TDescription,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    SKU1Desc                 TDescription,
    SKU2Desc                 TDescription,
    SKU3Desc                 TDescription,
    SKU4Desc                 TDescription,
    SKU5Desc                 TDescription,

    NumSKUs                  TCount,
    NumLPNs                  TCount,
    InnerPacks               TQuantity,
    Quantity                 TQuantity,
    LocationABCClass         TFlag,
    LastCycleCounted         TDateTime,
    PolicyCompliant          TFlag,
    DaysAfterLastCycleCount  TCount,

    HasActiveTask            as case when TaskId > 0 then 'Y' else 'N' end,
    TaskId                   TRecordId,
    BatchNo                  TTaskBatchNo,
    ScheduledDate            TDateTime,

    CC_LocUDF1               TUDF,
    CC_LocUDF2               TUDF,
    CC_LocUDF3               TUDF,
    CC_LocUDF4               TUDF,
    CC_LocUDF5               TUDF,
    CC_LocUDF6               TUDF,
    CC_LocUDF7               TUDF,
    CC_LocUDF8               TUDF,
    CC_LocUDF9               TUDF,
    CC_LocUDF10              TUDF,

    BusinessUnit             TBusinessUnit,

    UniqueId                 as cast(LocationId as varchar(10)) + '-' + cast(SKUId as varchar(10)),

    Unique                   (Location, RecordId),
    Unique                   (LocationId, SKUId, RecordId),
    Unique                   (SKUId, RecordId)
);

Grant References on Type:: TLocationsToCycleCountData to public;

Go
