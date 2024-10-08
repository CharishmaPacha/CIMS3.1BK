/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/11/07  YAN     Added ProductInfo1, ProductInfo2, ProductInfo3 (portback from BK onsite prod) (BK-75)
  2021/02/03  SGK     Added NestingFactor, PickMultiple, PrimaryPickZone, SecondaryPickZone, NMFC, HarmonizedCode, IsBaggable, SKUSortOrder, DefaultCoO, Archived (CIMSV3-1334)
  2020/10/09  RIA     Added DisplaySKU, DisplaySKUDesc, SKUImageURL (CIMSV3-1108)
  2020/09/15  RV      UnitDimensions: Made changes to null if considering type varchar instead of integer to handle conversion errors (HA-1343)
  2020/04/06  OK      Added V3 status fields (HA-132)
  2019/05/19  AY      Added UnitDimensions (V3)
  2019/01/29  TK      Added InventoryUoM (S2GMI-83)
  2018/09/28  KSK/VM  Added CartonGroup field (HPI-2044)
  2018/04/13  VM      Added CaseUPC, vwUDFs and aliases modified for UDFs (S2G-528)
  2016/08/08  MV      Added new field ReplenishClass (HPI-1423)
  2016/04/29  AY      Show ProdCategory when Desc is not available
  2015/10/23  OK      Added new field Ownership (NBD-36)
  2014/02/17  TD      Added new fields UnitCost/PickUoM/ShipUoM/ShipPack/PalletTie,PalletHigh,
                                Serialized,IsSortable,IsConveyable,IsConveyable.
  2013/07/26  NY      Added Length/Width/Height/Volume for Units and Innerpacks
  2013/03/27  AY      Added BU in joins
  2013/03/07  PKS     New fields SKU1Description1 to SKU1Description5, AlternateSKU, InnerPacksPerLPN,
                      UnitsPerInnerPack, UnitWeight, UnitPrice, CClass migrated from OB To TD.
  2011/08/29  TD      Changed LookUpCategory PC to ProductCategory and PSC to ProductSubCategory.
  2011/08/03  TD      Added PutawayClassDescriptions.
  2011/07/11  PK      Added PutawayClass.
  2011/07/05  PK      Added SKU1 - SKU5 fields.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/14  PK      Added StatusDescription.
  2010/11/19  VK      vwSKU => vwSKUs
  2010/10/26  VM      Added ProdCategory, ProdSubCategory
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwSKUs') is not null
  drop View dbo.vwSKUs;
Go

