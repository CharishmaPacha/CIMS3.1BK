/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/23  TD      Added TBatchedOrderDetails.
  Create Type TBatchedOrderDetails as Table (
  Grant References on Type:: TBatchedOrderDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TBatchedOrderDetails as Table (
    PickBatchId              TRecordId,
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    SKUId                    TRecordId,
    UnitsOrdered             TQuantity,
    UnitsAuthorizedToShip    TQuantity,
    UnitsPerInnerPack        TInteger,
    UnitsToAllocate          TInteger,
    DestZone                 TZoneId,

    Reference                TDescription,  -- To save reason as to why the DestZone is set to what it is

    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId),
    Unique                   (SKUId, OrderDetailId)
);

Grant References on Type:: TBatchedOrderDetails to public;

Go
