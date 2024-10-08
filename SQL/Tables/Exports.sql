/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/18  VS      Exports: Added Comments field (BK-885)
  2022/02/25  MS      Exports: Added InventoryKey (BK-768)
  2021/06/30  AY      ix_Exports_ReceiptId: Revised for performance of SendConsoliidatedExports (HA-2941)
  2021/04/04  AY      Exports: Add SortOrder (HA-1842)
  2021/02/20  PK      Exports: Added DesiredShipDate (HA-2029)
  2021/01/22  AY      Exports: Added NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity (HA-1896)
  2020/10/15  SK      Exports: Added FromLPNId, FromLPN (HA-1516)
  2020/06/30  RKC     Exports: Add ModifiedOn computed column and index (CIMS-3118)
  2020/04/28  AY      Exports: Added ReceiverId (HA-323)
  2020/03/31  AY      Exports: Added Inv.Classes (HA-85)
  2019/12/05  RKC     Exports: Added ShipToId, ShipToName, ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip,
  2019/09/10  MS      Exports: Added ShipVia and related fields (CID-1029)
  2019/09/07  AY      Exports: Revised index ix_Exports_Archived (CID-1022)
  2018/05/18  AY      Exports: Added ListNetCharge, AccountNewCharge to export both to Host
  2018/03/13  DK      Exports: Added SourceSystem (FB-1109)
  2018/02/10  AY      Exports: Added TransDate for selections & grouping
  2017/12/22  PK      Exports: Added Index on ReceiptId.
  2017/09/19  YJ      Exports: Migrated from Prod Onsite: Added ix_Exports_TransType (HPI-1558)
  2017/09/05  AY      Exports: Revised index ix_Exports_BatchNo as status is always needed and only looking for Status = N records.
  2016/08/31  AY      Exports: Added FreightCharges & TrackingNo (HPI-531)
  2016/08/24  AY      Revised ix_Exports_BatchNo
  2014/02/14  NY      Exports: Added additional UDF's.
  2014/01/27  TD      Exports: Added UDFs.
  2012/11/21  SP      Added index ixExportsArchived in Exports table.
  2010/12/07  VM      Uploads => Exports. Fields modified/added
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Exports
------------------------------------------------------------------------------*/
Create Table Exports (
    TransType                TTypeCode      not null,
    TransEntity              TEntity,
    TransQty                 TQuantity      default 0,

    TransDateTime            TDateTime      default current_timestamp,
    Status                   TStatus        not null default 'N',
    ProcessedDateTime        TDateTime,

    SKUId                    TRecordId,
    LPNId                    TRecordId,
    LPNDetailId              TRecordId,
    LocationId               TRecordId,
    PalletId                 TRecordId,

    /* Location */
    HostLocation             TLocation,

    ReceiverId               TRecordId,
    ReceiverNumber           TReceiverNumber,
    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,
    HostReceiptLine          THostReceiptLine,

    ReasonCode               TReasonCode,
    Warehouse                TWarehouse,
    Ownership                TOwnership,
    SourceSystem             TName          default 'HOST',
    Weight                   TWeight        default 0.0,
    Volume                   TVolume        default 0.0,
    Length                   TLength,
    Width                    TWidth,
    Height                   THeight,
    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    InventoryKey             as concat_ws('-', SKUId, Ownership, Warehouse, Lot, InventoryClass1, InventoryClass2, InventoryClass3),

    NumPallets               TCount,
    NumLPNs                  TCount,
    NumCartons               TCount,  -- computed based upon what is considered a carton for shipping
    InnerPacks               TInteger,
    Quantity                 TInteger,

    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    ShipmentId               TShipmentId,
    LoadId                   TRecordId,
    DesiredShipDate          TDateTime,

    ShipVia                  TShipVia,
    ShipViaDesc              TDescription,
    Carrier                  TCarrier,
    SCAC                     TSCAC,
    HostShipVia              TShipVia,      -- mapped from CIMS ShipVia to Host ShipVia

    FreightCharges           TMoney,        -- charges that will be applied to Order which could be one of the below two for Small packages
    FreightTerms             TDescription,
    ListNetCharge            TMoney,
    AccountNetCharge         TMoney,
    InsuranceFee             TMoney,
    TrackingNo               TTrackingNo,
    TrackingBarcode          TTrackingNo,

    Reference                TReference,
    ExportBatch              TBatch         not null default 0,

    HostOrderLine            THostOrderLine,
    SortOrder                TSortOrder,

    /* ShipToAddress */
    ShipToId                 TShipToId,
    ShipToName               TName,
    ShipToAddressLine1       TAddressLine,
    ShipToAddressLine2       TAddressLine,
    ShipToCity               TCity,
    ShipToState              TState,
    ShipToCountry            TCountry,
    ShipToZip                TZip,
    ShipToPhoneNo            TPhoneNo,
    ShipToEmail              TEmailAddress,
    ShipToReference1         TDescription,
    ShipToReference2         TDescription,

    /* SoldToAddress */
    SoldToId                 TCustomerId,
    SoldToName               TName,

    Comments                 TVarchar,  -- Export the Error Messages and other comments related to that exports

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
    UDF21                    TUDF,
    UDF22                    TUDF,
    UDF23                    TUDF,
    UDF24                    TUDF,
    UDF25                    TUDF,
    UDF26                    TUDF,
    UDF27                    TUDF,
    UDF28                    TUDF,
    UDF29                    TUDF,
    UDF30                    TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    ModifiedOn               As cast (ModifiedDate as date),

    /* Future Use */
    PrevSKUId                TRecordId,
    FromLPNId                TRecordId,
    FromLPN                  TLPN,
    FromWarehouse            TWarehouse,
    ToWarehouse              TWarehouse,
    FromLocationId           TRecordId,
    FromLocation             TLocation,
    ToLocationId             TRecordId,
    ToLocation               TLocation,
    MonetaryValue            TMonetaryValue,

    TransDate                as cast(TransDateTime as Date),
    RecordId                 TRecordId      identity (1,1) not null,
    constraint pkExports PRIMARY KEY (RecordId)
);

create index ix_Exports_Status                   on Exports (Status, TransType, TransEntity, ExportBatch);
create index ix_Exports_TransType                on Exports (TransType, OrderId, RecordId) Include (SKUId, TransQty);
/* Used in Archive */
create index ix_Exports_Archived                 on Exports (Archived) Include (Status, ModifiedOn) where (Archived = 'N');
/* Used in pr_ReceiptHeaders_Recount, pr_Receivers_SendConsolidatedExports */
create index ix_Exports_ReceiptId                on Exports (ReceiptId, TransType) Include(ReceiptDetailId, ReceiverNumber, TransQty, Status, BusinessUnit);
/* Used for exports i.e. creating batches */
create index ix_Exports_BatchNo                  on Exports (Status, ExportBatch, BusinessUnit, TransType, SourceSystem) Include (Ownership, RecordId, LoadId) where (Status = 'N');
create index ix_Exports_OrderId                  on Exports (OrderId) Include (TransDateTime, TransQty, Status, TransType);
create index ix_Exports_SKUId                    on Exports (SKUId, TransType) Include (RecordId, TransQty, TransDateTime);
create index ix_Exports_LPNId                    on Exports (LPNId, TransType) Include (RecordId, TransQty, TransDateTime);
create index ix_Exports_TransDate                on Exports (TransDate, TransType, Status) Include (SKUId, RecordId, Archived);
/* Used in PrepareData */
create index ix_Exports_ExportBatch              on Exports (ExportBatch, TransType, Status) Include (RecordId, ShipVia, SoldToId, ShipToId, OrderId, OrderDetailId);

Go
