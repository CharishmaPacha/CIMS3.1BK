/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/26  OK      pr_OrderHeaders_DisQualifiedOrders: Changes to recount the order before evaluating (BK-671)
  2021/08/18  VS      pr_OrderHeaders_DisQualifiedOrders, pr_OrderHeaders_Modify, pr_OrderHeaders_UnWaveOrders:
  2020/03/17  TK      pr_OrderHeaders_DisQualifiedOrders: Fix to resolve unique key constraint error while same SKU is repeated twice for an order (S2GCA-1110)
  2019/02/14  RIA     pr_OrderHeaders_DisQualifiedOrders: Changes to add Audit Log (S2G-1204)
  2018/08/14  RV      pr_OrderHeaders_DisQualifiedOrders: Implemented rules to UnWave disqualified orders (OB2-553)
                      pr_OrderHeaders_DisQualifiedOrders: Inital Revision (S2G-530)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_DisQualifiedOrders') is not null
  drop Procedure pr_OrderHeaders_DisQualifiedOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_DisQualifiedOrders: This proc evaluates all the orders and
    returns dataset of disqualified orders
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_DisQualifiedOrders
  (@OrdersToEvaluate      TEntityKeysTable  ReadOnly,
   @OrderId               TRecordId     = null,
   @WaveId                TRecordId     = null,
   @Operation             TOperation    = null,
   @BusinessUnit          TBusinessUnit = null,
   @UserId                TUserId       = null)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @vRecordId                TRecordId,
          @vOrderId                 TRecordId,
          @vIsQualified             TFlag,
          @vOrderDetailId           TRecordId,
          @vSKUId                   TRecordId,
          @vUnitsOrdered            TQuantity,
          @vUnitsAssigned           TQuantity,
          @vShipCompleteThreshold   TControlValue,

          @xmlRulesData             TXML;

  declare @ttOrdersToEvaluate    TEntityKeysTable,
          @ttAuditInfo           TAuditTrailInfo,
          @ttDisQualifiedOrders  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  /* Get all the Orders which needs to Evaluated */
  if exists(select * from @OrdersToEvaluate)
    insert into @ttOrdersToEvaluate(EntityId)
      select EntityId
      from @OrdersToEvaluate;
  else
  if (@OrderId is not null)
    insert into @ttOrdersToEvaluate(EntityId)
      select @OrderId;
  else
  if (@WaveId is not null)
    insert into @ttOrdersToEvaluate(EntityId)
      select OrderId
      from OrderHeaders
      where (PickBatchId = @WaveId);

  /* Recount order before evalauting so that OH.UnitsAssigned will be updated properly */
  exec pr_OrderHeaders_Recalculate @ttOrdersToEvaluate, 'C'/* Recount */, @UserId, @BusinessUnit;

  /* Get additional info for Orders to be evaluated */
  select OTE.EntityId, OH.PickTicket as EntityKey, OH.UnitsAssigned, OH.ShipCompletePercent, OH.FillRatePercent,
         'Y' as IsOrderQualified
  into #OrdersToEvaluate
  from @ttOrdersToEvaluate OTE
    join OrderHeaders OH on OH.OrderId = OTE.EntityId;

  /* Get controls */
  select @vShipCompleteThreshold = dbo.fn_Controls_GetAsString('PickTicket', 'ShipCompleteThreshold', '365' /* 365 days */, @BusinessUnit, @UserId);

   /* Build the Rules xml */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('ShipCompleteThreshold', @vShipCompleteThreshold) +
                           dbo.fn_XMLNode('Operation',             @Operation));

 /* Evaluate whether the Order Id qualify or not */
  exec pr_RuleSets_Evaluate 'OrderQualification' /* RuleSetType */, @xmlRulesData, @vIsQualified output;

  /* If the Order is not qualified - most likely because it isn't completely allocated,
     we would need to log the details in AT so that users know which SKUs they are short of
     This is done only when about to unwave disqualified orders as this procedure could be
     used in shipping and other places as well */
  if (@Operation = 'UnwaveDisQualifiedOrders')
    begin
      /* Build the Audit Trail with partially allocated Order details */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType,
                                Comment, UDF1, BusinessUnit, UserId)
        select 'PickTicket', DOH.EntityId, DOH.EntityKey, 'OrderDisqualified' /* Audit Activity */,
               dbo.fn_Messages_Build('AT_OrderDisqualified_PartiallyAllocated', S.SKU, OD.UnitsAssigned, OD.UnitsAuthorizedToShip, null, null) /* Comment */,
               OD.OrderDetailId, @BusinessUnit, @UserId   -- Included OrderDetailId to avoid unique key constraint error when same SKU is repeated twice for an Order
        from #OrdersToEvaluate DOH
          join OrderDetails OD on (OD.OrderId = DOH.EntityId)
          join SKUs S on (S.SKUId = OD.SKUId)
        where (DOH.IsOrderQualified = 'N') and
              (OD.UnitsAuthorizedToShip <> OD.UnitsAssigned);

        /* AT to log the unwaved OrderDetails */
        exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end /* If Disqualified Order */

  /* Return all disqualified orders */
  select EntityId, EntityKey from #OrdersToEvaluate where IsOrderQualified = 'N' /* DisQualified Orders */;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_DisQualifiedOrders */

Go
