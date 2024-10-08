/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/04/26  AY      InterfaceLog: Added Archived
  2017/11/09  TD      InterfaceLogDetails:Added HostRecId (CIMSDE-14)
  2016/09/11  AY      ix_InterfaceLog_Status: Enhanced (HPI-GoLive)
  2014/09/18  AY      InterfaceLog: Added index and default on AlertSent
  2014/01/10  DK      Added several fields in InterfaceLog
  2013/12/06  AY      Added indices on InterfaceLogDetails
  2013/04/24  AY      InterfaceLog: Added ResultXML and BusinessUnit.
  2012/09/06  AY      InterfaceLog: Added InputXML to save the input XML for debugging.
  2010/12/13  PK      Created table : InterfaceTypes, InterfaceLog.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InterfaceLog: Summary of the import/export activity
------------------------------------------------------------------------------*/
Create Table InterfaceLog (
    RecordId                 TRecordId      identity(1,1) not null,

    SourceSystem             TName,
    TargetSystem             TName,

    InputXML                 TXML,

    RecordTypes              TRecordTypes,
    TransferType             TTransferType, /* Import or Export */
    Status                   TStatus        default 'P', /* in Process, Warnings, Failed, Success */

    RecordsProcessed         TCount,
    RecordsFailed            TCount         default 0,
    RecordsPassed            TCount         default 0,

    SourceReference          TName,         /* Web service name or file name */

    StartTime                TDateTime      default current_timestamp,
    EndTime                  TDateTime,

    AlertSent                TFlags         default 'T', /* Y - Yes, NR - Not required, T - To be sent */

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as cast(CreatedDate as date),

    constraint pkInterfaceLog Primary Key Clustered (RecordId)
);

create index ix_InterfaceLog_Alert               on InterfaceLog (AlertSent) Include (RecordId, RecordTypes);
create index ix_InterfaceLog_Status              on InterfaceLog (Status) Include (RecordTypes, AlertSent, RecordsFailed, SourceReference);
/* In UI, Archived = N is default selection */
create index ix_InterfaceLog_Archived            on InterfaceLog (Archived, CreatedOn, BusinessUnit) Include (RecordId) where (Archived = 'N');

Go
