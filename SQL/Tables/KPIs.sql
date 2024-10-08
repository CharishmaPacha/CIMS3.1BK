/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/22  AY      KPIs: Added new table (HA-3019)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: KPIs - Key Performance Indicators

 KPIClass      - There may be different KPIs built for different purposes or with
                 different level of detail and those are distinguished by KPIClass
                 for ex. daily operational summary is one type of statistics. 
 Operation     - Picking, Receiving
 SubOperation1 - Case Pick, PTS, Pick & Pack (SubOperation for Picking could be the Wave Type)
------------------------------------------------------------------------------*/
Create Table KPIs (
    KPIId                    TRecordId      identity (1,1) not null,
    KPIClass                 TCategory,

    Operation                TDescription,
    SubOperation1            TDescription,
    SubOperation2            TDescription,
    SubOperation3            TDescription,
    JobCode                  TJobCode,

    ActivityDate             TDate,
    Account                  TAccount,
    AccountName              TName,

    NumWaves                 TCount,
    NumOrders                TCount,
    NumReceipts              TCount,
    NumLines                 TCount,
    NumLocations             TCount,
    NumPallets               TCount,
    NumLPNs                  TCount,
    NumInnerPacks            TCount,
    NumUnits                 TCount,
    NumTasks                 TCount,
    NumPicks                 TCount,
    NumSKUs                  TCount,

    Count1                   TCount,
    Count2                   TCount,
    Count3                   TCount,
    Count4                   TCount,
    Count5                   TCount,

    Weight                   TFloat,
    Volume                   TFloat,

    -- WaveType                 TTypeCode,
    -- WaveTypeDesc             TDescription,
    -- OrderType                TTypeCode,
    -- OrderCategory1           TCategory,
    -- OrderCategory2           TCategory,
    -- OrderCategory3           TCategory,
    -- OrderCategory4           TCategory,
    -- OrderCategory5           TCategory,

    Comment                  TVarChar,
    KPIStatus                TStatus        default 'A' /* Active */, -- Future use
    Archived                 TFlag          default 'N',

    Warehouse                TWarehouse,
    Ownership                TOwnership,
    SortOrder                TSortOrder,

    KPI_UDF1                 TUDF,
    KPI_UDF2                 TUDF,
    KPI_UDF3                 TUDF,
    KPI_UDF4                 TUDF,
    KPI_UDF5                 TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkKPI PRIMARY KEY (KPIId)
);

create index ix_KPI_Warehouse          on KPIs (Warehouse, BusinessUnit, KPIStatus, ActivityDate) Include (Operation, SubOperation1, SubOperation2);
create index ix_KPI_Operation          on KPIs (Operation, Warehouse, BusinessUnit, KPIStatus, ActivityDate) Include (SubOperation1, SubOperation2);
create index ix_KPI_ActivityDate       on KPIs (ActivityDate, BusinessUnit, KPIStatus, Operation, Warehouse) Include (SubOperation1, SubOperation2);

Go
