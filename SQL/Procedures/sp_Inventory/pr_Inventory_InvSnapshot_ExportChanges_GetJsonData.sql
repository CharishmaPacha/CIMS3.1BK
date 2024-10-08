/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/28  MS      pr_Inventory_InvSnapshot_ExportChanges, pr_Inventory_InvSnapshot_ExportChanges_GetJsonData: Proc to export invsnapshot changes (BK-981)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_InvSnapshot_ExportChanges_GetJsonData') is not null
  drop Procedure pr_Inventory_InvSnapshot_ExportChanges_GetJsonData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_InvSnapshot_ExportChanges_GetJsonData:
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_InvSnapshot_ExportChanges_GetJsonData
(@BusinessUnit TBusinessUnit,
 @UserId       TUserId,
 @MessageData  TNvarchar output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TMessage;

begin /* pr_Inventory_InvSnapshot_ExportChanges_GetJsonData */
  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null;

  select @MessageData = (select * from #InvSnapshotsModified for json path, INCLUDE_NULL_VALUES);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_InvSnapshot_ExportChanges_GetJsonData */

Go
