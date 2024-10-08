/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/08/07  TD      pr_SKUAttributes_Modify, pr_SKUAttributes_Delete: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUAttributes_Delete') is not null
  drop Procedure pr_SKUAttributes_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUAttributes_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_SKUAttributes_Delete
  (@SKUAttributeId  TRecordId,
   @UserId          TUserId   = null output)
as
  declare @vBusinessUnit     TBusinessUnit,
          @vAttributeValue   TUPC,
          @vSKUId            TRecordId,
          @vAuditId          TRecordId;
  /* Temp table to hold all the SKUs to be updated */
  declare @ttSKUsUpdated TEntityKeysTable;
begin
  SET NOCOUNT ON;
  /* Get thje details from table */
  select @vBusinessUnit   = BusinessUnit,
         @vAttributeValue = AttributeValue,
         @vSKUId          = SKUId
  from SKUAttributes
  where (SKUAttributeId = @SKUAttributeId);

  delete from SKUAttributes
  where (SKUAttributeId = @SKUAttributeId);

  /* generate Audit list here */
  exec pr_AuditTrail_Insert 'UPCRemovedFromSKU' /* Activity Type */, @UserId, null /* ActivityTimestamp */,
                            @SKUID         = @vSKUId,
                            @BusinessUnit  = @vBusinessUnit,
                            @Note1         = @vAttributeValue,
                            @AuditRecordId = @vAuditId output;

  /* Call Export Proc here t oexport data */
  exec pr_Exports_SKUData 'UPC-', @ttSKUsUpdated /* temp table */, @vSKUId,
                           @vAttributeValue /* UPC */, @vBusinessUnit, @UserId;
end /* pr_SKUAttributes_Delete */

Go
