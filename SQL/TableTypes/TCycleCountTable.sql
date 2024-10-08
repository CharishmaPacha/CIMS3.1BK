/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/21  AY      TCycleCountTable: Moved to domains_temptables due to dependencies
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Table of entity key values to pass around values to stored procedures */
Create Type TCycleCountTable as Table (
    EntityId                 TRecordId,
    EntityKey                TEntityKey,
    EntityType               TEntity,
    NewLPNs                  TInteger,
    NewInnerPacks            TInteger,
    NewQuantity              TInteger,
    NewUnitsPerInnerPack     TInteger,
    LocationId               TRecordId,
    PalletId                 TRecordId,
    LPNId                    TRecordId,
    SKUId                    TRecordId,
    Pallet                   TPallet,
    LPN                      TLPN,
    SKU                      TEntity,
    RecordId                 TRecordId      Identity(1,1),

    Primary Key              (RecordId),
    Unique                   (EntityKey, EntityId)
);

Grant References on Type:: TCycleCountTable to public;

Go
