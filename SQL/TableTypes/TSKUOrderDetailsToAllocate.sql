/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/26  TK      TAllocableLPNsTable, TOrderDetailsToAllocateTable & TSKUOrderDetailsToAllocate:
  2016/04/27  TK      Added TSKUOrderDetailsToAllocate (FB-648)
  Create Type TSKUOrderDetailsToAllocate as Table (
  Grant References on Type:: TSKUOrderDetailsToAllocate to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TSKUOrderDetailsToAllocate as Table (
    SKUId                    TRecordId,
    PrePackSKUId             TRecordId,
    DestZone                 TZoneId,
    ABCClass                 TFlag,
    Ownership                TOwnership,
    Lot                      TLot,
    Account                  TAccount,

    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,

    UnitsToAllocate          TQuantity,

    KeyValue                 TDescription,

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TSKUOrderDetailsToAllocate to public;

Go
