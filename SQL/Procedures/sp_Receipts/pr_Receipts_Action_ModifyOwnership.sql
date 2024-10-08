/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/21  AJM     pr_Receipts_Action_ModifyOwnership: Initial revision (CIMSV3-1437)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_Action_ModifyOwnership') is not null
  drop Procedure pr_Receipts_Action_ModifyOwnership;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_Action_ModifyOwnership: This procedure used to change the
    Ownership on selected receipts
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_Action_ModifyOwnership
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,
          @ttAuditTrailInfo      TAuditTrailInfo,
          @vReceiptid            TRecordId,
          @vEntity               TEntity,
          @vAction               TAction,
          @vReceiptsCount        TCount,
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount,

          /* Owner change */
          @vOldOwner             TOwnership,
          @vNewOwner             TOwnership,
          @vNewOwnerDescription  TDescription,

          @vValidReceiptStatuses TControlValue,
          @vValidLPNStatuses     TControlValue,
          @vMessage              TDescription,
          @vAuditActivity        TActivityType;

  declare @ttLPNsUpdated         TEntityKeysTable;
  declare @ttUpdatedReceipts table
          (ReceiptId             TRecordId,
           ReceiptNumber         TReceiptNumber,

           OldOwnership          TOwnership,
           OldOwnershipDesc      TDescription,

           NewOwnership          TOwnership,

           RecordId              TRecordId identity(1,1));

begin /* pr_Receipts_Action_ModifyOwnership */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordsUpdated = 0,
         @vRecordId       = 0,
         @vAuditActivity  = 'AT_ReceiptOwnerModified'

  /* Get the total count of receipts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select * into #UpdatedReceipts from @ttUpdatedReceipts

  select @vEntity   = Record.Col.value('Entity[1]',               'TEntity'),
         @vAction   = Record.Col.value('Action[1]',               'TAction'),
         @vNewOwner = Record.Col.value('(Data/NewOwnership)[1]',  'TOwnership')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vValidReceiptStatuses = dbo.fn_Controls_GetAsString('Receipts', 'ValidReceiptsToUpdateOwner', 'I' /* Initial */, @BusinessUnit, @UserId);
  select @vValidLPNStatuses     = dbo.fn_Controls_GetAsString('Receipts', 'ValidLPNsToUpdateOwner', 'TRV' /* InTransit, Received, Voided */, @BusinessUnit, @UserId);

  /* Fetch the Owner descriptions */
  select @vNewOwnerDescription = dbo.fn_LookUps_GetDesc('Owner', @vNewOwner, @BusinessUnit, default);

  /* Validations */
  select @vMessageName = dbo.fn_IsValidLookUp('Owner', @vNewOwner, @BusinessUnit, @UserId);

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get all the required info from ReceiptHeaders for validations to avoid hitting the ReciptHeaders table
     table again and again */
  select RH.ReceiptId, RH.ReceiptNumber, RH.Ownership, RH.ReceiptStatusDesc, 0 as InvalidLPNCount,
         case
           when (dbo.fn_IsInList(RH.Status, @vValidReceiptStatuses) = 0) then 'Receipts_ModifyOwner_InvalidStatus'
           when (RH.Ownership = @vNewOwner)                              then 'Receipts_ModifyOwner_SameOwnership'
         end as ErrorMessage
  into #InvalidReceipts
  from #ttSelectedEntities ttSE
    join vwReceiptHeaders RH on (RH.ReceiptId = ttSE.EntityId);

  /* Exclude receipts which have LPNs already received i.e. any receipts that do not have InTransit or Received LPNs */
  insert into #InvalidReceipts (ReceiptId, ReceiptNumber, ErrorMessage, InvalidLPNCount)
    select SE.EntityId, SE.EntityKey, 'Receipts_ModifyOwner_HasInventory',
           sum(case when (dbo.fn_IsInList(L.Status, @vValidLPNStatuses) = 0) then  1 else 0 end) as InvalidLPNCount
    from #ttSelectedEntities SE join LPNs L on (L.LPNId = SE.EntityId)
    group by SE.EntityId, SE.EntityKey;

  /* Exclude the Receeipts that are determined to be invalid above */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, IR.ErrorMessage, IR.ReceiptStatusDesc,
         @vNewOwnerDescription, IR.InvalidLPNCount
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, Value3, Value4)
  from #ttSelectedEntities SE join #InvalidReceipts IR on (SE.EntityId = IR.Receiptid)
  where (IR.ErrorMessage is not null);

  /* Update with Ownership of remaining Receipts */
  update RH
  set Ownership    = @vNewOwner,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output inserted.ReceiptId, inserted.ReceiptNumber, deleted.Ownership, inserted.Ownership, ''
  into #UpdatedReceipts (ReceiptId, ReceiptNumber, OldOwnership, NewOwnership, OldOwnershipDesc)
  from ReceiptHeaders RH join #ttSelectedEntities ttSE on RH.ReceiptId = ttSE.EntityId;

  set @vRecordsUpdated = @@rowcount;

  /* Update LPN Ownership too if that is Intransit or Received LPN */
  update L
  set Ownership    = @vNewOwner,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output inserted.LPNId, inserted.LPN into @ttLPNsUpdated
  from LPNs L
    join #UpdatedReceipts UR on L.ReceiptId = UR.ReceiptId
  where (L.Status in ('T','R' /* InTransit, Received */));

  /* Get the Onwer ship description */
  update #UpdatedReceipts
  set OldOwnershipDesc = dbo.fn_LookUps_GetDesc('Owner', OldOwnership, @BusinessUnit, default)
  where OldOwnership is not null

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Receipt', ReceiptId, ReceiptNumber, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, ReceiptNumber, OldOwnershipDesc, @vNewOwnerDescription, null, null) /* Comment */
    from #UpdatedReceipts

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords, @vNewOwner;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_Action_ModifyOwnership */

Go
