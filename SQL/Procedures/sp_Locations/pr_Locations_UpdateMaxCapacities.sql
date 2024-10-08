/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/29  TD      Added new procedure pr_Locations_UpdateMaxCapacities
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_UpdateMaxCapacities') is not null
  drop Procedure pr_Locations_UpdateMaxCapacities;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_UpdateMaxCapacities:  This procedure will take UpdateDefaultClass as
       input and based on this flag we will update the location max capacities.

      If the flag says Yes then we will get the values from controls and then we will
      update those on given locations.

      If the flag says no, then we will update the given values on the locations.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_UpdateMaxCapacities
  (@Locations                TEntityKeysTable   readonly,
   @LocationId               TRecordId,
   @UpdateDefaultCapacities  TFlags,
   @LocationClass            TCategory      = null,
   @MaxPallets               TCount         = null,
   @MaxLPNs                  TCount         = null,
   @MaxInnerPacks            TCount         = null,
   @MaxUnits                 TCount         = null,
   @MaxVolume                TVolume        = null,
   @MaxWeight                TWeight        = null,
   @BusinessUnit             TBusinessUnit,
   @UserId                   TUserId        = null,
   @Message                  TNVarChar output)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,

          @vLocClassCategory  TCategory,

          @vAuditRecordId     TRecordId,
          @vAuditActivity     TActivityType,
          @vLocationsUpdated  TCount,

          @vLocationsCount    TCount,
          @vAction            TAction,

          @ttLocations        TEntityKeysTable,
          @ttAuditLocations   TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @ReturnCode        = 0,
         @MessageName       = null,
         @vAction           = 'ChangeLocationProfile',
         @vLocClassCategory = 'LocationClass_' + coalesce(@LocationClass, '');

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

  /* if the user selects update max capacities based on the location class then we need to get it
     from controls and update those values */
  if (@UpdateDefaultCapacities = 'Y' /* Yes */) and (@LocationClass is not null)
    begin
      /* Get all values from controls for the given location class */
      select @MaxPallets     = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxPallets', 99,
                                                            @BusinessUnit, @UserId),
             @MaxLPNs        = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxLPNs', 99,
                                                            @BusinessUnit, @UserId),
             @MaxInnerPacks  = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxInnerPacks', 99,
                                                            @BusinessUnit, @UserId),
             @MaxUnits       = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxUnits', 9999,
                                                            @BusinessUnit, @UserId),
             @MaxVolume      = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxVolume', 999,
                                                            @BusinessUnit, @UserId),
             @MaxWeight      = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxWeight', 999,
                                                            @BusinessUnit, @UserId);
    end

  /* Let Audit reflect what was updated */
  select @vAuditActivity = case
                             when (@UpdateDefaultCapacities = 'Y' /* Yes */) and (@LocationClass is not null) then
                               'ChangeLocClassWithCapacities'
                             when (@LocationClass is null) then
                               'ChangeLocationCapacities'
                             else
                               'ChangeLocationClassAndCapacities'
                           end;

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update LocationClass and capacities on the Locations */
  update L
  set LocationClass = coalesce(@LocationClass, LocationClass),
      MaxPallets    = coalesce(@MaxPallets, MaxPallets),
      MaxLPNs       = coalesce(@MaxLPNs, MaxLPNs),
      MaxInnerPacks = coalesce(@MaxInnerPacks, MaxInnerPacks),
      MaxUnits      = coalesce(@MaxUnits,  MaxUnits),
      MaxVolume     = coalesce(@MaxVolume, MaxVolume),
      MaxWeight     = coalesce(@MaxWeight, MaxWeight),
      ModifiedBy    = @UserId
  output Inserted.LocationId, Inserted.Location into @ttAuditLocations
  from Locations L join @ttLocations LP on (LP.EntityId = L.LocationId)

  /* get the updated location count */
  select @vLocationsUpdated = @@rowcount;

  /* Framing result message. */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse 'Locations', @vAction, @vLocationsUpdated, @vLocationsCount;

  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @LocationClass,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttAuditLocations, @BusinessUnit;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_UpdateMaxCapacities */

Go
