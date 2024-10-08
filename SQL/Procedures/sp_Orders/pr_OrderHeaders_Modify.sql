/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/18  VS      pr_OrderHeaders_DisQualifiedOrders, pr_OrderHeaders_Modify, pr_OrderHeaders_UnWaveOrders:
  2021/05/04  AJM     pr_OrderHeaders_Modify : Made changes to show the StatusDesc in validation message (HA-2683)
  2020/12/04  MRK/AY  pr_OrderHeaders_Modify: Corrected variable name as per the latest xml (HA-1655)
  2020/08/05  RBV     pr_OrderHeaders_Modify: Made changes to does not allow to change the OrderType for Bulk Pull Orders (FB-2059)
  2020/07/17  KBB     pr_OrderHeaders_Modify: Added processed flag missed on temp table (HA-835)
                      pr_OrderHeaders_ModifyShipDetails: Made changes to call the seperated procedure (HA-745)
  2020/03/31  MS      pr_OrderHeaders_Modify: Corrections to node Insurance (CIMSV3-424)
  2019/10/10  AY      pr_OrderHeaders_Modify: Setup OrderId in temp table or UnwaveOrders (CID-Support)
  2019/10/09  YJ      pr_OrderHeaders_Modify: Added changes to update OrderHeader UDF28, UDF29, UDF7, UDF8, UDF3, OrderCategory1 on ModifyShipDetails (S2GCA-983)
  2019/10/01  YJ/TK   pr_OrderHeaders_Modify: Added changes to update DesiredShipDate on ModifyShipDetails (S2GCA-912)
  2019/08/30  RV      pr_OrderHeaders_Modify: Seperated the modify shipping details as new procedure pr_OrderHeaders_ModifyShipDetails (CID-1008)
  2019/06/25  MJ      pr_OrderHeaders_Modify: Made changes to update the ShipCompletePercent instead of ShipComplete (CID-609)
  2018/11/28  RV      pr_OrderHeaders_Modify: Made changes to update Shipment Reference number (S2G-1178)
  2018/10/08  PK      pr_OrderHeaders_Modify: Migrated from Prod (S2GCA-360)
  2018/09/19  TK      pr_OrderHeaders_Modify: Added validation not to modify Ship Details of order which is on Load (S2GCA-272)
  2018/08/16  TK      pr_OrderHeaders_Modify: ShipVia datatype changed to TShipVia (S2GCA-135)
  2018/06/21  CK/VM   pr_OrderHeaders_Modify: Restrictions to modify on orders, which will be processed in WSS (S2G-920)
  2018/05/11  RT      pr_OrderHeaders_Modify: Made change to display the complete message
  2018/04/27  OK      pr_OrderHeaders_Modify: Enhanced to update the Insurance and AESNumber on the Order (S2G-748)
  2018/04/13  RV      pr_OrderHeaders_Modify: Moved Orders updated rows count to after OrderHeaders updated
  2018/04/08  SV      pr_OrderDetails_Modify, pr_OrderHeaders_AfterClose, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close, pr_OrderHeaders_Modify (HPI-1842)
  2018/04/11  AY      pr_OrderHeaders_Modify: Preprocess Orders on ShipVia changes (S2G-580)
  2018/01/31  AY      pr_OrderHeaders_Modify: Modify Ship Details - not reporting updated count correctly - fixed (S2G-101)
  2017/07/04  PSK     pr_OrderHeaders_Modify: Bug fix to get the proper updated Order count and, to log the Audittrail on updated orders (SRI-795)
  2017/04/25  SV      pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_Modify, pr_OrderHeaders_RecomputeShipVia:
  2016/12/01  SV      pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_Modify, pr_OrderHeaders_RecomputeShipVia:
  2016/10/28  MV      pr_OrderHeaders_Modify: Updated the Ownership value for modifying the PickTicket (FB-792)
  2016/09/29  MV      pr_OrderHeaders_Modify: Updated the priority value for modifying the PickTicket (HPI-813)
  2016/09/27  KL      pr_OrderHeaders_Modify: Added new action RemoveOrdersFromWave (HPI-739)
  2016/05/11  RV      pr_OrderHeaders_Modify: Bug fixed to void the ship labels if already generated (NBD-506)
  2016/04/20  SV      pr_OrderHeaders_Modify: Moved the FreightTerms updation from ModifyPT to ModifyShipDetails (CIMS-887)
  2016/04/01  SV      pr_OrderHeaders_Modify: Updated the valid statuses for modifying the orders (NBD-293)
  2016/03/29  SV      pr_OrderHeaders_Modify: Added ShipComplete to edit (NBD-293)
  2016/03/02  OK      pr_OrderHeaders_Modify: Enhanced to use fn_AppendCSV function to append ShipVia and Bill to Add with commaseperated (CIMS-794)
  2016/02/12  SV      pr_OrderHeaders_Modify: Enhancement to update the BillToAccount (CIMS-769)
  2016/01/29  SV      pr_OrderHeaders_Modify: Enhancement, made changes to update the OrderType (FB-609)
  2015/10/20  YJ      pr_OrderHeaders_Modify: Handle to modify from empty ShipVia to a new ShipVia (FB-460)
  2014/03/03  NY      pr_OrderHeaders_Modify: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  2014/02/19  NY      pr_OrderHeaders_Modify: Added action for Modify PickTicket. (xsc-376)
  2012/09/12  NY      pr_OrderHeaders_Modify: Added validation @@trancount to handle transaction errors
  2012/09/12  PKS     pr_OrderHeaders_Modify: Prevent modify of Shipped/canceled Orders
                      called from pr_OrderHeaders_Modify, which handles the transaction.
  2012/07/25  PKS     pr_OrderHeaders_Modify: output variable 'Message' datatype changed from TMessageName to TMessage
  2012/07/18  PKS/VM  pr_OrderHeaders_Modify: Restrict all actions for Bulk Pull Orders.
  2012/06/30  SP      Placed the transaction controls in 'pr_OrderHeaders_Modify'.
                      pr_OrderHeaders_Modify:Added CancelPickTicket, CloseOrder functionality
  2012/01/31  PKS     Added pr_OrderHeaders_Modify.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Modify') is not null
  drop Procedure pr_OrderHeaders_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Modify
  (@OrderContents  TXML,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @Message        TMessage output)
