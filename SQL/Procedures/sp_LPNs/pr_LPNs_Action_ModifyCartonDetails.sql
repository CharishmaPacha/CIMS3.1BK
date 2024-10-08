/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/05  PKK     pr_LPNs_Action_ModifyCartonDetails: Made changes to void the shiplabels and generate the new one (BK-867)
  2020/11/11  MS      pr_LPNs_Action_ModifyCartonDetails: Added new proc to modify cartontype (CIMSV3-1155)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ModifyCartonDetails') is not null
  drop Procedure pr_LPNs_Action_ModifyCartonDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ModifyCartonDetails:
   This procedure modfies the CartonType and weight of the selected LPNs
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ModifyCartonDetails
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
          @vNewCartonType              TCartonType,
          @vNewWeight                  TWeight,
          @vCartonTypeId               TRecordId,
          @vCartonTypeStatus           TStatus;

  declare @ttLPNsToRecount             TRecountKeysTable,
          @ttShipLabelsToVoid          TEntityKeysTable;

  declare @ttLPNsInfo table (LPNId           TRecordId,
                             LPN             TLPN,
                             LPNStatus       TStatus,
                             OldCartonType   TCartonType,
                             OldWeight       TWeight,
                             NewCartonType   TCartonType,
                             NewWeight       TWeight,
                             RecordId        TRecordId identity(1,1));
begin /* pr_LPNs_Action_ModifyCartonDetails */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vAuditActivity = 'AT_LPNCartonDetailsModified';

  /* Create temp tables */
  select * into #LPNsUpdated from @ttLPNsInfo;

  /* Get the Action from the xml */
  select @vEntity        = Record.Col.value('Entity[1]',             'TEntity'),
         @vAction        = Record.Col.value('Action[1]',             'TAction'),
         @vNewCartonType = Record.col.value('(Data/CartonType)[1]',  'TCartonType'),
         @vNewWeight     = Record.Col.value('(Data/Weight)[1]',      'TWeight')
  from @xmlData.nodes('/Root') as Record(Col);

  select @vCartonTypeId     = RecordId,
         @vCartonTypeStatus = Status
  from CartonTypes
  where (CartonType = @vNewCartonType) and (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vNewCartonType is null)
    set @vMessageName = 'CartonTypeIsRequired';
  else
  if (@vCartonTypeId is null)
    set @vMessageName = 'CartonTypeIsInvalid';
  else
  if (@vCartonTypeStatus <> 'A' /* Active */)
    set @vMessageName = 'CartonTypeInactive';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the Total LPNs counts */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Update CartonType&Weight on the selected LPNs */
  update L
  set CartonType   = @vNewCartonType,
      ActualWeight = coalesce(nullif(@vNewWeight, 0), ActualWeight),
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output Inserted.LPNId, Inserted.LPN, Inserted.Status, Deleted.CartonType, Deleted.ActualWeight, Inserted.CartonType, Inserted.ActualWeight
  into #LPNsUpdated (LPNId, LPN, LPNStatus, OldCartonType, OldWeight, NewCartonType, NewWeight)
  from LPNs L
    join #ttSelectedEntities SE on (SE.EntityId = L.LPNId);

  set @vRecordsUpdated = @@rowcount;

  /* If no LPNs updated then return */
  if (@vRecordsUpdated = 0) goto BuildMessage;

  /* Get all the LPNs, void and insert new label */
  insert into @ttShipLabelsToVoid (EntityId, EntityKey)
    select LPNId, LPN from #LPNsUpdated where (LPNStatus <> 'S' /* Shipped */)

  exec pr_Shipping_VoidShipLabels null /* OrderId */, null /* LPNId */, @ttShipLabelsToVoid, @BusinessUnit, 'Y' /* RegenerateLabel - Yes */, null;

  /* In Packing sometimes user pause the package and so LPNs will struck in Packing,
     so when user again try to update CartonType then set the Status of the LPN to Packed */
  insert into @ttLPNsToRecount (EntityId, EntityKey)
    select LPNId, LPN from #LPNsUpdated where LPNStatus = 'G' /* Packing */;

  if (@@rowcount > 0)
    exec pr_LPNs_Recalculate @ttLPNsToRecount, 'S' /* SetStatus */, @UserId, 'D' /* Packed */;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select @vEntity, LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, NewCartonType, NewWeight, null, null, null) /* Comment */
    from #LPNsUpdated

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

BuildMessage:
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ModifyCartonDetails */

Go
