/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/25  VS      InvSnapshot: Added InitialOnhandQty and corrected OnhandQty, AvailableToSell (JLFL-98)
  2022/12/27  MS      InvSnapshot: Added Archived field (BK-981)
  2022/01/27  MS/AY   InvSnapshot: Added new Fields (HA-3328)
  2021/03/10  AY      ix_InvSnapshot_Id: Revised (HA-2243)
  2020/10/12  AY      InvSnapshot, InvComparison: Added InventoryKey (HA-1576)
  2020/08/04  AY      Revised index ix_InvSnapshot_SnapshotDate (HA-1180)
  2020/07/22  SK      InvSnapshot, InvComparison: Added columns InventoryClass (HA-1180)
  2013/09/03  VP      Added Table InvSnapshot
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InvSnapshot: Capture the snapshot of the inventory at the end of each day
   (or the beginning of each day). Through out the day, we would update the changes
   to the EOD snapshot to know the current OnhandQty

 Fields (applicable for EoD snapshot)
   AvailableQty    LPNDetail.OnhandStatus = Available
   ReservedQty     LPNDetailOnhandStatus  = Reserved
   ReceivedQty     LPN.Status = Received i.e. Not yet Putaway
   PutawayQty      Recv confirmations exported for the SnapshotDate under consideration
   AdjustedQty     InvCh exports for the date under consideration
   ShippedQty      Ship confirmations exported for the Snapshot date
   ToShipQty       Qty of Orders that are not yet reserved
   InitialOnhandQty end of the previous day OnhandQty that is in the WH
   OnhandQty       Current on hand Qty that is in the WH computed as InitialOHQ + PutawayQty + AdjustedQty - ShippedQty
   AvailableToSell OnhandQty - ToShipQty

------------------------------------------------------------------------------*/
Create Table InvSnapshot (
    RecordId                 TRecordId            identity (1,1) not null,

    SnapshotId               TRecordId,
    SnapshotDate             TDate                default getdate(),
    SnapshotDateTime         TDateTime            default current_timestamp,
    SnapshotType             TTypeCode, /* EndOfDay or Adhoc */

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    InventoryClass1          TInventoryClass      default '',
    InventoryClass2          TInventoryClass      default '',
    InventoryClass3          TInventoryClass      default '',

    UPC                      TUPC,

    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNStatus                TStatus,
    LPNOnhandStatus          TStatus,
    LPNDetailId              TRecordId,
    Reference                TReference,
    LocationId               TRecordId,
    Location                 TLocation,
    Lot                      TLot,
    Pallet                   TPallet,
    Warehouse                TWarehouse,
    Ownership                TOwnership,

    UnitsPerInnerPack        TCount,
    AvailableIPs             TCount,
    ReservedIPs              TCount,
    OnhandIPs                as coalesce(AvailableIPs, 0) + coalesce(ReservedIPs, 0),
    ReceivedIPs              TCount,
    ToShipIPs                TCount,

    AvailableQty             TQuantity,
    ReservedQty              TQuantity,
    ReceivedQty              TQuantity,
    PutawayQty               TQuantity,
    AdjustedQty              TQuantity,
    ShippedQty               TQuantity,
    ToShipQty                TQuantity,
    InitialOnhandQty         TQuantity,
    OnhandQty                as InitialOnhandQty + coalesce(PutawayQty, 0) + coalesce(AdjustedQty, 0) - coalesce(ShippedQty, 0),
    AvailableToSell          as InitialOnhandQty + coalesce(PutawayQty, 0) + coalesce(AdjustedQty, 0) - coalesce(ShippedQty, 0)- coalesce(ToShipQty, 0) - coalesce(ReservedQty, 0),

    OnhandValue              TMoney,
    InventoryKey             TKeyValue,

    IS_UDF1                  TUDF,
    IS_UDF2                  TUDF,
    IS_UDF3                  TUDF,
    IS_UDF4                  TUDF,
    IS_UDF5                  TUDF,
    IS_UDF6                  TUDF,
    IS_UDF7                  TUDF,
    IS_UDF8                  TUDF,
    IS_UDF9                  TUDF,
    IS_UDF10                 TUDF,

    SourceSystem             TName,
    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    ModifiedDate             TDateTime,

    constraint pk_InvSnapshot_RecordId PRIMARY KEY (SnapshotId, RecordId)
);

create index ix_InvSnapshot_Id                   on InvSnapshot (SnapshotId, InventoryKey, SKU) Include (RecordId, LPNId, LPNDetailId, LPN, Warehouse);
create index ix_InvSnapshot_SnapshotDate         on InvSnapshot (SnapshotDate, SnapshotType, Warehouse) Include (SnapshotId);
create index ix_InvSnapshot_SKU                  on InvSnapshot (SKU, SKU1, SKU2, SKU3, SKU4, SKU5);
create index ix_InvSnapshot_Archived             on InvSnapshot (Archived, SnapshotType, BusinessUnit) Include (SnapshotId, SnapshotDate) where (Archived = 'N');

Go