as
  declare @ReturnCode                  TInteger = 0,
          @MessageName                 TMessageName,
          @vMessage                    TMessage,
          @vEntity                     TEntity  = 'Order',
          @vAction                     TDescription,
          @vActivityType               TActivityType,
          @vOrders                     TNVarChar,
          @vOldCarrier                 TCarrier,
          @vShipVia                    TShipVia,
          @vOrderId                    TRecordId = 0,
          @vOrderStatus                TStatus,
          @vPickTicket                 TPickTicket,
          @vOrderType                  TOrderType,
          @vFreightTerms               TDescription,
          @vShipCompletePercent        TPercent,
          @vPriority                   TPriority,
          @vOwnership                  TOwnership,
          @vCarrierOptions             TDescription,
          @vAESNumber                  TAESNumber,
          @vShipmentRefNumber          TShipmentRefNumber,
          @vBillToAccount              TBillToAccount,
          @vDesiredShipDate            TDateTime,
          @vOrderCategory1             TOrderCategory,
          @xmlData                     xml,
          @vOrdersCount                TCount,
          @vOrdersUpdated              TCount,
          @vOrderCategory3             TOrderCategory,
          @vOrderCategory4             TOrderCategory,
          @vOrderCategory5             TOrderCategory,
          @vProcessed                  TFlag,
          @vNote1                      TDescription,
          @vNote2                      TDescription,
          @vValidStatuses              TStatus,
          @vReasonCode                 TReasonCode,
          @vRecordId                   TRecordId,
          @vAuditRecordId              TRecordId,
          @vPreprocessOnShipViaChange  TFlags;

  /* Temp table to hold all the Orders to be updated */
  declare @ttOrders table (RecordId       TRecordId Identity(1,1),
                           OrderId        TRecordId,
                           PickTicket     TPickTicket,
                           Status         TStatus,
                           StatusDesc     TDescription,
                           OrderType      TTypeCode,
                           PickBatchId    TRecordId,
                           OrderCategory3 TOrderCategory,
                           OrderCategory4 TOrderCategory,
                           OrderCategory5 TOrderCategory,
                           Processed      TFlag default 'N' /* Not yet Processed */);

  declare @ttOrdersModified        TEntityKeysTable,
          @ttOrdersToUnwave        TEntityKeysTable,
          @ttInvalidOrdersToModify TEntityKeysTable;

  declare @ttOrdersShipViaModified table (OrderId    TRecordId,
                                          PickTicket TPickTicket,
                                          OldShipVia TShipVia,
                                          NewShipVia TShipVia,
                                          RecordId   TRecordId Identity(1,1));
