/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  SV      pr_Receipts_GenerateRMA: Changed the ReceiptType from RMA to R (OB2-1794)
  2021/05/05  SV      pr_Receipts_GenerateRMA: Code to manage the Exports.Status on RMA creation (OB2-1791)
  2021/04/19  SV      pr_Receipts_GenerateRMA: Changes to use receipts imports procedure rather than having a new procedure (OB2-1777)
  2021/03/31  SV      pr_Receipts_GenerateRMA: Initial Version (OB2-1754)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_GenerateRMA') is not null
  drop Procedure pr_Receipts_GenerateRMA;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_GenerateRMA:
    This procedure is to create RMA (ReceiptHeader and its Details).
    For RH creation, we use I/P parameters.
    For RD creation, we use #ScannedDetails which generally filled with data in
      pr_AMF_Returns_ConfirmReceiveRMA.

Imp Note: Currently, we use pr_Imports_ReceiptHeaders and pr_Imports_ReceiptDetails,
    whose code is from OB(V2) but not CIMS V3
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_GenerateRMA
 (@Ownership     TOwnership,
  @Warehouse     TWarehouse,
  @BusinessUnit  TBusinessUnit,
  @UserId        TUserId,
  @ReceiptId     TRecordId      = null  output,
  @ReceiptNumber TReceiptNumber = null output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @vRecordId         TRecordId,
          @vReceiptId        TRecordId,
          @vReceiptNumber    TReceiptNumber,
          @vSKUId            TRecordId,
          @vSKU              TSKU,
          @vQuantity         TQuantity,
          @vReasonCode       TReasonCode,
          @vDisposition      TMessageName;

  declare @ttReceiptHeadersImport  TReceiptHeaderImportType,
          @ttReceiptDetailsImport  TReceiptDetailImportType;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @vRecordId   = 0,
         @vReceiptId  = 0,
         @MessageName = null;

  if object_id('tempdb..#ReceiptHeadersImport') is null select * into #ReceiptHeadersImport from @ttReceiptHeadersImport;
  if object_id('tempdb..#ReceiptDetailsImport') is null select * into #ReceiptDetailsImport from @ttReceiptDetailsImport;

  set Identity_Insert #ReceiptHeadersImport ON;

  exec pr_Controls_GetNextSeqNoStr 'Receipts_RMA', 1, @UserId, @BusinessUnit, @vReceiptNumber output;

  /* Create RMA Header */
  insert into #ReceiptHeadersImport(RecordAction, ReceiptNumber, ReceiptType, Status, Ownership, Warehouse,
                                    BusinessUnit, CreatedBy, RecordId)
    select 'I' /* Insert */, @vReceiptNumber, 'R', 'E' /* Status */, @Ownership, @Warehouse,
           @BusinessUnit, @UserId, row_number() over (order by @vReceiptNumber);

  /* Import Receipt Headers */
  exec pr_Imports_ReceiptHeaders @xmlData = null, @Action = 'I', @ReceiptNumber = @vReceiptNumber, @BusinessUnit = @BusinessUnit;

  /* Get ReceiptId of newly created RMA */
  select @vReceiptId = ReceiptId
  from ReceiptHeaders
  where (ReceiptNumber = @vReceiptNumber) and (BusinessUnit = @BusinessUnit);

  /* Summarize all the returned items by SKU to create RMA Details */
  insert into #ReceiptDetailsImport(RecordAction, ReceiptId, SKUId, QtyOrdered, QtyReceived,
                                    Ownership, RD_UDF9, RD_UDF10, BusinessUnit, CreatedBy)
    select 'I' /* Insert */, @vReceiptId, SD.SKUId, sum(SD.Quantity), sum(SD.Quantity),
           @Ownership, SD.ReasonCode, SD.Disposition, @BusinessUnit, @UserId
    from #ScannedDetails SD
    group by SD.SKUId, SD.ReasonCode, SD.Disposition;

  /* Import Receipt Details */
  exec pr_Imports_ReceiptDetails @xmlData = null, @Action = 'I', @ReceiptNumber = @vReceiptNumber, @BusinessUnit = @BusinessUnit;

  /* Export the RMA Hdr and Dtls create */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Generate the RMA header record so that Host can create RMA on their system */
  insert into #ExportRecords (TransType, TransEntity, TransQty, ReceiptId, Ownership, Warehouse, SourceSystem, CreatedBy)
    select 'RMA', 'RH', NumUnits, ReceiptId, Ownership, Warehouse, 'CIMS', @UserId
    from ReceiptHeaders RH
    where (RH.ReceiptId = @vReceiptId);

  /* Generate the RMA detail records so that Host can create RMA details on their system */
  insert into #ExportRecords (TransType, TransEntity, TransQty, ReceiptId, ReceiptDetailId, SKUId,
                              Lot, InventoryClass1, InventoryClass2, InventoryClass3, UDF9, UDF10,
                              Ownership, Warehouse, SourceSystem, CreatedBy)
    select 'RMA', 'RD', RD.QtyReceived, RD.ReceiptId, RD.ReceiptDetailId, RD.SKUId,
            '' /* Lot */, '', '', '', RD.UDF9, RD.UDF10,
            RH.Ownership, RH.Warehouse, 'CIMS', @UserId
    from ReceiptHeaders RH join ReceiptDetails RD on (RH.ReceiptId = RD.ReceiptId)
    where (RH.ReceiptId = @vReceiptId);

  /* The intention for below call is we need to ignore the RMA transactions for OB */
  exec pr_RuleSets_ExecuteAllRules 'Export_PreInsertProcess', null, @BusinessUnit;

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'RMA', null /* TransEntity */, @BusinessUnit;

  /* Assigning the output parameter */
  select @ReceiptId     = @vReceiptId,
         @ReceiptNumber = @vReceiptNumber;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Receipts_GenerateRMA */

Go
