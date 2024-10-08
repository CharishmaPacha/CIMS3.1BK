/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/13  AY      TTaskInfoTable: Added TDCount fields and ProcessFlag (CIMSV3-1387)
  2021/11/05  TK      TTaskInfoTable: Added TaskSubType & other required fields for task cancellation (CIMSV3-1490)
  2021/07/06  TK      TTaskInfoTable: Added InventoryClasses (HA-2923)
  2020/08/04  TK      TTaskInfoTable: Added CartType (HA-1137)
  2020/04/26  TK      TTaskInfoTable: Added DestLocationId (HA-86)
  2020/04/16  TK      TTaskInfoTable: Added Processed flag (HA-171)
  2019/08/25  TK      TTaskInfoTable: Added InnerPackWeight and InnerPackVolume
  2019/01/31  TK      TTaskInfoTable: Added UnitsPerInnerpack (S2GMI-79)
  2018/10/17  AY      TTaskInfoTable: Added PackingGroup (S2GCA-383)
  2018/04/23  TK      TTaskInfoTable: Added task detail MergeCriteria fields (S2G-493)
  2018/03/15  TK      TTaskInfoTable: Added TDStatus, TDInnerpacks & TDQuantity (S2G-423)
  2018/03/11  TK      TTaskInfoTable: Added TDCategory & UDF fields ()
  2017/01/23  TK      TTaskInfoTable: Added TempLabelDetailId field (HPI-1274)
  2016/11/01  YJ      TTaskInfoTable: Added IsLabelGenerated, IsTaskAllocated (CIMS-1146)
  2016/06/25  AY      TTaskInfoTable: Added DestLocationType, TaskId, TaskDetailId (HPI-162)
  2015/07/24  TK      TTaskInfoTable: Added PalletId(FB-265)
  2015/05/02  TK      TTaskInfoTable: Added CartonType, TempLabel
  2014/04/01  TD      TTaskInfoTable: Added PickType,LocationType, LPNType,
  Create Type TTaskInfoTable as Table (
  Grant References on Type:: TTaskInfoTable to public;
------------------------------------------------------------------------------*/

Go

Create Type TTaskInfoTable as Table (
    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    OrderDetailId            TRecordId,
    PalletId                 TRecordId,
    Pallet                   TPallet,
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNDetailId              TRecordId,
    LocationId               TRecordId,
    UnitsToAllocate          TQuantity,
    SKUId                    TRecordId,
    SKU                      TSKU,

    UnitsPerInnerpack        TInteger,
    InnerPacks               TInnerPacks,
    Quantity                 TQuantity,

    CartonType               TCartonType,
    CartonWidth              TWidth,
    CartonHeight             THeight,
    TempLabelId              TRecordId,
    TempLabel                TLPN,
    TempLabelDetailId        TRecordId,
    TempLabelPalletId        TRecordId,
    TempLabelPallet          TPallet,

    IsLabelGenerated         TFlags         not null DEFAULT 'N' /* No */,
    IsTaskAllocated          TFlags         not null DEFAULT 'N' /* No */,

    PickPath                 TLocation,
    PickZone                 TZoneId,
    TotalWeight              TWeight,
    TotalVolume              TVolume,
    InnerPackWeight          TWeight,
    InnerPackVolume          TVolume,
    UnitWeight               TWeight,
    UnitVolume               TVolume,

    DestZone                 TName,
    DestLocationId           TRecordId,
    DestLocation             TLocation,
    DestLocationType         TTypeCode,

    TaskGroup1               TCategory,
    TaskGroup2               TCategory,
    TaskGroup3               TCategory,

    TaskCategory1            TCategory,
    TaskCategory2            TCategory,
    TaskCategory3            TCategory,
    TaskCategory4            TCategory,
    TaskCategory5            TCategory,

    TDCategory1              TCategory,
    TDCategory2              TCategory,
    TDCategory3              TCategory,
    TDCategory4              TCategory,
    TDCategory5              TCategory,

    TDMergeCriteria1         TCategory,
    TDMergeCriteria2         TCategory,
    TDMergeCriteria3         TCategory,
    TDMergeCriteria4         TCategory,
    TDMergeCriteria5         TCategory,

    PackingGroup             TCategory,
    PickSequence             TPickSequence,

    PickType                 TTypeCode,
    CartType                 TControlValue,
    Location                 TLocation,
    LocationType             TTypeCode,
    StorageType              TTypeCode,
    LPNType                  TTypeCode,
    OrderType                TTypeCode,

    TaskId                   TRecordId,
    TaskSubType              TTypeCode,
    TaskStatus               TStatus,
    TDCount                  TCount,
    TDCompletedCount         TCount,
    TDRemainingCount         TCount,
    TaskDetailId             TRecordId,
    TDStatus                 TStatus,
    TDInnerpacks             TInnerpacks,
    TDQuantity               TQuantity,

    FromLPN                  TLPN,
    FromLPNInnerPacks        TQuantity,
    FromLPNQty               TQuantity,
    FromLPNPickingClass      TPickingClass,

    Warehouse                TWarehouse,
    Ownership                TOwnership,

    InventoryClass1          TInventoryClass    DEFAULT '',
    InventoryClass2          TInventoryClass    DEFAULT '',
    InventoryClass3          TInventoryClass    DEFAULT '',

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,

    Processed                TFlags,
    ProcessFlag              TFlags,

    RecordId                 TRecordId      identity (1,1)
    Primary Key              (RecordId),
    Unique                   (TaskDetailId, RecordId), -- Used in CreatePickTasks_PTS
    Unique                   (TempLabelId, RecordId)   -- Used in CreatePickTasks_PTS
);

Grant References on Type:: TTaskInfoTable to public;

Go
