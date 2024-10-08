/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/10  TK      TTaskDetailsInfoTable: Added PickedBy (CID-1704)
  2020/11/30  TK      TTaskDetailsInfoTable: Added FromLPNType, TDUnitsToPick & Reason (CID-1545)
  2020/06/10  TK      TTaskDetailsInfoTable: Added InventoryClasses (HA-880)
  2019/05/15  SV      TTaskDetailsInfoTable: Added CoO (CID-135)
  2019/03/22  TK      TTaskDetailsInfoTable: Added FromLPNOwnership (S2GCA-534)
  2019/01/27  TK      TTaskDetailsInfoTable: Added FromLDUnitsPerPackage (S2GMI-79)
  2016/11/11  VM      TTaskDetailsInfoTable: Added (HPI-993)
  Create Type TTaskDetailsInfoTable as Table (
  Grant References on Type:: TTaskDetailsInfoTable to public;
------------------------------------------------------------------------------*/

Go

Create Type TTaskDetailsInfoTable as Table (
    TaskDetailId             TRecordId,
    TaskId                   TRecordId,
    PickType                 TTypeCode,

    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    OrderDetailId            TRecordId,

    FromLocationId           TRecordId,
    FromLocation             TLocation,

    FromLPNId                TRecordId,
    FromLPN                  TLPN,
    FromLPNType              TTypeCode,
    FromLPNOwnership         TOwnership,
    FromLPNWarehouse         TWarehouse,
    FromLPNInventoryClass1   TInventoryClass      DEFAULT '',
    FromLPNInventoryClass2   TInventoryClass      DEFAULT '',
    FromLPNInventoryClass3   TInventoryClass      DEFAULT '',
    FromLPNDetailId          TRecordId,
    FromLDOnhandStatus       TStatus,
    FromLDQuantity           TQuantity,
    FromLDUnitsPerPackage    TUnitsPerPack,

    SKUId                    TRecordId,
    SKU                      TSKU,
    TDInnerPacks             TInnerPacks,
    TDQuantity               TQuantity,
    TDUnitsToPick            TQuantity,

    PalletId                 TRecordId,
    Pallet                   TPallet,

    IsTaskAllocated          TFlag,
    IsLabelGenerated         TFlag          not null DEFAULT 'N' /* No */,

    TempLabelId              TRecordId,
    TempLabel                TLPN,
    TempLabelDtlId           TRecordId,
    TempLabelDtlQty          TQuantity,

    ToLPNId                  TRecordId,
    ToLPN                    TLPN,
    ToLPNDtlId               TRecordId,
    ToLPNDtlQty              TQuantity,
    CoO                      TCoO,

    QtyPicked                TQuantity,
    PickedBy                 TUserId,

    RecordAction             TOperation,
    FromLPNAction            TOperation,
    ToLPNAction              TOperation,
    Reason                   TVarchar,

    ActivityType             TActivityType,
    ATComment                TVarChar

    Unique                   (PickBatchNo, OrderId, RecordId),
    RecordId                 TRecordId      identity (1,1)
);

Grant References on Type:: TTaskDetailsInfoTable to public;

Go
