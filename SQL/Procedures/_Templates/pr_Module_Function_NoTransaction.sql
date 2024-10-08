/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Module_Function_NoTransaction') is not null
  drop Procedure pr_Module_Function_NoTransaction;
Go
/*------------------------------------------------------------------------------
  Proc pr_Module_Function_NoTransaction:
------------------------------------------------------------------------------*/
Create Procedure pr_Module_Function_NoTransaction
  (@RecordId         TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Fetch details from tables/views */

  /* Validations */

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Functionality */

  if (@vReturnCode > 0)
    goto ExitHandler;

  /* Set Status or Do Recount? */

  /* Insert Audit Trail */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Module_Function_NoTransaction */

Go
