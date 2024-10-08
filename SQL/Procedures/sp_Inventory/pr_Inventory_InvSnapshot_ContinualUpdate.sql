/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/05/26  VM      pr_Inventory_InvSnapshot_ContinualUpdate: Do not need to use date while retreiving exports (JLCA-840)
  2023/02/08  MS      pr_Inventory_InvSnapshot_ContinualUpdate: Made changes to insert new inventory into snapshot (BK-1014)
  2023/01/25  VS      pr_Inventory_InvSnapshot_ContinualUpdate, pr_Inventory_InvSnapshot_Create: Update the ReserveQty and added InitialOnhandQty (JLFL-98)
                      pr_Inventory_InvSnapshot_ContinualUpdate: Bug fix to update controlvalue based on condition
  2022/02/26  VS/AY   pr_Inventory_InvSnapshot_ContinualUpdate: Initial version (JLFL-98)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_InvSnapshot_ContinualUpdate') is not null
  drop Procedure pr_Inventory_InvSnapshot_ContinualUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_InvSnapshot_ContinualUpdate: The Inventory snapshot is created at the
    beginning of the day (or end of previous day). To ensure the snapshot is
    relevant and upto date, this procedure is used to do continous updates to
    the snapshot for with the most recent Export info. i.e. each time it runs
    we would update the snapshot with the inventory Received, shipped, changed
    so that we have an accurate upto date inventory picture.

    The Units Received and UnitsToAllocate are important to know how many orders
    have been received and what inventory remains to be sold
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_InvSnapshot_ContinualUpdate
  (@SnapshotDate    TDate,
   @SnapshotType    TTypeCode     = 'EndOfDay',
   @BusinessUnit    TBusinessUnit = null,
   @UserId          TUserId       = null)
as
  declare @vReturnCode              TInteger,

          @vLastProcessedRecordId   TRecordId,
          @vControlId               TRecordId,
          @vMaxExportRecordId       TRecordId,
          @vSnapshotId              TRecordId,
          @vUserId                  TUserId,
          @vSnapshotDateTime        TDateTime;

  declare @ttExports Table
          (RecordId         TRecordId Identity(1,1),
           SKUId            TRecordId,
           SKU              TSKU,
           Warehouse        TWarehouse,
           Ownership        TOwnership,
           TransType        TTypeCode,
           TransEntity      TEntity,

           AvailableQty     TQuantity,
           ReservedQty      TQuantity,
           ReceivedQty      TQuantity,
           PutawayQty       TQuantity,
           AdjustedQty      TQuantity,
           ShippedQty       TQuantity,
           ToShipQty        TQuantity,

           InventoryClass1  TInventoryClass DEFAULT '',
           InventoryClass2  TInventoryClass DEFAULT '',
           InventoryClass3  TInventoryClass DEFAULT '',
           TransQty         TQuantity,
           BusinessUnit     TBusinessUnit,
           InventoryKey     TInventoryKey,

           MaxRecordId      TRecordId,
           primary key      (RecordId),
           unique           (SKU, Warehouse, RecordId)
           );

