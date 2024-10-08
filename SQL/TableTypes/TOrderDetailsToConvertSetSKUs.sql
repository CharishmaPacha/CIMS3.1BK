/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/28  RV      TOrderDetailsToConvertSetSKUs: Added (OB2-1948)
  Create Type TOrderDetailsToConvertSetSKUs as Table (
  Grant References on Type:: TOrderDetailsToConvertSetSKUs to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TOrderDetailsToConvertSetSKUs as Table (
    OrderDetailId         TRecordId,
    OrderId               TRecordId,
    HostOrderLine         THostOrderLine,
    LineType              TTypeCode,
    ParentLineId          TRecordId,
    ParentHostLineNo      THostOrderLine,

    LPNId                 TRecordId,
    LPNDetailId           TRecordId,
    SKUId                 TRecordId,
    UnitsperInnerPack     TInteger,
    OrderedCases          TQuantity,
    UnitsOrdered          TQuantity,
    UnitsAuthorizedToShip TQuantity,
    UnitsAssigned         TQuantity,
    UnitsToAllocate       TQuantity,
    UnitsPicked           TQuantity,
    KitsToShip            TQuantity,
    KitsPicked            TQuantity,
    KitsToConvert         TQuantity, -- for each Parent line, number of kits that can be created
    UnitsToConvert        TQuantity, -- for each parent line, number of units that can be conveerted to kits

    Weight                TWeight,
    Volume                TVolume,
    Lot                   TLot,

    RecordId              TRecordId identity(1,1)
);

Grant References on Type:: TOrderDetailsToConvertSetSKUs to public;

Go
