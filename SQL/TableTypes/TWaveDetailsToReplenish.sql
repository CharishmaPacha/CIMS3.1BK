/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/08  TK      TWaveDetailsToReplenish & TLocationsToReplenish: Added InventoryClass (HA-871)
  2018/03/07  TK      Added TWaveDetailsToReplenish & TLocationsToReplenish (S2G-364)
  Create Type TWaveDetailsToReplenish as Table (
  Grant References on Type:: TWaveDetailsToReplenish to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TWaveDetailsToReplenish as Table (
    WaveId                   TRecordId,
    OrderId                  TRecordId,
    SKUId                    TRecordId,
    TotalQtyToAllocate       TQuantity,
    CasesToAllocate          TQuantity,
    UnitsToAllocate          TQuantity,

    DestZone                 TZoneId,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TWaveDetailsToReplenish to public;

Go
