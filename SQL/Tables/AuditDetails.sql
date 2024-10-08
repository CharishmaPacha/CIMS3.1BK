/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/22  AY      AuditDetails: Added more fields (CID-1042)
  2019/10/02  AY      AuditDetails: Added fields and ix_AuditDetails_SKUId (CID-1042)
  2019/09/18  RKC     AuditDetails: Added Table (CID-1042)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: AuditDetails: Contains details of each Audit entry so that it can be
  selected by SKU
------------------------------------------------------------------------------*/
Create Table AuditDetails (
    AuditDetailId            TRecordId      identity (1,1) not null,
    AuditId                  TRecordId,

    SKUId                    TRecordId,
    SKU                      TSKU,
    LPNId                    TRecordId,
    LPN                      TLPN,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    WaveId                   TRecordId,
    WaveNo                   TPickBatchNo,
    ToLPNId                  TRecordId,
    ToLPN                    TLPN,
    LocationId               TRecordId,
    Location                 TLocation,
    ToLocationId             TRecordId,
    ToLocation               TLocation,
    PalletId                 TRecordId,
    Pallet                   TPallet,
    ReceiverId               TRecordId,
    ReceiptId                TRecordId,
    TaskId                   TRecordId,
    TaskDetailId             TRecordId,
    PrevInnerPacks           TInnerPacks,
    InnerPacks               TInnerPacks,
    PrevQuantity             TQuantity,
    Quantity                 TQuantity,

    Warehouse                TWarehouse,
    ToWarehouse              TWarehouse,
    Ownership                TOwnership,
    ToOwnership              TOwnership,

    CreatedDate              TDateTime      default current_timestamp,
    CreatedOn                As (cast(CreatedDate as date)),

    constraint pkAuditDetails_AuditDetailId PRIMARY KEY (AuditDetailId)
    -- constraint fkAuditDetails_AuditId       FOREIGN KEY (AuditId)
    --   REFERENCES AuditTrail (AuditId),
);

create index ix_AuditDetails_SKUId                on AuditDetails (SKUId, CreatedOn) Include (AuditId);
/* used by sp_Productivity procedures */
create index ix_AuditDetails_AuditIdOthers        on AuditDetails (AuditId) Include (WaveId, OrderId, LocationId, PalletId, LPNId, TaskId, TaskDetailId, SKUId, Quantity);

Go
