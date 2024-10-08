/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/12  RIA     Added pr_Imports_SKUAttributes, pr_Imports_SKUAttributes_Insert, pr_Imports_SKUAttributes_Update, pr_Imports_SKUAttributes_Delete (HPI-2485)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUAttributes_Insert') is not null
  drop Procedure pr_Imports_SKUAttributes_Insert;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUAttributes_Insert: Insert the SKU Attribute details from the input temp
   table into the actual table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUAttributes_Insert
  (@ImportSKUAttributes       TSKUImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Insert the SKU Attributes */
  insert into SKUs (
    InnerPacksPerLPN,
    UnitsPerInnerPack,
    UnitsPerLPN,
    InnerPackWeight,
    InnerPackLength,
    InnerPackWidth ,
    InnerPackHeight,
    InnerPackVolume,
    UnitWeight,
    UnitLength,
    UnitWidth,
    UnitHeight,
    UnitVolume,
    PalletTie,
    PalletHigh,
    ShipUoM,
    ShipPack)
  output 'SKU', Inserted.SKUId, Inserted.SKU, 'AT_SKUDimensionsModified' /* Audit Activity */, 'I' /* Action - Insert */,
         Inserted.BusinessUnit, Inserted.ModifiedBy
  into #ImportSKUAttrAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  select
    InnerPacksPerLPN,
    UnitsPerInnerPack,
    UnitsPerLPN,
    InnerPackWeight,
    InnerPackLength,
    InnerPackWidth ,
    InnerPackHeight,
    InnerPackVolume,
    UnitWeight,
    UnitLength,
    UnitWidth,
    UnitHeight,
    UnitVolume,
    PalletTie,
    PalletHigh,
    ShipUoM,
    ShipPack
  from @ImportSKUAttributes
  where (RecordAction = 'I' /* Insert */)
  order by HostRecId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_SKUAttributes_Insert */

Go
