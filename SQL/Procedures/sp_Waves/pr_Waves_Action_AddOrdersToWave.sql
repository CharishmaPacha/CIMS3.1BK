/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/09  RKC     pr_Waves_Action_AddOrdersToWave: Made changes to update the selected Wave info on #AddOrdersToWave temp table (JLCA-1001)
              SAK     pr_Waves_Action_AddOrdersToWave Initial Revision (CIMSV3-1516)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_AddOrdersToWave') is not null
  drop Procedure pr_Waves_Action_AddOrdersToWave;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_AddOrdersToWave: Adds the given Orders or Order Details
  to the Wave by calling pr_Waves_AddOrders proc
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_AddOrdersToWave
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
          @RecordId                    TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Process variables */
          @vOrderId                    TRecordId,
          @vEntityId                   TRecordId,
          @vWaveNo                     TWaveNo,
          @vWavingLevel                TDescription,
          @vWaveId                     TRecordId,
          @vPickBatchId                TRecordId,
          @vBatchStatus                TStatus,
          @vWaveStatus                 TStatus,
          @vWaveWarehouse              TWarehouse,
          @vWaveOwner                  TOwnership,
          @vPickbatchgroup             TWaveGroup,
          @vWaveGroup                  TWaveGroup,
          @vOrderGroup                 TWaveGroup,
          @vNumOrders                  TCount,
          @vOrderDetailId              TRecordId,
          @vActivity                   TActivityType,
          @vNote1                      TDescription,
          @Message                     TMessage;

  declare @ttOrdersUpdated             TEntityKeysTable;
  declare @ttAddOrdersToWave table (OrderId         TRecordId,
                                    OrderDetailId   TRecordId,
                                    PickTicket      TPickTicket,
                                    OrderStatus     TStatus,
                                    OrderStatusDesc TDescription,
                                    OrderType       TTypeCode,
                                    Warehouse       TWarehouse,
                                    Ownership       TOwnership,
                                    WaveGroup       TWaveGroup,
                                    ProcessStatus   TStatus,
                                    RecordId        TRecordId Identity (1,1));

