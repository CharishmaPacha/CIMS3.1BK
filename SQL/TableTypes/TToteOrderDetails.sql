/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/11  TD      Added TToteOrderDetails.
  Create Type TToteOrderDetails as Table (
  Grant References on Type:: TToteOrderDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TToteOrderDetails as Table (
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    SKUId                    TRecordId,
    UnitsToShip              TQuantity,
    UnitsAssigned            TQuantity,
    UnitsToAllocate          TQuantity,
    UnitsToPick              TQuantity,
    IsSortable               TFlag,

    PickPath                 TLocation,
    Location                 TLocation,
    PutawayZone              TZoneId,

    DestZone                 TZoneId,
    PutawayPath              TLocationPath,

    AllocatedStatus          TFlags,
    AvailableQty             TQuantity,

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TToteOrderDetails to public;

Go
