/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TTaskBuildCriteria: TDCategory1 to 5 and UDF1 to 5 (CID-931)
  Create Type TTaskBuildCriteria as Table (
  Grant References on Type:: TTaskBuildCriteria to public;
------------------------------------------------------------------------------*/

Go

/* Criteria to hold the criteria to add details to a task */
Create Type TTaskBuildCriteria as Table (
    /* Task */
    TaskId                   TRecordId,

    TDCategory1              TCategory,
    TDCategory2              TCategory,
    TDCategory3              TCategory,
    TDCategory4              TCategory,
    TDCategory5              TCategory,

    /* Threshold */
    MaxOrders                TCount,
    MaxTempLabels            TCount,
    MaxInnerPacks            TInnerPacks,
    MaxUnits                 TQuantity,
    MaxCases                 TCount,
    MaxWeight                TWeight,
    MaxVolume                TVolume,
    MaxCount1                TCount         default 99999,
    MaxCount2                TCount         default 99999,
    MaxCount3                TCount         default 99999,
    /* Current Counts */
    TaskOrders               TCount         default 0,
    TaskTempLabels           TCount         default 0,
    TaskInnerPacks           TInnerPacks    default 0,
    TaskUnits                TQuantity      default 0,
    TaskCases                TCount         default 0,
    TaskWeight               TWeight        default 0,
    TaskVolume               TVolume        default 0,
    TaskCount1               TCount         default 0,
    TaskCount2               TCount         default 0,
    TaskCount3               TCount         default 0,
    /* Computed */
    CanAddDetails            as case when (TaskOrders     <= coalesce(MaxOrders,     999))   and
                                          (TaskTempLabels <= coalesce(MaxTempLabels, 999))   and
                                          (TaskInnerPacks <= coalesce(MaxInnerPacks, 99999)) and
                                          (TaskUnits      <= coalesce(MaxUnits,      99999)) and
                                          (TaskWeight     <= coalesce(MaxWeight,     99999)) and
                                          (TaskVolume     <= coalesce(MaxVolume,     999999)) and
                                          (TaskCount1     <= coalesce(MaxCount1,     999999)) and
                                          (TaskCount2     <= coalesce(MaxCount2,     999999)) and
                                          (TaskCount3     <= coalesce(MaxCount3,     999999))
                                     then 'Y' else 'N' end,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    /* Keys */
    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId),
    Unique                   (TaskId, RecordId)
);

Grant References on Type:: TTaskBuildCriteria to public;

Go
