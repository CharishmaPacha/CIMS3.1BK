/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUs_Update') is not null
  drop Procedure pr_Imports_SKUs_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUs_Update:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUs_Update
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @vSKUPutawayClassUpdate  TString,
          @vSKUPackInfoUpdate      Tstring,
          @vSKUCubeUpdate          TString,
          @vSKUWeightUpdate        TString,
          @vSKUPalletTieHighUpdate Tstring,
          @vSKUDimensionUpdate     TString,
          @vSKUIPCubeUpdate        TString,
          @vSKUIPWeightUpdate      TString,
          @vSKUIPDimensionUpdate   TString;

begin
  SET NOCOUNT ON;

  select @vSKUPutawayClassUpdate  = dbo.fn_Controls_GetAsString('SKU', 'PutawayClassUpdate',     'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUPackInfoUpdate      = dbo.fn_Controls_GetAsString('SKU', 'SKUPackInfoUpdate',      'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUCubeUpdate          = dbo.fn_Controls_GetAsString('SKU', 'SKUCubeUpdate',          'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUWeightUpdate        = dbo.fn_Controls_GetAsString('SKU', 'SKUWeightUpdate',        'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUPalletTieHighUpdate = dbo.fn_Controls_GetAsString('SKU', 'PalletTieHighUpdate',    'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUDimensionUpdate     = dbo.fn_Controls_GetAsString('SKU', 'SKUDimensionUpdate',     'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUIPCubeUpdate        = dbo.fn_Controls_GetAsString('SKU', 'SKUIPCubeUpdate',        'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUIPWeightUpdate      = dbo.fn_Controls_GetAsString('SKU', 'SKUIPWeightUpdate',      'HOST', @BusinessUnit, '' /* user id */ );
  select @vSKUIPDimensionUpdate   = dbo.fn_Controls_GetAsString('SKU', 'SKUIPDimensionUpdate',   'HOST', @BusinessUnit, '' /* user id */ );

  update S1
  set
    S1.SKU               = S2.SKU,
    S1.SKU1              = S2.SKU1,
    S1.SKU2              = S2.SKU2,
    S1.SKU3              = S2.SKU3,
    S1.SKU4              = S2.SKU4,
    S1.SKU5              = S2.SKU5,
    S1.Description       = S2.Description,
    S1.SKU1Description   = S2.SKU1Description,
    S1.SKU2Description   = S2.SKU2Description,
    S1.SKU3Description   = S2.SKU3Description,
    S1.SKU4Description   = S2.SKU4Description,
    S1.SKU5Description   = S2.SKU5Description,
    S1.AlternateSKU      = S2.AlternateSKU,
    S1.Status            = coalesce(nullif(ltrim(rtrim(S2.Status)), ''), 'A' /* Active */),
    S1.UoM               = coalesce(nullif(S2.UoM, ''), nullif(S1.UoM, ''), 'EA'),
    S1.InnerPacksPerLPN  = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPackInfoUpdate) <> 0 then S2.InnerPacksPerLPN else S1.InnerPacksPerLPN end,
    S1.UnitsPerInnerPack = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPackInfoUpdate) <> 0 then coalesce(S2.UnitsPerInnerPack, 0) else S1.UnitsPerInnerPack end,
    S1.UnitsPerLPN       = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPackInfoUpdate) <> 0 then S2.UnitsPerLPN else S1.UnitsPerLPN end,
    S1.InnerPackWeight   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUIPWeightUpdate) <> 0 then coalesce(nullif(S2.InnerPackWeight, ''), S1.InnerPackWeight) else S1.InnerPackWeight end,
    S1.InnerPackLength   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUIPDimensionUpdate) <> 0 then coalesce(nullif(S2.InnerPackLength, ''), S1.InnerPackLength) else S1.InnerPackLength end,
    S1.InnerPackWidth    = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUIPDimensionUpdate) <> 0 then coalesce(nullif(S2.InnerPackWidth, ''), S1.InnerPackWidth) else S1.InnerPackWidth end,
    S1.InnerPackHeight   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUIPDimensionUpdate) <> 0 then coalesce(nullif(S2.InnerPackHeight, ''), S1.InnerPackHeight) else S1.InnerPackHeight end,
    S1.InnerPackVolume   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUIPCubeUpdate) <> 0 then coalesce(nullif(S2.InnerPackVolume, ''), S1.InnerPackVolume) else S1.InnerPackVolume end,
    S1.UnitWeight        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUWeightUpdate) <> 0 then coalesce(nullif(S2.UnitWeight, ''), S1.UnitWeight) else S1.UnitWeight end,
    S1.UnitLength        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(S2.UnitLength, ''), S1.UnitLength) else S1.UnitLength end,
    S1.UnitWidth         = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(S2.UnitWidth, ''), S1.UnitWidth)  else S1.UnitWidth  end,
    S1.UnitHeight        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(S2.UnitHeight, ''), S1.UnitHeight) else S1.UnitHeight end,
    S1.UnitVolume        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUCubeUpdate) <> 0 then S2.UnitVolume else S1.UnitVolume end,
    S1.NestingFactor     = S2.NestingFactor,
    S1.UnitPrice         = S2.UnitPrice,
    S1.UnitCost          = S2.UnitCost,
    S1.PalletTie         = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPalletTieHighUpdate) <> 0 then S2.PalletTie  else S1.PalletTie  end,
    S1.PalletHigh        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPalletTieHighUpdate) <> 0 then S2.PalletHigh else S1.PalletHigh end,
    S1.PickUoM           = S2.PickUoM,
    S1.ShipUoM           = S2.ShipUoM,
    S1.ShipPack          = S2.ShipPack,
    S1.IsSortable        = S2.IsSortable,
    S1.IsConveyable      = S2.IsConveyable,
    S1.IsScannable       = S2.IsScannable,
    S1.SKUSortOrder      = S2.SKUSortOrder,
    S1.Barcode           = S2.Barcode,
    S1.UPC               = S2.UPC,
    S1.CaseUPC           = S2.CaseUPC,
    S1.Brand             = S2.Brand,
    S1.ProdCategory      = S2.ProdCategory,
    S1.ProdSubCategory   = S2.ProdSubCategory,
    S1.PutawayClass      = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPutawayClassUpdate) <> 0 then S2.PutawayClass else S1.PutawayClass end,
    S1.ABCClass          = S2.ABCClass,
    S1.NMFC              = S2.NMFC,
    S1.HarmonizedCode    = S2.HarmonizedCode,
    S1.Ownership         = S2.Ownership,
    S1.DefaultCoO        = S2.DefaultCoO,
    S1.Serialized        = S2.Serialized,
    S1.ReturnDisposition = coalesce((nullif(S2.ReturnDisposition, '')), S1.ReturnDisposition),
    S1.UDF1              = S2.SKU_UDF1,
    S1.UDF2              = S2.SKU_UDF2,
    S1.UDF3              = S2.SKU_UDF3,
    S1.UDF4              = S2.SKU_UDF4,
    S1.UDF5              = S2.SKU_UDF5,
    S1.UDF6              = S2.SKU_UDF6,
    S1.UDF7              = S2.SKU_UDF7,
    S1.UDF8              = S2.SKU_UDF8,
    S1.UDF9              = S2.SKU_UDF9,
    S1.UDF10             = S2.SKU_UDF10,
    --S1.SourceSystem      = S2.SourceSystem, should not change source system
    S1.BusinessUnit      = S2.BusinessUnit,
    S1.ModifiedDate      = coalesce(S2.ModifiedDate, current_timestamp),
    S1.ModifiedBy        = coalesce(S2.ModifiedBy, System_User)
  output 'SKU', Inserted.SKUId, S2.SKU, 'AT_SKUModified', Inserted.BusinessUnit, Inserted.ModifiedBy, S2.RecordAction
  into #ImportSKUAuditInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Action)
  from SKUs S1 inner join #ImportSKUs S2 on (S1.SKU = S2.SKU)
  where (S2.RecordAction = 'U' /* Update */);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_SKUs_Update */

Go
