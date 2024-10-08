/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/11/09  TD      InterfaceLogDetails:Added HostRecId (CIMSDE-14)
  2013/12/06  AY      Added indices on InterfaceLogDetails
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InterfaceLogDetails: Details of all the errors associated with the import of data
------------------------------------------------------------------------------*/

Create Table InterfaceLogDetails (
    RecordId                 TRecordId      identity(1,1) not null,

    ParentLogId              TRecordId,
    TransferType             TTransferType, -- I don't know why we have this as header table has it already
    RecordType               TRecordType,

    LogMessage               TDescription,
    LogDateTime              TDateTime      default current_timestamp,
    KeyData                  TReference,
    HostReference            TReference,
    HostRecId                TRecordId,
    InputXML                 TXML,
    ResultXML                TXML,

    Status                   as case when ResultXML is not null then 'E' /* Error */ else 'S' /* Success */ end,
    LogDate                  as cast(LogDateTime as Date),

    BusinessUnit             TBusinessUnit,

    constraint pkInterfaceLogDetails Primary Key Clustered (RecordId)
);

create index ix_InterfaceLD_RecordType           on InterfaceLogDetails (RecordType, KeyData) Include (LogDate);
create index ix_InterfaceLD_LogDate              on InterfaceLogDetails (LogDate, RecordType) Include (KeyData);
create index ix_InterfaceLD_ParentLogId          on InterfaceLogDetails (ParentLogId) Include (Status);

Go
