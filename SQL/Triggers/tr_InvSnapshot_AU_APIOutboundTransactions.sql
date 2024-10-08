/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  if object_id('dbo.tr_InvSnapshot_AU_APIOutboundTransactions') is null
  exec('Create Trigger tr_InvSnapshot_AU_APIOutboundTransactions on InvSnapshot After Update as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('tr_InvSnapshot_AU_APIOutboundTransactions') is not null
  drop Trigger tr_InvSnapshot_AU_APIOutboundTransactions;
Go
/*------------------------------------------------------------------------------
  tr_InvSnapshot_AU_APIOutboundTransactions:
    trigger will insert invsnapshot prv and current qty data into hastable and process it
------------------------------------------------------------------------------*/
Create Trigger tr_InvSnapshot_AU_APIOutboundTransactions on InvSnapshot After Update
as
begin

  /* insert data into hash table */
  select INS.RecordId SnapshotRecordid, INS.SnapshotId, INS.SKUId, INS.SKU,
         INS.InventoryClass1, INS.InventoryClass2, INS.InventoryClass3, INS.InventoryKey,
         INS.Warehouse,  INS.BusinessUnit, INS.SourceSystem, INS.ModifiedBy,
         DEL.AvailableQty    OldAvailableQty,    INS.AvailableQty    NewAvailableQty,
         DEL.ReservedQty     OldReservedQty,     INS.ReservedQty     NewReservedQty,
         DEL.ReceivedQty     OldReceivedQty,     INS.ReceivedQty     NewReceivedQty,
         DEL.PutawayQty      OldPutawayQty,      INS.PutawayQty      NewPutawayQty,
         DEL.AdjustedQty     OldAdjustedQty,     INS.AdjustedQty     NewAdjustedQty,
         DEL.ShippedQty      OldShippedQty,      INS.ShippedQty      NewShippedQty,
         DEL.ToShipQty       OldToShipQty,       INS.ToShipQty       NewToShipQty,
         DEL.OnhandQty       OldOnhandQty,       INS.OnhandQty       NewOnhandQty,
         DEL.AvailableToSell OldAvailableToSell, INS.AvailableToSell NewAvailableToSell
  into #InvSnapshotsModified
  from Inserted INS
    join Deleted DEL on (INS.RecordId = DEL.RecordId)
  where (INS.Archived = 'N') and
        ((DEL.OnhandQty       <> INS.OnhandQty) or
         (DEL.AvailableToSell <> INS.AvailableToSell) or
         (DEL.AvailableQty    <> INS.AvailableQty));

  /* Process #InvSnapshotsModified data */
  exec pr_Inventory_InvSnapshot_ExportChanges;

end /* tr_InvSnapshot_AU_APIOutboundTransactions */

Go

/* By default we do not use this trigger */
alter table InvSnapshot disable trigger tr_InvSnapshot_AU_APIOutboundTransactions;

Go

