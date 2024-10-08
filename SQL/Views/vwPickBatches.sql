/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/22  PKK     Added MaxUnitsPerCarton and CartonizationModel (HA-2813)
  2020/10/05  RBV     Added PickMethod field (CID-1488)
  2020/05/29  TK      Added NumTasks (HA-691)
  2020/05/20  MS      Use Waves Table (HA-617)
  2020/05/01  RT      PickBatches: Included InvAllocationModel (HA-312)
  2019/07/11  AJ      Added NumLPNsToPA field (CID-735)
  2019/05/31  AY      Waves: Added WaveNo, WaveType, WaveTypeDesc, WaveStatus, WaveStatusDesc fields
  2019/04/09  VS      Added OrdersWaved field (CID-246)
  2018/09/18  MS      Changes to StatusGroup field return value (OB2-606)
  2018/08/30  MS      Added StatusGroup Field (OB2-606)
  2018/08/08  AY      Added several counts fields
  2018/08/03  AJ      Added condition to display Yellow color for new status waves (OB2-481)
  2018/05/05  AY      Mapped ShipToDescription to ShipToName (S2G-691)
  2018/03/09  AY      Added WCSStatus, WCSDependency, ColorCode fields
  2018/02/27  RT      Added field DependencyFlags (S2G-290)
  2017/01/17  RV      Un commented the required fields (HPI-1278)
  2017/01/14  TK      PickBatches: Mapped UDF4 with PB.UnitsAssigned (HPI-1267)
  2016/10/23  AY      Pickbatches: Added several Order/Unit count fields (HPI-GoLive)
  2016/09/10  TD      Sending Account value in UDF2. (HPI-603)
  2016/04/04  KL      Added TotalAmount, 5 Category's, AllocateFlags, IsAllocated, PickTicket, SoldToName,
                            ShipToStore, DropLocation (NBD-335)
  2015/12/08  RV      Added PBA_IsReplenished  PBA_IsReplenished,PBA_ReplenishBatchNo and 10 vwPB_UDFs (FB-561)
  2015/09/15  PK      Get ShipVia details from ShipVia table
  2014/02/18  NY      Calculating PercentComplete.
  2014/02/12  NY      Added NumPicks,NumPicksCompleted and PercentComplete.
  2013/11/13  NY      Added NumPallets and InnerPacks.
  2013/10/04  PK      Corrected the aliases in joins.
  2013/03/21  TD      Added new fields TotalWeight,CancelDate, TotalVolume.
  2012/10/14  AY      Added PickDate, ShipDate, Description
  2012/09/20  SP      Added "NumLPNs" field.
  2012/07/26  SP      Added the Warehouse, Ownership, PickBatchGroup fields.
  2012/06/12  PKS     Columns migrated from FH vwPickBatches.
  2011/11/30  VM      Removed temporary condition - where (Archived = 'N')
  2011/11/17  PKS     Archived column was added.
  2011/08/29  PK      Modifed SoldTo to SoldToId.
  2011/07/26  YA      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPickBatches') is not null
  drop View dbo.vwPickBatches;
Go

