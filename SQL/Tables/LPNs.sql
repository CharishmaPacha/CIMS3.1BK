/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/11  AY      ix_LPNs_LocationId, ix_LPNs_DestLocation: Optimized for LocationCounts (HA-3078)
  2021/04/21  PK/YJ   LPNs: Revised ix_LPNs_Archived, ix_LPNs_Warehouse, ix_LPNs_UDF3: ported changes from prod onsite (HA-2678)
  2021/04/14  OK      LPNs: Added not null constraint for Inventory class fields (HA-2404)
  2020/11/05  MS      LPNs: Added UDF11 to UDF20 (JL-294)
  2020/06/30  RKC     LPNs & Pallets: Add ModifiedOn computed column and index (CIMS-3118)
  2020/05/31  TK      LPNs: Added ix_LPNs_InventoryClass (HA-732)
  2020/04/01  TK      LPNs: InventoryClass defaulted to empty string (HA-84)
  LPNs: Added Inventory Classes (HA-77)
  2020/03/01  AY      LPNs: Added computed fields LPNWeight/LPNVolume
  2019/09/06  AY      LPNs: Added index ix_LPNs_Receiver (CID-1022)
  2019/01/23  KSK     LPNs:Added Reference field (S2GCA-461)
  2019/01/08  TD      LPNs:added HostNumLines(Interface changes)
  2018/12/18  TK      LPNs: Changed ixLPNStatus to include OrderId as well (HPI-Support)
  2018/01/31  TK      LPNs: Added DirectedQty (S2G-179)
  2017/12.03  TD      Locations:Added fields LocationClass,MaxPallets,MaxLPNs,MaxInnerPacks,
  2017/01/05  ??      LPNs: Added index ix_LPNs_ReceiptId, ix_LPNs_TrackingNo (HPI-GoLive)
  2017/01/05  AY      LPNs: Added index ix_LPNs_ReceiptId, ix_LPNs_TrackingNo (HPI-GoLive)
  2017/01/05  ??      LPNs: Added index ix_LPNs_ReceiptId, ix_LPNs_TrackingNo (HPI-GoLive)
  2016/11/02  ??      Added Index ix_LPNs_TaskId, ix_LPNs_TaskId for LPNs table (HPI-GoLive)
  2016/10/24  YJ      Added Index ixLPNArchived2 for LPNs table (HPI-GoLive)
  2016/07/29  TK      LPNs: Added Packing Group (HPI-380)
  2016/07/06  KN      LPNs: Added return Tracking No (NBD-634)
  2016/05/05  TK      LPNs: Added SKU15 fields (FB-648)
  2016/04/01  VM      LPNs: Added TaskId (NBD-291)
  2015/08/14  AY      LPNs & Pallets: Added PrintFlags.
  2014/12/09  PKS     LPNs: Added AlternateLPN
  2014/12/09  TD      LPNs: Added NumLines.
  2014/09/30  PK      LPNs: Added ReasonCode
  LPNs: Added LastMovedDate
  2014/03/24  AY      LPNs: Added PutawayClass, ExpiresInDays
  2014/02/28  TD      LPNs: Added DestZone and DestLocation.
  2014/01/28  AY      LPNs: Added ExpiryDate
  2013/12/16  TD      LPNs: Added ReservedQty.
  2013/12/09  TD      LPNs: Added PickBatchNo, PickBatchId.
  2013/12/07  AY      LPNs: Added Lot
  2012/10/07  AA      LPNs: Added new indices ixLPNShipment, ixLPNLoad
  Revised ukLPNs_BusinesssUnitLPN index to be able to select by LPN
  2012/08/06  AY      LPNs: Changed index ixLPNSKU for performance of Order Preprocess
  2012/06/30  AY      LPNs: Added UCCBarcode
  2012/06/18  TD      Added Loadnumber to  LPNs table.
  2012/02/23  AY/VM   Added indices ixLPNWarehouse, ixLPNOnhandStatus to LPNs table
  2011/10/31  AY      LPNs: Added PackageSeqNo
  2011/08/05  AY      LPNs: Added Pallet, Location, SKU along with Id fields to
  2011/07/29  VM      LPNs.DestWarehouse can be nullable for Temp labels, hence removed not null
  2011/07/25  AY      Added LPNDetails.LastPutawayDate, LPNs.Visible
  in LPNs Table.
  2011/01/21  VM      LPNs, LPNDetails - corrected OnhandStatus default value.
  2010/10/28  VM      LPNs: LPN is not alone unique - BusinessUnit & LPN together are unique
  LPNs, LPNDetails: CoE => CoO
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: LPNs

  PrintFlags - used to indicate the types of labels already printed for the LPN

  AlternateOrderId &
  AlternatePickTicket - This is required for Kit LPNs. When we make Kits, we will be
                        creating Kit LPNs upfront for each order. We can keep track of
                        the Kit LPNs created for each order by updating AlternateOrderId
