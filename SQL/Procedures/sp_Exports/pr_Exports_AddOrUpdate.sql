/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/25  VS      pr_Exports_InsertRecords, pr_Exports_AddOrUpdate, pr_Exports_WarehouseTransferForMultipleLPNs:
  2020/10/15  SK      pr_Exports_LPNData, pr_Exports_AddOrUpdate: New parameter FromLPNId included to be inserted or updated (HA-1516)
  2020/03/30  YJ      pr_Exports_AddOrUpdate, pr_Exports_GetData, pr_Exports_LPNData: To get E.InventoryClassses (HA-85)
                      pr_Exports_AddOrUpdate, pr_Exports_ConsolidatedOrderData, pr_Exports_OrderData:Added SoldToId, ShipToId params (CID-1175)
  2019/09/17  MS      pr_Exports_AddOrUpdate: Changes to populate ShipVia and other ShipVia fields
  2018/03/16  DK      pr_Exports_AddOrUpdate, pr_Exports_LPNData, pr_Exports_OrderData: Enhanced to insert SourceSystem in Exports (FB-1114)
  2018/02/24  SV      pr_Exports_LPNData: Pass the Receiver# to pr_Exports_AddOrUpdate update over the Exports
                      pr_Exports_AddOrUpdate: Added Receiver# in the signature to update Receiver# over Exports. (S2G-225)
                      pr_Exports_AddOrUpdate: Made changes to evaluate rules irrespective of status passed (HPI-1493)
  2017/04/07  RV      pr_Exports_AddOrUpdate: Evaluate rules to send transaction to host (HPI-1493)
  2014/01/20  TD      pr_Exports_LPNData, pr_Exports_AddOrUpdate: Added FromLocationId,ToLocationId as input Params.
  2013/08/13  PK      pr_Exports_LPNData: Passing in default values to pr_Exports_AddOrUpdate for params Length, Width and Height.
                      pr_Exports_AddOrUpdate: Added new params.
  2012/07/17  AY      pr_Exports_AddOrUpdate, pr_Exports_LPNData: Added Warehouse
  2011/01/23  AY      pr_Exports_LPNData: Added, revised pr_Exports_AddOrUpdate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_AddOrUpdate') is not null
  drop Procedure pr_Exports_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_AddOrUpdate:
    Procedures assumes that the caller would pass valid information to this.
    Hence, no validations are required.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_AddOrUpdate
  (@TransType          TTypeCode,
   @TransEntity        TEntity,
   @TransQty           TQuantity,
   @BusinessUnit       TBusinessUnit,

   @Status             TStatus           = 'N' /* Not Yet Processed */,

   @SKUId              TRecordId         = null,
   @LPNId              TRecordId         = null,
   @LPNDetailId        TRecordId         = null,
   @LocationId         TRecordId         = null,
   @PalletId           TRecordId         = null,

   @ReceiverId         TRecordId         = null,
   @ReceiverNumber     TReceiverNumber   = null,
   @ReceiptId          TRecordId         = null,
   @ReceiptDetailId    TRecordId         = null,

   @ReasonCode         TReasonCode       = null,
   @Warehouse          TWarehouse        = null,
   @Ownership          TOwnership        = null,
   @SourceSystem       TName             = null,
   @Weight             TWeight           = 0.0,
   @Volume             TVolume           = 0.0,
   @Length             TFloat            = 0.0,
   @Height             TFloat            = 0.0,
   @Width              TFloat            = 0.0,
   @Lot                TLot              = null,
   @InventoryClass1    TInventoryClass   = null,
   @InventoryClass2    TInventoryClass   = null,
   @InventoryClass3    TInventoryClass   = null,

   @OrderId            TRecordId         = null,
   @OrderDetailId      TRecordId         = null,
   @ShipmentId         TShipmentId       = null,
   @LoadId             TLoadId           = null,
   @SoldToId           TCustomerId       = null,
   @ShipToId           TShipToId         = null,

   @Reference          TReference        = null,
   @FreightCharges     TMoney            = null,
   @TrackingNo         TTrackingNo       = null,

   @ShipVia            TShipVia          = null,

   /* Future Use */
   @PrevSKUId          TRecordId         = null,
   @FromLPNId          TRecordId         = null,
   @FromLPN            TLPN              = null,
   @FromWarehouse      TWarehouse        = null,
   @ToWarehouse        TWarehouse        = null,
   @FromLocationId     TRecordId         = null,
   @FromLocation       TLocation         = null,
   @ToLocationId       TRecordId         = null,
   @ToLocation         TLocation         = null,
   @MonetaryValue      TMonetaryValue    = null,
   ---------------------------------------------
   @RecordId           TRecordId = null output,
   @TransDateTime      TDateTime = null output,
   @CreatedDate        TDateTime = null output,
   @ModifiedDate       TDateTime = null output,
   @CreatedBy          TUserId   = null output,
   @ModifiedBy         TUserId   = null output)

