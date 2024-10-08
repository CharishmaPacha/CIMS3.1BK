/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/21  PKD     pr_LPNs_Action_ModifyOwnership:Made changes to update the owner ship on the LPNs (OB2-1954)
  2021/07/14  PKD     pr_LPNs_Action_ModifyOwnership: Made changes to update the owner ship on the LPNs (OB2-1954)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ModifyOwnership') is not null
  drop Procedure pr_LPNs_Action_ModifyOwnership;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ModifyOwnership: Procedure that would be invoked when
   user performs the ModifyOwnership action in UI against selected LPNs.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ModifyOwnership
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
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vNewOwner                   TOwnership,
          @vNewOwnershipDesc           TDescription,
          @vReasonCode                 TReasonCode;

  declare @ttUpdatedLPNs table
          (LPNId             TRecordId,
           LPN               TLPN,
           OldOwnership      TOwnership,
           OldOwnershipDesc  TDescription,
           NewOwnership      TOwnership,
           RecordId          TRecordId identity(1,1));

begin /* pr_LPNs_Action_ModifyOwnership */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'AT_LPNChangeOwnership';

  select @vEntity     = Record.Col.value('Entity[1]',            'TEntity'),
         @vAction     = Record.Col.value('Action[1]',            'TAction'),
         @vNewOwner   = Record.Col.value('(Data/LPNOwner)[1]',   'TOwnership'),
         @vReasonCode = Record.Col.value('(Data/ReasonCode)[1]', 'TReasonCode')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select * into #LPNsUpdated from @ttUpdatedLPNs;

  /* Validations */
  select @vMessageName = dbo.fn_IsValidLookUp('Owner', @vNewOwner, @BusinessUnit, @UserId);

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the owner ship description */
  select @vNewOwnershipDesc = dbo.fn_LookUps_GetDesc('Owner', @vNewOwner, @BusinessUnit, null);

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get all the required info from LPNs for validations to avoid hitting the LPNs
     table again and again */
  select L.LPNId, L.LPN, L.Ownership, cast(L.Status as varchar(30)) as LPNStatus,
  case when L.Status <> 'P' /* PutAway */                  then 'LPNs_ChangeOwnership_NotPutaway'
       when L.Ownership = @vNewOwner                       then 'LPNs_ChangeOwnership_SameOwner'
  end ErrorMessage
  into #InvalidLPNs
  from #ttSelectedEntities SE join LPNs L on SE.EntityId = L.LPNId;

  /* Get the status description for the error message */
  update #InvalidLPNs
  set LPNStatus = dbo.fn_Status_GetDescription('LPN', LPNStatus, @BusinessUnit);

  /* Exclude the LPNs that are invalid */
  delete from SE
  output 'E', IL.LPNId, IL.LPN, IL.ErrorMessage, IL.LPNStatus, @vNewOwnershipDesc
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2, Value3)
  from #ttSelectedEntities SE join #InvalidLPNs IL on SE.EntityId = IL.LPNId
  where (IL.ErrorMessage is not null);

  /* Update the LPNs that can be updated - added the status condition again to be safe */
  update L
  set Ownership    = @vNewOwner,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output Inserted.LPNId, Inserted.LPN, Deleted.Ownership, Inserted.Ownership
  into #LPNsUpdated (LPNId, LPN, OldOwnership, NewOwnership)
  from LPNs L join #ttSelectedEntities SE on L.LPNId = SE.EntityId
  where (L.Status = 'P' /* Putaway */);

  select @vRecordsUpdated = @@rowcount;

  /* Get the status description for the error message */
  update #LPNsUpdated
  set OldOwnershipDesc = dbo.fn_LookUps_GetDesc('Owner', OldOwnership, @BusinessUnit, null);

  /*--------- Exports ---------------*/
  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Generate the transactional changes for all LPNs */
  insert into #ExportRecords (TransType, TransQty, LPNId, LPNDetailId, Ownership, ReasonCode, CreatedBy)
    /* Generate negative InvCh transactions for the Old Ownership */
    select 'InvCh', -1 * LD.Quantity, LU.LPNId, LD.LPNDetailId, LU.OldOwnership, @vReasonCode, @UserId
    from #LPNsUpdated LU join LPNs L on LU.LPNId = L.LPNId join LPNDetails LD on LU.LPNId = LD.LPNId
    union
    /* Generate positive InvCh transactions for the New Ownership */
    select 'InvCh', LD.Quantity, LU.LPNId, LD.LPNDetailId, LU.NewOwnership, @vReasonCode, @UserId
    from #LPNsUpdated LU join LPNs L on LU.LPNId = L.LPNId join LPNDetails LD on LU.LPNId = LD.LPNId

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'InvCh', 'LPND' /* TransEntity - LPNDetails */, @BusinessUnit;

  /*--------- Audit Trail ---------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'LPN', LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, OldOwnershipDesc, @vNewOwnershipDesc, null, null, null) /* Comment */
    from #LPNsUpdated;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ModifyOwnership */

Go
