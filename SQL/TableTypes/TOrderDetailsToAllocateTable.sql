/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/22  TK      TOrderDetailsToAllocateTable: Added new SKU, InventoryClasses & SourceSystem (HA-834)
  2020/04/26  TK      TAllocableLPNsTable, TOrderDetailsToAllocateTable & TSKUOrderDetailsToAllocate:
  2016/11/24  VM      TOrderDetailsToAllocateTable: Included Warehouse, KeyValue (FB-826)
  2015/11/12  AY      TOrderDetailsToAllocateTable: Added fields Ownership, Lot, Account & UDFs
  2014/04/06  TD      Added TOrderDetailsToAllocateTable, TAllocationRulesTable,
  Create Type TOrderDetailsToAllocateTable as Table (
  Grant References on Type:: TOrderDetailsToAllocateTable to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TOrderDetailsToAllocateTable as Table (
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    OrderType                TTypeCode,
    OrderDetailId            TRecordId,
    HostOrderLine            THostOrderLine,

    UnitsAuthorizedToShip    TQuantity,
    UnitsToAllocate          TQuantity,
    UnitsPreAllocated        TQuantity,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKUABCClass              TFlag,
    NewSKUId                 TRecordId,
    NewSKU                   TSKU,

    DestZone                 TZoneId,
    DestLocationId           TRecordId,
    DestLocation             TLocation,

    Ownership                TOwnership,
    Lot                      TLot,
    Account                  TAccount,
    Warehouse                TWarehouse,
    SourceSystem             TName,

    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    NewInventoryClass1       TInventoryClass,
    NewInventoryClass2       TInventoryClass,
    NewInventoryClass3       TInventoryClass,

    CasesToReserve           TInnerPacks,
    UnitsToReserve           TQuantity,
    ReserveUoM               TDescription, /* whether to reserve Cases or Units for the Order detail or both */

    ProcessFlag              TFlags, /* N - Need to be processed, Y- Processed, X - Don't need to be processed */

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    KeyValue                 as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' +
                                coalesce(Lot, '') + '-' + coalesce(InventoryClass1, ''),

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TOrderDetailsToAllocateTable to public;

Go
