/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/26  TK      TInventoryTransfer: Added more fields required for BulkMove action (HA-1115)
  2020/07/11  TK      TInventoryTransfer: Added ProcessFlag, ActivityType & Comment (HA-1115)
  2020/06/22  TK      Added TInventoryTransfer
  Create Type TInventoryTransfer as Table (
  Grant References on Type:: TInventoryTransfer  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TInventoryTransfer as Table (
    LPNId                TRecordId,
    LPN                  TLPN,
    LPNType              TTypeCode,
    LPNStatus            TStatus,
    LPNOnhandStatus      TStatus,

    LPNDetailId          TRecordId,
    NewLPNId             TRecordId,
    NewLPN               TLPN,
    NewLPNDetailId       TRecordId,

    PalletId             TRecordId,
    Pallet               TPallet,
    NewPalletId          TRecordId,
    NewPallet            TPallet,
    LocationId           TRecordId,
    Location             TLocation,
    NewLocationId        TRecordId,
    NewLocation          TLocation,
    NewLocationType      TTypeCode,
    NewStorageType       TTypeCode,

    OrderId              TRecordId,
    PickTicket           TPickTicket,
    WaveId               TRecordId,
    WaveNo               varchar(30), -- TWaveNo is not defined yet
    OrderDetailId        TRecordId,
    SKUId                TRecordId,
    SKU                  TSKU,
    NewSKUId             TRecordId,
    NewSKU               TSKU,
    Quantity             TQuantity,

    InventoryClass1      TInventoryClass,
    NewInventoryClass1   TInventoryClass,
    InventoryClass2      TInventoryClass,
    NewInventoryClass2   TInventoryClass,
    InventoryClass3      TInventoryClass,
    NewInventoryClass3   TInventoryClass,

    Lot                  TLot,
    NewLot               TLot,
    Ownership            TOwnership,
    NewOwnership         TOwnership,
    Warehouse            TWarehouse,
    NewWarehouse         TWarehouse,
    SourceSystem         TName,

    ActivityType         TActivityType,
    Comment              TVarchar,
    ProcessFlag          TFlags  default 'N',  /* N - Not yet processed, Y - Processed, I - Ignored, E - Error */

    RecordId             TRecordId identity(1,1)
);

Grant References on Type:: TInventoryTransfer  to public;

Go
