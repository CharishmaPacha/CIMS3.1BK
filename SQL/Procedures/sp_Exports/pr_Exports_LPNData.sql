/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/07  TK      pr_Exports_LPNData & pr_Exports_WarehouseTransferForMultipleLPNs:
              AY      pr_Exports_LPNData: Do not depend upon reason codes for sending -ve exports (HA-1837)
  2020/10/15  SK      pr_Exports_LPNData, pr_Exports_AddOrUpdate: New parameter FromLPNId included to be inserted or Updated (HA-1516)
  2020/05/18  KBB     pr_Exports_LPNData: Adding single cotations to value @reasoncode (HA-544)
  2020/05/06  TK      pr_Exports_LPNData & pr_Exports_InsertRecords: Bug fix in exporting InventoryClass (HA-422)
              AY      pr_Exports_LPNData: Export ReceiverId
  2020/04/29  MS      pr_Exports_OnhandInventory, pr_Exports_LPNData, pr_Exports_LPNReceiptConfirmation: Changes to send InventoryClasses in Exports (HA-323)
  2020/03/30  YJ      pr_Exports_AddOrUpdate, pr_Exports_GetData, pr_Exports_LPNData: To get E.InventoryClassses (HA-85)
  2018/03/16  DK      pr_Exports_AddOrUpdate, pr_Exports_LPNData, pr_Exports_OrderData: Enhanced to insert SourceSystem in Exports (FB-1114)
  2018/02/24  SV      pr_Exports_LPNData: Pass the Receiver# to pr_Exports_AddOrUpdate update over the Exports
                         which will be recalculated in pr_Exports_LPNData (HPI-1675)
  2017/07/31  DK      pr_Exports_LPNData: Made changes to insert Warehouse as well while generating exports at detail level
  2017/04/10  RV      pr_Exports_LPNData: Added rules to evaluate the status in exports add or Update procedure, so remove the
  2016/12/26  AY/PK   pr_Exports_LPNData: Set default value as zero for LoadId (HPI-GoLive)
  2015/09/29  DK      pr_Exports_LPNData: Modified to get ReasonCode from LPNs in case ReasonCode is null and Transtype is 'Recv'.
  2014/04/03  PK      pr_Exports_LPNData: Changing the TransType based on the ReasonCode.
  2014/03/07  TD/NY   pr_Exports_LPNData : Passing FromWh, ToWh for LPNs having more than 1 details as well.
  2014/02/10  AY      pr_Exports_LPNData: Changed Qty Sign for Lost/Short Pick only if it is an InvCh and not
  2014/01/28  NY      pr_Exports_LPNData: Passing LocationId to exports.
  2014/01/20  TD      pr_Exports_LPNData, pr_Exports_AddOrUpdate: Added FromLocationId,ToLocationId as input Params.
  2014/01/15  PK      pr_Exports_LPNData: Included Reason code for lost lpns to generate negative transactions.
  2013/10/10  NY      pr_Exports_WarehouseTransfer:Passing TransQty to pr_Exports_LPNData
  2013/10/08  TD      pr_Exports_LPNData: Export LPN Data changes to send PalletId.
  2013/08/13  PK      pr_Exports_LPNData: Passing in default values to pr_Exports_AddOrUpdate for params Length, Width and Height.
  2013/05/08  AY      pr_Exports_LPNData: Upload LPN Details when a multi-SKU LPN has been putaway
  2012/07/17  AY      pr_Exports_AddOrUpdate, pr_Exports_LPNData: Added Warehouse
  2011/12/09  AY/VM   pr_Exports_LPNData: Get details of LPNDetails and LPNHdr details
  2011/10/12  NB/AY   pr_Exports_LPNData: Changed to export both LPN and it's details for
  2011/09/14  TD      pr_Exports_LPNData: Export will be done for Active TransTypes only.
  2011/09/06  TD      pr_Exports_LPNData: Do not clear CreatedBy as it is now used.
  2011/04/06  VM      pr_Exports_LPNData: Export Picked info to host as well
  2011/01/23  AY      pr_Exports_LPNData: Added, revised pr_Exports_AddOrUpdate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_LPNData') is not null
  drop Procedure pr_Exports_LPNData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_LPNData:
    Procedures assumes that the caller would pass valid information to this.
    Hence, no validations are required.

    #TODO - VM: We will using this procedure to log Order Details as well when PT is
          completed picked, hence the name of the procedure neeeds to be changed
          to something like this (pr_Exports_ExportData etc.,) and change the
          callers to use latest name.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_LPNData
  (@TransType          TTypeCode,
   @TransEntity        TEntity           = null,
   @TransQty           TQuantity,
   @BusinessUnit       TBusinessUnit     = null,

   @Status             TStatus           = 'N',

   @SKUId              TRecordId         = null,
   @LPNId              TRecordId         = null,
   @LPNDetailId        TRecordId         = null,
   @LocationId         TRecordId         = null,
   @PalletId           TRecordId         = null,

   @ReceiptId          TRecordId         = null,
   @ReceiptDetailId    TRecordId         = null,
   @HostReceiptLine    THostReceiptLine  = null,

   @ReasonCode         TReasonCode       = null,
   @Warehouse          TWarehouse        = null,
   @Ownership          TOwnership        = null,
   @Weight             TWeight           = 0.0,
   @Volume             TVolume           = 0.0,
   @Lot                TLot              = null,
   @InventoryClass1    TInventoryClass   = null,
   @InventoryClass2    TInventoryClass   = null,
   @InventoryClass3    TInventoryClass   = null,

   @OrderId            TRecordId         = null,
   @OrderDetailId      TRecordId         = null,
   @ShipmentId         TShipmentId       = null,
   @LoadId             TLoadId           = null,

   @Reference          TReference        = null,

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
   @QuantitySign       TInteger          = null,
   /* Future Use */
   -------------------------------------
   @RecordId           TRecordId = null output,
   @TransDateTime      TDateTime = null output,
   @CreatedDate        TDateTime = null output,
   @ModifiedDate       TDateTime = null output,
   @CreatedBy          TUserId   = null output,
   @ModifiedBy         TUserId   = null output)

