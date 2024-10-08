/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/23  SK      Initial Revision (HA-3020)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwWarehouseKPI') is not null
  drop View dbo.vwWarehouseKPI;
Go

Create View dbo.vwWarehouseKPI (
  Operation,
  SubOperation1,
  SubOperation2,
  SubOperation3,
  JobCode,

  ActivityDate,
  Account,
  AccountName,

  NumWaves,
  NumOrders,
  NumLines,
  NumLocations,
  NumPallets,
  NumLPNs,
  NumInnerPacks,
  NumUnits,
  NumTasks,
  NumPicks,
  NumSKUs,

  Weight,
  Volume,

  Comment,
  KPIStatus,
  Archived,

  Warehouse,
  Ownership,
  SortOrder,

  KPI_UDF1,
  KPI_UDF2,
  KPI_UDF3,
  KPI_UDF4,
  KPI_UDF5,

  ActivityDate_DMY, -- Day Month Year
  ActivityDate_MY, -- Month Year
  ActivityDate_QY, -- Quarter Year
  ActivityDate_Y,  -- Year

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

  KPIId
) As
select
  Operation,
  SubOperation1,
  SubOperation2,
  SubOperation3,
  JobCode,

  ActivityDate,
  Account,
  AccountName,

  NumWaves,
  NumOrders,
  NumLines,
  NumLocations,
  NumPallets,
  NumLPNs,
  NumInnerPacks,
  NumUnits,
  NumTasks,
  NumPicks,
  NumSKUs,

  Weight,
  Volume,

  Comment,
  KPIStatus,
  Archived,

  Warehouse,
  Ownership,
  SortOrder,

  KPI_UDF1,
  KPI_UDF2,
  KPI_UDF3,
  KPI_UDF4,
  KPI_UDF5,

  convert(varchar, activitydate, 106), -- Day Month year
  right(convert(varchar, ActivityDate, 106), 8), -- Month Year
  'Q' + cast(datepart(q, activitydate) as varchar) +  ' ' + convert(varchar, year(ActivityDate)), -- Quarter Year
  year(ActivityDate), -- Year

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

  KPIId
from
  KPIs;

Go