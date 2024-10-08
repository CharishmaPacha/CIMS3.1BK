/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/24  TK      PickBatches: IsBulkPull defaulted to 'N' (BK-720)
  2021/11/15  TK      PickBatches: BulkOrderId & IsBulkPull (FBV3-390)
  2021/07/20  TD      PickBatches:Added ix_PickBatches_RecordId(HA-Support)
  2021/05/22  PKK     PickBatches: Added MaxUnitsPerCarton & CartonizationModel (HA-2813)
  2020/11/09  AJM     PickBatches: For PrintStatus field changed datatype from TPrintStatus to TStatus (CIMSV3-1201)
  2020/10/01  RBV/TK  PickBatches: Added PickMethod field (CID-1488)
  2020/07/30  RV      PickBatches: Added PrintStatus (S2GCA-1199)
  2020/06/30  RKC     PickBatches: Add ModifiedOn computed column and index (CIMS-3118)
  2020/05/29  TK      PickBatches: Added NumTasks (HA-691)
  2020/06/23  VS      PickBatches: Added CreatedOn field and index (FB-2043)
  2020/05/22  AY      PickBatches: Added LPN* fields, made WaveId primary key of the table
  2020/05/01  RT      PickBatches: Included InvAllocationModel (HA-312)
  2019/07/11  AJ      PickBatches: Added NumLPNsToPA (CID-735)
  2019/01/24  RIA     PickBatches: Added PickSequence field (OB2-796)
  2018/03/09  AY      PickBatches: Added WCSStatus, WCSDependency and ColorCode fields
  2018/02/23  TK      PickBatches: If DependencyFlags is defaulted to 'N' then user would be
  2018/02/01  TK      PickBatches: Added DependencyFlags (S2G-179)
  2016/10/08  TK      PickBatchRules & PickBatches: Added WaveRuleGroup (HPI-838)
  2016/09/10  TD      PickBatches:Added account (HPI-603)
  2015/07/20  AY      PickBatches: Added ReleaseDateTime
  2015/07/18  AY      PickBatches: Added AccountName
  2014/03/24  AY      PickBatches: Changed PercentCompleted to computed field
  2013/12/20  AY      PickBatches: Added NumPicks, NumPicksCompleted
  2013/11/13  AY      PickBatches: Added NumPallets, NumInnerPacks.
  2013/09/26  TD      PickBatches: Added new column AllocateFlags and IsAllocated.
  2013/03/21  TD      Added PickBatches.TotalWeight, CancelDate, TotalVolume
  2013/01/31  AY      PickBatches, PickBatchRules: Added Category fields.
  2012/10/11  AY      Added PickBatches.PickDate, ShipDate and Description.
  2012/09/13  AY      Added PickBatches.NumLPNs
  2012/07/10  NY      Added PickBatches.Warehouse
  2012/03/16  AY      PickBatches: Add new field AssignedTo
  2011/11/25  AY      PickBatches: Changed index ixPickBatchesPickZone to include only current batches
  2011/10/26  AY      PickBatches: Added new field Archived.
  2011/08/04  PK      Changed Field Names in PickBatches SoldTo to SoldToId and
  2011/07/26  YA      Added Indexes 'ixPickBatchesStatus',
  'ixPickBatchesPickZone' & 'ixPickBatchRulesStatus'
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: PickBatches

 PickMethod: 6River, CIMSRF
