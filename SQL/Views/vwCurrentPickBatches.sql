/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/10/26  SPP     Show ShipVia description from ShipVias table (CIMS-1646)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2013/11/13  AY      Added Pallets, InnerPacks and Dates
  2012/08/10  AA      Added columns TotalAmount, Ownership, Warehouse, UDF1, UDF2
  2011/08/29  PK      Modifed SoldTo to SoldToId.
  2011/07/26  YA      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwCurrentPickBatches') is not null
  drop View dbo.vwCurrentPickBatches;
Go

Create View dbo.vwCurrentPickBatches (
  RecordId,

  BatchNo,
  BatchType,
  BatchTypeDesc,
  Status,
  StatusDesc,
  StatusSortSeq,
  Priority,

  NumOrders,
  NumLines,
  NumSKUs,
  NumPallets,
  NumInnerPacks,
  NumUnits,
  TotalAmount,

  SoldToId,            /* Customer */
  SoldToName,
  ShipToId,
  ShipToName,

  ShipVia,
  ShipViaDesc,
  PickZone,
  PickZoneDesc,

  PalletId,
  Pallet,

  Ownership,           /* Future Use */
  OwnershipDesc,
  Warehouse,

  CancelDate,
  PickDate,
  ShipDate,

  Category1,
  Category2,
  Category3,
  Category4,
  Category5,

  UDF1,                /* Customer PO */
  UDF2,                /* Cancel Date */
  UDF3,
  UDF4,
  UDF5,
  UDF6,
  UDF7,
  UDF8,
  UDF9,
  UDF10,

  WaveId,              /* For future use */
  RuleId,              /* For future use */

  vwCPB_UDF1,
  vwCPB_UDF2,
  vwCPB_UDF3,
  vwCPB_UDF4,
  vwCPB_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) AS
select
  PB.RecordId,

  PB.BatchNo,
  PB.BatchType,
  ET.TypeDescription,
  PB.Status,
  S.StatusDescription,
  right('00' + cast(S.SortSeq as varchar), 2) + '-' + S.StatusDescription,
  PB.Priority,

  PB.NumOrders,
  PB.NumLines,
  PB.NumSKUs,
  PB.NumPallets,
  PB.NumInnerPacks,
  PB.NumUnits,
  PB.TotalAmount,

  PB.SoldToId,
  C.CustomerName,
  PB.ShipToId,
  SHT.ShipToAddressId,
  PB.ShipVia,
  coalesce(SV.Description, PB.ShipVia),
  PB.PickZone,
  PZ.LookUpDescription,

  PB.PalletId,
  PB.Pallet,

  PB.Ownership,   /* Future Use */
  OS.LookUpDescription,
  PB.Warehouse,

  PB.CancelDate,
  PB.PickDate,
  PB.ShipDate,

  PB.Category1,
  PB.Category2,
  PB.Category3,
  PB.Category4,
  PB.Category5,

  PB.UDF1,
  PB.UDF2,
  PB.UDF3,
  PB.UDF4,
  PB.UDF5,
  PB.UDF6,
  PB.UDF7,
  PB.UDF8,
  PB.UDF9,
  PB.UDF10,

  PB.WaveId,
  PB.RuleId,

  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),

  PB.Archived,
  PB.BusinessUnit,
  PB.CreatedDate,
  PB.ModifiedDate,
  PB.CreatedBy,
  PB.ModifiedBy
From
  PickBatches PB
  left outer join Statuses     S   on (PB.Status          = S.StatusCode   ) and
                                      (S.Entity           = 'PickBatch'    ) and
                                      (S.BusinessUnit     = PB.BusinessUnit)
  left outer join EntityTypes  ET  on (PB.BatchType       = ET.TypeCode    ) and
                                      (ET.Entity          = 'PickBatch'    ) and
                                      (ET.BusinessUnit    = PB.BusinessUnit)
  left outer join Customers    C   on (PB.SoldToId        = C.CustomerId   )
  left outer join ShipTos      SHT on (PB.ShipToId        = SHT.ShipToId   )
  left outer join ShipVias     SV  on (PB.ShipVia         = SV.ShipVia     ) and
                                      (PB.BusinessUnit    = SV.BusinessUnit)
  left outer join LookUps      PZ  on (PB.PickZone        = PZ.LookUpCode  ) and
                                      (PZ.LookUpCategory  = 'PickZones'    ) and
                                      (PZ.BusinessUnit    = PB.BusinessUnit)
  left outer join LookUps      OS  on (PB.Ownership       = OS.LookUpCode  ) and
                                      (OS.LookUpCategory  = 'Owner'        ) and
                                      (OS.BusinessUnit    = PB.BusinessUnit)
where (Archived = 'N');

Go
