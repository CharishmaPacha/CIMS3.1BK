/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/08  RKC     pr_Exports_GetData,pr_Exports_CaptureData:Added ShipToAddress fields
                      pr_Exports_AddOrUpdate, pr_Exports_ConsolidatedOrderData, pr_Exports_OrderData:Added SoldToId, ShipToId params (CID-1175)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_ConsolidatedOrderData') is not null
  drop Procedure pr_Exports_ConsolidatedOrderData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_ConsolidatedOrderData:
   This proc will generate Exports for Original Orders to the respective Consolidated Order
   by distributing the weight/volume/freight charges proportional to the original order units.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_ConsolidatedOrderData
  (@TransType          TTypeCode,
   @OrderId            TRecordId, -- Original OrderId
   @OrderDetailId      TRecordId = null,
   @LoadId             TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReasonCode         TReasonCode = null,
   @TotalLPNsWeight    TWeight,
   @TotalLPNsVolume    TVolume,
   @TotalUnitsShipped  TQuantity,
   @FreightCharges     TMoney)
as
  declare @ReturnCode             TInteger,
          @MessageName            TMessageName,
          @Message                TDescription,
          @vRecordId              TRecordId,
          @vOrderId               TRecordId,
          @vOrderDetailId         TRecordId,
          @vUDF20                 TUDF,
          @vUDF30                 TUDF,
          @vWeight                TWeight,
          @vOrderType             TOrderType,
          @vNumPallets            TCount,
          @vExportOrderDetails    TFlags,
          @vExportOrderHeaders    TFlags,
          @vVolume                TVolume,
          @TransEntity            TEntity,
          @SKUId                  TRecordId,
          @RecordId               TRecordId,
          @TransQty               TQuantity,
          @vOwnership             TOwnership,
          @vSourceSystem          TName,
          @vFreightCharges        TMoney,
          @vWarehouse             TWarehouse,
          @vUnitsShipped          TQuantity,
          @vFreightTerms          TDescription,
          @vShipVia               TShipVia,
          @vSoldToId              TCustomerId,
          @vShipToId              TShipToId,
          @vIsSmallPackageCarrier TFlags;


   declare    @TransDateTime      TDateTime   = null,
              @CreatedDate        TDateTime   = null,
              @ModifiedDate       TDateTime   = null,
              @CreatedBy          TUserId     = null,
              @ModifiedBy         TUserId     = null;

   declare @OrderLinesToExport table (RecordId         TRecordId Identity(1,1),
                                      OrderDetailId    TRecordId,
                                      SKUId            TRecordId,
                                      TransQty         TQuantity,
                                      OrigUnitsToShip  TQuantity,
                                      UnitsToShip      TQuantity,
                                      UnitsShipped     TQuantity,
                                      BusinessUnit     TBusinessUnit,
                                      ModifiedDate     TDateTime,
                                      ModifiedBy       TUserId);

   declare @ttMasterKeys  TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @vRecordId = 0,
         @vUDF20    = @OrderId;

  /* Get the Shipped counts aginst the order to calculate the Weight and Volume */
  select @vUnitsShipped = sum(UnitsShipped)
  from OrderDetails
  where (UDF20 = @vUDF20); -- UDF20 is char field and selecting using an integer var is not using the index

  if (@vUnitsShipped = 0) select @TransType = 'PTCancel';

  /* Calculate weight and Volume based on Units Shipped */
  select @vWeight         = (@TotalLPNsWeight*@vUnitsShipped)/@TotalUnitsShipped,
         @vVolume         = (@TotalLPNsVolume*@vUnitsShipped)/@TotalUnitsShipped,
         @vFreightCharges = (@FreightCharges*@vUnitsShipped)/@TotalUnitsShipped;

  /* Update the order totalweight and totalvolume by calculating the pallet weight and volume */
  update OrderHeaders
  set TotalWeight    = @vWeight,
      TotalVolume    = @vVolume,
      @vSourceSystem = SourceSystem,
      @vOwnership    = Ownership,
      @vWarehouse    = Warehouse,
      @vFreightTerms = FreightTerms,
      @vShipVia      = ShipVia,
      @vSoldToId     = SoldToId,
      @vShipToId     = ShipToId
  where (OrderId = @OrderId);

   /* Get ShipVia info */
  select @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

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

      /* We used to have OR conditions here which are causing poor performance, revised it */
      /* Get all the Order details for the Order in question */
      insert into @OrderLinesToExport(OrderDetailId, SKUId, TransQty, OrigUnitsToShip, UnitsToShip, UnitsShipped,
                                      BusinessUnit, ModifiedDate, ModifiedBy)
        select OrderDetailId, SKUId,
               case when (@TransType = 'Ship') and (@vExportOrderDetails in ('Y')) then UnitsShipped
                    when (@TransType = 'Ship') and (@vExportOrderDetails = 'S'/* Short Ship */)
                      then OrigUnitsAuthorizedToShip-UnitsShipped
                    when (@TransType = 'PTCancel') then UnitsShipped
               end,
               OrigUnitsAuthorizedToShip, UnitsAuthorizedToShip, UnitsShipped,
               BusinessUnit, ModifiedDate, ModifiedBy
        from OrderDetails
        where (UDF20 = @vUDF20);

      /* If Export Order Details = Y, we export all the order details for the Order
         If Export Order Details = S, we only export the short order details - delete others */
      if (@vExportOrderDetails = 'S'/* Short Ship */)
        delete from @OrderLinesToExport
        where (UnitsShipped < OrigUnitsToShip) and
              (UnitsToShip > 0);

      while exists (select * from @OrderLinesToExport where RecordId > @vRecordId)
        begin
          select top 1  @vRecordId     = RecordId,
                        @OrderDetailId = OrderDetailId,
                        @SKUId         = SKUId,
                        @TransQty      = TransQty,
                        @BusinessUnit  = BusinessUnit,
                        @ModifiedDate  = ModifiedDate,
                        @ModifiedBy    = ModifiedBy
          from @OrderLinesToExport
          where (RecordId > @vRecordId)
          order by RecordId;

          /* Post the Order Detail transaction */
          exec @ReturnCode = pr_Exports_AddOrUpdate
                               @TransType, @TransEntity, @TransQty, @BusinessUnit,
                               @OrderId       = @OrderId,
                               @OrderDetailId = @OrderDetailId,
                               @LoadId        = @LoadId,
                               @SoldToId      = @vSoldToId,
                               @ShiptoId      = @vShipToId ,
                               @SKUId         = @SKUId,
                               @ReasonCode    = @ReasonCode,
                               @Ownership     = @vOwnership,
                               @SourceSystem  = @vSourceSystem,
                               @Warehouse     = @vWarehouse,
                               @RecordId      = @RecordId,
                               @TransDateTime = @ModifiedDate,
                               @ModifiedBy    = @ModifiedBy;
        end /* while OrderLinesToExport */
    end /* If ExportOrder Details */

  /* Export Order Headers Y - Export always, D - Export only when details are exported */
  if (@vExportOrderHeaders = 'Y') or
     (@vExportOrderHeaders = 'D')
    begin
      /* Now upload the order header */
      select @TransEntity = 'OH' /* Order Header */,
             @RecordId    = null,
             @TransQty    = @vUnitsShipped;

      if ((@TransEntity = 'OH') and (@vIsSmallPackageCarrier = 'Y') and (@vFreightTerms in ('COLLECT', '3RDPARTY')))
        select  @vFreightCharges = 0.0;

      /* Post the Order header transaction */
      exec @ReturnCode = pr_Exports_AddOrUpdate
                           @TransType, @TransEntity, @TransQty, @BusinessUnit,
                           @OrderId        = @OrderId,
                           @Ownership      = @vOwnership,
                           @SourceSystem   = @vSourceSystem,
                           @ReasonCode     = @ReasonCode,
                           @Warehouse      = @vWarehouse,
                           @LoadId         = @LoadId,
                           @SoldToId       = @vSoldToId,
                           @ShiptoId       = @vShipToId ,
                           @RecordId       = @RecordId,
                           @Weight         = @vWeight,
                           @Volume         = @vVolume,
                           @FreightCharges = @vFreightCharges,
                           @TransDateTime  = @ModifiedDate,
                           @ModifiedBy     = @ModifiedBy;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_ConsolidatedOrderData */

Go
