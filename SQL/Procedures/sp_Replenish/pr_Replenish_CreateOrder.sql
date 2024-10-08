/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/14  VS      pr_Replenish_CreateOrder: Generate Replenish Order (CIMSV3-1604)
  2021/05/05  SJ/AY   pr_Replenish_CreateOrder: Return PickTicket
                      pr_Replenish_CreateOrder: Initial Revision (S2G-385)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_CreateOrder') is not null
  drop Procedure pr_Replenish_CreateOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_CreateOrder: Creates a Replenish Order with the given inputs
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_CreateOrder
  (@OrderType         TTypeCode,
   @OrderPriority     TPriority,
   @ReplenishGroup    TCategory,
   @Warehouse         TWarehouse,
   @Ownership         TOwnership,
   @Operation         TOperation,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @OrderId           TRecordId          output,
   @PickTicket        TPickTicket = null output)
as
  declare @vMessageName         TMessageName,
          @vReturnCode          TInteger,

          @vPickTicket          TPickTicket,
          @vOrderCategory       TCategory,
          @vOrderDate           TDateTime;

  declare @ttOrderHeaderImport  TOrderHeaderImportType;

begin /* pr_Replenish_CreateOrder */
  /* Define Order Category */
  select @vOrderDate     = current_timestamp,
         @vOrderCategory = case
                             when @Operation like 'OnDemandReplenish'
                               then 'On-Demand'
                             when @Operation = 'ReplenishDynamicLocations'
                               then 'DynamicReplenishments'
                             else 'Min-Max'
                           end;

  /* Get Next PickTicket No */
  exec pr_Replenish_GetNextPickTicketNo @BusinessUnit, @UserId, @vPickTicket output;

  /* Create #OrderHeadersImport to create the Replenish Order */
  if object_id('tempdb..#OrderHeadersImport') is null
    select * into #OrderHeadersImport from @ttOrderHeaderImport;

  /* Import Replenish Order - Step 1: Load */
  exec pr_Imports_OrderHeaders_LoadData @xmlData        = null,
                                        @Action         = 'I',
                                        @PickTicket     = @vPickTicket,
                                        @SalesOrder     = @vPickTicket,
                                        @OrderType      = @OrderType,
                                        @OrderDate      = @vOrderDate,
                                        @Priority       = @OrderPriority,
                                        @OrderCategory1 = @vOrderCategory,
                                        @OrderCategory5 = @ReplenishGroup,
                                        @Warehouse      = @Warehouse,
                                        @Ownership      = @Ownership,
                                        @BusinessUnit   = @BusinessUnit,
                                        @CreatedBy      = @UserId;

 /* Import Replenish Order - Step 1: Validate & Insert */
 exec pr_Imports_OrderHeaders @BusinessUnit = @BusinessUnit, @UserId = @UserId;

  /* Get the OrderId of the Repl. Order just created */
  select @OrderId    = OrderId,
         @PickTicket = PickTicket
  from OrderHeaders
  where (PickTicket   = @vPickTicket ) and
        (BusinessUnit = @BusinessUnit);

  update OrderHeaders
  set PickBatchGroup = @OrderType,
      PreProcessFlag = 'I' /* Ignore */
  where (OrderId = @OrderId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_CreateOrder */

Go
