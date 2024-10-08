/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/05  NY      Addded pr_ReceiptHeaders_AfterROClose (XSC-537: Don not send ROClose for trasfers)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_AfterROClose') is not null
  drop Procedure pr_ReceiptHeaders_AfterROClose;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_AfterROClose:

ExportRODsOnClose: The options are

LPN:         We export one record for each LPN Received
LPN+RODZero: We export one record for each LPN Received and ROD for lines that are not received
ROD-Zero:    We export one record for each ROD, but only where there is received Qty i.e
                we exclude the lines where nothing has been received
ROD:         We export one for each ROD even if nothing has been received against the line.
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_AfterROClose
  (@ReceiptId       TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,

          @vRecordId           TRecordId,
          @vReceiptId          TRecordId,
          @vReceiptDetailId    TRecordId,
          @vReceiptType        TReceiptType,
          @vQuantity           TQuantity,
          @vWarehouse          TWarehouse,
          @vOwnership          TOwnership,
          @vSKUId              TRecordId,

          @vExportROHOnClose   TString,
          @vExportRODsOnClose  TString;

  declare @ttReceiptDetails Table
          (RecordId        TRecordId Identity(1,1),
           ReceiptId       TRecordId,
           ReceiptDetailId TRecordId,
           SKUID           TRecordId,
           Quantity        TQuantity);
begin
  SET NOCOUNT ON;

  /* Get ROH Info */
  select @vReceiptId   = ReceiptId,
         @vReceiptType = ReceiptType,
         @vWarehouse   = Warehouse,
         @vOwnership   = Ownership
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* Get Control vars for the type of RO in consideration */
  select @vExportROHOnClose  = dbo.fn_Controls_GetAsString('ExportROHOnClose', @vReceiptType, 'N',   @BusinessUnit, @UserId);
  select @vExportRODsOnClose = dbo.fn_Controls_GetAsString('ExportRODOnClose', @vReceiptType, 'LPN', @BusinessUnit, @UserId);

  /* If any RODs are to be exported, the process it */
  if (@vExportRODsOnClose like '%ROD%')
    begin
      insert into @ttReceiptDetails
        select RD.ReceiptId, RD.ReceiptDetailId, RD.SKUId, RD.QtyReceived
        from ReceiptDetails RD
        join ReceiptHeaders RH on (RD.ReceiptID = RH.ReceiptId)
      where (RD.ReceiptId = @ReceiptId) and
            ((@vExportRODsOnClose = 'ROD-Zero'    and QtyReceived > 0) or
             (@vExportRODsOnClose = 'LPN+RODZero' and QtyReceived = 0) or
             (@vExportRODsOnClose = 'ROD'));

      while (exists(select *
                    from @ttReceiptDetails))
        begin
           /* select the top 1 receipt detail */
          select top 1 @vRecordId        = RecordId,
                       @vReceiptDetailId = ReceiptDetailId,
                       @vSKUId           = SKUId,
                       @vQuantity        = Quantity
          from @ttReceiptDetails;

          exec pr_Exports_AddOrUpdate @TransType       = 'Recv',
                                      @TransEntity     = 'RD',
                                      @TransQty        = @vQuantity,
                                      @SKUId           = @vSKUId,
                                      @BusinessUnit    = @BusinessUnit,
                                      @ReceiptId       = @vReceiptId,
                                      @ReceiptDetailId = @vReceiptDetailId,
                                      @Warehouse       = @vWarehouse,
                                      @Ownership       = @vOwnership,
                                      @CreatedBy       = @UserId;

         delete from @ttReceiptDetails
         where (recordid = @vRecordId);
        end
    end

  /* Export the log to host system if the Receipt is reopened */
  if (@vExportROHOnClose = 'Y')
    exec pr_Exports_AddOrUpdate @TransType    = 'ROClose',
                                @TransEntity  = 'RH',
                                @TransQty     = 0,
                                @BusinessUnit = @BusinessUnit,
                                @ReceiptId    = @vReceiptId,
                                @Warehouse    = @vWarehouse,
                                @Ownership    = @vOwnership;

end /* pr_ReceiptHeaders_AfterROClose */

Go