begin /* pr_Waves_Action_AddOrdersToWave */
  SET NOCOUNT ON;

  select @vReturnCode        = 0,
         @vMessageName       = null,
         @vRecordId          = 0,
         @vAuditActivity     = '',
         @vRecordsUpdated    = 0;

  /* Create Hash tables */
  select * into #AddOrdersToWave from @ttAddOrdersToWave;
  select * into #OrdersToProcess from @ttAddOrdersToWave;

  select @vEntity      = Record.Col.value('Entity[1]',               'TEntity'),
         @vAction      = Record.Col.value('Action[1]',               'TAction'),
         @vWaveNo      = Record.Col.value('(Data/WaveNo)[1]',        'TWaveNo'),
         @vWavingLevel = Record.Col.value('(Data/BatchingLevel)[1]', 'TFlag')
  from @xmlData.nodes('/Root') as Record(Col);

  /* Here WavingLevel may be OH or OD so we need to insert the EntityId into OrderId , OrderDetailId fields */
  insert into #AddOrdersToWave (OrderId, OrderDetailId, ProcessStatus)
    select case when @vWavingLevel = 'OH' then EntityId else null end,
           case when @vWavingLevel = 'OD' then EntityId else null end,
           'ToBeProcessed'
    from #ttSelectedEntities;

  /* Get the Total Records Orders or OrderDetails given by the user */
  select @vTotalRecords = @@rowcount;

  /* If we are processing Order details, get the corresponding Order id */
  if (@vWavingLevel = 'OD')
    update OTW
    set OrderId = OD.OrderId
    from #AddOrdersToWave OTW join OrderDetails OD on OTW.OrderDetailId = OD.OrderDetailId;

  /* get the unique order ids for validations */
  insert #OrdersToProcess (OrderId) select distinct OrderId from #AddOrdersToWave;

  /* fill in the Order info */
  update OTP
  set PickTicket  = OH.PickTicket,
      OrderStatus = OH.Status,
      OrderType   = OH.OrderType,
      Warehouse   = OH.Warehouse,
      Ownership   = OH.Ownership,
      WaveGroup   = OH.PickBatchGroup
  from #OrdersToProcess OTP join OrderHeaders OH on OTP.OrderId = OH.OrderId;

  /* get the required info from Waves */
  select @vWaveId        = RecordId,
         @vWaveNo        = WaveNo,
         @vWaveStatus    = Status,
         @vWaveWarehouse = Warehouse,
         @vWaveOwner     = Ownership,
         @vWaveGroup     = Pickbatchgroup,
         @vNumOrders     = NumOrders
  from Waves
  where (WaveNo       = @vWaveNo) and
        (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vWaveId is null)
    set @vMessageName = 'Wave_AddOrders_WaveIsInvalid';
  else
  if (@vWaveStatus <> 'N' /* New */ )
    select @vMessageName = 'Wave_AddOrders_WaveStatusInvalid',
           @vNote1       = dbo.fn_Status_GetDescription('Wave', @vWaveStatus, @BusinessUnit);
  else
  /* If new batch, then ensure all orders are from same Warehouse. If it is a batch that already has existing
     orders, then we can add whatever orders that match the batch and leave others alone */
  if (@vWaveWarehouse is null) and
     ((select count(distinct Warehouse) from #OrdersToProcess) > 1)
    set @vMessageName = 'Wave_AddOrders_MultipleWarehouses';
  else
  if (@vWaveGroup is null) and
     ((select count(distinct WaveGroup) from #OrdersToProcess) > 1)
    set @vMessageName = 'Wave_AddOrders_MultipleGroups';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vWaveNo, @vNote1;

  /* Get all the required info from OrderHeaders for validations to avoid hitting the OH  table again and again */
  select OTP.OrderId, OTP.PickTicket, OTP.OrderStatus, OTP.OrderType, OTP.Warehouse, @vWaveNo WaveNo,
         case when (OTP.WaveGroup <> @vWaveGroup)                  then 'Wave_AddOrders_WaveGroupMismatch'
              when (OTP.Warehouse <> @vWaveWarehouse)              then 'Wave_AddOrders_WarehouseMismatch'
              when (dbo.fn_IsInList(OTP.OrderStatus, 'N') = 0)     then 'Wave_AddOrders_OrderInvalidStatus'
              when (dbo.fn_IsInList(OTP.OrderType, 'B') > 0)       then 'Wave_AddOrders_BulkOrderNotValid'
              when (dbo.fn_IsInList(OTP.OrderType, 'R,RU,RP') > 0) then 'Wave_AddOrders_ReplenishNotValid'
         end ErrorMessage,
         case when (OTP.WaveGroup <> @vWaveGroup)                  then OTP.WaveGroup
              when (OTP.Warehouse <> @vWaveWarehouse)              then OTP.Warehouse
         end OrderValue,
         case when (OTP.WaveGroup <> @vWaveGroup)                  then @vWaveGroup
              when (OTP.Warehouse <> @vWaveWarehouse)              then @vWaveWarehouse
         end WaveValue
  into #InvalidOrders
  from #OrdersToProcess OTP

  /* Get the status description for the error message */
  update #AddOrdersToWave
  set OrderStatusDesc = dbo.fn_Status_GetDescription('Order', OrderStatus, @BusinessUnit);

  /* Exclude the Orders that are determined to be invalid above. if #AddOrdersToWave has
     orderdetails, then all the details of the invalid orders are removed */
  delete from OTW
  output 'E', IO.OrderId, IO.PickTicket, IO.ErrorMessage, IO.WaveNo, deleted.OrderStatusDesc, IO.OrderValue, IO.WaveValue
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, Value3, Value4, Value5)
  from #AddOrdersToWave OTW join #InvalidOrders IO on OTW.OrderId = IO.OrderId
  where (IO.ErrorMessage is not null);

  /* Add the remaining Orders in #AddOrdersToWave to the wave @vWaveId */
  exec pr_Waves_AddOrders @vWaveId, @vWaveNo, @vWavingLevel, @BusinessUnit, @UserId;

  /* Get the Records update count from #Table  */
  select @vRecordsUpdated = count (*) from #AddOrdersToWave where ProcessStatus = 'Done'

  /* Audit Trails not required here, Already given in pr_Waves_AddOrders */

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction,  @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_AddOrdersToWave */

Go
