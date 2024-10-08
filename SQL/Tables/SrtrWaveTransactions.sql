/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/21  MS      SrtrPackedLPNs, SrtrWaveTransactions, SrtrWaveStatus: Renamed WaveNumber as WaveNo (JL-64)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: SrtrWaveTransactions.

------------------------------------------------------------------------------*/
Create Table SrtrWaveTransactions (
    RecordId                 TRecordId            identity (1,1) not null,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,

    OrderDetailId            TRecordId,
    SKUId                    TRecordId,
    SKU                      TSKU,

    PackedLPNId              TRecordId,
    PackedLPN                TLPN,
    PackedLPNDetailId        TRecordId,
    PackedLPNQty             TQuantity,

    ConsumedLPNId            TRecordId,
    ConsumedLPN              TLPN,
    ConsumedLPNDetailId      TRecordId,
    ConsumedLPNQty           TQuantity,

    SorterName               TName,

    ConsumedQty              TQuantity,
    PackedQty                TQuantity,

    BusinessUnit             TBusinessUnit  not null,
    Archived                 TFlag          default 'N',
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSrtrWaveTransactions_RecordId PRIMARY KEY (RecordId)
);

create index ix_SrtrWaveTransactions_WaveNo  on SrtrWaveTransactions (WaveNo) Include (ConsumedQty, PackedLPN, SKU, SorterName);

Go
