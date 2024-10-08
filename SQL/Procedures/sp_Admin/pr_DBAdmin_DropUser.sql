/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DBAdmin_DropUser') is not null
  drop Procedure pr_DBAdmin_DropUser;
Go
/*------------------------------------------------------------------------------
  Proc pr_DBAdmin_DropUser:

    This is executed to drop the user and its associated login
------------------------------------------------------------------------------*/
Create Procedure pr_DBAdmin_DropUser
  (@User     TName,
   @Confirm  TBinary = 0)
as
  /* Declare local variables */
  declare @vReturnCode   TInteger,
          @vMessageName  TVarChar,
          @vRecordId     TRecordId,

          @vsql          TSQL,
          @vdbname       TName,
          @vspid         TRecordId,
          @vProc         TVarChar;

  declare @ttObjects     table (RecordId  TRecordId identity(1,1),
                                procname  varchar(max));

  declare @ttOpenProcess table (RecordId  TRecordId identity(1,1),
                                spid      TRecordId);
begin
begin try
  SET NOCOUNT ON;

  select @vdbname      = db_name(),
         @vReturnCode  = 0,
         @vRecordId    = 0,
         @vspid        = 0,
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
  if (@User is null)
    set @vMessageName = 'Please input user name to be deleted';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Kill open processes with given login or standard logins */
  insert into @ttOpenProcess
    select spid
    from sys.sysprocesses
    where loginame = @User;

  while (exists(select * from @ttOpenProcess where RecordId > @vRecordId))
    begin
      select top 1  @vspid     = spid,
                    @vRecordId = RecordId
      from @ttOpenProcess
      where RecordId > @vRecordId;

      select @vsql = 'kill '+convert(varchar(10), @vspid);

      exec(@vsql);
    end /* End of loop */

  begin transaction

  /* Drop User & its associate Login from the database */
  select @vsql = 'if (user_id('''+@User+''') is not null) drop user ['+@User+'];';
  exec(@vsql);

  select @vsql = 'use master; if (suser_id('''+@User+''') is not null) drop login ['+@User+'];';
  exec(@vsql);

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
end /* pr_DBAdmin_DropUser */

Go
