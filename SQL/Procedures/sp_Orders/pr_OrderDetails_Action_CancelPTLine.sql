/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/10  RKC     pr_OrderDetails_Action_CancelPTLine: Initial Revision (CIMSV3-1500)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderDetails_Action_CancelPTLine') is not null
  drop Procedure pr_OrderDetails_Action_CancelPTLine;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderDetails_Action_CancelPTLine: Used to
   1)Cancel the Order details line or reduce UnitsAuthorizedToShip on the
    selected PickTickets
   2)Send the PTCancel export transactions

   Note: #ttSelectedEntities defined in pr_Entities_ExecuteAction_V3
------------------------------------------------------------------------------*/
Create Procedure pr_OrderDetails_Action_CancelPTLine
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                      TInteger,
          @vMessageName                     TMessageName,
          @vMessage                         TDescription,
          @vRecordId                        TRecordId,
          /* Audit & Response */
          @vAuditActivity                   TActivityType,
          @ttAuditTrailInfo                 TAuditTrailInfo,
          @vAuditRecordId                   TRecordId,
          @vRecordsUpdated                  TCount,
          @vTotalRecords                    TCount,
          /* Input variables */
          @vEntity                          TEntity,
          @vAction                          TAction,
          @vUnitsToAllocate                 TQuantity,
          /* Process variables */
          @vValidStatusesToCancelPTLine     TDescription,
          @vPartialLineCancel               TFlags;

begin /* pr_OrderDetails_Action_CancelPTLine */
  SET NOCOUNT ON;

  select @vReturnCode                   = 0,
         @vMessageName                  = null,
         @vRecordId                     = 0,
         @vAuditActivity                = 'AT_ODModified_PTcancel',
         @vRecordsUpdated               = 0,
         @vValidStatusesToCancelPTLine  = dbo.fn_Controls_GetAsString('CancelPTLine', 'ValidStatuses', 'IWACN'/* InProgress,batched,Allocated,picking, New */, @BusinessUnit, null/* UserId */),
         @vPartialLineCancel            = dbo.fn_Controls_GetAsString('CancelPTLine', 'AllowPartialLineCancel',  'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Create hash table for Recalc */
  create table #EntitiesToRecalc (RecalcRecId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'RecalcCounts', '#EntitiesToRecalc';

  select @vEntity          = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction          = Record.Col.value('Action[1]', 'TAction'),
         @vUnitsToAllocate = nullif(Record.Col.value('(Data/UnitsToAllocate)[1]', 'TQuantity'), 0)
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* insert all the OrderDetails into the # table which are to be updated */
  select OD.OrderDetailId, OD.OrderId, OH.PickTicket, OD.SKUId, OD.SKU, OD.UnitsAuthorizedToShip PrevUnitsToShip,
         OD.UnitsAssigned, OD.UnitsToAllocate, OH.Status OrderStatus,
         'N' ProcessFlag, WD.WaveId, WD.WaveNo, OH.SoldToId, OH.ShipToId, OH.Warehouse, OH.Ownership,
         case when @vAction = 'OrderDetails_CancelRemainingQty' then OD.UnitsToAllocate else OD.UnitsToAllocate - @vUnitsToAllocate end UnitsToCancel,
         row_number() over (order by (select 1)) as RecordId
  into #OrderDetails
  from #ttSelectedEntities ttSE
               join OrderDetails OD on (OD.OrderDetailId = ttSE.EntityId )
    left outer join WaveDetails  WD on (OD.OrderDetailId = WD.OrderDetailId)
               join OrderHeaders OH on (OD.OrderId       = OH.OrderId);

   if (coalesce(@vUnitsToAllocate, 0) = 0) and (@vAction <> 'OrderDetails_CancelRemainingQty')
     select @vMessageName = 'CancelPTLine_NewUnitsToAllocateRequired';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the total no. of Order details that user requested be update */
  select @vTotalRecords = count(*) from #OrderDetails;

  /* Do not allow to cancel the PTLine, if Cancelled Qty is Greaterthan ToAllocate */
  delete from OD
  output 'E', deleted.OrderId, deleted.PickTicket, 'CancelPTLine_NoUnitsToCancel', deleted.SKU
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #OrderDetails OD
  where (coalesce(UnitsToCancel, 0) = 0);

  /* If attempting to cancel more than what is already allocated UnitsToCancel will be -ve
     and we do not want to allow to cancel the PTLine */
  delete from OD
  output 'E', deleted.OrderId, deleted.PickTicket, 'CancelPTLine_CannotCancelAllocatedQty', deleted.SKU, deleted.UnitsToAllocate
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, Value3)
  from #OrderDetails OD
  where (UnitsToCancel < 0);

  /* Some host systems will not allow a line to be cancelled partially and remaining shipped
     so if that is the case, then the line cannot be partially cancelled */
  if (@vPartialLineCancel = 'N')
    delete from OD
    output 'E', deleted.OrderId, deleted.PickTicket, 'CancelPTLine_CannotCancelPartialQty'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
    from #OrderDetails OD
    where (coalesce(OD.PrevUnitsToShip, 0) <> coalesce(OD.UnitsToCancel, 0));

  /* Remove unqualfied entities and insert those into #ResultMessages at the same time */
  delete from OD
  output 'E', deleted.OrderId, deleted.PickTicket, 'CancelPTLine_InvalidOrderStatus', deleted.OrderStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #OrderDetails OD
  where (charindex(OD.OrderStatus, @vValidStatusesToCancelPTLine) = 0);

  /* we have status code in Value2 so updating as StatusDescription */
  update #ResultMessages
  set Value2 = dbo.fn_Status_GetDescription ('Order', Value2, @BusinessUnit)
  where MessageName = 'CancelPTLine_InvalidOrderStatus'

  /* Reduce the UnitsToShip by the cancel amount */
  update OD
  set UnitsAuthorizedToShip -= ttOD.UnitsToCancel
  from OrderDetails OD
    join #OrderDetails ttOD on (OD.OrderDetailId = ttOD.OrderDetailId)

  set @vRecordsUpdated = @@rowcount;

  /* Generate Exports here */
  insert into #ExportRecords (TransType, TransEntity, TransQty, SKUId, OrderId, OrderDetailId, SoldToId, ShipToId, Warehouse, Ownership)
    select 'PTCancel', 'OD', UnitsToCancel, SKUId, OrderId, OrderDetailId, SoldToId, ShipToId, Warehouse, Ownership
    from  #OrderDetails

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'PTCancel' /* TransType */, 'OD' /* TransEntity - Receiver */, @BusinessUnit;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'PickTicket', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, UnitsToCancel, SKU, PickTicket, null, null) /* Comment */
    from #OrderDetails

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  /* Insert the Orders & Waves into #EntitiesToRecalc */
  insert into #EntitiesToRecalc (EntityType, EntityId, EntityKey, RecalcOption, Status, BusinessUnit)
    select distinct 'Order', OrderId, PickTicket, 'CS' /* Counts & Status */, 'N', @BusinessUnit from #OrderDetails
    union all
    select distinct 'Wave', WaveId, WaveNo, 'CS' /* Count & Status */, 'N', @BusinessUnit from #OrderDetails

  /* Process all recalcs to avoid at the end once so that we don't process the same Pallet/Location
     again and again */
  exec pr_Entities_RequestRecalcCounts null /* EntityType */, @RecalcOption = 'DeferAll';

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderDetails_Action_CancelPTLine */

Go
