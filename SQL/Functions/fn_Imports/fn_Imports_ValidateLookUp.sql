/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/07  AY      fn_Imports_ValidateLookUp: Change to use Lookups as vwLookUps checks if LookUp category is active (JL-93)
  2014/12/02  NB      Added functions fn_Imports_ValidateLookUp and fn_Imports_ValidateInputData
                      Modified pr_Imports_ValidateSKU to use new functions for Code optimization
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Imports_ValidateLookUp') is not null
  drop Function fn_Imports_ValidateLookUp;
Go
/*------------------------------------------------------------------------------
  Function fn_Imports_ValidateLookUp:
    Various fields on import have to be validated against the valid values (as
    defined in LookUps table). this is generic function used to do these validations.
------------------------------------------------------------------------------*/
Create Function fn_Imports_ValidateLookUp
  (
   @LookUpCategory  TCategory,
   @LookUpCode      TLookupCode
   )
  -----------------------------
   returns          TXML
as
begin /* fn_Imports_ValidateLookUp */
  declare @vLookUpIsRequired TMessageName,
          @vLookUpIsInvalid  TMessageName,
          @vValidationResult TXML;

  select @vLookUpIsRequired = 'Import_' + @LookUpCategory + 'IsRequired',
         @vLookUpIsInvalid  = 'Import_' + @LookUpCategory + 'IsInvalid',
         @vValidationResult = null;

  if (coalesce(@LookUpCode, '') = '')
    set @vValidationResult = dbo.fn_Imports_AppendError(@vValidationResult, @vLookUpIsRequired, null)
  else
  if (not exists (select *
                  from LookUps
                  where (LookUpCategory = @LookUpCategory) and
                        (LookUpCode     = @LookupCode) and
                        (Status         = 'A' /* Active */)))
    set @vValidationResult = dbo.fn_Imports_AppendError(@vValidationResult, @vLookUpIsInvalid, @LookUpCode)

  return (nullif(@vValidationResult, ''));
end /* fn_Imports_ValidateLookUp */

Go
