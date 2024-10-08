/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/02/15  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShippedOrderedVariance') is not null
  drop View dbo.vwShippedOrderedVariance;
Go

Create View dbo.vwShippedOrderedVariance (
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  Status,
  StatusDescription,

  OrderDate,
  DesiredShipDate,

  OrderDay,
  ShippedDay,

  Year,
  Quarter,
  Month,
  Week,
  Day,

  TADays,
  TADaysDescription,
  TABusinessDays,
  TABusinessDaysDescription,

  DaysInfo,

  Priority,
  SoldToId,
  ShipToId,
  ReturnAddress,
  PickBatchNo,
  ShipVia,
  ShipFrom,
  CustPO,
  Ownership,
  ShortPick,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,
  UDF6,
  UDF7,
  UDF8,
  UDF9,
  UDF10,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  ET.TypeDescription,
  OH.Status,
  S.StatusDescription,

  cast(convert(varchar, OH.OrderDate,   101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),

  datename(dw, OrderDate),                 /* OrderDay */
  datename(dw, ModifiedDate),              /* ShippedDay */

  datepart(year, ModifiedDate),  /* Year */

  Case  /* Quarter */
    when datepart(Quarter, ModifiedDate) = 1 then
      convert(varchar, datepart(year, ModifiedDate)) + ' - ' +'Quarter 1'
    when datepart(Quarter, ModifiedDate) = 2 then
      convert(varchar, datepart(year, ModifiedDate)) + ' - ' +'Quarter 2'
    when datepart(Quarter, ModifiedDate) = 3 then
      convert(varchar, datepart(year, ModifiedDate)) + ' - ' +'Quarter 3'
    when datepart(Quarter, ModifiedDate) = 4 then
      convert(varchar, datepart(year, ModifiedDate)) + ' - ' +'Quarter 4'
  end,
  /* Month */
  convert(varchar, datepart(year, ModifiedDate)) + ' - ' + convert(varchar, datepart(month, ModifiedDate)) + '(' + convert(varchar, datename(month, ModifiedDate)) + ')',

  /* Week */
  convert(varchar, datepart(year, ModifiedDate)) + ' - ' + convert(varchar, datepart(month, ModifiedDate)) + '(' + convert(varchar, datename(month, ModifiedDate)) + ')' + ' Week ' + convert(varchar, datediff(Week, dateadd(month, datediff(month, 0, ModifiedDate), 0), ModifiedDate) +1),

  /* Day */
  datename(dw, ModifiedDate),

  datediff(dd, OrderDate, ModifiedDate),  /* TADays */

  Case                                    /* TADaysDescription */
    when datediff(dd, OrderDate, ModifiedDate)  = 0 then
      '0 Day or Same Day'
    when datediff(dd, OrderDate, ModifiedDate)  = 1 then
      '1st Day or Next Day'
    when datediff(dd, OrderDate, ModifiedDate)  = 2 then
      '2nd Day'
    when datediff(dd, OrderDate, ModifiedDate)  = 3 then
      '3rd Day'
    else
      '4+ Days'
  end,
  /* TABusinessDays */
  datediff(dd, OrderDate, ModifiedDate) - (datediff(wk, OrderDate, ModifiedDate) * 2) -
  case
    when datepart(dw, OrderDate) = 1 then
      1
    else 0
  end +
  case
    when datepart(dw, ModifiedDate) = 1 then
      1
    else 0
  end,

 /* Case  /* TABusinessDays */
    when ((datepart(dw, OrderDate) = 2) and (datepart(dw, ModifiedDate) = 2)) then
      0
    when ((datepart(dw, OrderDate) = 2) and (datepart(dw, ModifiedDate) = 3)) then
      1
    when ((datepart(dw, OrderDate) = 6) and (datepart(dw, ModifiedDate) = 6)) then
      0
    when ((datepart(dw, OrderDate) = 6) and (datepart(dw, ModifiedDate) = 2)) then
      1
    when ((datepart(dw, OrderDate) = 7) and (datepart(dw, ModifiedDate) = 2)) then
      0
    when ((datepart(dw, OrderDate) = 7) and (datepart(dw, ModifiedDate) = 3)) then
      2
  end,          */

  Case  /* TABusinessDaysDescription */
    when datediff(dd, OrderDate, ModifiedDate) - (datediff(wk, OrderDate, ModifiedDate) * 2) -
      case
        when datepart(dw, OrderDate) = 1 then
          1
        else 0
      end +
      case
        when datepart(dw, ModifiedDate) = 1 then
          1
        else 0
      end  = 0 then
    '0 Day or Same Day'
    when datediff(dd, OrderDate, ModifiedDate) - (datediff(wk, OrderDate, ModifiedDate) * 2) -
      case
        when datepart(dw, OrderDate) = 1 then
          1
        else 0
      end +
      case
        when datepart(dw, ModifiedDate) = 1 then
          1
        else 0
      end  = 1 then
    '1st Day or Next Day'
    when datediff(dd, OrderDate, ModifiedDate) - (datediff(wk, OrderDate, ModifiedDate) * 2) -
      case
        when datepart(dw, OrderDate) = 1 then
          1
        else 0
      end +
      case
        when datepart(dw, ModifiedDate) = 1 then
          1
        else 0
      end  = 2 then
    '2nd Day'
    when datediff(dd, OrderDate, ModifiedDate) - (datediff(wk, OrderDate, ModifiedDate) * 2) -
      case
        when datepart(dw, OrderDate) = 1 then
          1
        else 0
      end +
      case
        when datepart(dw, ModifiedDate) = 1 then
          1
        else 0
      end  = 3 then
    '3rd Day'
    else
      '4+ Days'
  end,

  Case                                   /* DaysInfo */
    when datediff(dd, OrderDate, ModifiedDate)  = 0 then
      '0 Day or Same Day'
    when datediff(dd, OrderDate, ModifiedDate)  = 1 then
      '1st Day or Next Day'
    when datediff(dd, OrderDate, ModifiedDate)  = 2 then
      '2nd Day'
    when datediff(dd, OrderDate, ModifiedDate)  = 3 then
      '3rd Day'
    else
      '4+ Days'
  end,

  OH.Priority,
  OH.SoldToId,
  OH.ShipToId,
  OH.ReturnAddress,
  OH.PickBatchNo,
  OH.ShipVia,
  OH.ShipFrom,
  OH.CustPO,
  OH.Ownership,
  OH.ShortPick,

  OH.UDF1,
  OH.UDF2,
  OH.UDF3,
  OH.UDF4,
  OH.UDF5,
  OH.UDF6,
  OH.UDF7,
  OH.UDF8,
  OH.UDF9,
  OH.UDF10,

  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy
from
  OrderHeaders OH
  left outer join EntityTypes  ET  on (ET.TypeCode     = OH.OrderType   ) and
                                      (ET.Entity       = 'Order'        ) and
                                      (ET.BusinessUnit = OH.BusinessUnit)
  left outer join Statuses     S   on (S.StatusCode   = OH.Status       ) and
                                      (S.Entity       = 'Order'         ) and
                                      (S.BusinessUnit = OH.BusinessUnit )
where OH.Status = 'S' /* Shipped */

Go
