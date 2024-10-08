/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails_Insert') is not null
  drop Procedure pr_Imports_OrderDetails_Insert;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderDetails_Insert; Inserts the Order details in
    #OrderDetailsImport with RecordAction of 'I'

  #OrderDetailsImport: TOrderDetailsImportType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails_Insert
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
begin /* pr_Imports_OrderDetails_Insert */

  insert into OrderDetails (
    OrderId, HostOrderLine,
    ParentHostLineNo, LineType, SKUId, SKU,
    UnitsOrdered, UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsAssigned,
    UnitsPerCarton, UnitsPerInnerPack,
    RetailUnitPrice, UnitSalePrice, UnitTaxAmount, Lot, CustSKU,
    InventoryClass1, InventoryClass2, InventoryClass3, PackingGroup, LocationId,
    UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10,
    UDF11, UDF12, UDF13, UDF14, UDF15, UDF16, UDF17, UDF18, UDF19, UDF20,
    UDF21, UDF22, UDF23, UDF24, UDF25, UDF26, UDF27, UDF28, UDF29, UDF30,
    BusinessUnit, CreatedDate, CreatedBy)
  select
    OrderId, HostOrderLine,
    ParentHostLineNo, LineType, SKUId, SKU,
    UnitsOrdered, UnitsAuthorizedToShip, UnitsAuthorizedToShip, UnitsAssigned,
    UnitsPerCarton,  UnitsPerInnerPack,
    coalesce(RetailUnitPrice, 0), UnitSalePrice, UnitTaxAmount, nullif(Lot, ''), CustSKU,
    coalesce(trim(InventoryClass1), ''), coalesce(trim(InventoryClass2),''), coalesce(trim(InventoryClass3), ''), PackingGroup, LocationId,
    OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
    OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
    OD_UDF21, OD_UDF22, OD_UDF23, OD_UDF24, OD_UDF25, OD_UDF26, OD_UDF27, OD_UDF28, OD_UDF29, OD_UDF30,
    BusinessUnit,
    coalesce(CreatedDate, current_timestamp),
    coalesce(CreatedBy, System_User)
  from #OrderDetailsImport
  where (RecordAction = 'I' /* Insert */)
  order by HostRecId;

end /* pr_Imports_OrderDetails_Insert */

Go
