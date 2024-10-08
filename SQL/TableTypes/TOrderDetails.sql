/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/15  TK      TOrderDetails: Added More Fields (BK-720)
  2021/07/28  RV      TOrderDetailsToConvertSetSKUs: Added (OB2-1948)
  2021/05/21  TK      TOrderDetails: Added PrepackCode & KitQuantity (HA-2664)
  2021/04/22  RV      TOrderDetails: Added NewInventoryClass1, NewInventoryClass2 and NewInventoryClass3 (HA-2685)
  2021/04/07  TK      TOrderDetails: Added TotalWeight, TotalVolume, LoadId, LoadNumber, ShipmentId (HA-1842)
  2021/03/30  TK      TOrderDetails: Added BulkOrderId (HA-2463)
  2021/03/13  PK      TOrderDetails: Added InventoryClass1, InventoryClass2, InventoryClass3,
  2021/03/03  AY      TOrderDetails: Added SortOrder (HA-2127)
  2021/02/21  TK      TOrderDetails: Added ProcessFlag (HA-2033)
  2021/01/11  TK      TOrderDetails: Added ResidualUnits (HA-1899)
  2020/09/11  TK      TOrderDetails: Added columns required for Kitting process (HA-1238)
  2020/06/22  TK      TOrderDetailsToAllocateTable: Added new SKU, InventoryClasses & SourceSystem (HA-834)
  2020/05/13  TK      TOrderDetails: Added HostOrderLine, DestZone & InventoryClasses (HA-86)
  2020/05/01  TK      TOrderDetails: Added SalesOrder, Lot, PackingGroup, Ownership, Warehouse (HA-172)
  2020/04/26  TK      TAllocableLPNsTable, TOrderDetailsToAllocateTable & TSKUOrderDetailsToAllocate:
  2016/11/24  VM      TOrderDetailsToAllocateTable: Included Warehouse, KeyValue (FB-826)
  2015/11/12  AY      TOrderDetailsToAllocateTable: Added fields Ownership, Lot, Account & UDFs
  2014/04/06  TD      Added TOrderDetailsToAllocateTable, TAllocationRulesTable,
  Create Type TOrderDetailsToAllocateTable as Table (
  Grant References on Type:: TOrderDetailsToAllocateTable to public;
  Create Type TOrderDetails as Table (
  Grant References on Type:: TOrderDetails to public;
  Create Type TOrderDetailsToConvertSetSKUs as Table (
  Grant References on Type:: TOrderDetailsToConvertSetSKUs to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TOrderDetails as Table (
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,
    WaveStatus               TStatus,
    WaveAllocateFlags        TFlags,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderType                TTypeCode,
    OrderStatus              TStatus,

    OrderDetailId            TRecordId,
    HostOrderLine            THostOrderLine,
    ParentHostLineNo         THostOrderLine,
    SKUId                    TRecordId,
    SKU                      TSKU,

    UnitsOrdered             TQuantity,
    UnitsToShip              TQuantity,
    UnitsShipped             TQuantity,
    UnitsAssigned            TQuantity,
    UnitsPreAllocated        TQuantity,
    UnitsPerInnerPack        TInteger,
    UnitsPerCarton           TInteger,
    UnitsToAllocate          TInteger,
    UnitsLabeled             TInteger,
    UnitsToLabel             TInteger,

    KitSKUId                 TRecordId,
    KitsToCreate             TInteger,
    KitsOrdered              TInteger,
    KitsAllocated            TInteger,
    KitsPossible             TInteger, -- Possible number of Kits that can be created
    KitQuantity              TInteger, -- Quantity in each Kit
    ResidualUnits            TInteger,

    BulkOrderId              TRecordId,
    DestZone                 TZoneId,
    PackingGroup             TCategory,
    PrepackCode              TCategory,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    Lot                      TLot,
    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',
    NewInventoryClass1       TInventoryClass    DEFAULT '',
    NewInventoryClass2       TInventoryClass    DEFAULT '',
    NewInventoryClass3       TInventoryClass    DEFAULT '',
    SortOrder                TSortOrder         DEFAULT '',

    TotalVolume              TVolume            DEFAULT 0,
    TotalWeight              TWeight            DEFAULT 0.0,

    LoadId                   TLoadId,
    LoadNumber               TLoadNumber,
    ShipmentId               TShipmentId,

    OD_UDF1                  TUDF,
    OD_UDF2                  TUDF,
    OD_UDF3                  TUDF,
    OD_UDF4                  TUDF,
    OD_UDF5                  TUDF,

    ProcessFlag              TFlags,

    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId),
    Unique                   (SKUId, OrderDetailId, InventoryClass1, InventoryClass2,
                              InventoryClass3, NewInventoryClass1, Ownership, Warehouse)
);

Grant References on Type:: TOrderDetails to public;

Go
