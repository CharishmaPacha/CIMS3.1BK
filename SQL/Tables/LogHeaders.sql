/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: LogHeaders: All primary operations of RF and may be others in future would
   be logged into this table. This is almost identical to Activity Log and is used
   for operations logging. Some of the entries may have associated details which
   would helpful for debugging.
------------------------------------------------------------------------------*/
Create Table LogHeaders (
    LogId                    TRecordId      identity (1,1) not null,
    DateTimeStamp            TDateTime      default current_timestamp,

    ProcName                 TName, /* Object name of the caller */
    Operation                TOperation,

    LPN                      TLPN,
    WaveNo                   TWaveNo,
    TaskId                   TRecordId,
    PickTicket               TPickTicket,
    Pallet                   TPallet,
    Location                 TLocation,
    SKU                      TSKU,
    ToLPN                    TLPN,

    InnerPacks               TInnerPacks,
    Quantity                 TQuantity,

    DurationInSecs           as cast(datediff(s /* seconds */, convert(Datetime, StartTime, 121), convert(Datetime, EndTime, 121)) As varchar(50)),

    UserId                   TUserId,
    DeviceId                 TDeviceId,

    XMLData                  TXML,
    XMLResult                TXML,
    Markers                  TXML,

    StartTime                TDateTime      default current_timestamp,
    EndTime                  TDateTime,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    constraint pkLogHeaders_LogId PRIMARY KEY (LogId)
);

Go
