/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/18  AY      LoadRoutingInfo: Added more fields (HA-1962)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: LoadRoutingInfo: When routing is confirmed by the customer, they give
    the routing of the orders in an excel sheet, email and/or an EDI754. This
    table is used to hold the results of the routing and to process the same.
------------------------------------------------------------------------------*/
Create Table LoadRoutingInfo (
    RecordId                 TRecordId      identity (1,1) not null,

    Account                  TAccount,
    AccountName              TName,
    CustPO                   TCustPO,
    ShipToStore              TShipToStore,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    PickTicketStart          TPickTicket,
    PickTicketEnd            TPickTicket,

    NB4Date                  TDateTime,
    CancelDate               TDateTime,
    DesiredShipDate          TDateTime,
    DeliveryStart            TDateTime,
    DeliveryEnd              TDateTime,

    ClientLoadNumber         TLoadNumber,
    LoadGroup                TLoadGroup,
    ShipVia                  TShipVia,
    ShipmentRefNumber        TShipmentRefNumber,

    NumPallets               TCount         default 0,
    NumCartons               TCount         default 0,
    Weight                   TWeight        default 0.0,
    Volume                   TVolume        default 0,

    BatchNo                  TBatch,
    Status                   TStatus        default 'Initial',
    ReferenceFileName        TName,

    LRI_UDF1                 TUDF,
    LRI_UDF2                 TUDF,
    LRI_UDF3                 TUDF,
    LRI_UDF4                 TUDF,
    LRI_UDF5                 TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,

    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

  constraint pkLoadRoutingInfo_RecordId PRIMARY KEY (RecordId)
);

Go
