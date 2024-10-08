/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUs_Delete') is not null
  drop Procedure pr_Imports_SKUs_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUs_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUs_Delete
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Capture audit info */
  insert into #ImportSKUAuditInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Action)
    select 'SKU', SKUId, SKU, 'AT_SKUDeleted', BusinessUnit, ModifiedBy, RecordAction
    from #ImportSKUs
    where (RecordAction = 'D');

  update S1
  set S1.Status   = 'I' /* Inactive */,
      S1.Archived = 'Y'
  from SKUs S1 inner join #ImportSKUs S2 on (S1.SKUId = S2.SKUId)
  where (S2.RecordAction = 'D') and
        (coalesce(S1.SourceSystem, S2.SourceSystem) = S2.SourceSystem);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_SKUs_Delete */

Go
