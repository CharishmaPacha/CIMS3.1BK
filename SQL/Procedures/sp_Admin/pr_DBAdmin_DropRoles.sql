/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DBAdmin_DropRoles') is not null
  drop Procedure pr_DBAdmin_DropRoles;
Go
/*------------------------------------------------------------------------------
  Proc pr_DBAdmin_DropRoles:

    This is executed to drop the pre defined roles
------------------------------------------------------------------------------*/
Create Procedure pr_DBAdmin_DropRoles
  (@Role     TName,
   @Confirm  TBinary = 0)
as
  /* Declare local variables */
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vRecordId      TRecordId,

          @vsql           TSQL,
          @vdbname        TName,
          @vMember        TName;

  declare @ttRoleMembers Table (Name     TVarchar,
                                RecordId TRecordId identity(1,1));

begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vdbname      = db_name(),
         @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  /* Switch to the database given or being run */
  select @vsql = 'use '+@vdbname+';'
  exec(@vsql);

  /* Validations */
  if (IS_ROLEMEMBER('db_owner') <> 1) and (IS_SRVROLEMEMBER('sysadmin') <> 1)
    set @vMessageName = 'NoAuthorizationToRun';
  else
  if (@Confirm = 0)
    set @vMessageName = 'PleasePassOnConfirmBinaryDigit';
  else
  if (@vdbname in ('msdb', 'master', 'tempdb', 'model'))
    set @vMessageName = 'CannotRunOnSystemDBs';
  else
  if (@Role is null)
    set @vMessageName = 'RoleIsNotProvided';
  else
  if (@Role not in ('cimsro', 'cimsint', 'cimsapp'))
    set @vMessageName = 'Available Roles are: cimsro, cimsint, cimsapp only';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Find all role members */
  insert into @ttRoleMembers (Name)
    select name
    from sys.database_principals
    where principal_id in (select member_principal_id
                           from sys.database_role_members
                           where role_principal_id in (select principal_id
                                                       from sys.database_principals
                                                       where name = @Role and type = 'R' /* DATABASE_ROLE */));

  /* Drop all members from the Role */
  while (exists(select * from @ttRoleMembers where RecordId > @vRecordId))
    begin
      select top 1 @vMember   = Name,
                   @vRecordId = RecordId
      from @ttRoleMembers
      where RecordId > @vRecordId

      select @vsql = 'alter role ['+@Role+'] drop member ['+@vMember+']';
      exec(@vsql);
    end

  /* Drop Role */
  select @vsql = 'drop role ['+@Role+']';
  exec(@vsql);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_DBAdmin_DropRoles */

Go
