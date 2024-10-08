/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/13  RKC     pr_Load_Generate, pr_Load_AddOrders: Moved the all validation messages to Rules
                      pr_Loads_AutoBuild, pr_Load_UI_AddOrders: Pass the Operation parm to pr_Load_AddOrders
                      pr_Load_AddOrders: Added new parms as Operation (HA-1610)
  2018/08/12  RV      pr_Load_AddOrders: Made changes to do not allow order if the order have outstanding picks (OB2-554)
  2015/09/16  YJ      pr_Load_AddOrders: Added validation to avoid Orders which has ShipVia null. (ACME-336)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_AddOrders') is not null
  drop Procedure pr_Load_AddOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_AddOrders: Procedure to add the given Orders to the given Loads by
    calling pr_Load_AddOrder proc for each order. The orders to be added can be
    passed in using the table variable @ttOrders or #Load_OrdersToAdd

  This is utilized both by Load generation process or when user chooses to individually
  add Orders to a selected Load in UI.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_AddOrders
  (@LoadNumber    TLoadNumber,
   @ttOrders      TEntityKeysTable  ReadOnly,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @LoadRecount   TFlag        = 'N',
   @Operation     TOperation   = null,
   ------------------------------------------
   @TotalOrders   TCount       = null output,
   @AddedOrders   TCount       = null output,
   @Message       TDescription = null output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @xmlRulesData      TXML,
          @vOrders           XML,
          @vOrderId          TRecordId,
          @vLoadId           TRecordId,
          @vRecordId         TRecordId,
          @vStatus           TStatus,
          @vOrderShipmentId  TShipmentId,
          @vTotalCount       TCount,
          @vDeletedOrdCount  TCount,
          @vShipViaNullCount TCount;

  declare @ttOrdersToAdd     TLoadAddOrders,
          @ttOrdersToUpdate  TEntityKeysTable;

begin /* pr_Load_AddOrders */
begin try
  begin transaction;
  select @ReturnCode  = 0,
         @MessageName = null,
         @Message     = null,
         @AddedOrders = 0,
         @vRecordId   = 0;

  /* create # table with @ttOrdersToAdd table structure */
  if (object_id('tempdb..#Load_OrdersToAdd') is null)
    select * into #Load_OrdersToAdd from @ttOrdersToAdd;

  select * into #OrdersToUpdate from @ttOrdersToUpdate;

  /* Add records from @ttOrders if there are none in the # table Load_OrdersToAdd */
  if (not exists (select * from #Load_OrdersToAdd)) and (exists (select * from @ttOrders))
    insert into #Load_OrdersToAdd(OrderId, LoadNumber, ProcessStatus)
      select EntityId, @LoadNumber, 'ToBeProcessed' from @ttOrders;

  /* Get the total orders */
  select @TotalOrders = @@rowcount;

  /* Get Load info */
  select @vLoadId = LoadId,
         @vStatus = Status
  from Loads
  where (LoadNumber   = @LoadNumber) and
        (BusinessUnit = @BusinessUnit);

  if (@vLoadId is null)
    set @MessageName = 'InvalidLoad';
  else
  if (@vStatus in ('S', 'X' /* Shipped/Cancelled */)) -- Why Orders cannot be added to load which are ready to ship?
    set @MessageName = 'Load_AddOrders_InvalidStatus';

  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Build the data for evaluation of rules to get Valid orders to generate load */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation', @Operation));

  /* If selected order not valid to generate load calling rules remove the orders from #Load_OrdersToAdd table */
  exec pr_RuleSets_ExecuteAllRules 'Loads_AddOrders', @xmlRulesData, @BusinessUnit;

  /* Add the valid orders to the Load one at a time */
  while (exists (select * from #Load_OrdersToAdd where (RecordId > @vRecordId) and (ProcessStatus = 'ToBeProcessed')))
    begin
      select Top 1 @vRecordId = RecordId,
                   @vOrderId  = OrderId
      from #Load_OrdersToAdd
      where (RecordId > @vRecordId) and
            (ProcessStatus = 'ToBeProcessed')
      order by RecordId;

     /* This proc will add order to shipment if order is not on shipment, then will add to load */
      exec @ReturnCode = pr_Load_AddOrder @vLoadId, @vOrderId, @BusinessUnit, @UserId;

      if (@ReturnCode = 0)  /* Count the total orders added to load */
         begin
           set @AddedOrders = @AddedOrders + 1;

           /* Once after procesing the orders update Process status as Done */
           update #Load_OrdersToAdd
           set ProcessStatus = 'Done'
           where (RecordId = @vRecordId);
         end
    end

  /* If order has single shipment then update Load info on the Order */
  insert into #OrdersToUpdate (EntityId) select distinct OrderId from #Load_OrdersToAdd where ProcessStatus = 'Done';
  exec pr_OrderHeaders_UpdateLoadInfo @Operation, @BusinessUnit, @UserId;

  /* Recount will calculate the counts afresh. Also calls SetStatus of Load to update the Load Status accordingly */
  exec pr_Load_Recount @vLoadId;

  /* Based upon the number of Orders that have been added, give an appropriate message */
  if (@Message is null)
    exec @Message = dbo.fn_Messages_BuildActionResponse 'Load', 'AddOrders', @AddedOrders, @TotalOrders, @LoadNumber;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;

end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_AddOrders */

Go
