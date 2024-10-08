/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/20  OK      pr_Waves_Action_Modify: Removed the unnecessary validation to allow update other attributes on Wave (BK-427)
  2021/06/03  AJM     pr_Waves_Action_Modify : Initial Revision (CIMSV3-1462)
  2021/05/13  AJM     pr_Waves_Action_Modify : Initial Revision (CIMSV3-1462)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_Action_Modify') is not null
  drop Procedure pr_Waves_Action_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_Action_Modify: This procedure used to change the
    Priority, Drop Location and dates on selected waves
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_Action_Modify
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
          @vPriority                   TPriority,
          @vDropLocation               TLocation,
          @vShipDate                   TDate,
          @vCancelDate                 TDate,
          /* Process variables */
          @vValidWaveStatus            TControlValue,
          @vNote1                      TDescription;

  declare @ttWavesUpdated              TEntityKeysTable;
begin /* pr_Waves_Action_Modify */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'WaveModified'

  select @vEntity       = Record.Col.value('Entity[1]',                    'TEntity'),
         @vAction       = Record.Col.value('Action[1]',                    'TAction'),
         @vPriority     = Record.Col.value('(Data/Priority)[1]',           'TPriority'),
         @vDropLocation = Record.Col.value('(Data/DropLocation)[1]',       'TLocation'),
         @vShipDate     = nullif(Record.Col.value('(Data/ShipDate)[1]',    'TDate'), ''),
         @vCancelDate   = nullif(Record.Col.value('(Data/CancelDate)[1]',  'TDate'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vShipDate   = nullif(@vShipDate,   '0001-01-01'),
         @vCancelDate = nullif(@vCancelDate, '0001-01-01');

  /* Get the total count of LPNs from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select @vValidWaveStatus =  dbo.fn_Controls_GetAsString('Modify', 'ValidWaveStatus', 'NBLERPUKACGO' /* New */ /* Planned */ /* Ready To Pull */ /* Released */ /* ReadyToPick */ /* Picking */ /* Paused */ /* Picked */ /* Packing */ /* Packed */ /* Staged */ /* Loaded */, @BusinessUnit, null/* UserId */);

  /* Validations */
  /* Check if the Priority is passed or not */
  if (@vPriority is null)
    set @vMessageName = 'PriorityIsRequired';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If any wave has invalid status, delete it here */
  delete ttSE
  output 'E', 'Waves_Modify_InvalidStatus', W.WaveNo, W.WaveStatusDesc
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from vwWaves W join #ttSelectedEntities ttSE on (W.WaveId = ttSE.EntityId)
  where (charindex(W.WaveStatus, @vValidWaveStatus) = 0);

  /* Update all Waves remaining in the temp table */
  update W
  set Priority     = @vPriority,
      DropLocation = coalesce(@vDropLocation, DropLocation),
      ShipDate     = coalesce(@vShipDate,     ShipDate),
      CancelDate   = coalesce(@vCancelDate,   CancelDate),
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output Deleted.RecordId, Deleted.BatchNo
  into @ttWavesUpdated(EntityId, EntityKey)
  from Waves W join #ttSelectedEntities ttSE on (W.BatchNo = ttSE.EntityKey);

  select @vRecordsUpdated = @@rowcount;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Priority',     @vPriority);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'DropLocation', @vDropLocation);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'ShipDate',     @vShipDate);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'CancelDate',   @vCancelDate);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Wave', @ttWavesUpdated, @BusinessUnit;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_Action_Modify */

Go
