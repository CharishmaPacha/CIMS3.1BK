/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/29  TK      TaskDetails: Added PickGroup (CID-1652)
  2020/10/30  TK      TaskDetails: Added ExportStatus (CID-1489)
  2020/08/05  TK      TaskDetails: Added CartType (HA-1137)
  2019/11/25  VS      Added Check constraint pkTaskDetails_UnitsCompleted on TaskDetails (CID-1076)
  2018/10/17  AY      TaskDetails.PackingGroup: Added to determine which details can be packed or cubed together (S2GCA-383)
  2018/08/02  AY      TaskDetails.PickSequence: Added to determine the sequence to pick the tasks (OB2-396)
  2018/06/11  YJ      TaskDetails: ix_TaskDetails_LocationId: Migrated from staging (S2G-727)
  2018/06/05  OK      TaskDetails: Added RequestedCCLevel, ActualCCLevel fields to determine CC levels (S2G-217)
  2018/04/23  TK      TaskDetails: Added task detail MergeCriteria fields (S2G-493)
  2018/03/14  TD      TaskDetails:Added UnitsToPick in index for picking purpose (S2G-422)
  2018/02/23  TK      Tasks & TaskDetails: If DependencyFlags is defaulted to 'N' then user would be
  TaskDetails: Added WaveId (S2G-153)
  2018/02/09  TD      TaskDetails:Added PickType to the index for cubing (S2G-107)
  2018/02/01  TK      TaskDetails: Added DependencyFlags (S2G-179)
  2017/01/05  AY      TaskDetails: Added index ix_TaskDetails_LPNId (HPI-GoLive)
  2016/12/06  PK      TaskDetails: Added TempLabelDetailId
  2016/11/02  OK      TaskDetails: Added DependentOn field (HPI-978)
  2016/08/10  AY      TaskDetails: Added PickPosition (the position on cart it needs to be picked to)
  2016/06/28  TK      TaskDetails: Removed Foreign Key (HPI-162)
  2016/06/25  AY      TaskDetails: Added PickType, PickBatchNo (HPI-162)
  2016/06/09  TK      TaskDetails: Added UnitsToPick, DependencyFlag
  2016/01/26  TD      TaskDetails:Added detailcategory fields.
  2015/05/06  TK      TaskDetails: Added TempLPNId.
  2014/04/18  TD      TaskDetails: Added new column IsLabelGenerated.
  2013/11/26  AY      Created indices ixTaskDetails_TaskId, ixTaskDetails_PalletId
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Task Details

   This table is the list of picks within a Task.

   PickZone: Is the zone the particular Pick is from
   PickZones: Is the list of pickzones of all the related TaskDetails. For example,
     if the TDs are cubed, then the Pick Zones will the the list of zones for all
     the picks to the cubed temp label. i.e. PickZone is the list of zones for
     all TDs of the group
------------------------------------------------------------------------------*/
Create Table TaskDetails (
    TaskDetailId             TRecordId      identity (1,1) not null,
    TaskId                   TRecordId      not null,

    Status                   TStatus        not null default 'N' /* Not yet started */,
    TransactionDate          TDateTime,

    LocationId               TRecordId,
    LPNId                    TRecordId,
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    LPNDetailId              TRecordId,
    SKUId                    TRecordId,
    PalletId                 TRecordId,

    DestZone                 TLookupCode,
    DestLocation             TLocation,

    InnerPacks               TInnerPacks,
    Quantity                 TQuantity,
    InnerPacksCompleted      TQuantity      default 0,
    UnitsCompleted           TQuantity      default 0,
    InnerPacksToPick         As case when Status in ('X', 'C') then 0
                                     else (coalesce(InnerPacks, 0) - coalesce(InnerPacksCompleted, 0))
                                end,

    UnitsToPick              As case when Status in ('X', 'C') then 0
                                     else (coalesce(Quantity, 0) - coalesce(UnitsCompleted, 0))
                                end,

    Variance                 TFlags,

    IsLabelGenerated         TFlags         not null default 'N' /* No */,
    TempLabelId              TRecordId,
    TempLabel                TLPN,
    TempLabelDetailId        TRecordId,
    PickPosition             TLPN,

    PickGroup                TPickGroup,
    PickType                 TTypeCode,
    CartType                 TTypeCode,
    WaveId                   TRecordId,
    PickBatchNo              TPickBatchNo,
    Warehouse                TWarehouse,
    PickSequence             TPickSequence,
    PackingGroup             TCategory      default '',  -- identifies which tasks can be cubed together

    LocationType             TTypeCode,
    LocationTypes            TDescription,
    PickZone                 TZoneId,
    PickZones                TDescription, -- list of zones for a temp label or an order

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

    DependencyFlags          TFlags,
    DependentOn              TDescription,

    DateCompleted            as case when Status = 'C' then cast(ModifiedDate as date) else null end,

    RequestedCCLevel         TTypeCode,
    ActualCCLevel            TTypeCode,
    ExportStatus             TStatus      default 'NotRequired', /* NotRequired, WaitingOnReplen, ReadyToExport, Exported */

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

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkTaskDetails_TaskDetailId PRIMARY KEY (TaskDetailId),
    constraint ccTaskDetails_UnitsCompleted CHECK (UnitsCompleted <= Quantity)
);

