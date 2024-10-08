/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/05/23  TD      Added pr_Imports_TemplateSKUs, pr_Imports_PreValidateTemplateSKUs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_PreValidateTemplateSKUs') is not null
  drop Procedure pr_Imports_PreValidateTemplateSKUs;
Go
/*------------------------------------------------------------------------------
  Procedure is used to pre-validate the data which is sent from template
  i.e user select SKUs file(which was loaded with records)from the UI to importSKUs.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_PreValidateTemplateSKUs
  (@SKUContents      TXML,
   @Message          TMessageName output)
as
  declare @ttSKUs table
    (RecordId TRecordId identity (1,1), Action TAction, RecordType TRecordType,
     SKU TSKU, SKU1 TSKU, SKU2 TSKU, SKU3 TSKU, SKU4 TSKU, SKU5 TSKU, Description TDescription,
     Status TStatus, UoM TUoM, Barcode TBarcode, UPC TUPC, Brand TBrand,
     ProdCategory TCategory, ProdSubCategory TCategory,
     UDF1 TUDF, UDF2 TUDF, UDF3 TUDF, UDF4 TUDF, UDF5 TUDF,
     UDF6 TUDF, UDF7 TUDF, UDF8 TUDF, UDF9 TUDF, UDF10 TUDF,
     BusinessUnit TBusinessUnit, UserId TUserId, ValidStatus TVarChar,
     Processed TFlag default 'N', Message TVarchar);

  declare @vRecordId TRecordId, @vAction TFlag, @vRecordType TRecordType,
          @vSKU TSKU, @vSKU1 TSKU, @vSKU2 TSKU, @vSKU3 TSKU, @vSKU4 TSKU, @vSKU5 TSKU, @vDescription TDescription,
          @vStatus TStatus, @vUoM TUoM, @vBarcode TBarcode, @vUPC TUPC, @vBrand TBrand,
          @vProdCategory     TCategory, @vProdSubCategory  TCategory,
          @vUDF1 TUDF, @vUDF2 TUDF, @vUDF3 TUDF, @vUDF4 TUDF, @vUDF5 TUDF,
          @vUDF6 TUDF,@vUDF7 TUDF,@vUDF8 TUDF,@vUDF9 TUDF,@vUDF10 TUDF,
          @vBusinessUnit TBusinessUnit, @vUserId TUserId,
          @vCount TCount, @vSKUsCount TCount, @vRecordsCount TCount, @vValidSKUCount TCount,
          @vMessage TVarchar, @MessageName TDescription, @ReturnCode TInteger,
          @xmlData xml, @vRequiredMsg TDescription;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @xmlData      = convert(xml, @SKUContents),
         @vRequiredMsg = 'REQUIRED';

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return;

  /* Get the information from the xml and load into a temp table */
  if (@xmlData is not null)
    begin
      insert into @ttSKUs (
        Action, RecordType,
        SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Description,
        Status, UoM, Barcode, UPC, Brand,
        ProdCategory, ProdSubCategory,
        UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10,
        BusinessUnit, UserId)
      select
        Record.Col.value('Action[1]', 'TFlag'), Record.Col.value('RecordType[1]', 'TRecordType'),
        Record.Col.value('SKU[1]', 'TSKU'), Record.Col.value('SKU1[1]', 'TSKU'),
        Record.Col.value('SKU2[1]', 'TSKU'), Record.Col.value('SKU3[1]', 'TSKU'),
        Record.Col.value('SKU4[1]', 'TSKU'), Record.Col.value('SKU5[1]', 'TSKU'),
        Record.Col.value('Description[1]', 'TDescription'), Record.Col.value('Status[1]', 'TStatus'),
        Record.Col.value('UoM[1]', 'TUoM'), Record.Col.value('Barcode[1]', 'TBarcode'),
        Record.Col.value('UPC[1]', 'TUPC'), Record.Col.value('Brand[1]', 'TBrand'),
        Record.Col.value('ProdCategory[1]', 'TCategory'), Record.Col.value('ProdSubCategory[1]', 'TCategory'),
        Record.Col.value('UDF1[1]', 'TUDF'), Record.Col.value('UDF2[1]', 'TUDF'),
        Record.Col.value('UDF3[1]', 'TUDF'), Record.Col.value('UDF4[1]', 'TUDF'),
        Record.Col.value('UDF5[1]', 'TUDF'), Record.Col.value('UDF6[1]', 'TUDF'),
        Record.Col.value('UDF7[1]', 'TUDF'), Record.Col.value('UDF8[1]', 'TUDF'),
        Record.Col.value('UDF9[1]', 'TUDF'),Record.Col.value('UDF10[1]', 'TUDF'),
        Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), Record.Col.value('UserId[1]', 'TUserId')
      from @xmlData.nodes('/Records/Record') as Record(Col);
    end

  select @vCount        = @@rowcount,
         @vRecordsCount = @@rowcount;

  if (@vCount = 0)
  begin
    set @MessageName = 'NoRecordsFound';
    goto ErrorHandler;
  end

  /* begin Loop */
  while (@vCount > 0)
    begin
      select @vMessage = null;
        /* Get values from temp table */
      select top 1 @vRecordId = RecordId, @vRecordType = RecordType, @vAction = Action,
                   @vSKU = SKU, @vSKU1 = SKU1,
                   @vSKU2 = SKU2, @vSKU3 = SKU3,
                   @vSKU4 = SKU4, @vSKU5 = SKU5,
                   @vDescription = Description, @vStatus = Status,
                   @vUoM = UoM, @vBarcode = Barcode,
                   @vUPC = UPC, @vBrand = Brand,
                   @vProdCategory = ProdCategory, @vProdSubCategory = ProdSubCategory,
                   @vUDF1 = UDF1, @vUDF2 = UDF2,
                   @vUDF3 = UDF3, @vUDF4 = UDF4,
                   @vUDF5 = UDF5, @vUDF6 = UDF6,
                   @vUDF7 = UDF7, @vUDF8 = UDF8,
                   @vUDF9 = UDF9, @vUDF10 = UDF10,
                   @vBusinessUnit = BusinessUnit, @vUserId = UserId
      from @ttSKUs
      where (Processed = 'N' /* No */);


      /* Validate RecordType */
      if (coalesce(@vRecordType, '') <> 'SKU')
        begin
          update @ttsKUs
          set RecordType   = coalesce(RecordType, '') + ' (Invalid Record Type)',
              ValidStatus  = 'Invalid' ,
              Processed    = 'Y' /* Yes */
          where (RecordId  = @vRecordId);
        end
      else
      /* Validate RecordType */
      if (charindex(coalesce(@vAction, ''), 'IUD' /* Insert, Update, Delete */) = 0)
        begin
          update @ttsKUs
          set Action       = coalesce(Action, '') + ' (Invalid Action)',
              ValidStatus  = 'Invalid' ,
              Processed    = 'Y' /* Yes */
          where (RecordId  = @vRecordId);
        end
      else
      /* Validate all mandatory fields */
      if (coalesce(@vSKU,          '') = '') or
         (coalesce(@vDescription,  '') = '') or
         (coalesce(@vUoM,          '') = '') or
         (coalesce(@vStatus,       '') = '') or
         (coalesce(@vBusinessUnit, '') = '')
        begin
          update @ttsKUs
          set SKU          = coalesce(nullif(@vSKU,         ''), @vRequiredMsg),
              Description  = coalesce(nullif(@vDescription, ''), @vRequiredMsg),
              UoM          = coalesce(nullif(@vUoM,         ''), @vRequiredMsg),
              Status       = coalesce(nullif(@vStatus,      ''), @vRequiredMsg),
              BusinessUnit = coalesce(nullif(@vBusinessUnit,''), @vRequiredMsg),
              ValidStatus  = 'Invalid' ,
              Processed    = 'Y' /* Yes */
          where (RecordId  = @vRecordId);
        end
      else
        begin
          update @ttSKUs
          set ValidStatus = 'Valid',
              Processed   = 'Y' /* Yes */
          where (RecordId = @vRecordId);

          select @vValidSKUCount = coalesce(@vValidSKUCount, 0) + 1
        end

      select @vCount = @vCount - 1;
    end

   /* Based upon the number of SKUs that have been Validated, give an appropriate message */
    if (coalesce(@vValidSKUCount,0) = 0)
      set @Message = dbo.fn_Messages_GetDescription ('NoSKUValidToImport');
    else
    if (@vValidSKUCount < @vRecordsCount)
      set @Message = dbo.fn_Messages_GetDescription ('SomeSKUsValidToImport');
    else
    if (@vValidSKUCount = @vRecordsCount)
      set @Message = dbo.fn_Messages_GetDescription ('AllSKUsValidToImport');

    if (@@error <> 0)
      goto ErrorHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Return data from temp table */
  select * from @ttSKUs;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch
end /* pr_Imports_PreValidateTemplateSKUs */

Go