Create View dbo.vwSKUs (
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
  ProductInfo1,
  ProductInfo2,
  ProductInfo3,
  AlternateSKU,
  DisplaySKU,
  DisplaySKUDesc,

  Status,
  StatusDescription,
  SKUStatus,
  SKUStatusDesc,
  UoM,
  InventoryUoM,

  InnerPacksPerLPN,
  UnitsPerInnerPack,
  UnitsPerLPN,
  InnerPackWeight,
  InnerPackLength,
  InnerPackWidth,
  InnerPackHeight,
  InnerPackVolume,
  UnitWeight,
  UnitLength,
  UnitWidth,
  UnitHeight,
  UnitVolume,
  NestingFactor,
  UnitDimensions,

  UnitPrice,
  UnitCost,

  PickUoM,
  ShipUoM,
  PickMultiple,
  ShipPack,

  PalletTie,
  PalletHigh,

  Barcode,
  UPC,
  CaseUPC,
  Brand,
  SKUImageURL,

  ProdCategory,
  ProdCategoryDesc,
  ProdSubCategory,
  ProdSubCategoryDesc,
  PutawayClass,
  PutawayClassDesc,
  PutawayClassDisplayDesc,
  ABCClass,
  ReplenishClass,
  ReplenishClassDesc,
  ReplenishClassDisplayDesc,

  PrimaryLocationId,
  PrimaryLocation,
  PrimaryPickZone,
  SecondaryPickZone,

  CartonGroup,
  CartonGroupDesc,
  CartonGroupDisplayDesc,
  NMFC,
  HarmonizedCode,

  Serialized,
  IsSortable,
  IsConveyable,
  IsScannable,
  IsBaggable,
  SKUSortOrder,
  Ownership,
  DefaultCoO,

  SKU_UDF1,
  SKU_UDF2,
  SKU_UDF3,
  SKU_UDF4,
  SKU_UDF5,
  SKU_UDF6,
  SKU_UDF7,
  SKU_UDF8,
  SKU_UDF9,
  SKU_UDF10,

  vwSKU_UDF1,
  vwSKU_UDF2,
  vwSKU_UDF3,
  vwSKU_UDF4,
  vwSKU_UDF5,

  SourceSystem,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
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
  S.ProductInfo1,
  S.ProductInfo2,
  S.ProductInfo3,
  S.AlternateSKU,
  S.DisplaySKU,
  S.DisplaySKUDesc,

  S.Status,
  ST.StatusDescription,
  S.Status,
  ST.StatusDescription,
  S.UoM,
  S.InventoryUoM,

  S.InnerPacksPerLPN,
  S.UnitsPerInnerPack,
  S.UnitsPerLPN,
  case when coalesce(S.InnerPackWeight, 0) <> 0 then S.InnerPackWeight
       else S.UnitsPerInnerPack * S.UnitWeight
  end,
  S.InnerPackLength,
  S.InnerPackWidth,
  S.InnerPackHeight,
  case when coalesce(S.InnerPackVolume, 0) <> 0 then S.InnerPackVolume
       else S.UnitsPerInnerPack * S.UnitVolume
  end,
  S.UnitWeight,
  S.UnitLength,
  S.UnitWidth,
  S.UnitHeight,
  S.UnitVolume,
  S.NestingFactor,
  /* Unit Dimensions */
  coalesce(nullif(cast(UnitLength as varchar), '0'), '?') + ' x ' +
  coalesce(nullif(cast(UnitWidth  as varchar), '0'), '?') + ' x ' +
  coalesce(nullif(cast(UnitHeight as varchar), '0'), '?'),

  S.UnitPrice,
  S.UnitCost,

  S.PickUoM,
  S.ShipUoM,
  S.PickMultiple,
  S.ShipPack,

  S.PalletTie,
  S.PalletHigh,

  S.Barcode,
  S.UPC,
  S.CaseUPC,
  S.Brand,
  S.SKUImageURL,

  S.ProdCategory,
  coalesce(PC.LookUpDescription, S.ProdCategory),
  S.ProdSubCategory,
  coalesce(PSC.LookUpDescription, S.ProdSubCategory),
  S.PutawayClass,
  PAC.LookUpDescription,
  PAC.LookUpDisplayDescription,
  S.ABCClass,
  S.ReplenishClass,

  RC.LookUpDescription,
  RC.LookUpDisplayDescription,

  S.PrimaryLocationId,
  S.PrimaryLocation,
  S.PrimaryPickZone,
  S.SecondaryPickZone,

  S.CartonGroup,
  CG.LookUpDescription,
  CG.LookUpDisplayDescription,
  S.NMFC,
  S.HarmonizedCode,

  S.Serialized,
  S.IsSortable,
  S.IsConveyable,
  S.IsScannable,
  S.IsBaggable,
  S.SKUSortOrder,
  S.Ownership,
  S.DefaultCoO,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,
  S.UDF6,
  S.UDF7,
  S.UDF8,
  S.UDF9,
  S.UDF10,

  S.SourceSystem,
  cast(' ' as varchar(50)), /* vwSKU_UDF1 */
  cast(' ' as varchar(50)), /* vwSKU_UDF2 */
  cast(' ' as varchar(50)), /* vwSKU_UDF3 */
  cast(' ' as varchar(50)), /* vwSKU_UDF4 */
  cast(' ' as varchar(50)), /* vwSKU_UDF5 */

  S.Archived,
  S.BusinessUnit,
  S.CreatedDate,
  S.ModifiedDate,
  S.CreatedBy,
  S.ModifiedBy
from
  SKUs S
  left outer join LookUps  PC  on (PC.LookUpCode      = S.ProdCategory      ) and
                                  (PC.LookUpCategory  = 'ProductCategory'   ) and
                                  (PC.BusinessUnit    = S.BusinessUnit      )
  left outer join LookUps  PSC on (PSC.LookUpCode     = S.ProdSubCategory   ) and
                                  (PSC.LookUpCategory = 'ProductSubCategory') and
                                  (PSC.BusinessUnit   = S.BusinessUnit      )
  left outer join Statuses ST  on (ST.StatusCode      = S.Status            ) and
                                  (ST.Entity          = 'Status'            ) and
                                  (ST.BusinessUnit    = S.BusinessUnit      )
  left outer join Lookups  PAC on (S.PutawayClass     = PAC.LookUpCode      ) and
                                  (PAC.LookUpCategory = 'PutawayClasses'    ) and
                                  (PAC.BusinessUnit   = S.BusinessUnit      )
  left outer join Lookups  RC  on (S.ReplenishClass   = RC.LookUpCode       ) and
                                  (RC.LookUpCategory  = 'ReplenishClasses'  ) and
                                  (RC.BusinessUnit    = S.BusinessUnit      )
  left outer join Lookups  CG  on (S.CartonGroup      = CG.LookUpCode       ) and
                                  (CG.LookUpCategory  = 'CartonGroups'      ) and
                                  (CG.BusinessUnit    = S.BusinessUnit      );

Go
