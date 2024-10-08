/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/25  TK      pr_AMF_Info_GetOrderInfoXML: For LPN reservation return order details into order of SortOrder (HA-GoLive)
  2020/06/23  RIA     pr_AMF_Info_GetOrderInfoXML: Made changes to return SKU Details for the order
  2020/05/24  TK      pr_AMF_Info_GetOrderInfoXML, pr_AMF_Info_GetWaveInfoXML & pr_AMF_Info_GetLPNReservationInfoXML:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetOrderInfoXML') is not null
  drop Procedure pr_AMF_Info_GetOrderInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetOrderInfoXML: We need order related informtion in different
    screens/places like LPNReservation, ReworkProcessing etc. We will build the OrderInfo
    regardless of the context, but the details that we show/present will be based on the
    value sent in IncludeDetails.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetOrderInfoXML
  (@OrderId                TRecordId,
   @IncludeDetails         TFlags     = 'OD',
   @Operation              TOperation = null,
   @OrderInfoXML           TXML       = null output,
   @OrderDetailsXML        TXML       = null output,
   @xmlOrderInfo           XML        = null output,
   @xmlOrderDetails        XML        = null output)
as
  declare @vRecordId          TRecordId,
          @vxmlOrderInfo      xml,
          @vxmlWaveInfo       xml,

          @vOrderId           TRecordId;
begin /* pr_AMF_Info_GetOrderInfoXML */

  /* Delete if there are any existing records from hash tables */
  delete from #DataTableSKUDetails;

  /* Capture Order Information */
  select @vxmlOrderInfo = (select OrderId, PickTicket, SalesOrder, CustPO, Account, AccountName,
                                  WaveId, WaveNo, WaveType, WaveTypeDesc, Ownership, Warehouse,
                                  OrderCategory1, OrderCategory2, OrderCategory3,
                                  SoldToId, CustomerName, ShipToId, ShipToName,
                                  ShipToAddressLine1, ShipToAddressLine2, ShipToCityStateZip,
                                  Carrier, ShipVia, ShipViaDesc, ShipFrom,
                                  NumUnits, UnitsAssigned, UnitsToAllocate
                                  LPNsAssigned, LPNsPicked, LPNsPacked, LPNsStaged, LPNsLoaded, LPNsToLoad,
                                  LPNsShipped, LPNsToShip,
                                  LoadNumber
                           from vwOrderHeaders
                           where (OrderId = @OrderId)
                           for xml raw('OrderInfo'), Elements);

  select @OrderInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('OrderInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlOrderInfo.nodes('/OrderInfo/*') as t(c)
  )
  select @OrderInfoXML = @OrderInfoXML + DetailNode from FlatXML;

  select @xmlOrderInfo = convert(xml, coalesce(@OrderInfoXML, ''));

  /* Get the Order Details along with SKU info */
  if (@IncludeDetails = 'OD' /* Order Details */)
    begin
      /* insert values into hash table */
      insert into #DataTableSKUDetails (DisplaySKU, DisplaySKUDesc, Quantity, Quantity1, Quantity2,
                                        SKU, UPC, AlternateSKU, Barcode, InventoryUoM, UoM,
                                        IPUoMDescSL, IPUoMDescPL, EAUoMDescSL, EAUoMDescPL,
                                        UnitsPerInnerPack, InnerPacksPerLPN, UnitsPerLPN,
                                        InventoryClass1, InventoryClass2, InventoryClass3,
                                        SKUId, SortOrder)
        select coalesce(S.DisplaySKU, S.SKU), coalesce(S.DisplaySKUDesc, S.Description),
               OD.UnitsAuthorizedToShip, OD.UnitsAssigned, OD.UnitsToAllocate,
               S.SKU, S.UPC, S.AlternateSKU, S.Barcode, S.InventoryUoM, S.UoM,
               'Case', 'Cases', 'Unit', 'Units',
               coalesce(S.UnitsPerInnerPack, 0) UnitsPerInnerPack,
               coalesce(S.InnerPacksPerLPN, 0) InnerPacksPerLPN,
               coalesce(S.UnitsPerLPN, 0) UnitsPerLPN,
               OD.InventoryClass1, OD.InventoryClass2, OD.InventoryClass3,
               S.SKUId, (coalesce(convert(varchar(20), OD.OrderDetailId), '') +
               coalesce(convert(varchar(20), OD.HostOrderLine), '') + coalesce(convert(varchar(50), S.SKU), ''))
        from OrderDetails OD
          join SKUs S on OD.SKUId = S.SKUId
        where (OD.OrderId = @OrderId)
        order by OD.SortOrder
    end

  select @xmlOrderDetails = (select * from #DataTableSKUDetails
                             order by SortOrder
                             for Xml Raw('OrderDetail'), elements XSINIL, Root('OrderDetails'));

  select @OrderDetailsxml = coalesce(convert(varchar(max), @xmlOrderDetails), '');

end /* pr_AMF_Info_GetOrderInfoXML */

Go

