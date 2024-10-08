/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/15  AJM     pr_Locations_Action_UpdateAllowedOperations: Initial Revision (CIMSV3-1280)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_UpdateAllowedOperations') is not null
  drop Procedure pr_Locations_Action_UpdateAllowedOperations;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_UpdateAllowedOperations: This procedure used to update the
    AllowedOperations on selected locations
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_UpdateAllowedOperations
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
          @vAction               TAction,
          @vAllowedOperations    TDescription,
          /* Process variables */
          @vNote1                TDescription;

  declare @ttLocationsUpdated    TEntityKeysTable;
begin /* pr_Locations_Action_UpdateAllowedOperations */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_Loc_UpdateAllowedOperations'

  select @vEntity            = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction            = Record.Col.value('Action[1]', 'TAction'),
         @vAllowedOperations = Record.Col.value('(Data/AllowedOperations) [1]', 'TDescription')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* There are no validations */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Update the remaining Locations */
  update L
  set AllowedOperations = case
                            when @vAllowedOperations = 'Release' then replace(AllowedOperations, 'N', '')
                            else @vAllowedOperations
                          end,
      ModifiedDate      = current_timestamp,
      ModifiedBy        = @UserId
  output Inserted.LocationId, Inserted.Location into @ttLocationsUpdated(EntityId, EntityKey)
  from Locations L join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Location', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vAllowedOperations, null, null, null, null) /* Comment */
    from @ttLocationsUpdated;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_UpdateAllowedOperations */

Go
