/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/07  VS      DebugPacking: Added New Column CreatedOn to Purge the Data quickly (HPI-2284)
  2016/12/05  AY      DebugPacking: Added ModifiedDate for performance evaluation (HPI-1118)
  2013/05/06  AY      DebugPacking: New table
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: DebugPacking
------------------------------------------------------------------------------*/
Create table DebugPacking (
    RecordId                 TRecordId      identity(1,1),
    CartonType               TCartonType,
    PalletId                 TRecordId,
    OrderId                  TRecordId,
    Weight                   TWeight,
    Volume                   TVolume,
    LPNContents              varchar(max),
    ToLPN                    TLPN,
    PackStation              TName,
    Action                   TAction,
    BusinessUnit             TBusinessUnit,
    UserId                   TUserId,
    OutputXML                TXML,
    CreatedDate              TDateTime      default current_timestamp,
    CreatedOn                As convert(date, CreatedDate),
    ModifiedDate             TDateTime,

    constraint pkDebugPacking_RecordId PRIMARY KEY (RecordId)
);

create index ix_DebugPacking_CreatedOn           on DebugPacking (CreatedOn);

Go
