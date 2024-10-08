/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/06/09  VM      TExportInvSnapshot: Added Brand, ExpiryDate, InitialOnhandQty and converted calculated fields to normal fields (JLCA-866)
  2022/01/27  MS      TExportInvSnapshot: Added new fields (HA-3328)
  2021/02/27  TD      Added TExportInvSnapshot (BK-126)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in def_DE_Interface
   This table structure mimics the record structure of Inventory InvSnapshot, with few additional fields
   to capture key fields, etc.,. */
Create Type TExportInvSnapshot as Table (
    SnapshotId               TRecordId,
    SnapshotDate             TDate                default getdate(),
    SnapshotDateTime         TDateTime            default getdate(),
    SnapshotType             TTypeCode, /* EndOfDay or EODLPN */

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

    LPN                      TLPN,
    Location                 TLocation,
    Lot                      TLot,
    Warehouse                TWarehouse,
    Ownership                TOwnership,

    UnitsPerInnerPack        TCount,
    AvailableIPs             TCount,
    ReservedIPs              TCount,
    OnhandIPs                TCount,
    ReceivedIPs              TCount,
    ToShipIPs                TCount,

    AvailableQty             TQuantity,
    ReservedQty              TQuantity,
    ReceivedQty              TQuantity,
    AdjustedInvQty           TQuantity,
    ShippedQty               TQuantity,
    ToShipQty                TQuantity,
    OnhandAvailableQty       as (case when ((coalesce([OnhandQty],(0))-coalesce([ToShipQty],(0)))-coalesce([ReservedQty],(0)))+coalesce([AdjustedInvQty],(0))<(0) then (0) else ((coalesce([OnhandQty],(0))-coalesce([ToShipQty],(0)))-coalesce([ReservedQty],(0)))+coalesce([AdjustedInvQty],(0)) end),
    OnhandQty                TQuantity,
    OnhandValue              TMoney,
    InventoryKey             varchar(200),

    vwEOHINV_UDF1            TUDF,
    vwEOHINV_UDF2            TUDF,
    vwEOHINV_UDF3            TUDF,
    vwEOHINV_UDF4            TUDF,
    vwEOHINV_UDF5            TUDF,
    vwEOHINV_UDF6            TUDF,
    vwEOHINV_UDF7            TUDF,
    vwEOHINV_UDF8            TUDF,
    vwEOHINV_UDF9            TUDF,
    vwEOHINV_UDF10           TUDF,

    SourceSystem             TName,
    BusinessUnit             TBusinessUnit,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    CIMSRecId                TRecordId,

    RecordId                 TRecordId      identity (1,1),

    primary key              (RecordId)
);

grant references on Type:: TExportInvSnapshot to public;

Go
