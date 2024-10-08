/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/24  RIA     TLocationImportType: Added SKUId and SKUStatus (S2GCA-867)
  2018/05/24  RT      TLocationImportType: Added LocationClass and SKU
  2017/05/15  OK      Added TLocationImportType (CIMS-1339)
  Create Type TLocationImportType as Table (
  Grant References on Type:: TLocationImportType  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* ?? */
Create Type TLocationImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    Location                 TLocation,
    LocationType             TLocationType,
    LocationSubType          TTypeCode,
    StorageType              TStorageType,
    Status                   TStatus,

    LocationRow              TRow,
    LocationBay              TBay,
    LocationLevel            TLevel,
    LocationSection          TSection,

    Warehouse                TWarehouse,
    LocationClass            TCategory,
    MinReplenishLevel        TQuantity,
    MaxReplenishLevel        TQuantity,
    ReplenishUoM             TUoM,

    SKU                      TSKU,
    AllowMultipleSKUs        TFlag,

    Barcode                  TBarcode,
    PutawayPath              TLocationPath,
    PickPath                 TLocationPath,
    PickingZone              TLookUpCode,
    PutawayZone              TLookUpCode,
    Ownership                TOwnership,

    LOC_UDF1                 TUDF,
    LOC_UDF2                 TUDF,
    LOC_UDF3                 TUDF,
    LOC_UDF4                 TUDF,
    LOC_UDF5                 TUDF,

    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    LocationId               TRecordId,
    SKUId                    TRecordId,
    SKUStatus                TStatus,
    EntityKey                TEntityKey,
    InputXML                 TXML,
    ResultXML                TXML,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
  );

Grant References on Type:: TLocationImportType  to public;

Go
