/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/30  VS      pr_Receivers_Close, pr_Receivers_SendConsolidatedExports: Do not send exports if already exported for the Receiver (HA-2935)
  2020/11/02  MS      pr_Receivers_AutoCreateReceiver: Changes to send ContainerNo in Rules (JL-287)
                      pr_Receivers_Close, pr_Receivers_RemoveInTransitLPNs: Changes to Send RI in Receiver Close
  2020/05/06  VS      pr_Receivers_Close: Made the changes to send Consolidated exports based on RO Type (HA-339)
  2020/03/23  RV      pr_Receivers_Close: Corrected the message name (JL-161)
  2019/08/07  SPP     pr_Receivers_Close: Added join with where codition (CID-136) (Ported from Prod)
  2019/07/25  SPP     pr_Receivers_Close:Updated ttreceiver Status (CID-136) (Ported from Prod)
  2018/02/18  VS      pr_Receivers_Close: Do not allow user to close the receiver when there are any QC LPNs (CID-117)
                      pr_Receivers_Close: Consider receivers with void LPNs as well and code optimization (S2G-947)
  2015/11/12  NY      pr_Receivers_Close: Added validation messages(ACME- 398).
  2015/10/18  AY      pr_Receivers_Close: Enable closing of Receivers w/o LPNs
  2015/05/28  OK      Refactor the procedure from pr_Receivers_Close.
  2015/05/11  SV      pr_Receivers_Close: Made changes to close the Receiver once after all LPNs associated with it are putaway.
  2014/06/12  VM      pr_Receivers_Close: Consolidate by Receiver, Receipt Detail line instead of CustPO
  2014/04/28  DK      pr_Receivers_Close: Modified to call the pr_Exports_ReceiversData.
  2014/04/25  DK      pr_Receivers_Close: Modified to send consolidated exports  and
  2014/04/18  DK      Modified pr_Receivers_Close and Added pr_Receivers_UnAssign.
  2014/03/03  PKS     Added pr_Receivers_Close
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_Close') is not null
  drop Procedure pr_Receivers_Close;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_Close: Receivers close function is to mark the receiver as
   done so that there are no more receipts that happen against it. Most often,
   this is the only purpose. But it could vary for some clients based upon control
   variables.

  Basic rule is that for a Receiver to be closed, there should be no InTransit LPNs
  i.e. all LPNs are received at least.

  A. PutawayBeforeClose: The intent of this is to have all the LPNs received putaway
     before the receiver is closed. This means there are no Received LPNs
     pending against that receipt. If this variable is Y then we do not allow closing
     of a Receiver unless all LPNs are putaway.

  B. PutawayInventoryOnClose: If LPNs are not Putaway before receiver is closed, then
     we logically putaway those LPNs and if needed, send exports for them as well.

  C. SendConsolidatedExports: Some clients/systems choose to export all the Received
     confirmations at once, in summary instead of individual transactions. If that is
     the case, then we would set this flag to send the consolidated exports by PO Detail.

  @ReceiverContents XML:
    <Root>
      <Entity> CloseReceiver</Entity>
      <Action>CloseReceiver</Action>
      <Data>
        <ReceiverNo></ReceiverNo >
       ...
      </Data>
   </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_Close
  (@ReceiverContents   XML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Message            TMessage= null output)
