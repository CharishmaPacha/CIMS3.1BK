/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/16  VS      pr_Imports_DE_GetSKUsToImport, pr_ImportDE_CreateBatchesForImportRecords: Import process changed to New process by using ##Tables (HA-3084)
  2018/02/19  TD      pr_Imports_DE_GetSKUsToImport,pr_Imports_DE_ACKImportedRecords:
  2017/01/05  AY/TD   pr_Imports_DE_GetSKUsToImport: Changed to pass KeyData column to
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetSKUsToImport') is not null
  drop Procedure pr_Imports_DE_GetSKUsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetSKUsToImport: This procedure will returns the SKUs to be
    imported into CIMS for the given batch. If no batch is given, then the next
    available batch is selected. Based upon IsDESameServer either the data
    is returned in ##ImportSKUs or as XML in ImportResults. In both cases, the
    ImportResults.RecordId is returned which has the Batchno or the XML data.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetSKUsToImport
  (@UserId             TUserId       = null,
   @BusinessUnit       TBusinessUnit = null,
   @Ownership          TOwnership    = null,
   @RecordsPerRun      TCount        = 500,
   @ImportBatch        TBatch        = null,
   @IsDESameServer     TFlag         = null,
   @ResultRecordId     TRecordId     = null output)
as
  declare @vxmlSKUdata      xml,
          @vxmlHeader       TXML,
          @xmlSKUs          xml,
          @vImportRsltRecId TRecordId,
          @vReturnCode      TInteger;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @BusinessUnit    = coalesce(@BusinessUnit, 'CIMS');

  /* IF no batch is given, get the next available batch to import */
  if (@ImportBatch is null)
    select top 1 @ImportBatch = ImportBatch
    from ImportSKUs
    where (ImportBatch    > 0) and
          (ExchangeStatus = 'N' /* Not yet processed */) and
          (BusinessUnit   = @BusinessUnit)
    order by ImportBatch;

  /* If there are no Batches to process then go to Exithandler */
    if (@ImportBatch is null)
      goto Exithandler;

  /* If we are transferring data thru ## table then load the batch into ##ImportSKUs */
  if (@IsDESameServer = 'Y')
    begin
      select *, SKU as KeyData
      into ##ImportSKUs
      from ImportSKUs
      where (ImportBatch    = @ImportBatch) and
            (ExchangeStatus = 'N' /* Not yet processed */) and
            (BusinessUnit   = @BusinessUnit)
      order by RecordId;

      /* insert the xml result into importresult table to retreive and update it in CIMS */
      insert into ImportResults(Result, Entity)
        select @ImportBatch, 'SKU';

      select @ResultRecordId = SCOPE_IDENTITY();
    end
  else
    begin
      /* Get all records from the table which are not yet processed */
      select @vxmlSKUdata = (select top (@RecordsPerRun) *,
                                                       SKU as KeyData
                             from ImportSKUs
                             where (ImportBatch    = @ImportBatch) and
                                   (ExchangeStatus = 'N' /* Not yet processed */) and
                                   (BusinessUnit   = @BusinessUnit)
                             order by RecordId
                             FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

      /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
        so need to replace the RecordAction with Action */
      select @vxmlSKUdata = replace(cast(@vxmlSKUdata as varchar(max)), 'RecordAction', 'Action');

      /* Build the xml Import header - this procedure will build header with the data like
         source and target systems and other necessary data  */
      exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

      /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
      select @xmlSKUs = '<msg>'  +
                          coalesce(@vxmlHeader, '')  +
                          convert(varchar(max), @vxmlSKUdata) +
                        '</msg>';

      /* insert the xml result into importresult table to retreive and update it in CIMS */
      insert into ImportResults(Result, Entity)
        select convert(varchar(max), @xmlSKUs), 'SKU';

      select @ResultRecordId = SCOPE_IDENTITY();
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetSKUsToImport */

Go