begin
  set NOCOUNT ON;

  /* initialize */
  select @vUserId = system_user;

  /* Get the Last updated control value for the Export RecordId */
  select @vLastProcessedRecordId = ControlValue,
         @vControlId             = RecordId
  from Controls
  where (ControlCategory = 'UpdateInvSnapShot') and
        (ControlCode     = 'LastProcessedRecordId') and
        (BusinessUnit    = @BusinessUnit);

 if (@vLastProcessedRecordId is null)
   return;

  if (object_id('tempdb..#ttExports') is null)   select * into #Exports     from @ttExports
  if (object_id('tempdb..#ToShipQty') is null)   select * into #ToShipQty   from @ttExports
  if (object_id('tempdb..#ReceivedQty') is null) select * into #ReceivedQty from @ttExports
  if (object_id('tempdb..#InvSnapshot') is null) select * into #InvSnapshot from InvSnapshot where 1 = 2

  /* Get latest SnapshotId and add records to it */
  select @vSnapshotId = max(SnapshotId)
  from InvSnapshot
  where (SnapshotDate = @SnapshotDate) and
        (SnapshotType = @SnapshotType) and
        (Archived     = 'N');

  /* New records to be inserted with the same date and time of the snapshot we will be
     inserting into for sake of consistency - However, createdate would tell us when
     we actually inserted the records */
  select top 1 @vSnapshotDateTime = SnapshotDateTime
  from InvSnapshot
  where (SnapshotId = @vSnapshotId);

  /* After creating invsnapshot for the day, if new SKU's are imported and
     inventory is created then insert those SKUs as well into latest invsnapshot */
  ;with MissedInvInfo(SKUId, Warehouse, Ownership, Lot, InventoryClass1, InventoryClass2, InventoryClass3, BusinessUnit, InventoryKey)
  as
  (
   select min(E.SKUId), min(E.Warehouse), min(E.Ownership), min(E.Lot),
          min(E.InventoryClass1), min(E.InventoryClass2), min(E.InventoryClass3),
          min(E.BusinessUnit), E.InventoryKey
   from Exports E
     left outer join InvSnapshot INVSS on (INVSS.InventoryKey = E.InventoryKey) and
                                          (INVSS.SnapshotId   = @vSnapshotId)
   where (E.TransDate = @SnapshotDate) and
         (E.TransType in ('InvCh') and E.TransEntity in ('LPND') or
          E.TransType in ('InvCh', 'Recv') and E.TransEntity in ('LPND', 'LPN', 'RV')) and
         (E.Status in ('Y', 'N')) and
         (INVSS.RecordId is null)
   group by E.InventoryKey
  )
  insert into #InvSnapshot (SKUId, Warehouse, Ownership, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                          BusinessUnit, InventoryKey, InitialOnhandQty, Createdby)
  select SKUId, Warehouse, Ownership, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
       BusinessUnit, InventoryKey, 0, @UserId
  from MissedInvInfo;

  /* Add the SKU details */
  update INVSS
  set INVSS.UPC  = S.UPC,
      INVSS.SKU  = S.SKU,
      INVSS.SKU1 = S.SKU1,
      INVSS.SKU2 = S.SKU2,
      INVSS.SKU3 = S.SKU3,
      INVSS.SKU4 = S.SKU4,
      INVSS.SKU5 = S.SKU5
  from #InvSnapshot INVSS join SKUs S on (INVSS.SKUId = S.SKUId);

  /* Insert the new SKUs into the indentified InvSnapshot */
  insert into InvSnapshot (SnapshotId, SnapshotDateTime, SnapshotDate, SnapShotType,
                           SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC,
                           Warehouse, Ownership, Lot,
                           InventoryClass1, InventoryClass2, InventoryClass3,
                           InventoryKey, InitialOnhandQty, BusinessUnit, CreatedBy)
  select @vSnapshotId, @vSnapshotDateTime, @SnapshotDate, @SnapshotType,
         SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC,
         Warehouse, Ownership, Lot,
         InventoryClass1, InventoryClass2, InventoryClass3,
         InventoryKey, InitialOnhandQty, BusinessUnit, Createdby
  from #InvSnapshot;

  /* Add the required fields */
  alter table #ToShipQty add UnitsToAllocate int, UnitsReserved int;

  /* Get the max Export recordId to process - to avoid the issues which will happen when we will add new export record
    while processing */
  select @vMaxExportRecordId = max(RecordId)
  from Exports
  where (RecordId > @vLastProcessedRecordId) and
        (Status in ('Y', 'N' /* Processed, Not Processed */));

  /* Identify and get all the new exports which have happened since the earlier snapshot was taken */
  insert into #Exports (TransType, InventoryKey, TransQty)
    select E.TransType, E.InventoryKey, sum(E.TransQty)
    from Exports E
    where (E.RecordId > @vLastProcessedRecordId) and
          (E.RecordId <= @vMaxExportRecordId) and
          ((E.TransType in ('InvCh', 'Ship') and E.TransEntity in ('LPND', 'LPNDetail')) or
           (E.TransType in ('InvCh','Recv') and E.TransEntity in ('LPND', 'LPN', 'RV'))) and
          (E.Status in ('Y', 'N' /* Processed, Not Processed */))
    group by E.TransType, E.InventoryKey;

  /* Get the ReceivedQty */
  insert into #ReceivedQty(InventoryKey, ReceivedQty)
    select LD.InventoryKey, sum(LD.Quantity)
    from LPNs L
      join LPNDetails LD on (L.LPNId = LD.LPNId) and (LD.OnhandStatus = 'U' /* Unavailable */)
    where (L.Archived = 'N') and (L.Status = 'R' /* Received */)
    group by LD.InventoryKey;

  /* Get the UnitsToAllocate */
  insert into #ToShipQty(InventoryKey, UnitsToAllocate)
    select OD.InventoryKey, sum(OD.UnitsToAllocate)
    from Orderdetails OD
      join OrderHeaders OH on (OD.OrderId = OH.OrderId)
    where (OD.Archived = 'N') and
          (OH.Status not in ('S', 'D', 'X' /* Shipped, Completed, Canceled */)) and
          (OH.OrderType not in ('R', 'RP', 'RU', 'B'  /* Regular/Partial, Replenish Cases, Replenish Units, Bulk Pull */))
    group by OD.InventoryKey;

  /* Update final values here. We don't recompute Available/ReservedQty, so
     clear them so that it is not assumed to be wrong */
  update Inv
  set Inv.AdjustedQty  = coalesce(Inv.AdjustedQty, 0) + iif (EINV.TransType = 'InvCh', coalesce(EINV.TransQty, 0), 0),
      Inv.PutawayQty   = coalesce(Inv.PutawayQty,  0) + iif (EPA.TransType = 'Recv',  coalesce(EPA.TransQty, 0), 0),
      Inv.ShippedQty   = coalesce(Inv.ShippedQty,  0) + iif (ESHIP.TransType = 'Ship',  coalesce(ESHIP.TransQty, 0), 0),
      Inv.ReceivedQty  = coalesce(RQ.ReceivedQty,      Inv.ReceivedQty, 0),
      Inv.ToShipQty    = coalesce(TSQ.UnitsToAllocate, Inv.ToShipQty,   0),
      Inv.IS_UDF1      = @vLastProcessedRecordId + 1,     -- Reflects the starting of the exports that are summarized
      Inv.IS_UDF2      = @vMaxExportRecordId              -- Reflects the ending of the exports that are summarized
  from InvSnapshot Inv
     left outer join #Exports    EINV  on (Inv.InventoryKey = EINV.InventoryKey ) and EINV.TransType ='InvCh'
     left outer join #Exports    EPA   on (Inv.InventoryKey = EPA.InventoryKey  ) and EPA.TransType ='Recv'
   	 left outer join #Exports    ESHIP on (Inv.InventoryKey = ESHIP.InventoryKey) and ESHIP.TransType ='Ship'
    left outer join #ReceivedQty RQ    on (Inv.InventoryKey = RQ.InventoryKey )
    left outer join #ToShipQty   TSQ   on (Inv.InventoryKey = TSQ.InventoryKey)
  where (Inv.SnapshotId = @vSnapshotId);

  /* Save the last export record processed in Controls */
  if (coalesce(@vMaxExportRecordId, 0) <> 0)
    update Controls set ControlValue = @vMaxExportRecordId where (RecordId = @vControlId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_InvSnapshot_ContinualUpdate */

Go
