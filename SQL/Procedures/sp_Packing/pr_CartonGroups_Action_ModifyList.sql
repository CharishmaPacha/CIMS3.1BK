/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/10  SJ      pr_CartonGroups_Action_ModifyList, pr_CartonGroups_Action_Delete: New proc's (HA-1621)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CartonGroups_Action_ModifyList') is not null
  drop Procedure pr_CartonGroups_Action_ModifyList;
Go
/*------------------------------------------------------------------------------
  Proc pr_CartonGroups_Action_ModifyList: This procedure is for user to add
    new carton type to group in the system or edit carton type in existing carton group. Carton Groups
    are saved in LookUps as there is no specific table for it.
------------------------------------------------------------------------------*/
Create Procedure pr_CartonGroups_Action_ModifyList
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
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
          @vLookUpCategory             TCategory,
          @vCartonGroup                TCartonGroup,
          @vCartonGroupDesc            TDescription,
          @vCartonType                 TCartonType,
          @vAvailableSpace             TInteger,
          @vMaxWeight                  TInteger,
          @vMaxUnits                   TInteger,
          @vStatus                     TStatus,
          @vExistingCartonGroup        TFlags;

begin /* pr_CartonGroups_Action_ModifyList */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordId       = null,
         @vMessageName    = null,
         @vLookUpCategory = 'CartonGroups';

  select @vEntity          = Record.Col.value('Entity[1]',                    'TEntity'),
         @vAction          = Record.Col.value('Action[1]',                    'TAction'),
         @vCartonGroup     = Record.Col.value('(Data/CartonGroup)[1]',        'TCartonGroup'),
         @vCartonType      = Record.Col.value('(Data/CartonType)[1]',         'TCartonType'),
         @vAvailableSpace  = Record.Col.value('(Data/CG_AvailableSpace)[1]',  'TInteger'),
         @vMaxWeight       = Record.Col.value('(Data/CG_MaxWeight)[1]',       'TInteger'),
         @vMaxUnits        = Record.Col.value('(Data/CG_MaxUnits)[1]',        'TInteger'),
         @vStatus          = Record.Col.value('(Data/CGT_Status)[1]',         'TStatus')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the Total selected counts */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Based on the given combination  find the Carton Groups to types  exist or not*/
  select @vRecordId = RecordId
  from vwCartonGroupsAndTypes
  where (CartonGroup  = @vCartonGroup) and
        (CartonType   = @vCartonType) and
        (BusinessUnit = @BusinessUnit);

    /* Validations */
  if (@vAction = 'CartonGroupsCartonType_Add') and (coalesce(@vCartonGroup, '') = '')
    set @vMessageName = 'CartonGroupIsRequired';
  else
  if (@vAction = 'CartonGroupsCartonType_Add') and (coalesce(@vCartonType, '') = '')
    set @vMessageName = 'CartonTypeIsRequired';
  else
  if (@vAction = 'CartonGroupsCartonType_Add') and (@vRecordId is not null)
    set @vMessageName = 'CartonTypeToGroupAlreadyExists'

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vAction = 'CartonGroupsCartonType_Add')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new carton type
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      /* Insert the record into CartonGroups Table */
      insert into CartonGroups(CartonGroup, CartonType, Description, AvailableSpace, MaxWeight, MaxUnits, Status, BusinessUnit, CreatedBy)
        select @vCartonGroup, @vCartonType, '', @vAvailableSpace, @vMaxWeight, @vMaxUnits, @vStatus, @BusinessUnit, @UserId
     end
  else
  if (@vAction = 'CartonGroupsCartonType_Edit')
    begin
      /* Update the record in carton group table */
      update C
      set AvailableSpace    = coalesce(@vAvailableSpace,   AvailableSpace),
          MaxWeight         = coalesce(@vMaxWeight,        MaxWeight),
          MaxUnits          = coalesce(@vMaxUnits,         MaxUnits),
          Status            = coalesce(@vStatus,           Status),
          ModifiedDate      = current_timestamp,
          ModifiedBy        = coalesce(@UserId,            System_user)
      from CartonGroups C
        join #ttSelectedEntities ttSE on (C.RecordId = ttSE.EntityId);
    end

  select @vRecordsUpdated = @@rowcount;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_CartonGroups_Action_ModifyList */

Go
