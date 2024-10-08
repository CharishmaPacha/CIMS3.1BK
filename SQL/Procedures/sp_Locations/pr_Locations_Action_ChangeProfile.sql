/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/28  AJM     pr_Locations_Action_ChangeProfile: Initial Revision (CIMSV3-1436)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_ChangeProfile') is not null
  drop Procedure pr_Locations_Action_ChangeProfile;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_ChangeProfile: This procedure used to Change the
    LocationProfile on selected locations
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_ChangeProfile
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vLocationClass              TCategory,
          @vMaxPallets                 TCount,
          @vMaxLPNs                    TCount,
          @vMaxInnerPacks              TCount,
          @vMaxUnits                   TCount,
          @vMaxWeight                  TWeight,
          @vMaxVolume                  TVolume,

          @vLocClassCategory           TCategory,
          @vUpdateLocDefaultCapacities TFlags,
          /* Process variables */
          @vNote1                      TDescription;

  declare @ttLocationsUpdated          TEntityKeysTable;
begin /* pr_Locations_Action_ChangeProfile */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'ChangeLocationClassAndCapacities'

  select @vEntity            = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction            = Record.Col.value('Action[1]', 'TAction'),
         @vLocationClass     = nullif(Record.Col.value('(Data/LocationClass) [1]',       'TCategory'), ''),
         @vMaxPallets        = nullif(Record.Col.value('(Data/MaxPallets) [1]',          'TCount'),    ''),
         @vMaxLPNs           = nullif(Record.Col.value('(Data/MaxLPNs) [1]',             'TCount'),    ''),
         @vMaxInnerPacks     = nullif(Record.Col.value('(Data/MaxInnerPacks) [1]',       'TCount'),    ''),
         @vMaxUnits          = nullif(Record.Col.value('(Data/MaxUnits) [1]',            'TCount'),    ''),
         @vMaxVolume         = nullif(Record.Col.value('(Data/MaxVolume) [1]',           'TVolume'),   ''),
         @vMaxWeight         = nullif(Record.Col.value('(Data/MaxWeight) [1]',           'TWeight'),   ''),
         @vUpdateLocDefaultCapacities = Record.Col.value('(Data/UpdateLocDefaultCapacities) [1]', 'TFlags')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* if the user selects update max capacities based on the location class then we need to get it
     from controls and update those values */
  if (@vUpdateLocDefaultCapacities = 'Y' /* Yes */) and (@vLocationClass is not null)
    begin
      /* Establish Control Category based upon Lcoation Class */
      select @vLocClassCategory = 'LocationClass_' + coalesce(@vLocationClass, '');

      /* Get all values from controls for the given location class */
      select @vMaxPallets     = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxPallets',    99,   @BusinessUnit, @UserId),
             @vMaxLPNs        = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxLPNs',       99,   @BusinessUnit, @UserId),
             @vMaxInnerPacks  = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxInnerPacks', 99,   @BusinessUnit, @UserId),
             @vMaxUnits       = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxUnits',      9999, @BusinessUnit, @UserId),
             @vMaxVolume      = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxVolume',     999,  @BusinessUnit, @UserId),
             @vMaxWeight      = dbo.fn_Controls_GetAsInteger(@vLocClassCategory, 'MaxWeight',     999,  @BusinessUnit, @UserId);
    end

  /* validations */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Update LocationClass and capacities on the Locations */
  update L
  set LocationClass = coalesce(@vLocationClass, LocationClass),
      MaxPallets    = coalesce(@vMaxPallets,    MaxPallets),
      MaxLPNs       = coalesce(@vMaxLPNs,       MaxLPNs),
      MaxInnerPacks = coalesce(@vMaxInnerPacks, MaxInnerPacks),
      MaxUnits      = coalesce(@vMaxUnits,      MaxUnits),
      MaxVolume     = coalesce(@vMaxVolume,     MaxVolume),
      MaxWeight     = coalesce(@vMaxWeight,     MaxWeight),
      ModifiedBy    = @UserId
  output Inserted.LocationId, Inserted.Location into @ttLocationsUpdated
  from Locations L join #ttSelectedEntities ttSE on (L.LocationId = ttSE.EntityId)

  select @vRecordsUpdated = @@rowcount;

  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'LocationClass', @vLocationClass);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'MaxPallets',    @vMaxPallets);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'MaxLPNs',       @vMaxLPNs);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'MaxInnerPacks', @vMaxInnerPacks);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'MaxUnits',      @vMaxUnits);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'MaxVolume',     @vMaxVolume);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'MaxWeight',     @vMaxWeight);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttLocationsUpdated, @BusinessUnit;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_ChangeProfile */

Go
