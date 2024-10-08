/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/13  VM      TOpenOrdersSummary: Added LoadDesiredShipDate, AppointmentDateTime (HA-2275)
  2020/08/12  SK      TOpenOrdersSummary: New table type for exporting open order summary (HA-1267)
  Create Type TOpenOrdersSummary as Table (
  Grant References on Type:: TOpenOrdersSummary     to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type for Open Order Summary */
Create Type TOpenOrdersSummary as Table (
    RecordId                 TRecordId      identity (1,1),
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderType                TOrderType,
    OrderStatus              TStatus,
    OrderStatusDesc          TDescription,
    CancelDate               TDateTime,
    DesiredShipDate          TDateTime,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    ShipFrom                 TShipFrom,
    ShipVia                  TShipVia,
    ShipViaDescription       TDescription,
    CustPO                   TCustPO,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    Account                  TCustomerId,
    AccountName              TName,
    /* Aggregate fields */
    NumSKUs                  TQuantity,
    NumLines                 TQuantity,
    NumUnitsToShip           TQuantity,
    TotalSalePrice           TMoney,
    TotalShipmentValue       TMoney,
    /* Load Info */
    LoadNumber               TLoadNumber,
    LoadStatus               TStatus,
    LoadDesiredShipDate      TDateTime,
    AppointmentDateTime      TDateTime,
    RoutingStatus            TStatus,
    /* UDFs */
    vwEOS_UDF1               TUDF,
    vwEOS_UDF2               TUDF,
    vwEOS_UDF3               TUDF,
    vwEOS_UDF4               TUDF,
    vwEOS_UDF5               TUDF,
    vwEOS_UDF6               TUDF,
    vwEOS_UDF7               TUDF,
    vwEOS_UDF8               TUDF,
    vwEOS_UDF9               TUDF,
    vwEOS_UDF10              TUDF,
    /* Flags */
    ExchangeStatus           TStatus,
    Archived                 TFlags         DEFAULT 'N' /* Default */,
    /* Other */
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      DEFAULT current_timestamp,
    CreatedBy                TUserId,
    ModifiedDate             TDateTime,
    ModifiedBy               TUserId,

    CreatedOn                as convert(date, CreatedDate),
    ModifiedOn               as convert(date, ModifiedDate),

    PRIMARY KEY              (RecordId),
    Unique                   (PickTicket, BusinessUnit)
);

Grant References on Type:: TOpenOrdersSummary     to public;

Go
