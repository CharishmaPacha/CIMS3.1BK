/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/05/23  TD      Added pr_Imports_TemplateSKUs, pr_Imports_PreValidateTemplateSKUs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_TemplateSKUs') is not null
  drop Procedure pr_Imports_TemplateSKUs;
Go
/*------------------------------------------------------------------------------
  Procedure is used to import SKUs which are loaded from SKUs template from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_TemplateSKUs
  (@SKUContents  TXml,
   @Message      TMessageName output)
as
  declare @ttSKUs table
    (RecordId TRecordId Identity(1,1), Action TFlag,RecordType TRecordType,
     SKU TSKU, SKU1 TSKU, SKU2 TSKU, SKU3 TSKU, SKU4 TSKU, SKU5 TSKU, Description TDescription,
     Status TStatus, UoM TUoM, Barcode TBarcode, UPC TUPC, Brand TBrand,
     ProdCategory TCategory, ProdSubCategory TCategory,
     UDF1 TUDF, UDF2 TUDF, UDF3 TUDF, UDF4 TUDF, UDF5 TUDF,
     UDF6 TUDF, UDF7 TUDF, UDF8 TUDF, UDF9 TUDF, UDF10 TUDF,
     BusinessUnit TBusinessUnit, CreatedDate TDateTime, ModifiedDate TDateTime,
     UserId TUserId,ModifiedBy TUserId,
     ImportStatus TDescription, Result TDescription,
     Processed TFlag default 'N', Message TMessageName);

   declare @ttResult table(RecordId  TRecordId Identity(1,1),
                           Result    XML);

   declare @vRecordId        TRecordType,
           @vCount           TCount,
           @vImportedSKUCount TCount,
           @vRecordsCount    TCount,
           @MessageName      TDescription,
           @ReturnCode       TInteger,
           @xmlData          XML,
           @xmlResult        XML,
           @xmlImportSKUInfo XML;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @xmlData           = convert(xml, @SKUContents),
         @vImportedSKUCount = 0;

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return;

  /* Get the information from the xml and load into a temp table */
  if (@xmlData is not null)
    begin
      insert into @ttSKUs(
        Action, RecordType,
        SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Description,
        Status, UoM, Barcode, UPC, Brand,
        ProdCategory, ProdSubCategory,
        UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10,
        BusinessUnit, UserId, Processed)
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
        Record.Col.value('UDF9[1]', 'TUDF'), Record.Col.value('UDF10[1]', 'TUDF'),
        Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), Record.Col.value('UserId[1]', 'TUserId'),
        'N' /* Processed - No */
      from @xmlData.nodes('/ArrayOfSKUsToImport/SKUsToImport') as Record(Col);
    end

  select @vCount        = @@rowcount,
         @vRecordsCount = @@rowcount;

  if (@vCount = 0)
    begin
      set @MessageName  = 'NoRecordsFound';
      goto ErrorHandler;
    end

  /* begin Loop */
  while (@vCount > 0)
    begin
      select @vRecordId =(select top 1 recordId
                          from @ttSKUs
                          where Processed = 'N'/* No */);

      set @xmlImportSKUInfo = (select top 1 RecordType, Action,
                                            SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Description,
                                            Status, UoM, Barcode, UPC, Brand,
                                            ProdCategory, ProdSubCategory,
                                            UDF1, UDF2, UDF3, UDF4, UDF5,
                                            UDF6, UDF7, UDF8, UDF9, UDF10,
                                            BusinessUnit,
                                            current_timestamp as CreatedDate,
                                            current_timestamp as ModifiedDate,
                                            UserId, System_User as ModifiedBy
                               from @ttSKUs
                               where (Processed = 'N' /* No */ and RecordId = @vRecordId)
                               FOR XML RAW('Record'), ELEMENTS);

       begin try
         /* Call proceudre to import SKUs*/
         insert into @ttResult
           exec pr_Imports_ImportRecord @xmlImportSKUInfo;

         select top 1 @xmlResult = Result
         from @ttResult
         order by RecordId desc;

         if (@xmlResult is null)
           begin
             update @ttSKUs
             set ImportStatus = 'Imported' /* Yes */,
                 Result  = 'Successful',
                 Message = 'Successful',
                 Processed = 'Y' /* Yes */
             where (RecordId = @vRecordId);

             select @vImportedSKUCount = @vImportedSKUCount + 1;
           end
         else
           update @ttSKUs
           set ImportStatus = 'Not Imported',
               Result  = 'Failure',
               Message =  (select Record.Col.value('.', 'TDescription')
                           from @xmlResult.nodes('/Errors') as Record(Col)),
               Processed = 'Y' /* Yes */
           where (RecordId = @vRecordId);
       end try
       begin catch
         update @ttSKUs
         set ImportStatus = 'Not Imported',
             Result  = 'Failure',
             Message =  @@error,
             Processed = 'Y' /* Yes */
         where (RecordId = @vRecordId);
       end catch

       select @vCount = @vCount - 1;
    end

  /* Based upon the number of SKUs that have been Validated, give an appropriate message */
  if (@vImportedSKUCount = 0)
    set @Message = dbo.fn_Messages_GetDescription ('NoSKUsImported');
  else
  if (@vImportedSKUCount < @vRecordsCount  )
    set @Message = dbo.fn_Messages_GetDescription ('SomeSKUsImported');
  else
  if (@vImportedSKUCount = @vRecordsCount )
    set @Message = dbo.fn_Messages_GetDescription ('AllSKUsImported');

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Get Data from Temp table*/
  select * from @ttSKUs
  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch
end  /* pr_Imports_TemplateSKUs */

Go
