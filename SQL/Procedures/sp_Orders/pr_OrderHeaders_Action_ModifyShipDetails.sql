/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/06/23  GAG     pr_OrderHeaders_Action_ModifyShipDetails: Consider PreProcessError as well (OBV3-1559)
  2022/05/17  GAG     pr_OrderHeaders_Action_ModifyShipDetails: Modified to Show Previous Values (OBV3-637)
  2022/04/28  SRP/MS  pr_OrderHeaders_Action_ModifyShipDetails: Changes to set value to null if user selected mutiple records (OBV3-559)
  2021/06/09  VM      pr_OrderHeaders_Action_ModifyShipDetails: Converted to complete v3 model action procedure (OB2-1887)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_ModifyShipDetails') is not null
  drop Procedure pr_OrderHeaders_Action_ModifyShipDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_ModifyShipDetails: Updates the shipping info on the
   selected Orders
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_ModifyShipDetails
  (@xmlData        xml,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @ResultXML      TXML           = null output)
as
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
          @vEntity                     TEntity  = 'Order',
          @vAction                     TDescription,
          @vShipVia                    TShipVia,
          @vBillToAccount              TBillToAccount,
          @vFreightTerms               TDescription,
          @vFreightCharges             TMoney,
          @vDesiredShipDate            TDateTime,
          @vOrderCategory1             TOrderCategory,

          @vNote1                      TDescription,
          @vNote2                      TDescription,

          @vValidStatuses              TControlValue,
          @vPreprocessOnShipViaChange  TControlValue;

  declare @ttOrdersShipViaModified table (OrderId             TRecordId,
                                          PickTicket          TPickTicket,
                                          IsOldShipViaSPG     TFlag,
                                          IsNewShipViaSPG     TFlag,
                                          OldShipVia          TShipVia,
                                          NewShipVia          TShipVia,
                                          OldBillToAccount    TBillToAccount,
                                          NewBillToAccount    TBillToAccount,
                                          OldFreightTerms     TDescription,
                                          NewFreightTerms     TDescription,
                                          OldFreightCharges   TDescription,
                                          NewFreightCharges   TDescription,
                                          OldDesiredShipDate  TDescription,
                                          NewDesiredShipDate  TDescription,
                                          OldOrderCategory1   TDescription,
                                          NewOrderCategory1   TDescription,
                                          Note                TVarchar  default '',
                                          RecordId            TRecordId Identity(1,1));
