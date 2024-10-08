/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/16  TK      TOrdersToCube: Added NumShipCartons (HA-1964)
  TOrdersToCube: Initial Revision (HA-1487)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TOrdersToCube as Table (
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    Account                  TAccount,
    OrderCartonGroup         TCartonGroup,
    PackingGroup             TCategory,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,

    TotalQtyToCube           TInteger,
    TotalSpaceRequired       TFloat,
    TotalWeight              TWeight,

    MaxFirstDimension        TFloat,
    MaxSecondDimension       TFloat,
    MaxThirdDimension        TFloat,

    NumPicks                 TInteger,
    NumLPNPicks              TInteger,
    NumCasePicks             TInteger,
    NumUnitsPicks            TInteger,
    NumShipCartons           TInteger,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      identity(1,1),

    Primary Key              (RecordId),
    Unique                   (OrderId, OrderCartonGroup)
);

Grant References on Type:: TOrdersToCube  to public;

Go
