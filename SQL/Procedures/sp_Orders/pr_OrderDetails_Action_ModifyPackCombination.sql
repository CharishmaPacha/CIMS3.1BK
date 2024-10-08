/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/25  TK/YJ   pr_OrderDetails_Action_ModifyPackCombination: Ported changes done by TK (HA-2443)
  2021/03/25  RKC     pr_OrderDetails_Action_ModifyPackCombination: Made changes to recalculate the estimated cartons when we modify pack combination
  2020/09/16  MS      pr_OrderDetails_Action_ModifyPackCombination: Added new proc
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_Action_ModifyPackCombination') is not null
  drop Procedure pr_OrderDetails_Action_ModifyPackCombination;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_Action_ModifyPackCombination:
    Action to modify the Packing Group and Pack Qty of the OrderDetails

  UnitsPerCarton can be blank - if so, then we don't change it. If user gives zero
  then we update it to zero.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_Action_ModifyPackCombination
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,
          @vAuditActivity        TActivityType,
          @ttAuditTrailInfo      TAuditTrailInfo,

          @vEntity               TEntity,
          @vAction               TAction,
          @vNewUnitsPerCarton    TQuantity,
          @vNewPackingGroup      TCategory,
          @vNote1                TDescription,
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount;

  declare @ttOrderDetails table
          (OrderId           TRecordId,
           PickTicket        TPickTicket,
           OrderDetailId     TRecordId,
           HostOrderLine     THostOrderLine,
           SKUId             TRecordId,
           SKU               TSKU,
           PackingGroup      TCategory,
           UnitsPerCarton    TQuantity);

  declare @ttOrdersToEstimateCartons  TEntityKeysTable;

begin /* pr_OrderDetails_Action_ModifyPackCombination */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'AT_ODModifyPackCombination';

  select @vEntity            = Record.Col.value('Entity[1]',                       'TEntity'),
         @vAction            = Record.Col.value('Action[1]',                       'TAction'),
         @vNewUnitsPerCarton = Record.Col.value('(Data/UnitsPerCarton)[1]',        'TQuantity'),
         @vNewPackingGroup   = nullif(Record.Col.value('(Data/PackingGroup)[1]',   'TCategory'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Create table #Table with the temp table structure */
  select * into #OrdersToEstimateCartons from @ttOrdersToEstimateCartons;
  alter table #OrdersToEstimateCartons add EstimationMethod  varchar(20);

  /* Get total count from temp table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */
  if (@vNewUnitsPerCarton < 0)
    select @vMessageName = 'OD_ModifyPack_InvalidUnitsPerCarton';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Do not update if wave is already released */
  /* TK_210322: Commented as request by AY during HA-GoLive */
  --delete ttSE
  --output 'E', 'OD_ModifyPack_WaveReleased', OD.OrderId, OD.PickTicket, W.WaveNo, OD.HostOrderLine, OD.SKU
  --into #ResultMessages (MessageType, MessageName, EntityId, Value1, Value2, Value3, Value4)
  --from vwOrderDetails OD
  --  join #ttSelectedEntities ttSE on (OD.OrderDetailId = ttSE.EntityId)
  --  join Waves               W    on (OD.WaveId        = W.WaveId)
  --where (W.Status <> 'N' /* New */);

  /* If PackingGroup & PackQty and existing  PackingGroup & PackQty are same delete them from #table */
  delete ttSE
  output 'I', 'OD_ModifyPack_NoChangeToUpdate', OD.OrderId, OD.HostOrderLine, OD.PackingGroup, OD.UnitsPerCarton
  into #ResultMessages (MessageType, MessageName, EntityId, Value2, Value3, Value4)
  from OrderDetails OD join #ttSelectedEntities ttSE on (OD.OrderDetailId = ttSE.EntityId)
  where (OD.UnitsPerCarton = @vNewUnitsPerCarton) and (OD.PackingGroup = @vNewPackingGroup);

  /* Fill in PT for messages */
  update RM
  set Value1 = OH.PickTicket
  from #ResultMessages RM join OrderHeaders OH on RM.EntityId = OH.OrderId;

  /* Update with PackingGroup & PackQty for remaining orderdetails */
  update OD
  set OD.UnitsPerCarton  = coalesce(@vNewUnitsPerCarton, OD.UnitsPerCarton),
      OD.PackingGroup    = coalesce(@vNewPackingGroup,   OD.PackingGroup),
      OD.ModifiedBy      = @UserId,
      OD.ModifiedDate    = current_timestamp
  output Inserted.OrderId, Inserted.OrderDetailId, Inserted.SKUId, Inserted.HostOrderLine, Inserted.PackingGroup, Inserted.UnitsPerCarton
  into @ttOrderDetails(OrderId, OrderDetailId, SKUId, HostOrderLine, PackingGroup, UnitsPerCarton)
  from OrderDetails OD
    join #ttSelectedEntities SE on (OD.OrderDetailId = SE.EntityId)

  set @vRecordsUpdated = @@rowcount;

  /* Update PT info to log AT */
  update OD
  set OD.PickTicket = OH.PickTicket
  from @ttOrderDetails OD join OrderHeaders OH on (OD.OrderId = OH.OrderId);

  update OD
  set OD.SKU = S.SKU
  from @ttOrderDetails OD join SKUs S on (S.SKUId = OD.SKUId);

  /* Calculate the Estimated cartons on the Order Headers */
  insert into #OrdersToEstimateCartons (EntityId)
    select distinct OrderId from @ttOrderDetails

  /* Invoke proc that updates num cartons on Order Headers table */
  exec pr_OrderHeaders_EstimateCartons @BusinessUnit, @UserId;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'New PackingGroup', @vNewPackingGroup);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'New Pack Qty',     @vNewUnitsPerCarton);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select distinct 'PickTicket', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vNote1, HostOrderLine, SKU, null, null) /* Comment */
    from @ttOrderDetails;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderDetails_Action_ModifyPackCombination */

Go
