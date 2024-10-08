/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/02  NB      pr_Archive_Orders changes to update OrderDetails Archived flag for Archived OrderHeaders(FBV3-366)
  2015/04/16  AY      pr_Archive_Orders: Do not update ModifiedDate on archive
  2014/05/30  PV      pr_Archive_Orders: Enhanced to take input from user and archive orders.
  2011/11/15  PKS     pr_Archive_LPNs, pr_Archive_Orders are added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_Orders') is not null
  drop Procedure pr_Archive_Orders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Orders: Archive the default set of orders (Shipped/Completed/Cancelled)
    or the selected set of orders passed in
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Orders
  (@UserId                TUserId,
   @BusinessUnit          TBusinessUnit,
   @ArchiveOrdersContents TXML      = null,
   @vMessage               TNVarChar = null output)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @xmldata         Xml,
          @vOrdersCount    TCount,
          @vOrdersUpdated  TCount,
          @vArchiveDate    TDate,

          @ttOrderHeaders    TEntityKeysTable,
          @ttArchivedOrders  TEntityKeysTable;

begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @xmlData       = convert(xml, @ArchiveOrdersContents),
         @vArchiveDate  = convert(date, getdate()-1);

  /* Load all the Orders into the temp table which are to be Archived */
  if (@xmlData.exist('/ArchiveOrders/Orders/OrderNo') = 1)
    begin
        insert into @ttOrderHeaders (EntityId)
        select Record.Col.value('.', 'TRecordId') OrderNo
        from @xmlData.nodes('/ArchiveOrders/Orders/OrderNo') as Record(Col);

        set @vOrdersCount = @@rowcount;
    end /* End If */
  else
    begin
      /* Read all the Orders in the desired status until 1 day before the current date */
      insert into @ttOrderHeaders (EntityId)
        select OrderId
        from OrderHeaders OH
        where ((OH.Archived = 'N' /* No */) and
               (OH.Status in ('S' /* Shipped*/,
                              'D' /* Completed */,
                              'X' /* Canceled */,
                              'V' /* Invoiced */) and
               (ModifiedOn <= @vArchiveDate)));

      set @vOrdersCount = @@rowcount;
    end /* end else */

  /* Update the Orders table */
  update OH
  set Archived = 'Y' /* Yes */
  output inserted.OrderId into @ttArchivedOrders (EntityId)
  from OrderHeaders OH
       join @ttOrderHeaders  TOH on(OH.OrderId = TOH.EntityId)
  where ((OH.Archived = 'N' /* No */) and
         (OH.Status in ('S' /* Shipped*/,
                        'D' /* Completed */,
                        'X' /* Canceled */,
                        'V' /* Invoiced */)));

  set @vOrdersUpdated = @@rowcount;

  /* Update Order Details for the Archived Orders */
  update OD
  set Archived = 'Y'
  from OrderDetails OD
    join @ttArchivedOrders TOH on (OD.OrderId = TOH.EntityId);

  exec @vMessage = dbo.fn_Messages_BuildActionResponse 'Order', 'ArchiveOrders', @vOrdersUpdated, @vOrdersCount;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Orders */

Go
