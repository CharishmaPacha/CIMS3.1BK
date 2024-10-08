/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RKC     TSKUImportType: Changed the data type for HarmonizedCode field (CID-1616)
  TSKUImportType: UDF's Renamed as SKU_UDF1 to 30, TSKUPrepacksImportType: SPP_UDF1 to 5
  TSKUImportType: Added UDF11 to 30 and Removed SKUValidations, AuditTrail
  2019/09/24  RKC     TSKUImportType ,TImportValidationType:Added CartonGroup
  2018/04/05  YJ      TSKUImportType: Added CaseUPC(S2G-528)
  2018/02/06  RT      Added NestingFactor and DefaultCoO fields in TSKUImportType (S2G-19)
  2017/11/09  TD      TSKUImportType, TImportValidationType - added HostRecId (CIMSDE-14)
  2016/03/01  YJ      TOrderHeaderImportType: Added field ReceiptNumber, And TSKUImportType: SKUSortOrder (CIMS-780)
  2014/10/20  NB      Added TSKUImportType
  Create Type TSKUImportType as Table (
  Grant References on Type:: TSKUImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in SKU Import
   This table structure mimics the record structure of SKU import, with few additional fields
   to capture key fields, etc.,. */

Create Type TSKUImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

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
    PalletTie                TInteger,
    PalletHigh               TInteger,
    NestingFactor            TFloat,

    UnitPrice                TFloat,
    UnitCost                 TFloat,
    PickUoM                  TFlags,
    ShipUoM                  TFlags,
    ShipPack                 TInteger,

    IsSortable               TFlags,
    IsConveyable             TFlags,
    IsScannable              TFlags,
    IsBaggable               TFlags,

    SKUSortOrder             TDescription,
    AlternateSKU             TSKU,
    Barcode                  TBarcode,
    UPC                      TUPC,
    CaseUPC                  TUPC,

    Brand                    TBrand,
    SKUImageURL              TURL,
    ProdCategory             TCategory,
    ProdSubCategory          TCategory,
    PutawayClass             TCategory,
    ABCClass                 TFlag,
    NMFC                     TTypeCode,
    HarmonizedCode           THarmonizedCode,
    Serialized               TFlag,
    ReturnDisposition        TOperation,
    CartonGroup              TCategory,
    Ownership                TOwnership,
    DefaultCoO               TCoO,

    SKU_UDF1                 TUDF,
    SKU_UDF2                 TUDF,
    SKU_UDF3                 TUDF,
    SKU_UDF4                 TUDF,
    SKU_UDF5                 TUDF,
    SKU_UDF6                 TUDF,
    SKU_UDF7                 TUDF,
    SKU_UDF8                 TUDF,
    SKU_UDF9                 TUDF,
    SKU_UDF10                TUDF,
    SKU_UDF11                TUDF,
    SKU_UDF12                TUDF,
    SKU_UDF13                TUDF,
    SKU_UDF14                TUDF,
    SKU_UDF15                TUDF,
    SKU_UDF16                TUDF,
    SKU_UDF17                TUDF,
    SKU_UDF18                TUDF,
    SKU_UDF19                TUDF,
    SKU_UDF20                TUDF,
    SKU_UDF21                TUDF,
    SKU_UDF22                TUDF,
    SKU_UDF23                TUDF,
    SKU_UDF24                TUDF,
    SKU_UDF25                TUDF,
    SKU_UDF26                TUDF,
    SKU_UDF27                TUDF,
    SKU_UDF28                TUDF,
    SKU_UDF29                TUDF,
    SKU_UDF30                TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    SKUId                    TRecordId,
    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, SKUId, RecordId),
    Unique                   (SKUId, RecordId),
    Unique                   (SKU, RecordId)
);

Grant References on Type:: TSKUImportType   to public;

Go
