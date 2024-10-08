/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Mapping_Action_Delete') is not null
  drop Procedure pr_Mapping_Action_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Mapping_Action_Delete: This procedure is used for Deleting the existing
   mappings.
------------------------------------------------------------------------------*/
Create Procedure pr_Mapping_Action_Delete
   (@xmlData       xml,
    @BusinessUnit  TBusinessUnit,
    @UserId        TUserId,
    @ResultXML     TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,
          @vAuditActivity             TActivityType,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vRecordsUpdated            TInteger,
          @vTotalRecords              TInteger;

begin /* pr_Mapping_Action_Delete */
  SET NOCOUNT ON;
  set @vRecordsUpdated = 0

  /* Get the total records counts from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Delete the selected mappings */
  delete M
  from Mapping M
   join #ttSelectedEntities ttSE on (M.RecordId = ttSE.EntityId)

  set @vRecordsUpdated = @@rowcount;

  /* Message after Mapping details Deleted */
  exec pr_Messages_BuildActionResponse 'Mapping' , 'Delete', @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Mapping_Action_Delete */

Go
