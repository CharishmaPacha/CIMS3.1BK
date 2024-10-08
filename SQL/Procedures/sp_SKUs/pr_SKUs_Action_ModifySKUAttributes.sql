/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_Action_ModifySKUAttributes') is not null
  drop Procedure pr_SKUs_Action_ModifySKUAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_Action_ModifySKUAttributes:
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_Action_ModifySKUAttributes
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
          @vActivityType               TActivityType,
          @vAuditRecordId              TRecordId,
          @vAuditComment               TVarChar,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vCartonGroup                TCategory,
          @vReturnDisposition          TOperation,
          /* Process variables */
          @vNote1                      TDescription;

  declare @ttSKUsUpdated               TEntityKeysTable;

begin /* pr_SKUs_Action_ModifySKUAttributes */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0;

  /* Get the Action from the xml */
  select @vEntity             = Record.Col.value('Entity[1]',                          'TEntity'),
         @vAction             = Record.Col.value('Action[1]',                          'TAction'),
         @vActivityType       = Record.Col.value('Action[1]',                          'TAction'),
         @vCartonGroup        = Record.Col.value('(Data/CartonGroup)[1]',              'TCategory'),
         @vReturnDisposition  = nullif(Record.Col.value('(Data/ReturnDisposition)[1]', 'TOperation'), '')
  from @xmlData.nodes('/Root') as Record(Col);

  /* Validations */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the Total SKUs selected */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Update CartonGroup and ReturnDisposition on the selected SKUs */
  update S
  set CartonGroup       = coalesce(@vCartonGroup, CartonGroup),
      ReturnDisposition = coalesce(@vReturnDisposition, ReturnDisposition),
      ModifiedDate      = current_timestamp,
      ModifiedBy        = @UserId
  output Inserted.SKUId, Inserted.SKU
  into @ttSKUsUpdated (EntityId, EntityKey)
  from SKUs S join #ttSelectedEntities SE on (SE.EntityId = S.SKUId);

  set @vRecordsUpdated = @@rowcount;

  /* Preprocess the SKUs to recalculate PutawayClass */
  exec pr_SKUs_PreProcess @ttSKUsUpdated, null /* SKUId */, @BusinessUnit;

  /* Build Note to log AT */
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Carton Group', @vCartonGroup);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Return Disposition', @vReturnDisposition);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  if (@vAuditRecordId is not null)
    exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'SKU', @ttSKUsUpdated, @BusinessUnit;

BuildMessage:
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords, @vNote1;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_SKUs_Action_ModifySKUAttributes */

Go
