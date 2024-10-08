/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/21  SV      TOpenOrderExportType, TOpenReceiptExportType, TExportsType Added SourceSystem field (S2G-379)
  Added TInventoryExportType, TOpenOrderExportType, TOpenReceiptExportType,
  Create Type TOpenOrderExportType as Table (
  Grant References on Type:: TOpenOrderExportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in def_DE_Interface
   This table structure mimics the record structure of Open Orders Export, with few additional fields
   to capture key fields, etc.,. */
Create Type TOpenOrderExportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderType                TOrderType,
    Status                   TStatus,
    DesiredShipDate          TDateTime,
    CancelDate               TDateTime,
    SoldToId                 TContactRefId,
    ShipToId                 TContactRefId,
    ShipFrom                 TShipFrom,
    ShipVia                  TShipVia,
    CustPO                   TCustPO,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    Account                  TAccount,
    HostOrderLine            THostOrderLine,

    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    Lot                      TLot,

    UnitsOrdered             TQuantity,
    UnitsAuthorizedToShip    TQuantity,
    UnitsReserved            TQuantity,
    UnitsNeeded              TQuantity,
    UnitsShipped             TQuantity,
    UnitsRemainToShip        TQuantity,

    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    OH_UDF4                  TUDF,
    OH_UDF5                  TUDF,
    OH_UDF6                  TUDF,
    OH_UDF7                  TUDF,
    OH_UDF8                  TUDF,
    OH_UDF9                  TUDF,
    OH_UDF10                 TUDF,

    OD_UDF1                  TUDF,
    OD_UDF2                  TUDF,
    OD_UDF3                  TUDF,
    OD_UDF4                  TUDF,
    OD_UDF5                  TUDF,
    OD_UDF6                  TUDF,
    OD_UDF7                  TUDF,
    OD_UDF8                  TUDF,
    OD_UDF9                  TUDF,
    OD_UDF10                 TUDF,
    /* Open Orders Export */
    vwOOE_UDF1               TUDF,
    vwOOE_UDF2               TUDF,
    vwOOE_UDF3               TUDF,
    vwOOE_UDF4               TUDF,
    vwOOE_UDF5               TUDF,
    vwOOE_UDF6               TUDF,
    vwOOE_UDF7               TUDF,
    vwOOE_UDF8               TUDF,
    vwOOE_UDF9               TUDF,
    vwOOE_UDF10              TUDF,

    SourceSystem             TName,
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      DEFAULT current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    PRIMARY KEY              (RecordId),
    Unique                   (PickTicket,   RecordId)
);

Grant References on Type:: TOpenOrderExportType   to public;

Go
