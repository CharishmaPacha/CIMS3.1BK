/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/02/03  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOpenReceipts') is not null
  drop View dbo.vwOpenReceipts;
Go

Create View dbo.vwOpenReceipts (
  ReceiptId,
  ReceiptNumber,
  ReceiptType,
  ReceiptTypeDesc,

  Status,
  StatusDescription,

  VendorId,
  VendorName,
  Vessel,
  Warehouse,
  Ownership,

  ContainerNo,

  HostReceiptLine,

  CustPO,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UPC,

  CoO,

  UnitCost,

  QtyOrdered,
  QtyInTransit,
  QtyReceived,
  QtyToReceive,

  RH_UDF1,
  RH_UDF2,
  RH_UDF3,
  RH_UDF4,
  RH_UDF5,

  RD_UDF1,
  RD_UDF2,
  RD_UDF3,
  RD_UDF4,
  RD_UDF5,
  RD_UDF6,
  RD_UDF7,
  RD_UDF8,
  RD_UDF9,
  RD_UDF10,

  vwORE_UDF1,
  vwORE_UDF2,
  vwORE_UDF3,
  vwORE_UDF4,
  vwORE_UDF5,
  vwORE_UDF6,
  vwORE_UDF7,
  vwORE_UDF8,
  vwORE_UDF9,
  vwORE_UDF10,

  SourceSystem,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  RH.ReceiptId,
  RH.ReceiptNumber,
  RH.ReceiptType,
  ET.TypeDescription,

  RH.Status,
  ST.StatusDescription,

  RH.VendorId,
  coalesce(V.VendorName, RH.VendorId),
  RH.Vessel,
  RH.Warehouse,
  RH.Ownership,

  coalesce(RH.ContainerNo, ''),

  RD.HostReceiptLine,

  coalesce(RD.CustPO, ''),

  RD.SKUId,
  S.SKU,
  coalesce(S.SKU1, ''),
  coalesce(S.SKU2, ''),
  coalesce(S.SKU3, ''),
  coalesce(S.SKU4, ''),
  coalesce(S.SKU5, ''),
  coalesce(S.UPC, ''),

  coalesce(RD.CoO, ''),

  coalesce(RD.UnitCost, 0.0),

  coalesce(RD.QtyOrdered, 0),
  coalesce(RD.QtyInTransit, 0),
  coalesce(RD.QtyReceived, 0),
  coalesce((RD.QtyOrdered - RD.QtyReceived), 0),

  coalesce(RH.UDF1, ''),
  coalesce(RH.UDF2, ''),
  coalesce(RH.UDF3, ''),
  coalesce(RH.UDF4, ''),
  coalesce(RH.UDF5, ''),

  coalesce(RD.UDF1, ''),
  coalesce(RD.UDF2, ''),
  coalesce(RD.UDF3, ''),
  coalesce(RD.UDF4, ''),
  coalesce(RD.UDF5, ''),
  coalesce(RD.UDF6, ''),
  coalesce(RD.UDF7, ''),
  coalesce(RD.UDF8, ''),
  coalesce(RD.UDF9, ''),
  coalesce(RD.UDF10, ''),

  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF1 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF2 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF3 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF4 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF5 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF6 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF7 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF8 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF9 */
  coalesce(cast(' ' as varchar(50)), ''), /* vwORE_UDF10 */

  RH.SourceSystem,
  RH.Archived,
  RH.BusinessUnit,
  RH.CreatedDate,
  RH.ModifiedDate,
  RH.CreatedBy,
  RH.ModifiedBy
from
ReceiptHeaders RH
  left outer join ReceiptDetails  RD  on (RH.ReceiptId    = RD.ReceiptId   )
  left outer join SKUs            S   on (RD.SKUId        = S.SKUId        )
  left outer join Vendors         V   on (RH.VendorId     = V.VendorId     )
  left outer join EntityTypes     ET  on (RH.ReceiptType  = ET.TypeCode    ) and
                                         (ET.Entity       = 'Receipt'      ) and
                                         (ET.BusinessUnit = RH.BusinessUnit)
  left outer join Statuses        ST  on (RH.Status       = ST.StatusCode  ) and
                                         (ST.Entity       = 'Receipt'      ) and
                                         (ST.BusinessUnit = RH.BusinessUnit)
where (RH.Status not in ('E'/* Received */, 'C'/* Closed */, 'X' /* Cancelled */))

Go
