/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/07/12  PK      Created pr_Imports_Contacts, pr_Imports_ValidateContact.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateContact') is not null
  drop Procedure pr_Imports_ValidateContact;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateContact:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateContact
  (@Action        TFlag output,
   @ContactRefId  TContactRefId,
   @ContactType   TContactType,
   @BusinessUnit  TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vName         TName,
          @vContactId    TRecordId,
          @vContactType  TContactType,
          @vContactRefId TContactRefId,
          @vBusinessUnit TBusinessUnit;
begin
  set @vReturnCode = 0;

  exec @vReturnCode = pr_Imports_ValidateInputData @BusinessUnit;

  exec @vReturnCode = pr_Imports_ValidateEntityType 'Contact', @ContactType;

  select @vName      = Name,
         @vContactId = ContactId
  from Contacts
  where (ContactRefId = @ContactRefId) and
        (ContactType  = @ContactType) and
        (Businessunit = @BusinessUnit);

  /* If the user trying to insert an existing record into the db or
                 trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */
  select @Action = dbo.fn_Imports_ResolveAction('CNT', @Action, @vName, @BusinessUnit, null /* UserId */);

  if (@Action = 'X'/* Invalid action */)
    exec pr_Imports_LogError 'Import_InvalidAction';

  if (coalesce(@ContactRefId, '') = '')
    exec pr_Imports_LogError 'ContactIsRequired';

  if (@Action = 'E'/* Error */) and
     (@vContactId is not null)
    exec pr_Imports_LogError 'ContactAlreadyExists';
  else
  if (@Action = 'E' /* Error */) and
     (@vContactId is null)
    exec pr_Imports_LogError 'ContactDoesNotExist';

  /* If any errors were recorded, then set return code appropriately */
  if exists(select * from #Errors)
    set @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateContact */

Go
