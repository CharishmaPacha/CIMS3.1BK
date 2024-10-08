/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/04  TK      LPNDetails: Added InventoryKey (FBV3-810)
  2021/08/30  AY      LPNDetails: Added Archived flag and index (HA-3124)
  2020/12/23  AY      LPNDetails: ix_LPNDetails_OnhandStatus enhanced (HA-1781)
  2020/04/26  TK      LPNDetails: Added Reference (HA-171)
  2020/04/14  TK      LPNDetails: Added InventoryClass (HA-84)
  2018/01/17  AY      LPNDetails: Remove constraint ukLPNDetails_LPNIdLine and remove default on LPNLine (S2GMI-77)
  2018/03/20  AY      LPNDetails: Added AllocableInnerPacks
  2018/01/24  TK      LPNDetails: Added ReservedQty (S2G-152)
  2017/10/03  AY      LPNDetails: Added ReplenishPickTicket (HPI-1435)
  2017/02/18  AY      LPNDetails: Updated ix_LPNDetails_LPNId (HPI-GoLive)
  2017/02/18  ??      LPNDetails: Added ix_LPNDetails_LPNId2 (HPI-GoLive)
  LPNDetails: Added index ix_LPNDetails_ReceiptId
  2015/03/24  TD      LPNDetails:Added ReplenishOrderId, ReplenishOrderDetailId.
  LPNDetails: Added Indexes ixLPNDetailLPNId, ixLPNDetailOrderId
  2013/01/03  YA      Added indexes ixLPNStatus, ixLPNArchivedStatus on LPN and ixLPNDetailOnHandStatus on LPNDetails.
  2011/10/20  AY      LPNDetails: Added PickedBy, PickedDate, PackedBy, PackedDate and ReferenceLocation fields
  2011/09/30  AY      LPNDetails: Added index for Onhand Inventory
  2011/07/25  AY      Added LPNDetails.LastPutawayDate, LPNs.Visible
  2011/01/21  VM      LPNs, LPNDetails - corrected OnhandStatus default value.
  2010/11/26  PK      LPNDetails: Added OnhandStatus Field
  LPNs, LPNDetails: CoE => CoO
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: LPNDtls

   Until we have Audit trail, we have to keep track of Picked/Packed Details
   at LPNDetail level. Likewise, we have to keep track of Picked or Putaway Location
   on the LPNDetail.
------------------------------------------------------------------------------*/
Create Table LPNDetails (
    LPNDetailId              TRecordId      identity (1,1) not null,

    LPNId                    TRecordId      not null,
    SKUId                    TRecordId,
    OnhandStatus             TStatus        not null default 'U' /* Unavailable */,
    InnerPacks               TInnerPacks    not null default 0,
    Quantity                 TQuantity      not null default 0,
    ReservedQty              TQuantity      not null default 0,
    UnitsPerPackage          TUnitsPerPack  not null default 0,

    ReceivedUnits            TQuantity      not null default 0,

    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,

    OrderId                  TRecordId,
    OrderDetailId            TRecordId,

    ReplenishOrderId         TRecordId,
    ReplenishPickTicket      TPickTicket,
    ReplenishOrderDetailId   TRecordId,

    Weight                   TWeight        not null default 0.0,
    Volume                   TVolume        default 0.0,
    Lot                      TLot,
    CoO                      TCoO,
    /* Inventory Class not used for now */
    InventoryClass1          TInventoryClass      default '',
    InventoryClass2          TInventoryClass      default '',
    InventoryClass3          TInventoryClass      default '',
    SerialNo                 TSerialNo,

    LastPutawayDate          TDateTime,
    ReferenceLocation        TLocation,
    PickedBy                 TUserId,
    PickedDate               TDateTime,
    PackedBy                 TUserId,
    PackedDate               TDateTime,

    Reference                TReference,   /* Temporary usage field */
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    LPNLine                  TDetailLine    default 0, -- deprecated, do not use it.

    Archived                 TFlag          default 'N',
    SourceSystem             TName          default 'HOST',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    InventoryKey             TInventoryKey,
    AllocableInnerPacks      as case
                              when (OnhandStatus = 'PR'/* Pending Reservation */) then 0
                              when (InnerPacks = 0) or (Quantity = 0) then 0
                              else (Quantity - ReservedQty) / (Quantity/InnerPacks)
                            end,
    AllocableQty             as case
                              when (OnhandStatus = 'PR'/* Pending Reservation */) then 0
                              else Quantity - ReservedQty
                            end,

--  InventoryKey            as fn_BuildInventoryKey (SKUId, Warehouse, Ownership, Lot, IC1, IC2, IC3)


    constraint pkLPNDetails_LPNDetailId PRIMARY KEY (LPNDetailId)
);

create index ix_LPNDetails_LPNId                 on LPNDetails (LPNId, OrderDetailId) Include (LPNDetailId, InnerPacks, OnhandStatus, Quantity, ReceiptDetailId, ReceivedUnits, ReplenishOrderId, SKUId, OrderId);
create index ix_LPNDetails_SKU                   on LPNDetails (SKUId, OnhandStatus) Include(LPNId, BusinessUnit, InnerPacks, Quantity, OrderDetailId, LPNDetailId, UnitsPerPackage);
/* for Onhand inventory */
create index ix_LPNDetails_OnhandStatus          on LPNDetails (OnhandStatus, LPNId) Include (LPNDetailId, InnerPacks, Quantity, SKUId, BusinessUnit, ReservedQty, AllocableQty);
/* LPNId-OrderDetailId needed to evaluate task dependencies - so added OrderDetailId */
create index ix_LPNDetails_OrderId               on LPNDetails (OrderId, OrderDetailId, SKUId) Include (LPNId, InnerPacks, Quantity, ReceiptDetailId, OnhandStatus);
create index ix_LPNDetails_ReceiptId             on LPNDetails (ReceiptId) Include (LPNId, Quantity, ReceiptDetailId, ReceivedUnits)
create index ix_LPNDetails_Replenish             on LPNDetails (ReplenishOrderId, ReplenishOrderDetailId, OnhandStatus);
create index ix_LPNDetails_Archived              on LPNDetails (Archived, SKUId, OnhandStatus) Include (LPNId) where (Archived = 'N');

Go
