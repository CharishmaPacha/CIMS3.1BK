/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/08  PKD     pr_Imports_ASNs_AddOrUpdateReceipts: Dropped DateExpected (JLFL-146)
                      pr_Imports_ASNLPNHeaders, pr_Imports_ASNs_AddOrUpdateReceipts: Corrections migrated from CID (JL-93)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNs_AddOrUpdateReceipts') is not null
  drop Procedure pr_Imports_ASNs_AddOrUpdateReceipts;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNs_AddOrUpdateReceipts:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNs_AddOrUpdateReceipts
  (@ASNLPNDetailsToImport TASNLPNImportType READONLY)
as
  declare @vReturnCode       TInteger,
          @vRecordId         TRecordId,
          @vBusinessUnit     TBusinessUnit,

          @vReceiptId        TRecordId,
          @vReceiptNumber    TReceiptNumber,
          @vReceiptDetailId  TRecordId,
          @vReceiptLine      TReceiptLine,
          @vTReceiptLine     TReceiptLine,

          @vSKU              TSKU,
          @vSKUId            TRecordId,
          @vQuantity         TQuantity,
          @vInnerPacks       TInnerPacks,

          @vAddReceipts      TControlValue;
begin
  SET NOCOUNT ON;

  set @vRecordId = 0;

  select top 1 @vBusinessUnit = BusinessUnit from @ASNLPNDetailsToImport;

  select @vAddReceipts  = dbo.fn_Controls_GetAsString('IMPORT_ASNLD', 'AddReceipts', 'N' /* Default: No*/, @vBusinessUnit, '' /* UserId */);

  if (@vAddReceipts = 'N')
    return;

  while (exists (select * from @ASNLPNDetailsToImport where RecordId > @vRecordId))
    begin
      select @vRecordId     = RecordId,
             @vReceiptNumber = ReceiptNumber,
             @vSKU           = SKU,
             @vQuantity      = Quantity,
             @vInnerPacks    = InnerPacks
      from @ASNLPNDetailsToImport
      where (RecordId > @vRecordId);

      /* Get the  Receipt Id here  */
      select @vReceiptId = ReceiptId
      from ReceiptHeaders
      where (ReceiptNumber = @vReceiptNumber) and
            (BusinessUnit  = @vBusinessUnit );

     if (coalesce(@vReceiptNumber, '') <> '')
       begin
         if (coalesce(@vReceiptId,0) = 0)
           begin
             /* Insert receipt headers into receipts */
             exec pr_ReceiptHeaders_AddOrUpdate @vReceiptNumber, 'N' /* Status */ ,
                                             null /* VendorId */, @vBusinessUnit /* Ownership */, null /* DateOrdered */,
                                             null /* DateExpected */ , null, null, null, null, null, /* UDF1 to UDF5 */
                                             @vBusinessUnit,  @vReceiptId output, null, null, null, null;
           end
         else
           begin
             /* get receipt detailid here */
             select @vReceiptDetailId = ReceiptDetailId
             from ReceiptDetails
             where (Receiptid   = @vReceiptId) and
                   (SKUId = @vSKUId);
           end

         /* Insert receipt Details */
         exec pr_ReceiptDetails_AddOrUpdate @vReceiptId, @vReceiptLine, null /* Coo */ ,
                                            @vSKU /* SKU */, 0 /* QtyOrdered */, @vQuantity /* QtyReceived */,
                                            1 /* LPNsReceived */ , 0,/* UnitCost */ null, null, null, null, null, /* UDF1 to UDF5 */
                                            @vBusinessUnit, @vReceiptDetailId output, null, null, null, null;

         /* Update Receipt Detail counts here */
         exec pr_ReceiptDetails_UpdateCount @vReceiptId, @vReceiptDetailId, '+', @vQuantity, 1, /* LPNs received */
                                            null /* Update IntransitOption */, null /* QtyIntransit */, null /* LPNsIntransit */;
       end
    end /* End while */
end /* pr_Imports_ASNs_AddOrUpdateReceipts */

Go
