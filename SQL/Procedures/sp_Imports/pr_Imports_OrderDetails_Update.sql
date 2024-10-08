/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/06  SV      pr_Imports_OrderDetails, pr_Imports_OrderDetails_Update: Port back from FB (FBV3-175)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails_Update') is not null
  drop Procedure pr_Imports_OrderDetails_Update;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderDetails_Update; Updates the Order details in
    #OrderDetailsImport with RecordAction of 'U'

  #OrderDetailsImport: TOrderDetailsImportType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails_Update
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
begin /* pr_Imports_OrderDetails_Update */

  update OD1
  set
    OD1.LineType                  = OD2.LineType,
    OD1.SKUId                     = OD2.SKUId,
    OD1.SKU                       = OD2.SKU,
    OD1.UnitsOrdered              = OD2.UnitsOrdered,
    OD1.UnitsAuthorizedToShip     = OD2.UnitsAuthorizedToShip,
    OD1.OrigUnitsAuthorizedToShip = OD2.UnitsAuthorizedToShip,
    --OD1.UnitsAssigned         = OD2.UnitsAssigned,
    OD1.UnitsPerCarton            = OD2.UnitsPerCarton,
    OD1.UnitsPerInnerPack         = OD2.UnitsPerInnerpack,
    OD1.RetailUnitPrice           = coalesce(OD2.RetailUnitPrice, 0),
    OD1.UnitSalePrice             = OD2.UnitSalePrice,
    OD1.UnitTaxAmount             = OD2.UnitTaxAmount,
    OD1.Lot                       = nullif(OD2.Lot, ''),
    OD1.InventoryClass1           = coalesce(trim(OD2.InventoryClass1), ''),
    OD1.InventoryClass2           = coalesce(trim(OD2.InventoryClass2), ''),
    OD1.InventoryClass3           = coalesce(trim(OD2.InventoryClass3), ''),
    OD1.ParentHostLineNo          = OD2.ParentHostLineNo,
    OD1.CustSKU                   = OD2.CustSKU,
    OD1.PackingGroup              = OD2.PackingGroup,
    OD1.LocationId                = OD2.LocationId,
    OD1.UDF1                      = OD2.OD_UDF1,
    OD1.UDF2                      = OD2.OD_UDF2,
    OD1.UDF3                      = OD2.OD_UDF3,
    OD1.UDF4                      = OD2.OD_UDF4,
    OD1.UDF5                      = OD2.OD_UDF5,
    OD1.UDF6                      = OD2.OD_UDF6,
    OD1.UDF7                      = OD2.OD_UDF7,
    OD1.UDF8                      = OD2.OD_UDF8,
    OD1.UDF9                      = OD2.OD_UDF9,
    OD1.UDF10                     = OD2.OD_UDF10,
    OD1.UDF11                     = OD2.OD_UDF11,
    OD1.UDF12                     = OD2.OD_UDF12,
    OD1.UDF13                     = OD2.OD_UDF13,
    OD1.UDF14                     = OD2.OD_UDF14,
    OD1.UDF15                     = OD2.OD_UDF15,
    OD1.UDF16                     = OD2.OD_UDF16,
    OD1.UDF17                     = OD2.OD_UDF17,
    OD1.UDF18                     = OD2.OD_UDF18,
    OD1.UDF19                     = OD2.OD_UDF19,
    OD1.UDF20                     = OD2.OD_UDF20,
    OD1.UDF21                     = OD2.OD_UDF21,
    OD1.UDF22                     = OD2.OD_UDF22,
    OD1.UDF23                     = OD2.OD_UDF23,
    OD1.UDF24                     = OD2.OD_UDF24,
    OD1.UDF25                     = OD2.OD_UDF25,
    OD1.UDF26                     = OD2.OD_UDF26,
    OD1.UDF27                     = OD2.OD_UDF27,
    OD1.UDF28                     = OD2.OD_UDF28,
    OD1.UDF29                     = OD2.OD_UDF29,
    OD1.UDF30                     = OD2.OD_UDF30,
    OD1.ModifiedDate              = coalesce(OD2.ModifiedDate, current_timestamp),
    OD1.ModifiedBy                = coalesce(OD2.ModifiedBy, System_User)
  output 'PickTicket', Inserted.OrderId, OD2.PickTicket, 'AT_OrderLineModified' /* Audit Activity */, OD2.RecordAction,
         Inserted.OrderDetailId, Inserted.BusinessUnit, Inserted.ModifiedBy, Inserted.OrderDetailId, OD2.SKU, Inserted.HostOrderLine
  into #AuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action,
                   Comment, BusinessUnit, UserId, UDF1, UDF2, UDF3)
  from OrderDetails OD1
    inner join #OrderDetailsImport OD2 on (OD1.OrderDetailId = OD2.OrderDetailId)
  where (OD2.RecordAction = 'U' /* Update */);

end /* pr_Imports_OrderDetails_Update */

Go
