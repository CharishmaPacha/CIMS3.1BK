/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/15  GAG/TK  Added pr_SKUs_Action_ModifyCommercialInfo (BK-797)
  if object_id('dbo.pr_SKUs_Action_ModifyCommercialInfo') is null
  exec('Create Procedure pr_SKUs_Action_ModifyCommercialInfo as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_Action_ModifyCommercialInfo') is not null
  drop Procedure pr_SKUs_Action_ModifyCommercialInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_Action_ModifyCommercialInfo: This procedure modifies the commerficial info on the SKUs
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_Action_ModifyCommercialInfo
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,
          @xmlRulesData                TXML,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @vActivityType               TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditId                    TRecordId,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vHarmonizedCode             THarmonizedCode,
          @vDefaultCoO                 TCoO,
          @vUnitPrice                  TFloat,
          @vNewValues                  TDescription;
begin /* pr_SKUs_Action_ModifyCommercialInfo */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'AT_SKUCommercialInfoModified';

  /* Get the Entity, Action and other details from the xml */
  select @vEntity            =  Record.Col.value('Entity[1]', 'TEntity'),
         @vAction            =  Record.Col.value('Action[1]', 'TAction'),
         @vHarmonizedCode    =  nullif(Record.Col.value('(Data/HarmonizedCode)[1]',  'THarmonizedCode'), ''),
         @vDefaultCoO        =  nullif(Record.Col.value('(Data/DefaultCoO)[1]',      'TCoO'), ''),
         @vUnitPrice         =  nullif(Record.Col.value('(Data/UnitPrice)[1]',       'TFloat'), '')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Validations */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get number of Records selected */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get the Prev Commercial Info */
  select SKUId, HarmonizedCode, DefaultCoO, UnitPrice, cast('' as varchar(120)) as PrevValues
  into #SKUPrevCommericalInfo
  from #ttSelectedEntities SE join SKUs S on (SE.EntityId = S.SKUId);

  /* Update SKUs */
  update S
  set HarmonizedCode = coalesce(@vHarmonizedCode, HarmonizedCode),
      DefaultCoO     = coalesce(@vDefaultCoO, DefaultCoO),
      UnitPrice      = coalesce(@vUnitPrice, UnitPrice),
      ModifiedDate   = current_timestamp,
      ModifiedBy     = @UserId
  from SKUs S join #ttSelectedEntities SE on (SE.EntityId = S.SKUId);

  /* Get the count of total number of SKUs Updated */
  select @vRecordsUpdated = @@rowcount;

  /* Build Note to display to user */
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'Harmonized Code', @vHarmonizedCode);
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'CoO',             @vDefaultCoO);
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'UnitPrice',       @vUnitPrice);

  /* Build the previous value */
  update #SKUPrevCommericalInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'Harmonized Code', HarmonizedCode);
  update #SKUPrevCommericalInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'CoO',             DefaultCoO);
  update #SKUPrevCommericalInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'UnitPrice',       UnitPrice);

   /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'SKU', EntityId, EntityKey, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vNewValues, PrevValues, null, null, null) /* Comment */
    from #ttSelectedEntities SE
      join #SKUPrevCommericalInfo S on (S.SKUId = SE.EntityId);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

BuildMessage:
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  /* Build success message */
  if (@vRecordsUpdated > 0)  -- Add this atleast if one SKU is modified
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, 'Update: (' + @vNewValues + ')';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_SKUs_Action_ModifyCommericalInfo */

Go
