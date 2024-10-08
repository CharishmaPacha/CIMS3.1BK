/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/31  AY      Completed NY's changes, code simplification
                      pr_Imports_ValidateEntityTypes: New procedure introduced.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateEntityType') is not null
  drop Procedure pr_Imports_ValidateEntityType;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateEntityType: Various entities on import have to be validated
    against the valid types (as defined in EntityTypes table. this is generic
    procedure used to do such validations.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateEntityType
  (@Entity    TEntity,
   @TypeCode  TTypeCode)
as
  declare @vEntityTypeIsRequired TMessageName,
          @vEntityTypeIsInvalid  TMessageName;
begin
  select @vEntityTypeIsRequired = @Entity + 'TypeIsRequired',
         @vEntityTypeIsInvalid  = @Entity + 'TypeIsInvalid';

  if (coalesce(@TypeCode, '') = '')
    exec pr_Imports_LogError @vEntityTypeIsRequired;
  else
  if (not exists (select *
                  from EntityTypes
                  where (Entity   = @Entity) and
                        (TypeCode = @TypeCode) and
                        (Status   = 'A' /* Active */)))
    exec pr_Imports_LogError @vEntityTypeIsInvalid;
end /* pr_Imports_ValidateEntityType */

Go
