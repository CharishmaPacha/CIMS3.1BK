/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/08  RIA     pr_RFC_Module_Function: Added template for RFC procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Module_Function') is not null
  drop Procedure pr_RFC_Module_Function;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Module_Function:

------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Module_Function
  (@xmlInput       xml,
   @xmlResult      xml   output)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vDeviceId              TDeviceId,
          @vUserId                TUserId,
          @vBusinessUnit          TBusinessUnit,
          @vActivityLogId         TRecordId;

begin
begin try
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the XML User inputs in to the local variables */
  select @vBusinessUnit = Record.Col.value('BusinessUnit[1]'   , 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]'         , 'TUserId'),
         @vDeviceId     = Record.Col.value('DeviceId[1]'       , 'TDeviceId')
  from @xmlInput.nodes('RootNode') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @EntityId = 0, @EntityKey = '', @Entity = '' /* pass appropriate values */ ,
                      @Value1 = '' , @Value2 = '' , @Value3 = ' ' /* pass appropriate values */ , @Value4 = ' ' /* pass appropriate values */ , @Value5 = ' ' /* pass appropriate values */ ,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction

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

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = /* pass appropriate values */ , @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = /* pass appropriate values */ , @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_Module_Function */

Go