create index ix_TaskDetails_LPNDetailId          on TaskDetails (LPNDetailId) Include (Status, TaskId);
/* Picking */
create index ix_TaskDetails_TaskId               on TaskDetails (TaskId, Status)
                                               Include (TaskDetailId, DestZone, InnerPacks, Quantity,
                                                        LocationType, OrderId, PickPosition, UnitsToPick, TempLabelId, SKUId);
create index ix_TaskDetails_PalletId             on TaskDetails (PalletId, Status) Include (TaskId, TaskDetailId);
/* Picktype is needed for cubing */
create index ix_TaskDetails_OrderId              on TaskDetails(OrderId, Status) Include (TaskId, TaskDetailId, OrderDetailId, PickType, LocationId);
/* Used in LPN_Move to update Location of all open tasks details of the LPN when LPN is moved
   Also used in pr_LPNs_RecomputeWaveAndTaskDependencies */
create index ix_TaskDetails_LPNId                on TaskDetails(LPNId, Status) Include (TaskDetailId, TaskId, DependencyFlags);
/* Qty needed for Alerts mismatch of OD UnitsAssigned */
create index ix_TaskDetails_OrderDetailId        on TaskDetails(OrderDetailId) Include (TaskId, TaskDetailId, Status, Quantity);
create index ix_TaskDetails_TDCategory1          on TaskDetails(TDCategory1, TDCategory2) Include (TaskId, TaskDetailId, Status);
create index ix_TaskDetails_TDCategory2          on TaskDetails(TDCategory2, TDCategory1) Include (TaskId, TaskDetailId, Status);
/* Used for Allocation_CreatePickTasks */
create index ix_TaskDetails_PickBatchNo          on TaskDetails(PickBatchNo, TaskId, BusinessUnit) Include (TaskDetailId, Status);
/* Needed in Cubing */
create index ix_TaskDetails_TempLabelId          on TaskDetails(TemplabelId, PickBatchNo) Include (TaskDetailId, SKUId, Status, OrderId, OrderDetailId, LocationId);
create index ix_TaskDetails_DateCompleted        on TaskDetails(DateCompleted, ModifiedBy) Include (PickType, UnitsCompleted, Status);
create index ix_TaskDetails_LocationId           on TaskDetails (LocationId, Status) Include (TaskDetailId, TaskId)
/* Used in update TDCategories */
create index ix_TaskDetails_WaveId               on TaskDetails (WaveId, TaskId) Include (TaskDetailId, Status, PickType, OrderId, LocationId, TempLabel, LPNId, PickPosition);
/* Used in Task Cancel */
create index ix_TaskDetails_Status               on TaskDetails (Status) Include(TaskId, TaskDetailId, LPNId, LPNDetailId, OrderId, OrderDetailId, PalletId, Quantity, IsLabelGenerated) where (Status in ('O', 'N', 'I'));
/* Used in Allocation */
create index ix_TaskDetails_MergeCriteria1       on TaskDetails (TDMergeCriteria1) Include(TaskId, TaskDetailId, LPNId, LPNDetailId, OrderId, OrderDetailId, PalletId, Quantity, IsLabelGenerated) where (Status in ('O', 'N', 'I'));
/* Used to export API Transactions */
create index ix_TaskDetails_ExportStatus         on TaskDetails (ExportStatus) Include(TaskId, TaskDetailId, WaveId)

Go
