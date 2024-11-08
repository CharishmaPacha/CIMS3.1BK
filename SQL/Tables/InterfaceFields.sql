/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/26  VS      InterfaceFields: Added Operation (JLFL-394)
  2020/11/14  AY      InterfaceFields: Changed datatype of FieldType as we could use domain name (CIMSV3-1120)
  2020/11/12  TK      InterfaceFields: Added FieldDefaultValue (CID-1498)
  2015/11/04  KN      Added InterfaceFields table definition (GNCLMS-4).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InterfaceFields

  Operations: CSV of these values: Upload,Import,Augment,Insert,Update
              Upload: Fields that are expected to be uploaded from the file
              Import: Fields that are to be imported into the actual tables
              Augment: Fields which are not uploaded from the file but added to the
                       hash table during FileImport either for processing, or validation
                       or for applying a default value.
              Insert: Fields that are to be inserted.
              Update: Fields that are to be updated.
              All applicable options would be included in the Operation

  At present Insert/Update are not used for FileImport
------------------------------------------------------------------------------*/
Create Table InterfaceFields (
    RecordId                 TRecordId      identity (1,1) not null,

    ProcessName              TName,         /* Import, Export or specific Import/Export process */
    DataSetName              TName,         /* Table name/Record type to group fields */
    Operations               TString,       /* FileImport, Upload, Insert, Update */

    FieldName                TName,
    ExternalFieldName        TName,
    FieldType                TName,         /* string, integer, datetime, date */
    FieldWidth               TInteger,
    FieldDefaultValue        TDescription,
    Justification            TName,         /* left, right */
    PadChar                  Char,          /* char to use used for padding */

    SortSeq                  TSortSeq       not null default 0,
    Status                   TStatus        not null default 'A' /* Active */,
    VersionId                TRecordId,     /* future use */

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              DateTime       default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkInterfaceFields                    PRIMARY KEY (RecordId),
    constraint ukInterfaceFields_DataSetFieldNameBU UNIQUE (ProcessName, DataSetName, FieldName, ExternalFieldName, BusinessUnit)
);

Go
