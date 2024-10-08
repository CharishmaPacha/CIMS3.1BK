/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/10/08  TK      PickBatchRules & PickBatches: Added WaveRuleGroup (HPI-838)
  2016/09/25  AY      PickBatchRules: Added Account, ShipFrom & ShipToStore (HPI-Golive)
  2013/09/12  TD      PickBatchRules:Added new fields.
  2013/05/15  TD      Added Carrier field to PickBatchRules.
  PickBatchRules.MaxWeight, OrderWeightMax, OrderWeightMin,
  2013/01/31  AY      PickBatches, PickBatchRules: Added Category fields.
  2012/06/20  AY      Added PickBatchRules.Ownership, Warehouse
  AA      PickBatchRules: Added new field PickZone
  'ixPickBatchesPickZone' & 'ixPickBatchRulesStatus'
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: PickBatchRules
------------------------------------------------------------------------------*/
Create Table PickBatchRules (
    RuleId                   TRecordId      identity (1,1) not null,
    WaveRuleGroup            TDescription,

    BatchingLevel            TDescription,

    /* Order Criteria */
    OrderType                TTypeCode,
    OrderPriority            TPriority,

    ShipVia                  TShipVia,
    Carrier                  TCarrier,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    PickZone                 TZoneId,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    Account                  TAccount,
    ShipFrom                 TShipFrom,
    ShipToStore              TShipToStore,

    OrderWeightMin           TWeight,
    OrderWeightMax           TWeight,
    OrderVolumeMin           TVolume,
    OrderVolumeMax           TVolume,
    OrderInnerPacks          TInteger,
    OrderUnits               TInteger,

    OH_Category1             TCategory,
    OH_Category2             TCategory,
    OH_Category3             TCategory,
    OH_Category4             TCategory,
    OH_Category5             TCategory,

    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    OH_UDF4                  TUDF,
    OH_UDF5                  TUDF,
    OH_UDF6                  TUDF,
    OH_UDF7                  TUDF,
    OH_UDF8                  TUDF,
    OH_UDF9                  TUDF,
    OH_UDF10                 TUDF,

    /* Pick Batch Attributes */
    BatchType                TTypeCode,
    BatchPriority            TPriority,
    BatchStatus              TStatus,
    PickBatchGroup           TWaveGroup,

    /* Order Detail Criteria */
    OrderDetailWeight        TWeight,
    OrderDetailVolume        TVolume,

    /* SKUs Related */
    PutawayClass             TCategory,
    ProdCategory             TCategory,     --Future Use
    ProdSubCategory          TCategory,     --Future Use
    PutawayZone              TLookUpCode,

    /* Limiting Criteria */
    MaxOrders                TCount,
    MaxLines                 TCount,
    MaxSKUs                  TCount,
    MaxUnits                 TCount,
    MaxWeight                TWeight,
    MaxVolume                TVolume,
    MaxLPNs                  TCount,
    MaxInnerPacks            TCount,

    DestZone                 TLookUpCode,
    DestLocation             TLocation,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    SortSeq                  TSortSeq       not null default 0,
    Status                   TStatus        not null default 'A' /* Active */,
    VersionId                TRecordId,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPickBatchRules_RuleId PRIMARY KEY (RuleId)
);

create index ix_PickBatchRules_Status            on PickBatchRules (Status, BusinessUnit);

Go
