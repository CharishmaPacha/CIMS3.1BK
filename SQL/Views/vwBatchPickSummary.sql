/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/09/27  AY      LPN counts based upon OD.UnitsPerCarton only.
  2012/09/24  PKS     Bugs fixed.
  2012/09/24  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBatchPickSummary') is not null
  drop View dbo.vwBatchPickSummary;
Go

Create View dbo.vwBatchPickSummary (
  PickBatchId,
  PickBatchNo,

  PickBatchGroup,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UoM,
  SKUDescription,

  UnitsOrdered,
  UnitsAuthorizedToShip,
  UnitsAssigned,

  LPNsAuthorizedToShip,
  LPNsAssigned,

  StdPackQty
) As
select
  PB.RecordId,
  OH.PickBatchNo,

  OH.PickBatchGroup,

  OD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UoM,
  S.Description,

  sum(OD.UnitsOrdered),
  sum(OD.UnitsAuthorizedToShip),
  sum(OD.UnitsAssigned),

  sum(case when S.UoM =  'PP' then OD.UnitsAuthorizedToShip
           when S.UoM <> 'PP' and OD.UnitsPerCarton > 0 then OD.UnitsAuthorizedToShip / OD.UnitsPerCarton /* StdPackQty */
           else 0 end),
  sum(case when S.UoM =  'PP' then OD.UnitsAssigned
           when S.UoM <> 'PP' and OD.UnitsPerCarton > 0 then OD.UnitsAssigned / OD.UnitsPerCarton /* StdPackQty */
           else 0 end),
  Min(OD.UnitsPerCarton)
from
  OrderHeaders OH
             join PickBatches      PB  on (OH.PickbatchNo = PB.BatchNo)
             join OrderDetails     OD  on (OH.OrderId     = OD.OrderId)
  left outer join SKUs             S   on (OD.SKUId       = S.SKUId   )
group by
  PB.RecordId,
  OH.PickBatchNo,

  OH.PickBatchGroup,

  OD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UoM,
  S.Description;

Go
