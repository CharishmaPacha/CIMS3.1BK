/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetSKUPrePacksToImport') is not null
  drop Procedure pr_Imports_DE_GetSKUPrePacksToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetSKUPrePacksToImport: This procedure will returns the xml which contains
    all un-processed records from ImportSKUPrePacks table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetSKUPrePacksToImport
  (@UserId          TUserId       = null,
   @BusinessUnit    TBusinessUnit = null,
   @Ownership       TOwnership    = null,
   @RecordsPerRun   TCount        = 500,
   @ResultRecordId  TRecordId     = null output)
as
  declare @vxmlSPPdata      xml,
          @xmlSPPs          xml,
          @vxmlHeader       TXML,
          @vReturnCode      TInteger;
begin
  SET NOCOUNT ON;

  /* Get all records from the table which are not yet processed */
  select @vxmlSPPdata = (select top (@RecordsPerRun) *,
                                                     MasterSKU + ComponentSKU as KeyData
                         from ImportSKUPrePacks
                         where (ExchangeStatus = 'N' /* Not yet processed */) and
                               (BusinessUnit   = @BusinessUnit)
                         order by RecordId
                         FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlSPPdata is null)
    goto Exithandler;

  /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlSPPdata = replace(cast(@vxmlSPPdata as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlSPPs = '<msg>'  +
                      coalesce(@vxmlHeader, '')  +
                      convert(varchar(max), @vxmlSPPdata) +
                    '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlSPPs), 'SPP';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetSKUPrePacksToImport */

Go
