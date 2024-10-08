/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/09  SPP     pr_Exports_OrderData: Added Inventory Classes (HA-296)
  2020/05/15  TK      pr_Exports_OrderData: Comented FrieghtTerms as Exports_AddOrUpdate doesn't accept that field (HA-543)
                      pr_Exports_OrderData: Calculate the Freight charges for each order (CID-1378)
                      pr_Exports_AddOrUpdate, pr_Exports_ConsolidatedOrderData, pr_Exports_OrderData:Added SoldToId, ShipToId params (CID-1175)
                      pr_Exports_OrderData: Changes to get the ShipmentId (CID-1029)
                      pr_Exports_OrderData: Prevent exports for Replenish Orders
  2018/08/27  TK      pr_Exports_OrderData: Added new TransType PTStatus (S2GCA-200)
  2018/04/03  SV      pr_Exports_OrderData: Added ReasonCode (HPI-1842)
  2018/03/16  DK      pr_Exports_AddOrUpdate, pr_Exports_LPNData, pr_Exports_OrderData: Enhanced to insert SourceSystem in Exports (FB-1114)
                      pr_Exports_OrderData: Set default value as zero for LoadId if not given
  2016/08/31  AY      pr_Exports_OrderData/LPNData/AddOrUpdate: Add FreightCharges & TrackingNo to Exports table (HPI-531)
  2016/08/30  AY      pr_Exports_OrderData: Send LoadId in ShipOH/OD records when shipped against a Load. (HPI-546)
  2016/02/09  TK      pr_Exports_OrderData: Retrieve TransQty as sum of units shipped if TransType is 'Ship' (NBD-142)
  2014/04/25  PK      pr_Exports_OrderData: Changes to export Short Shipped Units.
  2014/04/03  NY      pr_Exports_OrderData: Send Header transactions conditionally.
  2014/04/01  AY/NY   pr_Exports_OrderData: Partial PTLine cancel changes (XSC-531).
  2013/06/10  PK      pr_Exports_OrderData: Considering PTCancel transactions as well.
  2012/09/20  YA      pr_Exports_OrderData: Modified to send Warehouse as an i/p on exports.
  2011/10/04  AY      pr_Exports_OrderData : New Procedure to handle order header and
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_OrderData') is not null
  drop Procedure pr_Exports_OrderData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_OrderData:
    PTCancel - 1. Export the remaining units to ship with transaction type as PTCancel.
    Ship     - 1. Export the shipped units with transaction type as Ship
             - 2. If the control value of @vExportOrderDetails is S 'Short Ship'
                  then export the short units(remaning units) and transaction type as Ship.
    Pick     - 1. Export the Assigned Units with Transaction Type as Ship.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_OrderData
  (@TransType          TTypeCode,
   @OrderId            TRecordId,
   @OrderDetailId      TRecordId,
   @LoadId             TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReasonCode         TReasonCode = null,

   @RecordId           TRecordId   = null output,
   @TransDateTime      TDateTime   = null output,
   @CreatedDate        TDateTime   = null output,
   @ModifiedDate       TDateTime   = null output,
   @CreatedBy          TUserId     = null output,
   @ModifiedBy         TUserId     = null output)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,
          @Message                TDescription,

          @TransEntity            TEntity           = null,
          @TransQty               TQuantity         = null,
          @Status                 TStatus           = 'N',
          @InventoryClass1        TInventoryClass   = null,
          @InventoryClass2        TInventoryClass   = null,
          @InventoryClass3        TInventoryClass   = null,
          @vExportOrderDetails    TControlValue,
          @vExportOrderHeaders    TControlValue,
          @vOrderDetailsExported  TFlags,
          @vOrderId               TRecordId,
          @vOrderType             TOrderType,
          @vShipmentId            TShipmentId,
          @vOwnership             TOwnership,
          @vSourceSystem          TName,
          @vWarehouse             TWarehouse,
          @vSoldToId              TCustomerId,
          @vShipToId              TShipToId,
          @vOHFreightTerms        TDescription,
          @vBoLFreightTerms       TDescription,
          @SKUId                  TRecordId,
          @vWeight                TWeight,
          @vDefaultPalletWeight   TWeight,
          @vVolume                TVolume,
          @vFreightCharges        TMoney,
          @vShipVia               TShipVia,
          @vCarrier               TCarrier,
          @vIsSmallPackageCarrier TFlags,
          @vNumPallets            TCount,
          @vTotalLPNsWeight       TWeight,
          @vTotalLPNsVolume       TVolume,
          @xmlRulesData           TXML;
