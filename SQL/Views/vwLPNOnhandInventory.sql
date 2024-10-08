/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/01  TK      Added InventoryClass (HA-86)
  2018/11/06  AY      Added LocationSubType (HPI-2119)
  2018/03/28  YJ      Added AllowedOperations (S2G-327)
  2018/03/11  TK      Allocable Quantity should be the difference between AvailableQty & ReservedQty (S2G-152)
  2017/08/07  TK      Added ReplenishClass (HPI-1625)
  2017/01/13  TK      Check for Directed lines to allocate if available qty is zero (HPI_Support)
  2016/09/11  TK      Ignore orphan directed lines (HPI-562)
  2016/05/04  TK      Added NumLines (FB-648)
  2015/11/12  AY      Added Ownership
  2015/01/29  VM      Commented calculating Allocable Units as Packages as it is not applicable to SRI
  2014/05/18  AY      Reduce AllocableQty to be in multiples of UnitsPerPackage and
                        for it to be divisible by InnerPacks
              PK      Filtering with Directed OnhandStatus.
  2014/04/06  TD      Added new fields. ABCClass, ExpiryDate, StorageType.
  2013/11/20  TD      Added LPNDetailId-its temporary fix to show the valid data
                        which is available.
  2013/11/15  PK      Added Warehouse
              AY      Added PickPath, PutawayPath
  2013/10/04  AY      Added UnitsPerInnerPack
  2011/07/06  PK      Added SKU1 - SKU5 fields.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/24  VM      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLPNOnhandInventory') is not null
  drop View dbo.vwLPNOnhandInventory;
Go

Create View dbo.vwLPNOnhandInventory (
  LPNId,
  LPN,

  LPNDetailId,
  LPNLine,
  LPNType,
  NumLines,
  PickingClass,
  Ownership,

  CoO,
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  UOM,
  UnitsPerInnerPack,
  ABCClass,
  ReplenishClass,

  OnhandStatus,
  OnhandStatusDescription,
  AllocableInnerPacks,
  AllocableQuantity,
  UnitsPerPackage,
  TotalQuantity,

  ReceivedUnits,
  ShipmentId,
  LoadId,
  ASNCase,
  ExpiryDate,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  LocationId,
  Location,
  LocationType,
  LocationSubType,
  StorageType,
  PickingZone,
  PickPath,
  PutawayPath,
  AllowedOperations,

  Weight,
  Volume,
  Lot,

  /* UDFs that should match with Allocation Rules */
  LOI_UDF1,
  LOI_UDF2,
  LOI_UDF3,
  LOI_UDF4,
  LOI_UDF5,

  Warehouse,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  LD.LPNId,
  L.LPN,

  LD.LPNDetailId,
  LD.LPNLine,
  L.LPNType,
  L.NumLines,
  L.PickingClass,
  L.Ownership,

  LD.CoO,
  LD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.UoM,
  coalesce(nullif(S.UnitsPerInnerPack, 0), 1), /* prevent div by zero error */
  S.ABCClass,
  S.ReplenishClass,

  LD.OnhandStatus,
  OST.StatusDescription,
  /* Allocable InnerPacks */
  LD.InnerPacks,
  /* Allocable Qty: If the LPN is packaged, then ensure we allocate in multiples of packages only */
  LD.AllocableQty,
  LD.UnitsPerPackage,
  L.Quantity,

  LD.ReceivedUnits,
  L.ShipmentId,
  L.LoadId,
  L.ASNCase,
  L.ExpiryDate,
  L.InventoryClass1,
  L.InventoryClass2,
  L.InventoryClass3,

  L.LocationId,
  LOC.Location,
  LOC.LocationType,
  LOC.LocationSubType,
  LOC.StorageType,
  LOC.PickingZone,
  LOC.PickPath,
  LOC.PutawayPath,
  LOC.AllowedOperations,

  LD.Weight,
  LD.Volume,
  LD.Lot,

  /* These have to be empty string and not spaces as they are matched with Alloctionrules which could be nulls */
  cast(' ' as varchar(50)), /* LOI_UDF1: Future use */
  cast(' ' as varchar(50)), /* LOI_UDF2: Future use */
  cast(' ' as varchar(50)), /* LOI_UDF3: Future use */
  cast(' ' as varchar(50)), /* LOI_UDF4: Future use */
  cast(' ' as varchar(50)), /* LOI_UDF5: Future use */

  L.DestWarehouse,
  LD.BusinessUnit,
  LD.CreatedDate,
  LD.ModifiedDate,
  LD.CreatedBy,
  LD.ModifiedBy

from
LPNDetails LD
  left outer join LPNs             L   on (LD.LPNId           = L.LPNId            )
  left outer join Locations        LOC on (L.LocationId       = LOC.LocationId     )
  left outer join SKUs             S   on (LD.SKUId           = S.SKUId            )
  left outer join Statuses         OST on (LD.OnhandStatus    = OST.StatusCode     ) and
                                          (OST.Entity         = 'OnHand'           ) and
                                          (OST.BusinessUnit   = LD.BusinessUnit    )
where ((LD.OnhandStatus in ('A' /* Available */, 'D' /* Directed */)) and
       (LD.Quantity > 0) and
       (((LD.OnhandStatus = 'A') and (coalesce(LD.OrderDetailId, 0) = 0)) or
        ((LD.OnhandStatus = 'D') and (LD.ReplenishOrderId is not null))) and  -- Directed line without Replenish OrderId is invalid
       /* If available qty on Picklane LPN is zero then its OnHandStatus will be UnAvailable
          but there are Directed we need to check for that as well */
       ((L.OnhandStatus <> 'U') or (LD.OnhandStatus = 'D')) and -- looks like just an extra caution incase LD.Onhandstatus is not right
       (LOC.Location <> 'LOST'));

Go
