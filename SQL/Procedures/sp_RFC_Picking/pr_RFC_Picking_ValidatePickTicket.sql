/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ValidatePickTicket') is not null
  drop Procedure pr_RFC_Picking_ValidatePickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ValidatePickTicket:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ValidatePickTicket
  (@DeviceId    TDeviceId,
   @UserId      TUserId,
   @PickTicket  TPickTicket,
   @xmlResult   xml          output)

As
  declare @xmlResultvar        TVarchar,
          @vOrderId            TRecordId,
          @ValidPickTicket     TPickTicket,
          @vBusinessUnit       TBusinessUnit,
          @vActivityLogId      TRecordId;

begin /* pr_RFC_Picking_ValidatePickTicket */
begin try
  SET NOCOUNT ON;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin null, @@ProcId, null, @UserId, @DeviceId,
                      null, @PickTicket, 'Order',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given PickTicket exists and is valid for Picking */
  exec pr_Picking_ValidatePickTicket @PickTicket,
                                     @vOrderId        output,
                                     @ValidPickTicket output;

  if (@vOrderId is not null)
    select @vBusinessUnit = BusinessUnit
    from OrderHeaders
    where (OrderId = @vOrderId);

  /* On Error, return Error Code/Error Message */

  /* exec pr_OrderDetail_Get - Returns a single Line, so not using it here */
  set @xmlResult =  (select *
                     from vwOrderDetails
                     where (OrderId = @vOrderId)
                     FOR XML RAW('OrderInfo'), TYPE, ELEMENTS XSINIL, ROOT('OrderDetails'));

  /* Update Device Current Operation Details, etc.,. */
  set @xmlResultvar = convert(varchar(max), @xmlResult);
  exec pr_Device_Update @DeviceId, @UserId, 'ValidatePickTicket', @xmlResultvar, @@ProcId;

  /* Log the result/response */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vOrderId, @ActivityLogId = @vActivityLogId output;
end catch;
end /* pr_RFC_Picking_ValidatePickTicket */

Go
