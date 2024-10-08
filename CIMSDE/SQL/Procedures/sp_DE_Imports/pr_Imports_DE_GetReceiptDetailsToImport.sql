/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/29  VS      pr_Imports_DE_GetReceiptDetailsToImport: KeyData should not be null if HostReceiptLine is null (HA-3014)
  pr_Imports_DE_GetReceiptDetailsToImport: changes to handle duplicate RH records (HA-2417)
  2021/01/21  VS      pr_Imports_DE_GetOrderDetailsToImport, pr_Imports_DE_GetReceiptDetailsToImport:
  2019/04/25  VS      pr_Imports_DE_GetReceiptDetailsToImport: Import the ReceiptDetails when respective ReceiptHeaders are imported (HPI-2596)
  Added pr_Imports_DE_GetReceiptDetailsToImport (CIMSDE-18)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetReceiptDetailsToImport') is not null
  drop Procedure pr_Imports_DE_GetReceiptDetailsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetReceiptDetailsToImport: This procedure will returns the xml
    which contains all un-processed records from ImportReceiptDetailstable.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetReceiptDetailsToImport
  (@UserId                TUserId       = null,
   @BusinessUnit          TBusinessUnit = null,
   @Ownership             TOwnership    = null,
   @RecordsPerRun         TCount        = null,
   @ResultRecordId        TRecordId     = null output)
as
  declare @vxmlRDData                xml,
          @xmlReceiptDetails         xml,
          @vxmlHeader                TXML,
          @vReturnCode               TInteger;

 declare  @ttImportedReceiptHeaders  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Get distinct PickTickets from ImportReceiptHeaders to process respective Receipt detail lines and
     avoid returning multiple duplicate records after joining with RFH */
  insert into @ttImportedReceiptHeaders (EntityKey)
    select distinct IRH.ReceiptNumber
    from ImportReceiptHeaders IRH
      join ImportReceiptDetails  IRD on (IRH.ReceiptNumber  = IRD.ReceiptNumber) and
                                        (IRH.BusinessUnit   = IRD.BusinessUnit)
    where (IRD.ExchangeStatus = 'N' /* Not yet processed */) and
          (IRH.ExchangeStatus = 'Y' /* Processed Records */) and
          (IRD.BusinessUnit   = @BusinessUnit)

  /* Get all records from the table which are not yet processed */
  select @vxmlRDData = (select top (@RecordsPerRun) IRD.*,
                                                    concat_ws('', IRD.ReceiptNumber, IRD.SKU, IRD.HostReceiptLine) as KeyData
                        from @ttImportedReceiptHeaders  ttRTP
                          join ImportReceiptDetails      IRD   on (ttRTP.EntityKey = IRD.ReceiptNumber)
                        where (IRD.ExchangeStatus = 'N' /* Not yet processed */) and
                              (IRD.BusinessUnit   = @BusinessUnit)
                        order by IRD.RecordId
                        FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlRDData is null)
    goto Exithandler;

  /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlRDData = replace(cast(@vxmlRDData as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlReceiptDetails = '<msg>'  +
                                coalesce(@vxmlHeader, '')  +
                                convert(varchar(max), @vxmlRDData) +
                              '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlReceiptDetails), 'RD';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetReceiptDetailsToImport */

Go
