/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/30  SK      Additional fields (HA-2937)
  2016/10/10  AY      Several changes for Packing productivity statistics.
  2015/07/29  OK      Migrated from OB prod-onsite(FB-263).
  2014/10/17  VM      Consider 1st day of month should start with Week #1 of the month.
  2013/09/17  PKS     Added fields Day, Week, WeekDisplay, Month, MonthDisplay, Year.
  2013/07/18  TD      Initial Revision
------------------------------------------------------------------------------*/
Go

/*  Please make sure any changes done here are reflected into pr_Prod_DS_GetUserProductivity
    as that is the data set which would be used for Productivity

    Also make sure to update TUserProductivity as well */

if object_id('dbo.vwProductivity') is not null
  drop View dbo.vwProductivity;
Go

Create View dbo.vwProductivity (
  ProductivityId,

  Operation,
  SubOperation,
  JobCode,
  Assignment,

  ActivityDate,

  NumWaves,
  NumOrders,
  NumLocations,
  NumPallets,
  NumLPNs,
  NumTasks,
  NumPicks,
  NumSKUs,
  NumUnits,
  NumAssignments,

  Weight,
  Volume,

  EntityType,
  EntityId,
  EntityKey,

  SKUId,
  SKU,
  LPNId,
  LPN,
  LocationId,
  Location,
  PalletId,
  Pallet,
  ReceiptId,
  ReceiptNumber,
  ReceiverId,
  ReceiverNumber,
  OrderId,
  PickTicket,
  WaveNo,
  WaveId,
  WaveType,
  WaveTypeDesc,
  TaskId,
  TaskDetailId,

  DayNumber,
  Day,
  DayMonth,
  WeekNumber,
  Week,
  MonthWeek,
  MonthNumber,
  MonthShort,
  Month,
  Year,

  StartDateTime,
  EndDateTime,

  Duration,
  DurationInSecs,
  DurationInMins,
  DurationInHrs,

  UnitsPerMin,
  UnitsPerHr,

  Comment,
  Status,
  Archived,

  DeviceId,
  UserId,
  UserName,
  ParentRecordId,

  Warehouse,
  Ownership,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  P.ProductivityId,

  coalesce(L.LookUpDescription, Operation),
  /* Sub Operation */
  case
    when P.Operation = 'Packing' and coalesce(P.Wavetype, '') = 'SLB' /* Single line bulk */ then 'SingleLine'
    when P.Operation = 'Packing' and coalesce(P.Wavetype, '') = 'PTC' /* Pick to cart */ then 'ScanPack'
    else P.SubOperation
  end,
  P.JobCode,
  P.Assignment,

  P.ActivityDate,

  P.NumWaves,
  P.NumOrders,
  P.NumLocations,
  P.NumPallets,
  P.NumLPNs,
  P.NumTasks,
  P.NumPicks,
  P.NumSKUs,
  P.NumUnits,
  1, /* NumAssignments is 1 per productivity id */

  P.Weight,
  P.Volume,

  P.EntityType,
  P.EntityId,
  P.EntityKey,

  P.SKUId,
  P.SKU,
  P.LPNId,
  P.LPN,
  P.LocationId,
  P.Location,
  P.PalletId,
  P.Pallet,
  P.ReceiptId,
  P.ReceiptNumber,
  P.ReceiverId,
  P.ReceiverNumber,
  P.OrderId,
  P.PickTicket,
  P.WaveNo,
  P.WaveId,
  P.WaveType,
  P.WaveTypeDesc,
  P.TaskId,
  P.TaskDetailId,

  datepart(dd,P.ActivityDate), /* DayNumber */
  convert(varchar(1),datepart(weekday,P.ActivityDate)) + substring (convert(varchar(20), datename(WeekDay, P.ActivityDate)), 1, 3), /* Day */
  /* Zero added as Prefix to avoid sorting related problems when month contains only one digit. */
  case when (len(day(P.ActivityDate))> 1) then
    convert(varchar(2),day(P.ActivityDate)) + '-' + substring (convert(varchar(20),DATENAME (month,P.ActivityDate)),1,3)
  else
    '0' + convert(varchar(2),day(P.ActivityDate)) + '-' + substring (convert(varchar(20),DATENAME (month,P.ActivityDate)),1,3)
  end, /* DayMonth */
  DATENAME (week, P.ActivityDate), /* WeekNumber */
  'WK-' + convert(varchar(1),datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, P.StartDateTime), 0)), 0), P.StartDateTime - 1) + 1), /* Week */
  substring (convert(varchar(20),DATENAME (month,P.ActivityDate)),1,3) + ' WK-' + convert(varchar(1),datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, P.StartDateTime), 0)), 0), P.StartDateTime - 1) + 1), /* MonthWeek */
  month(P.ActivityDate), /* MonthNumber */
  case when (len(datepart(month, P.ActivityDate)) > 1) then
    convert(varchar(2),datepart(month, P.ActivityDate)) + '-' + substring (convert(varchar(20),DATENAME (month,P.ActivityDate)),1,3)
  else
    '0' + convert(varchar(2),datepart(month, P.ActivityDate)) + '-' + substring (convert(varchar(20),DATENAME (month,P.ActivityDate)),1,3)
  end, /* MonthShort */
  case when (len(datepart(month, P.ActivityDate)) > 1) then
    convert(varchar(2),datepart(month, P.ActivityDate)) + '-' + DATENAME (month,P.ActivityDate)
  else
    '0' + convert(varchar(2),datepart(month, P.ActivityDate)) + '-' + DATENAME (month,P.ActivityDate)
  end, /* Month */
  year(P.ActivityDate), /* Year */

  P.StartDateTime,
  P.EndDateTime,
  --convert(varchar(5),datediff(s, P.StartDateTime, P.EndDateTime)/3600)+':'+convert(varchar(5),datediff(s, P.StartDateTime, P.EndDateTime)%3600/60)+':'+convert(varchar(5),(datediff(s, P.StartDateTime, P.EndDateTime)%60))
  cast(P.EndDateTime - P.StartDateTime as time(0)) /* Duration time */,
  P.DurationInSecs,
  P.DurationInSecs/convert(float, 60) /* DurationInMins */,
  P.DurationInSecs/convert(float, 3600) /* DurationInHrs */,

  case
    when coalesce(P.DurationInSecs, 0) > 0 then coalesce(P.NumUnits, 0)/(convert(float,P.DurationInSecs)/60)
    else 0
  end, /* UnitsPerMin */
  case
    when coalesce(P.DurationInSecs, 0) > 0 then coalesce(P.NumUnits, 0)/(convert(float,P.DurationInSecs)/3600)
    else 0
  end, /* UnitsPerHour */

  P.Comment,
  P.Status,
  P.Archived,

  P.DeviceId,
  P.UserId,
  P.UserName,
  P.ParentRecordId,

  P.Warehouse,
  P.Ownership,
  P.BusinessUnit,
  P.CreatedDate,
  P.ModifiedDate,
  P.CreatedBy,
  P.ModifiedBy
from
  Productivity P
  left outer join LookUps L on (L.LookUpCode = P.Operation) and (L.LookUpCategory = 'Productivity')
where (P.Status = 'A' /* Active */);

Go
