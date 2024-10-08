/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/01/18  OK      Added TCCSummaryInfo (GNC-1408)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
Cycle Count Table Domains
------------------------------------------------------------------------------*/
/* Table Type to use for summarizing CycleCount statistics */
Create Type TCCSummaryInfo as Table (
    RecordId                 TRecordId      identity (1,1),
    LPNId                    TRecordId,
    LPN                      TLPN,
    SKUId                    TRecordId,
    SKU                      TSKU,
    Pallet                   TPallet,
    PalletId                 TRecordId,
    PrevLPNs                 TCount         DEFAULT 0,
    NumLPNs                  TCount         DEFAULT 0,
    LPNPrevLocation          TLocation,
    LPNStatus                TStatus,
    PreviousInnerPacks       TInnerpacks    DEFAULT 0,
    PreviousQty              TQuantity,
    NewInnerPacks            TInnerpacks    not null DEFAULT 0,
    NewQty                   TQuantity,
    QtyChange                as NewQty - PreviousQty,
    PalletScan               TFlag Default 'N',
    Deleted                  TFlag,
    SortSeq                  TSortSeq
);

Grant References on Type:: TCCSummaryInfo to public;

Go
