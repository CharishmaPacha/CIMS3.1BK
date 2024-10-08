/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/01  AY      TSizeList: Added (JL-123)
  Create Type TSizeList as Table (
  Grant References on Type:: TSizeList  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* For apparel, in many cases, we have to display the sizes in a grid form
   and this table would be used to build that matrix. We use generic
   count as field name as it could be used for LPNs, IPs or Quantity */
Create Type TSizeList as Table (
    RecordId                 TRecordId      identity (1,1) not null,
    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    Size                     TSKU,
    SKUDescription           TDescription,
    SKUSortOrder             TDescription,

    UnitsPerInnerPack        TInteger,

    Count1                   TCount,
    Count2                   TCount,
    Count3                   TCount
);

Grant References on Type:: TSizeList  to public;

Go
