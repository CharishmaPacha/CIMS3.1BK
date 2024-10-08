/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/03  RV      pr_LabelFormats_Action_AddOrEdit: Made changes to update template data in Content Templates (CIMSV3-1183)
  2020/11/02  AY      pr_LabelFormats_Action_AddOrEdit: New proc (CIMSV3-1183)

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LabelFormats_Action_AddOrEdit') is not null
  drop Procedure pr_LabelFormats_Action_AddOrEdit;
Go
/*------------------------------------------------------------------------------
  Proc pr_LabelFormats_Action_AddOrEdit: This procedure is for user to add or
    edit Label formats in CIMS
------------------------------------------------------------------------------*/
Create Procedure pr_LabelFormats_Action_AddOrEdit
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
          @vEntityType                 TEntity,
          @vLabelFormatName            TName,
          @vLabelFormatDesc            TDescription,
          @vLabelTemplateType          TLookUpCode,
          @vZPLTemplate                TVarchar,
          @vLabelSize                  TName,
          @vNumCopies                  TInteger,
          @vSortSeq                    TInteger,
          @vStatus                     TStatus,
          @vLabelFileName              TName,
          @vPrinterMake                TMake;

begin /* pr_LabelFormats_Action_AddOrEdit */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null;

  select @vEntity            = Record.Col.value('Entity[1]',                    'TEntity'),
         @vAction            = Record.Col.value('Action[1]',                    'TAction'),
         @vEntityType        = Record.Col.value('(Data/EntityType)[1]',         'TEntity'),
         @vLabelFormatName   = Record.Col.value('(Data/LabelFormatName)[1]',    'TName'),
         @vLabelFormatDesc   = Record.Col.value('(Data/LabelFormatName)[1]',    'TDescription'),
         @vLabelTemplateType = Record.Col.value('(Data/LabelTemplateType)[1]',  'TLookUpCode'),
         @vZPLTemplate       = Record.Col.value('(Data/ZPLTemplate)[1]',        'TVarchar'),
         @vLabelSize         = Record.Col.value('(Data/LabelSize)[1]',          'TName'),
         @vNumCopies         = Record.Col.value('(Data/NumCopies)[1]',          'TInteger'),
         @vSortSeq           = Record.Col.value('(Data/SortSeq)[1]',            'TInteger'),
         @vStatus            = Record.Col.value('(Data/Status)[1]',             'TStatus')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select @vRecordId = RecordId
  from LabelFormats
  where (EntityType      = @vEntityType     ) and
        (LabelFormatName = @vLabelFormatName) and
        (BusinessUnit    = @BusinessUnit    );

  /* Validations */

  if (@vAction = 'LabelFormats_Add') and (coalesce(@vLabelFormatName, '') = '')
    set @vMessageName = 'LabelFormatNameIsRequired';
  else
  if (@vAction = 'LabelFormats_Add') and (@vRecordId <> 0)
    set @vMessageName = 'LabelFormatAlreadyExists'
  else
  if (rtrim(coalesce(@vLabelFormatDesc, '')) = '')
    set @vMessageName = 'LabelFormatDescIsRequired';
  else
  if (@vAction = 'LabelFormats_Edit') and (coalesce(@vRecordId, 0) = 0)
    set @vMessageName = 'InvalidRecordId';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vLabelFileName = case when @vLabelTemplateType = 'BTW' then @vLabelFormatName + '.btw' else '' end,
         @vPrinterMake   = case when @vLabelTemplateType = 'ZPL' then 'Zebra' else 'Generic' end;

  if (@vAction = 'LabelFormats_Add')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new carton type
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      /* Add all LabelFormat */
      insert into LabelFormats (EntityType, LabelFormatName, LabelFormatDesc, LabelTemplateType, LabelSize,
                                LabelFileName, PrinterMake, NumCopies, SortSeq, Status, BusinessUnit, CreatedBy)
        select @vEntityType, @vLabelFormatName, @vLabelFormatDesc, @vLabelTemplateType, @vLabelSize,
               @vLabelFileName, @vPrinterMake, @vNumCopies, coalesce(@vSortSeq, 0), @vStatus, @BusinessUnit, @UserId;

      set @vRecordId = SCOPE_IDENTITY();
     end
  else
  if (@vAction = 'LabelFormats_Edit')
    begin
      /* Update carton group in the lookups table */
      update LabelFormats
      set EntityType        = coalesce(@vEntityType,        EntityType),
          LabelFormatDesc   = coalesce(@vLabelFormatDesc,   LabelFormatDesc),
          LabelTemplateType = coalesce(@vLabelTemplateType, LabelTemplateType),
          LabelSize         = coalesce(@vLabelSize,         LabelSize),
          LabelFileName     = coalesce(@vLabelFileName,     LabelFileName),
          PrinterMake       = coalesce(@vPrinterMake,       PrinterMake),
          NumCopies         = coalesce(@vNumCopies,         NumCopies),
          SortSeq           = coalesce(@vSortSeq,           SortSeq, 0),
          Status            = coalesce(@vStatus,            Status),
          ModifiedDate      = current_timestamp,
          ModifiedBy        = coalesce(@UserId,             System_user)
      where (RecordId = @vRecordId);
    end

  select @vRecordsUpdated = @@rowcount;

  /* Generate SQL statements for the labels */
  update LF
  set PrintOptions         = '<printoptions><printsize>' + LabelSize + '</printsize></printoptions>',
      LabelSQLStatement    = 'select ' + '[' + EntityType + ']' + '.* from ' + (select ResultSetDef from DBObjects where ObjectName = EntityType + 'Label') + ' ' + '[' + EntityType + ']' + ' where ~INPUTWHERECONDITION~',
      ZPLLabelSQLStatement = 'select ' + '[' + EntityType + ']' + '.* from ' + (select ResultSetDef from DBObjects where ObjectName = EntityType + 'Label') + ' ' + '[' + EntityType + ']' + ' where ' + EntityType + 'Id = ~EntityId~'
  from LabelFormats LF
  where (RecordId = @vRecordId);

  /* Need a generic way to do this in future ... */
  update LabelFormats
  set LabelSQLStatement    = 'exec pr_ShipLabel_GetLPNData null, ~EntityId~',
      ZPLLabelSQLStatement = 'exec pr_ShipLabel_GetLPNData null, ~EntityId~'
  where (RecordId = @vRecordId) and (LabelTemplateType like 'Ship%');

  update LabelFormats
  set LabelSQLStatement    = 'exec pr_Tasks_GetHeaderLabelData null, ~EntityId~',
      ZPLLabelSQLStatement = 'exec pr_Tasks_GetHeaderLabelData null, ~EntityId~'
  where (RecordId = @vRecordId) and (LabelTemplateType like 'Task%');

  update LabelFormats
  set LabelSQLStatement    = 'exec pr_Waves_GetLabelData null, ~EntityId~',
      ZPLLabelSQLStatement = 'exec pr_Waves_GetLabelData null, ~EntityId~'
  where (RecordId = @vRecordId) and (LabelTemplateType like 'Wave%');

  select @vRecordId = 0;

  /* Get Content template record id to update the tempalte details */
  select @vRecordId = RecordId
  from ContentTemplates
  where (TemplateName = @vLabelFormatName) and
        (BusinessUnit = @BusinessUnit    );

  /* Add the given ZPL to the content templates */
  if (coalesce(@vRecordId, 0) = 0)
    insert into ContentTemplates (TemplateName, TemplateType, TemplateDetail, Category, Status, BusinessUnit, CreatedBy)
      select @vLabelFormatName, @vLabelTemplateType, @vZPLTemplate, @vEntityType, @vStatus, @BusinessUnit, @UserId
  else
    update CT
    set TemplateType   = coalesce(@vLabelTemplateType, TemplateType),
        TemplateDetail = coalesce(@vZPLTemplate,       TemplateDetail),
        Status         = coalesce(@vStatus,            Status)
    from ContentTemplates CT
    where (RecordId = @vRecordId);

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_LabelFormats_Action_AddOrEdit */

Go
