/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/31  AY      pr_CartonGroups_Action_AddorEdit: New procedure (HA-1621)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CartonGroups_Action_AddorEdit') is not null
  drop Procedure pr_CartonGroups_Action_AddorEdit;
Go
/*------------------------------------------------------------------------------
  Proc pr_CartonGroups_Action_AddorEdit: This procedure is for user to add
    new carton groups in the system or edit an existing group. Carton Groups
    are saved in LookUps as there is no specific table for it.
------------------------------------------------------------------------------*/
Create Procedure pr_CartonGroups_Action_AddorEdit
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
          @vStatus                     TStatus,
          @vExistingCartonGroup        TFlags;

begin /* pr_CartonGroups_Action_AddorEdit */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vRecordId       = 0,
         @vMessageName    = null,
         @vLookUpCategory = 'CartonGroups';

  select @vEntity          = Record.Col.value('Entity[1]',                 'TEntity'),
         @vAction          = Record.Col.value('Action[1]',                 'TAction'),
         @vCartonGroup     = Record.Col.value('(Data/CartonGroup)[1]',     'TCartonGroup'),
         @vCartonGroupDesc = Record.Col.value('(Data/CartonGroupDesc)[1]', 'TDescription'),
         @vStatus          = Record.Col.value('(Data/CG_Status)[1]',       'TStatus')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select @vRecordId            = RecordId,
         @vExistingCartonGroup = LookUpCode
  from LookUps
  where (LookUpCategory = @vLookUpCategory) and
        (LookUpCode     = @vCartonGroup   ) and
        (BusinessUnit   = @BusinessUnit   );

  /* Validations */

  if (@vAction = 'CartonGroups_Add') and (coalesce(@vCartonGroup, '') = '')
    set @vMessageName = 'CartonGroupIsRequired';
  else
  if (@vAction = 'CartonGroups_Add') and (@vExistingCartonGroup is not null)
    set @vMessageName = 'CartonGroupAlreadyExists'
  else
  if (rtrim(coalesce(@vCartonGroupDesc, '')) = '')
    set @vMessageName = 'CartonGroupDescIsRequired';
  else
  if (@vAction = 'CartonGroups_Edit') and (coalesce(@vRecordId, 0) = 0)
    set @vMessageName = 'InvalidRecordId';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vAction = 'CartonGroups_Add')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new carton type
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      /* Insert the record into LookUps Table */
      insert into LookUps(LookUpCategory, LookUpCode, LookUpDescription, Status, BusinessUnit, CreatedBy)
        select @vLookUpCategory, @vCartonGroup, @vCartonGroupDesc, @vStatus, @BusinessUnit, @UserId
     end
  else
  if (@vAction = 'CartonGroups_Edit')
    begin
      /* Update carton group in the lookups table */
      update LookUps
      set LookUpDescription = coalesce(@vCartonGroupDesc, LookUpDescription),
          Status            = coalesce(@vStatus,          Status),
          ModifiedDate      = current_timestamp,
          ModifiedBy        = coalesce(@UserId,           System_user)
      where (RecordId = @vRecordId);
    end

  select @vRecordsUpdated = @@rowcount;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_CartonGroups_Action_AddorEdit */

Go
