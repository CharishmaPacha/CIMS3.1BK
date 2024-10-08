/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/24  VS      pr_Imports_DE_GetOrderHeadersToImport, pr_Imports_DE_GetOrderDetailsToImport: Get the records Batchwise (CIMSV3-1604)
  2021/09/22  OK      pr_Imports_DE_GetOrderDetailsToImport, pr_Imports_DE_GetOrderHeadersToImport:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetOrderHeadersToImport') is not null
  drop Procedure pr_Imports_DE_GetOrderHeadersToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetOrderHeadersToImport: This procedure will returns the xml
    which contains all un-processed records from ImportOrderHeaders table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetOrderHeadersToImport
  (@UserId             TUserId       = null,
   @BusinessUnit       TBusinessUnit = null,
   @Ownership          TOwnership    = null,
   @RecordsPerRun      TCount        = 500,
   @ImportBatch        TBatch        = null,
   @IsDESameServer     TFlag         = null,
   @ResultRecordId     TRecordId     = null output)
as
  declare @vxmlOHData      xml,
          @xmlOrderHeaders xml,
          @vxmlHeader      TXML,
          @vReturnCode     TInteger;
begin
  SET NOCOUNT ON;

  /* If no batch is given, get the next available batch to import */
  if (@ImportBatch is null)
    select top 1 @ImportBatch = ImportBatch
    from ImportOrderHeaders
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
      select *, PickTicket as KeyData
      into ##ImportOrderHeaders
      from ImportOrderHeaders
      where (ImportBatch    = @ImportBatch) and
            (ExchangeStatus = 'N' /* Not yet processed */) and
            (BusinessUnit   = @BusinessUnit)
      order by ImportBatch;

      /* insert the xml result into importresult table to retreive and update it in CIMS */
      insert into ImportResults(Result, Entity)
        select @ImportBatch, 'OrderHeader';

      select @ResultRecordId = SCOPE_IDENTITY();
    end
  else
    begin
      /* Get all records from the table which are not yet processed */
      select @vxmlOHData = (select top (@RecordsPerRun) *, PickTicket as KeyData
                            from ImportOrderHeaders
                            where (ImportBatch    = @ImportBatch) and
                                  (ExchangeStatus = 'N' /* Not yet processed */) and
                                  (BusinessUnit   = @BusinessUnit)
                            order by RecordId
                            FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

      if (@vxmlOHData is null)
        goto Exithandler;

      /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
         so need to replace the RecordAction with Action */
      select @vxmlOHData = replace(cast(@vxmlOHData as varchar(max)), 'RecordAction', 'Action');

      /* Build the xml Import header - this procedure will build header with the data like
         source and target systems and other necessary data  */
      exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

      /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
      select @xmlOrderHeaders = '<msg>'  +
                                   coalesce(@vxmlHeader, '')  +
                                   convert(varchar(max), @vxmlOHData) +
                                '</msg>';

      /* insert the xml result into importresult table to retreive and update it in CIMS */
      insert into ImportResults(Result, Entity)
        select convert(varchar(max), @xmlOrderHeaders), 'OH';

      /* Get the scope identiry here i.e the record which was created from the above
         insert operation */
      select @ResultRecordId = SCOPE_IDENTITY();
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetOrderHeadersToImport */

Go
