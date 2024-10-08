/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  SJ      pr_Loads_Action_GenerateBoLs: Implemented new act proc (CIMSV3-1513)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_GenerateBoLs') is not null
  drop Procedure pr_Loads_Action_GenerateBoLs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_GenerateBoLs: This procedure will used to generate
          BoL info for the each load and also update the MasterBoL if exists.
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_GenerateBoLs
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
         /* Process variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vLoadId                     TRecordId,
          @vLoadNumber                 TLoadNumber,
          @vRegenerate                 TFlag,
          @vBOD_GroupCriteria          TCategory;

begin /* pr_Loads_Action_GenerateBoLs */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vRecordsUpdated = 0;

  select @vEntity             = Record.Col.value('Entity[1]',                    'TEntity'),
         @vAction             = Record.Col.value('Action[1]',                    'TAction'),
         @vRegenerate         = Record.Col.value('(Data/Regenerate)[1]',         'TFlag'),
         @vBOD_GroupCriteria  = Record.Col.value('(Data/BOD_GroupCriteria)[1]',  'TCategory')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the Total selected counts */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Basic validations of input data or entity info */

  /* If error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Iterate through each Load and generate the BOLs for it */
  while exists(select * from #ttSelectedEntities where RecordId > @vRecordId)
    begin
      select top 1 @vLoadId     = EntityId,
                   @vLoadNumber = EntityKey,
                   @vRecordId   = RecordId
      from #ttSelectedEntities
      where (RecordId > @vRecordId)
      order by RecordId;

      begin try
        exec @vReturnCode = pr_Load_GenerateBoLs @vLoadId, @vRegenerate, @UserId, @vBOD_GroupCriteria;
        select @vRecordsUpdated = @vRecordsUpdated + 1;
      end try
      begin catch
        /* Capture the error message to display to user */
        insert into #ResultMessages(MessageType, EntityId, EntityKey, MessageText)
          select 'E', @vLoadId, @vLoadNumber, ERROR_MESSAGE();

        exec pr_Notifications_SaveValidations 'Load', @vLoadId, @vLoadNumber, 'NO' /* Save To */,
                                              'GenerateBoLs', @BusinessUnit, @UserId;
      end catch;
    end;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_GenerateBoLs */

Go
