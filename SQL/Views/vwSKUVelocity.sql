/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/21  SRP     Initial Revision (BK-813).
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwSKUVelocity') is not null
  drop View dbo.vwSKUVelocity;
Go

Create View dbo.vwSKUVelocity (
   RecordId,

   TransDate,
   VelocityType,

   SKUId,
   SKU,
   SKU1,
   SKU2,
   SKU3,
   SKU4,
   SKU5,
   InventoryClass1,
   InventoryClass2,
   InventoryClass3,

   LocationId,
   Location,

   NumPallets,
   NumLPNs,
   NumCases,
   NumUnits,

   InventoryKey,
   Warehouse,
   Ownership,

   Account,
   AccountName,
   SoldToId,
   ShipToId,
   WaveType,

   SVCategory1,
   SVCategory2,
   SVCategory3,
   SVCategory4,
   SVCategory5,

   Status,

   SV_UDF1,
   SV_UDF2,
   SV_UDF3,
   SV_UDF4,
   SV_UDF5,

   Archived,
   BusinessUnit,
   CreatedDate,
   ModifiedDate,
   CreatedBy,
   ModifiedBy
    ) as
select
   SV.RecordId,

   SV.TransDate,
   SV.VelocityType,

   SV.SKUId,
   SV.SKU,
   S.SKU1,
   S.SKU2,
   S.SKU3,
   S.SKU4,
   S.SKU5,

   SV.InventoryClass1,
   SV.InventoryClass2,
   SV.InventoryClass3,

   SV.LocationId,
   SV.Location,

   SV.NumPallets,
   SV.NumLPNs,
   SV.NumCases,
   SV.NumUnits,

   SV.InventoryKey,
   SV.Warehouse,
   SV.Ownership,

   SV.Account,
   SV.AccountName,
   SV.SoldToId,
   SV.ShipToId,
   SV.WaveType,

   SV.SVCategory1,
   SV.SVCategory2,
   SV.SVCategory3,
   SV.SVCategory4,
   SV.SVCategory5,

   SV.Status,

   SV.SV_UDF1,
   SV.SV_UDF2,
   SV.SV_UDF3,
   SV.SV_UDF4,
   SV.SV_UDF5,

   SV.Archived,
   SV.BusinessUnit,
   SV.CreatedDate,
   SV.ModifiedDate,
   SV.CreatedBy,
   SV.ModifiedBy
from
   SKUVelocity SV join SKUs S on SV.SKUId = S.SKUId
;

Go
