/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  SK      TWaveInfo: Added new Table type (HA-906)
  Create Type TWaveInfo as Table (
  Grant References on Type:: TWaveInfo to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TWaveInfo as Table (
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,
    WaveStatus               TStatus,

    -- SKUId                    TRecordId,
    -- SKU                      TSKU,
    --
    -- OrderId                  TRecordId,
    -- OrderDetailId            TRecordId,
    --
    -- LPNId                    TRecordId,
    -- LPNDetailId              TRecordId,
    -- LPNType                  TTypeCode,

    NumOrders                TCount         DEFAULT 0,
    NumSKUs                  TCount         DEFAULT 0,
    NumPallets               TCount         DEFAULT 0,
    NumLPNs                  TCount         DEFAULT 0,
    NumUnits                 TCount         DEFAULT 0,
    NumTasks                 TCount         DEFAULT 0,
    NumPicks                 TCount         DEFAULT 0,
    NumPicksCompleted        TCount         DEFAULT 0,

    /* Counts of orders in various statuses */
    OrdersWaved              TCount         DEFAULT 0,
    OrdersAllocated          TCount         DEFAULT 0,
    OrdersPicked             TCount         DEFAULT 0,
    OrdersPacked             TCount         DEFAULT 0,
    OrdersLoaded             TCount         DEFAULT 0,
    OrdersStaged             TCount         DEFAULT 0,
    OrdersShipped            TCount         DEFAULT 0,
    OrdersOpen               TCount         DEFAULT 0,

    /* sum of Units in various statuses */
    UnitsAssigned            TQuantity      DEFAULT 0,
    UnitsPicked              TQuantity      DEFAULT 0,
    UnitsPacked              TQuantity      DEFAULT 0,
    UnitsStaged              TQuantity      DEFAULT 0,
    UnitsLoaded              TQuantity      DEFAULT 0,
    UnitsShipped             TQuantity      DEFAULT 0,

    LPNDetailQuantity        TQuantity      DEFAULT 0,
    LPNQuantity              TQuantity      DEFAULT 0,
    LPNsAssigned             TQuantity      DEFAULT 0,
    LPNsPicked               TQuantity      DEFAULT 0,
    LPNsPacked               TQuantity      DEFAULT 0,
    LPNsStaged               TQuantity      DEFAULT 0,
    LPNsLoaded               TQuantity      DEFAULT 0,
    LPNsShipped              TQuantity      DEFAULT 0,

    TotalAmount              TMoney,
    TotalWeight              TWeight        DEFAULT 0.0,
    TotalVolume              TVolume        DEFAULT 0,

    UDF1                     TUDF           DEFAULT '',
    UDF2                     TUDF           DEFAULT '',
    UDF3                     TUDF           DEFAULT '',
    UDF4                     TUDF           DEFAULT '',

    Ownership                TOwnership     DEFAULT '',
    Warehouse                TWarehouse     DEFAULT '',
    BusinessUnit             TBusinessUnit  DEFAULT '',

    RecordId                 TRecordId      Identity(1,1)
);

Grant References on Type:: TWaveInfo to public;

Go
