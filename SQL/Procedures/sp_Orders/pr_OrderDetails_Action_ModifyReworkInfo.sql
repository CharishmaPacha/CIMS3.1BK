/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/09  AJM     pr_OrderDetails_Action_ModifyReworkInfo: Added condition to log PT info in AT (CIMSV3-1433)
  2020/08/25  AJM     pr_OrderDetails_Action_ModifyReworkInfo : New procedure (HA-1059)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_Action_ModifyReworkInfo') is not null
  drop Procedure pr_OrderDetails_Action_ModifyReworkInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_Action_ModifyReworkInfo: Action to modify the NewSKU and
    New Labelcode for Rework Orders
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_Action_ModifyReworkInfo
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,

          @vEntity                     TEntity,
          @vAction                     TAction,
          @vSKU                        TSKU,
          @vNewSKUId                   TRecordId,
          @vNewSKU                     TSKU,
          @vInventoryClass1            TInventoryClass,
          @vNewInventoryClass1         TInventoryClass,
          @vNewIC1RecordId             TRecordId,
          @vNote1                      TDescription,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount;

  declare @ttOrderDetails table
          (OrderDetailId             TRecordId,
           WaveId                    TRecordId,
           WaveNo                    TWaveNo,
           OrderId                   TRecordId,
           PickTicket                TPickTicket,
           SKUId                     TRecordId,
           NewSKUId                  TRecordId,
           InventoryClass1           TInventoryClass,
           NewInventoryClass1        TInventoryClass,
           OrderLine                 TDetailLine,
           SKU                       TSKU,
           HostOrderLine             THostOrderLine,
           PrevUnitsToShip           TQuantity,
           PrevUnitsOrdered          TQuantity,
           PrevOrderStatus           TStatus,
           UnitsToCancel             TQuantity,
           ProcessFlag               TFlag,
           Status                    TStatus,
           ReasonCode                TMessageName,
           Reason                    TMessage);

begin /* pr_OrderDetails_Action_ModifyReworkInfo */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'AT_ODModifyReworkInfo';

  select @vEntity              = Record.Col.value('Entity[1]',                    'TEntity'),
         @vAction              = Record.Col.value('Action[1]',                    'TAction'),
         @vNewSKU              = nullif(Record.col.value('(Data/NewSKU)[1]',             'TSKU'), ''),
         @vNewInventoryClass1  = nullif(Record.Col.value('(Data/NewInventoryClass1)[1]', 'TInventoryClass'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Get total count from temp table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get SKU Info */
  select @vNewSKUId = SKUId,
         @vNewSKU   = SKU
  from dbo.fn_SKUs_GetScannedSKUs (@vNewSKU, @BusinessUnit)
  where (Status = 'A'/* Active */)

  /* Validations */
  if (@vNewSKU is not null) and (@vNewSKUId is null)
    set @vMessageName = 'SKUIsInvalid';
  else
  if (@vNewInventoryClass1 is not null) and
     (dbo.fn_IsValidLookUp('InventoryClass1', @vNewInventoryClass1, @BusinessUnit, null) is not null)
    set @vMessageName = 'InventoryClass1IsInvalid';
  else
  if ((@vNewSKU is null) and (@vNewInventoryClass1 is null))
    set @vMessagename = 'ODModifyReworkInfo_SKUOrICRequired';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If NewSKU & NewInventoryClass1 and existing order SKU & InventoryClass1 are same delete them from #table */
  delete ttSE
  output 'I', 'ODModifyReworkInfo_SameSKU&InvClass', OD.HostOrderLine, OD.SKUId
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from OrderDetails OD join #ttSelectedEntities ttSE on (OD.OrderDetailId = ttSE.EntityId)
  where (OD.NewSKU = @vNewSKU) and (OD.NewInventoryClass1 = @vNewInventoryClass1); /* Should not update if Prev and selected SKU is same */

  /* Update with NewSKU & NewInventoryclass1 of remaining orders */
  update OD
  set NewSKU             = coalesce(@vNewSKU,             NewSKU),
      NewInventoryClass1 = coalesce(@vNewInventoryClass1, NewInventoryClass1)
  output Inserted.OrderId, Inserted.OrderDetailId, Inserted.SKUId
  into @ttOrderDetails(OrderId, OrderDetailId, SKUId)
  from OrderDetails OD
    join #ttSelectedEntities SE on (OD.OrderDetailId = SE.EntityId)
  where (OD.UnitsAssigned = 0);

  set @vRecordsUpdated = @@rowcount;

  /* Update PT info to log AT */
  update OD
  set OD.PickTicket = OH.PickTicket
  from @ttOrderDetails OD join OrderHeaders OH on (OD.OrderId = OH.OrderId);

  /* Get the SKU for the AT */
  update TOD
  set TOD.SKU = S.SKU
  from @ttOrderDetails TOD join SKUs S on TOD.SKUId = S.SKUId;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'New SKU',             @vNewSKU);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'New Inventory Class', @vNewInventoryClass1);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select distinct 'PickTicket', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, SKU, @vNote1, HostOrderLine, null, null) /* Comment */
    from @ttOrderDetails;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderDetails_Action_ModifyReworkInfo */

Go
