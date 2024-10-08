/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/11/27  SK      Added TSKUPrepacksImportValidation, TSKUPrepacksImportType
  Create Type TSKUPrepacksImportValidation as Table (
  Grant References on Type:: TSKUPrepacksImportValidation   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in Validation of data being imported, capture the validations, use to update the InterfaceLogDetails */
Create Type TSKUPrepacksImportValidation as Table (
    RecordId                 TRecordId,
    SKUPrePackId             TRecordId,
    RecordAction             TFlag,
    RecordType               TRecordType,
    MasterSKUId              TRecordId,
    MasterSKU                TSKU,
    MasterBU                 TBusinessUnit,
    ComponentSKUId           TRecordId,
    ComponentSKU             TSKU,
    ComponentBU              TBusinessUnit,
    ComponentQty             TQuantity,
    Status                   TStatus,
    SortSeq                  TSortSeq,
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    InputXML                 TXML,
    ResultXML                TXML,
    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TSKUPrepacksImportValidation   to public;

Go
