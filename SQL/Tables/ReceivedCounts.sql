/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/18  TK      ReceivedCounts: Combination of LPNDetailId & ReceiptDetailId should be unique (HA-222)
  2020/04/09  MS      ReceivedCounts: Removed not null for ReceiptLine column (HA-165)
  2018/06/05  PK/AY   Added ReceivedCounts (S2G-879)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: ReceivedCounts: Table introduced to keep track of the received counts
    for RH/RD and Receiver. Earlier, when inventory is received and the LPN putaway
    to Picklane, we would delete the from LPN line and so the amount received
    is not accurate anymore. Likewise, we could not depend upon the exports as
    the tranactions could be purged after which the received counts are wrong.
------------------------------------------------------------------------------*/
Create Table ReceivedCounts (
    RecordId                 TRecordId      identity (1,1) not null,

    ReceiptId                TRecordId      not null,
    ReceiptNumber            TReceiptNumber not null,
    ReceiverId               TRecordId,
    ReceiverNumber           TReceiverNumber,

    ReceiptDetailId          TRecordId      not null,
    ReceiptLine              TReceiptLine,

    Status                   TStatus        default 'A' not null, -- A Active, V - Voided

    PalletId                 TRecordId,
    Pallet                   TPallet,
    LocationId               TRecordId,
    Location                 TLocation,

    LPNId                    TRecordId      not null,
    LPN                      TLPN           not null,
    LPNDetailId              TRecordId      not null,

    SKUId                    TRecordId      not null,
    SKU                      TSKU           not null,

    InnerPacks               TInnerPacks    not null default 0,
    Quantity                 TQuantity      not null,
    UnitsPerPackage          TUnitsPerPack  not null default 0,

    Ownership                TOwnership,
    Warehouse                TWarehouse,
    ReceivedDate             As cast(CreatedDate as date),

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    CreatedBy                TUserId,
    ModifiedDate             TDateTime,
    ModifiedBy               TUserId,

    constraint pkReceivedCounts_RecordId              PRIMARY KEY (RecordId),
    constraint ukReceivedCounts_RNRIdRDIdLIdLDIdSIDBU UNIQUE (LPNDetailId, ReceiptDetailId)
);

/* For counts on Receipt Header, ReceiptDetail and Receiver */
create index ix_ReceivedCounts_Receipt           on ReceivedCounts (ReceiptId, ReceiptDetailId) Include (LPNId, LPNDetailId, InnerPacks, Quantity, Status);
create index ix_ReceivedCounts_Receiver          on ReceivedCounts (ReceiverId) Include (ReceiptId, LPNId, LPNDetailId, InnerPacks, Quantity);
/* For dashboard */
create index ix_ReceivedCounts_RecvDate          on ReceivedCounts (ReceivedDate, Ownership, Warehouse) Include (LPNId);

Go
