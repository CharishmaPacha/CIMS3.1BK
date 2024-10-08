/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateNotes') is not null
  drop Procedure pr_Imports_ValidateNotes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateNotes: Accepts the NoteImports table type with NOTE records
    to validate returns the validation results in a dataset of ImportValidationsType

  Only validation done is on RecordAction
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateNotes
  (@NotesToImport  TNoteImportType READONLY)
as
  declare @vReturnCode   TInteger;

  declare @NoteValidations TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Insert key information in SKU validations table */
  insert into @NoteValidations(RecordId, EntityId, EntityKey, RecordType, KeyData, InputXML, BusinessUnit,
                              RecordAction, HostRecId)
    select N.RecordId, N.EntityId, N.EntityKey, N.RecordType, N.NoteType, convert(nvarchar(max), N.InputXML), N.BusinessUnit,
           dbo.fn_Imports_ResolveAction('NOTE', N.RecordAction, N.EntityId, N.BusinessUnit, null /* UserId */), N.HostRecId
    from @NotesToImport N;

  /* If action itself was invalid, then report accordingly */
  update N
  set N.RecordAction = 'E' /* Error */,
      N.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', N.EntityKey)
  from @NoteValidations N
  where (N.RecordAction = 'X' /* Invalid Action */);

  /* Update RecordAction when there are errors */
  update @NoteValidations
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  select * from @NoteValidations order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateNotes */

Go
