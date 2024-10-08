/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/04  AY      pr_Locations_ChangeLocationStorageType: Setup LocationSubType on LocationType changes (HPI-GoLive)
  2016/10/26  ??      pr_Locations_ChangeLocationStorageType: Included update statements to recalculate the PA/Pick paths (HPI-GoLive)
  2016/01/19  NY      pr_Locations_ChangeLocationStorageType,pr_Locations_Generate :
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_ChangeLocationStorageType') is not null
  drop Procedure pr_Locations_ChangeLocationStorageType;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_ChangeLocationStorageType:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_ChangeLocationStorageType
  (@Locations       TEntityKeysTable   readonly,
   @LocationId      TRecordId, -- future use
   @LocationType    TLocationType,
   @StorageType     TStorageType,
   @UserId          TUserId,
   @BusinessUnit    TBusinessUnit,
   @Message         TNVarChar output)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,

          @vTotalQuantity     TQuantity,
          @vControlCategory   TCategory,
          @vValidStorageType  TControlValue,
          @vLocationId        TRecordId,
          @vRecordId          TRecordId,

          @vLocation          TLocation,
          @vAuditRecordId     TRecordId,
          @vAuditActivity     TActivityType,
          @vLocationsUpdated  TCount,
          @vInvalidLocations  TCount,
          @vLocationsCount    TCount,
          @vAction            TAction,

          @vLocationTypeDesc  TDescription,
          @vStorageTypeDesc   TDescription,
          @vLocationSubType   TTypeCode;

  declare @ttLocations        TEntityKeysTable,
          @ttAuditLocations   TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @vRecordId   = 0  ,

         @vAction           = 'ChangeLocationStorageType',
         @vAuditActivity    = @vAction,
         @vTotalQuantity    = 0,
         @vControlCategory  = 'Location_' + @LocationType,
         @vValidStorageType = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidStorageType', 'AU',
                                                          @BusinessUnit, @UserId),
         @vLocationSubType  = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultSubType', 'D',
                                                          @BusinessUnit, @UserId);

  /* Get the Locations to temp table */
  if (@LocationId is not null)
    insert into @ttLocations(EntityId)
      select @LocationId
  else
    insert into @ttLocations(EntityId)
      select EntityId
      from @Locations;

  /* Get number of rows inserted */
  select @vLocationsCount = @@rowcount;

  /* get the description for entity types */
  select @vLocationTypeDesc = TypeDescription from EntityTypes where Entity = 'Location' and TypeCode = @LocationType;
  select @vStorageTypeDesc  = TypeDescription from EntityTypes where Entity = 'LocationStorage' and TypeCode = @StorageType;

  /* Validate the user selected Locationtype and Storage type */
  if (charindex(@StorageType, @vValidStorageType) = 0)
    select @MessageName = @vLocationTypeDesc + 'StorageTypeIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Delete the Locations from temp table if they are not empty */
  delete TT
  from @ttLocations TT
    inner join Locations L on L.LocationId = TT.EntityId and L.BusinessUnit = @BusinessUnit
  where (L.Status <> 'E');

  select @vInvalidLocations = @@rowcount;

  /* Update the LocationType and StorageType for remaining Locations.
     When Location Type changes, the subtype also would change as it depends upon the Location Type */
  update Loc
  set LocationType    = @LocationType,
      StorageType     = @StorageType,
      LocationSubType = coalesce(@vLocationSubType, LocationSubType),
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  output Inserted.LocationId, Inserted.Location into @ttAuditLocations
  from Locations Loc
    join @ttLocations TT on (Loc.LocationId = TT.EntityId);

  /* After the LocationType is changed, we need to recalc the PA/Pick paths as the LocationType affects the path */
  update Loc
  set PickPath       = dbo.fn_Locations_GetPath(Location, null, 'PickPath', @BusinessUnit, @UserId),
      PutawayPath    = dbo.fn_Locations_GetPath(Location, null, 'PutawayPath', @BusinessUnit, @UserId)
  from Locations Loc
    join @ttLocations TT on (Loc.LocationId = TT.EntityId);

  /* get the updated location count */
  set @vLocationsUpdated = @@rowcount;

  /* Framing result message. */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse 'Locations', @vAction, @vLocationsUpdated, @vLocationsCount;

  /* If there are invalid/unqualified Locations that were not processed then let user know about it */
  if (@vInvalidLocations > 0)
    select @Message += dbo.fn_Messages_Build('ChangeLocationType_LocationsNotEmpty', @vInvalidLocations, null, null, null, null);

  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vLocationTypeDesc,
                            @Note2         = @vStorageTypeDesc,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttAuditLocations, @BusinessUnit;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_ChangeLocationStorageType */

Go