begin
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordsUpdated = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_OrderShipDetailsModify',
         @vNote1          = '';

  /* Get the Entity, Action and other details from the xml */
  select @vEntity             = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction             = Record.Col.value('Action[1]', 'TAction'),
         @vShipVia            = Record.Col.value('(Data/ShipVia)[1]',                'TShipVia'),
         @vBillToAccount      = Record.Col.value('(Data/BillToAccount)[1]',          'TBillToAccount'),
         @vFreightTerms       = Record.Col.value('(Data/FreightTerms)[1]',           'TDescription'),
         @vFreightCharges     = nullif(Record.Col.value('(Data/FreightCharges)[1]',  'TMoney'),    '0'),
         @vDesiredShipDate    = nullif(Record.Col.value('(Data/DesiredShipDate)[1]', 'TDateTime'), ''),
         @vOrderCategory1     = Record.Col.value('(Data/OrderCategory1)[1]',         'TOrderCategory')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vValidStatuses             = dbo.fn_Controls_GetAsString('ModifyShipDetails', 'ValidOrderStatus', 'O,N,I,A,W,C,P' /* Downloaded, New, InProgress, Allocated, Waved, Picking, Picked */, @BusinessUnit, @UserId),
         @vPreprocessOnShipViaChange = dbo.fn_Controls_GetAsString('ModifyShipDetails', 'PreprocessOnShipViaChange', 'N' /* No */, @BusinessUnit, @UserId);

  select @vShipVia        = nullif(Trim(@vShipVia),        '$MULTIPLE$'),
         @vFreightTerms   = nullif(Trim(@vFreightTerms),   '$MULTIPLE$'),
         @vOrderCategory1 = nullif(Trim(@vOrderCategory1), '$MULTIPLE$');

  /* Get number of Orders selected */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */
  /* Check if the ShipVia is passed or not */
  if (@vShipVia is null) and (@vBillToAccount is null) and (@vFreightTerms is null) and
     (@vFreightCharges is null) and (@vDesiredShipDate is null) and (@vOrderCategory1 is null)
    set @vMessageName = 'ModifyOrder_AnyOfTheShipDetailRequired';
  else
  /* Also, need to check if the user is selecting the ShipVia and check if the ShipVia is Active or not */
  if (@vShipVia is not null) and
     (not exists(select * from ShipVias
                 where (ShipVia = @vShipVia) and
                       (Status  = 'A' /* Active */ )))
    set @vMessageName = 'ShipViaIsInactive';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the invalid records into a hash table. This is to get all key values and errors at once for performance reasons */
  select OH.OrderId, OH.PickTicket, cast(OH.Status as varchar(30)) as OrderStatus,
         case when (dbo.fn_IsInList(OH.Status, @vValidStatuses) = 0)                           then 'ModifyOrder_InvalidOrderStatus'
              when (coalesce(W.WCSStatus, '') in ('Exported to WSS', 'Released To WSS')) then 'ModifyOrder_AlreadySentToWSS'
         end ErrorMessage
  into #InvalidOrders
  from #ttSelectedEntities SE
                  join OrderHeaders OH on (SE.EntityId = OH.OrderId)
       left outer join Waves         W on (W.WaveId    = OH.PickBatchId);

  /* Get the status description for the error message */
  update #InvalidOrders
  set OrderStatus = dbo.fn_Status_GetDescription('Order', OrderStatus, @BusinessUnit);

  /* Exclude the Orders that are not valid */
  delete from SE
  output 'E', IL.OrderId, IL.PickTicket, IL.ErrorMessage, IL.OrderStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE join #InvalidOrders IL on SE.EntityId = IL.OrderId
  where (IL.ErrorMessage is not null);

  /* This #table OnChangeShipDetails procedure to update */
  select * into #OrdersShipDetailsModified from @ttOrdersShipViaModified;

  /* Update the remaining orders */
  update OH
  set ShipVia         = coalesce(@vShipVia,       OH.ShipVia      ),
      PreprocessFlag  = case when (OH.ShipVia <> coalesce(@vShipVia, OH.ShipVia)) and (@vPreprocessOnShipViaChange = 'Y'/* Yes */)
                               then 'N'/* N - Preprocess Orders */
                             else PreprocessFlag
                        end,
      BillToAccount   = coalesce(@vBillToAccount,   OH.BillToAccount),
      FreightTerms    = coalesce(@vFreightTerms,    OH.FreightTerms),
      FreightCharges  = coalesce(@vFreightCharges,  OH.FreightCharges),
      DesiredShipDate = coalesce(@vDesiredShipDate, OH.DesiredShipDate),
      OrderCategory1  = coalesce(@vOrderCategory1,  OH.OrderCategory1),
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  output inserted.OrderId, inserted.PickTicket, deleted.ShipVia, inserted.ShipVia,
         deleted.BillToAccount, inserted.BillToAccount, deleted.FreightTerms, inserted.FreightTerms,
         deleted.FreightCharges, inserted.FreightCharges, deleted.DesiredShipDate, inserted.DesiredShipDate,
         deleted.OrderCategory1, inserted.OrderCategory1
  into #OrdersShipDetailsModified(OrderId, PickTicket, OldShipVia, NewShipVia, OldBillToAccount, NewBillToAccount,
                                  OldFreightTerms, NewFreightTerms, OldFreightCharges, NewFreightCharges,
                                  OldDesiredShipDate, NewDesiredShipDate, OldOrderCategory1, NewOrderCategory1)
  from OrderHeaders OH
    join #ttSelectedEntities ttSE on (OH.OrderId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* If ship via or bill to account or freight terms have changed on the order,
     then there are consequences - labels may need to be voided, regenerated etc.
     so do the subsequent updates */
  exec pr_OrderHeaders_OnChangeShipDetails @BusinessUnit, @UserId, @ResultXML output;

  /* Build the note with the change in values for each field */
  update #OrdersShipDetailsModified set Note = coalesce(Note, '');
  update #OrdersShipDetailsModified set Note = concat_ws(', ',
                                                 dbo.fn_ChangeInValue('ShipVia',          OldShipVia,         NewShipVia,         default, @BusinessUnit, @UserId),
                                                 dbo.fn_ChangeInValue('BillToAccount',    OldBillToAccount,   NewBillToAccount,   default, @BusinessUnit, @UserId),
                                                 dbo.fn_ChangeInValue('FreightTerms',     OldFreightTerms,    NewFreightTerms,    default, @BusinessUnit, @UserId),
                                                 dbo.fn_ChangeInValue('FreightCharges',   OldFreightCharges,  NewFreightCharges,  default, @BusinessUnit, @UserId),
                                                 dbo.fn_ChangeInValue('DesiredShipDate',  OldDesiredShipDate, NewDesiredShipDate, default, @BusinessUnit, @UserId),
                                                 dbo.fn_ChangeInValue('OrderCategory1',   OldOrderCategory1,  NewOrderCategory1,  default, @BusinessUnit, @UserId));

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'PickTicket', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, Note, null, null, null, null) /* Comment */
    from #OrdersShipDetailsModified;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_ModifyShipDetails */

Go
