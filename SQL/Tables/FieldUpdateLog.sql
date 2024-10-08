/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/24  AY      FieldUpdateLog: New table (HPI-1517)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: FieldUpdateLog: Table to keep track of updates to fields to record
   the changes to the DB
------------------------------------------------------------------------------*/
Create Table FieldUpdateLog (
    RecordId                 TRecordId      identity (1,1) not null,

    TableName                TName,
    FieldName                TName,
    EntityId                 TRecordId,
    EntityKey                TEntityKey,

    OldValue                 TDescription,
    NewValue                 TDescription,
    ChangeDateTime           TDateTime      default current_timestamp,
    ChangedBy                TUserId,

    ChangeDate               as convert(date, CreatedDate),
    ChangeTime               as convert(time, CreatedDate),

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkFieldUpdateLog PRIMARY KEY (RecordId)
);

create index ix_FieldUpdateLog_Entity            on FieldUpdateLog (EntityKey, TableName, FieldName);

Go
