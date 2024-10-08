/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  MS      pr_Imports_DE_GetASNLPNsToImport, pr_Imports_DE_GetASNLPNDetailsToImport: Process ASNLPNs only if RH is imported (JL-315)
  2019/02/28  YJ      pr_Imports_DE_GetASNLPNDetailsToImport: Using conversion (CID-136)(Ported from Staging)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetASNLPNDetailsToImport') is not null
  drop Procedure pr_Imports_DE_GetASNLPNDetailsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetASNLPNDetailsToImport: This procedure will returns the xml
    which contains all un-processed records from ImportASNLPNDetails table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetASNLPNDetailsToImport
  (@UserId                TUserId       = null,
   @BusinessUnit          TBusinessUnit = null,
   @Ownership             TOwnership    = null,
   @RecordsPerRun         TCount        = 500,
   @ResultRecordId        TRecordId     = null output)
as
  declare @vxmlASNLPNDsData   xml,
          @xmlASNLPNDs        xml,
          @vxmlHeader         TXML,
          @vReturnCode        TInteger;

  declare  @ttImportedASNLPNDetails  TEntityKeysTable;
begin
  SET NOCOUNT ON;


  /* Get distinct RecordIds from ImportedASNLPNDetails to process respective LPNDetails and
     avoid returning multiple duplicate records after joining with ASNL */
  insert into @ttImportedASNLPNDetails (EntityId)
    select distinct ALD.RecordId
    from ImportASNLPNDetails ALD
      join ImportASNLPNs AL on (ALD.LPN = AL.LPN) and (ALD.BusinessUnit = AL.BusinessUnit)
    where (ALD.ExchangeStatus = 'N' /* Not yet processed */) and
          (AL.ExchangeStatus  = 'Y' /* Processed */) and
          (ALD.BusinessUnit   = @BusinessUnit);

  /* Get all records from the table which are not yet processed */
  select @vxmlASNLPNDsData = (select top (@RecordsPerRun) ASLD.*,
                                                          ASLD.LPN + ASLD.SKU + convert(varchar(15), (coalesce(ASLD.ReceiptLine, ''))) as KeyData
                              from @ttImportedASNLPNDetails  ttAL
                                join ImportASNLPNDetails     ASLD on (ttAL.EntityId = ASLD.RecordId)
                              order by ASLD.RecordId
                              FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlASNLPNDsData is null)
    goto Exithandler;

  /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlASNLPNDsData = replace(cast(@vxmlASNLPNDsData as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlASNLPNDs = '<msg>'  +
                           coalesce(@vxmlHeader, '')  +
                           convert(varchar(max), @vxmlASNLPNDsData) +
                        '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlASNLPNDs), 'ASNLD';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetASNLPNDetailsToImport */

Go
