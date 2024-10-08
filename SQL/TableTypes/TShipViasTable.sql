/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/08/09  LRA     TShipViasTable:Added BusinessUnit (cIMs-1346)
  2017/07/27  LRA     Added the TShipViasTable (CIMS-1346)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TShipViasTable as Table (
    ShipVia                  TShipVia,
    Carrier                  TCarrier,
    Description              TDescription,
    SCAC                     TSCAC,

    CarrierServiceCode       varchar(50),
    StandardAttributes       varchar(max),
    SpecialServices          varchar(max),

    Status                   TStatus,
    SortSeq                  TInteger,
    BusinessUnit             TBusinessUnit,
    RecordId                 TRecordId      identity(1,1)
);

Grant References on Type:: TShipViasTable to public;

Go
