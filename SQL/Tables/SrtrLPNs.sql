/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/11  PK      SrtrWaveDetails, SrtrLPNs: Added AllocatedQty.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: SrtrLPNs.    --need to write comments--related sorter tables...

  ContainerQty: Qty translated into Pick Packs
  AllocatedQty: Actual qty in the LPN in eaches
------------------------------------------------------------------------------*/
Create Table SrtrLPNs (
    RecordId                 TRecordId      identity (1,1) not null,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,         --Map to OrderWaveID

    OrderId                  TRecordId,       --Future use
    SalesOrder               TSalesOrder,     --Future use
    OrderType                TTypeCode,       --Future Use
    ShipToStore              TShipToStore,

    LPNId                    TRecordId,
    LPN                      TLPN,            --Map to LPN
    AlternateLPN             TLPN,

    LPNDetailId              TRecordId,       --Future use
    SKUId                    TRecordId,
    SKU                      TSKU,
    Barcode                  TUPC,
    SKUDescription           TDescription,

    ContainerQty             TQuantity,
    AllocatedQty             TQuantity,

    LocationId               TRecordId,
    Location                 TLocation,

    Volume                   TVolume,
    Weight                   TWeight,

    Status                   TStatus        default 'N',

    ExportedStatus           TStatus        default 'N',
    ExportedDate             TDateTime,

    --SorterName             TName,          --Destination

    BusinessUnit             TBusinessUnit  not null,
    Archived                 TFlag          default 'N',
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSrtrLPNs_RecordId PRIMARY KEY (RecordId)
);

create index ix_SrtrLPNs_LPN                     on SrtrLPNs(LPN, WaveNo);
create index ix_SrtrLPNs_WaveNo                  on SrtrLPNs(WaveNo);
create index ix_SrtrLPNs_ExportedStatus          on SrtrLPNs(ExportedStatus desc, WaveId, LPNId);

Go
