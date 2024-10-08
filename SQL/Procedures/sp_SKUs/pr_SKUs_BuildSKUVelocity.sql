/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/25  MS      Added pr_SKUs_BuildSKUVelocity (BK-768)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_BuildSKUVelocity') is not null
  drop Procedure pr_SKUs_BuildSKUVelocity;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_BuildSKUVelocity: This procedure will built the SKU Velocity data
    for the given Velocity Type and Date
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_BuildSKUVelocity
  (@VelocityType TTypeCode,
   @TransDate    TDate,
   @BusinessUnit TBusinessUnit,
   @UserId       TName)
as
begin
  select @TransDate = coalesce(@TransDate, convert(date, getdate()))--Initialize

  /* Clean up any prior data */
  delete from SKUVelocity
  where (VelocityType = @VelocityType) and (TransDate = @TransDate);

  /* Build the Shipping velocity for the given date */
  if (@VelocityType = 'Ship')
    begin
      /* Build the Ship Velocity from exports */
      insert into SKUVelocity(VelocityType, TransDate, SKUId, SKU, InventoryKey,
                              InventoryClass1, InventoryClass2, InventoryClass3,
                              NumUnits, Warehouse, Ownership, BusinessUnit)
        select @VelocityType, @TransDate, min(SKUId), min(SKU), InventoryKey,
               min(InventoryClass1), min(InventoryClass2), min(InventoryClass3),
               sum(TransQty), min(Warehouse), min(Ownership), @BusinessUnit
        from vwExports
        where (TransDate    = @TransDate) and
              (TransType    = 'Ship') and
              (TransEntity  = 'LPND') and
              (BusinessUnit = @BusinessUnit)
        group by TransDate, InventoryKey;
    end
end /* pr_SKUs_BuildSKUVelocity */

Go
