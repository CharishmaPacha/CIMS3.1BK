/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/30  VS      pr_Receivers_Close, pr_Receivers_SendConsolidatedExports: Do not send exports if already exported for the Receiver (HA-2935)
  2020/07/28  RT      pr_Receivers_SendConsolidatedExports: Changed the type of SendConsolidatedExports and Changes to send Inv Trans for Transfer Order (HA-111)
  2020/05/12  MS      pr_Receivers_SendConsolidatedExports: Changes to use pr_PrepareHashTable for #ExportRecords (HA-350)
  2020/04/29  MS      pr_Receivers_SendConsolidatedExports: Changes to send Consoidated Exports (HA-323)
  2020/04/27  PK/SPP  pr_Receivers_SendConsolidatedExports: joined LPNs with ReceiptId but if we have multiple,LPNs received against multiple different SKUs
  2020/04/23  TK      pr_Receivers_SendConsolidatedExports: Changes to exclude sending exports when inventory is received to picklane location (HA-222)
  2019/10/01  MS      pr_Receivers_SendConsolidatedExports: Changes to get the sourcecsystem and send to caller (CID-1071)
  2018/02/25  OK      pr_Receivers_SendConsolidatedExports:changes to use ReceivedCounts table instead of other entity tables (CID-116)
  2016/04/05  NB      pr_Receivers_SendConsolidatedExports: Fix - Initialize loop variable to 0, for loop to process(NBD-89)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_SendConsolidatedExports') is not null
  drop Procedure pr_Receivers_SendConsolidatedExports;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_SendConsolidatedExports: Instead of getting incremental Recv
    transactions as Received LPNs are putaway, some ERP systems prefer to get
    the consoldiated update of all receipts when the Receiver is finally closed.
  This procedure, processes all the Receivers/Receipt Orders on a Receiver and
  sends exports accordingly with summary by Receiver - ReceiptDetail and total
  qty received against it.
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_SendConsolidatedExports
  (@ttReceipts    TEntityKeysTable readonly,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReceiptId                  TRecordId,
          @vRecordId                   TRecordId,
          @vReceiverNumber             TReceiverNumber,
          @vReceiptDetailId            TRecordId,

          @vTransType                  TTypeCode,
          @vTransQty                   TQuantity,
          @vWarehouse                  TWarehouse,
          @vOwnership                  TOwnership,
          @vSourceSystem               TName,

          @vReturnCode                 TInteger;

begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vRecordId = 0;

  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Summarize the data from ReceivedCounts table for the given Receiver-Receipt Orders */
  insert into #ExportRecords (TransType, ReceiverId, ReceiverNumber, ReceiptId, ReceiptDetailId, SKUId, TransQty, Warehouse, Ownership,
                              Lot, InventoryClass1, InventoryClass2, InventoryClass3)
    select 'Recv', RC.ReceiverId, RC.ReceiverNumber, RC.ReceiptId, RC.ReceiptDetailId, RC.SKUId, sum(RC.Quantity), RC.Warehouse, RC.Ownership,
           L.Lot, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
    from @ttReceipts ttR
      join ReceivedCounts RC on (RC.ReceiptId = ttR.EntityId) and (RC.ReceiverNumber = ttR.EntityKey) and (RC.BusinessUnit = @BusinessUnit)
      join LPNs            L on (L.LPNId = RC.LPNId)
      left join Exports    E on (ttR.EntityId = E.ReceiptId) and (ttR.EntityKey = E.ReceiverNumber) and (E.TransType = 'Recv') and (E.BusinessUnit = @BusinessUnit)
    where (RC.Status = 'A' /* Active */) and
          (L.LPNType <> 'L'/* Logical */) and (E.RecordId is null)
    group by RC.ReceiverId, RC.ReceiverNumber, RC.ReceiptId, RC.ReceiptDetailId, RC.SKUId, RC.Warehouse, RC.Ownership,
             L.Lot, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3;

  /* get the sourcesystem and TransType from RH to send to exports */
  update ER
  set SourceSystem = RH.SourceSystem
  from #ExportRecords ER join ReceiptHeaders RH on (RH.ReceiptId = ER.ReceiptId);

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'Recv' /* TransType */, 'RV' /* TransEntity - Receiver */, @BusinessUnit;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_SendConsolidatedExports */

Go
