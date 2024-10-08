/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/18  AY      Added TSKUInquiry (V3)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
Inquiry
------------------------------------------------------------------------------*/
/* Table Type to use for collecting all the waves to allocate */
Create Type TSKUInquiry as Table (
    RecordId                   TRecordId    identity (1,1),
    RecordType                 TTypeCode    default 'SKUInfo',
    PutawayZone                TLookUpCode,
    Location                   TLocation,
    Quantity                   TQuantity,
    ReservedQty                TQuantity,
    OnHandStatDesc             TDescription,
    LPNTypeDesc                TDescription,
    LPN                        TLPN,
    LocTypeDesc                TDescription,
    Warehouse                  TDescription,
    FieldName                  TEntity,
    FieldValue                 TDescription,
    FieldVisible               TInteger     Default 1,  /* 2: Always Show, 1 - Show if not null, -1 do not show */
    SortSeq                    TInteger     Default 0
);

Grant References on Type:: TSKUInquiry to public;

Go
