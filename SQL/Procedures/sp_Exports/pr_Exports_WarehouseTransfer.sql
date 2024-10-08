/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/25  VS      pr_Exports_InsertRecords, pr_Exports_AddOrUpdate, pr_Exports_WarehouseTransferForMultipleLPNs:
  2021/05/01  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Bug fix - missing union (HA-2736)
  2021/04/14  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Send LPND exports when LPN has multiple SKUs (HA-2626)
  2021/04/12  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Export reference on LPNs (HA-2601)
  2020/12/31  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Initial Revision (HA-1830)
  2020/07/29  TK      pr_Exports_WarehouseTransfer: Introduced ToLocationId to fix bug in generating exports (HA-1246)
  2020/07/29  RT      pr_Exports_WarehouseTransfer: Included few Parameters to generate the Exports (HA-111)
  2020/06/11  VS      pr_Exports_WarehouseTransfer: Made changes to generate exports for Transfer Orders (HA-110)
  2018/02/12  VS      pr_Exports_WarehouseTransfer: Added Reference field in Exports for WHTransfer (CID-68)
  2018/08/16  TK      pr_Exports_WarehouseTransfer: Changes to pass LPNDetailId while generating WHXfer exports (S2G-1080)
  2018/05/01  RV      pr_Exports_WarehouseTransfer: Migrated changes from HPI to generate exports for transferred units (S2G-714)
  2017/11/07  SV      pr_Exports_WarehouseTransfer: Resolved the issue with wrong TransQty update over the available LPN/LOC
                      pr_Exports_WarehouseTransfer: Made changes to send TransEntity in order to send exports at details level (OB-541).
  2016/02/23  PK      pr_Exports_WarehouseTransfer: Added controls variable WHXferAsInvCh.
  2013/10/10  NY      pr_Exports_WarehouseTransfer:Passing TransQty to pr_Exports_LPNData
  2013/10/10  AY      pr_Exports_WarehouseTransfer: Export single or multiple records
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_WarehouseTransfer') is not null
  drop Procedure pr_Exports_WarehouseTransfer;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_WarehouseTransfer:
    Procedure to generate client appropriate transactions on Warehouse transfer.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_WarehouseTransfer
  (@TransType          TTypeCode         = null,
   @TransEntity        TEntity           = null,
   @TransQty           TQuantity,
   @BusinessUnit       TBusinessUnit     = null,

   @Status             TStatus           = 'N',

   @SKUId              TRecordId         = null,
   @LPNId              TRecordId         = null,
   @LPNDetailId        TRecordId         = null,
   @LocationId         TRecordId         = null,
   @ToLocationId       TRecordId         = null,
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

   @OrderId            TRecordId         = null,
   @OrderDetailId      TRecordId         = null,
   @ShipmentId         TShipmentId       = null,
   @LoadId             TLoadId           = null,

   @Reference          TReference        = null,

   @FromLPNId          TRecordId         = null,
   @FromLPNDetailId    TRecordId         = null,
   @PrevSKUId          TRecordId         = null,
   @OldWarehouse       TWarehouse        = null,
   @NewWarehouse       TWarehouse        = null,
   @MonetaryValue      TMonetaryValue    = null,
   @Operation          TOperation        = null,

   /* Future Use */
   --------------------------------------------
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

          @vTransType       TTypeCode,
          @vLPNQuantity     TInteger,
          @vLPNDetailId     TRecordId,
          @vUploadRecords   TVarChar,
          @vQuantitySign    TInteger,
          @vLPNLines        TInteger,
          @vPalletId        TRecordId,
          @vToLocationId    TRecordId,
          @vControlCategory TCategory,
          @vExportWHXferAsInventoryChange  TFlag;
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @ReasonCode    = coalesce(@ReasonCode, '130' /* Modify Warehouse */),
         @FromLPNId     = coalesce(@FromLPNId, @LPNId); -- If From LPN is not given, then it could be changing WH on LPN

  /* Get the control category */
  select @vControlCategory         = 'Exports' + coalesce('_' + @Operation, '');

  /* Get the control value whether to generate InvCh Exports when transferring the inventory between Warehouses */
  select @vExportWHXferAsInventoryChange = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'WHXferAsInvCh', 'Y' /* Yes */, @BusinessUnit, @CreatedBy);

  /* Determine the transaction type to upload */
  select @vTransType = Case
                         when (@vExportWHXferAsInventoryChange = 'N' /* No */) then
                           'WHXfer'
                          else
                           'InvCh'
                       end;

  -- If we do not need exports to be sent, we will mark them as Ignore using rules
  -- we cannot skip altogether as if they need it later, we wouldn't even know what they are.

  -- if not exists (select * from vwEntityTypes
  --                where ((TypeCode = @vTransType) and
  --                       (Entity   = 'Transaction')))
  --   goto Exithandler;

  /* Export WHXfer or InvCh */
  if (@vTransType = 'WhXfer')
    begin
      /* Consider the case ToLPN is having 25 units initally  and we xfered 5 units from FromLPN.
         Earlier we passed @TransQty as null as we are calculating in Exports_LPNData which exports the TransQty
         of the ToLPN which as 30(25 + 5 Qty Xfered). This is wrong as we need to generate the exports the Qty
         which is Xfered. Hence passed @TransQty */
      exec @vReturnCode = pr_Exports_LPNData 'WhXFer'        /* Warehouse Transfer */,
                                             @LPNId         = @LPNId,
                                             @LPNDetailId   = @LPNDetailId,
                                             @TransQty      = @TransQty,
                                             @FromWarehouse = @OldWarehouse,
                                             @ToWarehouse   = @NewWarehouse,
                                             @ReasonCode    = @ReasonCode,
                                             @Reference     = @Reference,
                                             @CreatedBy     = @CreatedBy;
    end
  else
    begin
      /* Add to new Warehouse */
      exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                             @LPNId        = @LPNId,
                                             @LPNDetailId  = @LPNDetailId,
                                             @TransQty     = @TransQty,
                                             @Warehouse    = @NewWarehouse,
                                             @ToWarehouse  = @NewWarehouse,
                                             @ToLocationId = @ToLocationId,
                                             @ReasonCode   = @ReasonCode,
                                             @Reference    = @Reference,
                                             @CreatedBy    = @CreatedBy;

      /* Remove from old Warehouse */
      exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                             @LPNId         = @FromLPNId,
                                             @LPNDetailId   = @FromLPNDetailId,
                                             @LocationId    = @LocationId,
                                             @TransQty      = @TransQty,
                                             @QuantitySign  = -1,
                                             @Warehouse     = @OldWarehouse,
                                             @FromWarehouse = @OldWarehouse,
                                             @ReasonCode    = @ReasonCode,
                                             @Reference     = @Reference,
                                             @CreatedBy     = @CreatedBy;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_WarehouseTransfer */

Go
