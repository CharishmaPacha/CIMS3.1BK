/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  Create Type TLPNContentsLabelDetails as Table (
  Grant References on Type:: TLPNContentsLabelDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLPNContentsLabelDetails as Table (
    RecordId                 TRecordId      Identity(1,1),

    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNLine                  TDetailLine,
    SKUId                    TRecordId,
    SKU                      TSKU,
    Quantity                 TQuantity,
    UPC                      TUPC,
    CustSKU                  TCustSKU,
    SKUDescription           TDescription,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    UnitsAuthorizedToShip    TQuantity,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF
);

Grant References on Type:: TLPNContentsLabelDetails to public;

Go
