/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  AJM     pr_Locations_Action_ModifyPickZone: Initial Revision (CIMSV3-1231)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_ModifyPickZone') is not null
  drop Procedure pr_Locations_Action_ModifyPickZone;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_ModifyPickZone: This procedure used to change the
    PickZone on selected locations
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_ModifyPickZone
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
          @vPickZone             TLookUpCode,
          @vLocationsCount       TCount,
          @vNote1                TDescription,
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount,
          /* Input variables */
          @vEntity               TEntity,
          @vAction               TAction;

  declare @ttLocationsUpdated    TEntityKeysTable;
begin /* pr_Locations_Action_ModifyPickZone */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_LocPickZoneModified'

  select @vEntity      = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction      = Record.Col.value('Action[1]', 'TAction'),
         @vPickZone    = Record.Col.value('(Data/PickZone) [1]', 'TLookUpCode')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Validations */
  /* Check if the PickZone is passed or not */
  if (@vPickZone is null)
    set @vMessageName = 'PickZoneIsRequired';
  else
  /* Check if the PickZone is Active or not */
  if (not exists(select *
                     from vwLookUps
                     where LookUpCategory = 'PickZones' and
                           LookUpCode     = @vPickZone))
   set @vMessageName = 'InvalidPickZone';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Delete the Locations which already have selected Pickzone */
  delete ttSE
  output 'I', 'Locations_ModifyPickZone_SamePickZone', L.Location, L.PickingZone
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from Locations L
    join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId)
  where (L.PickingZone = @vPickZone); /* Should not update if Prev and selected PickZone is same */

  /* Update the remaining Locations */
  update L
  set PickingZone  = @vPickZone,
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
           dbo.fn_Messages_Build(@vAuditActivity, @vPickZone, null, null, null, null) /* Comment */
    from @ttLocationsUpdated;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_ModifyPickZone */

Go
