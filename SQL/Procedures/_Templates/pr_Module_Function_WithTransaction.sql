/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Module_Function_WithTransaction') is not null
  drop Procedure pr_Module_Function_WithTransaction;
Go
/*------------------------------------------------------------------------------
  Proc pr_Module_Function_WithTransaction:

------------------------------------------------------------------------------*/
Create Procedure pr_Module_Function_WithTransaction
  (@RecordId         TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId;

begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0;

  /* Fetch details from tables/views */

  /* Validations */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Functionality */

  if (@vReturnCode > 0)
    goto ErrorHandler;

  /* Set Status or Do Recount? */

  /* Insert Audit Trail */

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
end /* pr_Module_Function_WithTransaction */

Go
