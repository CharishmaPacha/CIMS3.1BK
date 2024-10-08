/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/12  TD      Added PutawayRules.LocationClass - CIMS-1750
  2013/03/31  AY      PutawayRules: Added PAType
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: PutawayRules

  PalletPutawayClass could be used in multiple ways: For Pallet Putaway it could
    be used to determine the location based upon the PalletPAClass. For LPN Putaway
    it could be used to find a Pallet of that PAClass.
------------------------------------------------------------------------------*/
Create Table PutawayRules (
    RecordId                 TRecordId           identity (1,1) not null,

    SequenceNo               TInteger            not null,

    PAType                   TTypeCode,
    LPNType                  TTypeCode,
    PalletType               TTypeCode,
    SKUPutawayClass          TPutawayClass,
    LPNPutawayClass          TPutawayClass,
    PalletPutawayClass       TPutawayClass,

    LocationType             TLocationType,
    StorageType              TStorageType,
    LocationStatus           TStatus,
    PutawayZone              TLookupCode,
    Location                 TLocation,
    SKUExists                TFlag,

    LocationClass            TCategory,

    Warehouse                TWarehouse,

    Status                   TStatus             not null default 'A' /* Active*/,

    BusinessUnit             TBusinessUnit       not null,
    CreatedDate              TDateTime           default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPutawayRules_RecordId PRIMARY KEY (RecordId)
);

Go
