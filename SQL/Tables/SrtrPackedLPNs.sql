/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/21  MS      SrtrPackedLPNs, SrtrWaveTransactions, SrtrWaveStatus: Renamed WaveNumber as WaveNo (JL-64)
  2014/05/01  TK      SrtrPackedLPNs: Added HostExportStatus.
  2014/04/20  PK      SrtrPackedLPNs: Added LPNsCreated, ShipLabeled, Routed.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: SrtrPackedLPNs.

    WaveNo : It is for reference, for which wavr those goit picked inventory.
    OrderId: This is also for reference, for which order they gor picked.
    LPN: This is carton, the inventory has been picked into.

    TD?? I think we do not need WaveId,WaveNo
------------------------------------------------------------------------------*/
Create Table SrtrPackedLPNs (
    RecordId                 TRecordId      identity (1,1) not null,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    OrderId                  TRecordId,
    SalesOrder               TSalesOrder,

    LPNId                    TRecordId,
    LPN                      TLPN,
    SKUId                    TRecordId,
    SKU                      TSKU,
    Quantity                 TQuantity,
    PackSize                 TQuantity,

    ProcessedStatus          TStatus        default 'N',
    ProcessedDate            TDateTime,

    IsLastCarton             TFlags,
    LPNsCreated              TStatus        default 'N',
    ShipLabeled              TStatus        default 'N',
    Routed                   TStatus        default 'N',
    HostExportStatus         TStatus        default 'N',

    SorterName               TName,         -- Future Use
    Location                 TLocation,

    ProdStatus               TStatus        default 'N',

    BusinessUnit             TBusinessUnit  not null,
    Archived                 TFlag          default 'N',
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSrtrPackedLPNs_RecordId PRIMARY KEY (RecordId)
);

create index ix_SrtrPackedLPNs_ProcessedStatus   on SrtrPackedLPNs(ProcessedStatus, LPN);
create index ix_SrtrPackedLPNs_LPN               on SrtrPackedLPNs(LPN) Include (ProcessedStatus, RecordId);
create index ix_SrtrPackedLPNs_Prod              on SrtrPackedLPNs(ProdStatus, SorterName, LPNsCreated) Include (LPNId, Quantity, CreatedDate, CreatedBy, PackSize, Location);
create index ix_SrtrPackedLPNs_LPNId             on SrtrPackedLPNs(LPNId)

Go
