/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/08/06  DK      Added UDF1
  2012/09/26  AY      Added CustSKU
  2012/09/11  AY      Changed to use SKU components instead of OD UDFs
  2012/08/14  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPackingListMatrix') is not null
  drop View dbo.vwPackingListMatrix;
Go

Create View dbo.vwPackingListMatrix (
  /* SKU fields */
  SKU1,
  SKU2,
  SKU3,
  SKUDescription,
  /* Order */
  OrderId,
  HostOrderLine,
  RetailUnitPrice,
  UnitSalePrice,
  CustSKU,
  OD_UDF1,
  /* Counts */
  Units1,
  Units2,
  Units3,
  Units4,
  Units5,
  Units6,
  Units7,
  Units8,
  Units9,
  Units10,
  Units11,
  Units12,

  TotalUnits
) as
select
  Season,
  Style,
  Color,
  Description,

  OrderId,
  HostOrderLine,
  RetailUnitPrice,
  UnitSalePrice,
  CustSKU,
  UDF1,

  "1"  as Units1,
  "2"  as Units2,
  "3"  as Units3,
  "4"  as Units4,
  "5"  as Units5,
  "6"  as Units6,
  "7"  as Units7,
  "8"  as Units8,
  "9"  as Units9,
  "10" as Units10,
  "11" as Units11,
  "12" as Units12,

  coalesce("1", 0) + coalesce("2", 0) + coalesce("3", 0) + coalesce("4", 0) + coalesce("5", 0) + coalesce("6", 0) + coalesce("7", 0) + coalesce("8", 0) + coalesce("9", 0) + coalesce("10", 0) + coalesce("11", 0) + coalesce("12", 0)
from (select S.SKU1 as Season,
             S.SKU2 as Style,
             S.SKU3 as Color,
             S.Description,
             OD.OrderId,
             OD.HostOrderLine,
             OD.RetailUnitPrice,
             OD.UnitSalePrice,
             OD.CustSKU,
             OD.UDF1,
             coalesce(S.SKUSortOrder, nullif(S.SKU5, ''), nullif(OD.UDF5, ''), '1') as SizeBucket, /* This is the size bucket */
             OD.UnitsAuthorizedToship -- should be UnitsAssigned
      from OrderDetails OD join SKUs S on OD.SKUId = S.SKUId) up
  PIVOT (sum(UnitsAuthorizedToShip) for SizeBucket in ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12")) as pvt

Go