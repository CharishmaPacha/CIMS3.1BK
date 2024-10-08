/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/22  PKK     Added CartonizationModel and MaxUnitsPerCarton (HA-2813)
  2021/03/10  SK      Updated WaveStatus field (HA-2228)
  2021/02/20  SGK     Added NumLPNsToPA, ReleaseDateTime, PrintStatus, CustPO, PickSequence,
                      WaveRuleGroup, CreatedOn, ModifiedOn (CIMSV3-1364)
  2020/10/06  RBV     Added PickMethod field (CID-1488)
  2020/03/06  VS      Corrected field name to WaveGroup
  2020/05/29  TK      Added NumTasks (HA-691)
  2020/05/28  AY      LPN Counts added
  2019/05/15  TK/RT   Included InvAllocationModel, PickBatch -> WaveType (HA-312)
  2019/06/01  AY      Added PickBatchId, PickBatchNo to link to other lists
  2019/05/10  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwWaves') is not null
  drop View dbo.vwWaves;
Go

Create View dbo.vwWaves (
  RecordId,

  WaveId,
  WaveNo,
  /* For joining with other tables which aren't changed yet */
  PickBatchId,
  PickBatchNo,

  WaveType,
  WaveTypeDesc,
  WaveStatus,
  WaveStatusDesc,
  Priority,

  NumOrders,
  NumLines,
  NumPallets,
  NumSKUs,
  NumInnerPacks,
  NumLPNs,
  NumLPNsToPA,
  NumUnits,
  NumTasks,
  NumPicks,
  NumPicksCompleted,
  PercentPicksComplete,
  TotalAmount,
  TotalWeight,
  TotalVolume,
  MaxUnitsPerCarton,

  CancelDate,
  PickDate,
  ShipDate,
  ReleaseDateTime,
  Description,

  Category1,
  Category2,
  Category3,
  Category4,
  Category5,

  AllocateFlags,
  IsAllocated,
  DependencyFlags,
  PrintStatus,
  InvAllocationModel,
  CartonizationModel,
  PickMethod,

  WCSStatus,
  WCSDependency,

  /* Counts of orders in various statuses */
  OrdersWaved,
  OrdersAllocated,
  OrdersPicked,
  OrdersPacked,
  OrdersLoaded,
  OrdersStaged,
  OrdersShipped,
  OrdersOpen,

  /* sum of Units in various statuses */
  UnitsAssigned,
  UnitsPicked,
  UnitsPacked,
  UnitsStaged,
  UnitsLoaded,
  UnitsShipped,

  /* sum of LPNs in various statuses */
  LPNsAssigned,
  LPNsPicked,
  LPNsPacked,
  LPNsStaged,
  LPNsLoaded,
  LPNsShipped,

  SoldToId,
  SoldToDesc,
  ShipToId,
  ShipToDescription,
  Account,
  AccountName,
  CustPO,
  ShipVia,
  ShipViaDesc,
  PickZone,
  PickTicket,
  SoldToName,
  ShipToStore,
  PickZoneDesc,

  PalletId,
  Pallet,
  AssignedTo,
  Ownership,
  Warehouse,
  DropLocation,
  PickSequence,
  WaveGroup,
  WA_IsReplenished,
  WA_ReplenishWaveNo,
  ColorCode,

  RuleId,              /* For future use */
  WaveRuleGroup,

  W_UDF1,
  W_UDF2,
  W_UDF3,
  W_UDF4,
  W_UDF5,
  W_UDF6,
  W_UDF7,
  W_UDF8,
  W_UDF9,
  W_UDF10,

  vwW_UDF1,
  vwW_UDF2,
  vwW_UDF3,
  vwW_UDF4,
  vwW_UDF5,
  vwW_UDF6,
  vwW_UDF7,
  vwW_UDF8,
  vwW_UDF9,
  vwW_UDF10,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,

  CreatedOn,
  ModifiedOn
) AS
select
  W.RecordId,

  W.RecordId,
  W.BatchNo,

  W.RecordId, /* PickBatchId */
  W.BatchNo, /* PickBatchNo */

  W.BatchType,
  ET.TypeDescription,
  W.WaveStatus,
  S.StatusDescription,
  W.Priority,

  W.NumOrders,
  W.NumLines,
  W.NumPallets,
  W.NumSKUs,
  W.NumInnerPacks,
  W.NumLPNs,
  W.NumLPNsToPA,
  W.NumUnits,
  W.NumTasks,
  W.NumPicks,
  W.NumPicksCompleted,
  W.PercentComplete,
  W.TotalAmount,
  /*
  case when coalesce(W.NumPicks, 0) > 0  then
          cast (cast(coalesce(W.NumPicksCompleted,(0)) as float)/ cast(coalesce(W.NumPicks,(0)) as float) * 100 as decimal(5,2))
       else 0
  end,
  */
  W.TotalWeight,
  W.TotalVolume,
  W.MaxUnitsPerCarton,

  W.CancelDate,
  W.PickDate,
  W.ShipDate,
  W.ReleaseDateTime,
  W.Description,

  W.Category1,
  W.Category2,
  W.Category3,
  W.Category4,
  W.Category5,

  W.AllocateFlags,
  W.IsAllocated,
  W.DependencyFlags,
  W.PrintStatus,
  W.InvAllocationModel,
  W.CartonizationModel,
  W.PickMethod,

  W.WCSStatus,
  W.WCSDependency,

  /* Counts of orders in various statuses */
  W.OrdersWaved,
  W.OrdersAllocated,
  W.OrdersPicked,
  W.OrdersPacked,
  W.OrdersLoaded,
  W.OrdersStaged,
  W.OrdersShipped,
  W.OrdersOpen,

  /* sum of Units in various statuses */
  W.UnitsAssigned,
  W.UnitsPicked,
  W.UnitsPacked,
  W.UnitsStaged,
  W.UnitsLoaded,
  W.UnitsShipped,

  /* sum of LPNs in various statuses */
  W.LPNsAssigned,
  W.LPNsPicked,
  W.LPNsPacked,
  W.LPNsStaged,
  W.LPNsLoaded,
  W.LPNsShipped,

  W.SoldToId,
  C.CustomerName,
  W.ShipToId,
  SHT.Name,
  W.Account,
  W.AccountName,
  W.CustPO,
  W.ShipVia,
  SV.Description,
  W.PickZone,
  W.PickTicket,
  W.SoldToName,
  W.ShipToStore,
  PZ.LookUpDescription,

  W.PalletId,
  W.Pallet,
  W.AssignedTo,
  W.Ownership,
  W.Warehouse,
  W.DropLocation,
  W.PickSequence,
  W.PickBatchGroup,
  WA.IsReplenished,
  WA.ReplenishBatchNo,
  W.ColorCode,

  W.RuleId,
  W.WaveRuleGroup,

  W.UDF1,
  W.UDF2,
  W.UDF3,
  W.UDF4,
  W.UDF5,
  W.UDF6,
  W.UDF7,
  W.UDF8,
  W.UDF9,
  W.UDF10,

  cast(' ' as varchar(50)),/* vwW_UDF1 */
  cast(' ' as varchar(50)),/* vwW_UDF2 */
  cast(' ' as varchar(50)),/* vwW_UDF3 */
  cast(' ' as varchar(50)),/* vwW_UDF4 */
  cast(' ' as varchar(50)),/* vwW_UDF5 */
  cast(' ' as varchar(50)),/* vwW_UDF6 */
  cast(' ' as varchar(50)),/* vwW_UDF7 */
  cast(' ' as varchar(50)),/* vwW_UDF8 */
  cast(' ' as varchar(50)),/* vwW_UDF9 */
  cast(' ' as varchar(50)),/* vwW_UDF10 */

  W.Archived,
  W.BusinessUnit,
  W.CreatedDate,
  W.ModifiedDate,
  W.CreatedBy,
  W.ModifiedBy,

  W.CreatedOn,
  W.ModifiedOn
From
  Waves W
  left outer join Statuses            S   on (W.Status           = S.StatusCode   ) and
                                             (S.Entity           = 'Wave'         ) and
                                             (W.BusinessUnit     = S.BusinessUnit )
  left outer join EntityTypes         ET  on (W.BatchType        = ET.TypeCode    ) and
                                             (ET.Entity          = 'Wave'         ) and
                                             (ET.BusinessUnit    = W.BusinessUnit )
  left outer join Customers           C   on (W.SoldToId         = C.CustomerId   )
  left outer join Contacts            SHT on (W.ShipToId         = SHT.ContactRefId) and
                                             (SHT.ContactType    = 'S'            )
  left outer join ShipVias            SV  on (W.ShipVia          = SV.ShipVia     ) and
                                             (W.BusinessUnit     = SV.BusinessUnit)
  left outer join LookUps             PZ  on (W.PickZone         = PZ.LookUpCode  ) and
                                             (PZ.LookUpCategory  = 'PickZones'    ) and
                                             (PZ.BusinessUnit    = S.BusinessUnit )
  left outer join PickBatchAttributes WA  on (W.BatchNo          = WA.PickBatchNo )
--where (Archived = 'N') /* Temporary */

Go
