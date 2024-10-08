/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/10  YJ      pr_Receivers_AssignASNLPNs, pr_Receivers_UnAssignLPNs: Added to log AuditTrail for Assigned and Unassigned Actions.
  2014/04/28  DK      pr_Receivers_AssignASNLPNs: Modified the datatype of @ttReceipts temp table due to incompatibility.
  2014/04/26  DK      pr_Receivers_AssignASNLPNs, pr_Receivers_UnAssignLPNs: Log Audittrial in Receipts as well
  2014/04/25  VM      pr_Receivers_AssignASNLPNs: Assign only unassigned and Intransit LPNs only
  2014/04/16  DK      Added pr_Receivers_Modify, pr_Receivers_AssignASNLPNs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_AssignASNLPNs') is not null
  drop Procedure pr_Receivers_AssignASNLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_AssignASNLPNs:
  Sample XML:
  <Root>
   <Entity>Receiver</Entity>
   <Action>AssignASNLPNs</Action>
   <Data>
      <ReceiverNo></ReceiverNo >
   </Data>
   <Receipts>
     <ReceiptId></ReceiptId>
     ..
     ..
   </Receipts>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_AssignASNLPNs
  (@ReceiverContents   XML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Message            TMessage= null output)
as
  declare @vAction           TAction,
          @xmlData           xml,

          @vReceiverNumber   TReceiverNumber,
          @vReceiptsCount    TCount,
          @vReceiptsUpdated  TCount,
          @vLPNsUpdated      TCount,
          @vReceiverStatus   TStatus,
          @vReceiverId       TRecordId,

          @ReturnCode        TInteger,
          @MessageName       TMessageName,

          @vNote1            TDescription,
          @vAuditId          TRecordId;

   /* Temp table to hold all the Receipts */
  declare @ttReceipts TEntityKeysTable;

  declare @ttLPNsUpdated TEntityKeysTable;
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

  /* Load all the ReceiptIds into the temp table which are to be updated in LPN table */
  insert into @ttReceipts (EntityId)
    select Record.Col.value('.', 'TRecordId') ReceiptId
    from @xmlData.nodes('/Root/Receipts/ReceiptId') as Record(Col);

  /* Get number of rows inserted */
  select @vReceiptsCount = @@rowcount;

  /* To log Audit trail on Receipts */
  update ttR
  set EntityKey = R.ReceiptNumber
  from @ttReceipts ttR
    join ReceiptHeaders R on (ttR.EntityId = R.ReceiptId);

  /* Get the ReceiverNumber from the xml */
  select @vReceiverNumber = Record.Col.value('ReceiverNo[1]', 'TReceiverNumber')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  select @vReceiverId     = ReceiverId,
         @vReceiverStatus = Status
  from Receivers
  where (ReceiverNumber = @vReceiverNumber) and
        (BusinessUnit   = @BusinessUnit);

  /* Check if the ReceiverNumber is passed or not */
  if (@vReceiverNumber is null)
    set @MessageName = 'ReceiverNumberIsRequired';
  else
  if (@vReceiverId is null)
    select @MessageName = 'ReceiverNumberIsInvalid';
  else
  if (@vReceiverStatus = 'C' /* Closed */)
    select @MessageName = 'Receipts_AssignASNLPNs_ReceiverClosed';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update the Intransit LPNs which are not associated with the receiver */
  update L
  set ReceiverNumber = @vReceiverNumber,
      ModifiedDate   = current_timestamp,
      ModifiedBy     = @UserId
  output Inserted.LPNId, Inserted.LPN
  into @ttLPNsUpdated
  from LPNs L
    join @ttReceipts LP on (LP.EntityId = L.ReceiptId)
  where (L.Status = 'T') /* Intransit */ and (coalesce(L.ReceiverNumber, '') = '');

  set @vLPNsUpdated = @@rowcount;

  /* Get the count of total number of Receipts Updated */
  set @vReceiptsUpdated = (select count(distinct L.ReceiptId)
                           from LPNs L
                             join @ttLPNsUpdated LU on (L.LPNId = LU.EntityId)
                           where L.ReceiverNumber = @vReceiverNumber);

  /* AT related */
  /* Only if any of the Receipts are updated, generate audittrail else skip. */
  if (@vReceiptsUpdated > 0)
    begin
      exec pr_AuditTrail_Insert 'ReceiverAssigned', @UserId, null /* ActivityTimestamp */,
                                @ReceiverId    = @vReceiverId,
                                @Note1         = @vLPNsUpdated,
                                @BusinessUnit  = @BusinessUnit;

      exec pr_AuditTrail_Insert 'ASNLPNsAssigned', @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vReceiverNumber,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'LPN', @ttLPNsUpdated, @BusinessUnit;

      exec pr_AuditTrail_Insert 'ASNReceiptLPNsAssigned', @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vReceiverNumber,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'Receipt', @ttReceipts, @BusinessUnit;
    end

  /* Based upon the number of Receipts that have been modified, give an appropriate message */
  exec @Message = dbo.fn_Messages_BuildActionResponse 'Receipts', @vAction, @vReceiptsUpdated, @vReceiptsCount, @vLPNsUpdated;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Receivers_AssignASNLPNs */

Go
