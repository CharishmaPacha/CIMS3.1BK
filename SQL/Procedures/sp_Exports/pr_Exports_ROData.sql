/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/01/08  DK      pr_Exports_ROData: Modifed to send ReasonCode (FB-596).
  2015/10/12  VM      pr_Exports_ROData: Do not need to fetch Ownership from RD as we are getting it from RH (FB-438)
  2015/09/30  DK      pr_Exports_ROData: Update OrderId as well on Exports (FB-416)
  2015/09/29  OK      pr_Exports_ROData: Added the procedure to Export Receipts and Receipt Details(FB-388).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_ROData') is not null
  drop Procedure pr_Exports_ROData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_ROData:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_ROData
  (@TransType        TTypeCode,
   @ReceiptsToExport TEntityKeysTable ReadOnly,
   @ReceiptId        TRecordId  = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,

   @RecordId         TRecordId = null output,
   @TransDateTime    TDateTime = null output,
   @CreatedDate      TDateTime = null output,
   @ModifiedDate     TDateTime = null output,
   @CreatedBy        TUserId   = null output,
   @ModifiedBy       TUserId   = null output)
as
  declare @ReturnCode             TInteger,
          @vRecordId              TRecordId,
          @vDetailRecordId        TRecordId,
          @MessageName            TMessageName,
          @Message                TDescription,

          @vReceiptId             TRecordId,
          @vReceiptDetailId       TRecordId,
          @vReceipt               TPallet,
          @vOrderId               TRecordId,
          @vPickTicket            TPickTicket,
          @vQuantity              TQuantity,
          @vReference             TReference,
          @vControlCategory       TCategory,


          @TransEntity            TEntity    = null,
          @vTransQty              TQuantity  = null,
          @vExportReceiptDetails  TControlValue,
          @vExportReceiptHeaders  TControlValue,
          @vReasonCode            TReasonCode,
          @vOwnership             TOwnership,
          @vWarehouse             TWarehouse,
          @vSKUId                 TRecordId;

  /* Temp table to hold all the Pallets to be updated */
  declare @ttReceipts TEntityKeysTable;

  declare @ttReceiptDetailsToExport table (RecordId         TRecordId identity (1,1),
                                           ReceiptId        TRecordId,
                                           ReceiptDetailId  TRecordId,
                                           SKUId            TRecordId,
                                           OrderedQuantity  TQuantity,
                                           ReasonCode       TReasonCode,
                                           Warehouse        TWarehouse,
                                           Ownership        TOwnership)

begin
  SET NOCOUNT ON;

  select @ReturnCode       = 0,
         @vRecordId        = 0,
         @vDetailRecordId  = 0,
         @MessageName      = null,
         @CreatedBy        = @UserId,
         @vControlCategory = 'Export.' + @TransType;

  /* If the given TransType is not active then do nothing and exit.
     Not all clients or installs use or are interested in all transaction types */
  if not exists (select * from vwEntityTypes
                 where ((TypeCode = @TransType) and
                        (Entity   = 'Transaction')))
    goto Exithandler;

  /* Get the control value to determine if we want to export Order Details also or not */
  select @vExportReceiptDetails = dbo.fn_Controls_GetAsString(@vControlCategory, 'ReceiptDetails', 'Y' /* yes */, @BusinessUnit, @UserId),
         @vExportReceiptHeaders = dbo.fn_Controls_GetAsString(@vControlCategory, 'ReceiptHeaders', 'Y' /* yes */, @BusinessUnit, @UserId);

  /* insert Receipts into the temp table */
  if (@ReceiptId is not null)
    insert into @ttReceipts(EntityId) select @ReceiptId
  else
    insert into @ttReceipts(EntityId)
      select EntityId
      from @ReceiptsToExport;

  while (exists (select * from @ttReceipts where RecordId > @vRecordId))
    begin
      /* Get the next one here in the loop */
      select top 1 @vRecordId  = RecordId,
                   @vReceiptId = EntityId
      from @ttReceipts
      where (RecordId > @vRecordId);

      /* get ReceiptDetails here */
      select  @vPickTicket= PickTicket,
              @vOwnership = Ownership,
              @vWarehouse = Warehouse
      from ReceiptHeaders
      where (ReceiptId = @vReceiptId);

      /* get OrderDetails here */
      select  @vOrderId = OrderId
      from OrderHeaders
      where (PickTicket = @vPickTicket);

      if (@TransType in ('Return'))
        begin
          if (@vExportReceiptDetails = 'Y' /* Yes */)
            begin
              /* Get all Receipt details .. */
              insert into @ttReceiptDetailsToExport (ReceiptDetailId, SKUId, OrderedQuantity, ReasonCode, Warehouse, Ownership)
                select ReceiptDetailId, SKUId, QtyOrdered, ReasonCode, @vWarehouse, Ownership
                from ReceiptDetails
                where (ReceiptId = @vReceiptId);

              /* Export Receipt Details */
              while exists (select * from @ttReceiptDetailsToExport where RecordId > @vDetailRecordId)
                begin
                  select top 1  @vDetailRecordId  = RecordId,
                                @vReceiptDetailId = ReceiptDetailId,
                                @vSKUId           = SKUId,
                                @vTransQty        = OrderedQuantity,
                                @vReasonCode      = ReasonCode,
                                @vWarehouse       = Warehouse
                                --@vOwnership       = Ownership
                  from @ttReceiptDetailsToExport
                  where (RecordId > @vDetailRecordId);

                  /* Post the Receipt Details transaction */
                  exec @ReturnCode = pr_Exports_AddOrUpdate  @TransType, 'RD' /* ReceiptDetail */, @vTransQty, @BusinessUnit,
                                                             Default /* Status */,
                                                             @ReceiptId  = @vReceiptId,
                                                             @SKUId      = @vSKUId,
                                                             @OrderId    = @vOrderId,
                                                             @ReasonCode = @vReasonCode,
                                                             @Warehouse  = @vWarehouse,
                                                             @Ownership  = @vOwnership;
                end
            end

            /* Now go for Receipt Headers */
            if (@vExportReceiptHeaders = 'Y' /* Yes */)
              begin
                /* Post the Receipt header transaction */
                exec @ReturnCode = pr_Exports_AddOrUpdate  @TransType, 'RH' /* ReceiptHeader */, null, @BusinessUnit,
                                                           @ReceiptId   = @vReceiptId,
                                                           @OrderId     = @vOrderId,
                                                           @Ownership   = @vOwnership,
                                                           @Warehouse   = @vWarehouse;
              end /* Export Receipt Headers = Y */
        end /* TransType = RecvReturn */
    end /* More receipts to process */

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_ROData */

Go
