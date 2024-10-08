/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/10  MS      pr_Imports_SKUAttributes_Update,pr_Imports_SKUs : Changes to update SKUDimentions (JL-76)
  2019/03/12  RIA     Added pr_Imports_SKUAttributes, pr_Imports_SKUAttributes_Insert, pr_Imports_SKUAttributes_Update, pr_Imports_SKUAttributes_Delete (HPI-2485)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUAttributes_Update') is not null
  drop Procedure pr_Imports_SKUAttributes_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUAttributes_Update: Update the SKU Attribute Details using the input
   temp table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUAttributes_Update
  (@ImportSKUAttributes  TSKUImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
      @vBusinessUnit      TBusinessUnit;

  declare @vSKUPackInfoUpdate      Tstring,
          @vSKUCubeUpdate          TString,
          @vSKUWeightUpdate        TString,
          @vSKUPalletTieHighUpdate Tstring,
          @vSKUDimensionUpdate     TString;
begin
  SET NOCOUNT ON;

  select @vSKUPackInfoUpdate      = dbo.fn_Controls_GetAsString('SKU', 'SKUPackInfoUpdate',      'CIMS', @vBusinessUnit, '' /* user id */ );
  select @vSKUCubeUpdate          = dbo.fn_Controls_GetAsString('SKU', 'SKUCubeUpdate',          'CIMS', @vBusinessUnit, '' /* user id */ );
  select @vSKUWeightUpdate        = dbo.fn_Controls_GetAsString('SKU', 'SKUWeightUpdate',        'CIMS', @vBusinessUnit, '' /* user id */ );
  select @vSKUPalletTieHighUpdate = dbo.fn_Controls_GetAsString('SKU', 'PalletTieHighUpdate',    'CIMS', @vBusinessUnit, '' /* user id */ );
  select @vSKUDimensionUpdate     = dbo.fn_Controls_GetAsString('SKU', 'SKUDimensionUpdate',     'CIMS', @vBusinessUnit, '' /* user id */ );

  /* Update the SKU Attributes */
  update S1
  set
    S1.InnerPacksPerLPN  = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPackInfoUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.InnerPacksPerLPN), ''), S1.InnerPacksPerLPN) else S1.InnerPacksPerLPN end,
    S1.UnitsPerInnerPack = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPackInfoUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitsPerInnerPack), ''), S1.UnitsPerInnerPack) else S1.UnitsPerInnerPack end,
    S1.UnitsPerLPN       = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPackInfoUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitsPerLPN), ''), S1.UnitsPerLPN) else S1.UnitsPerLPN end,
    S1.InnerPackWeight   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUWeightUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.InnerPackWeight), ''), S1.InnerPackWeight) else S1.InnerPackWeight end,
    S1.InnerPackLength   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.InnerPackLength), ''), S1.InnerPackLength) else S1.InnerPackLength end,
    S1.InnerPackWidth    = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.InnerPackWidth), ''), S1.InnerPackWidth) else S1.InnerPackWidth end,
    S1.InnerPackHeight   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.InnerPackHeight), ''), S1.InnerPackHeight) else S1.InnerPackHeight end,
    S1.InnerPackVolume   = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUCubeUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.InnerPackVolume), ''), S1.InnerPackVolume) else S1.InnerPackVolume end,
    S1.UnitWeight        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUWeightUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitWeight), ''), S1.UnitWeight) else S1.UnitWeight end,
    S1.UnitLength        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitLength), ''), S1.UnitLength) else S1.UnitLength end,
    S1.UnitWidth         = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitWidth), ''), S1.UnitWidth)  else S1.UnitWidth  end,
    S1.UnitHeight        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUDimensionUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitHeight), ''), S1.UnitHeight) else S1.UnitHeight end,
    S1.UnitVolume        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUCubeUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.UnitVolume), ''), S1.UnitVolume) else S1.UnitVolume end,
    S1.PalletTie         = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPalletTieHighUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.PalletTie), ''), S1.PalletTie) else S1.PalletTie  end,
    S1.PalletHigh        = case when dbo.fn_IsInList(S2.SourceSystem, @vSKUPalletTieHighUpdate) <> 0 then coalesce(nullif(convert(varchar, S2.PalletHigh), ''), S1.PalletHigh) else S1.PalletHigh end,
    S1.ShipUoM           = coalesce(nullif(convert(varchar, S2.ShipUoM), ''), S1.ShipUoM),
    S1.ShipPack          = coalesce(nullif(convert(varchar, S2.ShipPack), ''), S1.ShipPack),
    S1.ModifiedDate      = coalesce(S2.ModifiedDate, current_timestamp),
    S1.ModifiedBy        = coalesce(S2.ModifiedBy, System_User)
  output 'SKU', Inserted.SKUId, Inserted.SKU, 'AT_SKUDimensionsModified' /* Audit Activity */, 'U' /* Action - Update */,
         Inserted.BusinessUnit, Inserted.ModifiedBy
  into #ImportSKUAttrAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  from SKUs S1 inner join @ImportSKUAttributes S2 on (S1.SKUId = S2.SKUId)
  where (RecordAction = 'U' /* Update */);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_SKUAttributes_Update */

Go
