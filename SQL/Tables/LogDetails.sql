/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: LogDetails: The purpose of the details is to log the before and after images
   of any datasets for debugging or the impact of changes done in the operation.
------------------------------------------------------------------------------*/
Create Table LogDetails (
    LogDetailId              TRecordId      identity (1,1) not null,
    LogId                    TRecordId,
    DateTimeStamp            TDateTime      default current_timestamp,

    SubOperation             TOperation,
    EntityType               TTypeCode,
    Entity                   TEntity,
    DurationInSecs           as cast(datediff(s /* seconds */, convert(Datetime, StartTime, 121), convert(Datetime, EndTime, 121)) As varchar(50)),

    BeforeXML                TXML,
    AfterXML                 TXML,

    StartTime                TDateTime      default current_timestamp,
    EndTime                  TDateTime,

    constraint pkLogDetails_LogDetailId PRIMARY KEY (LogDetailId)
);

Go
