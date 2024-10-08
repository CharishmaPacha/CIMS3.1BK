/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: SrtrConsumedLPNs.
         This table will contains the consumed LPN details, this is while picking
------------------------------------------------------------------------------*/
Create Table SrtrConsumedLPNs (
    RecordId                 TRecordId      identity (1,1) not null,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    LPNId                    TRecordId,
    LPN                      TLPN,
    OrderId                  TRecordId,

    SKUId                    TRecordId,
    SKU                      TSKU,

    QtyRemaining             TQuantity,

    PackSize                 TInteger,
    PickLocation             TLocation,

    ProcessedStatus          TStatus        default 'N',
    ProcessedDate            TDateTime,

    SorterName               TName,

    BusinessUnit             TBusinessUnit  not null,
    Archived                 TFlag          default 'N',
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSrtrConsumedLPNs_RecordId PRIMARY KEY (RecordId)
);

create index ix_SrtrConsumedLPNs_ProcessedStatus on SrtrConsumedLPNs(ProcessedStatus, LPN);

Go
