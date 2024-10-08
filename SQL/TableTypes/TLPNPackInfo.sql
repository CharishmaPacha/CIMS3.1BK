/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  Create Type TLPNPackInfo as Table (
  Grant References on Type:: TLPNPackInfo  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLPNPackInfo as Table (
    LPNId                    TRecordId,
    LPNDetailId              TRecordId,

    InnerPacks               TInteger,
    Quantity                 TInteger,
    Cases                    TCount,
    UnitsPerPackage          TInteger,

    OrderId                  TRecordId,
    BoLId                    TRecordId,
    LoadId                   TRecordId,

    BusinessUnit             TBusinessUnit,
    CreatedBy                TUserId,

    RecordId                 TRecordId      identity (1,1) not null
);

Grant References on Type:: TLPNPackInfo  to public;

Go
