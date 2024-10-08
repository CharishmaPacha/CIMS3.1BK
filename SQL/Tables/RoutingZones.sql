/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/26  AY      RoutingZones: Added new table
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: RoutingZones: This is the list of zones used for setting up of Routing
    rules. A Zone is a list of States and/or zip codes within that state. Having
    the zones defined would make it easier to determine the addresses that can be
    shipped via Ground service and yet reach within the required days.
------------------------------------------------------------------------------*/
Create Table RoutingZones (
    RecordId                 TRecordId      identity (1,1) not null,
    SortSeq                  TInteger       default 0,

    ZoneName                 TName,

    SoldToId                 TCustomerId,    -- future use
    ShipToId                 TShipToId,      -- future use

    ShipToCity               TCity,          -- future use
    ShipToState              TState,
    ShipToZipStart           TZip,
    ShipToZipEnd             TZip,
    ShipToCountry            TCountry,

    TransitDays              TInteger,       -- future use
    DeliveryRequirement      TDescription,   -- future use

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Status                   TStatus        default 'A'  /* Active */,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

  constraint pkRoutingZones_RecordId PRIMARY KEY (RecordId)
);

create index ix_RoutingZones_ZoneName            on RoutingZones (ZoneName) Include (ShipToState, ShipToZipStart, ShipToZipEnd);

Go
