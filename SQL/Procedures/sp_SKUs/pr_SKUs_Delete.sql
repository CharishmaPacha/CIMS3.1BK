/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2010/10/26  VM      Modified file to maintain Coding standards and
                        implemented Error handling mechanism wherever it is required.
                      pr_SKUs_AddOrUpdate: Added ProdCategory, ProdSubCategory
                      pr_SKUs_Delete: Set SKU to Inactive when deleted.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_Delete') is not null
  drop Procedure pr_SKUs_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_Delete
  (@SKUId  TRecordId,
   @SKU    TSKU)
As
begin
  SET NOCOUNT ON;

  update SKUs
  set Status = 'I' /* InActive */
  where ((SKUId = @SKUId) or
         (SKU   = @SKU));
end /* pr_SKUs_Delete */

Go
