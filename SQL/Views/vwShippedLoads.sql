/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/02/14  PK      Modified to retrieve Quantity from Exports.
  2014/02/13  PK      Modified to retrive the data by joining Exports table.
  2014/02/03  PK      Modified to send previous days records as per client request.
  2014/01/27  NY      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwShippedLoads') is not null
  drop View dbo.vwShippedLoads;
Go

Create View vwShippedLoads (
  LoadId,
  LoadNumber,
  ShipToId,

  PickTicket,
  SalesOrder,
  SoldToId,

  UnitsShipped,

  Pallet,

  LPNId,
  LPN,
  Lot,

  LPNDetailId,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,

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
  CreatedBy,
  ModifiedDate,
  ModifiedBy
) As
select
  distinct
  L.LoadId,
  L.LoadNumber,
  L.ShipToId,

  OH.PickTicket,
  OH.SalesOrder,
  OH.SoldToId,

  E.TransQty,

  LPN.Pallet,

  LPN.LPNId,
  LPN.LPN,
  LPN.Lot,

  LPND.LPNDetailId,

  SKU.SKUId,
  SKU.SKU,
  coalesce(SKU.SKU1, ''),
  coalesce(SKU.SKU2, ''),
  coalesce(SKU.SKU3, ''),
  coalesce(SKU.SKU4, ''),
  coalesce(SKU.SKU5, ''),

  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),
  coalesce(cast(' ' as varchar(50)), ''),

  L.Archived,
  L.BusinessUnit,
  L.CreatedDate,
  L.CreatedBy,
  L.ModifiedDate,
  L.ModifiedBy
from Loads L
  left outer join Exports        E    on (E.LoadId      = L.LoadId  ) and (E.TransType = 'Ship'  ) and
                                         (E.TransEntity = 'PALD'    )
  left outer join Pallets        P    on (P.PalletId    = E.PalletId)
  left outer join SKUs           SKU  on (SKU.SKUId     = E.SKUId   )
  left outer join LPNs           LPN  on (LPN.PalletId  = P.PalletId) and (LPN.LoadId = P.LoadId )
  left outer join LPNDetails     LPND on (LPND.LPNId    = LPN.LPNId ) and (LPND.SKUId = SKU.SKUId)
  left outer join OrderHeaders   OH   on (OH.OrderId    = E.OrderId )
  left outer join OrderDetails   OD   on (OD.OrderId    = E.OrderId ) and (OD.SKUId   = SKU.SKUId)
where (L.Status = 'S' /* Shipped */) and
      ((cast(E.TransDateTime as Date)) =  cast(current_timestamp - 1 as date));

Go