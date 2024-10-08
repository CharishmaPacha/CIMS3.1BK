/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/03  PK      pr_OrderHeaders_LoadedOrdersToShip: Considering the Orders which has UnitsToAllocate is zero.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_LoadedOrdersToShip') is not null
  drop Procedure pr_OrderHeaders_LoadedOrdersToShip;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_LoadedOrdersToShip:   This procedure will used in Job.

  Purpose: This procedure will checks for the Loaded orders and then pass each
           order to the procedure pr_OrderHeaders_Close to ship each LPN on the
           order and eventually ship the order itself.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_LoadedOrdersToShip
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,

          @vRecordId          TRecordId,
          @vOrderId           TRecordId,
          @vPickTicket        TPickTicket,
          @ttLoadedOrders     TEntityKeysTable;
begin
  select @ReturnCode   = 0,
         @MessageName  = null,
         @vRecordId    = 0;          ;

  /* insert all the orders which are in Loaded status into a temp table */
  insert into @ttLoadedOrders(EntityId, EntityKey)
    select OrderId, PickTicket
    from OrderHeaders
    where (BusinessUnit = @BusinessUnit) and
          (Status in ('L' /* Loaded */, 'E' /* Staged */));

  if (@@rowcount = 0)
    goto ExitHandler;

  while (exists (select * from @ttLoadedOrders where (RecordId > @vRecordId)))
    begin
      select top 1 @vOrderId    = EntityId,
                   @vPickTicket = EntityKey,
                   @vRecordId   = RecordId
      from @ttLoadedOrders
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Close the Order as all LPNs are loaded - if there is no more inventory to pick */
      exec pr_OrderHeaders_Close @vOrderId, @vPickTicket, 'N' /* Force Close */, null /* LoadId */, @BusinessUnit, @UserId;

    end /* End of the while loop */

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_OrderHeaders_LoadedOrdersToShip */

Go
