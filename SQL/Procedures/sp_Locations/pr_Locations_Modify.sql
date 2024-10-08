/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/12  RT      pr_Locations_Modify: Added LocationSubType (HPI-2131)
  2018/06/12  TK      pr_Locations_Modify: Modify Locations action not working (S2G-Support)
  2018/06/07  AJ      pr_Locations_Modify: Added ModifyLocationAttributes action (S2G-904)
                      pr_Locations_Modify:Changes to Modify Location profile and capacities (CIMS-1741)
  2017/02/17  MV      pr_Locations_Modify: Added  a new action  AllowOnholdOperations (GNC-1427).
  2016/07/08  TD      pr_Locations_Modify:Change to update Barcode as well when we delete location.
  2016/05/12  OK      pr_Locations_Modify: Made changes to allow deleting InActive locations with zero quanity (HPI-85)
  2016/02/18  OK      pr_Locations_Modify: Enhanced to log the Audit Trail on deleting locations (NBD-169)
  2016/01/20  NY      pr_Locations_Modify: Recalculate Location after activate.
  2015/11/03  SV      pr_Locations_Modify: Changes for DeleteLocation action (NBD-35)
  2014/07/15  AK      pr_Locations_Modify: Added audit trail for activate and deactivate locations.
  2014/03/03  NY      pr_Locations_Modify: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  2103/06/04  TD      pr_Locations_Modify: Changes about Activate and Deactivate Locations.
  2012/12/07  SP      pr_Locations_Modify: Changed the signature of the procedure to pass businessUnit
  2012/11/30  NY      pr_Locations_Modify:Implemented AT for modify Putaway/PickZones
  2012/06/30  SP      Placed the transaction controls in 'pr_Locations_Modify'.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Modify') is not null
  drop Procedure pr_Locations_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Modify
  (@LocationContents  TXML,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Message           TNVarChar output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vEntity             TEntity  = 'Location',
          @vAction             TAction,
          @vLocations          TLocation,
          @vPutawayZone        TLookUpCode,
          @vPickZone           TLookUpCode,
          @vAllowedOperations  TDescription,
          @vLocationId         TRecordId,
          @vLocationType       TLocationType,
          @vStorageType        TStorageType,
          @xmlData             xml,
          @vLocationsCount     TCount,
          @vLocationsUpdated   TCount,
          @vRecordId           TRecordId,
          @vEntityId           TRecordid,
          @vAddlMsg            TDescription,
          @vBusinessUnit       TBusinessUnit,
          @vAllowMultipleSKUs  TControlValue,
          @vLocationSubType    TLocationType,
          @vLocationSubTypeDesc
                               TDescription,

          @vLocationClass      TCategory,
          @vMaxPallets         TCount,
          @vMaxLPNs            TCount,
          @vMaxInnerPacks      TCount,
          @vMaxUnits           TCount,
          @vMaxWeight          TWeight,
          @vMaxVolume          TVolume,

          @vLocClassCategory   TCategory,
          @vUpdateLocDefaultCapacities
                               TFlags;

   declare @vNote1             TDescription,
           @vNote2             TDescription,
           @vActivityType      TActivityType,
           @vAuditId           TRecordId,
           @vAuditRecordId     TRecordId;

  /* Temp table to hold all the Locations to be updated */
  declare @ttLocations         TEntityKeysTable;
  declare @ttLocationsUpdated  TEntityKeysTable;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;
  set @xmlData = convert(xml, @LocationContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/ModifyLocations') as Record(Col);

  /* Load all the Locations into the temp table which are to be updated in Locatiom table */
  insert into @ttLocations (EntityId)
    select Record.Col.value('.', 'TRecordId') Location
    from @xmlData.nodes('/ModifyLocations/Locations/LocationId') as Record(Col);

  /* Get number of rows inserted */
  select @vLocationsCount = @@rowcount;

  if (@vAction = 'ModifyPutawayZone')
    begin
      select @vPutawayZone = Record.Col.value('PutawayZone[1]', 'TLookUpCode')
      from @xmlData.nodes('/ModifyLocations/Data') as Record(Col);

      /* Check if the PutawayZOne is passed or not */
      if (@vPutawayZone is null)
        set @MessageName = 'PutawayZoneIsRequired';
      else
      /* Check if the PutawayZone is Active or not */
      if (not exists(select *
                     from vwLookUps
                     where LookUpCategory = 'PutawayZones' and
                           LookUpCode     = @vPutawayZone))
        set @MessageName = 'InvalidPutawayZone';

      if (@MessageName is not null)
        goto ErrorHandler;

      /* Update only if there is a change in PutawayZone.*/
      update L
      set PutawayZone    = @vPutawayZone,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Inserted.LocationId, Inserted.Location into @ttLocationsUpdated
      from Locations L
        join @ttLocations LP on (LP.EntityId = L.LocationId)
      where (coalesce(L.PutawayZone,'') <> @vPutawayZone);

      /*Get the count of total number of locations Updated */
      set @vLocationsUpdated = @@rowcount;

      /* AT related */
      select @vActivityType = 'LocPutawayZoneModified',
             @vNote1        = @vPutawayZone;
    end
  else
  if (@vAction = 'ModifyPickZone')
    begin
      select @vPickZone = Record.Col.value('PickZone[1]', 'TLookUpCode')
      from @xmlData.nodes('/ModifyLocations/Data') as Record(Col);

      /* Check if the PickZOne is passed or not */
      if (@vPickZone is null)
        set @MessageName = 'PickZoneIsRequired';
      else
      /* Check if the PickZone is Active or not */
      if (not exists(select *
                     from vwLookUps
                     where LookUpCategory = 'PickZones' and
                           LookUpCode     = @vPickZone))
        set @MessageName = 'InvalidPickZone';

      if (@MessageName is not null)
        goto ErrorHandler;

      /* Update only if there is a change in PickZone.*/
      update L
      set PickingZone    = @vPickZone,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Inserted.LocationId, Inserted.Location into @ttLocationsUpdated
      from Locations L
        join @ttLocations LP on (LP.EntityId = L.LocationId)
      where (coalesce(L.PickingZone,'') <> @vPickZone);

      /*Get the count of total number of locations Updated */
      set @vLocationsUpdated = @@rowcount;

      /* AT related */
      select @vActivityType  = 'LocPickZoneModified',
             @vNote1         = @vPickZone;
    end
  else
  if (@vAction = 'UpdateAllowedOperations')
    begin
      select @vAllowedOperations = Record.Col.value('AllowedOperations[1]', 'TDescription')
      from @xmlData.nodes('/ModifyLocations/Data') as Record(Col);

      /* Update only if there is a change in AllowOnholdOperations.
        If caller sends an Operation as Release then we want to allow the location for other operations what
        we have defined on the location earlier, because assumption is, until this point the location will be in onhold, and no operations will
        allow to do */
      update L
      set AllowedOperations = case
                                when @vAllowedOperations = 'Release' then replace(AllowedOperations, 'N', '')
                                else @vAllowedOperations
                              end,
          ModifiedDate      = current_timestamp,
          ModifiedBy        = @UserId
      output Inserted.LocationId, Inserted.Location
      into @ttLocationsUpdated
      from Locations L
        join @ttLocations LP on (LP.EntityId = L.LocationId);

      /*Get the count of total number of locations Updated */
      set @vLocationsUpdated = @@rowcount;

      /* AT related */
      select @vActivityType = case when @vAllowedOperations = 'Release' then 'Loc_ReleaseOnhold'
                                   else 'Loc_UpdateAllowedOperations'
                              end,
             @vNote1        = @vAllowedOperations;
    end
  else
  if (@vAction = 'Activate')
    begin
      /* Update Location.*/
      update L
      set Status         = 'E' /* Empty - it nothing but activating */,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Inserted.LocationId, Inserted.Location into @ttLocationsUpdated
      from Locations L
        join @ttLocations LA on (LA.EntityId = L.LocationId)
      where (L.Status = 'I' /* Inactive */)

      select @vLocationsUpdated = @@rowcount,
             @vRecordId         = 0,
             @vActivityType     = 'ActivateLocation';

      /* Recalculate Location status after activating the location */
      while (exists (select * from @ttLocationsUpdated where RecordId > @vRecordId))
        begin
           select top 1 @vRecordId   = RecordId,
                        @vLocationId = EntityId
           from @ttLocationsUpdated
           where (RecordId > @vRecordId)
           order by RecordId;

           exec pr_Locations_SetStatus @vLocationId, '*';
        end
    end
  else
  if (@vAction = 'Deactivate')
    begin
      /* If there are any Locations which are not Empty then alert the user */
      if (exists (select *
                  from @ttLocations TL
                    join Locations L on (L.LocationId = TL.EntityId)
                  where L.Status <> 'E' /* Empty */))
        set @MessageName = 'Location_CannotDeactivate';

      if (@MessageName is not null)
        goto ErrorHandler;

      /* Update Location.*/
      update L
      set Status         = 'I' /* Inactivate */,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output Inserted.LocationId, Inserted.Location
      into @ttLocationsUpdated
      from Locations L
        join @ttLocations LD on (LD.EntityId = L.LocationId)
      where (L.Status = 'E'/* Empty */)

      select @vLocationsUpdated = @@rowcount,
             @vActivityType     = 'DeactivateLocation';
    end
  else
  if (@vAction = 'DeleteLocation')
    begin
      /* Remove locations from the list which have LPNs in them or coming to them */
      delete @ttLocations
      from @ttLocations TL join Locations LOC on (LOC.LocationId = TL.EntityId)
       join LPNs L on ((LOC.LocationId = L.LocationId) or (L.DestLocation = LOC.Location));

      if (@@rowcount > 0)
        exec @vAddlMsg = dbo.fn_Messages_Build 'LocDelete_AssociatedLPNs', @@rowcount;

      /* Delete Locations.*/
      /*delete Locations
      output Deleted.LocationId, Deleted.Location into @ttLocationsUpdated
      from Locations LOC join @ttLocations TL on (LOC.LocationId = TL.EntityId)
      where (LOC.BusinessUnit = @BusinessUnit) and
            (LOC.Status = 'E' ) and
            (LOC.Quantity = 0); -- just a safety check.  */

      /* we do not want to delete entire location, we need to update with some char,
         so that this will usefull in productivity/ audittrail in future */
      update LOC
      set Status   = 'D' /* Deleted */,
          --Archived = 'Y', /* Locations doesn't have Archived column commenting due to build issues will be reported*/
          Location = Location + '-' + convert(varchar(15), LocationId) + '-' + '*',
          Barcode  = Barcode + '-' + convert(varchar(15), LocationId) + '-' + '*'
          output Inserted.LocationId, Inserted.Location into @ttLocationsUpdated
      from Locations LOC join @ttLocations TL on (LOC.LocationId = TL.EntityId)
      where (LOC.BusinessUnit = @BusinessUnit) and
            (LOC.Status in ('E','I' /* Empty, InActive */)) and
            (LOC.Quantity     = 0);

      select @vLocationsUpdated = @@rowcount,
             @vActivityType     = 'DeleteLocation';
    end
  else
  if (@vAction = 'ModifyLocationType')
    begin
      select @vLocationType = Record.Col.value('NewLocationType[1]', 'TLocationType'),
             @vStorageType  = Record.Col.value('NewStorageType[1]',  'TStorageType')
      from @xmlData.nodes('/ModifyLocations/Data') as Record(Col);

      exec pr_Locations_ChangeLocationStorageType @ttLocations,
                                                  null,           /* LocationId */
                                                  @vLocationType, /* New Location Type */
                                                  @vStorageType,  /* New Storage Type */
                                                  @UserId,
                                                  @BusinessUnit,
                                                  @Message output;
    end
  else
  if (@vAction = 'ChangeLocationProfile')
    begin
      select @vLocationClass  = nullif(Record.Col.value('LocationClass[1]',       'TCategory'), ''),
             @vMaxPallets     = nullif(Record.Col.value('MaxPallets[1]',          'TCount'),    ''),
             @vMaxLPNs        = nullif(Record.Col.value('MaxLPNs[1]',             'TCount'),    ''),
             @vMaxInnerPacks  = nullif(Record.Col.value('MaxInnerPacks[1]',       'TCount'),    ''),
             @vMaxUnits       = nullif(Record.Col.value('MaxUnits[1]',            'TCount'),    ''),
             @vMaxVolume      = nullif(Record.Col.value('MaxVolume[1]',           'TVolume'),   ''),
             @vMaxWeight      = nullif(Record.Col.value('MaxWeight[1]',           'TWeight'),   ''),
             @vUpdateLocDefaultCapacities
                              = Record.Col.value('UpdateLocDefaultCapacities[1]', 'TFlags')
      from @xmlData.nodes('/ModifyLocations/Data') as Record(Col);

      /* call procedure here to update the location max limits on the locations */
      exec pr_Locations_UpdateMaxCapacities @ttLocations, null /* LocationId */, @vUpdateLocDefaultCapacities,
                                            @vLocationClass, @vMaxPallets, @vMaxLPNs, @vMaxInnerPacks, @vMaxUnits,
                                            @vMaxVolume, @vMaxWeight, @BusinessUnit, @UserId, @Message output;
    end
  else
  if (@vAction = 'ModifyLocationAttributes')
    begin
      select @vAllowMultipleSKUs = Record.Col.value('AllowMultipleSKUs[1]', 'TFlags'),
             @vLocationSubType   = Record.Col.value('LocationSubType[1]',   'TLocationSubType')
      from @xmlData.nodes('/ModifyLocations/Data') as Record(Col);

      select @vAllowMultipleSKUs = nullif(@vAllowMultipleSKUs, ''),
             @vLocationSubType   = nullif(@vLocationSubType, '');

      /* Get the location sub type description to display in confrimation message */
      select @vLocationSubTypeDesc = TypeDescription from EntityTypes where (Entity = 'LocationSubType') and (TypeCode = @vLocationSubType);

      /* Update Locations with AllowMultipleSKUs having Yes or No & LocatioSubType */
      update L
      set AllowMultipleSKUs = coalesce(@vAllowMultipleSKUs, AllowMultipleSKUs),
          LocationSubType   = coalesce(@vLocationSubType, LocationSubType)
      output Inserted.LocationId, Inserted.Location
      into @ttLocationsUpdated
      from Locations L
        join @ttLocations LP on (LP.EntityId = L.LocationId);

      select @vLocationsUpdated = @@rowcount,
             @vActivityType     = case when (@vAllowMultipleSKUs is not null) and (@vLocationSubType is not null)
                                         then 'ModifyLocationAtrbts_UpdatedBothAttributes'
                                       when (@vAllowMultipleSKUs is not null)
                                         then 'ModifyLocationAtrbts_UpdateAllowMultipleSKUs'
                                       when (@vLocationSubType is not null)
                                         then 'ModifyLocationAtrbts_UpdateLocationSubType'
                                  end,
             @vNote1            = coalesce(@vLocationSubTypeDesc, @vLocationSubType),
             @vNote2            = case when @vAllowMultipleSKUs = 'Y' then 'Yes' else 'No' end;
    end
  else
    begin
      /* If the action is not one of the above, send a message to UI saying Unsupported Action*/
      set @MessageName = 'UnsupportedAction-'+coalesce(@vAction, '');
      goto ErrorHandler;
    end;

  /* Only if any of the Locations are updated, generate audittrail else skip. */
  if (@vLocationsUpdated > 0)
    begin
     /* Currently we are setting Business Unit as hard coded for this release(12/3).
        we need to further change the signature to pass BusinessUnit also(ta5691 created)*/
      exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vNote1,
                                @Note2         = @vNote2,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'Location', @ttLocationsUpdated, @BusinessUnit;
    end

  /* Based upon the number of Locations that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vLocationsUpdated, @vLocationsCount;

  if (@vAddlMsg is not null)
    select @Message += @vAddlMsg;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_Modify */

Go