------------------------------------------------------------------------------*/
Create Table PickBatches (
    RecordId                 TRecordId,
    WaveId                   TRecordId      identity (1,1) not null,
    WaveNo                   TWaveNo        not null,
    WaveType                 TTypeCode      not null,
    WaveStatus               TStatus        not null,
    BatchType                TTypeCode      not null,
    Status                   TStatus        not null,
    Priority                 TPriority,

    NumOrders                TCount         not null default 0,
    NumLines                 TCount         not null default 0,
    NumSKUs                  TCount         not null default 0,
    NumPallets               TCount         not null default 0,
    NumLPNs                  TCount         not null default 0,
    NumLPNsToPA              TCount         not null default 0,
    NumInnerPacks            TCount         not null default 0,
    NumUnits                 TCount         not null default 0,

    NumTasks                 TCount         default 0,
    NumPicks                 TCount         default 0,
    NumPicksCompleted        TCount         default 0,
    PercentComplete          As (case when NumPicks = 0 then 0
                                      when NumPicksCompleted >= NumPicks then 100
                                      when NumPicks > 0 then NumPicksCompleted * 100 / NumPicks
                                      else 0
                                 end),

    /* Counts of orders in various statuses */
    OrdersWaved              TCount         default 0,
    OrdersAllocated          TCount         default 0,
    OrdersPicked             TCount         default 0,
    OrdersPacked             TCount         default 0,
    OrdersLoaded             TCount         default 0,
    OrdersStaged             TCount         default 0,
    OrdersShipped            TCount         default 0,
    OrdersOpen               TCount         default 0,

    /* sum of Units in various statuses */
    UnitsAssigned            TQuantity      default 0,
    UnitsPicked              TQuantity      default 0,
    UnitsPacked              TQuantity      default 0,
    UnitsStaged              TQuantity      default 0,
    UnitsLoaded              TQuantity      default 0,
    UnitsShipped             TQuantity      default 0,

    LPNsAssigned             TQuantity      default 0,
    LPNsPicked               TQuantity      default 0,
    LPNsPacked               TQuantity      default 0,
    LPNsStaged               TQuantity      default 0,
    LPNsLoaded               TQuantity      default 0,
    LPNsShipped              TQuantity      default 0,

    TotalAmount              TMoney,
    TotalWeight              TWeight        default 0.0,
    TotalVolume              TVolume        default 0,
    MaxUnitsPerCarton        TInteger,

    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    ShipVia                  TShipVia,
    PickZone                 TZoneId,
    PickSequence             TPickSequence,
    PickTicket               TPickTicket,
    SoldToName               TName,         -- decprecated
    ShipToStore              TShipToStore,
    Account                  TAccount,
    AccountName              TName,
    CustPO                   TCustPO,

    PalletId                 TRecordId,
    Pallet                   TPallet,
    AssignedTo               TUserId,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    DropLocation             TLocation,
    PickBatchGroup           TWaveGroup,
    PickMethod               TPickMethod,

    CancelDate               TDate,
    PickDate                 TDate,
    ShipDate                 TDate,
    Description              TDescription,
    ReleaseDateTime          TDatetime,

    WCSStatus                TDescription,
    WCSDependency            TFlags,
    ColorCode                TFlags,

    Category1                TCategory,
    Category2                TCategory,
    Category3                TCategory,
    Category4                TCategory,
    Category5                TCategory,

    AllocateFlags            TFlags         default 'N', /* Not Allocated */
    IsAllocated              As (case when NumPicks > 0 then 'Y' else 'N' end),
    DependencyFlags          TFlags,
    PrintStatus              TStatus,
    InvAllocationModel       TDescription,
    CartonizationModel       TDescription,

    BulkOrderId              TRecordId,
    IsBulkPull               TFlags         default 'N',

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,

    RuleId                   TRecordId,     /* For future use */
    BatchNo                  TPickBatchNo   not null,
    WaveRuleGroup            TDescription,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as cast (CreatedDate as date),
    ModifiedOn               as cast (ModifiedDate as date),

    constraint pkPickBatches_RecordId PRIMARY KEY (WaveId),
    constraint ukPickBatches_BatchNo  UNIQUE (BatchNo, BusinessUnit)
);

create index ix_PickBatches_Status               on PickBatches (Status, BusinessUnit, BatchType);
create index ix_PickBatches_PickZone             on PickBatches (PickZone, Status, BusinessUnit) where (Archived = 'N');
create index ix_PickBatches_Warehouse            on PickBatches (Warehouse, Status, BusinessUnit) where (Archived = 'N');
create index ix_PickBatches_Archived             on PickBatches (Archived, Status, BatchNo) Include (CreatedOn, ModifiedOn) where (Archived = 'N');
create index ix_PickBatches_AllocateFlag         on PickBatches (AllocateFlags, BusinessUnit, BatchType, Status) Include (RecordId, BatchNo, Warehouse, IsAllocated);
create index ix_PickBatches_RecordId             on PickBatches (RecordId) Include (Status, WaveNo);
create index ix_PickBatches_WaveNo               on PickBatches (WaveNo, BusinessUnit) Include (WaveId, Status);

Go
