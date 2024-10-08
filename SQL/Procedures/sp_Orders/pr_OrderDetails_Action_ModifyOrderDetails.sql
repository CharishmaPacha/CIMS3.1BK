/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/16  VM      pr_OrderDetails_Action_ModifyOrderDetails: Added (CIMSV3-1515)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_Action_ModifyOrderDetails') is not null
  drop Procedure pr_OrderDetails_Action_ModifyOrderDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_Action_ModifyOrderDetails: Update the UnitsAuthorizedToShip
    on the selected Order details
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_Action_ModifyOrderDetails
  (@xmlData        xml,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @ResultXML      TXML           = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,
          /* Audit & Response */
          @vAuditActivity         TActivityType,
          @ttAuditTrailInfo       TAuditTrailInfo,
          @vAuditRecordId         TRecordId,
          @vRecordsUpdated        TCount,
          @vTotalRecords          TCount,
          /* Input variables */
          @vEntity                TEntity  = 'OrderDetail',
          @vAction                TDescription,
          @vUnitsOrdered          TQuantity,
          @vUnitsToShip           TQuantity,
          /* Process variables */
          @vOrderId               TRecordId,
          @vNewOrderStatus        TStatus,

          @vNote1                 TDescription,
          @vNote2                 TDescription;

  declare @OrderDetailsModified table (OrderId                   TRecordId,
                                       OrderDetailId             TRecordId,
                                       SKUId                     TRecordId,
                                       HostOrderLine             THostOrderLine,
                                       OldUnitsOrdered           TQuantity,
                                       NewUnitsOrdered           TQuantity,
                                       OldUnitsAuthorizedToShip  TQuantity,
                                       NewUnitsAuthorizedToShip  TQuantity,
                                       RecordId                  TRecordId Identity(1,1));

  declare @OrdersModified table (OrderId    TRecordId,
                                 PickTicket TPickTicket,
                                 WaveId     TRecordId,
                                 WaveNo     TWaveNo,
                                 RecordId   TRecordId Identity(1,1));

  declare @WavesToRecalculate TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordsUpdated = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vAuditActivity  = 'AT_ODModifyOrderDetails',
         @vNote1          = '';

  /* Get the Entity, Action and other details from the xml */
  select @vEntity          = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction          = Record.Col.value('Action[1]', 'TAction'),
         @vUnitsToShip     = nullif(Record.Col.value('(Data/UnitsAuthorizedToShip)[1]', 'TQuantity'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get number of Orders selected */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */
  if (@vUnitsToShip is null)
  select @vMessageName = 'OD_ModifyDetails_UnitsToShipIsRequired';


  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Create hash tables */
  select * into #OrderDetailsModified from @OrderDetailsModified;
  select * into #OrdersModified from @OrdersModified;

  /* Get all the required info from OrderDetails for validations to avoid hitting the table/view again and again */
  select OD.OrderDetailId, OD.OrderId, OD.PickTicket, OD.HostOrderLine, OD.SKU, OD.OrderStatusDesc,
  case when (OD.UnitsAssigned > coalesce(@vUnitsToShip, OD.UnitsAuthorizedToShip))                          then 'OD_ModifyDetails_UnitsAssignedGreaterThanToShip'
       when (coalesce(@vUnitsToShip, OD.UnitsAuthorizedToShip) > coalesce(@vUnitsOrdered, OD.UnitsOrdered)) then 'OD_ModifyDetails_ToShipGreaterThanUnitsOrdered'
       when (OD.Status in ('S', 'X', 'D'  /* Shipped, Cancelled, Completed */))                             then 'OD_ModifyDetails_OrderStatusIsInvalid'
  end ErrorMessage
  into #InvalidOrderDetails
  from #ttSelectedEntities SE join vwOrderDetails OD on (SE.EntityId = OD.OrderDetailId);

  /* Exclude the Order Details that are invalid to modify */
  delete from SE
  output 'E', IOD.OrderId, IOD.PickTicket, IOD.ErrorMessage, IOD.HostOrderLine, IOD.SKU, IOD.OrderStatusDesc
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, Value3, Value4)
  from #ttSelectedEntities SE join #InvalidOrderDetails IOD on (SE.EntityId = IOD.OrderDetailId)
  where (IOD.ErrorMessage is not null);

  /* Update the remaining order details */
  update OD
  set OD.UnitsAuthorizedToShip = coalesce(@vUnitsToShip,  OD.UnitsAuthorizedToShip),
      OD.ModifiedBy            = @UserId,
      OD.ModifiedDate          = current_timestamp
  output inserted.OrderId, inserted.OrderDetailId, inserted.SKUId, deleted.UnitsOrdered, inserted.UnitsOrdered,
         deleted.UnitsAuthorizedToShip, inserted.UnitsAuthorizedToShip
  into #OrderDetailsModified(OrderId, OrderDetailId, SKUId, OldUnitsOrdered, NewUnitsOrdered,
                             OldUnitsAuthorizedToShip, NewUnitsAuthorizedToShip)
  from OrderDetails OD
    join #ttSelectedEntities ttSE on (OD.OrderDetailId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* If no Order Details updated then return */
  if (@vRecordsUpdated = 0) goto BuildMessage;

  /* Capture all distinct orders modified, to do more updates on OH */
  insert into #OrdersModified (OrderId, PickTicket, WaveId, WaveNo)
    select distinct OH.OrderId, OH.PickTicket, OH.PickBatchId, OH.PickBatchNo
    from #OrderDetailsModified ODM
      join OrderHeaders OH on (OH.OrderId = ODM.OrderId);

  /* Loop through all distinct orders of Order details, to do required updates */
  while exists(select * from #OrdersModified where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId   = RecordId,
                   @vOrderId    = OrderId
      from #OrdersModified
      where RecordId > @vRecordId
      order by RecordId;

      /* Recount Order Headers */
      exec pr_OrderHeaders_Recount @vOrderId, default /* PickTicket */, @vNewOrderStatus output;

      /* If the order is now shipped, then do the afterclose */
      if (charindex(@vNewOrderStatus, 'SDX' /* Shipped, Completed or Canceled */) <> 0)
        exec pr_OrderHeaders_AfterClose @vOrderId, default /* Order Type */, default /* Status */, default /* LoadId */,
                                        @BusinessUnit, @UserId, 'Y'/* GenerateExports */, 'ModifyOrderDetails'/* Operation */;

    end

  /* Get the waves on modified orders to recalculate counts and statuses */
  insert into @WavesToRecalculate(EntityId, EntityKey) select distinct WaveId, WaveNo from #OrdersModified;
  if (@@rowcount > 0)
    exec pr_PickBatch_Recalculate @WavesToRecalculate, '$CS' /* Counts & Status */, @UserId, @BusinessUnit;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Units to Ship', @vUnitsToShip);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'PickTicket', ODM.OrderId, OM.PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, OM.PickTicket, S.SKU, @vNote1, null, null) /* Comment */
    from #OrderDetailsModified ODM
      join #OrdersModified OM on (OM.OrderId = ODM.OrderId)
      join SKUs S             on (S.SKUId    = ODM.SKUId);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

BuildMessage:
  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderDetails_Action_ModifyOrderDetails */

Go
