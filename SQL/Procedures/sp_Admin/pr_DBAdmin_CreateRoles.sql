/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DBAdmin_CreateRoles') is not null
  drop Procedure pr_DBAdmin_CreateRoles;
Go
/*------------------------------------------------------------------------------
  Proc pr_DBAdmin_CreateRoles:
    Procedure to create different roles for accessing cIMS application
------------------------------------------------------------------------------*/
Create Procedure pr_DBAdmin_CreateRoles
as
  declare @vReturnCode   TInteger,
          @vMessageName  TVarChar,
          @vRecordId     TRecordId,

          @vsql          TSQL,
          @vdbname       TName,
          @vProc         TVarChar;

  declare @ttObjects     table (RecordId  TRecordId identity(1,1),
                                procname  varchar(max));
begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vdbname      = db_name(),
         @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  /* Validations */
  if (IS_ROLEMEMBER('db_owner') <> 1) and (IS_SRVROLEMEMBER('sysadmin') <> 1)
    set @vMessageName = 'NoAuthorizationToRun';
  else
  if (@vdbname in ('msdb', 'master', 'tempdb', 'model'))
    set @vMessageName = 'CannotRunOnSystemDBs';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Switch to the database given or being run */
  select @vsql = 'use '+@vdbname+';'
  exec(@vsql);

  /*************  Role CIMSRO - For Read only permissions **************/
  /* Create a role */
  if (DATABASE_PRINCIPAL_ID('cimsro') is null)
    create role [cimsro];
  else
    print 'Database role [cimsro] already exists'

  /* Assign to default roles */
  exec sp_addrolemember 'db_datareader', 'cimsro';

  /*************  Role CIMSINT - with DML & Import & Export permissions *********/
  /* Create a role */
  if (DATABASE_PRINCIPAL_ID('cimsint') is null)
    create role [cimsint];
  else
    print 'Database role [cimsint] already exists'

  /* Assign to default roles */
  exec sp_addrolemember 'db_datareader', 'cimsint';

  /* Grant permissions to all pr_Import_* & pr_Export_* procedures */
  insert into @ttObjects (procname)
    select name
    from sys.objects
    where (type = 'P' /* procedure */) and
          (name like 'pr_Import%' or name like 'pr_Export%')

  /* Build the sql to grant for all the selected procs */
  select @vsql = '';
  select @vsql += 'grant execute ON '+ ProcName+' TO [cimsint];'
  from @ttObjects;

  exec(@vsql);

  /*************  Role CIMSAPP - with DML & Executable permissions **************/
  /* Create a role */
  if (DATABASE_PRINCIPAL_ID('cimsapp') is null)
    create role [cimsapp];
  else
    print 'Database role [cimsapp] already exists'

  /* Assign to default roles */
  exec sp_addrolemember 'db_datareader', 'cimsapp';

  /* Grant special permissions */
  grant execute           TO [cimsapp];
  grant INSERT            TO [cimsapp];
  grant update            TO [cimsapp];
  grant DELETE            TO [cimsapp];
  grant CREATE TABLE      TO [cimsapp];
  grant CREATE PROCEDURE  TO [cimsapp];
  grant CREATE VIEW       TO [cimsapp];
  grant CREATE SYNONYM    TO [cimsapp];

  /*************  Role CIMSADMIN - DBO **************/
  /* Create a role */
  if (DATABASE_PRINCIPAL_ID('cimsadmin') is null)
    create role [cimsadmin];
  else
    print 'Database role [cimsadmin] already exists'

  /* Assign to default roles */
  exec sp_addrolemember 'db_owner',           'cimsadmin';
  exec sp_addrolemember 'db_ddladmin',        'cimsadmin';
  exec sp_addrolemember 'db_backupoperator',  'cimsadmin';
  exec sp_addrolemember 'db_datareader',      'cimsadmin';
  exec sp_addrolemember 'db_datawriter',      'cimsadmin';

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
end /* pr_DBAdmin_CreateRoles */

Go
