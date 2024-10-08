/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/10/28  YJ      pr_Replenish_ModifyOrders: Validating statuses for Action close Order/Cancel Order (FB-400)
  2015/10/19  TK      pr_Replenish_ModifyOrders: Update Pickbatch Status to Completed or Canceled if all the
  2015/10/08  YJ      pr_Replenish_ModifyOrders: Added Waved and InProgress status as well to Cancel Orders.
  2015/04/07  TK      pr_Replenish_ModifyOrders: Allow to change Order priority if it Batched also
  2014/11/11  TK      pr_Replenish_ModifyOrders: Updated to Log Audit Trail.
  2014/07/22  TK      pr_Replenish_ModifyOrders: Changes to Close Order action.
  2014/07/04  AK      pr_Replenish_ModifyOrders:Used distinct as returning duplicate LocationIDs.
  2014/06/02  AK      Renamed pr_Replenish_Modify to pr_Replenish_ModifyOrders.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_ModifyOrders') is not null
  drop Procedure pr_Replenish_ModifyOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_ModifyOrders
  XML Structure

<ModifyReplenishOrders>
  <Action>ChangeOrderPriority</Action>
  <Data>
    <Priority>1</Priority>
  </Data>
  <OrdersToModify>
    <OrderNo>R0906002</OrderNo>
    <OrderNo>R0830004</OrderNo>
    <OrderNo>R0910002</OrderNo>
  </OrdersToModify>
</ModifyReplenishOrders>
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_ModifyOrders
  (@UserId           TUserId,
   @ModifyDetails    TXML,
   @BusinessUnit     TBusinessUnit,
   @Message          TDescription  output)
as
  declare @ReturnCode      TInteger,
          @MessageName     TMessageName,
          @vRecordId       TRecordId,
          @vPickBatchId    TRecordId,
          @vPickBatchNo    TPickBatchNo,
          @vPriority       TPriority,
          @vAction         TDescription,
          @vData           TDescription,
          @vOrders         TNVarChar,
          @xmlData         xml,
          @vOrdersCount    TCount,
          @vOrdersUpdated  TCount,
          @vInvalidOrders  TCount,
          @vOrdersWithLPNsNotPutaway
                           TCount,
          @vEntity         TEntity,
          @vStatus         TStatus,
          @vOrderId        TRecordId,
          @vEntityKey      TEntity,

          @vAuditRecordId  TRecordId,
          @vAuditActivity  TActivityType,
          @vInvalidStatusesToClose
                           TControlCode,
          @vInvalidStatusesToCancel
                           TControlCode;
  /* Temp table to hold all the ReplenishOrders to be updated */
  declare @ttOrders               TEntityKeysTable,
          @ttOrdersModified       TEntityKeysTable,
          @ttAuditLocations       TEntityKeysTable,
          @ttPickBatchesModified  TEntityKeysTable;

