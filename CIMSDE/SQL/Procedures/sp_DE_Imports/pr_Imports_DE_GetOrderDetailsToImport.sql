/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/24  VS      pr_Imports_DE_GetOrderHeadersToImport, pr_Imports_DE_GetOrderDetailsToImport: Get the records Batchwise (CIMSV3-1604)
  2021/09/22  OK      pr_Imports_DE_GetOrderDetailsToImport, pr_Imports_DE_GetOrderHeadersToImport:
  2021/07/29  VS      pr_Imports_DE_GetOrderDetailsToImport:KeyData should not be null if HostOrderLine is null (HA-2491)
  2021/03/30  RKC     pr_Imports_DE_GetOrderDetailsToImport: Made changes to handle duplicate OH records sent
  2021/01/21  VS      pr_Imports_DE_GetOrderDetailsToImport, pr_Imports_DE_GetReceiptDetailsToImport:
  2019/04/25  VS      pr_Imports_DE_GetOrderDetailsToImport: Import the OrderDetails when respective OrderHeaders are imported (HPI-2589)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetOrderDetailsToImport') is not null
  drop Procedure pr_Imports_DE_GetOrderDetailsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetOrderDetailsToImport: This procedure will returns the xml
    which contains all un-processed records from ImportOrderDetails table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetOrderDetailsToImport
  (@UserId             TUserId       = null,
   @BusinessUnit       TBusinessUnit = null,
   @Ownership          TOwnership    = null,
   @RecordsPerRun      TCount        = 500,
   @ImportBatch        TBatch        = null,
   @IsDESameServer     TFlag         = null,
   @ResultRecordId     TRecordId     = null output)
as
  declare @vxmlODData              xml,
          @vxmlHeader              TXML,
          @xmlOrderDetails         xml,
          @vReturnCode             TInteger;

 declare  @ttImportedOrderHeaders  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Get distinct PickTickets from ImportOrderHeaders to process respective Order detail lines and
     avoid returning multiple duplicate records after joining with OH */
  insert into @ttImportedOrderHeaders (EntityKey)
    select distinct IOH.PickTicket
    from ImportOrderHeaders IOH
      join ImportOrderDetails  IOD on  (IOH.PickTicket   = IOD.PickTicket) and
                                       (IOH.BusinessUnit = IOD.BusinessUnit)
    where (IOD.ExchangeStatus = 'N' /* Not yet processed */) and
          (IOH.ExchangeStatus = 'Y' /* Processed Records */) and
          (IOD.BusinessUnit   = @BusinessUnit);

  /* IF no batch is given, get the next available batch to import */
  if (@ImportBatch is null)
    select top 1 @ImportBatch = IOD.ImportBatch
    from ImportOrderHeaders IOH
      join ImportOrderDetails  IOD on  (IOH.PickTicket   = IOD.PickTicket) and
                                       (IOH.BusinessUnit = IOD.BusinessUnit)
    where (IOD.ImportBatch    > 0) and
          (IOD.ExchangeStatus = 'N' /* Not yet processed */) and
          (IOH.ExchangeStatus = 'Y' /* Processed Records */) and
          (IOD.BusinessUnit   = @BusinessUnit)
    order by IOD.ImportBatch;

  /* If there is no Batch to process then go to existhandler */
  if (@ImportBatch is null) goto ExitHandler;

  /* If we are transferring data thru ## table then load the batch into ##ImportOrderDetails */
  if (@IsDESameServer = 'Y')
    begin
      select IOD.*, concat_ws('', IOD.PickTicket, IOD.HostOrderLine, IOD.SKU) as KeyData
      into ##ImportOrderDetails
      from @ttImportedOrderHeaders ttOH
        join ImportOrderDetails IOD on ttOH.EntityKey = IOD.PickTicket
      where (IOD.ImportBatch    = @ImportBatch) and
            (IOD.ExchangeStatus = 'N' /* Not yet processed */) and
            (IOD.BusinessUnit   = @BusinessUnit)
      order by IOD.ImportBatch

      /* insert the xml result into importresult table to retreive and update it in CIMS */
      insert into ImportResults(Result, Entity)
        select @ImportBatch, 'OrderDetail';

      select @ResultRecordId = SCOPE_IDENTITY();
    end
  else
    begin
      /* Get all records from the table which are not yet processed */
      select @vxmlODData = (select top (@RecordsPerRun) IOD.*,
                                                        concat_ws('', IOD.PickTicket, IOD.HostOrderLine, IOD.SKU) as KeyData
                            from @ttImportedOrderHeaders ttOH
                              join ImportOrderDetails IOD on ttOH.EntityKey = IOD.PickTicket
                            where (IOD.ImportBatch    = @ImportBatch) and
                                  (IOD.ExchangeStatus = 'N' /* Not yet processed */) and
                                  (IOD.BusinessUnit   = @BusinessUnit)
                            order by IOD.RecordId
                            FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

      if (@vxmlODData is null)
        goto Exithandler;

      /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
        so need to replace the RecordAction with Action */
      select @vxmlODData = replace(cast(@vxmlODData as varchar(max)), 'RecordAction', 'Action');

      /* Build the xml Import header - this procedure will build header with the data like
         source and target systems and other necessary data  */
      exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

      /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
      select @xmlOrderDetails = '<msg>'  +
                                  coalesce(@vxmlHeader, '')  +
                                  convert(varchar(max), @vxmlODData) +
                                '</msg>';

      /* insert the xml result into importresult table to retreive and update it in CIMS */
      insert into ImportResults(Result, Entity)
        select convert(varchar(max), @xmlOrderDetails), 'OD';

      /* Get the scope identiry here i.e the record which was created from the above
         insert operation */
      select @ResultRecordId = SCOPE_IDENTITY();
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetOrderDetailsToImport */

Go
