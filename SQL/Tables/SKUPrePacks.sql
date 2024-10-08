/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/16  MS      SKUPrePacks: Added MasterSKU & ComponentSKU (JL-261)
  2013/07/30  PK      SKUPrePacks: Added BusinessUnit
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: SKUPrePacks
------------------------------------------------------------------------------*/
Create Table SKUPrePacks (
    SKUPrePackId             TRecordId      identity (1,1) not null,

    MasterSKUId              TRecordId      not null,
    MasterSKU                TSKU,
    ComponentSKUId           TRecordId      not null,
    ComponentSKU             TSKU,

    ComponentQty             TQuantity      not null CHECK (ComponentQty > 0) default 1,
    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq       not null default 0,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSKUPrePacks_SKUId PRIMARY KEY (SKUPrePackId),
    constraint ukSKUPrePacks_SKU   UNIQUE (MasterSKUId, ComponentSKUId)
);

create index ix_SKUPrePacks_Status               on SKUPrepacks (MasterSKUId, Status, Archived);
create index ix_SKUPrepacks_COMPSKUPrePackStatus on SKUPrepacks (ComponentSKUId) Include (MasterSKUId, Status, ComponentQty);

Go