as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vMessage         TDescription,

          @vLPNQuantity     TInteger,
          @vReceiverId      TRecordId,
          @vReceiverNumber  TReceiverNumber,
          @vLPNDetailId     TRecordId,
          @vLPNLineQuantity TQuantity,
          @vUploadRecords   TVarChar,
          @vQuantitySign    TInteger,
          @vLPNLines        TInteger,
          @vPalletId        TRecordId,
          @vStatus          TStatus,
          @vFreightCharges  TMoney,
          @vSourceSystem    TName,
          @vSoldToId        TCustomerId,
          @vShipToId        TShipToId,
          @vTrackingNo      TTrackingNo,
          @vInventoryClass1 TInventoryClass,
          @vInventoryClass2 TInventoryClass,
          @vInventoryClass3 TInventoryClass,

          @vxmlRulesData    TXML;

begin
  SET NOCOUNT ON;

  /* Get ReasonCode from LPNs in case ReasonCode is null and TransType is 'Recv' */
  if (@ReasonCode is null) and (@TransType = 'Recv')
    select @ReasonCode = ReasonCode
    from LPNs
    where (LPNId = @LPNId);

  /* Ignore Inv. Changes with reason code of 99 as XSC would like to not generate exports sometimes */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @QuantitySign  = case when @QuantitySign is not null then @QuantitySign
                               else 1
                          end,
         @Status        = case when (@TransType = 'InvCh') and (len(@ReasonCode) = 2) and (substring(@ReasonCode, 1, 1) = '9') then 'I' /* Ignore */
                               else @Status
                          end;

  if not exists (select * from vwEntityTypes
                 where ((TypeCode = @TransType) and
                        (Entity   = 'Transaction')))
    goto Exithandler;

  /* If an LPN Detail has not been specified then we have to determine if LPN or LPNDetails
     have to be uploaded. If LPN has multiple lines, then upload LPN Details */
  if (@LPNDetailId is null)
    select @vLPNLines = count(*)
    from LPNDetails
    where (LPNId = @LPNId);

  select @vUploadRecords = Case
                             when (@LPNDetailId is not null) then
                               'LPNDetail'
                             when @TransType in ('Ship', 'Xfer', 'Pick') then
                               'Both'
                             when (@TransType in ('Recv', 'WHXfer') and @vLPNLines > 1) or (@TransEntity = 'LPNDetails') then
                               'LPNDetails'
                             when (@LPNId is not null) then
                               'LPN'
                             else
                               null
                           end;

  if (@vUploadRecords is null)
    return (-1); /* Neither LPN nor LPNDetail are given, so exit with error */

  /* Build Xml for rules */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('TransType',     @TransType) +
                            dbo.fn_XMLNode('TransEntity',   @TransEntity) +
                            dbo.fn_XMLNode('LPNId',         @LPNId) +
                            dbo.fn_XMLNode('OrderId',       @OrderId) +
                            dbo.fn_XMLNode('UploadRecords', @vUploadRecords));

  /* If LPNDetailId is given, then retrieve missing values from it, else
     from LPN */
  if (@vUploadRecords = 'LPNDetail')
    begin
      select @TransEntity     = coalesce(@TransEntity, 'LPND');

      select @TransQty        = coalesce(@TransQty,        Quantity) * @QuantitySign,
             @LPNId           = coalesce(@LPNId,           LPNId),
             @SKUId           = coalesce(@SKUId,           SKUId),
             @ReceiptId       = coalesce(@ReceiptId,       ReceiptId),
             @ReceiptDetailId = coalesce(@ReceiptDetailId, ReceiptDetailId),
             @OrderId         = coalesce(@OrderId,         OrderId),
             @OrderDetailId   = coalesce(@OrderDetailId,   OrderDetailId),
             @Lot             = coalesce(@Lot,             Lot)
      from LPNDetails
      where (LPNDetailId = @LPNDetailId);

      select @PalletId         = coalesce(@PalletId,        PalletId),
             @LocationId       = coalesce(@LocationId,      LocationId),
             @vReceiverId      = ReceiverId,
             @vReceiverNumber  = coalesce(ReceiverNumber,   ''),
             @ShipmentId       = coalesce(@ShipmentId,      ShipmentId),
             @LoadId           = coalesce(@LoadId,          LoadId, 0),
             @vInventoryClass1 = coalesce(@InventoryClass1, InventoryClass1),
             @vInventoryClass2 = coalesce(@InventoryClass2, InventoryClass2),
             @vInventoryClass3 = coalesce(@InventoryClass3, InventoryClass3),
             @Warehouse        = coalesce(@Warehouse,       DestWarehouse),
             @Ownership        = coalesce(@Ownership,       Ownership),
             @BusinessUnit     = coalesce(@BusinessUnit,    BusinessUnit)
      from LPNs
      where (LPNId = @LPNId);
    end
  else
  if (@vUploadRecords = 'Both' /* LPN and Details */) or
     (@vUploadRecords = 'LPNDetails')
    begin
      /* Export LPN Details  */
      declare LPNLinesToExport Cursor Local Forward_Only Static Read_Only
      For select LPNDetailId, Quantity, PalletId, BusinessUnit
          from vwLPNDetails
          where (LPNId = @LPNId) and
                (Quantity > 0);

      Open LPNLinesToExport;
      Fetch next from LPNLinesToExport into @vLPNDetailId, @vLPNLineQuantity, @vPalletId, @BusinessUnit;

      while (@@fetch_status = 0)
        begin
          /* Post the Export transaction */
          exec @vReturnCode = pr_Exports_LPNData @TransType,
                                                 @LPNDetailId    = @vLPNDetailId,
                                                 @TransQty       = @vLPNLineQuantity,
                                                 @LocationId     = @LocationId,
                                                 @PalletId       = @vPalletId,
                                                 @BusinessUnit   = @BusinessUnit,
                                                 @ReasonCode     = @ReasonCode,
                                                 @FromLPNId      = @FromLPNId,
                                                 @FromLPN        = @FromLPN,
                                                 @Warehouse      = @Warehouse,
                                                 @FromWarehouse  = @FromWarehouse,
                                                 @ToWarehouse    = @ToWarehouse,
                                                 @FromLocationId = @FromLocationId,
                                                 @FromLocation   = @FromLocation,
                                                 @ToLocationId   = @ToLocationId,
                                                 @ToLocation     = @ToLocation,
                                                 @QuantitySign   = @QuantitySign,
                                                 @Reference      = @Reference,
                                                 @CreatedBy      = @CreatedBy;

          Fetch next from LPNLinesToExport into @vLPNDetailId, @vLPNLineQuantity, @vPalletId, @BusinessUnit;
        end

        Close LPNLinesToExport;
        Deallocate LPNLinesToExport;
     end

  /* Export LPN Info */
  if (@vUploadRecords in ('LPN', 'Both'))
    begin
      select @TransEntity      = coalesce(@TransEntity, 'LPN'),
             @TransQty         = coalesce(@TransQty, L.Quantity),
             @SKUId            = coalesce(@SKUId, L.SKUId),
             @PalletId         = coalesce(@PalletId, L.PalletId),
             @LocationId       = coalesce(@LocationId, L.LocationId),
             @vReceiverId      = coalesce(@vReceiverId, L.ReceiverId),
             @vReceiverNumber  = coalesce(@vReceiverNumber, L.ReceiverNumber),
             @ReceiptId        = coalesce(@ReceiptId, L.ReceiptId),
             @ReceiptDetailId  = coalesce(@ReceiptDetailId, LD.ReceiptDetailId),
             @OrderId          = coalesce(@OrderId, L.OrderId),
             @OrderDetailId    = coalesce(@OrderDetailId, LD.OrderDetailId),
             @ShipmentId       = coalesce(@ShipmentId, L.ShipmentId),
             @LoadId           = coalesce(@LoadId, L.LoadId, 0),
             @Warehouse        = coalesce(@Warehouse, L.DestWarehouse),
             @Ownership        = coalesce(@Ownership, L.Ownership),
             @vInventoryClass1 = coalesce(@InventoryClass1, L.InventoryClass1),
             @vInventoryClass2 = coalesce(@InventoryClass2, L.InventoryClass2),
             @vInventoryClass3 = coalesce(@InventoryClass3, L.InventoryClass3),
             @BusinessUnit     = coalesce(@BusinessUnit, L.BusinessUnit),
             @vTrackingNo      = L.TrackingNo
      from LPNs L left outer join LPNDetails LD on L.LPNId = LD.LPNId
      where (L.LPNId = @LPNId);

      /* some how this is not updating with sign in above statement, so move here
         will check later about the above issue */
      select @TransQty = @TransQty * @QuantitySign;
    end

  /* Identify Source System */
  if (@TransType = 'Ship')
    select @vSourceSystem = SourceSystem,
           @vSoldToId     = SoldToId,
           @vShipToId     = ShipToId
    from OrderHeaders
    where (OrderId = @OrderId);
  else
  if (@TransType in ('InvCh', 'WhXFer'))
    select Top 1 @vSourceSystem = S.SourceSystem
    from LPNDetails LD
      join SKUs S on (LD.SKUId = S.SKUId)
    where (LD.LPNId = @LPNId)
    order by LD.LPNDetailId;
  else
  if (@TransType = 'Recv')
    select @vSourceSystem = SourceSystem
    from ReceiptHeaders
    where (ReceiptId = @ReceiptId);

  /* ToDo: if given Weight/Volume are null, pro-rate by weight in LPN Detail */
  /* ToDo: See if we can compute the monetary value as well */
  /* ToDo: Create cursor and iterate thru each LPNDetail for an LPN - For now
           we assume that only single SKU LPNs would be putaway and hence there
           would be only one LPNDetail to work with */

  /* Avoid posting the extra export transaction, if the UploadRecords is of 'LPNDetails',
     as we post each LPN detail transaction internally by calling this procedure */
  if (@vUploadRecords <> 'LPNDetails')
    begin
      /* Get the freight charges to be reported for the order header */
      select @vxmlRulesData = dbo.fn_XMLStuffValue (@vxmlRulesData, 'TransEntity', @TransEntity);
      select @vxmlRulesData = dbo.fn_XMLStuffValue (@vxmlRulesData, 'OrderId', @OrderId);
      exec pr_RuleSets_Evaluate 'Export_FreightCharges', @vxmlRulesData, @vFreightCharges output;

      /* Post the Export transaction */
      exec @vReturnCode = pr_Exports_AddOrUpdate
                            @TransType, @TransEntity, @TransQty, @BusinessUnit,
                            @Status,
                            /* Inventory Details */
                            @SKUId, @LPNId, @LPNDetailId, @LocationId, @PalletId,
                            /* Purchase Details */
                            @vReceiverId, @vReceiverNumber, @ReceiptId, @ReceiptDetailId,
                            /* LPN Details */
                            @ReasonCode, @Warehouse, @Ownership, @vSourceSystem, @Weight, @Volume,
                            default /* Length */, default /* Height */,
                            default /* Width */, @Lot, @vInventoryClass1, @vInventoryClass2, @vInventoryClass3,
                            /* Order Details */
                            @OrderId, @OrderDetailId, @ShipmentId, @LoadId,
                            @vSoldToId, @vShipToId,
                            /* Misc */
                            @Reference, @vFreightCharges, @vTrackingNo, null /* ShipVia */,
                            /* Future Use */
                            @PrevSKUId, @FromLPNId, @FromLPN, @FromWarehouse, @ToWarehouse,
                            @FromLocationId, @FromLocation,
                            @ToLocationId, @ToLocation, @MonetaryValue,
                            @RecordId    output, @TransDateTime output,
                            @CreatedDate output, @ModifiedDate  output,
                            @CreatedBy   output, @ModifiedBy    output;
    end

ErrorHandler:
   exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_LPNData */

Go
