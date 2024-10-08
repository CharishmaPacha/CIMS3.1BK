/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/19  AY      pr_RFC_Inquiry_SKU: Added UnitVolume, Weight, UnitDimensions (V3)
  2018/12/22  AY      pr_RFC_Inquiry_SKU: Summarize qty by Location, LPN
  2018/04/13  VM      pr_RFC_Inquiry_SKU: Modified UDF aliases as per latest in vwSKUs (S2G-528)
  2016/04/13  NY      pr_RFC_Inquiry_SKU: Get most recent SKU by modified date desc (SRI-527)
  2015/12/11  SV      pr_RFC_Inquiry_SKU: Handle duplicate UPCs i.e. diff SKUs having same UPC
  2015/05/28  AY      pr_RFC_Inquiry_SKU: Add UPC
  2013/10/11  PK      pr_RFC_Inquiry_SKU: Added UnitsPerInnerpack, InnerPacksPerLPN.
  2013/07/08  YA      pr_RFC_Inquiry_SKU: Modified to show the details of Static Location as well.
  2013/05/03  AY      pr_RFC_Inquiry_SKU: Show Reserved inventory as well.
  2013/03/25  AY      pr_RFC_Inquiry_SKU: Change to show SKU1..SKU5 and UDF captions based on init_Fields
  2013/03/22  PKS     pr_RFC_Inquiry_SKU: Changes related to using of fn_SKUs_GetScannedSKUs to fetch SKU info was migrated from TD
  2012/01/29  AY      pr_RFC_Inquiry_SKU: Enhanced to return an Active SKU if there is one.
  2012/10/11  AY      pr_RFC_Inquiry_SKU: Find other inventory of that item by scanning a LPN
  2012/08/31  VM      pr_RFC_Inquiry_SKU: Added UDF's to show in SKU info
  2012/08/30  AY      pr_RFC_Inquiry_SKU: Do not show SKU5 for TD
  2012/08/27  AY      pr_RFC_Inquiry_SKU: When no descriptions exists for PAClass, Prod/SubCategory, show actual values
  2011/10/03  PKS     pr_RFC_Inquiry_SKU: Used coalesce to avoid null values.
  2011/09/07  PKS     Created pr_RFC_Inquiry_SKU
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Inquiry_SKU') is not null
  drop Procedure pr_RFC_Inquiry_SKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Inquiry_SKU:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Inquiry_SKU
  (@SKUId        TRecordId,
   @SKU          TSKU,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @ReturnCode               TInteger,
          @MessageName              TMessageName,
          @vSKUId                   TRecordId,
          @vSKU                     TSKU,
          @vSKU1                    TSKU,
          @vSKU2                    TSKU,
          @vSKU3                    TSKU,
          @vSKU4                    TSKU,
          @vSKU5                    TSKU,
          @vSKUDescription          TDescription,
          @vPrimaryLocation         TLocation,
          @vPutawayClassDisplayDesc TDescription,
          @vStatusDesc              TDescription,
          @vProdCategoryDesc        TDescription,
          @vProdSubCategoryDesc     TDescription,
          @vPutawayClass            TCategory,
          @vProdCategory            TCategory,
          @vProdSubCategory         TCategory,
          @vInnerPacksPerLPN        TInteger,
          @vUnitsPerInnerPack       TInteger,
          @vUnitsPerLPN             TInteger,
          @vPalletTie               TInteger,
          @vPalletHigh              TInteger,
          @vUnitVolume              TFloat,
          @vUnitWeight              TFLoat,
          @vUnitDimensions          TDescription,
          @vSKUUDF1                 TUDF,
          @vSKUUDF2                 TUDF,
          @vSKUUDF3                 TUDF,
          @vSKUUDF4                 TUDF,
          @vSKUUDF5                 TUDF,
          @vUPC                     TUPC,
          @vContextName             TName;

  declare @ttSKUInquiry TSKUInquiry;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Assume user has given SKU - order by Status so we
     will find an Active SKU first and if there are multiple, get the most recent */
  select Top 1 @vSKUId = SKUId
  from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit)
  order by Status, coalesce(ModifiedDate, CreatedDate), SKUId desc;

  /* Well, how about LPN? If LPN has single SKU, then we could use that too!
     The intent here is let user scan an LPN and then find similar inventory
     in the Warehouse */
  select @vSKUId = SKUId
  from vwLPNs
  where (LPN          = @SKU  ) and
        (BusinessUnit = @BusinessUnit);

  /* Set ContextName */
  select @vContextName = 'RFInquiry.SKU';

  select @vSKUId                   = SKUId,
         @vSKU                     = SKU,
         @vSKU1                    = nullif(SKU1, ''),
         @vSKU2                    = nullif(SKU2, ''),
         @vSKU3                    = nullif(SKU3, ''),
         @vSKU4                    = nullif(SKU4, ''),
         @vSKU5                    = nullif(SKU5, ''),
         @vSKUDescription          = Description,
         @vPutawayClass            = PutawayClass,
         @vProdCategory            = ProdCategory,
         @vProdSubCategory         = ProdSubCategory,
         @vPutawayClassDisplayDesc = PutawayClassDisplayDesc,
         @vStatusDesc              = StatusDescription,
         @vProdCategoryDesc        = ProdCategoryDesc,
         @vProdSubCategoryDesc     = ProdSubCategoryDesc,
         @vInnerPacksPerLPN        = InnerPacksPerLPN,
         @vUnitsPerInnerPack       = UnitsPerInnerPack,
         @vUnitsPerLPN             = UnitsPerLPN,
         @vPalletTie               = PalletTie,
         @vPalletHigh              = PalletHigh,
         @vUnitVolume              = UnitVolume,
         @vUnitWeight              = UnitWeight,
         @vUnitDimensions          = UnitDimensions,
         @vUPC                     = UPC,
         @vSKUUDF1                 = SKU_UDF1,
         @vSKUUDF2                 = SKU_UDF2,
         @vSKUUDF3                 = SKU_UDF3,
         @vSKUUDF4                 = SKU_UDF4,
         @vSKUUDF5                 = SKU_UDF5
  from vwSKUs
  where (SKUId = @vSKUId);

  /*  If scanned SKU does not exist error-out */
  if (@vSKUId is null)
    set @MessageName = 'SKUDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Insert the basic data */
  insert into @ttSKUInquiry (RecordType, FieldName, FieldValue, FieldVisible)
                     select  'SKU',      'SKU',     @vSKU,      2 /* Always Show */;

  /* Retrieving information from LPNDetails and Locations for given SKU and inserting into temp table
     For the info which is returned from LPNDetails table will be inserted into temp table
     with RecordType as 'SKUDetails'*/
  /* Assuming that there is a possibility for null value to occur, coalesce function is used to avoid it.
     If it was happened in other procedures follow the same there. */
  select LocationType, LocationSubType, OnhandStatus, Location, DestWarehouse, sum(Quantity) Quantity,
          Min(LPN) LPN, PutawayZone
  into #SKUDetails
  from vwLPNDetails LD
  where (LD.SKUId = @vSKUId) and
        ((LD.Quantity     > 0) or (LD.LocationSubType = 'S'/* Static */)) and
        ((LD.OnhandStatus in ('A', 'R' /* Available, Reserved */)) or
         (LD.OnhandStatus ='U' and LD.LPNStatus = 'R' /* Received */))
  group by LocationType, LocationSubType, OnhandStatus, Location, PutawayZone, DestWarehouse, LPN;

  /* Show summary by Location, showing static picklane, dynamic picklane and then others */
  insert into @ttSKUInquiry (RecordType, Quantity, PutawayZone, Location, LPN, Warehouse,
                             OnhandStatDesc, LocTypeDesc, FieldVisible)
    select top 25 'SKUDetails', SD.Quantity, coalesce(SD.PutawayZone, ''),
                  coalesce(SD.Location, ''), case when SD.LocationType = 'K' then '' else SD.LPN end,
                  coalesce(SD.DestWarehouse, ''),
                  OST.StatusDescription, LT.TypeDescription, 2 /* Always show */
    from #SKUDetails SD
         left outer join Statuses OST on    (OST.StatusCode   = SD.OnhandStatus) and
                                            (OST.Entity       = 'OnHand'       ) and
                                            (OST.BusinessUnit = @BusinessUnit  )
         left outer join EntityTypes LT  on (LT.TypeCode      = SD.LocationType) and
                                            (LT.Entity        = 'Location'     ) and
                                            (LT.BusinessUnit  = @BusinessUnit  )
    order by case when SD.LocationType = 'K' and SD.LocationSubType = 'S' then 1
                  when SD.LocationType = 'K' and SD.LocationSubType = 'D' then 2
                  when SD.LocationType = 'B' then 3
                  when SD.LocationType = 'R' then 4
                  when SD.LocationType = 'D' and SD.Onhandstatus    = 'R' then 9 -- Reserved LPN @ Dock are least interesting
                  else 5
             end,
             SD.LocationType, SD.Location, SD.OnhandStatus, SD.LPN;

  /* Retrieving information from SKUs for given SKU and inserting into temp table.
     For the info which is returned from SKUs table will be insterted into temp table
     with RecordType as 'SKUInfo' */
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'Description',       @vSKUDescription
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU1',              @vSKU1
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU2',              @vSKU2
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU3',              @vSKU3
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU4',              @vSKU4
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU5',              @vSKU5
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'UPC',               @vUPC
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'InnerPacksPerLPN',  @vInnerPacksPerLPN
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'UnitsPerInnerPack', @vUnitsPerInnerPack
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'UnitsPerLPN',       @vUnitsPerLPN
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'PalletTie',         @vPalletTie
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'PalletHigh',        @vPalletHigh
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'PutawayClass',      coalesce(@vPutawayClassDisplayDesc, @vPutawayClass, 'Not Defined')
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'Status',            @vStatusDesc
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'ProdCategory',      coalesce(@vProdCategoryDesc, @vProdCategory)
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'ProdSubCategory',   coalesce(@vProdSubCategoryDesc, @vProdSubCategory)
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'UnitVolume',        @vUnitVolume
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'UnitWeight',        @vUnitWeight
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'UnitDimensions',    @vUnitDimensions
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU_UDF1',          @vSKUUDF1
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU_UDF2',          @vSKUUDF2
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU_UDF3',          @vSKUUDF3
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU_UDF4',          @vSKUUDF4
  insert into @ttSKUInquiry (FieldName, FieldValue) select 'SKU_UDF5',          @vSKUUDF5

  /* Use defined captions for all fields */
  update L
  set L.FieldName    = coalesce(FC.FieldCaption, L.FieldName),
      L.FieldVisible = coalesce(FC.FieldVisible, L.FieldVisible),
      L.SortSeq      = coalesce(FC.SortSeq,      L.SortSeq)
  from @ttSKUInquiry L left outer join vwFieldCaptions FC on L.FieldName    = FC.FieldName and
                                                             FC.ContextName = @vContextName;

  /* Return Data-set */
  select *
  from @ttSKUInquiry
  where (FieldVisible > 1) or (FieldVisible = 1 and FieldValue is not null)
  order by SortSeq, RecordId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_Inquiry_SKU */

Go
