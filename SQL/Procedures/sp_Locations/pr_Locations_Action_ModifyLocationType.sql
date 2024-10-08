/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/14  AJM     pr_Locations_Action_ModifyLocationType: Made few changes (CIMSV3-1429) (Ported from Trunk)
  2021/04/06  AJM     pr_Locations_Action_ModifyLocationType: Made changes to Upadte LocationSubType (CIMSV3-1429)
  2020/11/01  RKC     pr_Locations_Action_ModifyLocationType: Added V3 module (CIMSV3-1181)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_ModifyLocationType') is not null
  drop Procedure pr_Locations_Action_ModifyLocationType;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_ModifyLocationType: Procedure to modify the LocationType,
    StorageType on the Locations.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_ModifyLocationType
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vMessage                TDescription,
          @vRecordId               TRecordId,
          /* Audit & Response */
          @vAuditActivity          TActivityType,
          @ttAuditTrailInfo        TAuditTrailInfo,
          @vNote1                  TDescription,
          @vRecordsUpdated         TCount,
          @vTotalRecords           TCount,
          /* Input variables */
          @vEntity                 TEntity,
          @vAction                 TAction,

          @vControlCategory        TCategory,
          @vValidStorageType       TControlValue,

          @vNewLocationTypeDesc    TDescription,
          @vNewStorageTypeDesc     TDescription,
          @vLocationSubTypeDesc    TDescription,
          @vDefaultLocationSubType TTypeCode,
          @vLocationSubType        TLocationType,
          @vNewLocationType        TLocationType,
          @vNewStorageType         TStorageType;

  declare @ttUpdatedLocations table
          (LocationId              TRecordId,
           Location                TLocation,

           OldLocationType         TLocationType,
           OLDLocationTypeDesc     TDescription,
           NewLocationType         TLocationType,
           NewLocationTypeDesc     TDescription,

           OldStorageType          TStorageType,
           OldStorageTypeDesc      TDescription,
           NewStorageType          TStorageType,
           NewStorageTypeDesc      TDescription,
           RecordId                TRecordId identity(1,1));
begin /* pr_Locations_Action_ModifyLocationType */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'AT_ModifyLocationType';

  /* Get the Selected data from input XML */
  select @vEntity          = Record.Col.value('Entity[1]',                 'TEntity'      ),
         @vAction          = Record.Col.value('Action[1]',                 'TAction'      ),
         @vNewLocationType = Record.Col.value('(Data/NewLocationType)[1]', 'TLocationType'),
         @vNewStorageType  = Record.Col.value('(Data/NewStorageType)[1]',  'TStorageType' ),
         @vLocationSubType = nullif(Record.Col.value('(Data/LocationSubType)[1]', 'TLocationSubType'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the ValidStorage type from controls */
  select @vControlCategory        = 'Location_' + @vNewLocationType,
         @vValidStorageType       = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStorageType', 'AU', @BusinessUnit, @UserId),
         @vDefaultLocationSubType = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultSubType', 'D', @BusinessUnit, @UserId);

  /* get the description for entity types */
  select @vNewLocationTypeDesc = dbo.fn_EntityType_GetDescription ('Location',        @vNewLocationType, @BusinessUnit);
  select @vNewStorageTypeDesc  = dbo.fn_EntityType_GetDescription ('LocationStorage', @vNewStorageType,  @BusinessUnit);
  select @vLocationSubTypeDesc = dbo.fn_EntityType_GetDescription ('LocationSubType', @vLocationSubType, @BusinessUnit);

  /* Validate if user selected invaild storage type for selected Locationtype */
  if (charindex(@vNewStorageType, @vValidStorageType) = 0)
    select @vMessageName = @vNewLocationTypeDesc + 'StorageTypeIsInvalid';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the total count of receipts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select * into #UpdatedLocations from @ttUpdatedLocations

  /* Delete the selected Locations from temp table if they are not empty */
  delete from SE
  output 'E', Deleted.EntityId, L.Location, 'ModifyLocationType_LocationsNotEmpty'
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
  from #ttSelectedEntities SE join Locations L on (L.LocationId = SE.EntityId)
  where (L.Status <> 'E' /* Empty */);

  /* Update the LocationType and StorageType for remaining Locations.
     When Location Type changes, the subtype also would change as it depends upon the Location Type */
  update Loc
  set LocationType    = @vNewLocationType,
      StorageType     = @vNewStorageType,
      LocationSubType = coalesce(@vLocationSubType, LocationSubType, @vDefaultLocationSubType),
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  output inserted.LocationId, inserted.Location, deleted.LocationType, inserted.LocationType, deleted.StorageType, inserted.StorageType
  into #UpdatedLocations (LocationId, Location, OldLocationType, NewLocationType, OldStorageType, NewStorageType)
  from Locations LOC
    join #ttSelectedEntities SE on (Loc.LocationId = SE.EntityId);

  /* get the updated location count */
  select @vRecordsUpdated = @@rowcount;

  /* After the LocationType is changed, we need to recalc the PA/Pick paths as the LocationType affects the path */
  update LOC
  set PickPath    = dbo.fn_Locations_GetPath(Location, null, 'PickPath',    @BusinessUnit, @UserId),
      PutawayPath = dbo.fn_Locations_GetPath(Location, null, 'PutawayPath', @BusinessUnit, @UserId)
  from Locations LOC join #ttSelectedEntities SE on (LOC.LocationId = SE.EntityId);

  /* Get the Changed Location Type Description & Storage Type description for Log info in AT messages */
  update #UpdatedLocations
  set OldLocationTypeDesc = dbo.fn_EntityType_GetDescription ('Location', OldLocationType, @BusinessUnit),
      NewLocationTypeDesc = @vNewLocationTypeDesc,
      OldStorageTypeDesc  = dbo.fn_EntityType_GetDescription ('LocationStorage', OldStorageType, @BusinessUnit),
      NewStorageTypeDesc  = @vNewStorageTypeDesc;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Location Type', @vNewLocationTypeDesc);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Storage Type',  @vNewStorageTypeDesc);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Sub Type',      @vLocationSubTypeDesc);

  /* Insert Audit Trail for modified Locations */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Location', LocationId, Location, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vNote1, null, null, null, null) /* Comment */
    from #UpdatedLocations;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_ModifyLocationType */

Go