begin
  SET NOCOUNT ON;

  select @ReturnCode            = 0,
         @MessageName           = null,
         @CreatedBy             = @UserId,
         @vOrderDetailsExported = 'N',
         @LoadId                = coalesce(@LoadId, 0);

  /* If the given TransType is not active then do nothing and exit.
     Not all clients or installs use or are interested in all transaction types */
  if not exists (select * from vwEntityTypes
                 where ((TypeCode = @TransType) and
                        (Entity   = 'Transaction')))
    goto Exithandler;

  /* Get Order Info - consider the Order Modified date as Transaction Date Time */
  select @vOrderId        = OrderId,
         @vSoldToId       = SoldToId,
         @vShipToId       = ShipToId,
         @TransDateTime   = ModifiedDate,
         @vOwnership      = Ownership,
         @vSourceSystem   = SourceSystem,
         @vWarehouse      = Warehouse,
         @vOrderType      = OrderType,
         @vWeight         = TotalWeight,
         @vVolume         = TotalVolume,
         @vShipVia        = ShipVia,
         @vOHFreightTerms = FreightTerms,
         @BusinessUnit  = coalesce(@BusinessUnit, BusinessUnit)
  from OrderHeaders
  where (Orderid = @OrderId);

  /* Get the ShipmentId to pass to caller */
  select @vShipmentId = ShipmentId
  from vwOrderShipments
  where (LoadId  = @LoadId) and
        (OrderId = @OrderId) and
        (coalesce(@LoadId, 0) <> 0)

  /* Get ShipVia info */
  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

  /* Get NumPallets for the order */
  select @vNumPallets = count(*)
  from Pallets
  where (OrderId = @OrderId);

  /* Get the total LPNs weight and volume for the order */
  select @vTotalLPNsWeight = sum(coalesce(nullif(ActualWeight, 0), EstimatedWeight, 0)),
         @vTotalLPNsVolume = sum(coalesce(nullif(ActualVolume, 0), EstimatedVolume, 0))
  from LPNs
  where (OrderId = @OrderId);

  /* Build Xml for rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('OrderType',             @vOrderType) +
                           dbo.fn_XMLNode('TransType',             @TransType) +
                           dbo.fn_XMLNode('TransEntity',           '') +
                           dbo.fn_XMLNode('OrderId',               @vOrderId) +
                           dbo.fn_XMLNode('LoadId',                @LoadId)   +
                           dbo.fn_XMLNode('Carrier',               @vCarrier)   +
                           dbo.fn_XMLNode('OrderWeight',           @vTotalLPNsWeight)   +
                           dbo.fn_XMLNode('IsSmallPackageCarrier', @vIsSmallPackageCarrier) +
                           dbo.fn_XMLNode('FreightTerms',          @vOHFreightTerms)
                           );

  /* To Generate the Exports for Consolidated Orders */
  if ((@vOrderType = 'CO') and (@TransType in ('Ship', 'PTCancel')))
    begin
      exec pr_Exports_ExplodeConsolidatedOrder @TransType, @vOrderId, @LoadId, @BusinessUnit, @UserId, @ReasonCode, @xmlRulesData;
      goto Exithandler;
    end

    /* Get the Default Pallet Weight based on control value */
  select @vDefaultPalletWeight = dbo.fn_Controls_GetAsInteger('ExportData', 'DefaultPalletWeight', '1', @BusinessUnit, @UserId);

  /* Update the order totalweight and totalvolume by calculating the pallet weight and volume */
  update OrderHeaders
  set @vWeight    =
      TotalWeight = @vTotalLPNsWeight + (@vNumPallets * @vDefaultPalletWeight),
      @vVolume    =
      TotalVolume = @vTotalLPNsVolume
  where (OrderId = @OrderId);

  /* Do not send any exports for Replenish or Bulk Orders */
  if (@vOrderId is null) or
     (@TransType not in ('Ship', 'Pick', 'PTCancel', 'PTStatus')) or
     (@vOrderType in ('R', 'RU', 'RP', 'B' /* Replenish/Bulk */))
    goto Exithandler;

  /* Get the control value to determine if we want to export Order Details also or not */
  select @vExportOrderDetails = dbo.fn_Controls_GetAsString('ExportOrderDetails', @TransType, 'N' /* No */, @BusinessUnit, @UserId),
         @vExportOrderHeaders = dbo.fn_Controls_GetAsString('ExportOrderHeaders', @TransType, 'N' /* No */, @BusinessUnit, @UserId);

  /* For Ship or Pick Transactions, first upload all the OrderDetails followed
     by the Order Header. It is possible some clients want it the other way
     around at which time we will enhance it. */
  if (@vExportOrderDetails in ('Y' /* Yes */, 'C' /* Cancel Remaining lines */, 'S'/* Short Ship */))
    begin
      if (@vExportOrderDetails = 'C' /* Export Cancel Remaining */) and (@TransType = 'Ship')
        select @TransType  = 'PTCancel';

      /* Upload all Order Details for the order */
      set @TransEntity = coalesce(@TransEntity, 'OD' /* Order Details */);

      declare OrderLinesToExport Cursor Local Forward_Only Static Read_Only
      For select OrderDetailId, SKUId, InventoryClass1, InventoryClass2, InventoryClass3,
                 case when (@TransType = 'Ship') and (@vExportOrderDetails in ('Y')) then UnitsShipped
                      when (@TransType = 'Ship') and (@vExportOrderDetails = 'S'/* Short Ship */)
                        then OrigUnitsAuthorizedToShip-UnitsShipped
                      when (@TransType = 'PTCancel') then OrigUnitsAuthorizedToShip-UnitsShipped
                      when (@TransType = 'Pick')     then UnitsAssigned
                 end,
                 BusinessUnit, ModifiedDate, ModifiedBy
      from OrderDetails
      where (OrderId = @OrderId) and
            (((@TransType  = 'Ship') and (@vExportOrderDetails in ('Y')))
             or
             ((@TransType = 'Ship') and (@vExportOrderDetails = 'S'/* Short Ship */) and
              (UnitsShipped < OrigUnitsAuthorizedToShip) and
              (UnitsAuthorizedToShip > 0))
             or
             ((@TransType = 'PTCancel') and (UnitsShipped < OrigUnitsAuthorizedToShip) and (UnitsAuthorizedToShip > 0))
             or
             ((@TransType = 'Pick') and (UnitsAssigned > 0)));

      Open OrderLinesToExport;
      Fetch next from OrderLinesToExport into @OrderDetailId, @SKUId, @InventoryClass1, @InventoryClass2, @InventoryClass3,
                                              @TransQty, @BusinessUnit, @ModifiedDate, @ModifiedBy;

      while (@@fetch_status = 0)
        begin
          /* Clear o/p as they will be retained within the loop and pr_Exports_AddOrUpdate update the same record */
          select @RecordId              = null,
                 @TransDateTime         = null,
                 @vOrderDetailsExported = 'Y';

          /* Post the Order Detail transaction */
          exec @ReturnCode = pr_Exports_AddOrUpdate
                               @TransType, @TransEntity, @TransQty, @BusinessUnit,
                               @OrderId          = @OrderId,
                               @OrderDetailId    = @OrderDetailId,
                               @LoadId           = @LoadId,
                               @ShipVia          = @vShipVia,
                               @SoldToId         = @vSoldToId,
                               @ShiptoId         = @vShipToId ,
                               @ShipmentId       = @vShipmentId,
                               @SKUId            = @SKUId,
                               @ReasonCode       = @ReasonCode,
                               @Ownership        = @vOwnership,
                               @SourceSystem     = @vSourceSystem,
                               @Warehouse        = @vWarehouse,
                               @InventoryClass1  = @InventoryClass1,
                               @InventoryClass2  = @InventoryClass2,
                               @InventoryClass3  = @InventoryClass3,
                               @RecordId         = @RecordId,
                           --    @FreightTerms  = @vOHFreightTerms,
                               @TransDateTime    = @ModifiedDate,
                               @ModifiedBy       = @ModifiedBy;

          Fetch next from OrderLinesToExport into @OrderDetailId, @SKUId, @InventoryClass1, @InventoryClass2, @InventoryClass3,
                                                  @TransQty, @BusinessUnit, @ModifiedDate, @ModifiedBy;
        end

      Close OrderLinesToExport;
      Deallocate OrderLinesToExport;
    end

  /* Export Order Headers Y - Export always, D - Export only when details are exported */
  if (@vExportOrderHeaders = 'Y') or
     (@vExportOrderHeaders = 'D' and @vOrderDetailsExported = 'Y')
    begin
      /* Now upload the order header */
      select @TransEntity = 'OH' /* Order Header */,
             @RecordId    = null;

      /* Compute TransQty */
      select @TransQty = case when (@TransType = 'Ship') then sum(UnitsShipped) else null end
      from OrderDetails
      where (OrderId = @OrderId);

      /* Get the freight charges to be reported for the order header */
      select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'TransEntity', @TransEntity);
      exec pr_RuleSets_Evaluate 'Export_FreightCharges', @xmlRulesData, @vFreightCharges output;

      /* Post the Order header transaction */
      exec @ReturnCode = pr_Exports_AddOrUpdate
                           @TransType, @TransEntity, @TransQty, @BusinessUnit,
                           @OrderId        = @OrderId,
                           @Ownership      = @vOwnership,
                           @SourceSystem   = @vSourceSystem,
                           @ReasonCode     = @ReasonCode,
                           @Warehouse      = @vWarehouse,
                           @LoadId         = @LoadId,
                           @ShipVia        = @vShipVia,
                           @SoldToId       = @vSoldToId,
                           @ShiptoId       = @vShipToId,
                           @ShipmentId     = @vShipmentId,
                           @RecordId       = @RecordId,
                           @Weight         = @vWeight,
                           @Volume         = @vVolume,
                         --  @FreightCharges = @vFreightCharges,
                           @TransDateTime  = @ModifiedDate,
                           @ModifiedBy     = @ModifiedBy;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_OrderData */

Go