------------------------------------------------------------------------------*/
Create Table LPNs (
    LPNId                    TRecordId      identity (1,1) not null,

    LPN                      TLPN           not null,
    LPNType                  TTypeCode      not null default 'C' /* Carton */,
    Status                   TStatus        not null default 'N' /* New */,
    OnhandStatus             TStatus        not null default 'U' /* Unavailable */,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    InnerPacks               TInnerPacks    not null default 0,
    Quantity                 TQuantity      not null default 0,
    ReservedQty              TQuantity      default 0,
    DirectedQty              TQuantity      default 0,
    NumLines                 TCount         default 0,
    HostNumLines             TCount         default 0,

    PalletId                 TRecordId,
    Pallet                   TPallet,
    LocationId               TRecordId,
    Location                 TLocation,

    ReceiverId               TRecordId,
    ReceiverNumber           TReceiverNumber,
    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,

    OrderId                  TRecordId,
    PickTicketNo             TPickTicket,
    SalesOrder               TSalesOrder,
    PackageSeqNo             TInteger,   /* the sequence number of this package within the order */

    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,

    TaskId                   TRecordId,

    ShipmentId               TShipmentId CHECK(ShipmentId >= 0) default 0,
    LoadId                   TLoadId     CHECK(LoadId >= 0)     default 0,
    LoadNumber               TLoadNumber,
    BoL                      TBoL,
    ASNCase                  TASNCase,
    TrackingNo               TTrackingNo,
    ReturnTrackingNo         TTrackingNo,
    UCCBarcode               TBarcode,

    DestWarehouse            TWarehouse,
    DestZone                 TLookupCode,
    DestLocation             TLocation,
    PutawayClass             TPutawayClass,
    PickingClass             TPickingClass,
    ReasonCode               TReasonCode,
    Reference                TReference,
    SorterName               TDescription,

    ExpiryDate               TDate,
    ExpiresInDays            As datediff(d, getdate(), ExpiryDate),
    ReceivedDate             TDateTime,
    LastMovedDate            TDateTime,
    PickedDate               TDateTime,

    EstimatedWeight          TWeight        default 0.0,
    EstimatedVolume          TVolume        default 0.0,
    ActualWeight             TWeight        default 0.0,
    ActualVolume             TVolume        default 0.0,

    InventoryStatus          TInventoryStatus not null default 'N' /* Normal Stock */,
    Ownership                TOwnership,  /* Inventory Owner */
    CoO                      TCoO,
    Lot                      TLot,
    InventoryClass1          TInventoryClass not null default '',
    InventoryClass2          TInventoryClass not null default '',
    InventoryClass3          TInventoryClass not null default '',
    CartonType               TCartonType,
    PackingGroup             TCategory,
    ExportFlags              TFlags         default '',
    PrintFlags               TPrintFlags,

    AlternateLPN             TLPN,
    AlternateOrderId         TRecordId,
    AlternatePickTicket      TPickTicket,

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
    UDF11                    TUDF,
    UDF12                    TUDF,
    UDF13                    TUDF,
    UDF14                    TUDF,
    UDF15                    TUDF,
    UDF16                    TUDF,
    UDF17                    TUDF,
    UDF18                    TUDF,
    UDF19                    TUDF,
    UDF20                    TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    UniqueId                 TLPN,
    Visible                  as case when LPNType = 'L' and (SKUId is null or SKUId = 0) and (Quantity = 0) then
                                  'N'
                                else
                                  'Y'
                                end,
    LPNWeight                as coalesce(nullif(ActualWeight, 0), nullif(EstimatedWeight, 0), 0),
    LPNVolume                as coalesce(nullif(ActualVolume, 0), nullif(EstimatedVolume, 0), 0),
    ModifiedOn               as cast (ModifiedDate as date),

    constraint pkLPNs_LPNId            PRIMARY KEY (LPNId),
    constraint ukLPNs_BusinessUnitLPN  UNIQUE (LPN, BusinessUnit, UniqueId)
);

