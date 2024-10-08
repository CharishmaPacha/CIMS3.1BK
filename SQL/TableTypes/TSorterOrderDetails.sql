/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/05/22  PK      Added TSorterOrderDetails.
  Create Type TSorterOrderDetails as Table (
  Grant References on Type:: TSorterOrderDetails to public;
  Create Type TSorterOrderDetailsNew as Table (
  Grant References on Type:: TSorterOrderDetailsNew to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TSorterOrderDetails as Table (
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    SKUId                    TRecordId,
    CartonId                 TDescription   DEFAULT ('-'),
    UnitsAssigned            TQuantity,
    UnitsAuthorizedToShip    TQuantity,
    UnitsToAllocate          TQuantity,
    DestZone                 TZoneId,
    UnitWeight               TWeight,
    UnitVolume               TVolume,
    Weight                   as UnitsAssigned * UnitWeight,
    Volume                   as UnitsAssigned * UnitVolume,

    --UnitsPerInnerPack      TInteger,
    --ShipAlone              TFlag,

    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId)
);

Grant References on Type:: TSorterOrderDetails to public;

Go
