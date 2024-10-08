/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/17  TK      TOrderRoutingInfo: Added Warehouse (HA-2303)
  2021/02/05  TK      TOrderRoutingInfo: Initial version (HA-1962)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TOrderRoutingInfo as Table (
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    Warehouse                TWarehouse,

    PrevLoadId               TRecordId,
    PrevLoadNumber           TLoadNumber,
    PrevLoadType             TTypeCode,
    PrevLoadGroup            TLoadGroup    DEFAULT '',
    PrevShipmentId           TRecordId,
    PrevBoLId                TRecordId,

    NewLoadId                TRecordId,
    NewLoadNumber            TLoadNumber,
    NewLoadType              TTypeCode,
    NewLoadGroup             TLoadGroup    DEFAULT '',

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      identity (1,1),

    primary key              (RecordId)
);

Grant References on Type:: TOrderRoutingInfo to public;

Go
