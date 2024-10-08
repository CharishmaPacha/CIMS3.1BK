/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Imports_ValidateEntityType') is not null
  drop Function fn_Imports_ValidateEntityType;
Go
/*------------------------------------------------------------------------------
  Function fn_Imports_ValidateEntityType:
    Various fields on import have to be validated against the valid values (as
    defined in LookUps table). this is generic function used to do these validations.
------------------------------------------------------------------------------*/
Create Function fn_Imports_ValidateEntityType
  (
   @RecordType     TTypeCode,
   @Entity         TEntity,
   @EntityType     TTypeCode,
   @BusinessUnit   TBusinessUnit
 )
  ------------------------------
   returns         TXML
as
begin /* fn_Imports_ValidateEntityType */
  declare @vEntityTypeIsRequired TMessageName,
          @vEntityTypeIsInvalid  TMessageName,
          @vEntityTypeIsInactive TMessageName,
          @vValidationResult     TXML,
          @vEntityTypeStatus     TStatus,
          @vControlCategory      TCategory,
          @vControlCode          TControlCode;

  select @vEntityTypeIsRequired = 'Import_' + @Entity + 'TypeIsRequired',
         @vEntityTypeIsInvalid  = 'Import_' + @Entity + 'TypeIsInvalid',
         @vEntityTypeIsInactive = 'Import_' + @Entity + 'TypeIsInactive',
         @vControlCategory      = 'Import_' + @RecordType,
         @vControlCode          = @Entity + 'TypeIsRequired',
         @vValidationResult     = null;

  /* For the particular RecordType, if the EntityType is not given and is required raise the error */
  if (coalesce(@EntityType, '') = '') and
     (dbo.fn_Controls_GetAsString(@vControlCategory, @vControlCode,
                                  'N' /* Default: No */, @BusinessUnit, '' /* UserId */) = 'Y')
    set @vValidationResult = dbo.fn_Imports_AppendError(@vValidationResult, @vEntityTypeIsRequired, null);

  select @vEntityTypeStatus = Status
  from vwEntityTypes
  where (Entity       = @Entity) and
        (TypeCode     = @EntityType) and
        (BusinessUnit = @BusinessUnit);

  /* Check if the given EntityType exists and is active */
  if (@vEntityTypeStatus is null)
    set @vValidationResult = dbo.fn_Imports_AppendError(@vValidationResult, @vEntityTypeIsInvalid, @EntityType)
  else
  if (@vEntityTypeStatus <> 'A' /* Active */)
    set @vValidationResult = dbo.fn_Imports_AppendError(@vValidationResult, @vEntityTypeIsInactive, @EntityType)

  return (nullif(@vValidationResult, ''));
end /* fn_Imports_ValidateEntityType */

Go