/* ReservedQty, Ownership helpful for vwLocationsToReplenish */
/* LPNWeight, LPNVolume helpful in Locations_UpdateCounts */
create index ix_LPNs_LocationId                  on LPNs (LocationId, Onhandstatus, Status) Include (LPNId, LPN, SKUId, InnerPacks, Quantity, ReservedQty, DirectedQty, PalletId, LPNType, BusinessUnit, Ownership, Archived, LPNWeight, LPNVolume);
create index ix_LPNs_OrderId                     on LPNs (OrderId, Status) Include (InnerPacks, Quantity, LPNId, LPN, ShipmentId, LoadId, LPNType, OnhandStatus, PackageSeqNo, SKUId);
/* Packing group, SKUId needed for Picking to identify the cart position to pick to, LoadId is needed for validate to ship */
create index ix_LPNs_PalletId                    on LPNs (PalletId, Status, Onhandstatus, BusinessUnit) Include (Pallet, Quantity, OrderId, LPNId, LPN, LPNType, SKUId, PackingGroup, TaskId, LoadId);
create index ix_LPNs_Pallet                      on LPNs (Pallet, Status, Quantity, Onhandstatus, BusinessUnit) Include (OrderId, LPNId, LPN);
create index ix_LPNs_SKUId                       on LPNs (SKUId, Archived, OnhandStatus, DestWarehouse) Include(LPNType, Status, Quantity);
/* vwLPNs has Status <> 'I' and by default we select Archived = 'N' and so to improve LPN page performace, this has been changed */
create index ix_LPNs_Archived                    on LPNs (Archived, Status, DestWarehouse, Quantity, BusinessUnit) Include (LPNId, LPN, LPNType, ModifiedOn, OnhandStatus, PalletId);
create index ix_LPNs_Warehouse                   on LPNs (DestWarehouse, OnhandStatus, Status, BusinessUnit, Quantity) where (Archived='N')
create index ix_LPNs_OnhandStatus                on LPNs (OnhandStatus, BusinessUnit) Include(LPNId);
create index ix_LPNs_ReceiptId                   on LPNs (ReceiptId, BusinessUnit) Include (LPNId, PalletId, Status);
create index ix_LPNs_Shipment                    on LPNs (ShipmentId, OrderId) Include (Status, InnerPacks, Quantity, LPNId, LPN, PalletId, LPNWeight);
create index ix_LPNs_Load                        on LPNs (LoadId) Include (LPNId, LPNType, Status, InnerPacks, Quantity, PalletId, LPNWeight, LPNVolume);
/* Enhanced to add LastMovedDate to show in Putaway Dashboard */
create index ix_LPNs_Status                      on LPNs (Status, BusinessUnit) Include (LPNId, LPN, LPNType, OnhandStatus, InnerPacks, Quantity, LastMovedDate, ReceiverNumber, OrderId, PickBatchId, DestWarehouse);
create index ix_LPNs_TaskId                      on LPNs (TaskId, Status) Include (Archived, LPN, LPNId);
/* Used in pr_Allocation_InsertShipLabels etc. */
create index ix_LPNs_WaveId                      on LPNs (PickBatchId, Status, Quantity) Include (PickBatchNo, LPNId, LPN, OnhandStatus, InnerPacks, Location, LPNType, TrackingNo, UCCBarcode);
/* Used in pr_Location_SetStatus */
create index ix_LPNs_DestLocation                on LPNs (DestLocation, BusinessUnit) Include (LPNId, LPN, OnhandStatus, Status, InnerPacks, Quantity, Location, PalletId, LPNWeight, LPNVolume);
create index ix_LPNs_PickBatchNo                 on LPNs (PickBatchNo) Include (OnhandStatus, Status, InnerPacks, Quantity);
create index ix_LPNs_AlternateLPN                on LPNs (AlternateLPN, BusinessUnit) Include (SKUId, LPNId, LocationId);
create index ix_LPNs_TrackingNo                  on LPNs (TrackingNo, BusinessUnit) Include (LPNId);
create index ix_LPNs_UCCBarcode                  on LPNs (UCCBarcode, LPN) Include (Archived, BusinessUnit, LPNId);
create index ix_LPNs_Receiver                    on LPNs (ReceiverNumber, LPN) include (InventoryStatus, Status, ReceiptId);
create index ix_LPNs_ASNCase                     on LPNs (ASNCase, BusinessUnit) include (LPNId);
/* needed for Allocation  - Preallocated cases */
create index ix_LPNs_Lot                         on LPNs (Lot, Status) Include (LPNId);
create index ix_LPNs_ReceiverId                  on LPNs (ReceiverId) Include (LPNId, ReceiptId, Status);
create index ix_LPNs_InventoryClass              on LPNs (SKUId, InventoryClass1, InventoryClass2, InventoryClass3) Include(LPNId, LPNType, Status, Quantity);

Go
