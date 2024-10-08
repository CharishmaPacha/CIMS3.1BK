/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TSKUPrePackImportType, TUPCImportType (CIMSDE-33)
  Create Type TUPCImportType as Table (
  Grant References on Type:: TUPCImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in UPC Import
   This table structure mimics the record structure of UPC import, with few additional fields
   to capture key fields, etc.,. */

Create Type TUPCImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TFlag,
    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    Description              TDescription,
    SKU1Description          TDescription,
    SKU2Description          TDescription,
    SKU3Description          TDescription,
    SKU4Description          TDescription,
    SKU5Description          TDescription,
    AlternateSKU             TSKU,
    Status                   TStatus,
    UoM                      TUoM,
    InnerPacksPerLPN         TInteger,
    UnitsPerInnerPack        TInteger,
    UnitsPerLPN              TInteger,
    InnerPackWeight          TFloat,
    InnerPackLength          TFloat,
    InnerPackWidth           TFloat,
    InnerPackHeight          TFloat,
    InnerPackVolume          TFloat,
    UnitWeight               TFloat,
    UnitLength               TFloat,
    UnitWidth                TFloat,
    UnitHeight               TFloat,
    UnitVolume               TFloat,
    UnitPrice                TFloat,
    Barcode                  TBarcode,
    UPC                      TUPC,
    Brand                    TBrand,
    ProdCategory             TCategory,
    ProdSubCategory          TCategory,
    ABCClass                 TFlag,
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,
    UDF11                    TUDF,
    UDF12                    TUDF,
    UDF13                    TUDF,
    UDF14                    TUDF,
    UDF15                    TUDF,
    UDF16                    TUDF,
    UDF17                    TUDF,
    UDF18                    TUDF,
    UDF19                    TUDF,
    UDF20                    TUDF,
    UDF21                    TUDF,
    UDF22                    TUDF,
    UDF23                    TUDF,
    UDF24                    TUDF,
    UDF25                    TUDF,
    UDF26                    TUDF,
    UDF27                    TUDF,
    UDF28                    TUDF,
    UDF29                    TUDF,
    UDF30                    TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, SKUId, RecordId),
    Unique                   (SKUId, RecordId),
    Unique                   (SKU, RecordId)
);

Grant References on Type:: TUPCImportType   to public;

Go
