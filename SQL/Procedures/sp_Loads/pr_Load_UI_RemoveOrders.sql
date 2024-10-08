/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/08  TK      pr_Loads_Action_Cancel, pr_Load_RemoveOrders &  pr_Load_UI_RemoveOrders:
  pr_Load_UI_RemoveOrders: Made changes to insert selected entities into #table to work in V2 (HA-839)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_UI_RemoveOrders') is not null
  drop Procedure pr_Load_UI_RemoveOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_UI_RemoveOrders:
       Removes the given Orders from the Loads by
       calling pr_Load_RemoveOrder proc for each order

  '<Orders xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <OrderHeader>
    <OrderId>19</OrderId>
    </OrderHeader>
  </Orders>'
------------------------------------------------------------------------------*/
Create Procedure pr_Load_UI_RemoveOrders
  (@LoadNumber         TLoadNumber,
   @Orders             TXML,
   @CancelLoadIfEmpty  TFlag,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
  ------------------------------------------------
   @TotalOrders        TCount       = null output,
   @OrdersRemoved      TCount       = null output,
   @Message            TDescription = null output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          /* Orders info */
          @vxmlOrders        XML,
          @vOrderId          TRecordId,
          @vOrderShipmentId  TShipmentId,
          /* Load Info */
          @vLoadId           TRecordId,
          @vStatus           TStatus,
          @vOrderOnLoad      TCount,
          /* Other info..*/
          @ttOrders          TEntityValuesTable;
begin /* pr_Load_UI_RemoveOrders */
  select @CancelLoadIfEmpty = coalesce(@CancelLoadIfEmpty, 'N'),
         @TotalOrders       = 0,
         @ReturnCode        = 0,
         @OrdersRemoved     = 0,
         @Message           = null,
         @MessageName       = null;

  if (coalesce(@Orders, '') <> '')
    begin
      select @vxmlOrders = convert(xml, @Orders);

      insert into @ttOrders(EntityType, EntityId, RecordId)
        select 'PickTicket', Record.Col.value('(OrderId/text())[1]', 'TRecordId'), row_number() over (order by (select 1))
        from @vxmlOrders.nodes('/Orders/OrderHeader') as Record(Col);
    end

  /* Call the Remove orders procedure - it uses #ttSelectedEntities */
  exec pr_Load_RemoveOrders @LoadNumber,
                            @ttOrders,
                            @CancelLoadIfEmpty,
                            'Load_RemoveOrder',
                            @BusinessUnit,
                            @UserId,
                            @TotalOrders   output,
                            @OrdersRemoved output,
                            @Message       output;

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_UI_RemoveOrders */

Go