as
  declare @vReturnCode                   TInteger,
          @vMessageName                  TMessageName,
          @vRecordId                     TRecordId,

          @vAction                       TAction,
          @xmlData                       xml,
          /* Receivers Info */
          @vReceiversCount               TCount,
          @vReceiversUpdated             TCount,
          @vReceiverLPNCount             TCount,
          @vReceiverLPNPutAwayCount      TCount,
          @vReceiversWithLPNsNotPutaway  TCount,
          @vReceiversWithLPNsIntransit   TCount,
          /* Others */
          @vSendConsolidatedExports      TControlValue,
          @vPutawayBeforeClose           TControlValue,
          @vPutawayInventoryOnClose      TControlValue,
          @vReceiversWithQCLPNs          TControlValue,
          @vRemoveIntransitLPNs          TControlValue,

          @vActivityType                 TActivityType,
          @vAuditId                      TRecordId;

   /* Temp table to hold all the Receivers to be updated */
  declare @ttReceipts TEntityKeysTable;

  declare @ttReceivers table(RecordId       TRecordId Identity(1,1),
                             ReceiverNumber TReceiverNumber,
                             BoLNumber      TBoLNumber,
                             Container      TContainer,
                             Reference1     TDescription);

  declare @ttReceiversUpdated TEntityKeysTable;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Create #Receivers */
  select * into #Receivers from @ttReceivers

  set @xmlData = convert(xml, @ReceiverContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    begin
      set @vMessageName = 'InvalidData';
      goto ErrorHandler;
    end

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/Root') as Record(Col);

  /* Load all the Receivers into the temp table  */
  insert into #Receivers (ReceiverNumber)
    select Record.Col.value('.', 'TReceiverNumber') ReceiverNumber
    from @xmlData.nodes('/Root/Data/ReceiverNo') as Record(Col);

  /* Get number of rows inserted */
  select @vReceiversCount = @@rowcount;

  /* If Receiver is closed do not close it again */
  delete from TR
  output 'E', 'Receiver_Close_AlreadyClosed', deleted.ReceiverNumber
  into #ResultMessages (MessageType, MessageName, Value1)
  from #Receivers TR
    join Receivers R on (R.ReceiverNumber = TR.ReceiverNumber) and (R.BusinessUnit = @BusinessUnit)
  where (R.Status = 'C' /* Closed */);

  update TR
  set TR.BoLNumber  = nullif(R.BoLNumber, ''),
      TR.Container  = R.Container,
      TR.Reference1 = R.Reference1 /* Typically used for Packing List # */
  from #Receivers TR join Receivers R on (TR.ReceiverNumber = R.ReceiverNumber) and (R.BusinessUnit = @BusinessUnit);

  /* Prevent closing of Receiver if there is no BoL */
  if (exists (select * from #Receivers where BoLNumber is null))
    begin
      select @vMessageName = 'BoLNumberIsRequired';
      goto ErrorHandler;
    end

  /* Get the Control variables PutawayBeforeClose, PutawayInventoryOnClose, SendConsolidatedExports */
  select @vPutawayBeforeClose      = dbo.fn_Controls_GetAsString('Receiver', 'PutawayBeforeClose',      'N' /* No */, @BusinessUnit, @UserId),
         @vPutawayInventoryOnClose = dbo.fn_Controls_GetAsString('Receiver', 'PutawayInventoryOnClose', 'N' /* No */, @BusinessUnit, @UserId),
         @vSendConsolidatedExports = dbo.fn_Controls_GetAsString('Receiver', 'SendConsolidatedExports', 'PO' /* PO */, @BusinessUnit, @UserId),
         @vRemoveIntransitLPNs     = dbo.fn_Controls_GetAsString('Receiver', 'SendRejectRI',            'N' /* No */,  @BusinessUnit, @UserId);

  /* Remove the Intransit LPNs from the Receiver */
  if (@vRemoveIntransitLPNs = 'Y')
    exec pr_Receivers_RemoveInTransitLPNs @BusinessUnit, @UserId;

  /* Based upon the Control var, delete the in-eligible receivers from the list of Receivers to be closed */
  if (@vPutawayBeforeClose = 'N')
    begin
      /* If there are any LPNs that are in InTransit status, then we cannot close the Receiver */
      delete from TR
      output 'E', 'Receiver_Close_LPNsinIntransit', Deleted.ReceiverNumber
      into #ResultMessages (MessageType, MessageName, Value1)
      from #Receivers TR
        left join LPNs L on (TR.ReceiverNumber = L.ReceiverNumber)
      where (L.Status = 'T' /* InTransit */);
    end
  else
  if (@vPutawayBeforeClose = 'Y')
    begin
      /* Remove all Receivers from the list, if any one of its LPNs is not in InTransit, Received Status
         That means, it only can be closed when all LPNs on it are Putaway */
      delete from TR
        output 'E', 'Receiver_Close_LPNsNotPutaway', Deleted.ReceiverNumber
        into #ResultMessages (MessageType, MessageName, Value1)
      from #Receivers TR
        left join LPNs L on (TR.ReceiverNumber = L.ReceiverNumber)
      where (L.Status not in ('T', 'R', 'V')/* InTransit, Received, Voided */);
    end

  /* If there are any LPNs that are in QC, then we cannot close the Receiver */
  delete from TR
  output 'E', 'Receiver_Close_LPNsinQC', Deleted.ReceiverNumber
  into #ResultMessages (MessageType, MessageName, Value1)
  from #Receivers TR
    left join LPNs L on (TR.ReceiverNumber = L.ReceiverNumber)
  where ((L.InventoryStatus = 'QC') and (L.Status <> 'C'));

  /* Process the remaining Receivers */
  insert into @ttReceipts(EntityId, EntityKey)
    select distinct L.ReceiptId, L.ReceiverNumber
    from LPNs L
      join #Receivers RP on (RP.ReceiverNumber = L.ReceiverNumber)
    where (L.ReceiptId is not null);

  /* if PutawayInventoryOnClose = 'Y' and then Receiver is being closed, we need to Putaway all the inventory */
  if (@vPutawayInventoryOnClose = 'Y')
    exec pr_Receivers_PutawayInventory @ttReceipts, @BusinessUnit, @UserId;

  /* Remove receipts for which we do not send consolidated exports */
  delete from R
  from @ttReceipts R
    join ReceiptHeaders RH on RH.ReceiptId = R.EntityId
  where (dbo.fn_IsInList(RH.ReceiptType, @vSendConsolidatedExports) = 0)

  /* Close all selected receivers if all associated LPNs with the Receiver have been Putaway */
  update R
    set Status       = 'C' /* Closed */,
        ModifiedDate = current_timestamp,
        ModifiedBy   = @UserId
  output Inserted.ReceiverId, Inserted.ReceiverNumber
  into @ttReceiversUpdated
  from Receivers R
    join #Receivers      RP on (RP.ReceiverNumber = R.ReceiverNumber)
    left outer join LPNs L  on (L.ReceiverNumber  = R.ReceiverNumber)
  where (R.Status = 'O' /* Open */) and
        ((L.Status is null) or (L.Status not in ('T', 'R', 'V' /* In Transit or Received or 'Voided' */))) or (L.InventoryStatus <> 'QC' /* QC LPN */);

  set @vReceiversUpdated = @@rowcount;

  /* Send Consolidated Exports */
  exec pr_Receivers_SendConsolidatedExports @ttReceipts, @BusinessUnit, @UserId;

  /* Based upon the number of Receivers that have been modified, give an appropriate message */
  exec pr_Messages_BuildActionResponse 'Receivers', @vAction, @vReceiversUpdated, @vReceiversCount;

  if (@vReceiversUpdated > 0)
    begin
      exec pr_AuditTrail_Insert 'ReceiverClosed', @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'Receiver', @ttReceiversUpdated, @BusinessUnit;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_Close */

Go
