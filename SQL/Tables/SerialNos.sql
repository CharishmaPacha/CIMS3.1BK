/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/07  RV      SerialNos: Added PrintBatch (S2GCA-507)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: SerialNos

 Status: 'A' - Assigned
         'R' - Ready To Use
         'S' - Shipped
------------------------------------------------------------------------------*/
Create Table SerialNos (
    RecordId                 TRecordId      identity (1,1) not null,

    SerialNo                 TSerialNo,
    SerialNoStatus           TStatus        default 'R',

    LPNId                    TRecordId,
    LPNDetailId              TRecordId,
    SKUId                    TRecordId,
    PrintBatch               TBatch,

    PickTicket               TPickTicket,
    WaveNo                   TWaveNo,

    SN_UDF1                  TUDF,
    SN_UDF2                  TUDF,
    SN_UDF3                  TUDF,
    SN_UDF4                  TUDF,
    SN_UDF5                  TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSerialNos_SerialNoId       PRIMARY KEY (RecordId),
    constraint ukSerialNos_SerialNo         UNIQUE      (SerialNo, BusinessUnit)
);

create index ix_SerialNos_SerialNo               on SerialNos(SerialNo, BusinessUnit) Include (RecordId, SerialNoStatus);
create index ix_SerialNos_LPNId                  on SerialNos(LPNId) Include (SerialNoStatus, SerialNo);

Go
