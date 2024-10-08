/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/29  PK      pr_OrderHeaders_CloseReworkLPNs: Mapped OrderDetailId to send OD.UDFs to host(HA-1723).
  2020/09/16  AJM     pr_OrderHeaders_CloseReworkLPNs: Made changes to display AT message appropriately (HA-598)
  2020/06/04  OK      pr_OrderHeaders_CloseReworkLPNs: CHanges to pass Source System (HA-815)
  2020/05/30  TK      pr_OrderHeaders_CloseReworkLPNs: Recalc Pallet Status (HA-623)
  2020/05/16  TK      pr_OrderHeaders_CloseReworkLPNs: Changes to log AT (HA-543)
  2020/05/13  MS      pr_OrderHeaders_CloseReworkLPNs: Use pr_PrepareHashTable for #ExportRecords (HA-350)
  2020/05/10  TK      pr_OrderHeaders_CloseReworkLPNs: Initial Revision (HA-475)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_CloseReworkLPNs') is not null
  drop Procedure pr_OrderHeaders_CloseReworkLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_CloseReworkLPNs marks all the LPNs that are picked for rework order to
    putaway status and generates exports if there is any change in SKU or InventoryClass(es)
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_CloseReworkLPNs
  (@OrderId          TRecordId,
   @Operation        TOperation  = null,
   @ReasonCode       TReasonCode = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vAuditActivity     TActivityType;

  declare @ttAuditTrailInfo   TAuditTrailInfo,
          @ttPalletsToRecalc  TRecountKeysTable;

  declare @ttLPNsInfo table (LPNId                TRecordId,
                             LPN                  TLPN,
                             LPNDetailId          TRecordId,

                             OrderId              TRecordId,
                             PickTicket           TPickTicket,
                             OrderDetailId        TRecordId,
                             SKUId                TRecordId,
                             SKU                   TSKU,
                             NewSKUId             TRecordId,
                             NewSKU               TSKU,
                             Quantity             TQuantity,

                             InventoryClass1      TInventoryClass,
                             NewInventoryClass1   TInventoryClass,
                             InventoryClass2      TInventoryClass,
                             NewInventoryClass2   TInventoryClass,
                             InventoryClass3      TInventoryClass,
                             NewInventoryClass3   TInventoryClass,
                             SourceSystem         TName,

                             RecordId             TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'ReworkOrder_CloseLPN';

  /* Get all the LPNs that needs to be closed */
  insert into @ttLPNsInfo (LPNId, LPN, LPNDetailId, OrderId, PickTicket, OrderDetailId, SKUId, SKU, Quantity,
                           NewSKUId, NewSKU, InventoryClass1, NewInventoryClass1, InventoryClass2, NewInventoryClass2,
                           InventoryClass3, NewInventoryClass3, SourceSystem)
    select L.LPNId, L.LPN, LD.LPNDetailId, L.OrderId, OH.PickTicket, LD.OrderDetailId, LD.SKUId, OD.SKU, LD.Quantity,
           nullif(OD.NewSKUId, ''), nullif(OD.NewSKU, ''), OD.InventoryClass1, nullif(OD.NewInventoryClass1, ''), OD.InventoryClass2, nullif(OD.NewInventoryClass2, ''),
           OD.InventoryClass3, nullif(OD.NewInventoryClass3, ''), OH.SourceSystem
    from LPNs L
      join LPNDetails LD on (L.LPNId = LD.LPNId)
      join OrderDetails OD on (LD.OrderDetailId = OD.OrderDetailId)
      join OrderHeaders OH on (OD.OrderId = OH.OrderId)
    where (OD.OrderId = @OrderId) and
          (L.Status = 'K'/* Picked */);

  /* Mark LPNs as Putaway, Update new SKU if there is any change in SKU */
  update L
  set Status          = 'P' /* Putaway */,
      OnhandStatus    = 'A' /* Available */,
      OrderId         = null,
      PickTicketNo    = null,
      SalesOrder      = null,
      PickBatchId     = null,
      PickBatchNo     = null,
      ReservedQty     = 0,
      SKUId           = coalesce(ttLI.NewSKUId, L.SKUId),
      InventoryClass1 = coalesce(ttLI.NewInventoryClass1, L.InventoryClass1),
      InventoryClass2 = coalesce(ttLI.NewInventoryClass2, L.InventoryClass2),
      InventoryClass3 = coalesce(ttLI.NewInventoryClass3, L.InventoryClass3),
      ReasonCode      = @ReasonCode,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  output Inserted.PalletId into @ttPalletsToRecalc (EntityId)
  from LPNs L
    join @ttLPNsInfo ttLI on (L.LPNId = ttLI.LPNId);

  /* Mark LPN Detail OnhandStatus as available, Update new SKU if there is any change in SKU */
  update LD
  set OnhandStatus  = 'A' /* Available */,
      OrderId       = null,
      OrderDetailId = null,
      ReservedQty   = 0,
      SKUId         = coalesce(ttLI.NewSKUId, LD.SKUId),
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  from LPNDetails LD
    join @ttLPNsInfo ttLI on (LD.LPNDetailId = ttLI.LPNDetailId);

  /* if there is any change in SKU or InventoryClass then export InvCh transactions to host */
  if exists (select *
             from @ttLPNsInfo
             where (SKUId <> coalesce(NewSKUId, SKUId)) or
                   ((InventoryClass1 <> coalesce(NewInventoryClass1, InventoryClass1)) or
                    (InventoryClass2 <> coalesce(NewInventoryClass2, InventoryClass2)) or
                    (InventoryClass3 <> coalesce(NewInventoryClass3, InventoryClass3))))
    begin
      /* Build temp table with the Result set of the procedure */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the transactional changes for all LPNs */
      insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, PalletId, LocationId, OrderId, OrderDetailId, Warehouse, Ownership, ReasonCode,
                                  Lot, InventoryClass1, InventoryClass2, InventoryClass3, SourceSystem)
        /* Generate negative InvCh transactions for the Old SKU or Inventory Class(es) */
        select 'InvCh', -1 * ttLI.Quantity, L.LPNId, ttLI.SKUId, L.PalletId, L.LocationId, ttLI.OrderId, ttLI.OrderDetailId, L.DestWarehouse, L.Ownership, @ReasonCode,
               L.Lot, ttLI.InventoryClass1, ttLI.InventoryClass2, ttLI.InventoryClass3, ttLI.SourceSystem
        from @ttLPNsInfo ttLI
          join LPNs L on ttLI.LPNId = L.LPNId and L.OnhandStatus = 'A'/* Available */
        /* Generate positive InvCh transactions for the New SKU or Inventory Class(es) */
        union
        select 'InvCh', ttLI.Quantity, L.LPNId, coalesce(ttLI.NewSKUId, ttLI.SKUId), L.PalletId, L.LocationId, ttLI.OrderId, ttLI.OrderDetailId, L.DestWarehouse, L.Ownership, @ReasonCode,
               L.Lot, coalesce(ttLI.NewInventoryClass1, ttLI.InventoryClass1), coalesce(ttLI.NewInventoryClass2, ttLI.InventoryClass2),
               coalesce(ttLI.NewInventoryClass3, ttLI.InventoryClass3), ttLI.SourceSystem
        from @ttLPNsInfo ttLI
          join LPNs L on ttLI.LPNId = L.LPNId and L.OnHandStatus = 'A'/* Available */

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'InvCh', 'LPN' /* TransEntity - LPN */, @BusinessUnit;
    end

   /* Recalc pallets */
   exec pr_Pallets_Recalculate @ttPalletsToRecalc, 'S'/* Status only */, @BusinessUnit, @UserId;

  /* Get the SKU for the AT */
  update LD
  set LD.SKU = S.SKU
  from @ttLPNsInfo LD join SKUs S on LD.SKUId = S.SKUId;

   /* Audit Log */
   insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
     /* LPN */
     select distinct 'LPN', LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build('AT_'+@vAuditActivity, Quantity, SKU, NewSKU, InventoryClass1, NewInventoryClass1) /* Comment */
     from @ttLPNsInfo
     union
     /* Order */
     select distinct 'PickTicket', OrderId, PickTicket, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build('AT_'+@vAuditActivity+'_PickTicket', Quantity, SKU, NewSKU, InventoryClass1, NewInventoryClass1) /* Comment */
     from  @ttLPNsInfo;

   /* Insert records into AT */
   exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_CloseReworkLPNs */

Go
