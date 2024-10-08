/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: RFLog - Deprecated, do not use
   We have activity Log table that has this and more information and already has
   ready procedures, so we should use that instead of RFLog table. Instead use
   vwRFLog that gives all RFLog information pulled from Activity table
------------------------------------------------------------------------------*/
Create Table RFLog (
    RecordId                 TRecordId      identity (1,1) not null,

    UserId                   TUserId,
    DeviceId                 TDeviceId,

    InputXML                 XML,
    OutputXML                XML,

    DateTimeStamp            TDateTime      default current_timestamp,
    CreatedOn                as cast(DateTimeStamp as date),

    constraint pkRFLog_RecordId  PRIMARY KEY (RecordId),
);

create index ix_RFLog_CreatedOn                  on RFLog (CreatedOn);

Go