begin
begin try
  SET NOCOUNT ON;

  select @xmlData        = convert(xml, @OrderContents),
         @vOrdersUpdated = 0;

  select @vValidStatuses = dbo.fn_Controls_GetAsString('ModifyOrder', 'ValidOrderStatus', 'ONIAWCPKRGL' /* Valid statuses other than Cancelled, Shipped */,
                                                       @BusinessUnit, @UserId);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return;

  begin transaction;

  select * into #ttOrdersToModify from @ttOrders;

  /* Get the Action from the xml */
  select @vAction     = Record.Col.value('Action[1]',     'varchar(100)'),
         @vReasonCode = Record.Col.value('ReasonCode[1]', 'TReasonCode')
  from @xmlData.nodes('/ModifyOrders') as Record(Col);

  /* Get selected orders to modify */
  insert into #ttOrdersToModify (OrderId, PickTicket)
    select EntityId, EntityKey from #ttSelectedEntities;

  /* Get Order information */
  update TTO
  set TTO.OrderId     = OH.OrderId,
      TTO.Status      = OH.Status,
      TTO.StatusDesc  = S.StatusDescription,
      TTO.OrderType   = OH.OrderType,
      TTO.PickBatchId = OH.PickBatchId,
      TTO.Processed   = 'N' /* Not yet Processed */
  from #ttOrdersToModify TTO
    join OrderHeaders OH on (TTO.PickTicket = OH.PickTicket and OH.BusinessUnit = @BusinessUnit)
    join Statuses S on (S.Entity = 'Order' and OH.Status = S.StatusCode and OH.BusinessUnit = @BusinessUnit);

  /* Get number of rows inserted */
  select @vOrdersCount = @@rowcount;

  /* Restrict all actions on Bulk Pull Orders */
  delete TTO
  output 'E', 'ModifyOrder_InvalidOrderType', deleted.PickTicket into #ResultMessages(MessageType, MessageName, Value1)
  from #ttOrdersToModify TTO
  where (OrderType = 'B' /* Bulk Pull */);

  /* Restrict all actions on Shipped/Canceled/Completed Orders */
  delete TTO
  output 'E', 'ModifyOrder_InvalidOrderStatus', deleted.PickTicket, deleted.StatusDesc
  into #ResultMessages(MessageType, MessageName, Value1, Value2)
  from #ttOrdersToModify TTO
  where (charindex(Status, @vValidStatuses) = 0);

  if not exists(select * from #ttOrdersToModify)
    goto MessageHandler;

  if (@vAction = 'ModifyShipDetails')
    exec pr_OrderHeaders_Action_ModifyShipDetails @xmlData, @BusinessUnit, @UserId, @Message output;
  else
  if (@vAction in ('CancelPickTicket', 'ClosePickTicket'))
    begin
      select @vActivityType = null; /* Audit is logged in OrderHeaders_Afterclose, so we
                                        don't need to do it in this procedure */

      while (exists (select * from #ttOrdersToModify where Processed ='N'  /* Not yet Processed */))
        begin
          set @vProcessed = null;

          select top 1 @vPickTicket = PickTicket
          from #ttOrdersToModify
          where (Processed = 'N' /* Not yet Processed */)

          begin try
            if (@vAction = 'CancelPickTicket')
              exec pr_OrderHeaders_CancelPickTicket null /* OrderId */, @vPickTicket, @vReasonCode /* ReasonCode */,
                                                    @BusinessUnit, @UserId;
            else
              exec pr_OrderHeaders_Close null /* OrderId */, @vPickTicket, 'Y' /* Force Close */, null /* LoadId */,
                                         @BusinessUnit, @UserId;

            set @vProcessed = 'S'; /* Assuming the ClosePickTicket success case */
          end try
          begin catch
            select @Message = ERROR_MESSAGE();
            set @vProcessed = 'F'; /* Assuming the ClosePickTicket failure case */
          end catch

          update #ttOrdersToModify
          set Processed = @vProcessed
          where PickTicket = @vPickTicket;
        end

      select @vOrdersUpdated = count(*) /* Get the Total number of Orders closed*/
      from #ttOrdersToModify
      where Processed = 'S';

      insert into @ttOrdersModified (EntityKey) select PickTicket from #ttOrdersToModify where Processed = 'S';
    end /* Cancel PickTicket, ClosePickTicket */
  else
  if (@vAction = 'ReleaseOrders')
    begin
      select @vActivityType = 'ReleaseOrders';

      /* Update only if there is a change in ShipVia.*/
      update OH
      set ExchangeStatus = 'P',
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output inserted.OrderId, inserted.PickTicket into @ttOrdersModified
      from OrderHeaders OH join #ttOrdersToModify O on (OH.OrderId = O.OrderId);

      set @vOrdersUpdated = @@rowcount;
    end
  else
  if (@vAction = 'ModifyPickTicket')
    begin
      select @vActivityType = 'ModifyPickTicket';

      select @vOrderType           = Record.Col.value('OrderType[1]',           'TOrderType'),
             @vShipCompletePercent = nullif(Record.Col.value('ShipCompletePercent[1]', 'TPercent'), '0'),
             @vPriority            = Record.Col.value('Priority[1]',            'TPriority'),
             @vOwnership           = Record.Col.value('Ownership[1]',           'TOwnership'),
             @vCarrierOptions      = nullif(Record.Col.value('CarrierOptions[1]',      'TDescription'),       ''),
             @vAESNumber           = nullif(Record.Col.value('AESNumber[1]',           'TAESNumber'),         ''),
             @vShipmentRefNumber   = nullif(Record.Col.value('ShipmentRefNumber[1]',   'TShipmentRefNumber'), '')
             /* The below ones are commented for future enhancements
             @vOrderCategory1      = Record.Col.value('OrderCategory1[1]', 'TOrderCategory'),
             @vOrderCategory2      = Record.Col.value('OrderCategory2[1]', 'TOrderCategory'),
             @vOrderCategory3      = Record.Col.value('OrderCategory3[1]', 'TOrderCategory'),
             @vOrderCategory4      = Record.Col.value('OrderCategory4[1]', 'TOrderCategory'),
             @vOrderCategory5      = Record.Col.value('OrderCategory5[1]', 'TOrderCategory') */
      from @xmlData.nodes('/ModifyOrders/OrderData') as Record(Col);

      -- if ((@vOrderType is null) and (@vShipCompletePercent is null))
      --   select @MessageName = 'ModifyPickTicket_NoValues';
      --
      -- if (@MessageName is not null)
      --  goto ErrorHandler;

      /* Update only if there is a change in ShipVia.*/
      update OH
      set OrderType           = case when OH.OrderType <> 'B' then coalesce(@vOrderType, OH.OrderType)
                                     else OH.OrderType
                                end,
          ShipCompletePercent = coalesce(@vShipCompletePercent, OH.ShipCompletePercent),
          Priority            = coalesce(@vPriority,            OH.Priority),
          Ownership           = coalesce(@vOwnership,           OH.Ownership),
          AESNumber           = coalesce(@vAESNumber,           OH.AESNumber),
          ShipmentRefNumber   = coalesce(@vShipmentRefNumber,   OH.ShipmentRefNumber),
          CarrierOptions      = coalesce(@vCarrierOptions,      OH.CarrierOptions)
          /* The below ones are commented for future enhancements
          OrderCategory1      = coalesce(@vOrderCategory1, OH.OrderCategory1),
          OrderCategory2      = coalesce(@vOrderCategory2, OH.OrderCategory2),
          OrderCategory3      = coalesce(@vOrderCategory3, OH.OrderCategory3),
          OrderCategory4      = coalesce(@vOrderCategory4, OH.OrderCategory4),
          OrderCategory5      = coalesce(@vOrderCategory5, OH.OrderCategory5) */
      output inserted.OrderId, inserted.PickTicket into @ttOrdersModified
      from OrderHeaders OH
         join #ttOrdersToModify O on (OH.OrderId = O.OrderId)

      set @vOrdersUpdated = @@rowcount;

      /* Update LPN Ownership Based On PickTicket */
      update L
      set Ownership    = @vOwnership,
          ModifiedDate = current_timestamp,
          ModifiedBy   = @UserId
      from LPNs L
         join @ttOrdersModified O on (L.OrderId = O.EntityId);

      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Order Type',          @vOrderType);
      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Ship Complete %',     @vShipCompletePercent);
      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Priority',            @vPriority);
      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Ownership',           @vOwnership);
      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Insurance',           @vCarrierOptions);
      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'AES Number',          @vAESNumber);
      select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Shipment Ref Number', @vShipmentRefNumber);
      select @vNote1 = '(' + @vNote1 + ')';
    end
  else
  if (@vAction = 'RemoveOrdersFromWave')
    begin
      select @vActivityType = 'RemoveOrdersFromWave';

      insert into @ttOrdersToUnwave(EntityKey)
        select Record.Col.value('.', 'TPickTicket') EntityKey
        from @xmlData.nodes('/ModifyOrders/Orders/Order') as Record(Col);

      exec pr_OrderHeaders_UnWaveOrders @ttOrdersToUnwave, @UserId, @BusinessUnit, @vAction, @Message output;
    end
  else
  if (@vAction in ('AddNote', 'ReplaceNote', 'DeleteNote'))
    exec pr_OrderHeaders_AddOrReplaceOrDeleteNote @xmlData, @BusinessUnit, @UserId, @Message output;
  else
    /* If the action is other than above, send a message to UI saying Unsupported Action*/
    set @Message = dbo.fn_Messages_GetDescription ('UnsupportedAction');

  /* Audit Trail */
  if (@vActivityType is not null)
    begin
      exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */, null /* Device Id */, @BusinessUnit,
                                @Note1         = @vNote1,
                                @Note2         = @vNote2,
                                @AuditRecordId = @vAuditRecordId output;

      exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttOrdersModified, @BusinessUnit;
    end;

MessageHandler:
  /* Based upon the number of Orders that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vOrdersUpdated, @vOrdersCount;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;

  return(coalesce(@ReturnCode, 0));
end /* pr_OrderHeaders_Modify */

Go
