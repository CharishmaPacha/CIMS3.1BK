/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/16  TK      TLocationsToReplenishData: Added UniqueId & InventoryClasses (HA-938)
  2020/05/27  NB      Added TLocationsToReplenishData(HA-368)
  Create Type TLocationsToReplenishData as Table (
  Grant References on Type:: TLocationsToReplenishData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLocationsToReplenishData as Table (
    RecordId                      TRecordId  identity (1,1) PRIMARY KEY,
    LocationId                    TRecordId,
    Location                      TLocation,
    LocationType                  TTypeCode,
    LocationTypeDesc              TDescription,
    LocationSubType               TTypeCode,
    LocationSubTypeDesc           TDescription,
    LocationRow                   TRow,
    LocationLevel                 TLevel,
    LocationSection               TSection,
    StorageType                   TTypeCode,
    StorageTypeDesc               TDescription,
    LocationStatus                TStatus,
    LocationStatusDesc            TDescription,
    PutawayZone                   TLookUpCode,
    PickZone                      TLookUpCode,

    SKUId                         TRecordId,
    SKU                           TSKU,
    SKU1                          TSKU,
    SKU2                          TSKU,
    SKU3                          TSKU,
    SKU4                          TSKU,
    SKU5                          TSKU,
    ProdCategory                  TCategory,
    ProdSubCategory               TCategory,

    LPNId                         TRecordId,
    LPN                           TLPN,

    Quantity                      TQuantity,
    InnerPacks                    TInnerPacks,
    UnitsPerLPN                   TQuantity,
    MinReplenishLevel             TQuantity,
    MinReplenishLevelDesc         TDescription,
    MinReplenishLevelUnits        TQuantity,
    MinReplenishLevelInnerPacks   TInnerPacks,
    MaxReplenishLevel             TQuantity,
    MaxReplenishLevelDesc         TDescription,
    MaxReplenishLevelUnits        TQuantity,
    MaxReplenishLevelInnerPacks   TInnerPacks,

    PercentFull                   TInteger,
    MinToReplenish                TQuantity,
    MinToReplenishDesc            TDescription,
    MaxToReplenish                TQuantity,
    MaxToReplenishDesc            TDescription,
    ReplenishUoM                  TUoM,

    UnitsInProcess                TQuantity,
    OrderedUnits                  TQuantity,
    ResidualUnits                 TQuantity,
    ReplenishType                 TTypeCode,
    ReplenishTypeDesc             TDescription,
    HotReplenish                  TTypeCode, -- SKU can be both Required/Fill Up as well as Hot, hence diff. flag is needed
    Ownership                     TOwnership,
    Warehouse                     TWarehouse,
    InventoryClass1               TInventoryClass,
    InventoryClass2               TInventoryClass,
    InventoryClass3               TInventoryClass,
    BusinessUnit                  TBusinessUnit,
    InventoryAvailable            TFlag,

    CurrentQty                    TQuantity  default 0,
    UnitsOnOrder                  TQuantity  default 0,
    DirectedQty                   TQuantity  default 0,
    AllocatedQty                  TQuantity  default 0,
    ToAllocateQty                 TQuantity  default 0,
    FinalQty                      as CurrentQty + AllocatedQty + ToAllocateQty + DirectedQty + UnitsOnOrder,

    UniqueId                      as cast(LocationId as varchar(10)) + '-' + cast(SKUId as varchar(10)),

    Unique                        (Location, RecordId),
    Unique                        (LocationId, SKUId, RecordId),
    Unique                        (SKUId, RecordId)
);

Grant References on Type:: TLocationsToReplenishData to public;

Go
