/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/16  SK      ix_SKUs_SKUId: Added display sku fields (HA-3941)
  2023/03/20  VM      SKUs: Added notes related to SKU1..SKU5 components (CIMSV3-2702)
  2022/05/11  SJ      SKUs: Added ProductInfo1, 2, & 3 fields (OBV3-635)
  2022/02/28  LAC     SKUs: Changed datatype For SKUImageURL (BK-775)
  2021/09/14  AY      ix_SKUs_SKUId: Added index for performance to calc SKU attr on LPN and Pallet (HA-3161)
  2021/07/20  AY      ix_SKUs_SKU1: Revised to add SKU2..SKU5 (HA Support)
  2021/01/06  RKC     SKUs: Changed the data type for HarmonizedCode field (CID-1616)
  2020/09/14  SAK     SKUs: Added ReturnDisposition field (FB-2135)
  2020/03/29  AY      SKUs: Added SKUImageURL (CIMSV3-733)
  SKUs: Added indices by AlternateSKU, CaseUPC, Barcode
  2019/01/29  TK      SKUs: Added InventoryUoM (S2GMI-83)
  2018/09/24  TK      SKUs: Added CartonGroup (HPI-2047)
  2018/06/01  AY      SKUs: Added IsBaggable
  2018/03/17  AY      SKUs: Added SourceSystem (FB-1114)
  2018/01/09  TK      SKUs: Added CaseUPC (S2G-41)
  2017/11/22  PK      SKUs: Added NMFC, HarmonizedCode (CIMS-1722).
  2017/08/07  TK      SKUs: Added ReplenishClass field (HPI-1623)
  2016/10/01  AY      SKUs: Added Nesting factor.
  2016/06/04  TK      SKUs: Added PrimaryLocationId and PrimaryLocation (NBD-580)
  2016/05/09  AY      SKUs: Added defaultCoO
  2016/03/01  AY      SKUs: UnitsPerInnerPack default of 1 removed.
  2015/02/06  AY      SKUs: Added Primary PickZone & Secondary Pick Zone
  2015/10/19  TD      SKUs: added Ownership field.
  2014/11/26  VM      SKUs: UnitsPerInnerPack should be 1 by default
  2013/07/19  AY      SKUs: Added Length/Width/Height for Units and Innerpacks
  2013/02/26  PK      SKUs: Added ABCClass
  2013/01/31  PK      SKUs: Added SKU1Description, SKU2Description, SKU3Description, SKU4Description
  2012/10/29  PK      SKUs: Added UnitsPerLPN
  AY      SKUs: Added SKU1..SKU3 Descriptions & SortOrder for SKUs.
  SKUs: Added indices by Status, SKU2,SKU3, UPC
  2012/09/20  AY      SKUs, SKUPrepacks: Added Archived.
  with multiple SKUs
  2011/07/08  AY      Added SKUs.PutawayClass
  2011/07/05  PK      Added SKU1 - SKU5 fields in SKUs table, and also added ReceivedDate and DestWarehouse
  2010/10/26  VM      SKUs: Added ProdCategory, ProdSubCategory
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: SKUs

 SKU1..SKU5 & SKU1Description..SKU5Description: Refer below link for standard descriptions and notes
   http://wiki.foxfireindia.com:8085/Projects.CIMS-SKU-Components-Standard.ashx

 IsSortable:  N - if the SKU is not conducive for sorting on a sorter else Y
 IsConveyable: N - if the SKU is too large to be transported on a conveyor else Y
 IsScannable: N - if the SKU does not have a barcode that can be scanned, else Y

 PalletTie: Number of Cases (IPs) on each layer of the Pallet
 PalletHigh: Number of layers of cases on the pallet

 PickUoM: C - means we can pick cases, U - we can pick units - by default U
 ShipUoM: C - means that we can ship an individual case, U - Can ship an individual unit,
                else we have to repack a Case or Unit to ship them

 PrimaryPickZone: PickLane - Unit Storage
 SecondaryPickZone: PickLane - Case Storage or Reserve
