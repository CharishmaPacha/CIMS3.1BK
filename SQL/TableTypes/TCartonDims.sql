/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/21  TK      TCartonDims: Table Type added (HA-2664)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TCartonDims as Table (
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNQuantity              TQuantity,

    OrderId                  TRecordId,
    WaveId                   TRecordId,

    CartonType               TCartonType,
    CartonGroup              TCartonGroup,

    PackageWeight            TWeight,
    PackageVolume            TVolume,

    PackageLength            TLength,
    PackageWidth             TWidth,
    PackageHeight            THeight,

    FirstDimension           TFloat,
    SecondDimension          TFloat,
    ThirdDimension           TFloat,

    RecordId                 TRecordId      identity(1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TCartonDims  to public;

Go
