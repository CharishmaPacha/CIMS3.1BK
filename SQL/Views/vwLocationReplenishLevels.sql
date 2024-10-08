/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/17  SRS      Initial Revision (BK-764).
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLocationReplenishLevels') is not null
  drop View dbo.vwLocationReplenishLevels;
Go

Create View dbo.vwLocationReplenishLevels (
  RecordId,

  LocationId,
  Location,
  Warehouse,

  SKUId,
  SKU,
  InventoryKey,

  Status,

  MinReplenishLevel,
  MaxReplenishLevel,
  ReplenishUoM,
  IsReplenishable,

  SV_PrevWeek,
  SV_Prev2Week,
  SV_PrevMonth,
  SV_Prev2Month,
  SV_PrevQuarter,
  SV_Prev2Quarter,

  PV_PrevWeek,
  PV_Prev2Week,
  PV_PrevMonth,
  PV_Prev2Month,
  PV_PrevQuarter,
  PV_Prev2Quarter,

  LOCRL_UDF1,
  LOCRL_UDF2,
  LOCRL_UDF3,
  LOCRL_UDF4,
  LOCRL_UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
  ) as
select
  LRL.RecordId,

  LRL.LocationId,
  LRL.Location,
  LRL.Warehouse,

  LRL.SKUId,
  LRL.SKU,
  LRL.InventoryKey,

  LRL.Status,

  LRL.MinReplenishLevel,
  LRL.MaxReplenishLevel,
  LRL.ReplenishUoM,
  LRL.IsReplenishable,

  LRL.SV_PrevWeek,
  LRL.SV_Prev2Week,
  LRL.SV_PrevMonth,
  LRL.SV_Prev2Month,
  LRL.SV_PrevQuarter,
  LRL.SV_Prev2Quarter,

  LRL.PV_PrevWeek,
  LRL.PV_Prev2Week,
  LRL.PV_PrevMonth,
  LRL.PV_Prev2Month,
  LRL.PV_PrevQuarter,
  LRL.PV_Prev2Quarter,

  LRL.LOCRL_UDF1,
  LRL.LOCRL_UDF2,
  LRL.LOCRL_UDF3,
  LRL.LOCRL_UDF4,
  LRL.LOCRL_UDF5,

  LRL.BusinessUnit,
  LRL.CreatedDate,
  LRL.ModifiedDate,
  LRL.CreatedBy,
  LRL.ModifiedBy
from
  LocationReplenishLevels LRL
;

Go
