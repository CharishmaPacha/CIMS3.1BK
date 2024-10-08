/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/07/29  AY      Size Scale does not depend upon the Order, so eliminated it.
  2012/09/26  AY      Size scale varies by style only, so removed all other fields.
  2012/09/11  AY      Added SKU2, revised to use SKU fields instead of OD UDF's
  2012/08/14  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPackingListSizeScale') is not null
  drop View dbo.vwPackingListSizeScale;
Go

Create View dbo.vwPackingListSizeScale (
  /* SKU fields */
  SKU1,
  SKU2,
  /* Order */
  --OrderId,
  /* Sizes */
  Size1,
  Size2,
  Size3,
  Size4,
  Size5,
  Size6,
  Size7,
  Size8,
  Size9,
  Size10,
  Size11,
  Size12,

  FullScale

) as
select
  Season,
  Style,
  --OrderId,

  "1"  as Size1,
  "2"  as Size2,
  "3"  as Size3,
  "4"  as Size4,
  "5"  as Size5,
  "6"  as Size6,
  "7"  as Size7,
  "8"  as Size8,
  "9"  as Size9,
  "10" as Size10,
  "11" as Size11,
  "12" as Size12,

  coalesce("1", '0') + '-' + coalesce("2",  '0') + '-' + coalesce("3",  '0') + '-' + coalesce("4",  '0') + '-' +
  coalesce("5", '0') + '-' + coalesce("6",  '0') + '-' + coalesce("7",  '0') + '-' + coalesce("8",  '0') + '-' +
  coalesce("9", '0') + '-' + coalesce("10", '0') + '-' + coalesce("11", '0') + '-' + coalesce("12", '0')

from (select S.SKU1 as Season,
             S.SKU2 as Style,
             --OD.OrderId,
             S.SKUSortOrder, /* This is the size bucket */
             S.SKU5  /* This is the size */
      from SKUs S) up -- OrderDetails OD inner join SKUs S on OD.SKUId = S.SKUId) up
  PIVOT (Min(SKU5) for SKUSortOrder in ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12")) as pvt

Go
