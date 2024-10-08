/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/19  TK      Added TLPNsInfo (HA-3182)
  Create Type TLPNsInfo as Table (
  Grant References on Type:: TLPNsInfo  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLPNsInfo as Table (
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNType                  TTypeCode,
    LPNStatus                TStatus,
    LPNOnHandStatus          TStatus,

    NewLPNStatus             TStatus,
    NewLPNOnHandStatus       TStatus,

    SKUId                    TRecordId,
    SKU                      TSKU,
    InnerPacks               TInteger,
    Quantity                 TInteger,
    ReservedQty              TQuantity,
    AllocableQty             TQuantity,
    ConsumedQty              TQuantity,
    UnitsPerPackage          TInteger,

    NumLines                 TCount,
    AvailableLines           TCount,
    ReservedLines            TCount,
    UnavailableLines         TCount,

    PalletId                 TRecordId,
    Pallet                   TPallet,
    PalletType               TTypeCode,
    PalletStatus             TStatus,

    ReceiptId                TRecordId,
    ReceiptNumber            varchar(50),
    ReceiverId               TRecordId,
    ReceiverStatus           TStatus,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    OrderType                TTypeCode,
    OrderStatus              TStatus,

    WaveId                   TRecordId,
    WaveNo                   varchar(30), -- TWaveNo is not defined yet
    WaveType                 TTypeCode,
    WaveStatus               TStatus,

    Weight                   TFloat,
    Volume                   TFloat,

    Warehouse                TWarehouse,
    Ownership                TOwnership,
    Lot                      TLot,
    CoO                      TCoO,
    ReasonCode               varchar(20),
    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    LocationId               TRecordId,
    Location                 TLocation,
    LocationType             TLocationType,
    LocationSubType          TTypeCode,
    LocationStorageType      TStorageType,
    LocationStatus           TStatus,
    AllowMultipleSKUs        TFlag,
    PickingZone              TLookUpCode,
    PutawayZone              TLookUpCode,

    NewLocationId            TRecordId,
    NewLocation              TLocation,
    NewLocationType          TLocationType,
    NewLocationSubType       TTypeCode,
    NewLocationStorageType   TStorageType,
    NewLocationStatus        TStatus,
    NewLocAllowMultipleSKUs  TFlag,
    NewLocationWarehouse     TWarehouse,
    NewLocationPickingZone   TLookUpCode,
    NewLocationPutawayZone   TLookUpCode,

    DestLocation             TLocation,
    DestLocationType         TTypeCode,
    DestZone                 TZone,
    ClearDestination         TFlag,

    LoadId                   TRecordId,
    LoadNumber               TLoadNumber,
    LoadType                 TTypecode,
    ShipmentId               TShipmentId,

    ExportTransType          TTypeCode,
    KeyValue                 TVarchar,
    Reference                TReference,
    UniqueId                 TUniqueId,
    LPNLines                 TCount,
    EntityId                 TRecordId,

    BusinessUnit             TBusinessUnit,
    ValidationMessage        TMessage,
    CreatedBy                TUserId,
    ProcessedFlag            TFlag,
    SortOrder                TSortOrder,
    InputRecordId            TRecordId,

    RecordId                 TRecordId      identity (1,1) not null
);

Grant References on Type:: TLPNsInfo  to public;

Go
