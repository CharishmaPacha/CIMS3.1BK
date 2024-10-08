/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/03  SV      Added TSKUChange (SRI-422)
  Create Type TSKUChange as Table (
  Grant References on Type:: TSKUChange to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TSKUChange as Table (
    RecordId                 TRecordId      identity (1,1) not null,
    OldSKUId                 TRecordId,
    OldSKU                   TSKU,
    OldSKU1                  TSKU,
    OldSKU2                  TSKU,
    OldSKU3                  TSKU,
    OldSKU4                  TSKU,
    OldSKU5                  TSKU,
    OldUPC                   TUPC,
    OldSKUCreatedDate        TDateTime,
    NewSKUId                 TRecordId,
    NewSKU                   TSKU,
    NewSKU1                  TSKU,
    NewSKU2                  TSKU,
    NewSKU3                  TSKU,
    NewSKU4                  TSKU,
    NewSKU5                  TSKU,
    NewUPC                   TUPC,
    NewSKUCreatedDate  TDateTime
);

Grant References on Type:: TSKUChange to public;

Go
