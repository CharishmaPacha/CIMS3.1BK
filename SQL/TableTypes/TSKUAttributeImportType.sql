/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/11/18  SK      Added TSKUAttributeImportType
  Create Type TSKUAttributeImportType as Table (
  Grant References on Type:: TSKUAttributeImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in UPC Import
   This table structure mimics the record structure of SKUAttribute table, with few additional fields
   to capture key fields, etc.,. */

Create Type TSKUAttributeImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,
    SKUId                    TRecordId,
    SKU                      TSKU,
    Status                   TStatus,
    UPC                      TUPC,
    BusinessUnit             TBusinessUnit,
    Ownership                TOwnership,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    Primary Key             (RecordId),
    Unique                  (RecordAction, RecordId)
);

Grant References on Type:: TSKUAttributeImportType   to public;

Go
