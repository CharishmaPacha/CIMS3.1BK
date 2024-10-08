/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/21  MS      SrtrPackedLPNs, SrtrWaveTransactions, SrtrWaveStatus: Renamed WaveNumber as WaveNo (JL-64)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: SrtrWaveStatus
    This table holds all the Wave status messages that we receive from WCS for each
    subwave. There may be duplicates for the same subwave.
------------------------------------------------------------------------------*/
Create Table SrtrWaveStatus (
    RecordId                 TRecordId      identity (1,1) not null,

    WCSRecId                 TRecordId,

    WaveNo                   TWaveNo,
    WaveStatus               TDescription,
    SorterName               TName,

    BusinessUnit             TBusinessUnit  not null,
    Archived                 TFlag          default 'N',
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkWaveStatus_RecordId PRIMARY KEY (RecordId)
);

create index ix_SrtrWaveStatus_WaveNo        on SrtrWaveStatus (WaveNo, SorterName) Include (WaveStatus);

Go
