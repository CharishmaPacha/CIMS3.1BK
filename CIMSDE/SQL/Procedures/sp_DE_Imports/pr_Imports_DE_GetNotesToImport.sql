/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/11/29  TD      Added pr_Imports_DE_GetNotesToImport (CIMSDE-34).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetNotesToImport') is not null
  drop Procedure pr_Imports_DE_GetNotesToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetNotesToImport: This procedure will returns the xml
    which contains all un-processed records from ImportNotes.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetNotesToImport
  (@UserId                TUserId       = null,
   @BusinessUnit          TBusinessUnit = null,
   @Ownership             TOwnership    = null,
   @RecordsPerRun         TCount        = null,
   @ResultRecordId        TRecordId     = null output)
as
  declare @vxmlNotesData   xml,
          @xmlNotes        xml,
          @vxmlHeader      TXML,
          @vReturnCode     TInteger;
begin /* pr_Imports_DE_GetNotesToImport */
  SET NOCOUNT ON;

  /* Get all records from the table which are not yet processed */
  select @vxmlNotesData = (select top (@RecordsPerRun) *,
                                                       Note as KeyData
                           from ImportNotes
                           where (ExchangeStatus = 'N' /* Not yet processed */) and
                                 (BusinessUnit   = @BusinessUnit)
                           order by RecordId
                           FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlNotesData is null)
    goto Exithandler;

  /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlNotesData = replace(cast(@vxmlNotesData as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlNotes = '<msg>'  +
                       coalesce(@vxmlHeader, '')  +
                       convert(varchar(max), @vxmlNotesData) +
                     '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlNotes), 'NOTE';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetNotesToImport */

Go
