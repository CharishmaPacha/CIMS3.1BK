/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/29  TK      ix_Tasks_PrintStatus: Added (CIDV3-676)
  2020/11/09  AJM     Tasks : For PrintStatus field changed datatype from TPrintStatus to TStatus (CIMSV3-1201)
  2020/07/29  RV      Tasks: Added PrintStatus (S2GCA-1199)
  2020/07/13  VS      Tasks: Added ix_Tasks_PalletId index (S2GCA-1180)
  2020/06/30  RKC     Tasks: Add ModifiedOn computed column and index (CIMS-3118)
  2019/08/09  AJ      Tasks: Added PrintedTime (OB2-898)
  2019/03/06  NB      Added Tasks.LPNCount(CIMSV3-370)
  2018/12/06  TK      Tasks: Added CartType (HPI-2049)
  2018/11/17  AY      Tasks: Added OrderId, UDF6-10
  2018/11/06  MS      Tasks: Added UnitsCompleted & UnitsToPick (OB2-701)
  2018/02/23  TK      Tasks & TaskDetails: If DependencyFlags is defaulted to 'N' then user would be
  2018/02/20  TK      Tasks: WaveId would be null for Cyclecount Tasks (S2G-152)
  2018/02/13  TK      Tasks: Added WaveId & IsTaskConfirmed
  2018/02/08  TD      Tasks:Added PickGroup (S2G-218).
  2017/09/05  AY      LPNTasks: Added ix_LPNTasks_TaskId
  2017/05/15  AY      Tasks: Added Pallet, StartTime, EndTime, Duration (CIMS-1400)
  2016/10/20  AY/PK   Added index ix_Tasks_Archived for Tasks table (HPI-GoLive)
  2016/10/05  AY      Tasks: Added DependentOn to show the list of Replenish Tasks that this task depends upon (HPI-GoLive)
  2016/09/11  AY      ix_Tasks_BatchNo: Revised (HPI-GoLive)
  2016/08/18  AY      Tasks: Added Location ranges (HPI-484)
  2016/06/07  AY      Tasks: Enhanced indices
  2016/02/09  TD      Tasks: Added Ownership.
  2015/06/26  VS      Tasks: Added OrderCount
  2015/06/06  AY      Tasks: Added PalletId
  2015/05/08  TK      Tasks: Added IsTaskAllocated.
  2014/09/26  NB      Tasks: Added LabelsPrinted
  2014/09/12  AY      Tasks: Added TaskCategory and UDF fields
  2014/05/07  AY      Tasks: Added TotalCases, TotalUnits
  2014/04/18  TD      Added LPNTasks.
  2012/09/06  AY      Tasks: Changed ScheduledDate to Date
  2012/07/16  AY      Tasks: Added Warehouse.
  2012/03/27  AY      Added index on Tasks by BatchNo
  2012/01/25  PKS     Tasks: Added ScheduledDate.
  2012/01/04  VM      Tasks: Added TaskDesc
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Task Headers

  Dependency Flags: R - Waiting on Replenishment
                    C - Replenishment Completed
                    blank or null - no Dependency

  PickZones: Consolidated List of zones
