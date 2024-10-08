/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/22  PKK     pr_Waves_Action_ApproveToRelease: Initial revision (BK-1033)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_ApproveToRelease') is not null
  drop Procedure pr_Waves_Action_ApproveToRelease;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_ApproveToRelease: After waves are created, some clients
    require an approval process before the wave can be released for allocation.
    This action does this. This is similar to the "Plan" Wave process which means
    the wave has been finalized and is ready.
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_ApproveToRelease
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
          @xmlRulesData                TXML,
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
          @ttWavesUpdated              TEntityKeysTable;
begin /* pr_Waves_Action_ApproveToRelease */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'ApproveToReleaseWave';

  /* Fetching required data from XML */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get total count from temp table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Perform the actual updates */
  update W
  set W.Status     = 'B' /* Planned/Approved */,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output inserted.WaveId, inserted.WaveNo
  into @ttWavesUpdated (EntityId, EntityKey)
  from Waves W join #ttSelectedEntities SE on (W.Waveid = SE.Entityid)
  where (W.Status = 'N' /* New */);

  /* Get the total Updated count */
  select @vRecordsUpdated = @@rowcount;

  /*----------------- Audit Trail ----------------*/
  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Wave', @ttWavesUpdated, @BusinessUnit;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_ApproveToRelease */

Go
