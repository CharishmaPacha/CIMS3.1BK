/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/14  AY      InterfaceFields: Changed datatype of FieldType as we could use domain name (CIMSV3-1120)
  2020/11/12  TK      InterfaceFields: Added FielddefaultValue (CID-1498)
  2015/11/04  KN      Added InterfaceFields table definition (GNCLMS-4).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InterfaceFields
------------------------------------------------------------------------------*/
Create Table InterfaceFields (
    RecordId                 TRecordId      identity (1,1) not null,

    ProcessName              TName,         /* Import, Export or specific Import/Export process */
    DataSetName              TName,         /* Table name/Record type to group fields */

    FieldName                TName,
    ExternalFieldName        TName,
    FieldType                TName,         /* string, integer, datetime, date */
    FieldWidth               TInteger,
    FielddefaultValue        TDescription,
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
