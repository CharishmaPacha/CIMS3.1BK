/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/17  MS      InventoryKey mapping insync with Export def (BK-992)
  2022/06/09  VS      vwExportsOnhandInventory, vwExportsOnhandInventoryBySKU: Use InventoryKey (JLFL-98)
  2022/03/24  AY      vwExportsOnhandInventory, vwExportsOnhandInventoryBySKU: Correct the inventory key to use LD.ICs (HA-3455)
  2022/03/22  AY      Export LD.ICs if available over L.ICs (HA-3455)
  2021/12/28  MS      Added Pallet & Reference (HA-3328)
  2021/09/06  AY      Minor changes (HA-3146)
  2021/08/11  AY      Performance optimization
  2021/08/03  AY      Added AvailableToReserve (OB2-1985)
  2020/10/12  AY      Added InventoryKey (HA-1576)
  2020/04/06  YJ      Added InventoryClass fields (HA-87)
  2019/10/01  AJM     Added DW with Ownership (SRI-780) (ported from prod)
  2019/06/29  SPP     Added coalesce in lot (CID-136) (Ported from Staging)
  2018/05/02  TD      Changes to shoe proper lot number based on the SourceSystem (HPI-1890)
  2018/03/29  SV      Added SourceSystem (HPI-1845)
  2018/02/15  TK      Added LOC.PickingZone (HPI-1811)
  2017/08/11  VM/KL   Send OnhandStatus as A (Available) when it is R (Reserved) for replenishment Order
                        Send on hand inventory as ReservedQty when OnhandStatus R-Reserved and OrderId is null (HPI-1622)
  2017/03/13  PK      Modified where clause to consider LPN status 'O' lost (HPI-GoLive)
  2016/09/11  AY      Clean-up (HPI-GoLive)
  2016/05/16  AY      Bug fix: Incorrect join with OH on L.OrderId instead of LD.OrderId
  2016/05/05  AY      Corrected logic to determine reserved units as orders get removed from Wave
                        if LPN does not have PickTicketNo
  2016/04/04  AY      Changed to include Qty allocated for Replenishment as AvailableQty
  2015/10/26  OK      Added AvailableQty, ReservedQty, ReceivedQty (CIMS-653)
  2015/10/14  OK      Added AvailableIPs, ReservedIPs & ReceivedIPs (CIMS-653)
  2015/05/17  AY      Exclude staged LPNs
  2015/02/06  AY      Added where clause to exclude Inactive LPNs
  2014/10/24  PKS     Added Warehouse.
  2014/09/11  AK      Added vwEOHINV_UDF1 to vwEOHINV_UDF10.
  2013/12/17  AY      Added InnerPacks.
  2013/12/11  NY      Added UnitsPerInnerPack.
  2013/10/16  NY      Added SKUId.
  2013/05/16  NY      Added SKU related fields to use for Show Onhandinventory.
  2012/08/10  YA      Included 'Ownership' field as required.
  2011/09/28  YA      Added Location field as it is required in 'pr_Exports_OnHandInventory'
  2011/07/21  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwExportsOnhandInventory') is not null
  drop View dbo.vwExportsOnhandInventory;
Go

