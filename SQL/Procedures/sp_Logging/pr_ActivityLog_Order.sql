/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ActivityLog_Order') is not null
  drop Procedure pr_ActivityLog_Order;
Go
/*------------------------------------------------------------------------------
  Proc pr_ActivityLog_Order: To Log OrderHeader or OrderDetails related details of given operation
  ------------------------------------------------------------------------------*/
Create Procedure pr_ActivityLog_Order
  (@Operation      TDescription,
   @OrderId        TRecordId,
   @ttOrders       TEntityKeysTable ReadOnly,
   @Entity         TEntity       = 'OH,OD',
   @ProcId         TInteger      = 0,
   @Message        TDescription  = null,
   @DeviceId       TDeviceId     = null,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = 'CIMS',
   @ActivityLogId  TRecordId     = null output)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,

          @vPickTicket   TPickTicket,
          @vxmlLogDataOH TXML,
          @vxmlLogDataOD TXML,
          @vxmlLogData   TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  if (@OrderId is not null)
    select @vPickTicket = PickTicket
    from OrderHeaders
    where (OrderId = @OrderId);

  /* Get the OrderHeader or OrderDetails Details info for logging */
  if (exists (select * from @ttOrders)) and (charindex('OH', @Entity) > 0)
    select @vxmlLogDataOH = (select OH.* from @ttOrders ttOH join OrderHeaders OH on (ttOH.EntityId = OH.OrderId)
                             for XML raw('OrderHeaders'), elements);
  else
  if (charindex('OH', @Entity) > 0)
    select @vxmlLogDataOH = (select OH.* from OrderHeaders OH where (OH.OrderId = @OrderId)
                             for XML raw('OrderHeaders'), elements);

  if (exists (select * from @ttOrders)) and (charindex('OD', @Entity) > 0)
    select @vxmlLogDataOD = (select OD.* from @ttOrders ttOD join OrderDetails OD on (ttOD.EntityId = OD.OrderDetailId)
                             for XML raw('OrderDetails'), elements);
  else
  if (charindex('OD', @Entity) > 0)
    select @vxmlLogDataOD = (select OD.* from OrderDetails OD where (OD.OrderId = @OrderId)
                             for XML raw('OrderDetails'), elements);

  select @vxmlLogData = dbo.fn_XMLNode('Root', @vxmlLogDataOH + @vxmlLogDataOD);

  /* insert into activitylog details */
  exec pr_ActivityLog_AddMessage @Operation, @OrderId, @vPickTicket, @Entity,
                                 @Message, @ProcId, @vxmlLogData, @BusinessUnit, @UserId,
                                 @ActivityLogId = @ActivityLogId output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ActivityLog_Order */

Go
