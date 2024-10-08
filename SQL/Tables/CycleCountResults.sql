/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/29  VS      CycleCountResults: Added new column TransactionDate for Performance improvement (HPI-2180)
  2012/08/10  AY      CycleCountResults: Added PrevLPNs, NumLPNs
  2012/01/20  YA      CycleCountResults: Added SKUVariance.
  2011/12/29  YA      Added table 'CycleCountResults'.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: CycleCountResults

  This table holds the results of each Cycle count, the cycle count itself could be
  accepted or rejected, but for purpose of history all of those are saved in this table.

  Fields:

  PrevInnerPacks/Qty    Count of InnerPacks and Quantity prior to the CC.
  InnerPacks1/Quantity1 Count of IPs/Qty at the end of the first count. If the first
                        count is the final count, these values would be null
  FinalInnerPacks/Qty   Count of the final inner packs and qty. Final count does not
                        mean that the CC has been accepted
------------------------------------------------------------------------------*/
Create Table CycleCountResults (
    RecordId                 TRecordId      identity (1,1) not null,

    TaskId                   TRecordId,
    TaskDetailId             TRecordId,
    BatchNo                  TTaskBatchNo,

    LPNId                    TRecordId,
    LPN                      TLPN,

    LocationId               TRecordId,
    PrevLocationId           TRecordId,
    Location                 TLocation,
    PrevLocation             TLocation,
    LocationType             TTypeCode,
    PickZone                 TZoneId,

    PalletId                 TRecordId,
    PrevPalletId             TRecordId,
    Pallet                   TPallet,
    PrevPallet               TPallet,

    SKUId                    TRecordId,
    SKU                      TSKU,

    PrevLPNs                 TCount,
    NumLPNs                  TCount,

    PrevInnerPacks           TQuantity,
    PrevQuantity             TQuantity,

    NewInnerPacks            TQuantity, -- deprecated, do not use - will be dropped after new procedures are migrated
    NewQuantity              TQuantity, -- deprecated, do not use - will be dropped after new procedures are migrated

    InnerPacks1              TQuantity,
    Quantity1                TQuantity,

    FinalInnerPacks          as NewInnerPacks, -- temporary until the above fields are deprecated
    FinalQuantity            as NewQuantity,   -- temporary until the above fields are deprecated
    CCResolution             TTypeCode,

    SKUVariance              as (case when (PrevQuantity = 0)                then 'N' /* New SKU in Location */
                                      when (NewQuantity  = 0)                then 'M' /* SKU Misplaced */
                                      when (PrevQuantity - NewQuantity <> 0) then 'Q' /* Change in Quantity */
                                 end),
    TransactionDate          as convert(date, CreatedDate),

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId
);

create index ix_CCResults_CreateDate             on CycleCountResults (CreatedDate);
create index ix_CCResults_TransDate              on CycleCountResults (TransactionDate) Include (TaskDetailId, TaskId, LocationType, SKUId, SKUVariance, BatchNo, BusinessUnit);
create index ix_CCResults_BatchNo                on CycleCountResults (BatchNo) Include (TaskDetailId, TaskId, LocationType, SKUId, SKUVariance, BusinessUnit);

Go
