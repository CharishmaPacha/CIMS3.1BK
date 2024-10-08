/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  AJM     pr_Locations_Action_ModifyAttributes: Initial Revision (CIMSV3-1428)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_ModifyAttributes') is not null
  drop Procedure pr_Locations_Action_ModifyAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_ModifyAttributes: This procedure used to change
    the LocationAttributes on selected locations
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_ModifyAttributes
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,
          /* Audit & Response */
          @vAuditActivity         TActivityType,
          @ttAuditTrailInfo       TAuditTrailInfo,
          @vAllowMultipleSKUs     TControlValue,
          @vAllowMultipleSKUsDesc TDescription,
          @vRecordsUpdated        TCount,
          @vTotalRecords          TCount,
          /* Input variables */
          @vEntity                TEntity,
          @vAction                TAction;

begin /* pr_Locations_Action_ModifyAttributes */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'AT_ModifyLocationAtrributes'

  select @vEntity            = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction            = Record.Col.value('Action[1]', 'TAction'),
         @vAllowMultipleSKUs = nullif(Record.Col.value('(Data/AllowMultipleSKUs) [1]', 'TFlags'),  '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the Look up description for the give look up code */
  select @vAllowMultipleSKUsDesc = dbo.fn_LookUps_GetDesc ('YesNo', @vAllowMultipleSKUs, @BusinessUnit, default);

  /* Validations */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* If new Allow Multiple SKUs and existing AllowMultipleSKUs value are same delete them from #table */
  delete ttSE
  output 'E', 'LocationModifyAttrs_AllowMultipleSKUsSame', L.Location, @vAllowMultipleSKUsDesc
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from Locations L join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId)
  where (L.AllowMultipleSKUs = @vAllowMultipleSKUs);

  /* Update the remaining Locations */
  update L
  set AllowMultipleSKUs = coalesce(@vAllowMultipleSKUs, AllowMultipleSKUs),
      ModifiedDate      = current_timestamp,
      ModifiedBy        = @UserId
  from Locations L
    join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount;

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Location', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vAllowMultipleSKUsDesc, null, null, null, null) /* Comment */
    from #ttSelectedEntities;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_ModifyAttributes */

Go
