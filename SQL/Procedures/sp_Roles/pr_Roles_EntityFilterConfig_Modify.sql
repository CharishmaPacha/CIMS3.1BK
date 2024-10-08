/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/27  RV      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Roles_EntityFilterConfig_Modify') is not null
  drop Procedure pr_Roles_EntityFilterConfig_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Roles_EntityFilterConfig_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_Roles_EntityFilterConfig_Modify
  (@EntityFilterConfig    XML,
   @UserId                TUserId,
   @BusinessUnit          varchar(10),
   @Message               TXML output)
as
  declare @vEntity                TEntity  = 'Role',
          @ReturnCode             TInteger,
          @MessageName            TMessageName,

          @vRoleName              TName,
          @vEntityFilterConfigxml XML;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  select @vRoleName           = Record.Col.value('RoleName[1]', 'TName')
    from @EntityFilterConfig.nodes('/Root') as Record(Col);

  select @vEntityFilterConfigxml = @EntityFilterConfig.query('/*/*/*[local-name()=("EntityFilters")]')


  /* Validations */
  if (coalesce(@vRoleName, '') = '')
    set @MessageName = 'RoleNameIsInvalid';
  else
  if (coalesce(@UserId, '') = '')
    set @MessageName = 'UserIdInvalid';
  else
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  update Roles
  set  EntityFilterConfig = cast(@vEntityFilterConfigxml as varchar(max))
  where (RoleName = @vRoleName);

  if (@@rowcount > 0)
    select @Message = 'Role_EntityFilterConfig_UpdatedSuccessful';
  else
    select @MessageName = 'Role_DoesNotExist';

  exec @Message = dbo.fn_Messages_Build @Message;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Roles_EntityFilterConfig_Modify */

Go
