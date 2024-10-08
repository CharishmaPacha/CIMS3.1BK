/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetContactsToImport') is not null
  drop Procedure pr_Imports_DE_GetContactsToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetContactsToImport: This procedure will returns the xml
    which contains all un-processed records from ImportContacts table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetContactsToImport
  (@UserId                TUserId       = null,
   @BusinessUnit          TBusinessUnit = null,
   @Ownership             TOwnership    = null,
   @RecordsPerRun         TCount        = 500,
   @ResultRecordId        TRecordId     = null output)
as
  declare @vxmlContactsData   xml,
          @xmlContacts        xml,
          @vxmlHeader         TXML,
          @vReturnCode        TInteger;
begin
  SET NOCOUNT ON;

  /* Get all records from the table which are not yet processed */
  select @vxmlContactsData = (select top (@RecordsPerRun) *,
                                                          ContactId as KeyData
                              from ImportContacts
                              where (ExchangeStatus = 'N' /* Not yet processed */) and
                                    (BusinessUnit   = @BusinessUnit)
                              order by RecordId
                              FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlContactsData is null)
    goto Exithandler;

  /* At present we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlContactsData = replace(cast(@vxmlContactsData as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlContacts = '<msg>'  +
                           coalesce(@vxmlHeader, '')  +
                           convert(varchar(max), @vxmlContactsData) +
                        '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlContacts), 'CNT';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetContactsToImport */

Go
