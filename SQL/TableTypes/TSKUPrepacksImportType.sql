/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TSKUImportType: UDF's Renamed as SKU_UDF1 to 30, TSKUPrepacksImportType: SPP_UDF1 to 5
  TSKUPrepacksImportType: Added MasterSKU1 to 5, ComponentSKU1 to ComponentSKU5
  2014/11/27  SK      Added TSKUPrepacksImportValidation, TSKUPrepacksImportType
  Create Type TSKUPrepacksImportType as Table (
  Grant References on Type:: TSKUPrepacksImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in SKUPrepacks Import
   This table structure mimics the record structure of SKUAttribute table, with few additional fields
   to capture key fields, etc.,. */
Create Type TSKUPrepacksImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TFlag,

    MasterSKU                TSKU,
    MasterSKU1               TSKU,
    MasterSKU2               TSKU,
    MasterSKU3               TSKU,
    MasterSKU4               TSKU,
    MasterSKU5               TSKU,

    ComponentSKU             TSKU,
    ComponentSKU1            TSKU,
    ComponentSKU2            TSKU,
    ComponentSKU3            TSKU,
    ComponentSKU4            TSKU,
    ComponentSKU5            TSKU,

    ComponentQty             TQuantity,
    Status                   TStatus,
    SortSeq                  TSortSeq,

    SPP_UDF1                 TUDF,
    SPP_UDF2                 TUDF,
    SPP_UDF3                 TUDF,
    SPP_UDF4                 TUDF,
    SPP_UDF5                 TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    SKUPrePackId             TRecordId,
    MasterSKUId              TRecordId,
    ComponentSKUId           TRecordId,
    InputXML                 TXML,
    ResultXML                TXML,
    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TSKUPrepacksImportType   to public;

Go
