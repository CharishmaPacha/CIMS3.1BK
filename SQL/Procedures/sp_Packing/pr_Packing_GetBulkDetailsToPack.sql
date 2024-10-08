/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/21  TK      pr_Packing_GetBulkDetailsToPack: Fixed issue with packing when SKU is repeated twice for same order (FBV3-1130)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetBulkDetailsToPack') is not null
  drop Procedure pr_Packing_GetBulkDetailsToPack;
Go
/*------------------------------------------------------------------------------
  pr_Packing_GetBulkDetailsToPack: Typically, an Order is picked and then the
    picked units are packed. However for a Bulk Order Wave (a Wave that has a
    Bulk Order on it), the units are picked against the Bulk Order but the
    actual Customer order is the one that is being packed i.e. nothing would
    have been picked against the Order being packed. Hence this procedure is
    to merge the units need to pack from the original order details and the
    picked qty of the associated Bulk Order.

  Note:
  This is not used for SLB Wave (even though it has a bulk order, it has it's own method)
  There is a limitation to fetch the bulk order picked quantity, as of now we are getting the picked
  quantity from one LPN. So all picked inventory against bulk wave should be dropped into different
  picklane locations

  #ttSelectedEntities: TEntityKeysTable
  #PackingDetails:     vwOrderToPackDetails
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetBulkDetailsToPack
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,

          @vOrderId                    TRecordId,
          @ValidOrderId                TRecordId,
          @vBulkOrderId                TRecordId,
          @vWaveId                     TRecordId,
          @vWaveNo                     TWaveNo,
          @vBusinessUnit               TBusinessUnit,
          @vShowLinesWithNoPickedQty   TFlag,
          @vShowComponentSKUsLines     TFlag,
          @vInputParams                TInputParams,
          @vOutputXML                  TXML,
          @vActivityLogId              TRecordId,
          @vDebug                      TFlags;

begin
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vOrderId       = null;

  /* Get Debug Options */
  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;

  select @vShowComponentSKUsLines   = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowComponentSKUsLines', 'N', @vBusinessUnit, null /* UserId */);
  /* Remove all the lines where the PickedQuantity is 0. There is nothing to be packed */
  select @vShowLinesWithNoPickedQty = dbo.fn_Controls_GetAsBoolean('Packing', 'ShowLinesNotPicked', 'N', @vBusinessUnit, System_User);

  /* Should be created by caller, else exit */
  if (object_id('tempdb..#PackingDetails') is null) return;

  /* Loop through all selected entities i.e the orders being packed.
     This is should only have one Customer Order that is being packed */
  while exists (select * from #ttSelectedEntities where RecordId > @vRecordId)
    begin
      select @vOrderId     = case when EntityType = 'ORDER' then EntityId end,
             @vBulkOrderId = null,
             @vRecordId    = RecordId
      from #ttSelectedEntities
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Identify if the Order belongs to a Bulk Wave */
      select @vWaveId = PickBatchId,
             @vWaveNo = PickBatchNo
      from OrderHeaders
      where (OrderId = @vOrderId);

      /* Get the Bulk Order Id of the particular Wave */
      select @vBulkOrderId = OrderId
      from OrderHeaders
      where (PickBatchId = @vWaveId) and (OrderType = 'B' /* Bulk Pull*/);

      /* If Wave does not have Bulk order, then continue to next one */
      if (@vBulkOrderId is null) continue;

      /* Get all the SKUs on the order that is being packed and
         load matching picked inventory for bulk order on the wave */
      insert into #PackingDetails (OrderDetailId, OrderLine, OrderId, PickTicket, SalesOrder, OrderType, Status,
                                   Priority, SoldToId, ShipToId, WaveId, WaveNo, PickBatchId, PickBatchNo, ShipVia, CustPO, Ownership,
                                   SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKUDesc, SKU1Desc, SKU2Desc, SKU3Desc, SKU4Desc, SKU5Desc,
                                   Serialized, UPC, AlternateSKU, DisplaySKU, DisplaySKUDesc, SKUBarcode, UnitWeight, SKUImageURL, SKUSortOrder,
                                   HostOrderLine, UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, UnitsToAllocate, UnitsToPack, UnitsPacked,
                                   InventoryClass1, InventoryClass2, InventoryClass3, Lot, InventoryKey, CustSKU, PackingGroup,
                                   OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
                                   OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
                                   SKU_UDF1, SKU_UDF2, SKU_UDF3, SKU_UDF4, SKU_UDF5,
                                   PalletId, Pallet, LPNId, LPN, LPNType, LPNStatus, LPNDetailId, PickedQuantity, PickedFromLocation, PickedBy, SerialNo, GiftCardSerialNumber,
                                   LocationId, Location, LastMovedDate, BusinessUnit, PageTitle, PackGroupKey,
                                   vwOPDtls_UDF1, vwOPDtls_UDF2, vwOPDtls_UDF3, vwOPDtls_UDF4, vwOPDtls_UDF5)
        select COD.OrderDetailId, COD.OrderLine, COD.OrderId, COD.PickTicket, COD.SalesOrder, COD.OrderType, COD.Status,
               COD.Priority, COD.SoldToId, COD.ShipToId, COD.WaveId, COD.WaveNo, COD.WaveId, COD.WaveNo, COD.ShipVia, COD.CustPO, COD.Ownership,
               COD.SKUId, COD.SKU, COD.SKU1, COD.SKU2, COD.SKU3, COD.SKU4, COD.SKU5, COD.SKUDesc, COD.SKU1Desc, COD.SKU2Desc, COD.SKU3Desc, COD.SKU4Desc, COD.SKU5Desc,
               COD.Serialized, COD.UPC, COD.AlternateSKU, COD.DisplaySKU, COD.DisplaySKUDesc, COD.SKUBarcode, COD.UnitWeight, COD.SKUImageURL, COD.SKUSortOrder,
               COD.HostOrderLine, COD.UnitsOrdered, COD.UnitsAuthorizedToShip, COD.UnitsAssigned, COD.UnitsToAllocate, COD.UnitsToPack, COD.UnitsPacked,
               COD.InventoryClass1, COD.InventoryClass2, COD.InventoryClass3, COD.Lot, COD.InventoryKey, COD.CustSKU, COD.PackingGroup,
               COD.OD_UDF1, COD.OD_UDF2, COD.OD_UDF3, COD.OD_UDF4, COD.OD_UDF5, COD.OD_UDF6, COD.OD_UDF7, COD.OD_UDF8, COD.OD_UDF9, COD.OD_UDF10,
               COD.OD_UDF11, COD.OD_UDF12, COD.OD_UDF13, COD.OD_UDF14, COD.OD_UDF15, COD.OD_UDF16, COD.OD_UDF17, COD.OD_UDF18, COD.OD_UDF19, COD.OD_UDF20,
               COD.SKU_UDF1, COD.SKU_UDF2, COD.SKU_UDF3, COD.SKU_UDF4, COD.SKU_UDF5,
               BOD.PalletId, BOD.Pallet, BOD.LPNId, BOD.LPN, BOD.LPNType, BOD.LPNStatus, BOD.LPNDetailId, BOD.PickedQuantity, BOD.PickedFromLocation, BOD.PickedBy, BOD.SerialNo, BOD.GiftCardSerialNumber,
               BOD.LocationId, BOD.Location, BOD.LastMovedDate, BOD.BusinessUnit, BOD.PageTitle, BOD.PackGroupKey,
               BOD.vwOPDtls_UDF1, BOD.vwOPDtls_UDF2, BOD.vwOPDtls_UDF3, BOD.vwOPDtls_UDF4, BOD.vwOPDtls_UDF5
        from vwOrderToPackDetails BOD
          join vwBulkOrderToPackDetails COD on (COD.OrderId = @vOrderId) and
                                               (BOD.InventoryKey = COD.InventoryKey)
        where (BOD.OrderId = @vBulkOrderId) and
              (BOD.LPNStatus in ('K', 'G' /* Picked, Packing */));

      /* set the picked quantity to minimum of unitstoallocate on the order details of order to pack and
         the units picked in the bulk order sku line
         There are instances when the order lines in Bulk order are picked partially or not picked at all.
         In such cases, the Picked Quantity must reflect the actual physical inventory, instead of the UnitsToAllocate
         as this could lead to packer getting confused between the discrepancy in what is displayed and physically available.
         update the previously packed quantity from original orders units assigned, as we are updating units assigned
         after packed
      */
      update #PackingDetails
      set PickedQuantity = dbo.fn_MinInt(coalesce(PickedQuantity, 0), OD.UnitsToAllocate),
          UnitsToPack    = dbo.fn_MinInt(coalesce(PickedQuantity, 0), OD.UnitsToAllocate)
      from OrderDetails OD
      where (OD.OrderId = @vOrderId) and (#PackingDetails.OrderDetailId = OD.OrderDetailId);

    end /* while end */

  if (@vShowLinesWithNoPickedQty = 'N' /* No */)
    delete from #PackingDetails where (PickedQuantity = 0);

  /* Delete component lines if not required to show */
  if (@vShowComponentSKUsLines = 'N')
    delete from #PackingDetails where (LineType = 'C' /* Component SKU */);

end /* pr_Packing_GetBulkDetailsToPack */

Go
