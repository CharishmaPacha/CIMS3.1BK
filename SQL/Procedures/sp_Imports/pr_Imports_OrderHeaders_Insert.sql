/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderHeaders_Insert') is not null
  drop Procedure pr_Imports_OrderHeaders_Insert;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderHeaders_Insert; Inserts the Order Headers in
    #ImportOrderHeaders with RecordAction of 'I'

  #ImportOrderHeaders: TOrderHeadersImportType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderHeaders_Insert
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  insert into OrderHeaders (
    PickTicket, SalesOrder,
    OrderType, ReceiptNumber, Status,
    OrderDate, DesiredShipDate, DownloadedDate, CancelDate,
    Priority,
    SoldToId, ShipToId, ReturnAddress, MarkForAddress,
    ShipToStore, ShipVia, DeliveryRequirement, CarrierOptions,ShipFrom, ShipCompletePercent, CustPO, Ownership, SourceSystem,
    Account, AccountName, HostNumLines, OrderCategory1,
    OrderCategory2, OrderCategory3,
    OrderCategory4, OrderCategory5,Warehouse,
    TotalTax, TotalShippingCost, TotalDiscount, TotalSalesAmount,
    FreightCharges, FreightTerms, BillToAccount, BillToAddress, Comments,
    UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10,
    UDF11, UDF12, UDF13, UDF14, UDF15, UDF16, UDF17, UDF18, UDF19, UDF20,
    UDF21, UDF22, UDF23, UDF24, UDF25, UDF26, UDF27, UDF28, UDF29, UDF30,
    BusinessUnit, CreatedDate, CreatedBy)
  select
    PickTicket, coalesce(nullif(SalesOrder, ''), PickTicket),
    OrderType, ReceiptNumber, Status,
    OrderDate, DesiredShipDate, current_timestamp, CancelDate, Priority,
    SoldToId, ShipToId,
    ReturnAddrId, MarkForAddress,
    ShipToStore, ShipVia, DeliveryRequirement, CarrierOptions, ShipFrom, coalesce(ShipCompletePercent, 0), CustPO, Ownership, SourceSystem,
    Account, AccountName, HostNumLines, OrderCategory1,
    OrderCategory2, OrderCategory3,
    OrderCategory4, OrderCategory5, Warehouse,
    TotalTax, TotalShippingCost, TotalDiscount, TotalSalesAmount,
    FreightCharges, FreightTerms, BillToAccount, BillToAddress, Comments,
    OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_UDF6, OH_UDF7, OH_UDF8, OH_UDF9, coalesce(OH_UDF10, ''),
    OH_UDF11, OH_UDF12, OH_UDF13, OH_UDF14, OH_UDF15, OH_UDF16, OH_UDF17, OH_UDF18, OH_UDF19, OH_UDF20,
    OH_UDF21, OH_UDF22, OH_UDF23, OH_UDF24, OH_UDF25, OH_UDF26, OH_UDF27, OH_UDF28, OH_UDF29, OH_UDF30,
    BusinessUnit, coalesce(CreatedDate, current_timestamp), coalesce(CreatedBy, System_User)
  from #OrderHeadersImport
  where (RecordAction = 'I' /* Insert */)
  order by HostRecId;

  /* Update OrderId for the newly inserted OrderHeaders in the ttOrderHeaderImport table */
  update OHI
  set OHI.OrderId = OH.OrderId
  from #OrderHeadersImport OHI
    join OrderHeaders OH on (OHI.PickTicket   = OH.PickTicket  ) and
                            (OHI.BusinessUnit = OH.BusinessUnit)
  where (OHI.OrderId is null) and (OHI.RecordAction = 'I' /* Insert */);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_OrderHeaders_Insert */

Go
