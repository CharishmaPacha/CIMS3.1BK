/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/12  RIA     Added pr_Imports_SKUAttributes, pr_Imports_SKUAttributes_Insert, pr_Imports_SKUAttributes_Update, pr_Imports_SKUAttributes_Delete (HPI-2485)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUAttributes_Delete') is not null
  drop Procedure pr_Imports_SKUAttributes_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUAttributes_Delete: Delete SKU Atributes
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUAttributes_Delete
  (@ImportSKUAttributes  TSKUImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Cannot delete SKUs to delete SKU Attributes */
  return;

  /* Delete all the details */
  Delete S
  output 'SKU', Deleted.SKUId, SKU, 'AT_SKUDimensionsModified' /* Audit Activity */, 'D' /* Action - Update */,
         Deleted.BusinessUnit, Deleted.ModifiedBy
  into #ImportSKUAttrAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  from SKUs S1
    join @ImportSKUAttributes S2 on S1.SKUId = S2.SKUId and S1.SKU = S2.SKU and S1.BusinessUnit = S2.BusinessUnit
  where RecordAction = 'D';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_SKUAttributes_Delete */

Go
