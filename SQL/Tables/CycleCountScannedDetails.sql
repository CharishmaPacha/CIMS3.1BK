/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/09  SPP     Added new table for CycleCountScannedDetails (HA-2881)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: CycleCountScannedDetails
------------------------------------------------------------------------------*/
Create Table CycleCountScannedDetails (
    RecordId                 TRecordId      identity (1,1) not null,

    LocationId               TRecordId,
    Location                 TLocation,

    TaskId                   TRecordId,
    TaskDetailId             TRecordId,
    BatchNo                  TPickBatchNo,

    ScannedSKUId             TRecordId,
    ScannedSKU               TSKU,

    ScannedLPNId             TRecordId,
    ScannedLPN               TLPN,

    ScannedPalletId          TRecordId,
    ScannedPallet            TPallet,

    NumLPNs                  TCount,
    ScannedQty               TQuantity,
    ScannedInnerPacks        TQuantity,

    LPNPrevLocationId        TRecordId,
    LPNPrevLocation          TLocation,
    PrevQuantity             TQuantity,
    PrevInnerPacks           TQuantity,

    LPNStatus                TStatus,
    
    constraint pkCycleCountScannedDetails_RecordId PRIMARY KEY (RecordId)
)

Go
