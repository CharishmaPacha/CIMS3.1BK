/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/29  PK      pr_Inventory_BulkTransfer: Added OrderDetailId to send the order details in exports to host (HA-1723)
  2020/11/13  AY/TK   pr_Inventory_BulkTransfer: Bug fix with missing inventory class (HA-1672)
  2020/06/30  TK      pr_Inventory_BulkTransfer: Changes to insert LPN Details directly instead of calling proc to do that (HA-830)
  2020/06/23  TK      pr_Inventory_BulkTransfer: Initial Revision (HA-833)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_BulkTransfer') is not null
  drop Procedure pr_Inventory_BulkTransfer;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_BulkTransfer: This procedure is mainly to transfer inventory
    from one Picklane to another. The picklanes may be in the same WH or not and
    during the transfer, the SKU and/or InventoryClasses may be changed as well.

  Input for this proc is #InventoryTransferInfo table and does the following
    1. If the table has new location specified then system will deduct the inventory
       from old location and add inventory to the new location
    2. If the table has any of the following values the system deducts the inventory
       with old value and adds inventory with new values
       NewSKUId, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3

  Assumptions:
    a. LPNId, LPNDetailId, SKUId, Qty will be specified always (these are the From LPN Details)
    b. Qty can be +ve or -ve.
    c. NewLocationId is given and it matches with the NewWarehouse, NewOwnership and New InventoryClasses
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_BulkTransfer
  (@ReasonCode       TReasonCode = null,
   @Operation        TOperation  = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vReasonCode        TReasonCode;

  declare @ttLPNs                TLPNDetails,
          @ttAuditTrailInfo      TAuditTrailInfo,
          @ttLPNsToRecalc        TRecountKeysTable,
          @ttLPNsToDeleted       TRecountKeysTable,
          @ttLocationsToRecalc   TRecountKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vReasonCode  = coalesce(@ReasonCode, 'CNV');

  /* Create temp tables */
  select * into #LPNs from @ttLPNs;
  select * into #CreateLPNDetails from @ttLPNs;

  /******** Primary Validations ***********/

  /* Make sure the from LPNs have the inventory to deduct */

  /* If there is any change in the Location then deduct the inventory in old location and
     increment the inventory in new location */
  if exists (select *
             from #InventoryTransferInfo
             where (LocationId <> coalesce(NewLocationId, LocationId) or
                   (LPNId <> coalesce(NewLPNId, LPNId))))
    begin
      /******** Determine the Destination Logical LPNs and LPN Details ***********/

      /* When New Location is specified, then get the NewLPNId and NewLPNDetailId of that Picklane */
      update ITI
      set NewLPNId       = LD.LPNId,
          NewLPN         = L.LPN,
          NewLPNDetailId = LD.LPNDetailId
      from #InventoryTransferInfo ITI
        join LPNs L on (L.SKUId           = coalesce(ITI.NewSKUId, ITI.SKUId)) and
                       (L.LocationId      = ITI.NewLocationId) and
                       (L.Ownership       = ITI.Ownership) and
                       (L.InventoryClass1 = coalesce(ITI.NewInventoryClass1, ITI.InventoryClass1)) and
                       (L.InventoryClass2 = coalesce(ITI.NewInventoryClass2, ITI.InventoryClass1)) and
                       (L.InventoryClass3 = coalesce(ITI.NewInventoryClass3, ITI.InventoryClass1))
        left outer join LPNDetails LD on (L.LPNId         = LD.LPNId) and
                                         (LD.OnhandStatus = 'A' /* Available */)
      where (ITI.NewLocationId is not null);

      /******** Create the Destination Logical LPNs if needed ***********/

      /* Generate the LPNs for the items that doesn't have one in the Location */
      if exists (select * from #InventoryTransferInfo where NewLPNId is null and NewLocationId is not null)
        begin
          insert into #LPNs (LPN, LPNType, LPNStatus, OnhandStatus, SKUId, SKU, LocationId, Location,
                             InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse, InputRecordId)
            select NewLocation, 'L'/* Logical */, 'P' /* Putaway */, 'A' /* Available */, coalesce(NewSKUId, SKUId), coalesce(NewSKU, SKU), NewLocationId, NewLocation,
                   coalesce(NewInventoryClass1, InventoryClass1), coalesce(NewInventoryClass2, InventoryClass2), coalesce(NewInventoryClass3, InventoryClass3),
                   Ownership, coalesce(NewWarehouse, Warehouse), RecordId
            from #InventoryTransferInfo
            where (NewLPNId is null) and (NewLocationId is not null);

          /* Invoke procedure to insert LPNs  */
          exec pr_LPNs_Insert @BusinessUnit, @UserId;

          /* Update New LPN info on temp table */
          update ITI
          set NewLPNId = L.LPNId,
              NewLPN   = L.LPN
          from #InventoryTransferInfo ITI
            join #LPNs L on (ITI.RecordId = L.InputRecordId);

          /* Capture LPNs created to recalculate */
          insert into @ttLPNsToRecalc (EntityId) select LPNId from #LPNs;
        end

      /******** Insert or Update the Destination LPN Details ***********/

      /* Increment the quantity on LPN Detail on destination picklane LPN if exists */
      update LD
      set Quantity += ITI.Quantity
      output Inserted.LPNId into @ttLPNsToRecalc (EntityId)
      from LPNDetails LD
        join #InventoryTransferInfo ITI on (LD.LPNDetailId = ITI.NewLPNDetailId);

      /* Add Details for the picklanes LPNs whose LPNDetailId is null */
      insert into LPNDetails (LPNId, SKUId, OnhandStatus, Quantity, Weight, Volume, BusinessUnit, CreatedBy)
        select NewLPNId, coalesce(NewSKUId, ITI.SKUId), 'A'/* Available */, Quantity, coalesce(Quantity * S.UnitWeight, 0.0),
               coalesce(Quantity * S.UnitVolume, 0.0), @BusinessUnit, @UserId
        from #InventoryTransferInfo ITI
          join SKUs S on (coalesce(ITI.NewSKUId, ITI.SKUId) = S.SKUId)
        where (NewLPNId is not null) and
              (NewLPNDetailId is null);

      /******** Deduct from Source LPN Details ***********/

      /* Deduct inventory from source LPN/Picklane */
      ;with QtyToDeduct as
      (
        select LPNDetailId, sum(Quantity) as Quantity
        from #InventoryTransferInfo
        group by LPNDetailId
      )
      update LD
      set Quantity -= QTD.Quantity
      output Inserted.LPNId into @ttLPNsToRecalc (EntityId)
      from LPNDetails LD
        join QtyToDeduct QTD on (LD.LPNDetailId = QTD.LPNDetailId);

      /* Recalc all the source & destination LPNs to recalc */
      exec pr_LPNs_Recalculate @ttLPNsToRecalc, 'C' /* Counts Only */;

      /* Delete dynamic picklane LPNs & its Details if quantity on them goes to zero */
      delete L
      output deleted.LPNId into @ttLPNsToDeleted (EntityId)
      from @ttLPNsToRecalc ttL
        join LPNs L on (ttL.EntityId = L.LPNId)
        join Locations Loc on (L.LocationId = Loc.LocationId)
      where (L.Quantity = 0) and
            (Loc.LocationType = 'K' /* Picklane */) and
            (Loc.LocationSubType = 'D' /* Dynamic */);

      delete LD
      from LPNDetails LD
        join @ttLPNsToDeleted ttLD on (LD.LPNId = ttLD.EntityId);

      /* Get all the Locations to recalc */
      insert into @ttLocationsToRecalc (EntityId, EntityKey)
        select LocationId, Location from #InventoryTransferInfo where LocationId is not null
        union
        select NewLocationId, NewLocation from #InventoryTransferInfo where NewLocationId is not null;

      exec pr_Locations_Recalculate @ttLocationsToRecalc, '*' /* Recount */, @BusinessUnit;
    end

  /* if there is any change in SKU or InventoryClass then export InvCh transactions to host */
  if exists (select *
             from #InventoryTransferInfo
             where (SKUId <> coalesce(NewSKUId, SKUId)) or
                   ((InventoryClass1 <> coalesce(NewInventoryClass1, InventoryClass1)) or
                    (InventoryClass2 <> coalesce(NewInventoryClass2, InventoryClass2)) or
                    (InventoryClass3 <> coalesce(NewInventoryClass3, InventoryClass3))) or
                   (LocationId <> coalesce(NewLocationId, LocationId)))
    begin
      /* Build temp table with the Result set of the procedure */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the transactional changes for all LPNs */
      insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, PalletId, LocationId, OrderId, OrderDetailId, Ownership, ReasonCode,
                                  Lot, InventoryClass1, InventoryClass2, InventoryClass3, Warehouse, SourceSystem, CreatedBy)
        /* Generate negative InvCh transactions for the Old SKU or Inventory Class(es) */
        select 'InvCh', -1 * ITI.Quantity, ITI.LPNId, ITI.SKUId, ITI.PalletId, ITI.LocationId, ITI.OrderId, ITI.OrderDetailId, ITI.Ownership, @vReasonCode,
               ITI.Lot, ITI.InventoryClass1, ITI.InventoryClass2, ITI.InventoryClass3, ITI.Warehouse, ITI.SourceSystem, @UserId
        from #InventoryTransferInfo ITI
        /* Generate positive InvCh transactions for the New SKU or Inventory Class(es) */
        union
        select 'InvCh', ITI.Quantity, coalesce(ITI.NewLPNId, ITI.LPNId), coalesce(ITI.NewSKUId, ITI.SKUId), ITI.PalletId, coalesce(ITI.NewLocationId, ITI.LocationId),
               ITI.OrderId, ITI.OrderDetailId, ITI.Ownership, @vReasonCode, ITI.Lot, coalesce(ITI.NewInventoryClass1, ITI.InventoryClass1), coalesce(ITI.NewInventoryClass2, ITI.InventoryClass2),
               coalesce(ITI.NewInventoryClass3, ITI.InventoryClass3), coalesce(ITI.NewWarehouse, ITI.Warehouse), ITI.SourceSystem, @UserId
        from #InventoryTransferInfo ITI;

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'InvCh', 'LPN' /* TransEntity - LPN */, @BusinessUnit;
    end

  /* Identify operation to log AT */
  if (@Operation = 'ReworkComplete')
    select @Operation = case when exists (select * from #InventoryTransferInfo where NewSKU is not null and NewInventoryClass1 is not null)
                               then 'ReworkCompleteSKU&ICChange'
                             when exists (select * from #InventoryTransferInfo where NewSKU is not null and NewInventoryClass1 is null)
                               then 'ReworkCompleteSKUChange'
                             when exists (select * from #InventoryTransferInfo where NewSKU is null and NewInventoryClass1 is not null)
                               then 'ReworkCompleteICChange'
                        end;

  /* Audit Log */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1, Comment)
    /* From LPN */
    select distinct 'LPN', LPNId, LPN, @Operation, @BusinessUnit, @UserId, RecordId,
                    dbo.fn_Messages_BuildDescription('AT_'+ @Operation +'_FromLPN', 'PickTicket', PickTicket, 'ToLPN', NewLPN, 'Quantity', Quantity, 'SKU', SKU, 'NewSKU', NewSKU, 'NewInventoryClass1', NewInventoryClass1)
    from #InventoryTransferInfo
    union
    /* To LPN */
    select distinct 'LPN', NewLPNId, NewLPN, @Operation, @BusinessUnit, @UserId, RecordId,
                    dbo.fn_Messages_BuildDescription('AT_'+ @Operation +'_ToLPN', 'PickTicket', PickTicket, 'FromLPN', LPN, 'Quantity', Quantity, 'SKU', SKU, 'NewSKU', NewSKU, 'NewInventoryClass1', NewInventoryClass1)
    from #InventoryTransferInfo
    union
    /* From Location */
    select distinct 'Location', LocationId, Location, @Operation, @BusinessUnit, @UserId, RecordId,
                    dbo.fn_Messages_BuildDescription('AT_'+ @Operation +'_FromLPN', 'PickTicket', PickTicket, 'ToLPN', NewLPN, 'Quantity', Quantity, 'SKU', SKU, 'NewSKU', NewSKU, 'NewInventoryClass1', NewInventoryClass1)
    from #InventoryTransferInfo
    union
    /* To Location */
    select distinct 'Location', NewLocationId, NewLocation, @Operation, @BusinessUnit, @UserId, RecordId,
                    dbo.fn_Messages_BuildDescription('AT_'+ @Operation +'_ToLPN', 'PickTicket', PickTicket, 'FromLPN', LPN, 'Quantity', Quantity, 'SKU', SKU, 'NewSKU', NewSKU, 'NewInventoryClass1', NewInventoryClass1)
    from #InventoryTransferInfo
    union
    /* Order */
    select distinct 'PickTicket', OrderId, PickTicket,  @Operation, @BusinessUnit, @UserId, RecordId,
                    dbo.fn_Messages_BuildDescription('AT_'+ @Operation +'_PickTicket', 'FromLPN', LPN, 'ToLPN', NewLPN, 'Quantity', Quantity, 'SKU', SKU, 'NewSKU', NewSKU, 'NewInventoryClass1', NewInventoryClass1)
    from #InventoryTransferInfo
    union
    /* Wave */
    select distinct 'PickBatch', WaveId, WaveNo, @Operation, @BusinessUnit, @UserId, RecordId,
                    dbo.fn_Messages_BuildDescription('AT_'+ @Operation +'_PickTicket', 'FromLPN', LPN, 'ToLPN', NewLPN, 'Quantity', Quantity, 'SKU', SKU, 'NewSKU', NewSKU, 'NewInventoryClass1', NewInventoryClass1)
    from #InventoryTransferInfo;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_BulkTransfer */

Go
