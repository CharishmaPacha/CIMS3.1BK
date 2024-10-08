/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUs_Insert') is not null
  drop Procedure pr_Imports_SKUs_Insert;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUs_Insert:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUs_Insert
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  insert into SKUs (
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
    UoM,
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
    UnitPrice,
    UnitCost,
    PalletTie,
    PalletHigh,
    PickUoM,
    ShipUoM,
    ShipPack,
    IsSortable,
    IsConveyable,
    IsScannable,
    SKUSortOrder,
    Barcode,
    UPC,
    CaseUPC,
    Brand,
    ProdCategory,
    ProdSubCategory,
    PutawayClass,
    ABCClass,
    NMFC,
    HarmonizedCode,
    Ownership,
    DefaultCoO,
    Serialized,
    ReturnDisposition,
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
    SourceSystem,
    BusinessUnit,
    CreatedDate,
    CreatedBy)
  select
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
    coalesce(nullif(ltrim(rtrim(Status)), ''), 'A' /* Active */),
    coalesce(nullif(UoM, ''), 'EA'),
    InnerPacksPerLPN,
    coalesce(UnitsPerInnerPack, '0'),
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
    UnitPrice,
    UnitCost,
    PalletTie,
    PalletHigh,
    PickUoM,
    ShipUoM,
    ShipPack,
    IsSortable,
    IsConveyable,
    IsScannable,
    SKUSortOrder,
    Barcode,
    UPC,
    CaseUPC,
    Brand,
    ProdCategory,
    ProdSubCategory,
    PutawayClass,
    ABCClass,
    NMFC,
    HarmonizedCode,
    Ownership,
    DefaultCoO,
    Serialized,
    nullif(ReturnDisposition, ''),
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
    SourceSystem,
    BusinessUnit,
    coalesce(CreatedDate, current_timestamp),
    coalesce(CreatedBy, System_User)
  from #ImportSKUs
  where (RecordAction = 'I' /* Insert */)
  order by HostRecId;

  /* Update SKUId for the newly inserted SKUs in the # table */
  update #ImportSKUs
  set SKUId = S.SKUId
  from SKUS S
       join #ImportSKUs SI on (S.SKU=SI.SKU)
  where (SI.SKUId is null) and (SI.RecordAction = 'I' /* Insert */);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_SKUs_Insert */

Go
