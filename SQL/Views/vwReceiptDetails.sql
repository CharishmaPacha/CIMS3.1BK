/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/04  VS      Added SKUImageURL (BK-1053)
  2021/07/08  SPP     Added New Field AppointmentDateTime (HA-2969)
  2020/11/05  MS      Added New Fields SortLanes, SortOptions, SortStatus (JL-294)
  2020/10/15  MS      Mapping corrected for LPNsInTransit (CIMSV3-1116)
  2020/03/30  MS      Added InventoryClasses (HA-83)
  2020/03/27  AY      Added RHStatus & SKUDescription fields
  2020/03/17  AY      Clean up, Re-Organized fields
  2019/09/26  TK      Added InventoryUoM (S2GCA-969)
  2018/11/27  SV      In case of over receiving, we shouldn't show -ve values over MaxQtyAllowedToReceive (OB2-708)
  2018/03/01  SV      Added InnerPacksPerLPN, UnitsPerLPN (S2G-316)
  2018/01/09  TK      Added SKU.CaseUPC (S2G-41)
  2016/09/26  SV      Resolved the -ve update over QtyToLabel during over receiving (HPI-732)
  2015/05/19  SV      Added QtyToLabel, UoM and UoM Description
  2014/12/03  SV      Added SKU1Description to SKU5Description.
  2014/11/01  NY      Removed computation as we are doing it on table.
  2014/04/05  PV      Eliminate negative values for QtyToReceive.
  2013/08/28  TD      Added UPC.
  2013/08/22  PK      Added UnitsPerInnerPack.
  2013/04/16  TD      Added PackingSlipNumber.
  2013/03/31  AY      Added MaxQtyAllowedToReceive
  2013/03/23  PK      Added UDF6 - UDF10.
  2013/03/07  NY      Added ExtraQtyAllowed,CustPO.
  2011/06/27  AY      Added QtyInTransit and LPNsInTransit
  2011/07/09  PK      Added HostReceiptLine.
  2011/07/06  PK      Added SKU1- SKU5 fields.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/26  VK      Added SKU_UDF1,SKU_UDF2,SKU_UDF3,SKU_UDF4 and SKU_UDF1.
  2011/01/14  PK      Added ReceiptTypeDesc, VendorName, BUDescription.
  2010/12/30  PK      Added ReceiptType, VendorId, Ownership, DateOrdered, DateExpected.
  2010/12/01  PK      Added QtyToReceive.
  2010/10/26  VM      CoE => CoO
  2010/10/21  VM      vwReceiptDetail => vwReceiptDetails
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwReceiptDetails') is not null
  drop View dbo.vwReceiptDetails;
Go

