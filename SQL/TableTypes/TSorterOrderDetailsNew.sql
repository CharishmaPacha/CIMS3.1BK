/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  Create Type TSorterOrderDetailsNew as Table (
  Grant References on Type:: TSorterOrderDetailsNew to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TSorterOrderDetailsNew as Table (
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
    ShipPack                 TInteger,      -- added new field
    Weight                   as UnitsAssigned * UnitWeight,
    Volume                   as UnitsAssigned * UnitVolume,

    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId)
);

Grant References on Type:: TSorterOrderDetailsNew to public;

Go
