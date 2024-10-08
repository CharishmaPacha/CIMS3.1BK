/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/25  AJM     pr_Locations_Action_DeleteLocation: Initial Revision (CIMSV3-1241)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_DeleteLocation') is not null
  drop Procedure pr_Locations_Action_DeleteLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_DeleteLocation: This procedure is used to delete the
  locations
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_DeleteLocation
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
          @vRecordsUpdated       TCount,
          @vTotalRecords         TCount,
          /* Input variables */
          @vEntity               TEntity,
          @vAction               TAction;

  declare @ttLocationsDeleted    TEntityKeysTable;
begin /* pr_Locations_Action_DeleteLocation */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_DeleteLocation'

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Remove locations from the list which have LPNs in them */
  delete ttSE
  output 'E', 'LocDelete_AssociatedLPNs', Deleted.EntityKey
  into #ResultMessages (MessageType, MessageName, Value1)
  from #ttSelectedEntities ttSE
    join Locations LOC on (LOC.LocationId = ttSE.EntityId)
    join LPNs L on (LOC.LocationId = L.LocationId);

  /* Remove locations from the list which have LPNs coming to them */
  delete ttSE
  output 'E', 'LocDelete_DirectedLPNs', Deleted.EntityId, Deleted.EntityKey
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from #ttSelectedEntities ttSE
    join Locations LOC on (LOC.LocationId = ttSE.EntityId)
    join LPNs L on (L.DestLocation = LOC.Location) and (L.BusinessUnit = LOC.BusinessUnit);

  /* Delete only the Locations that are empty or inactive */
  update LOC
  set Status   = 'D' /* Deleted */,
      Location = Location + '-' + convert(varchar(15), LocationId) + '-' + '*',
      Barcode  = Barcode + '-' + convert(varchar(15), LocationId) + '-' + '*'
  output Inserted.LocationId, Inserted.Location into @ttLocationsDeleted(EntityId, EntityKey)
  from Locations LOC join #ttSelectedEntities ttSE on (LOC.LocationId = ttSE.EntityId)
  where (LOC.BusinessUnit = @BusinessUnit) and
        (LOC.Status in ('E', 'I' /* Empty, InActive */)) and
        (LOC.Quantity     = 0);

  select @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Location', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, EntityKey, null, null, null, null) /* Comment */
    from @ttLocationsDeleted;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_DeleteLocation */

Go
