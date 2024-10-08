/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/17  AY      InvComparison: Fix issues with not including some Receipts, performance (HI-1539)
  2020/10/12  AY      InvSnapshot, InvComparison: Added InventoryKey (HA-1576)
  2020/07/22  SK      InvSnapshot, InvComparison: Added columns InventoryClass (HA-1180)
  InvComparison: Added Ownership, KeyValue and index
  2019/01/11  HB      Renamed InvVariances table name as InvComparison and also changed constraint,index names as well.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InvComparison
------------------------------------------------------------------------------*/
Create Table InvComparison (
    RecordId                 TRecordId            identity (1,1) not null,
    SKUId                    TRecordId,
    SKU                      TSKU,
    Warehouse                TWarehouse,
    Ownership                TOwnership,
    InventoryClass1          TInventoryClass      default '',
    InventoryClass2          TInventoryClass      default '',
    InventoryClass3          TInventoryClass      default '',

    SS1Id                    TRecordId,
    SS1Date                  TDate,
    SS1AvailableQty          TQuantity,
    SS1ReservedQty           TQuantity,
    SS1OnhandQty             TQuantity,
    SS1ReceivedQty           TQuantity,
    SS1ToShipQty             TQuantity,

    SS2Id                    TRecordId,
    SS2Date                  TDate,
    SS2AvailableQty          TQuantity,
    SS2ReservedQty           TQuantity,
    SS2OnhandQty             TQuantity,
    SS2ReceivedQty           TQuantity,
    SS2ToShipQty             TQuantity,

    ExpReceivedQty           TQuantity            not null default 0,
    ExpInvChanges            TQuantity            not null default 0,
    ExpShippedQty            TQuantity            not null default 0,
    /* Ext Packed Qty is Qty packed in an external system */
    ExtPackedQty             TQuantity            not null default 0,

    Notes                    TVarchar,

    InventoryKey             TKeyValue,
    KeyValue                 as SKU + '-' + coalesce(Warehouse, '') + '-' + coalesce(Ownership, '') +  '-' +
                                coalesce(InventoryClass1, '') + '-' + coalesce(InventoryClass2, '') + '-' + coalesce(InventoryClass3, ''),
    NettQuantity             as (ExpReceivedQty + ExpInvChanges - ExpShippedQty),
    HasActivity              as case when (ExpReceivedQty <> 0)  or (ExpInvChanges <> 0) or (ExpShippedQty <> 0) then 'Y' else 'N' end,
    Balance                  as (coalesce(SS1OnhandQty, 0) + coalesce(ExpReceivedQty, 0) + coalesce(ExpInvChanges, 0) - coalesce(ExpShippedQty, 0)),
    Variance                 as coalesce(SS2OnhandQty, 0) - (coalesce(SS1OnhandQty, 0) + coalesce(ExpReceivedQty, 0) + coalesce(ExpInvChanges, 0) - coalesce(ExpShippedQty, 0)),

    IC_UDF1                  TUDF,
    IC_UDF2                  TUDF,
    IC_UDF3                  TUDF,
    IC_UDF4                  TUDF,
    IC_UDF5                  TUDF,

    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime            default current_timestamp,
    CreatedBy                TUserId,
    CreatedOn                as cast(CreatedDate as date),

    constraint pk_InvComparison_RecordId PRIMARY KEY (RecordId)
);

create index ix_InvComparison_SS1Date            on InvComparison (SS1Date, SS2Date, Balance) include (Variance, HasActivity, NettQuantity);
create index ix_InvComparison_Id                 on InvComparison (SS1Id, SS2Id, Balance) include (Variance, HasActivity, NettQuantity);
create index ix_InvComparison_SS2Date            on InvComparison (SS2Date, Variance);
create index ix_InvComparison_Variance           on InvComparison (Variance, SS2Date, BusinessUnit) Include (RecordId);
create index ix_InvComparison_KeyValue           on InvComparison (KeyValue, BusinessUnit) Include (RecordId);
create index ix_InvComparison_CreatedOn          on InvComparison (CreatedOn, Variance);

Go
