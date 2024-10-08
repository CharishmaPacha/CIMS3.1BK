/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/08/02  TD      pr_SKUs_AddOrUpdate: Added other params (XSC related )
  2012/11/08  PKS     pr_SKUs_AddOrUpdate: commented validation of ProdCategory and ProdSubCategory.
  2011/08/29  TD      pr_SKUs_AddOrUpdate: Change LookUpCategory from PC to ProductCategory,
                      pr_SKUs_AddOrUpdate: Added ProdCategory, ProdSubCategory
  2010/10/18  SHR     pr_SKUs_AddOrUpdate: Changed input and output parameters,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_AddOrUpdate') is not null
  drop Procedure pr_SKUs_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_AddOrUpdate
  (@SKU                TSKU,
   @Description        TDescription,
   @Status             TStatus,
   @UoM                TUoM,

   @Barcode            TBarcode,
   @UPC                TUPC,
   @Brand              TBrand,

   @ProdCategory       TCategory,
   @ProdSubCategory    TCategory,
   @PutawayClass       TCategory,

   @UnitWeight         TFloat,
   @UnitLength         TFloat,
   @UnitWidth          TWidth,
   @UnitHeight         THeight,
   @UnitVolume         TVolume,

   @InnerPacksPerLPN   TInteger,
   @UnitsPerInnerPack  TInteger,
   @UnitsPerLPN        TInteger,


   @UDF1               TUDF,
   @UDF2               TUDF,
   @UDF3               TUDF,
   @UDF4               TUDF,
   @UDF5               TUDF,
   @UDF6               TUDF,
   @UDF7               TUDF,
   @UDF8               TUDF,
   @UDF9               TUDF,
   @UDF10              TUDF,

   @BusinessUnit       TBusinessUnit,
   ------------------------------------
   @SKUId              TRecordId output,
   @CreatedDate        TDateTime output,
   @ModifiedDate       TDateTime output,
   @CreatedBy          TUserId   output,
   @ModifiedBy         TUserId   output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;

  declare @Inserted table (SKUId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'A' /* Active */);

  /* Validate SKU */
  if (@SKU is null)
    set @MessageName = 'SKUIsInvalid';
  else
  if (@SKUId is null) and
     (exists(select *
             from SKUs
             where SKU = @SKU))
    set @MessageName = 'SKUAlreadyExists';  /* trying to add an existing SKU */
  else
  if (@Description is null)
    set @MessageName = 'SKUDescriptionIsInvalid';
 /* As TD is not using ProdCategory and ProductSubCategory.
    It is causing problem in editing of SKUs UDF3 and UDF4 in SKUs page in Inline Edit.*/
 /* else
  if (@ProdCategory is not null) and
     (not exists(select *
                 from LookUps
                 where (LookUpCategory = 'ProductCategory') and
                       (LookUpCode     = @ProdCategory)))
    set @MessageName = 'ProdCategoryIsInvalid';
  else
  if (@ProdSubCategory is not null) and
     (not exists(select *
                 from LookUps
                 where (LookUpCategory = 'ProductSubCategory') and
                       (LookUpCode     = @ProdSubCategory)))
    set @MessageName = 'ProdSubCategoryIsInvalid';*/
  else
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Validates SKU whether it is exists, if it then it updates or inserts  */
  if (not exists(select *
                 from SKUs
                 where SKUId = @SKUId))
    begin
      insert into SKUs(SKU,
                       Description,
                       Status,
                       UoM,
                       BarCode,
                       UPC,
                       Brand,
                       ProdCategory,
                       ProdSubCategory,
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
                       CreatedBy)
                output inserted.SKUId, inserted.CreatedDate, inserted.CreatedBy
                  into @Inserted
                select @SKU,
                       @Description,
                       @Status,
                       @UoM,
                       @Barcode,
                       @UPC,
                       @Brand,
                       @ProdCategory,
                       @ProdSubCategory,
                       @UDF1,
                       @UDF2,
                       @UDF3,
                       @UDF4,
                       @UDF5,
                       @UDF6,
                       @UDF7,
                       @UDF8,
                       @UDF9,
                       @UDF10,
                       @BusinessUnit,
                       coalesce(@CreatedBy, System_User);

      select @SKUId       = SKUId,
             @CreatedDate = CreatedDate,
             @CreatedBy   = CreatedBy
      from @Inserted;
    end
  else
    begin
      update SKUs
      set
        Description        = @Description,
        Status             = @Status,
        UoM                = @UoM,
        UPC                = @UPC,
        Brand              = @Brand,
        ProdCategory       = @ProdCategory,
        ProdSubCategory    = @ProdSubCategory,
        PutawayClass       = @PutawayClass,
        UnitWeight         = @UnitWeight,
        UnitLength         = @UnitLength,
        UnitWidth          = @UnitWidth,
        UnitHeight         = @UnitHeight,
        UnitVolume         = @UnitVolume,
        InnerPacksPerLPN   = @InnerPacksPerLPN,
        UnitsPerInnerPack  = @UnitsPerInnerPack,
        UnitsPerLPN        = @UnitsPerLPN,
        UDF1               = @UDF1,
        UDF2               = @UDF2,
        UDF3               = @UDF3,
        UDF4               = @UDF4,
        UDF5               = @UDF5,
        UDF6               = @UDF6,
        UDF7               = @UDF7,
        UDF8               = @UDF8,
        UDF9               = @UDF9,
        UDF10              = @UDF10,
        @ModifiedDate      = ModifiedDate = current_timestamp,
        @ModifiedBy        = ModifiedBy   = coalesce(@ModifiedBy, System_User)
      where SKUId = @SKUId;

     /* If we do any changes about the SKU dimensions then we need to export those
       details */
       exec pr_Exports_SKUData  'SKUCh', @SKUId, @UPC, @BusinessUnit, @ModifiedBy;
    end

ErrorHandler:
  if (@MessageName is not null)
  begin
    select @Message = Description,
           @ReturnCode = 1
    from Messages
    where MessageName = @MessageName;

    raiserror(@Message, 16, 1);
  end

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_SKUs_AddOrUpdate */

Go
