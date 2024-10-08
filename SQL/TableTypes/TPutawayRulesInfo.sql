/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/12  TD      TPutawayRulesInfo:Added LocationClass (CIMS-1750)
  2014/09/17  PKS     Added TPutawayRulesInfo and TEntityStatusCounts to Domains_TempTables.Sql
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
Inventory Table Domains
------------------------------------------------------------------------------*/
Create Type TPutawayRulesInfo as Table (
    RecordId                 TRecordId      identity (1,1) not null,

    SequenceNo               TInteger       not null,

    PAType                   TTypeCode,
    SKUPutawayClass          TCategory,
    LPNPutawayClass          TCategory,
    PalletType               TTypeCode,
    LPNType                  TTypeCode,

    PutawayZone              TLookupCode,
    LocationType             TLocationType,
    StorageType              TStorageType,
    LocationStatus           TStatus,
    Location                 TLocation,
    SKUExists                TFlag,

    LocationClass            TCategory,

    Status                   TStatus        not null DEFAULT 'A' /* Active*/
);

Grant References on Type:: TPutawayRulesInfo to public;

Go
