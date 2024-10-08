/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/29  VS      pr_LPNs_Action_ReGenerateTrackingNo: Regenerate the ShipLabels through the API (HA-3966)
  2021/03/24  TK      pr_LPNs_Action_ReGenerateTrackingNo: Resolved unique key constraint error (HA-GoLive)
  2020/12/16  PHK     pr_LPNs_Action_ReGenerateTrackingNo: Implemented a new action proc to regenerate tracking number (HA-1772)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ReGenerateTrackingNo') is not null
  drop Procedure pr_LPNs_Action_ReGenerateTrackingNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ReGenerateTrackingNo: We may have errors while generating
    the tracking numbers (wrong address, zip code, etc..)
    So we need the ability to re-generate the tracking number once the issue
    has been resolved and this proc is set up for a list of all LPNs of a given
    order or selected LPNs
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ReGenerateTrackingNo
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML         = null output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          /* Audit & Response */
          @vAuditActivity      TActivityType,
          @vValidStatuses      TControlValue,
          @ttAuditTrailInfo    TAuditTrailInfo,
          @vAuditRecordId      TRecordId,
          @vTotalRecords       TCount,
          @vProcessedLPNCount  TCount,
          @vRecordsUpdated     TCOunt,

           /* Input variables */
          @vEntity             TEntity,
          @vAction             TAction;

  declare @ttAuditLPNs          TEntityKeysTable;
  declare @ttUpdatedEntities    TEntityKeysTable;
  declare @ttShipLabelsToInsert TShipLabels;
begin

  /* Initialize */
  select @vReturnCode          = 0,
         @vMessageName         = null,
         @vTotalRecords        = 0,
         @vProcessedLPNCount   = 0,
         @vAuditActivity       = 'AT_RegenerateTrackingNo';

  /* Create temp tables */
  select * into #UpdatedEntities from @ttUpdatedEntities;

  /* Caller could pass in LPNs via #ShipLabelsToInsert, if not, then create one */
  if (object_id('tempdb..#ShipLabelsToInsert') is null)
    select * into #ShipLabelsToInsert from @ttShipLabelsToInsert;

  /* Get the Action from the xml */
  select @vEntity        = Record.Col.value('Entity[1]',             'TEntity'),
         @vAction        = Record.Col.value('Action[1]',             'TAction')
  from @xmlData.nodes('/Root') as Record(Col);

  /* We only would want to re-generate tracking no if the LPN is of valid status - there by
     preventing insertion of Putaway LPNs etc into Shiplables table even if user has chosen them */
  select @vValidStatuses = dbo.fn_Controls_GetAsString('Shipping', 'RegenerateTrackingNo', 'AFUKGDEL'/* Allocate, NewTemp, Picking, Picked, Packed, Staged, Loaded */,
                                                       @BusinessUnit, @UserId);

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get all the required info from LPNs for validations to avoid hitting the LPNs
     table again and again */
  select L.LPNId, L.LPN, L.LPNType, L.SKUId, L.SKU, cast(L.Status as varchar(30)) as LPNStatus,
  case when (dbo.fn_IsInList(L.Status, @vValidStatuses) = 0) then 'LPN_ReGenerateTrackingNo_InvalidLPNStatus'
       when (L.LPNType <> 'S' /* Ship Carton */)             then 'LPN_ReGenerateTrackingNo_InvalidLPNType'
       when (SL.Status       = 'A') and
            (SL.ProcessStatus not in ('LGE')) and
            (SL.TrackingNo   <> '')                          then 'LPN_ReGenerateTrackingNo_AlreadyGenerated'
       when (SL.Status       = 'A') and
            (SL.ProcessStatus in ('N', 'PA', 'GI')) and
            (SL.TrackingNo   = '')                           then 'LPN_ReGenerateTrackingNo_GenerationInProgress'
       when (S.IsSmallPackageCarrier = 'N')                  then 'LPN_ReGenerateTrackingNo_InvalidCarrier'
  end ErrorMessage
  into #InvalidLPNs
  from #ttSelectedEntities SE join LPNs L on (L.LPNId = SE.EntityId)
    join ShipLabels SL on (SL.EntityId = SE.EntityId)
    join OrderHeaders OH on (L.OrderId               = OH.OrderId)
    join ShipVias     S  on (S.ShipVia               = OH.ShipVia) and
                            (S.BusinessUnit          = OH.BusinessUnit);

  /* Get the status description for the error message */
  update #InvalidLPNs
  set LPNStatus = dbo.fn_Status_GetDescription('LPN', LPNStatus, @BusinessUnit);

  /* Exclude the LPNs that have errors */
  delete from SE
  output 'E', IL.LPNId, IL.LPN, IL.ErrorMessage, IL.LPNStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE join #InvalidLPNs IL on (SE.EntityId = IL.LPNId)
  where (IL.ErrorMessage is not null);

  /* Reset Process Status if entry exists in ShipLabels table with an error.
     If the prior label was voided, then we shouldn't update it, we would create a new entry */
  update SL
  set ProcessStatus = 'N' /* No */
  output Inserted.EntityId, Inserted.EntityKey
  into #UpdatedEntities(EntityId, EntityKey)
  from ShipLabels SL
    join #ttSelectedEntities SE on (SL.EntityId      = SE.EntityId)   and
                                   (SL.ProcessStatus = 'LGE')         and
                                   (SL.Status        = 'A' /* Active */);

  /* Insert required ShipLabels to Generate the Labels */
  insert into #ShipLabelsToInsert(EntityId, EntityType, EntityKey, CartonType, OrderId, TaskId, WaveId, WaveNo, LabelType)
    select L.LPNId, 'L', L.LPN, L.CartonType, L.OrderId, L.TaskId, L.PickBatchId, L.PickBatchNo, ''
    from LPNs L
      join #UpdatedEntities SL on (L.LPNId = SL.EntityId);

  set @vProcessedLPNCount += @@rowcount;

  /* Regenerate the Labels and TrackingNo which inserted into #ShipLabelsToInsert table */
  exec pr_Shipping_ShipLabelsInsert 'LPNs' /* Module */, 'RegenerateTrackingNo', null, null, @BusinessUnit, @UserId/* UserId */;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select distinct 'LPN', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityKey, null, null, null, null) /* Comment */
    from #UpdatedEntities;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vProcessedLPNCount, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ReGenerateTrackingNo */

Go