Create View dbo.vwPickBatches (
  RecordId,

  BatchNo,
  BatchType,
  BatchTypeDesc,
  Status,
  StatusDesc,

  WaveNo,
  WaveType,
  WaveTypeDesc,
  WaveStatus,
  WaveStatusDesc,

  StatusGroup,
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
  PercentComplete,
  TotalAmount,
  TotalWeight,
  TotalVolume,
  MaxUnitsPerCarton,

  CancelDate,
  PickDate,
  ShipDate,
  Description,

  Category1,
  Category2,
  Category3,
  Category4,
  Category5,

  AllocateFlags,
  IsAllocated,
  DependencyFlags,
  InvAllocationModel,
  CartonizationModel,
  PickMethod,
  WCSStatus,
  WCSDependency,

  /* Counts of orders in various statuses */
  OrdersWaved,
  OrdersAllocated,
  OrdersToAllocate,
  OrdersPicked,
  OrdersToPick,
  OrdersPacked,
  OrdersToPack,
  OrdersStaged,
  OrdersToStage,
  OrdersLoaded,
  OrdersToLoad,
  OrdersShipped,
  OrdersToShip,
  OrdersOpen,

  /* sum of Units in various statuses */
  UnitsAssigned,
  UnitsToAllocate,
  UnitsPicked,
  UnitsToPick,
  UnitsPacked,
  UnitsToPack,
  UnitsStaged,
  UnitsToStage,
  UnitsLoaded,
  UnitsToLoad,
  UnitsShipped,
  UnitsToShip,

  SoldToId,
  SoldToDesc,
  ShipToId,
  ShipToDescription,
  Account,
  AccountName,
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
  PickBatchGroup,
  PBA_IsReplenished,
  PBA_ReplenishBatchNo,
  ColorCode,

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

  vwPB_UDF1,
  vwPB_UDF2,
  vwPB_UDF3,
  vwPB_UDF4,
  vwPB_UDF5,
  vwPB_UDF6,
  vwPB_UDF7,
  vwPB_UDF8,
  vwPB_UDF9,
  vwPB_UDF10,

  WaveId,              /* For future use */
  RuleId,              /* For future use */
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) AS
select
  W.RecordId,

  W.BatchNo,
  W.BatchType,
  ET.TypeDescription,
  W.Status,
  S.StatusDescription,

  W.WaveNo,
  W.WaveType,
  ET.TypeDescription, /* WaveTypeDesc */
  W.WaveStatus,
  S.StatusDescription, /* WaveStatusDesc */

  case
    when (W.Status in ('N'/* New */,'B'/* Planned */))
      then 'To Process'
    when (W.Status in ('S'/* Shipped */,'D'/* Completed */,'X'/* Cancelled */))
      then 'Closed'
    else
      'In Process'
  end, /* Status group */
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
  case when coalesce(PB.NumPicks, 0) > 0  then
          cast (cast(coalesce(PB.NumPicksCompleted,(0)) as float)/ cast(coalesce(PB.NumPicks,(0)) as float) * 100 as decimal(5,2))
       else 0
  end,
  */
  W.TotalWeight,
  W.TotalVolume,
  W.MaxUnitsPerCarton,

  W.CancelDate,
  W.PickDate,
  W.ShipDate,
  W.Description,

  W.Category1,
  W.Category2,
  W.Category3,
  W.Category4,
  W.Category5,

  W.AllocateFlags,
  W.IsAllocated,
  W.DependencyFlags,
  W.InvAllocationModel,
  W.CartonizationModel,
  W.PickMethod,
  W.WCSStatus,
  W.WCSDependency,

  /* Counts of orders in various statuses */
  W.OrdersWaved,
  W.OrdersAllocated,
  W.NumOrders - W.OrdersAllocated, /* Orders To Allocate */
  W.OrdersPicked,
  W.NumOrders - W.OrdersPicked, /* Orders To Pick */
  W.OrdersPacked,
  W.NumOrders - W.OrdersPacked, /* Orders To Pack */
  W.OrdersStaged,
  W.NumOrders - W.OrdersStaged, /* Orders To Stage */
  W.OrdersLoaded,
  W.NumOrders - W.OrdersLoaded, /* Orders To Load */
  W.OrdersShipped,
  W.NumOrders - W.OrdersShipped, /* Orders To Ship */
  W.OrdersOpen,

  /* sum of Units in various statuses */
  W.UnitsAssigned,
  W.NumUnits - W.UnitsAssigned, /* Units To Allocate */
  W.UnitsPicked,
  W.NumUnits - W.UnitsPicked, /* Units To Pick */
  W.UnitsPacked,
  W.NumUnits - W.UnitsPacked, /* Units To Pack */
  W.UnitsStaged,
  W.NumUnits - W.UnitsStaged, /* Units To Stage */
  W.UnitsLoaded,
  W.NumUnits - W.UnitsLoaded, /* Units To Load */
  W.UnitsShipped,
  W.NumUnits - W.UnitsShipped, /* Units To Ship */

  W.SoldToId,
  C.CustomerName,
  W.ShipToId,
  SHT.Name,
  W.Account,
  W.AccountName,
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
  W.PickBatchGroup,
  PBA.IsReplenished,
  PBA.ReplenishBatchNo,
  case
    when W.Status = 'N'
      then 'G;LG' /* Green */
    when (W.NumUnits - W.UnitsAssigned) > 0 /* If wave partially allocated and needs to be reallocated */
      then 'B;LB' /* Fore color Red and backgroud is Green */
    else
      W.ColorCode
  end,
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

  cast(' ' as varchar(50)),/* vwPB_UDF1 */
  cast(' ' as varchar(50)),/* vwPB_UDF2 */
  cast(' ' as varchar(50)),/* vwPB_UDF3 */
  cast(' ' as varchar(50)),/* vwPB_UDF4 */
  cast(' ' as varchar(50)),/* vwPB_UDF5 */
  cast(' ' as varchar(50)),/* vwPB_UDF6 */
  cast(' ' as varchar(50)),/* vwPB_UDF7 */
  cast(' ' as varchar(50)),/* vwPB_UDF8 */
  cast(' ' as varchar(50)),/* vwPB_UDF9 */
  cast(' ' as varchar(50)),/* vwPB_UDF10 */

  W.WaveId,
  W.RuleId,

  W.Archived,
  W.BusinessUnit,
  W.CreatedDate,
  W.ModifiedDate,
  W.CreatedBy,
  W.ModifiedBy
From
  Waves W
  left outer join Statuses            S   on (W.Status          = S.StatusCode   ) and
                                             (S.Entity          = 'Wave'         ) and
                                             (W.BusinessUnit    = S.BusinessUnit )
  left outer join EntityTypes         ET  on (W.BatchType       = ET.TypeCode    ) and
                                             (ET.Entity         = 'Wave'         ) and
                                             (ET.BusinessUnit   = W.BusinessUnit )
  left outer join Customers           C   on (W.SoldToId        = C.CustomerId   )
  left outer join Contacts            SHT on (W.ShipToId        = SHT.ContactRefId) and
                                             (SHT.ContactType   = 'S'            )
  left outer join ShipVias            SV  on (W.ShipVia         = SV.ShipVia     ) and
                                             (W.BusinessUnit    = SV.BusinessUnit)
  left outer join LookUps             PZ  on (W.PickZone        = PZ.LookUpCode  ) and
                                             (PZ.LookUpCategory = 'PickZones'    ) and
                                             (PZ.BusinessUnit   = S.BusinessUnit )
  left outer join PickBatchAttributes PBA on (W.BatchNo         = PBA.PickBatchNo)
--where (Archived = 'N') /* Temporary */

Go
