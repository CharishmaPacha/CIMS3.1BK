/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/30  RKC     LPNs & Pallets: Add ModifiedOn computed column and index (CIMS-3118)
  2020/06/18  VS      Pallets: Added ix_Pallets_Load index (S2GCA-1148)
  2020/02/20  AY      Pallets: Added SKU, SKU1..5
  2020/02/18  MS      Pallets: Added ReceiverNumber & ReceiptNumber (JL-104)
  2019/01/22  RT      Pallets: new field PalletSeqNo (S2GMI-76)
  2019/01/18  OK      Pallets: Introduced new fields DestZone and DestLocation (CID-38)
  2018/08/04  AY      Pallets: Added TaskId (OB2-474)
  2017/12.03  TD      Locations:Added fields LocationClass,MaxPallets,MaxLPNs,MaxInnerPacks,
  2015/10/23  AY      Pallets: Added PutawayClass and PickingClass.
  2015/08/14  AY      LPNs & Pallets: Added PrintFlags.
  2013/10/24  TD      Pallets: Added new fields.
  2013/05/12  AY      Pallets: Added PackingByUser
  2012/10/03  SP      Pallets:Added Archived field.
  Pallets: Added indices by LocationId, PickBatchId Changed unique index to include BusinessUnit
  2012/06/20  PK      Pallets: Added Ownership, Warehouse.
  PalletType, Pallets.Status default value to Empty
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Pallets

  PrintFlags - used to indicate the types of labels already printed for the LPN

  PutawayClass - F - Full Pallet, P - Partial Pallet, M - Mixed Pallet
  PickingClass - for future use.

  CustPO: Multiple LPNs on the Pallet may be for various Orders, but they could
          all be for same CustPO, so we need CustPO at the Pallet level.
------------------------------------------------------------------------------*/
Create Table Pallets (
    PalletId                 TRecordId      identity (1,1) not null,

    Pallet                   TPallet        not null,
    Status                   TStatus        not null default 'E',  /* Empty */
    PalletType               TTypeCode      not null default 'I',  /* Inventory */

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    NumLPNs                  TCount         not null default 0,
    InnerPacks               TInnerPacks    not null default 0,
    Quantity                 TQuantity      not null default 0,

    Ownership                TOwnership,    /* Inventory Owner */
    Warehouse                TWarehouse,

    LocationId               TRecordId,
    OrderId                  TRecordId,
    ShipToId                 TShipToId,
    CustPO                   TCustPO,
    ShipToStore              TShipToStore,
    ShipmentId               TShipmentId    CHECK(ShipmentId >= 0) default 0,
    LoadId                   TLoadId        CHECK(LoadId >= 0)     default 0,
    PalletSeqNo              TInteger,      /* Pallet Seq No of each pallet on a Load */
    TrackingNo               TTrackingNo,

    Weight                   TWeight,
    Volume                   TVolume,

    PickBatchId              TRecordId      default 0,
    PickBatchNo              TPickBatchNo,
    PackingByUser            TUserId,
    TaskId                   TRecordId,

    PrintFlags               TPrintFlags,

    PutawayClass             TPutawayClass,
    PickingClass             TPickingClass,
    DestZone                 TLookupCode,
    DestLocation             TLocation,

    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,
    ReceiverId               TRecordId,
    ReceiverNumber           TReceiverNumber,

    Reference                TReference,   /* Temporary usage field */

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    ModifiedOn               As cast (ModifiedDate as date),

    constraint pkPallets_PalletId PRIMARY KEY (PalletId),
    constraint ukPallets_Pallet   UNIQUE (Pallet, BusinessUnit)
);

create index ix_Pallets_SKU                      on Pallets (SKUId, Status);
create index ix_Pallets_Location                 on Pallets (LocationId, Status);
create index ix_Pallets_WaveId                   on Pallets (PickBatchId) Include (Status, PalletType);
create index ix_Pallets_WaveNo                   on Pallets (PickBatchNo) Include (PalletType, Status);
create index ix_Pallets_Status                   on Pallets (Status, PalletType) Include (Pallet, PalletId, LocationId, PickBatchId);
create index ix_Pallets_Archived                 on Pallets (Archived, Status) Include (Pallet, PalletId, PalletType, LocationId, ModifiedOn);
create index ix_Pallets_ReceiptNumber            on Pallets (ReceiptNumber, BusinessUnit) Include (Archived, ReceiptId);
create index ix_Pallets_ReceiptId                on Pallets (ReceiptId) Include (Archived, ReceiptNumber);
/* Used in PalletShipment */
create index ix_Pallets_Load                     on Pallets (LoadId) Include (PalletId, Status);

Go
