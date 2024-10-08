/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_DE_GetCartonTypesToImport') is not null
  drop Procedure pr_Imports_DE_GetCartonTypesToImport;
Go
/*------------------------------------------------------------------------------
  pr_Imports_DE_GetCartonTypesToImport: This procedure will returns the xml
    which contains all un-processed records form ImportCartonTypes table.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_DE_GetCartonTypesToImport
  (@UserId                TUserId       = null,
   @BusinessUnit          TBusinessUnit = null,
   @Ownership             TOwnership    = null,
   @RecordsPerRun         TCount        = 500,
   @ResultRecordId        TRecordId     = null output)
as
  declare @vxmlCartonTypesData   xml,
          @xmlCartonTypes        xml,
          @vxmlHeader            TXML,
          @vReturnCode           TInteger;
begin
  SET NOCOUNT ON;

  /* Get all records from the table which are not yet processed */
  select @vxmlCartonTypesData = (select top (@RecordsPerRun) *,
                                                             CartonType as KeyData
                                 from ImportCartonTypes
                                 where (ExchangeStatus = 'N' /* Not yet processed */) and
                                       (BusinessUnit   = @BusinessUnit)
                                 order by RecordId
                                 FOR XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  if (@vxmlCartonTypesData is null)
    goto Exithandler;

  /* Atpresent we are getting Action as RecordAction as this was defined in Domains,
    so need to replace the RecordAction with Action */
  select @vxmlCartonTypesData = replace(cast(@vxmlCartonTypesData as varchar(max)), 'RecordAction', 'Action');

  /* Build the xml Import header - this procedure will build header with the data like
     source and target systems and other necessary data like reference etc  */
  exec pr_Imports_DE_GetXMLHeader @xmlHeader = @vxmlHeader output;

  /* Concatenate the xmlHeader and the Record set to form the final message to send to CIMS */
  select @xmlCartonTypes = '<msg>'  +
                              coalesce(@vxmlHeader, '')  +
                              convert(varchar(max), @vxmlCartonTypesData) +
                           '</msg>';

  /* insert the xml result into importresult table to retreive and update it in CIMS */
  insert into ImportResults(Result, Entity)
    select convert(varchar(max), @xmlCartonTypes), 'CTP';

  /* Get the scope identiry here i.e the record which was created from the above
     insert operation */
  select @ResultRecordId = SCOPE_IDENTITY();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_DE_GetCartonTypesToImport */

Go