Create View dbo.vwExportsOnhandInventory (
  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  Description,
  SKU1Description,
  SKU2Description,
  SKU3Description,
  SKU4Description,
  SKU5Description,
  UPC,
  Brand,
  ProdCategory,
  ProdSubCategory,
  ABCClass,
  SKUSortOrder,
  UnitPrice,
  UoM,
  UnitsPerInnerPack,
  SourceSystem,

  LPNId,
  LPN,
  LPNDetailId,
  Location,
  LPNOnHandStatus,
  Status,
  Warehouse,
  Ownership,
  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,
  ExpiryDate,
  DestWarehouse,
  LPNType,
  LPNTypeDescription,
  Reference,

  Pallet,

  PickingZone,

  InnerPacks,
  AvailableIPs,
  ReservedIPs,
  ReceivedIPs,

  Quantity,
  AvailableQty,
  ReservedQty,
  ReceivedQty,
  AvailableToReserve,

  OnhandStatus,
  OHStatus,
  BusinessUnit,

  InventoryKey,

  vwEOHINV_UDF1,
  vwEOHINV_UDF2,
  vwEOHINV_UDF3,
  vwEOHINV_UDF4,
  vwEOHINV_UDF5,
  vwEOHINV_UDF6,
  vwEOHINV_UDF7,
  vwEOHINV_UDF8,
  vwEOHINV_UDF9,
  vwEOHINV_UDF10

) As
select
  S.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.Description,
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,
  S.UPC,
  S.Brand,
  S.ProdCategory,
  S.ProdSubCategory,
  S.ABCClass,
  S.SKUSortOrder,
  S.UnitPrice,
  S.UoM,
  S.UnitsPerInnerPack,
  S.SourceSystem,
  L.LPNId,
  L.LPN,
  LD.LPNDetailId,
  LOC.Location,
  L.OnhandStatus,
  L.Status,
  L.DestWarehouse,
  L.Ownership,
  coalesce(L.Lot, ''),
  coalesce(nullif(LD.InventoryClass1, ''), L.InventoryClass1),
  coalesce(nullif(LD.InventoryClass2, ''), L.InventoryClass2),
  coalesce(nullif(LD.InventoryClass3, ''), L.InventoryClass3),
  L.ExpiryDate,
  L.DestWarehouse,
  L.LPNType,
  ET.TypeDescription,
  L.Reference,

  L.Pallet,

  LOC.PickingZone,

  LD.InnerPacks,
  /* If Reserved for Replenish PT, then consider it as available. For performance sake, avoiding
     another join with OH to check Ordertype and instead taking the easy route of checking PT begins with R */
  case when LD.OnhandStatus = 'A' or
            LD.OnhandStatus = 'R' and OH.OrderType in ('RU', 'RP') then coalesce(LD.InnerPacks, 0) else 0 end AvailableIPs,
  case when LD.OnhandStatus = 'R' and ((OH.OrderType not in ('RU', 'RP')) or (OH.OrderId is null)) then coalesce(LD.InnerPacks, 0) else 0 end ReservedIPs,
  case when L.Status        = 'R' then coalesce(LD.InnerPacks, 0) else 0 end ReceivedIPs,

  LD.Quantity,
  case when LD.OnhandStatus = 'A' then coalesce(LD.Quantity, 0)
       when LD.OnhandStatus = 'R' and OH.OrderType in ('RU', 'RP') then coalesce(LD.Quantity, 0)
       else 0
  end AvailableQty,
  case when LD.OnhandStatus = 'R' and ((OH.OrderType not in ('RU', 'RP')) or (OH.OrderId is null)) then coalesce(LD.Quantity, 0)
       else 0
  end ReservedQty,
  case when LD.OnhandStatus = 'U' then coalesce(LD.Quantity, 0) else 0 end ReceivedQty,

  case when L.LPNType = 'L' /* Logical */ then L.Quantity - L.ReservedQty
       when LD.OnhandStatus = 'A' then coalesce(LD.Quantity, 0)
       when LD.OnhandStatus = 'R' and OH.OrderType in ('RU', 'RP') then coalesce(LD.Quantity, 0)
       else 0
  end AvailableToReserve,

  /* VM_20170811: When we treat quantity reserved against replenish order as AvailableQty (above), even send OnhandStatus as A (Available) as well */
  case when LD.OnhandStatus = 'A' then 'A'
       when LD.OnhandStatus = 'R' and OH.OrderType in ('RU', 'RP') then 'A'
       when LD.OnhandStatus = 'R' and ((OH.OrderType not in ('RU', 'RP')) or (OH.OrderId is null)) then 'R'
       else LD.OnhandStatus end OnhandStatus,

  case when LD.OnhandStatus = 'A' or
            LD.OnhandStatus = 'R' and OH.OrderType in ('RU', 'RP') then 'Available'
       when LD.OnhandStatus = 'R' and ((OH.OrderType not in ('RU', 'RP')) or (OH.OrderId is null)) then 'Reserved'
       when LD.OnhandStatus = 'U' then 'Received'  end OHStatus,
  L.BusinessUnit,

  /* Inventory Key */
  concat_ws('-', LD.SKUId, L.Ownership, L.DestWarehouse, coalesce(L.Lot, ''), L.InventoryClass1, L.InventoryClass2, L.InventoryClass3),

  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50)),
  cast(' ' as varchar(50))
from
LPNDetails LD
             join LPNs        L   with (index = ix_LPNs_Archived)
                                                on (LD.LPNId        = L.LPNId             )
  left outer join OrderHeaders OH with (nolock) on (LD.OrderId      = OH.OrderId          )
  left outer join Locations   LOC with (nolock) on (LOC.LocationId  = L.LocationId        )
  left outer join SKUs        S   with (nolock) on (LD.SKUId        = S.SKUId             )
  left outer join EntityTypes ET  with (nolock) on (L.LPNType       = ET.TypeCode         ) and
                                     (ET.Entity       = 'LPN'               ) and
                                     (ET.BusinessUnit = LD.BusinessUnit     )
where ((LD.OnhandStatus in ('A' /* Available */, 'R' /* Reserved */)) or
       (LD.Onhandstatus = 'U' /* Unavailable */ and L.Status = 'R' /* Received */)) and
      --(L.Status not in ('O', 'I' /* Lost, Inactive */)) and
      (L.Archived = 'N')
;

Go
