/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/10  SJ      pr_CartonGroups_Action_ModifyList, pr_CartonGroups_Action_Delete: New proc's (HA-1621)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CartonGroups_Action_Delete') is not null
  drop Procedure pr_CartonGroups_Action_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_CartonGroups_Action_Delete: This procedure is used for delete the
  selected records from cartongroups
------------------------------------------------------------------------------*/
Create Procedure pr_CartonGroups_Action_Delete
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount;

begin /* pr_CartonGroups_Action_Delete */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vRecordsUpdated = 0;

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total records counts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Delete the entire carton group and the list of cartons in it */
  delete from C
  from CartonGroups C
    join #ttSelectedEntities ttSE on (C.RecordId = ttSE.EntityId)

  select @vRecordsUpdated = @@rowcount;

  /* Message after remove the selected record from cartongroup  */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_CartonGroups_Action_Delete */

Go
