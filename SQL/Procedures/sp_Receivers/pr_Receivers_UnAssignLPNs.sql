/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/10  YJ      pr_Receivers_AssignASNLPNs, pr_Receivers_UnAssignLPNs: Added to log AuditTrail for Assigned and Unassigned Actions.
  2015/05/28  VM/RV   pr_Receivers_UnAssignLPNs : Do not void the LPNs.
  2014/04/28  DK      pr_Receivers_UnAssignLPNs: Modified the datatype of @ttReceipts temp table due to incompatibility.
  2014/04/26  DK      pr_Receivers_AssignASNLPNs, pr_Receivers_UnAssignLPNs: Log Audittrial in Receipts as well
  2014/04/24  DK      Modified pr_Receivers_UnAssignLPNs to void non-ASN LPNs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_UnAssignLPNs') is not null
  drop Procedure pr_Receivers_UnAssignLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_UnAssignLPNs:
  Sample XML:
  <Root>
  <Entity>Receiver</Entity>
  <Action>UnAssignLPNs</Action>
     <LPNs>
     <LPNId></LPNId>
     ..
     ..
  </LPNs>
</Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_UnAssignLPNs
  (@ReceiverContents   XML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Message            TMessage= null output)
as
  declare @vAction         TAction,
          @xmlData         xml,

          @vReceiverNumber TReceiverNumber,
          @vReceiverId     TRecordId,

          @vLPNs           xml,
          @vLPNId          TRecordId,
          @vLPNsToVoid     TXML,

          @vTotalLPNCount  TCount,
          @vLPNsUpdated    TCount,

          @ReturnCode      TInteger,
          @MessageName     TMessageName,

          @vAuditId        TRecordId;

   /* Temp table to hold all the LPNs to be updated */
  declare @ttLPNs table(RecordId  TRecordId Identity(1,1),
                        LPNId     TRecordId,
                        LPN       TLPN,
                        ASNLPN    TFlag default 'N' /* No */);

  declare @ttReceipts    TEntityKeysTable;
  declare @ttLPNsUpdated TEntityKeysTable;
  declare @ttLPNsVoided  TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  set @xmlData = convert(xml, @ReceiverContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    begin
      set @MessageName = 'InvalidData';
      goto ErrorHandler;
    end

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/Root') as Record(Col);

  /* Load all the LPNIds into the temp table  */
  insert into @ttLPNs (LPNId)
    select Record.Col.value('.', 'TRecordId') LPNId
    from @xmlData.nodes('/Root/LPNs/LPNId') as Record(Col);

  /* Delete the LPNs which are alreday unassigned */
  delete LP
  from @ttLPNs LP
    left join LPNs L on (LP.LPNId = L.LPNId)
  where (L.ReceiverNumber = '');

  select top 1 @vLPNId =  LPNId
  from @ttLPNs;

  select @vReceiverNumber = ReceiverNumber
  from LPNs
  where LPNId = @vLPNId;

  update LP
  set LPN    = L.LPN,
      ASNLPN = case
                 when RH.ReceiptType = 'A' /* ASN Receipt */ then 'Y' /* Yes */
               else
                 'N' /* No */
               end
  from @ttLPNs LP
    join LPNs L on (LP.LPNId = L.LPNId)
    left join ReceiptHeaders RH on (L.ReceiptId = RH.ReceiptId)

  /* Get number of rows inserted */
  select @vTotalLPNCount = @@rowcount;

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Clear Receiver # on LPNs*/
  update L
  set ReceiverNumber = ''
  output Inserted.LPNId, Inserted.LPN
  into @ttLPNsUpdated
  from LPNs L
    join @ttLPNs R on L.LPNId = R.LPNId
  where (L.Status = 'T' /* In Transit */);

  set @vLPNsUpdated = @@rowcount;

  insert into @ttReceipts(EntityId, EntityKey)
    select distinct ReceiptId, ReceiptNumber
    from LPNs L
      join @ttLPNs R on (L.LPNId = R.LPNId);

  /* Need to void the non-ASN LPNs as they are just created */
  --update L
  --set Status = 'V' /* Voided */ ,
  --    OnhandStatus = 'U'  /* Unavailable */ ,
  --    ModifiedDate = current_timestamp,
  --    ModifiedBy   = coalesce(@UserId, System_User)
  --  output Inserted.LPNId,Inserted.LPN
  --into @ttLPNsVoided
  --from LPNs L
  --  join @ttLPNs R on L.LPNId = R.LPNid
  --where (R.ASNLPN = 'N' /* No */) and (L.Status in (@LPNStatusesToVoidOnUnassignFromReceiver))
  /* Not needed to void at this point as per discussions _20150528: If required,
     can introduced a control var in which we will define the LPN statues to Void and void based on it */

  select @vReceiverId = ReceiverId
  from Receivers
  where ReceiverNumber = @vReceiverNumber;

  /* AT related */
  /* Only if any of the Receipts are updated, generate audittrail else skip. */
  if (@vLPNsUpdated > 0)
    begin
      exec pr_AuditTrail_Insert 'ReceiverUnAssigned', @UserId, null /* ActivityTimestamp */,
                                @Note1         = @vLPNsUpdated,
                                @ReceiverId    = @vReceiverId,
                                @BusinessUnit  = @BusinessUnit;

      exec pr_AuditTrail_Insert 'UnAssignedLPNsFromReceivers', @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vReceiverNumber,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'LPN', @ttLPNsUpdated, @BusinessUnit;

      exec pr_AuditTrail_Insert 'ASNReceiptLPNsUnassigned', @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vReceiverNumber,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'Receipt', @ttReceipts, @BusinessUnit;

      /* Audit Trail - needs to be reflected against LPN, Pallet and Location */
      exec pr_AuditTrail_Insert 'LPNVoided', @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'LPN', @ttLPNsVoided, @BusinessUnit;
    end

  /* Based upon the number of Receipts that have been modified, give an appropriate message */
  exec @Message = dbo.fn_Messages_BuildActionResponse 'LPNs', @vAction, @vLPNsUpdated, @vTotalLPNCount;

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Receivers_UnAssignLPNs */

Go
