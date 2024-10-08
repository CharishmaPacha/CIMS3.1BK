/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/02  RKC     Added TLPNDetails.UoM (BK-218)
  2021/07/31  TK      TLPNDetails: Added LoadType (HA-3031)
  2021/04/21  TK      TLPNDetails: Added ShipmentId (HA-2641)
  2021/04/04  AY      TLPNDetails: Added PalletType, PickTicket, LoadId, LoadNumber, EntityId (HA-1842)
  2020/09/12  TK      TLPNDetails: Added ConsumedQty (HA-1238)
  2020/07/01  TK      TLPNDetails: Added PalletId  & Pallet (HA-830)
  TLPNDetails: Added more fields as needed (HA-833)
  2020/06/08  TK      TLPNDetails: Added WaveNo (HA-820)
  2020/05/24  SK      Added ProcessedFlag field to TLPNDetails (HA-640)
  TK      TLPNDetails: Added InventoryClasses (HA-521)
  2020/04/25  TK      TLPNDetails: Added LPN, Reference, BusinessUnit & CreatedBy (HA-171)
  2019/09/12  SK      TLPNDetails: Added WaveId (FB-1460)
  2019/09/16  AY      TLPNDetails: New (FB-1351)
  Create Type TLPNDetails as Table (
  Grant References on Type:: TLPNDetails  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLPNDetails as Table (
    WaveId                   TRecordId,
    WaveNo                   varchar(30), -- TWaveNo is not defined yet
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNDetailId              TRecordId,
    PalletId                 TRecordId,
    Pallet                   TPallet,
    PalletType               TTypeCode,

    SKUId                    TRecordId,
    SKU                      TSKU,
    UoM                      TUoM,
    InnerPacks               TInteger,
    Quantity                 TInteger,
    ReservedQty              TQuantity,
    AllocableQty             TQuantity,
    ConsumedQty              TQuantity,
    UnitsPerPackage          TInteger,

    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    OrderType                TTypeCode,
    OrderDetailId            TRecordId,

    Weight                   TFloat,
    Volume                   TFloat,

    LPNType                  TTypeCode,
    LPNStatus                TStatus,
    OnhandStatus             TStatus,

    Warehouse                TWarehouse,
    Ownership                TOwnership,
    Lot                      TLot,
    CoO                      TCoO,
    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    LocationId               TRecordId,
    Location                 TLocation,

    LoadId                   TRecordId,
    LoadNumber               TLoadNumber,
    LoadType                 TTypecode,
    ShipmentId               TShipmentId,

    KeyValue                 TKeyValue,
    InventoryKey             TInventoryKey, -- use this instead of KeyValue
    Reference                TReference,
    UniqueId                 TLPN,
    LPNLines                 TCount,
    EntityId                 TRecordId,

    BusinessUnit             TBusinessUnit,
    CreatedBy                TUserId,
    ProcessedFlag            TFlag,
    SortOrder                TSortOrder,
    InputRecordId            TRecordId,

    RecordId                 TRecordId      identity (1,1) not null
);

Grant References on Type:: TLPNDetails  to public;

Go
