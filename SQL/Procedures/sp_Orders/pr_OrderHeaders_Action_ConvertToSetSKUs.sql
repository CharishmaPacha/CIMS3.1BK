/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/29  RV      pr_OrderHeaders_Action_ConvertToSetSKUs: Intial revision (OB2-1948)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_ConvertToSetSKUs') is not null
  drop Procedure pr_OrderHeaders_Action_ConvertToSetSKUs;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_ConvertToSetSKUs: This procedure used to convert to the
    possible set SKUs from the components on selected orders
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_ConvertToSetSKUs
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Process variables */
          @vValidOrderStatus           TControlValue,
          @vValidLPNStatus             TControlValue,
          @vOrderId                    TRecordId;

  declare @ttOrdersToConvertSetSKUs table
          (OrderId        TRecordId,
           PickTicket     TPickTicket,
           OrderType      TTypeCode,
           OrderStatus    TStatus,
           OrderDetailId  TRecordId,
           ODLineType     TTypeCode,

           LPNId          TRecordId,
           LPN            TLPN,
           LPNType        TTypeCode,
           LPNStatus      TStatus,
           LDOnhandStatus TStatus,

           RecordId       TRecordId identity(1,1));

  declare @ttODsToConvertSetSKUs TOrderDetailsToConvertSetSKUs;
  declare @ttLPNsToConvertSets   TEntityKeysTable;

begin /* pr_OrderHeaders_Action_ConvertToSetSKUs */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordsUpdated = 0,
         @vRecordId       = 0;

  /* Read input xml */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get Controls */
  select @vValidOrderStatus = dbo.fn_Controls_GetAsString('ConvertToSetSKUs', 'ValidOrderStatus', 'PKSL' /* Picked, Packed, Staged, Loaded */, @BusinessUnit, @UserId);
  select @vValidLPNStatus   = dbo.fn_Controls_GetAsString('ConvertToSetSKUs', 'ValidLPNStatus', 'KGDEL' /* Picked, Packing, Packed, Staged, Loaded */, @BusinessUnit, @UserId);

  /* Get total selected records count */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  if (object_id('tempdb..#OrdersToConvertSetSKUs') is null) select * into #OrdersToConvertSetSKUs from @ttOrdersToConvertSetSKUs;
  if (object_id('tempdb..#ODsToConvertSetSKUs') is null)    select * into #ODsToConvertSetSKUs from @ttODsToConvertSetSKUs;
  if (object_id('tempdb..#LPNsToConvertSets') is null)      select * into #LPNsToConvertSets from @ttLPNsToConvertSets;

  /* For the selected Orders, get all the OrderDetails that could possibly be converted i.e.
     Picked LPNs */
  insert into #OrdersToConvertSetSKUs (OrderId, PickTicket, OrderType, OrderStatus, OrderDetailId, ODLineType,
                                       LPNId, LPN, LPNType, LPNStatus, LDOnhandStatus)
    select OH.OrderId, OH.PickTicket, OH.OrderType, OH.Status, OD.OrderDetailId, OD.LineType,
           L.LPNId, L.LPN, L.LPNType, L.Status, LD.OnhandStatus
    from #ttSelectedEntities SE
      join OrderHeaders OH on (OH.OrderId = SE.EntityId)
      join OrderDetails OD on (OH.OrderId = OD.OrderId) and (OD.LineType = 'C' /* Component */)
      join LPNDetails LD on (LD.OrderDetailId = OD.OrderDetailId) and (LD.OnhandStatus = 'R' /* Reserve */)
      join LPNs L on (L.LPNId = LD.LPNId) and
                     (dbo.fn_IsInList(L.LPNType, 'L') = 0) and
                     (dbo.fn_IsInList(L.Status, @vValidLPNStatus) > 0);

  /* Validations */

  delete from OTC
  output 'E', deleted.OrderId, deleted.PickTicket, 'OrderHeader_ConvertToSetSKUs_InvalidOrderType', deleted.OrderType
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #OrdersToConvertSetSKUs OTC
  where (OTC.OrderType in ('B' /* Bulk Pull */, 'R', 'RP', 'RU'));

  delete from OTC
  output 'E', deleted.OrderId, deleted.PickTicket, 'OrderHeader_ConvertToSetSKUs_InvalidOrderStatus', deleted.OrderStatus
  into #ResultMessages(MessageType, EntityId, EntityKey, MessageName, Value2)
  from #OrdersToConvertSetSKUs OTC
  where (dbo.fn_IsInList(OTC.OrderStatus, @vValidOrderStatus) = 0);

  /* we have status code in Value2 so updating as StatusDescription */
  update #ResultMessages
  set Value2 = case when (MessageName = 'OrderHeader_ConvertToSetSKUs_InvalidOrderType')
                      then dbo.fn_EntityTypes_GetDescription('Order', Value2, @BusinessUnit)
                    when (MessageName = 'OrderHeader_ConvertToSetSKUs_InvalidOrderStatus')
                      then dbo.fn_Status_GetDescription ('Order', Value2, @BusinessUnit)
                    else Value2
               end,
      Value3 = case when (MessageName = 'OrderHeader_ConvertToSetSKUs_InvalidLPNType')
                      then dbo.fn_EntityTypes_GetDescription('LPN', Value3, @BusinessUnit)
                    when (MessageName = 'OrderHeader_ConvertToSetSKUs_InvalidLPNStatus')
                      then dbo.fn_Status_GetDescription ('LPN', Value3, @BusinessUnit)
                    else Value2
               end

  insert into #LPNsToConvertSets(EntityId, EntityKey)
    select distinct LPNId, LPN
    from #OrdersToConvertSetSKUs
    where (LPNId is not null);

  if exists (select * from #LPNsToConvertSets)
    exec pr_LPNs_ConvertToSetSKUs default, @BusinessUnit, @UserId;

  /* Get the orders, which are converted */
  select @vRecordsUpdated = count(distinct OrderId)
  from #ODsToConvertSetSKUs
  where (LineType = 'S' /* Sets */) and (KitsToConvert > 0);

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_ConvertToSetSKUs */

Go
