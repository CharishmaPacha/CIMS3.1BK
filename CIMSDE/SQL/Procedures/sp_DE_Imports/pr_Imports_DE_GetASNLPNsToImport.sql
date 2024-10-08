/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  MS      pr_Imports_DE_GetASNLPNsToImport, pr_Imports_DE_GetASNLPNDetailsToImport: Process ASNLPNs only if RH is imported (JL-315)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetASNLPNsToImport') is not null
  drop Procedure pr_Imports_DE_GetASNLPNsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetASNLPNsToImport: This procedure will returns the xml
    which contains all un-processed records from ImportASNLPNs table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetASNLPNsToImport
  (@UserId               TUserId       = null,
   @BusinessUnit         TBusinessUnit = null,
   @Ownership            TOwnership    = null,
   @RecordsPerRun        TCount        = 500,
   @ResultRecordId       TRecordId     = null output)
as
  declare @vxmlASNLPNsData  xml,
          @xmlASNLPNs       xml,
          @vxmlHeader       TXML,
          @vReturnCode      TInteger;

  declare  @ttImportedASNLPNs  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Get distinct RecordIds from ImportedASNLPNs to process respective LPNs and
     avoid returning multiple duplicate records after joining with RH */
  insert into @ttImportedASNLPNs (EntityId)
    select distinct AL.RecordId
    from ImportASNLPNs AL
      join ImportReceiptHeaders RH on (AL.ReceiptNumber = RH.ReceiptNumber) and (AL.BusinessUnit = RH.BusinessUnit)
    where (AL.ExchangeStatus = 'N' /* Not yet processed */) and
          (RH.ExchangeStatus = 'Y' /* Processed */) and
          (AL.BusinessUnit   = @BusinessUnit);

  /* Get all records from the table which are not yet processed */
  select @vxmlASNLPNsData = (select top (@RecordsPerRun) ASL.*,
                                                         ASL.LPN as KeyData
                             from @ttImportedASNLPNs  ttAL
                               join ImportASNLPNs     ASL on (ttAL.EntityId = ASL.RecordId)
                             order by ASL.RecordId
                             FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlASNLPNsData is null)
    goto Exithandler;

  /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlASNLPNsData = replace(cast(@vxmlASNLPNsData as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlASNLPNs = '<msg>'  +
                          coalesce(@vxmlHeader, '')  +
                          convert(varchar(max), @vxmlASNLPNsData) +
                       '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlASNLPNs), 'ASNLH';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetASNLPNsToImport */

Go
