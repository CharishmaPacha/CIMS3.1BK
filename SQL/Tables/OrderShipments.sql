/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/16  AY      Created indices on Shipments, OrderShipments
  2012/06/18  TD      Added New Tables Loads, Shipments, OrderShipments
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: OrderShipments
    This table which defines the OrderIds associated with a Shipment.
------------------------------------------------------------------------------*/
Create Table OrderShipments (

    RecordId                 TRecordId      identity (1,1) not null,

    ShipmentId               TShipmentId    not null,
    OrderId                  TRecordId      not null,

    MaxPallets               TCount         default 0,
    MaxLPNs                  TCount         default 0,
    MaxPackageCount          TCount         default 0,
    MaxUnits                 TCount         default 0,

    NumPallets               TCount         default 0,
    NumLPNs                  TCount         default 0,
    NumPackages              TCount         default 0,
    NumUnits                 TCount         default 0,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,

    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkOrderShipments_RecordId PRIMARY KEY (RecordId)
);

create index ix_OrdShipments_OrderId             on OrderShipments (OrderId) Include(ShipmentId);
create index ix_OrdShipments_ShipmentId          on OrderShipments (ShipmentId) Include(OrderId);

Go
