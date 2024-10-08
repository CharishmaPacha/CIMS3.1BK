/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/14  TK      TPickBatchRules: Added Status (BK-64)
  2016/10/08  TK      TPickBatchRules: Added WaveRuleGroup (HPI-838)
  2016/09/25  VM      TPickBatchRules: Added Account, ShipFrom, ShipToStore (HPI-GoLive)
  2013/09/17  TD      Added TPickBatchRules.
  Create Type TPickBatchRules as Table (
  Grant References on Type:: TPickBatchRules to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Pick batches */
Create Type TPickBatchRules as Table (
    RuleId                   TRecordId,
    WaveRuleGroup            TDescription,
    BatchingLevel            TDescription,
    OrderType                TTypeCode,
    OrderPriority            TPriority,
    ShipVia                  TShipVia,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    Account                  TAccount,
    ShipFrom                 TShipFrom,
    ShipToStore              TShipToStore,
    BatchType                TTypeCode,
    BatchPriority            TPriority,
    BatchStatus              TStatus,
    MaxOrders                TCount,
    MaxLines                 TCount,
    MaxSKUs                  TCount,
    MaxUnits                 TCount,
    MaxLPNs                  TCount,
    MaxInnerPacks            TCount,
    MaxWeight                TWeight,
    MaxVolume                TVolume,
    OrderWeightMin           TWeight,
    OrderWeightMax           TWeight,
    OrderVolumeMin           TVolume,
    OrderVolumeMax           TVolume,
    OrderInnerPacks          TInteger,
    OrderUnits               TInteger,
    PickBatchGroup           TWaveGroup,
    OrderDetailWeight        TWeight,
    OrderDetailVolume        TVolume,
    PutawayClass             TCategory,
    ProdCategory             TCategory,
    ProdSubCategory          TCategory,
    PutawayZone              TZoneId,
    SortSeqNo                TSortSeq,
    DestZone                 TLookUpCode,
    DestLocation             TLocation,
    PickZone                 TZoneId,
    Status                   TStatus,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    OH_UDF4                  TUDF,
    OH_UDF5                  TUDF,

    OH_Category1             TCategory,
    OH_Category2             TCategory,
    OH_Category3             TCategory,
    OH_Category4             TCategory,
    OH_Category5             TCategory,

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TPickBatchRules to public;

Go
