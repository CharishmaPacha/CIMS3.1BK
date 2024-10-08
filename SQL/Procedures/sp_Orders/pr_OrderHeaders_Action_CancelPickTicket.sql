/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/10  PKK     Added New procedure pr_OrderHeaders_Action_CancelPickTicket (CIMSV3-1487)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_CancelPickTicket') is not null
  drop Procedure pr_OrderHeaders_Action_CancelPickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_CancelPickTicket: This procedure loops through each
    selected pick ticket and invoke pr_OrderHeaders_CancelPickTicket proc to Cancel it
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_CancelPickTicket
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Process variables */
          @vValidStatuses              TControlValue,
          @vPickTicket                 TPickTicket,
          @vReasonCode                 TReasonCode,
          @vOrderId                    TRecordId;

begin /* pr_OrderHeaders_Action_CancelPickTicket */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vRecordsUpdated = 0;

  /* Read input xml */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get total selected records count */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */

  /* delete Bulk Orders */
  delete from SE
  output 'E', deleted.EntityId, OH.PickTicket, 'Order_CancelPickTicket_InvalidOrderType'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE
    join OrderHeaders OH on (SE.EntityId = OH.OrderId)
  where (OrderType = 'B' /* Bulk Pull */);

  /* Restrict all actions on Shipped/Canceled/Completed Orders */
  delete from SE
  output 'E', deleted.EntityId, OH.PickTicket, 'Order_CancelPickTicket_InvalidOrderStatus',  OH.Status
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE
    join OrderHeaders OH on (SE.EntityId = OH.OrderId)
  where (dbo.fn_IsInList(Status, 'SDX' /* Shipped, Completed for Canceled */) <> 0);

  /* delete the PickTickets which are in Shipped Status */
  delete from SE
  output 'E', deleted.EntityId, OH.PickTicket, 'Order_CancelPickTicket_SomeUnitsareShipped'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE
    join OrderHeaders OH on (SE.EntityId = OH.OrderId)
  where (OH.UnitsShipped > 0);

  /* delete the PickTickets which are on Load */
  delete from SE
  output 'E', deleted.EntityId, OH.PickTicket, 'Order_CancelPickTicket_OrderOnLoad'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE
    join Orderheaders OH on (SE.EntityId = OH.OrderId)
    join vwOrderShipments OS on (OH.OrderId = OS.OrderId)
  where ((coalesce(OS.LoadId, 0) <> 0))

  /* we have status code in Value2 so updating as StatusDescription */
  update #ResultMessages
  set Value2 = dbo.fn_Status_GetDescription ('Order', Value2, @BusinessUnit)
  where MessageName = 'Order_CancelPickTicket_InvalidOrderStatus'

  /* Loop thru remaining records and cancel each PickTicket */
  while (exists (select * from #ttSelectedEntities where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId   = RecordId,
                   @vOrderId    = EntityId,
                   @vPickTicket = EntityKey
      from #ttSelectedEntities
      where RecordId > @vRecordId
      order by RecordId;

      begin try
        /* Invoke procedure to cancel PickTicket */
        exec pr_OrderHeaders_CancelPickTicket @vOrderId, @vPickTicket, null /* ReasonCode */,
                                              @BusinessUnit, @UserId;

        /* Set Records Updated Count */
        select @vRecordsUpdated += 1;
      end try
      begin catch
        /* capture the error message to display user */
        insert into #ResultMessages(MessageType, EntityId, EntityKey, MessageName)
          select 'E', @vOrderId, @vPickTicket, ERROR_MESSAGE();
      end catch
    end

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_CancelPickTicket */

Go