Create View dbo.vwReceiptDetails (
  ReceiptDetailId,
  ReceiptLine,  -- deprecated
  ReceiptId,
  ReceiptNumber,
  ReceiptType,
  ReceiptTypeDesc,
  ReceiptStatus,
  ReceiptStatusDesc,

  SKUId,
  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,
  SKUDescription,

  QtyOrdered,
  QtyInTransit,
  QtyReceived,
  QtyToReceive,
  QtyToLabel,

  LPNsReceived,
  LPNsInTransit,
  ExtraQtyAllowed,
  MaxQtyAllowedToReceive,

  VendorId,
  VendorName,
  Ownership,
  OwnershipDesc,
  Warehouse,
  WarehouseDesc,
  BUDescription,

  DateOrdered,
  DateExpected,
  ETACountry,
  ETACity,
  ETAWarehouse,
  AppointmentDateTime,

  UnitCost,
  HostReceiptLine,
  CoO,
  CustPO,
  PackingSlipNumber,

  Lot,
  InventoryClass1,
  InventoryClass2,
  InventoryClass3,

  SortLanes,
  SortOptions,
  SortStatus,

  UPC,
  CaseUPC,
  UoM,
  InventoryUoM,
  UoMDescription,
  SKUImageURL,

  Description, -- -- Description is deprecated, we now use SKUDescription
  SKU1Description,
  SKU2Description,
  SKU3Description,
  SKU4Description,
  SKU5Description,

  InnerPacksPerLPN,
  UnitsPerInnerPack,
  UnitsPerLPN,

  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,

  RH_UDF1,
  RH_UDF2,
  RH_UDF3,
  RH_UDF4,
  RH_UDF5,
  RH_UDF6,
  RH_UDF7,
  RH_UDF8,
  RH_UDF9,
  RH_UDF10,

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

  /* deprecated below, do not use */
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

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy

) As
select
  RD.ReceiptDetailId,
  RD.ReceiptLine, -- deprecated
  RD.ReceiptId,
  RH.ReceiptNumber,
  RH.ReceiptType,
  ET.TypeDescription,
  RH.Status,
  ST.StatusDescription,

  RD.SKUId,
  S.SKU,
  S.SKU1,
  S.SKU2,
  S.SKU3,
  S.SKU4,
  S.SKU5,
  S.Description,

  RD.QtyOrdered,
  RD.QtyInTransit,
  RD.QtyReceived,
  RD.QtyToReceive,
  RD.QtyToLabel,

  RD.LPNsReceived,
  RD.LPNsInTransit,
  RD.ExtraQtyAllowed,
  /* MaxQtyAllowedToReceive */
  case when ((RD.QtyOrdered - RD.QtyReceived + RD.ExtraQtyAllowed) < 0) then
         0
       else
        (RD.QtyOrdered - RD.QtyReceived + RD.ExtraQtyAllowed)
  end,

  RH.VendorId,
  V.VendorName,
  RH.Ownership,
  LUO.LookUpDescription, /* Ownership Desc */
  RH.Warehouse,
  LUW.LookUpDescription, /* Warehouse Desc */
  '' /* BU Description - deprecated */,

  RH.DateOrdered,
  RH.DateExpected,
  RH.ETACountry,
  RH.ETACity,
  RH.ETAWarehouse,
  RH.AppointmentDateTime,

  RD.UnitCost,
  RD.HostReceiptLine,
  RD.CoO,
  RD.CustPO,
  'PackingSlipNo',

  RD.Lot,
  RD.InventoryClass1,
  RD.InventoryClass2,
  RD.InventoryClass3,

  RD.SortLanes,
  RD.SortOptions,
  RD.SortStatus,

  S.UPC,
  S.CaseUPC,
  S.UoM,
  S.InventoryUoM,
  L.LookUpDescription,
  S.SKUImageURL,

  S.Description, -- Description is deprecated, we now use SKUDescription
  S.SKU1Description,
  S.SKU2Description,
  S.SKU3Description,
  S.SKU4Description,
  S.SKU5Description,

  S.InnerPacksPerLPN,
  S.UnitsPerInnerPack,
  S.UnitsPerLPN,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,

  RH.UDF1,
  RH.UDF2,
  RH.UDF3,
  RH.UDF4,
  RH.UDF5,
  RH.UDF6,
  RH.UDF7,
  RH.UDF8,
  RH.UDF9,
  RH.UDF10,

  RD.UDF1,
  RD.UDF2,
  RD.UDF3,
  RD.UDF4,
  RD.UDF5,
  RD.UDF6,
  RD.UDF7,
  RD.UDF8,
  RD.UDF9,
  RD.UDF10,

  RD.UDF1,
  RD.UDF2,
  RD.UDF3,
  RD.UDF4,
  RD.UDF5,
  RD.UDF6,
  RD.UDF7,
  RD.UDF8,
  RD.UDF9,
  RD.UDF10,

  RD.BusinessUnit,
  RD.CreatedDate,
  RD.ModifiedDate,
  RD.CreatedBy,
  RD.ModifiedBy
from
  ReceiptDetails RD
  left outer join ReceiptHeaders  RH   on (RD.ReceiptId        = RH.ReceiptId   )
  left outer join SKUs            S    on (RD.SKUId            = S.SKUId        )
  left outer join EntityTypes     ET   on (RH.ReceiptType      = ET.TypeCode    ) and
                                          (ET.Entity           = 'Receipt'      ) and
                                          (ET.BusinessUnit     = RD.BusinessUnit)
  left outer join Statuses        ST   on (RH.Status           = ST.StatusCode  ) and
                                          (ST.Entity           = 'Receipt'      ) and
                                          (ST.BusinessUnit     = RD.BusinessUnit)
  left outer join Vendors         V    on (RH.VendorId         = V.VendorId     )
  left outer join LookUps         LUO  on (RH.Ownership        = LUO.LookUpCode ) and
                                          (LUO.LookUpCategory  = 'Owner'        ) and
                                          (LUO.BusinessUnit    = RD.BusinessUnit)
  left outer join LookUps         LUW  on (RH.Warehouse        = LUW.LookUpCode ) and
                                          (LUW.LookUpCategory  = 'Warehouse'    ) and
                                          (LUW.BusinessUnit    = RD.BusinessUnit)
  left outer join LookUps         L    on ((L.LookUpCode      = S.UoM) and
                                           (L.LookUpCategory   = 'UoM'))
where (RD.QtyOrdered > 0);

Go