------------------------------------------------------------------------------*/
Create Table SKUs (
    SKUId                    TRecordId      identity (1,1) not null,

    SKU                      TSKU           not null,
    SKU1                     TSKU,          /* Season */
    SKU2                     TSKU,          /* Style */
    SKU3                     TSKU,          /* Color */
    SKU4                     TSKU,          /* Dimension */
    SKU5                     TSKU,          /* Size */
    Description              TDescription,
    SKU1Description          TDescription,  /* Season Description */
    SKU2Description          TDescription,  /* Style Description */
    SKU3Description          TDescription,  /* Color Description */
    SKU4Description          TDescription,  /* Dimension Description */
    SKU5Description          TDescription,  /* Size Description */
    ProductInfo1             TVarchar,
    ProductInfo2             TVarchar,
    ProductInfo3             TVarchar,
    AlternateSKU             TSKU,
    Status                   TStatus        not null default 'A' /* Active */,
    UoM                      TUoM,
    InventoryUoM             TUoM,

    InnerPacksPerLPN         TInteger,      /* Cases Per LPN */
    UnitsPerInnerPack        TInteger,      /* Units Per Case */
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
    NestingFactor            TFloat         default 1.0,

    PalletTie                TInteger,
    PalletHigh               TInteger,

    UnitPrice                TFloat,
    UnitCost                 TFloat,

    PickUoM                  TFlags,        /* C - Pick Cases, U - Pick Units */
    ShipUoM                  TFlags,
    PickMultiple             TInteger       default 1,
    ShipPack                 TInteger       default 1,     /* Always ship in multiple of these Units only */

    Barcode                  TBarcode,
    UPC                      TUPC,
    CaseUPC                  TUPC,
    Brand                    TBrand,
    SKUImageURL              TURL,        -- full or part of the image file path+name

    ProdCategory             TCategory,
    ProdSubCategory          TCategory,
    PutawayClass             TCategory,
    ABCClass                 TFlag,
    ReplenishClass           TCategory,
    CartonGroup              TCategory,

    NMFC                     TTypeCode,
    HarmonizedCode           THarmonizedCode,
    HTSCode                  THTSCode,

    PrimaryLocationId        TRecordId,
    PrimaryLocation          TLocation,
    PrimaryPickZone          TLookUpCode,
    SecondaryPickZone        TLookUpCode,
    NumPicklanes             TCount        default 0,
    DisplaySKU               TSKU,
    DisplaySKUDesc           TDescription,

    Serialized               TFlag          default 'N' /* No */,
    ReturnDisposition        TOperation,
    IsSortable               TFlags,
    IsConveyable             TFlags,
    IsScannable              TFlags,
    IsBaggable               TFlags         default 'Y' /* Yes */,

    SKUSortOrder             TDescription,  /* The order in which SKUs should be sorted */

    Ownership                TOwnership,   /* Inventory Owner */
    defaultCoO               TCoO,

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

    SourceSystem             TName          default 'HOST',
    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default getdate(),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSKUs_SKUId PRIMARY KEY (SKUId),
    constraint ukSKUs_SKU   UNIQUE (SKU, BusinessUnit)
);

/* used in fn_LPNs_GetConsolidatedSKUAttributes */
create index ix_SKUs_SKUId                       on SKUs (SKUId) include (SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UnitWeight, UnitVolume, UnitsPerInnerPack, DisplaySKU, DisplaySKUDesc);
create index ix_SKUs_SKU                         on SKUs (SKU, BusinessUnit) Include (SKUId);
/* Used in SKUStyle inquiry to get all SKUs for a style/color */
create index ix_SKUs_SKU1                        on SKUs (SKU1, BusinessUnit, Status) Include (SKUId, SKU2, SKU3, SKU4, SKU5);
create index ix_SKUs_SKU2                        on SKUs (SKU2, Status);
create index ix_SKUs_SKU3                        on SKUs (SKU3, Status);
create index ix_SKUs_UPC                         on SKUs (UPC, BusinessUnit, Status) Include (SKUId);
create index ix_SKUs_Barcode                     on SKUs (Barcode, BusinessUnit, Status) Include (SKUId);
create index ix_SKUs_AlternateSKU                on SKUs (AlternateSKU, BusinessUnit, Status) Include (SKUId);
create index ix_SKUs_CaseUPC                     on SKUs (CaseUPC, BusinessUnit, Status) Include (SKUId);
create index ix_SKUs_Description                 on SKUs (Description);
create index ix_SKUs_Status                      on SKUs (Status) Include (SKUId, SKU, SKU1, SKU2, SKU3, SKU4, UPC, Description);
create index ix_SKUs_Category                    on SKUs (ProdCategory, ProdSubCategory);

Go
