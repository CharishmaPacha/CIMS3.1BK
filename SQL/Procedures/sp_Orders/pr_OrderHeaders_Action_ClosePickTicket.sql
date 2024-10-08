/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/31  PKK     Added New procedure pr_OrderHeaders_Action_ClosePickTicket (CIMSV3-1488)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_ClosePickTicket') is not null
  drop Procedure pr_OrderHeaders_Action_ClosePickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_ClosePickTicket: This procedure loops through each
    selected pick ticket and invoke pr_OrderHeaders_Close proc to close it
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_ClosePickTicket
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
          @vOrderId                    TRecordId;

begin /* pr_OrderHeaders_Action_ClosePickTicket */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordsUpdated = 0,
         @vRecordId       = 0;

  /* Read input xml */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get Controls */
  select @vValidStatuses = dbo.fn_Controls_GetAsString('ModifyOrder', 'ValidOrderStatus', 'ONIAWCPKRGL' /* Valid statuses other than Cancelled, Shipped */, @BusinessUnit, @UserId);

  /* Get total selected records count */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */

  /* Cannot close Bulk Orders */
  delete from SE
  output 'E', deleted.EntityId, OH.PickTicket, 'Order_ClosePickTicket_InvalidOrderType'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE
    join OrderHeaders OH on (SE.EntityId = OH.OrderId)
  where (OrderType = 'B' /* Bulk Pull */);

  /* Restrict all actions on Shipped/Canceled/Completed Orders */
  delete from SE
  output 'E', deleted.EntityId, OH.PickTicket, 'Order_ClosePickTicket_InvalidOrderStatus', OH.Status
    into #ResultMessages(MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE
    join OrderHeaders OH on (SE.EntityId = OH.OrderId)
  where (dbo.fn_IsInList(Status, @vValidStatuses) = 0);

  /* we have status code in Value2 so updating as StatusDescription */
  update #ResultMessages
  set Value2 = dbo.fn_Status_GetDescription ('Order', Value2, @BusinessUnit)
  where MessageName = 'Order_ClosePickTicket_InvalidOrderStatus'

  /* Loop thru each record and close PickTicket */
  while (exists (select * from #ttSelectedEntities where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId   = RecordId,
                   @vOrderId    = EntityId,
                   @vPickTicket = EntityKey
      from #ttSelectedEntities
      where RecordId > @vRecordId
      order by RecordId;

      begin try
        /* Invoke procedure to close PickTicket */
        exec pr_OrderHeaders_Close @vOrderId, @vPickTicket, 'Y' /* Force Close */, null /* LoadId */,
                                   @BusinessUnit, @UserId;

        /* Set Records Updated Count */
        select @vRecordsUpdated += 1;
      end try
      begin catch
        /* Capture the error message to display to user */
        insert into #ResultMessages(MessageType, EntityId, EntityKey, MessageText)
          select 'E', @vOrderId, @vPickTicket, ERROR_MESSAGE();
      end catch
    end

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_ClosePickTicket */

Go