begin /* pr_Replenish_ModifyOrders */
begin try
  begin transaction
  SET NOCOUNT ON;

  select @xmlData        = convert(xml, @ModifyDetails),
         @vOrdersCount   = 0,
         @vOrdersUpdated = 0,
         @vEntity        = 'ReplenishOrder',
         @MessageName    = null;

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/ModifyReplenishOrders') as Record(Col);

  /* Load all the Orders into the temp table which are to be updated in OrderHeaders table
     Assuming that the UI is always sending the PickTicket Number to modify */
  insert into @ttOrders (EntityId, EntityKey)
    select row_number() over(order by (select null)) AS RowNumber,
           Record.Col.value('.', 'TPickTicket') PickTicket
    from @xmlData.nodes('/ModifyReplenishOrders/OrdersToModify') as Record(Col);

  /* Get the control value here */
  select @vInvalidStatusesToClose  = dbo.fn_Controls_GetAsString('ReplenishOrder', 'InvalidStatusesToClose', 'NW'/* New, Wave */, @BusinessUnit, null/* UserId */);
  select @vInvalidStatusesToCancel = dbo.fn_Controls_GetAsString('ReplenishOrder', 'InvalidStatusesToCancel', 'IACP'/* InProgress, Allocated, Picking, Picked */, @BusinessUnit, null/* UserId */);

  /* Get number of rows inserted */
  select @vOrdersCount = @@rowcount;

  if (@vAction = 'ChangeReplenishOrderPriority')
    begin
      select @vAction        = 'ChangeOrderPriority',
             @vAuditActivity = @vAction;

      select @vPriority = Record.Col.value('Priority[1]', 'TPriority')
      from @xmlData.nodes('/ModifyReplenishOrders/Data') as Record(Col);

      /* Check if the Priority is passed or not */
      if (@vPriority is null)
        set @MessageName = 'PriorityIsRequired';

      if (@MessageName is not null)
         goto ErrorHandler;

      /* Update all Orders in the temp table and insert the updated records for audit entities */
      update OH
      set Priority     = @vPriority,
          ModifiedDate = current_timestamp,
          ModifiedBy   = @UserId
      output Inserted.OrderId, Inserted.PickTicket into @ttOrdersModified
      from OrderHeaders OH
        join @ttOrders TT on (OH.PickTicket = TT.EntityKey)
      where (OH.Status in ('N' /* New */, 'W' /* Batched */));

      set @vOrdersUpdated = @@rowcount;
    end
  else
  if (@vAction = 'CancelReplenishOrder')
    begin
      select @vAuditActivity = @vAction,
             @vAction        = 'Cancel',
             @vRecordId      = 0;

      /* Delete the orders from temp table if they are not qualified to be canceled */
      delete TT
      from @ttOrders TT
        inner join OrderHeaders OH on TT.EntityKey = OH.PickTicket and OH.BusinessUnit = @BusinessUnit
      where (charindex(OH.Status, @vInvalidStatusesToCancel) <> 0);

      select @vInvalidOrders = @@rowcount;

      /* Cancel all the remaining orders in the temp table and insert the updated records for audit entities */
      update OH
      set status       = 'X', /* Cancelled */
          ModifiedDate = current_timestamp,
          ModifiedBy   = @UserId
      output Inserted.OrderId, Inserted.PickTicket into @ttOrdersModified
      from OrderHeaders OH
          join @ttOrders TT on (OH.PickTicket = TT.EntityKey);

      set @vOrdersUpdated = @@rowcount;

      /* Get the PickBatchId on the Orders Canceled above */
      insert into @ttPickBatchesModified(EntityId, EntityKey)
        select distinct OH.PickBatchId, OH.PickBatchNo
        from OrderHeaders OH join @ttOrdersModified TT on (OH.PickTicket = TT.EntityKey);

      exec pr_PickBatch_Recalculate @ttPickBatchesModified, 'S' /* Status only */, @UserId;

    end /* if CancelReplenishOrder */
  else
  if (@vAction = 'CloseReplenishOrder')
    begin
      select @vAuditActivity = @vAction,
             @vAction        = 'Close',
             @vRecordId      = 0;

      /* Delete the orders from temp table if they are not qualified to be closed */
      delete TT
      from @ttOrders TT
        inner join OrderHeaders OH on TT.EntityKey = OH.PickTicket and OH.BusinessUnit = @BusinessUnit
      where (charindex(OH.Status, @vInvalidStatusesToClose) <> 0);

      select @vInvalidOrders = @@rowcount;

      /* Delete the orders from temp table if any LPNs are not in Putaway status */
      delete TT
      from @ttOrders TT
        inner join OrderHeaders OH on TT.EntityKey = OH.PickTicket and
                                      OH.BusinessUnit = @BusinessUnit
        inner join LPNs LP on OH.OrderId = LP.OrderId
      where (LP.Status <> 'P' /* Putaway */);

      select @vOrdersWithLPNsNotPutaway = @@rowcount;

      update OH
      set status       = 'D' /* Completed */,
          ModifiedDate = current_timestamp,
          ModifiedBy   = @UserId
      output Inserted.OrderId, Inserted.PickTicket into @ttOrdersModified
      from OrderHeaders OH
          join @ttOrders TT on (OH.PickTicket = TT.EntityKey);

      set @vOrdersUpdated = @@rowcount;

      /* Get the PickBatchId on the Orders Closed above */
      insert into @ttPickBatchesModified(EntityId, EntityKey)
        select distinct OH.PickBatchId, OH.PickBatchNo
        from OrderHeaders OH
          join @ttOrdersModified TT on (OH.PickTicket = TT.EntityKey)

      exec pr_PickBatch_Recalculate @ttPickBatchesModified, 'S' /* Status only */, @UserId;

    end /* if CloseReplenishOrder */
   else
     /* If the action is other then 'OrderPriorityUpdate', send a message to UI saying Unsupported Action*/
     set @Message = 'UnsupportedAction';

  /* Framing result message. */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vOrdersUpdated, @vOrdersCount;

  /* If there are invalid/unqualified orders that were not processed then let user know about it */
  if (@vInvalidOrders > 0)
    select @Message += dbo.fn_Messages_Build('ROModify_InvalidOrders', @vInvalidOrders, null, null, null, null);

  /* Do not close Orders that have LPNs that are not putaway and build the following message */
  if (@vOrdersWithLPNsNotPutaway > 0)
    select @Message += dbo.fn_Messages_Build('ROClose_LPNsNotPutaway', @vOrdersWithLPNsNotPutaway, null, null, null, null);

  /* Identify all the locations for the replenish orders */
  insert into @ttAuditLocations (EntityId, EntityKey )
    select distinct OD.LocationId, OD.Location
    from vwOrderDetails OD
    join @ttOrdersModified OH on (OD.OrderId = OH.EntityId);

  /* Logging AuditTrail for newly created Replenish Order locations */
  exec pr_AuditTrail_Insert @vAuditActivity,
                            @UserId,
                            null /* ActivityTimestamp */,
                            null /* DeviceId */,
                            @BusinessUnit,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Order Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttOrdersModified, @BusinessUnit;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttAuditLocations, @BusinessUnit;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch
  return(coalesce(@ReturnCode, 0));
end /* pr_Replenish_ModifyOrders */

Go
