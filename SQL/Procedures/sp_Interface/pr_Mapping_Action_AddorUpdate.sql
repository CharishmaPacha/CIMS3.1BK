/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Mapping_Action_AddorUpdate') is not null
  drop Procedure pr_Mapping_Action_AddorUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Mapping_Action_AddorUpdate: This procedure is used for
                               1)Create new mapping
                               2)update existing mapping
------------------------------------------------------------------------------*/
Create Procedure pr_Mapping_Action_AddorUpdate
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,
          @vAuditActivity             TActivityType,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vRecordsUpdated            TInteger,
          @vTotalRecords              TInteger,

          @vSourceSystem              TName,
          @vTargetSystem              TName,
          @vEntityType                TName,
          @vOperation                 TOperation,
          @vSourceValue               TDescription,
          @vTargetValue               TDescription,
          @vStatus                    TStatus,
          @vSortSeq                   TSortSeq;

begin /* pr_Mapping_Action_AddorUpdate */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = '';

  /* Extracting data elements from XML */
  select @vEntity         = Record.Col.value('Entity[1]',              'TEntity'),
         @vAction         = Record.Col.value('Action[1]',              'TAction'),
         @vRecordId       = Record.Col.value('(SelectedRecords/RecordDetails/EntityId) [1]',
                                                                       'TRecordId'),
         @vSourceSystem   = Record.Col.value('(Data/SourceSystem)[1]', 'TName'),
         @vTargetSystem   = Record.Col.value('(Data/TargetSystem)[1]', 'TName'),
         @vEntityType     = Record.Col.value('(Data/EntityType)[1]',   'TName'),
         @vOperation      = Record.Col.value('(Data/Operation)[1]',    'TOperation'),
         @vSourceValue    = Record.Col.value('(Data/SourceValue)[1]',  'TDescription'),
         @vTargetValue    = Record.Col.value('(Data/TargetValue)[1]',  'TDescription'),
         @vStatus         = Record.Col.value('(Data/Status)[1]',       'TStatus'),
         @vSortSeq        = Record.Col.value('(Data/SortSeq)[1]',      'TSortSeq')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  if ((@vAction = 'Mapping_Add') and
     (not exists(select * from Mapping where (RecordId = @vRecordId))))
    begin
      /* Basic validations of input data or entity info */
      if ((@vRecordId is null) and @vSourceSystem is null)
        set @vMessageName = 'SourceSystemIsRequired';
      else
      if ((@vRecordId is null) and @vTargetSystem is null)
        set @vMessageName = 'TargetSystemIsRequired';
      else
      if ((@vRecordId is null) and @vSourceValue is null)
        set @vMessageName = 'SourceValueIsInvalid';
      else
      if ((@vRecordId is null) and @vTargetValue is null)
        set @vMessageName = 'TargetValueIsInvalid';

      /* If Error, then return Error Code/Error Message */
      if (@vMessageName is not null)
        exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

      /* Insert the Records into Mapping Table */
      insert into Mapping(SourceSystem, TargetSystem, EntityType, Operation, SourceValue, TargetValue, Status, SortSeq, BusinessUnit)
        select @vSourceSystem, @vTargetSystem, @vEntityType, @vOperation, @vSourceValue, @vTargetValue, @vStatus, coalesce(@vSortSeq, 0), @BusinessUnit

      /* Get the total records counts from #table */
      select @vRecordsUpdated = @@rowcount, @vTotalRecords = 1;
    end
  else
    begin
      /* Get the total records counts from #table */
      select @vTotalRecords = count(*) from #ttSelectedEntities;

      update M
      set TargetValue = coalesce(@vTargetValue, TargetValue),
          Status      = coalesce(@vStatus, Status)
      from Mapping M
       join #ttSelectedEntities ttSE on (M.RecordId = ttSE.EntityId)

      /* Get the total records counts from #table */
      set @vRecordsUpdated = @@rowcount;
    end

 /* Message after Mapping details added/Updated */
 exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Mapping_Action_AddorUpdate */

Go