as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,

          @vShipVia          TShipVia,
          @xmlRulesData      TXML;

  declare @Inserted table (RecordId TRecordId, TransDateTime TDateTime, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null;

  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('TransEntity',     @TransEntity ) +
                           dbo.fn_XMLNode('TransType',       @TransType   ) +
                           dbo.fn_XMLNode('LPNId',           @LPNId       ) +
                           dbo.fn_XMLNode('ReceiptId',       @ReceiptId   ) +
                           dbo.fn_XMLNode('OrderId',         @OrderId     ) +
                           dbo.fn_XMLNode('SKUId',           @SKUId       ) +
                           dbo.fn_XMLNode('LoadId',          @LoadId      ) +
                           dbo.fn_XMLNode('ShipVia',         @ShipVia     ) +
                           dbo.fn_XMLNode('ShipmentId',      @ShipmentId  ) +
                           dbo.fn_XMLNode('ReceiverNumber',  @ReceiverNumber) +
                           dbo.fn_XMLNode('SourceSystem',    @SourceSystem) +
                           dbo.fn_XMLNode('ReasonCode',      @ReasonCode  ) +
                           dbo.fn_XMLNode('Ownership',       @Ownership   ) +
                           dbo.fn_XMLNode('Warehouse',       @Warehouse   ) +
                           dbo.fn_XMLNode('BusinessUnit',    @BusinessUnit));

  /* Evaluate the rules to determine whether to send exports to host or not */
  exec pr_RuleSets_Evaluate 'Export_StatusFlag', @xmlRulesData, @Status output;

  /* Evaluate the rules and get the ShipVia to send exports */
  exec pr_RuleSets_Evaluate 'Export_GetShipVia', @xmlRulesData, @vShipVia output;

  select @vShipVia = coalesce(@vShipVia, @ShipVia);

  /* If RecordId is not given or is not a valid one then insert. Note that we never pass in RecordId from caller */
  if (coalesce(@RecordId, 0) = 0) or
     (not exists (select * from Exports where RecordId = @RecordId))
    begin
      insert into Exports(TransType,
                          TransEntity,
                          TransQty,
                          Status,
                          SKUId,
                          LPNId,
                          LPNDetailId,
                          LocationId,
                          PalletId,
                          ReceiverId,
                          ReceiverNumber,
                          ReceiptId,
                          ReceiptDetailId,
                          ReasonCode,
                          Warehouse,
                          Ownership,
                          SourceSystem,
                          Weight,
                          Volume,
                          Length,
                          Height,
                          Width,
                          Lot,
                          InventoryClass1,
                          InventoryClass2,
                          InventoryClass3,
                          OrderId,
                          OrderDetailId,
                          ShipmentId,
                          LoadId,
                          SoldToId,
                          ShipToId,
                          ShipVia,
                          Reference,
                          FreightCharges,
                          TrackingNo,
                          BusinessUnit,
                          /* Future Use */
                          PrevSKUId,
                          FromLPNId,
                          FromLPN,
                          FromWarehouse,
                          ToWarehouse,
                          FromLocationId,
                          ToLocationId,
                          FromLocation,
                          ToLocation,
                          MonetaryValue,
                          /* Future Use */
                          CreatedBy)
                   output inserted.RecordId, inserted.TransDateTime, inserted.CreatedDate, inserted.CreatedBy
                     into @Inserted
                   select @TransType,
                          @TransEntity,
                          @TransQty,
                          @Status,
                          @SKUId,
                          @LPNId,
                          @LPNDetailId,
                          @LocationId,
                          @PalletId,
                          @ReceiverId,
                          @ReceiverNumber,
                          @ReceiptId,
                          @ReceiptDetailId,
                          @ReasonCode,
                          @Warehouse,
                          @Ownership,
                          coalesce(@SourceSystem, 'HOST'),
                          @Weight,
                          @Volume,
                          @Length,
                          @Height,
                          @Width,
                          coalesce(@Lot, ''),
                          @InventoryClass1,
                          @InventoryClass2,
                          @InventoryClass3,
                          @OrderId,
                          @OrderDetailId,
                          @ShipmentId,
                          @LoadId,
                          @SoldToId,
                          @ShipToId,
                          @vShipVia,
                          @Reference,
                          @FreightCharges,
                          @TrackingNo,
                          @BusinessUnit,
                          /* Future Use */
                          @PrevSKUId,
                          @FromLPNId,
                          @FromLPN,
                          @FromWarehouse,
                          @ToWarehouse,
                          @FromLocationId,
                          @ToLocationId,
                          @FromLocation,
                          @ToLocation,
                          @MonetaryValue,
                          /* Future Use */
                          coalesce(@CreatedBy, system_user);

      select @RecordId      = RecordId,
             @TransDateTime = TransDateTime,
             @CreatedDate   = CreatedDate,
             @CreatedBy     = CreatedBy
      from @Inserted;
    end
   else
      begin
        update Exports
        set TransQty              = coalesce(@TransQty, TransQty),
            Status                = coalesce(@Status, Status),
            SKUId                 = coalesce(@SKUId, SKUId),
            LPNId                 = coalesce(@LPNId, LPNId),
            LPNDetailId           = coalesce(@LPNDetailId, LPNDetailId),
            LocationId            = coalesce(@LocationId, LocationId),
            PalletId              = coalesce(@PalletId, PalletId),
            ReceiverNumber        = coalesce(@ReceiverNumber, ReceiverNumber),
            ReceiptId             = coalesce(@ReceiptId, ReceiptId),
            ReceiptDetailId       = coalesce(@ReceiptDetailId, ReceiptDetailId),
            ReasonCode            = coalesce(@ReasonCode, ReasonCode),
            Warehouse             = coalesce(@Warehouse, Warehouse),
            Ownership             = coalesce(@Ownership, Ownership),
            SourceSystem          = coalesce(@SourceSystem, SourceSystem),
            Weight                = coalesce(@Weight, Weight),
            Volume                = coalesce(@Volume, Volume),
            Lot                   = coalesce(@Lot, Lot),
            InventoryClass1       = coalesce(@InventoryClass1, InventoryClass1),
            InventoryClass2       = coalesce(@InventoryClass2, InventoryClass2),
            InventoryClass3       = coalesce(@InventoryClass3, InventoryClass3),
            Length                = coalesce(@Length, Length),
            Height                = coalesce(@Height, Height),
            Width                 = coalesce(@Width, Width),
            OrderId               = coalesce(@OrderId, OrderId),
            OrderDetailId         = coalesce(@OrderDetailId, OrderDetailId),
            ShipmentId            = coalesce(@ShipmentId, ShipmentId),
            LoadId                = coalesce(@LoadId, LoadId),
            SoldToId              = coalesce(@SoldToId, SoldToId),
            ShipToId              = coalesce(@ShipToId, ShipToId),
            ShipVia               = coalesce(@vShipVia, ShipVia),
            Reference             = coalesce(@Reference, Reference),
            FreightCharges        = coalesce(@FreightCharges, FreightCharges),
            TrackingNo            = coalesce(@TrackingNo, TrackingNo),
            /* Future Use */
            PrevSKUId             = coalesce(@PrevSKUId, PrevSKUId),
            FromLPNId             = coalesce(@FromLPNId, FromLPNId),
            FromLPN               = coalesce(@FromLPN, FromLPN),
            FromWarehouse         = coalesce(@FromWarehouse, FromWarehouse),
            ToWarehouse           = coalesce(@ToWarehouse, ToWarehouse),
            FromLocationId        = coalesce(@FromLocationId, FromLocationId),
            ToLocationId          = coalesce(@ToLocationId, ToLocationId),
            FromLocation          = coalesce(@FromLocation, FromLocation),
            ToLocation            = coalesce(@ToLocation, ToLocation),
            MonetaryValue         = coalesce(@MonetaryValue, MonetaryValue),
            /* Future Use */
            @ModifiedDate = ModifiedDate = current_timestamp,
            @ModifiedBy   = ModifiedBy   = coalesce(@ModifiedBy, system_user)
        where RecordId = @RecordId
     end

ErrorHandler:
   exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_AddOrUpdate */

Go
