/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/25  VS      pr_Exports_InsertRecords, pr_Exports_AddOrUpdate, pr_Exports_WarehouseTransferForMultipleLPNs:
  2021/05/01  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Bug fix - missing union (HA-2736)
  2021/04/14  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Send LPND exports when LPN has multiple SKUs (HA-2626)
  2021/04/12  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Export reference on LPNs (HA-2601)
  2020/12/31  TK      pr_Exports_WarehouseTransferForMultipleLPNs: Initial Revision (HA-1830)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_WarehouseTransferForMultipleLPNs') is not null
  drop Procedure pr_Exports_WarehouseTransferForMultipleLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_WarehouseTransferForMultipleLPNs: This proc does the same as
    pr_Exports_WarehouseTransfer but, the only change is it helps in sending exports
    for multiple LPNs in one shot

  The set of LPNs to be exported should be in loaded in hash table #LPNsToExport and
  that is of type Exports.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_WarehouseTransferForMultipleLPNs
  (@TransType          TTypeCode,
   @TransEntity        TEntity,
   @Operation          TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)

as
  declare @vReturnCode                    TInteger,
          @vMessageName                   TMessageName,
          @vMessage                       TMessage,

          @vReasonCode                    TControlValue,
          @vExportWHXferAsInvChange       TControlValue,
          @vControlCategory               TCategory;
begin /* pr_Exports_WarehouseTransferForMultipleLPNs */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* This proc works when the object #LPNsToExport is defined so, if that is not defined then return */
  if object_id('tempdb..#LPNsToExport') is null return;

  /* Set the control category */
  select @vControlCategory = 'Exports_' + coalesce(@Operation, '');

  /* Get Controls */
  select @vReasonCode              = dbo.fn_Controls_GetAsString(@vControlCategory, 'DefaultReasonCode', '130' /* Modify WH */, @BusinessUnit, @UserId),
         @vExportWHXferAsInvChange = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'WHXferAsInvCh', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Generate Required exports */
  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* If we need to generate Inventory change transactions on Warehouse change then generate both positive and negative transactions */
  if (@vExportWHXferAsInvChange = 'Y' /* Yes */)
    begin
      /* Generate the transactional changes for all LPNs */
      insert into #ExportRecords (TransType, TransEntity, TransQty, LPNId, SKUId, PalletId, LocationId, OrderId, Ownership, ReasonCode, Reference,
                                  LoadId, ShipmentId, ShipToId, ShipVia,
                                  Lot, InventoryClass1, InventoryClass2, InventoryClass3, Warehouse, FromWarehouse, ToWarehouse, CreatedBy)
        /* Generate negative InvCh transactions for the Old Warehouse */
        select 'InvCh', 'LPND', -1 * LD.Quantity, LD.LPNId, LD.SKUId, L.PalletId, LU.LocationId, LU.OrderId, L.Ownership, @vReasonCode, L.Reference,
               LU.LoadId, LU.ShipmentId, LU.ShipToId, LU.ShipVia,
               L.Lot, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, LU.FromWarehouse, LU.FromWarehouse, LU.ToWarehouse, @UserId
        from #LPNsToExport LU
          join LPNs L on (LU.LPNId = L.LPNId)
          join LPNDetails LD on (L.LPNId = LD.LPNId)
        union all
        /* Generate positive InvCh transactions for the New Warehouse */
        select 'InvCh', 'LPND', LD.Quantity, LD.LPNId, LD.SKUId, L.PalletId, LU.LocationId, LU.OrderId, L.Ownership, @vReasonCode, L.Reference,
               LU.LoadId, LU.ShipmentId, LU.ShipToId, LU.ShipVia,
               L.Lot, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, LU.ToWarehouse, LU.FromWarehouse, LU.ToWarehouse, @UserId
        from #LPNsToExport LU
          join LPNs L on (LU.LPNId = L.LPNId)
          join LPNDetails LD on (L.LPNId = LD.LPNId);

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'InvCh', null /* TransEntity */, @BusinessUnit;
    end
  else
    begin
      /* Generate the Warehouse transfer exports */
      insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, PalletId, LocationId, OrderId, Ownership, ReasonCode, Reference,
                                  LoadId, ShipmentId, Lot, InventoryClass1, InventoryClass2, InventoryClass3, Warehouse, FromWarehouse, ToWarehouse, CreatedBy)
        select 'WHXfer', LD.Quantity, LD.LPNId, LD.SKUId, L.PalletId, L.LocationId, LU.OrderId, L.Ownership, @vReasonCode, L.Reference,
               LU.LoadId, LU.ShipmentId, L.Lot, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, L.DestWarehouse, LU.FromWarehouse, LU.ToWarehouse, @UserId
        from #LPNsToExport LU
          join LPNs L on (LU.LPNId = L.LPNId)
          join LPNDetails LD on (L.LPNId = LD.LPNId);

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'WHXfer', null /* TransEntity */, @BusinessUnit;
    end

ErrorHandler:
   exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_WarehouseTransferForMultipleLPNs */

Go
