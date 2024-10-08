/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/01/06  SHR     Added pr_RFC_GetPickTicketInfo.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_GetPickTicketInfo') is not null
  drop Procedure pr_RFC_GetPickTicketInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_GetPickTicketInfo:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_GetPickTicketInfo
  (@DeviceId    TDeviceId,
   @UserId      TUserId,
   @PickTicket  TPickTicket,
   @xmlResult   xml          output)
As
  declare @xmlResultvar    TVarchar,
          @vOrderId        TRecordId,
          @ValidPickTicket TPickTicket,
          @vReturnCode     TInteger,
          @vMessageName    TMessageName,

          @vActivityLogId  TRecordId,
          @vBusinessUnit   TBusinessUnit,
          @vMessage        TDescription;

begin /* pr_RFC_GetPickTicketInfo */
begin try
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, @vBusinessUnit, @UserId, @DeviceId,
                      null /* EntityId */, @PickTicket, 'Order',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given PickTicket exists and is valid for Picking */
  select @vOrderId        = OrderId,
         @ValidPickTicket = PickTicket,
         @vBusinessUnit   = BusinessUnit
  from OrderHeaders
  where (PickTicket = @PickTicket);

  /* Verify whether the given PickTicket exists */
  if (@vOrderId is null)
    set @vMessageName = 'PickTicketDoesNotExist';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    goto ErrorHandler;

  /* exec pr_OrderDetail_Get - Returns a single Line, so not using it here */
  set @xmlResult =  (select *
                     from vwOrderDetails
                     where (OrderId = @vOrderId)
                     FOR XML RAW('orderinfo'), TYPE, ELEMENTS XSINIL, ROOT('orderdetails'));

  /* Save Device State */
  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'GetPickTicketInfo', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_GetPickTicketInfo */

Go
