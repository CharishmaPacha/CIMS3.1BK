/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/06/08  AY      Added TLPNsToGenerate
  Create Type TLPNsToGenerate as Table (
  Grant References on Type:: TLPNsToGenerate to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Table type to be used to generate LPNs w/ details in bulk */
Create Type TLPNsToGenerate as Table (
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNSeqNo                 TLPN,
    LPNType                  TTypeCode,

    SKUId                    TRecordId,
    InnerPacks               TInnerPacks,
    Quantity                 TQuantity,

    Status                   TStatus,
    OnhandStatus             TStatus,

    OrderId                  TRecordId,
    OrderDetailId            TRecordId,

    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,

    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,

    TaskId                   TRecordId,
    TaskDetailId             TRecordId,

    DestZone                 TZoneId,
    PalletId                 TRecordId,
    Pallet                   TPallet,
    LocationId               TRecordId,
    Location                 TLocation,

    Ownership                TOwnership,
    Warehouse                TWarehouse,

    FromLPNId                TRecordId,
    FromLPNDetailId          TRecordId,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId),
    Unique                   (LPNSeqNo, RecordId)
);

Grant References on Type:: TLPNsToGenerate to public;

Go
