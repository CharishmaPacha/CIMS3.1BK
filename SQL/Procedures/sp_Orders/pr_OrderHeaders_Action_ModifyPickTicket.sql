/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/02  SJ      pr_OrderHeaders_Action_ModifyPickTicket: Added Cancel date (OB2-1829)
  2021/03/08  OK      pr_OrderHeaders_Action_ModifyPickTicket: Made changes to all order set status if there is any change in ShipCompletePercent (HA-2095)
  2021/03/06  SAK     pr_OrderHeaders_Action_ModifyPickTicket Added field DesiredShipDate (HA-2138)
  2021/01/06  AJM     pr_OrderHeaders_Action_ModifyPickTicket: Initial Revision (CIMSV3-1296)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_ModifyPickTicket') is not null
  drop Procedure pr_OrderHeaders_Action_ModifyPickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_ModifyPickTicket: This procedure used to change the
    PickTicket on selected orders
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_ModifyPickTicket
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vOrderType                  TOrderType,
          @vShipCompletePercent        TPercent,
          @vPriority                   TPriority,
          @vOwnership                  TOwnership,
          @vCarrierOptions             TDescription,
          @vAESNumber                  TAESNumber,
          @vShipmentRefNumber          TShipmentRefNumber,
          @vDesiredShipDate            TDateTime,
          @vCancelDate                 TDateTime,
          /* Process variables */
          @vValidOrderStatus           TControlValue,
          @vNote1                      TDescription;

  declare @ttOrdersToSetStatus         TEntityKeysTable;

  declare @ttOrdersModified table
          (OrderId              TRecordId,
           PickTicket           TPickTicket,
           OldOwnership         TOwnership,
           NewOwnership         TOwnership,
           RecordId             TRecordId identity(1,1));

begin /* pr_OrderHeaders_Action_ModifyPickTicket */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordsUpdated = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_ModifyPickTicket'

  select @vEntity              = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction              = Record.Col.value('Action[1]', 'TAction'),
         @vOrderType           = Record.Col.value('(Data/OrderType) [1]',                  'TOrderType'),
         @vShipCompletePercent = nullif(Record.Col.value('(Data/ShipCompletePercent) [1]', 'TPercent'), '0'),
         @vPriority            = Record.Col.value('(Data/Priority) [1]',                   'TPriority'),
         @vOwnership           = Record.Col.value('(Data/Ownership) [1]',                  'TOwnership'),
         @vCarrierOptions      = nullif(Record.Col.value('(Data/CarrierOptions) [1]',      'TDescription'),       ''),
         @vAESNumber           = nullif(Record.Col.value('(Data/AESNumber) [1]',           'TAESNumber'),         ''),
         @vShipmentRefNumber   = nullif(Record.Col.value('(Data/ShipmentRefNumber) [1]',   'TShipmentRefNumber'), ''),
         @vDesiredShipDate     = nullif(Record.Col.value('(Data/DesiredShipDate) [1]',     'TDateTime'), ''),
         @vCancelDate          = nullif(Record.Col.value('(Data/CancelDate) [1]',          'TDateTime'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vValidOrderStatus =  dbo.fn_Controls_GetAsString('ModifyOrder', 'ValidOrderStatus', 'ONIAWCPKRGL' /* Statuses other than Cancelled, Shipped */, @BusinessUnit, null/* UserId */);

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select * into #OrdersModified from @ttOrdersModified;

  /* Validations */

  /* Cannot modify PickTicket which have ordertype Bulk Pull */
  delete ttSE
  output 'E', 'ModifyPickTicket_InvalidOrderType', OH.PickTicket
  into #ResultMessages(MessageType, MessageName, Value1)
  from OrderHeaders OH join #ttSelectedEntities ttSE on (OH.OrderId = ttSE.EntityId)
  where (OH.OrderType = 'B' /* Bulk Pull */);

  /* Cannot modify PickTicket which have invalid status */
  delete ttSE
  output 'E', 'ModifyPickTicket_InvalidOrderStatus', OH.PickTicket, OH.StatusDescription
  into #ResultMessages(MessageType, MessageName, Value1, Value2)
  from vwOrderHeaders OH join #ttSelectedEntities ttSE on (OH.OrderId = ttSE.EntityId)
  where (charindex(OH.Status, @vValidOrderStatus) = 0)

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Update the remaining orders */
  update OH
  set OrderType           = coalesce(@vOrderType,           OH.OrderType),
      ShipCompletePercent = coalesce(@vShipCompletePercent, OH.ShipCompletePercent),
      Priority            = coalesce(@vPriority,            OH.Priority),
      Ownership           = coalesce(@vOwnership,           OH.Ownership),
      AESNumber           = coalesce(@vAESNumber,           OH.AESNumber),
      ShipmentRefNumber   = coalesce(@vShipmentRefNumber,   OH.ShipmentRefNumber),
      CarrierOptions      = coalesce(@vCarrierOptions,      OH.CarrierOptions),
      DesiredShipDate     = coalesce(@vDesiredShipDate,     OH.DesiredShipDate),
      CancelDate          = coalesce(@vCancelDate,          OH.CancelDate)
  output inserted.OrderId, inserted.PickTicket, inserted.Ownership, deleted.Ownership
  into #OrdersModified(OrderId, PickTicket, NewOwnership, OldOwnership)
  from OrderHeaders OH
    join #ttSelectedEntities ttSE on (OH.OrderId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* Update Ownership of LPN for PickTicket that have changed Ownership */
  update L
  set Ownership    = @vOwnership,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  from LPNs L
    join @ttOrdersModified OM on (L.OrderId = OM.OrderId)
  where (OM.OldOwnership <> OM.NewOwnership);

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Order Type',          @vOrderType);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Ship Complete %',     @vShipCompletePercent);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Priority',            @vPriority);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Ownership',           @vOwnership);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Insurance',           @vCarrierOptions);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'AES Number',          @vAESNumber);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Shipment Ref Number', @vShipmentRefNumber);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'PickTicket', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vNote1, null, null, null, null) /* Comment */
    from #OrdersModified;

  /* If there is any change in order ship complete then reevalaute the order status */
  if ((coalesce(@vShipCompletePercent, 0) <> 0) and exists(select * from #OrdersModified))
    begin
      insert into @ttOrdersToSetStatus (EntityId, ENtityKey)
        select OrderId, PickTicket
        from #OrdersModified;

      exec pr_OrderHeaders_Recalculate @ttOrdersToSetStatus, 'S', @UserId, @BusinessUnit;
    end

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_ModifyPickTicket */

Go
