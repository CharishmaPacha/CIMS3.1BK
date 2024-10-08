/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/19  VS      Added ComponentSKUUnitCost, ComponentSKUUnitPrice, ComponentSKUUOM (BK-1054)
  2013/07/30  PK      Fetching BusinessUnit from SKUPrePacks.
  2012/11/19  PKS     Added BusinessUnit.
  2012/06/28  AY      Added MasterSKU/Component SKU fields
  2012/05/04  PKS     Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwSKUPrePacks') is not null
  drop View dbo.vwSKUPrePacks;
Go

Create View vwSKUPrePacks (
  SKUPrePackId,

  MasterSKUId,
  MasterSKU,
  MasterSKUDescription,
  MSKU1,
  MSKU2,
  MSKU3,
  MSKU4,
  MSKU5,

  ComponentSKUId,
  ComponentSKU,
  ComponentSKUDescription,
  CSKU1,
  CSKU2,
  CSKU3,
  CSKU4,
  CSKU5,

  ComponentQty,
  ComponentSKUUnitCost,
  ComponentSKUUnitPrice,
  ComponentSKUUnitWeight,
  ComponentSKUDefaultCoO,
  ComponentSKUHarmonizedCode,
  ComponentSKUUOM,

  Status,
  StatusDescription,
  SortSeq,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  SPP.SKUPrePackId,

  SPP.MasterSKUId,
  MS.SKU,
  MS.Description,
  MS.SKU1,
  MS.SKU2,
  MS.SKU3,
  MS.SKU4,
  MS.SKU5,

  SPP.ComponentSKUId,
  CS.SKU,
  CS.Description,
  CS.SKU1,
  CS.SKU2,
  CS.SKU3,
  CS.SKU4,
  CS.SKU5,

  SPP.ComponentQty,
  CS.UnitCost,
  CS.UnitPrice,
  CS.UnitWeight,
  CS.DefaultCoO,
  CS.HarmonizedCode,
  CS.UOM,

  SPP.Status,
  ST.StatusDescription,
  SPP.SortSeq,

  SPP.BusinessUnit,
  SPP.CreatedDate,
  SPP.ModifiedDate,
  SPP.CreatedBy,
  SPP.ModifiedBy
from
(
  SKUPrePacks SPP
  left outer join SKUs MS     on (MS.SKUId       = SPP.MasterSKUId)
  left outer join SKUs CS     on (CS.SKUId       = SPP.ComponentSKUId))
  left outer join Statuses ST on ((ST.StatusCode = SPP.Status) and
                                 (ST.Entity     = 'Status'));

Go