/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/20  SK         pr_DBAdmin_AddUser: replace : to - in the passcode string (JLCA-333)
                         pr_DBAdmin_AddUser: Create a random password (CIMSV3-1563)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DBAdmin_AddUser') is not null
  drop Procedure pr_DBAdmin_AddUser;
Go
/*------------------------------------------------------------------------------
  Proc pr_DBAdmin_AddUser:

    This is executed to add a given user and its associated login

    Steps to create DB roles
    This involves two steps:
      a) Create Login
      b) Create User from the Login
      c) Associate this User to one of the pre-defined roles
------------------------------------------------------------------------------*/
Create Procedure pr_DBAdmin_AddUser
  (@User     TName,
   @Role     TName,
   @PassCode nvarchar(1024) = null)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TVarChar,
          @vRecordId       TRecordId,

          @vPassCodeLength int,
          @vPassCode       varchar(20),
          @vsql            TSQL,
          @vdbname         TName,
          @vResult         varchar(2);

begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vdbname         = db_name(),
         @vReturnCode     = 0,
         @vRecordId       = 0,
         @vMessageName    = null,
         @vPassCodeLength = 8,
         @vResult         = 'N' /* No */;

  /* Validations */
  if (IS_ROLEMEMBER('db_owner') <> 1) and (IS_SRVROLEMEMBER('sysadmin') <> 1)
    set @vMessageName = 'NoAuthorizationToRun';
  else
  if (@vdbname in ('msdb', 'master', 'tempdb', 'model'))
    set @vMessageName = 'CannotRunOnSystemDBs';
  else
  if (@User is null)
    set @vMessageName = 'UsernameIsNotProvided';
  else
  if (@Role is null)
    set @vMessageName = 'RoleIsNotProvided';
  else
  if (@Role not in ('cimsro', 'cimsint', 'cimsapp'))
    set @vMessageName = 'Available Roles are: cimsro, cimsint, cimsapp only';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Generate password */
  exec pr_DBAdmin_GetRandomString @vPassCodeLength, @vPassCode output;

  /* Switch to the database given or being run */
  select @vsql = 'use '+@vdbname+';'
  exec(@vsql);

  /* Create login */
  select @vsql = 'if (suser_id('''+@User+''') is null)
                    begin
                      create login ['+@User+'] with Password = '''+@vPassCode+''', check_policy = OFF;
                      select @ResultParam = ''Y'';
                    end
                  else
                    print ''Login ['+@User+'] already exists''';

  /* Create a new login and capture the result */
  execute sp_executesql
            @vsql,
            N'@ResultParam varchar(2) output',
            @ResultParam = @vResult output;

  /* Create User */
  select @vsql = 'if (user_id('''+@User+''') is null)
                    create user ['+@User+'] from login ['+@User+'];
                  else
                    print ''User ['+@User+'] already exists''';
  exec(@vsql);

  /* Add User to the role specified */
  select @vsql = 'alter role ['+@Role+'] add member ['+@User+'];'

  exec(@vsql);
  
  /* Print out the info only when the login is created to capture the credentials */
  if (@vResult = 'Y' /* Yes */)
    select 'Please note and update config files as necessary' Note, @User 'User', @vPassCode 'Password';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  print 'Completed Successfully'

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_DBAdmin_AddUser */

Go
