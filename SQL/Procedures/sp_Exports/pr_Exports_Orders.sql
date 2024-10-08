/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/31  AKP/SV  Created pr_Exports_Orders
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_Orders') is not null
  drop Procedure pr_Exports_Orders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_Orders:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_Orders
  (@ExchangeStatus    TStatus,
   @SourceSystem      TName,
   @TargetSystem      TName,
   @EntityType        TName,
   @BusinessUnit      TBusinessUnit,
   @OrdersXml         XML = null output)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,
          @Message                TDescription;

  declare @ttOrders Table
          (OrderId               TRecordId,
           PickTicket            TPickTicket,
           SalesOrder            TSalesOrder,
           OrderType             TOrderType,
           Status                TStatus,
           ExchangeStatus        TStatus,
           OrderDate             TDateTime,
           CancelDate            TDateTime,
           DesiredShipDate       TDateTime,
           Priority              TPriority,
           SoldToId              TCustomerId,
           ShipToId              TShipToId,
           ShipVia               TShipVia,
           ShipFrom              TShipFrom,
           CustPO                TCustPO,
           Ownership             TOwnership,
           Warehouse             TWarehouse,
           TotalSalesAmount      TMoney,
           TotalTax              TMoney,
           TotalShippingCost     TMoney,
           TotalDiscount         TMoney,
           Comments              TVarchar,
           UDF1                  TUDF,
           UDF2                  TUDF,
           UDF3                  TUDF,
           UDF4                  TUDF,
           UDF5                  TUDF,
           UDF6                  TUDF,
           UDF7                  TUDF,
           UDF8                  TUDF,
           UDF9                  TUDF,
           UDF10                 TUDF,
           BusinessUnit          TBusinessUnit,
           CreatedBy             TUserId,
           ModifiedDate          TDateTime)
begin
  set NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null;

insert into @ttOrders(OrderId,PickTicket,SalesOrder, OrderType,Status,ExchangeStatus,OrderDate,
                        DesiredShipDate,Priority,SoldToId,ShipToId,ShipVia,
                        ShipFrom,CustPO,Ownership,Warehouse,TotalSalesAmount,
                        TotalTax,TotalShippingCost,TotalDiscount,Comments,
                        UDF1,UDF2,UDF3,UDF4,UDF5,UDF6,UDF7,UDF8,UDF9,UDF10,
                        BusinessUnit,CreatedBy,ModifiedDate)

    select OrderId,PickTicket,SalesOrder, OrderType,Status,ExchangeStatus,OrderDate,
            DesiredShipDate,Priority,SoldToId,ShipToId,ShipVia,
            ShipFrom,CustPO,Ownership,Warehouse,TotalSalesAmount,
            TotalTax,TotalShippingCost,TotalDiscount,Comments,
            UDF1,UDF2,UDF3,UDF4,UDF5,UDF6,UDF7,coalesce(UDF8, ''),UDF9,UDF10,
            BusinessUnit,CreatedBy,ModifiedDate
    from Orderheaders
    where (coalesce(ExchangeStatus, '') = coalesce(@ExchangeStatus, ExchangeStatus, ''))

    update @ttOrders set ShipVia = coalesce((select TargetValue from Mapping where SourceValue = ShipVia and SourceSystem = @SourceSystem and TargetSystem = @TargetSystem and EntityType = @EntityType and BusinessUnit = @BusinessUnit ),ShipVia)
    where (ShipVia =ShipVia)

  select @OrdersXml  = (select OH.OrderId,OH.PickTicket,OH.SalesOrder, OH.OrderType,OH.Status,OH.ExchangeStatus,
                               OH.OrderDate,OH.DesiredShipDate,OH.Priority,OH.SoldToId,
                               OH.ShipToId,coalesce(OH.ShipVia,'') ShipVia,OH.ShipFrom,OH.CustPO,OH.Ownership,
                               OH.Warehouse,OH.TotalSalesAmount,OH.TotalTax,OH.TotalShippingCost,
                               OH.TotalDiscount,OH.Comments,OH.UDF1,OH.UDF2,OH.UDF3,OH.UDF4,
                               OH.UDF5,OH.UDF6,OH.UDF7,OH.UDF8,OH.UDF9,OH.UDF10,
                               OH.BusinessUnit,OH.CreatedBy,OH.ModifiedDate,

                       (select C.ContactId,C.ContactRefId,C.ContactType,C.Name,C.AddressLine1,
            C.AddressLine2,C.City,C.State,C.Country,C.Zip,C.PhoneNo,C.Email,
            C.Reference1,C.Reference2,C.Status,C.ContactPerson
                        from Contacts C
                        where C.ContactRefId = OH.SoldToId
                        FOR XML PATH('ShippingAddress'), TYPE),

                       (select OD.OrderId,OD.OrderLine,OD.HostOrderLine,OD.SKUId,
                               OD.UnitsOrdered,OD.UnitsAuthorizedToShip,OD.UnitsAssigned,
                               cast(OD.RetailUnitPrice as Decimal(18,4)) as RetailUnitPrice,
                               OD.Lot,OD.CustSKU,OD.LocationId,OD.Location,OD.UDF1,OD.UDF2,
                               OD.UDF3,OD.UDF4,OD.UDF5,OD.BusinessUnit
                        from  Orderdetails OD
                        where OD.OrderId = OH.OrderId
                        FOR XML PATH('Item'), ROOT('Items'), TYPE)
  from  @ttOrders OH
  FOR XML PATH('Order'), ROOT('Orders'));

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_Orders */

Go
