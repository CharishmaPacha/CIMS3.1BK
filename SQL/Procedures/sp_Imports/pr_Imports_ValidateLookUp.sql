/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/05/19  AY      pr_Imports_OrderHeaders: Added Warehouse
                      Validation procedures: corrected messages, indentation.
                      pr_Imports_LogError, pr_Imports_ValidateLookUp, pr_Imports_ValidateInputdata:
                        New procedures added for code refactoring
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateLookUp') is not null
  drop Procedure pr_Imports_ValidateLookUp;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateLookUp: Various fields on import have to be validated
    against the valid values (as defined in LookUps table. this is generic
    procedure used to do these validations.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateLookUp
  (@LookUpCategory  TCategory,
   @LookUpCode      TLookupCode)
as
  declare @vLookUpIsRequired TMessageName,
          @vLookUpIsInvalid  TMessageName;
begin
  select @vLookUpIsRequired = @LookUpCategory + 'IsRequired',
         @vLookUpIsInvalid  = @LookUpCategory + 'IsInvalid';

  if (coalesce(@LookUpCode, '') = '')
    exec pr_Imports_LogError @vLookUpIsRequired;
  else
  if (not exists (select *
                  from vwLookUps
                  where (LookUpCategory = @LookUpCategory) and
                        (LookUpCode     = @LookupCode)))
    exec pr_Imports_LogError @vLookUpIsInvalid;
end /* pr_Imports_ValidateLookUp */

Go
