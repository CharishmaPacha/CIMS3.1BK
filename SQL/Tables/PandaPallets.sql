/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/18  AY      Enhanced fields on PandaLabels & Added New table - PandaPallets
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: PandaPallets - Pallet records need to be integrate with PandA System.

  When a set of LPNs on a Pallet have to be labelled or verified, we insert
  a record in this table. Later, when the

------------------------------------------------------------------------------*/
Create Table PandaPallets (
    RecordId                 TRecordId      identity (1,1) not null,

    PalletId                 TRecordId,
    Pallet                   TPallet,
    Operation                TOperation,

    ProcessStatus            TStatus        default 'N' /* Not processed */,
    ProcessedDateTime        TDateTime,

    ExportStatus             TStatus        default 'N' /* Not exported */,
    ExportDateTime           TDateTime,

    PandAStation             TName,
    ErrorMessage             TVarChar,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPandaPallets_RecordId PRIMARY KEY (RecordId)
);

create index ix_PandAPallets_Pallet              on PandaPallets (Pallet);
create index ix_PandAPallets_PalletId            on PandaPallets (PalletId);
create index ix_PandAPallets_ProocessStatus      on PandaPallets (ProcessStatus, PandAStation) include (RecordId);
create index ix_PandAPallets_ExportStatus        on PandaPallets (ExportStatus,  PandAStation) include (RecordId);

Go
