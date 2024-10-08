/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/19  TK      pr_Imports_DE_GetInvAdjustmentsToImport: Initial Revision (HA-2341)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetInvAdjustmentsToImport') is not null
  drop Procedure pr_Imports_DE_GetInvAdjustmentsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetInvAdjustmentsToImport: This procedure will returns the xml
    which contains all un-processed records from ImportInvAdjustments table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetInvAdjustmentsToImport
  (@UserId                TUserId       = null,
   @BusinessUnit          TBusinessUnit = null,
   @Ownership             TOwnership    = null,
   @RecordsPerRun         TCount        = 500,
   @ResultRecordId        TRecordId     = null output)
as
  declare @vXmlInvAdjData       xml,
          @vInvAdjustmentsXml   TXML,
          @vXmlHeader           TXML,
          @vReturnCode          TInteger;
begin
  SET NOCOUNT ON;

  /* Get all records from the table which are not yet processed */
  select @vXmlInvAdjData = (select top (@RecordsPerRun) *,
                                                        RecordId as KeyData
                            from ImportInvAdjustments
                            where (ExchangeStatus = 'N' /* Not yet processed */) and
                                  (BusinessUnit   = @BusinessUnit) and
                                  (RecordType = 'TRFINV')
                            order by RecordId
                            FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vXmlInvAdjData is null)
    goto Exithandler;

  /* Build the xml header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @XmlHeader = @vXmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @vInvAdjustmentsXml = dbo.fn_XMLNode('msg',
                                 coalesce(@vXmlHeader, '')  +
                                 convert(varchar(max), @vXmlInvAdjData));

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select @vInvAdjustmentsXml, 'Inv';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetInvAdjustmentsToImport */

Go
