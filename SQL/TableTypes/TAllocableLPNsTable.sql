/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/26  TK      TAllocableLPNsTable, TOrderDetailsToAllocateTable & TSKUOrderDetailsToAllocate:
  TAllocableLPNsTable: Added UnitsToAllocate & SortOrder (HA-86)
  2017/08/07  TK      TAllocationRulesTable & TAllocableLPNsTable: Added ReplenishClass (HPI-1625)
  2016/05/03  AY      TAllocableLPNsTable: Added NumLines, NumSKUs
  Create Type TAllocableLPNsTable as Table (
  Grant References on Type:: TAllocableLPNsTable to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Dataset to hold the list of LPNs that can be allocated */
Create Type TAllocableLPNsTable as Table (
    LocationId               TRecordId,
    Location                 TLocation,
    LocationType             TTypeCode,
    LocationSubType          TTypeCode,
    StorageType              TTypeCode,
    PickZone                 TZoneId,
    PickPath                 TLocation,

    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNDetailId              TRecordId,
    NumLines                 TCount,
    NumSKUs                  TCount,        -- future use

    OnhandStatus             TStatus,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKUABCClass              TFlag,

    PickingClass             TPickingClass,
    ReplenishClass           TCategory,

    AllocableInnerPacks      TInnerPacks,
    AllocableQuantity        TQuantity,
    TotalInnerPacks          TInnerPacks,
    TotalQuantity            TQuantity,
    UnitsPerPackage          TInteger,
    UnitsToAllocate          TInteger,

    ExpiryInDays             TInteger,
    ExpiryMonth              TInteger,
    ExpiryDate               TDate,
    ExpiryWindow             TInteger,

    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,

    Ownership                TOwnership,
    Warehouse                TWarehouse,

    ProcessFlag              TFlags,  /* N - Need to be processed, Y - Processed, X - Don't need to be processed */
    SortSeq                  TInteger,

    AL_UDF1                  TUDF,
    AL_UDF2                  TUDF,
    AL_UDF3                  TUDF,
    AL_UDF4                  TUDF,
    AL_UDF5                  TUDF,

    KeyValue                 as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' +
                                coalesce(Lot, '') + '-' + coalesce(InventoryClass1, ''),

    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId),
    unique                   (LPNId, LPN, LPNDetailId, RecordId),
    unique                   (ProcessFlag, SKUId, LPNDetailId)
);

Grant References on Type:: TAllocableLPNsTable to public;

Go
