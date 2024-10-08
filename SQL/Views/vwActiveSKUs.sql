/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/29  TK      Added InventoryUoM (S2GMI-83)
  2018/05/02  YJ      Used cast for few fields to fix data bind issue (S2G-801)
  2018/04/13  VM      Added CaseUPC, vwUDFs and aliases modified for UDFs (S2G-528)
  2017/01/11  CK      Join to display Warehouse of the respective owner (S2G-66)
  2017/12/18  NB      Added Join with BusinessUnits for SKUs table and other joins (CIMSV3-162)
  2016/07/15  SV      Avoid sending some values as null to callers (HPI-290)
  2016/05/04  YJ      Added to display Warehouse of the respective Owner (NBD-351)
  2016/04/06  KN      Added UnitsPerInnerPack , UnitsPerLPN for populating CreateInvLPNs popup (NBD-318)
  2015/11/19  RV      Added Ownership for populate the Ownership in the CreateInvLPNs action (NBD-36)
  2015/03/03  SV      Added UoMDescription for showing in the CreateInvLPNs action.
  2014/10/10  PKS     Added InnerPacksPerLPN
  2013/05/22  TD      Added SKU1 to SKU5 descriptions & AlternateSKU.
  2013/02/26  PK      Added ABCClass
  2012/09/22  AA      Initial Revision.  This view will be used to select SKUs in LookUp controls
                        Removed all join to increase the performance and retained the other columns
                        with blank data so that they can be enhanced in future
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwActiveSKUs') is not null
  drop View dbo.vwActiveSKUs;
Go

Create View dbo.vwActiveSKUs (
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
  AlternateSKU,
  Status,
  StatusDescription,
  UoM,
  UoMDescription,
  InventoryUoM,

  InnerPacksPerLPN,
  UnitsPerInnerPack,
  UnitsPerLPN,
  Barcode,
  UPC,
  CaseUPC,
  Brand,

  ProdCategory,
  ProdCategoryDesc,
  ProdSubCategory,
  ProdSubCategoryDesc,
  PutawayClass,
  PutawayClassDesc,
  PutawayClassDisplayDesc,
  ABCClass,
  Ownership,
  Warehouse,

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
  S.AlternateSKU,
  S.Status,
  cast(' ' as varchar(50)), /* ST.StatusDescription */
  S.UoM,
  L.LookUpDescription,
  S.InventoryUoM,

  coalesce(S.InnerPacksPerLPN, 0),
  coalesce(S.UnitsPerInnerPack, 0),
  coalesce(S.UnitsPerLPN, 0),
  S.Barcode,
  S.UPC,
  S.CaseUPC,
  S.Brand,

  S.ProdCategory,
  cast(' ' as varchar(50)), /* PC.LookUpDescription */
  S.ProdSubCategory,
  cast(' ' as varchar(50)), /* PSC.LookUpDescription */
  S.PutawayClass,
  cast(' ' as varchar(50)), /* PAC.LookUpDescription */
  cast(' ' as varchar(50)), /* PAC.LookUpDisplayDescription */
  S.ABCClass,
  S.Ownership,
  LW.LookUpDescription,

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

  cast(' ' as varchar(50)), /* vwSKU_UDF1 */
  cast(' ' as varchar(50)), /* vwSKU_UDF2 */
  cast(' ' as varchar(50)), /* vwSKU_UDF3 */
  cast(' ' as varchar(50)), /* vwSKU_UDF4 */
  cast(' ' as varchar(50)), /* vwSKU_UDF5 */

  S.BusinessUnit,
  S.CreatedDate,
  S.ModifiedDate,
  S.CreatedBy,
  S.ModifiedBy
from
  SKUs S
  left outer join LookUps    L   on (L.LookUpCode      = S.UoM) and
                                    (L.LookUpCategory  = 'UoM') and
                                    (L.BusinessUnit    = S.BusinessUnit)
  left outer join LookUps    LW  on (LW.LookUpCode     = S.Ownership) and
                                    (LW.LookUpCategory = 'OwnerDefaultWarehouse') and /* Display Warehouse of the Respective Owner */
                                    (LW.BusinessUnit   = S.BusinessUnit)
/*
  left outer join LookUps    PC  on (PC.LookUpCode      = S.ProdCategory) and
                                    (PC.LookUpCategory  = 'ProductCategory')
  left outer join LookUps   PSC  on (PSC.LookUpCode     = S.ProdSubCategory) and
                                    (PSC.LookUpCategory = 'ProductSubCategory')
  left outer join Statuses   ST  on (ST.StatusCode      = S.Status) and
                                    (ST.Entity          = 'Status')
  left outer join Lookups   PAC  on (S.PutawayClass     = PAC.LookUpCode   )   and
                                    (PAC.LookUpCategory = 'PutawayClasses')
*/
where S.Status = 'A'/* Active */
;

Go