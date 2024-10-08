/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/21  SV      TOpenOrderExportType, TOpenReceiptExportType, TExportsType Added SourceSystem field (S2G-379)
  Added TInventoryExportType, TOpenOrderExportType, TOpenReceiptExportType,
  Create Type TOpenReceiptExportType as Table (
  Grant References on Type:: TOpenReceiptExportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in ReceiptDetail type Import
   This table structure mimics the record structure of Open Receipt Exports table, with few additional fields
   to capture key fields, etc.,. */
Create Type TOpenReceiptExportType as Table (
    RecordId                 TRecordId      identity (1,1),

    ReceiptNumber            TReceiptNumber,
    RecordType               TRecordType,
    ReceiptType              TReceiptType,
    VendorId                 TVendorId,
    Vessel                   TVessel,
    ContainerNo              TContainer,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    CustPO                   TCustPO,

    HostReceiptLine          THostReceiptLine,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    QtyOrdered               TQuantity,
    QtyIntransit             TQuantity,
    QtyReceived              TQuantity,
    QtyOpen                  TQuantity,

    CoO                      TCoO,
    UnitCost                 TCost,

    RH_UDF1                  TUDF,
    RH_UDF2                  TUDF,
    RH_UDF3                  TUDF,
    RH_UDF4                  TUDF,
    RH_UDF5                  TUDF,

    RD_UDF1                  TUDF,
    RD_UDF2                  TUDF,
    RD_UDF3                  TUDF,
    RD_UDF4                  TUDF,
    RD_UDF5                  TUDF,
    RD_UDF6                  TUDF,
    RD_UDF7                  TUDF,
    RD_UDF8                  TUDF,
    RD_UDF9                  TUDF,
    RD_UDF10                 TUDF,
    /* Open Receipt Exports */
    vwORE_UDF1               TUDF,
    vwORE_UDF2               TUDF,
    vwORE_UDF3               TUDF,
    vwORE_UDF4               TUDF,
    vwORE_UDF5               TUDF,
    vwORE_UDF6               TUDF,
    vwORE_UDF7               TUDF,
    vwORE_UDF8               TUDF,
    vwORE_UDF9               TUDF,
    vwORE_UDF10              TUDF,

    SourceSystem             TName,
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      DEFAULT current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    Primary Key              (RecordId)
);

Grant References on Type:: TOpenReceiptExportType   to public;

Go
