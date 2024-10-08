/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  VS      Added TOnhandInventorySKUsToShip,TOnhandInventoryResult,TOnhandInventory2 (FB-2029)
  2020/04/29  MS      TOnhandInventory: Changes to send InventoyClasses in Exports (HA-323)
  2018/05/06  DK      TOnhandInventory: Added UnitsToFulfill (FB-1150)
  2018/03/30  YJ      TOnhandInventory: Added SourceSystem (FB-1114)
  2016/09/24  AY      TOnhandInventory: Added index for performance (HPI-GoLive)
  2016/05/30  TK      TOnhandInventory: Added ProcessFlag (HPI-31)
  2016/05/27  TK      TOnhandInventory: Added fields for Logging (HPI-31)
  2016/03/10  RV      Added TOnhandInventory (CIMS-809)
  Create Type TOnhandInventory as Table (
  Grant References on Type:: TOnhandInventory  to public;
  -- Create Type TOnhandInventory2 as Table
  -- Create Type TOnhandInventoryResult as Table
  Create Type TOnhandInventorySKUsToShip as Table
  Grant References on Type:: TOnhandInventorySKUsToShip to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TOnhandInventory as Table (
    SKUId                    TRecordId,
    SKU                      TSKU,

    AvailableQty             TQuantity      DEFAULT 0,
    ReservedQty              TQuantity      DEFAULT 0,
    ReceivedQty              TQuantity      DEFAULT 0,
    OnhandQty                as AvailableQty + ReservedQty,

  --OnhandValue              TMoney         DEFAULT 0,
    ToShipQty                TQuantity      DEFAULT 0,
    ShortQty                 TQuantity      DEFAULT 0,

    Warehouse                TWarehouse,
    Ownership                TOwnership,
    SourceSystem             TName          DEFAULT 'HOST',

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

    Brand                    TBrand,
    ProdCategory             TCategory,
    ProdSubCategory          TCategory,
    ABCClass                 TFlag,
    SKUSortOrder             TDescription,
    OnhandValue              TMoney,
    PutawayClass             TCategory,

    UPC                      TUPC,
    UnitPrice                TFloat         DEFAULT 0,
    UoM                      TUoM,
    UnitsPerInnerPack        TQuantity      DEFAULT 1,

    LPN                      TLPN,
    Location                 TLocation,
    Quantity                 TQuantity      DEFAULT 0,
    UnitsToFulfill           TQuantity,
    OnhandStatus             TStatus,
    ExpiryDate               TDate,
    Lot                      TLot,
    InventoryClass1          TInventoryClass DEFAULT '',
    InventoryClass2          TInventoryClass DEFAULT '',
    InventoryClass3          TInventoryClass DEFAULT '',

    InnerPacks               TQuantity      DEFAULT 0,
    AvailableIPs             TQuantity      DEFAULT 0,
    ReservedIPs              TQuantity      DEFAULT 0,
    ReceivedIPs              TQuantity      DEFAULT 0,
    ToShipIPs                TQuantity      DEFAULT 0,
    OnhandIPs                as AvailableIPs + ReservedIPs,

    ProcessFlag              TFlag          DEFAULT 'N',
    InventoryKey             TKeyValue,

    /* For Logging */
    SABatchNo                TInteger,
    Iteration                TCount,
    KeyValue                 TDescription,
    Operation                TOperation,
    CreatedDate              TDateTime DEFAULT current_timestamp,

    BusinessUnit             TBusinessUnit,

    vwEOHINV_UDF1            TUDF,
    vwEOHINV_UDF2            TUDF,
    vwEOHINV_UDF3            TUDF,
    vwEOHINV_UDF4            TUDF,
    vwEOHINV_UDF5            TUDF,
    vwEOHINV_UDF6            TUDF,
    vwEOHINV_UDF7            TUDF,
    vwEOHINV_UDF8            TUDF,
    vwEOHINV_UDF9            TUDF,
    vwEOHINV_UDF10           TUDF,

    Unique                   (KeyValue, RecordId),
    Unique                   (SABatchNo, RecordId),
    Unique                   (ProcessFlag, AvailableQty, RecordId),
    Unique                   (SKUId, Warehouse, Ownership, InventoryClass1, InventoryClass2, InventoryClass3, RecordId), -- For soft allocation
    RecordId                 TRecordId
);

Grant References on Type:: TOnhandInventory  to public;

Go