------------------------------------------------------------------------------*/
Create Table Tasks (
    TaskId                   TRecordId      identity (1,1) not null,

    TaskType                 TTypeCode      not null,
    TaskSubType              TTypeCode      not null,
    TaskDesc                 TDescription,
    Status                   TStatus,

    ScheduledDate            TDate,
    DetailCount              TInteger,
    CompletedCount           TInteger,

    TotalInnerPacks          TInteger,
    TotalUnits               TInteger,
    -- NumLPNPicks           TCount,
    -- NumUnitPicks          TCount,

    /* Using terminology Completed and Remaining as the Tasks may not always be for picking
       and they could be expanded to be used other operations as well like Putaway etc. */
    TotalIPsCompleted        TInteger       default 0,
    TotalUnitsCompleted      TInteger       default 0,
    TotalIPsRemaining        As (TotalInnerPacks - TotalIPsCompleted),
    TotalUnitsRemaining      As (TotalUnits - TotalUnitsCompleted),

    NumOrders                TCount,
    NumLPNs                  TCount,
    NumCases                 TCount,
    NumTempLabels            TCount,
    NumLocations             TCount,
    NumDestinations          TCount,

    UnitsCompleted           TQuantity      default 0, -- deprecated, use TotalUnitsCompleted instead
    OrderCount               TCount, -- deprecated, use NumOrders going forward
    LPNCount                 TCount, -- deprecated, use NumLPNs going forward

    WaveId                   TRecordId,
    BatchNo                  TTaskBatchNo   not null,
    PickZone                 TZoneId,
    PickZones                TZones,
    PutawayZone              TZoneId,
    Priority                 TPriority,
    Warehouse                TWarehouse,

    DestZone                 TLookUpCode,
    DestLocation             TLocation,
    PalletId                 TRecordId,
    Pallet                   TPallet,
    CartType                 TTypeCode,

    StartLocation            TLocation,
    EndLocation              TLocation,
    StartDestination         TLocation,
    EndDestination           TLocation,

    AssignedTo               TUserId,

    TaskCategory1            TCategory,
    TaskCategory2            TCategory,
    TaskCategory3            TCategory,
    TaskCategory4            TCategory,
    TaskCategory5            TCategory,

    LabelsPrinted            TFlags         not null default 'N' /* No */,
    PrintStatus              TStatus        not null default 'OnHold',
    IsTaskAllocated          TFlags         not null default 'N' /* No */,
    IsTaskConfirmed          TFlags         not null default 'N' /* No */,
    DependencyFlags          TFlags,
    DependentOn              TDescription,

    PickGroup                TPickGroup,

    StartTime                TDateTime,
    EndTime                  TDateTime, -- deprecated, do not use
    StopTime                 TDateTime,
    ElapsedMins              TInteger       not null default 0,
    DurationInMins           as ElapsedMins + cast(datediff(mi /* minutes */, convert(Datetime, StartTime, 121), convert(Datetime, StopTime, 121)) As varchar(50)),
    CompletedDate            as case when Status = 'C' then cast(StopTime as date) else null end,
    PrintedDateTime          TDateTime,
    PrintDate                as convert(date, PrintedDateTime),

    Ownership                TOwnership,
    OrderId                  TRecordId,

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

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    ModifiedOn               as convert(date, ModifiedDate),

    constraint pkTasks_TaskId PRIMARY KEY (TaskId)
);

create index ix_Tasks_Archived                   on Tasks (Archived, TaskType) Include (Status, TaskId, ModifiedOn) where (Archived = 'N');
create index ix_Tasks_TaskType                   on Tasks (TaskType, TaskSubType, DestZone, Archived) Include (TaskId, BatchNo, Status, PickZone);
create index ix_Tasks_Status                     on Tasks (Status, TaskType, TaskSubType)
                                                    Include (AssignedTo, TaskId, PickZone, DestZone, PickGroup, PrintStatus)
                                                    where (Archived = 'N');
/* Used in allocation: create pick tasks */
create index ix_Tasks_BatchNo                    on Tasks (BatchNo, TaskType, Status, PickZone, DestZone, PickGroup) Include (Archived, DependencyFlags);
/* used in pr_TaskDetails_UpdateDependentOn */
create index ix_Tasks_Dependency                 on Tasks (DependencyFlags) Include (TaskId, Status, BatchNo);
create index ix_Tasks_WaveId                     on Tasks (WaveId, TaskType, Status) Include (Archived, DependencyFlags, PrintStatus);
/* Used in pr_Picking_ValidatePallet */
create index ix_Tasks_PalletId                   on Tasks (PalletId, Status) Include (TaskId);
/* Used in re-computing PrintStatus */
create index ix_Tasks_PrintStatus                on Tasks (PrintStatus) include (TaskType, Status) where (Archived = 'N');

Go
