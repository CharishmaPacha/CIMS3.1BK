/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/04  AJM     pr_Locations_Action_ModifyPutawayZone: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_ModifyPutawayZone') is not null
  drop Procedure pr_Locations_Action_ModifyPutawayZone;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_ModifyPutawayZone: This procedure used to change the
    PutawayZone on selected locations
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_ModifyPutawayZone
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,
          @vRecordId             TRecordId,
          /* Audit & Response */
          @vAuditActivity        TActivityType,
          @ttAuditTrailInfo      TAuditTrailInfo,
          @vPutawayZone          TLookUpCode,
          @vLocationsCount       TCount,
          @vNote1                TDescription,
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount,
          /* Input variables */
          @vEntity               TEntity,
          @vAction               TAction;

  declare @ttLocationsUpdated    TEntityKeysTable;
begin /* pr_Locations_Action_ModifyPutawayZone */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_LocPutawayZoneModified'

  select @vEntity      = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction      = Record.Col.value('Action[1]', 'TAction'),
         @vPutawayZone = Record.Col.value('(Data/PutawayZone) [1]', 'TLookUpCode')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */
  /* Check if the PutawayZOne is passed or not */
  if (@vPutawayZone is null)
    set @vMessageName = 'PutawayZoneIsRequired';
  else
  /* Check if the PutawayZone is Active or not */
  if (not exists(select *
                     from vwLookUps
                     where LookUpCategory = 'PutawayZones' and
                           LookUpCode     = @vPutawayZone))
    set @vMessageName = 'InvalidPutawayZone';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Delete the Locations which already have selected PA zone */
  delete ttSE
  output 'I', 'Locations_ModifyPutawayZone_SamePutawayZone', L.Location, L.PutawayZone
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from Locations L
    join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId)
  where (L.PutawayZone = @vPutawayZone); /* Should not update if Prev and selected PutawayZone is same */

  /* Update the remaining Locations */
  update L
  set PutawayZone  = @vPutawayZone,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output Inserted.LocationId, Inserted.Location
  into @ttLocationsUpdated(EntityId, EntityKey)
  from Locations L
    join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Location', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vPutawayZone, null, null, null, null) /* Comment */
    from @ttLocationsUpdated;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_ModifyPutawayZone */

Go
