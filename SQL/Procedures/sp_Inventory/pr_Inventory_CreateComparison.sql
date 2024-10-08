/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/10  SK      pr_Inventory_CreateComparison: Consider all export records for inventory comparison
  2020/10/17  AY      pr_Inventory_CreateComparison: Fix issues with not including some Receipts, performance (HI-1539)
                      pr_Inventory_CreateComparison: Minor enhancements (HA-1297)
  2020/07/20  SK      pr_Inventory_CreateComparison: Email variance if exists for records (HA-1180)
  2019/07/08  VS      pr_Inventory_CreateComparison: Made changes for new table i.e InvComparison (CID-733)
  2019/01/11  HB      Renamed pr_Inventory_CreateVariance as pr_Inventory_CreateComparison. Removed pr_Inventory_ValidateInvComparison. Renamed InvVariances table as InvComparison.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_CreateComparison') is not null
  drop Procedure pr_Inventory_CreateComparison;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_CreateComparison: This procedure compares the snapshots
   between two different dates and all the exports that have happened during
   this time frame.

  If Date is given then the first snapshot is the last one created that day and
  the second snapshot is the last one created the prior day.

  ResultDataSet - If S, data would be saved in InvComparison table, if V, data will be returned
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_CreateComparison
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @DateGiven       TDate       = null,
   @CompareSSId1    TRecordId   = null,
   @CompareSSId2    TRecordId   = null,
   @SKU             TSKU        = null,
   @ResultDataSet   TFlags      = 'S',
   @Debug           TFlags      = null)
as

  declare @vExportStartRange      TDateTime,
          @vSS1_Id                TRecordId,
          @vSS2_Id                TRecordId,
          @vSS1_DateTime          TDateTime,
          @vSS1_Date              TDate,
          @vSS2_DateTime          TDateTime,
          @vSS2_Date              TDate,
          @vDebug                 TFlags,
          @vMessageName           TMessageName,
          @vReturnCode            TInteger;

  declare @InvKeys table (InventoryKey TKeyValue);

  declare @ttInvSnapshot Table
          (RecordId         TRecordId identity (1,1),
           SnapshotId       TRecordId,
           SKUId            TRecordId,
           SKU              TSKU,
           Warehouse        TWarehouse,
           Ownership        TOwnership,
           SnapshotDateTime TDateTime,
           InventoryClass1  TInventoryClass DEFAULT '',
           InventoryClass2  TInventoryClass DEFAULT '',
           InventoryClass3  TInventoryClass DEFAULT '',
           AvailableQty     TQuantity,
           ReservedQty      TQuantity,
           OnhandQty        TQuantity,
           ReceivedQty      TQuantity,
           ToShipQty        TQuantity,
           InventoryKey     TKeyValue,
           KeyValue         as cast(SKUId as varchar)  + '-' + coalesce(Warehouse, '') + '-' + coalesce(Ownership, '') + '-' +
                               coalesce(InventoryClass1, '') + '-' + coalesce(InventoryClass2, '') + '-' + coalesce(InventoryClass3, ''),

           Primary key      (RecordId),
           Unique           (SnapshotId, SKU, RecordId),
           Unique           (KeyValue, RecordId),
           Unique           (InventoryKey, RecordId)
           );

  declare @ttInvComparison Table
          (RecordId         TRecordId identity (1,1),
           SKUId            TRecordId,
           SKU              TSKU,
           Warehouse        TWarehouse,
           Ownership        TOwnership,
           InventoryClass1  TInventoryClass DEFAULT '',
           InventoryClass2  TInventoryClass DEFAULT '',
           InventoryClass3  TInventoryClass DEFAULT '',
           SS1Id            TRecordId,
           SS1Date          TDate,
           SS1AvailableQty  TQuantity,
           SS1ReservedQty   TQuantity,
           SS1OnhandQty     TQuantity,
           SS1ReceivedQty   TQuantity,
           SS1ToShipQty     TQuantity,
           SS2Id            TRecordId,
           SS2Date          TDate,
           SS2AvailableQty  TQuantity,
           SS2ReservedQty   TQuantity,
           SS2OnhandQty     TQuantity,
           SS2ReceivedQty   TQuantity,
           SS2ToShipQty     TQuantity,
           ExpReceivedQty   TQuantity,
           ExpInvChanges    TQuantity,
           ExpShippedQty    TQuantity,
           ExtPackedQty     TQuantity,

           InventoryKey     TKeyValue,
           KeyValue         as cast(SKUId as varchar) + '-' + coalesce(Warehouse, '') + '-' + coalesce(Ownership, '') + '-' +
                               coalesce(InventoryClass1, '') + '-' + coalesce(InventoryClass2, '') + '-' + coalesce(InventoryClass3, ''),
           Variance         as coalesce(SS2OnhandQty, 0) - (coalesce(SS1OnhandQty, 0) + coalesce(ExpReceivedQty, 0) + coalesce(ExpInvChanges, 0) - coalesce(ExpShippedQty, 0))

           Primary key      (RecordId),
           Unique           (KeyValue, RecordId),
           Unique           (InventoryKey, RecordId)
           );

  declare @ttExports Table
          (RecordId         TRecordId Identity(1,1),
           SKUId            TRecordId,
           SKU              TSKU,
           Warehouse        TWarehouse,
           Ownership        TOwnership,
           TransType        TTypeCode,
           TransEntity      TEntity,
           InventoryClass1  TInventoryClass DEFAULT '',
           InventoryClass2  TInventoryClass DEFAULT '',
           InventoryClass3  TInventoryClass DEFAULT '',
           TransQty         TQuantity,
           BusinessUnit     TBusinessUnit,
           InventoryKey     as cast(SKUId as varchar)  + '-' + coalesce(Warehouse, '') + '-' + coalesce(Ownership, '') + '-' + coalesce(BusinessUnit, '') + '-' +
                               rtrim(coalesce(InventoryClass1, '')) + '-' + rtrim(coalesce(InventoryClass2, '')) + '-' + rtrim(coalesce(InventoryClass3, '')),
           KeyValue         as cast(SKUId as varchar)  + '-' + coalesce(Warehouse, '') + '-' + coalesce(Ownership, '') + '-' +
                               coalesce(InventoryClass1, '') + '-' + coalesce(InventoryClass2, '') + '-' + coalesce(InventoryClass3, ''),

           Primary key      (RecordId),
           Unique           (SKU, Warehouse, RecordId),
           Unique           (KeyValue, TransType, TransQty, RecordId),
           Unique           (TransType, InventoryKey, TransQty, RecordId)
           );

begin/* pr_Inventory_CreateComparison */
SET NOCOUNT ON;

  select  @vReturnCode  = 0,
          @vMessageName = '',
          @DateGiven    = coalesce(@DateGiven, getdate()),
          @CompareSSId1 = coalesce(@CompareSSId1, 0),
          @CompareSSId2 = coalesce(@CompareSSId2, 0);

  /* Step 1: Validations */
  if (@DateGiven    = '') and
     (@CompareSSId1 = 0) and
     (@CompareSSId2 = 0)
    select @vMessageName = 'No inputs are provided, Please input date in YYYY-MM-DD format or given specific snapshots to compare'
  else
  if (@DateGiven    = '') and
     ((@CompareSSId1 <> 0) and (@CompareSSId2 = 0)) or
     ((@CompareSSId1 = 0)  and (@CompareSSId2 <> 0))
    select @vMessageName = 'Cannot compare only one snapshot, please provide both snapshots to compare'

  if (coalesce(@vMessageName,'') <> '')
    goto ErrorHandler;

  /* Establish the snapshots to compare */
  if (@CompareSSId1 <> 0) -- if SSIds are given
    begin
      select top 1 @vSS1_Id       = SnapshotId,
                   @vSS1_DateTime = SnapshotDateTime
      from InvSnapshot
      where (SnapShotId = @CompareSSId1);

      select top 1 @vSS2_Id       = SnapshotId,
                   @vSS2_DateTime = SnapshotDateTime
      from InvSnapshot
      where (SnapShotId = @CompareSSId2);
    end
  else
    begin
      /* If only date is given, then SS1 is the last previous end of day snapshot
         - most likely from the prior day but could be earlier as well */
      select top 1 @vSS1_Id       = SnapshotId,
                   @vSS1_DateTime = SnapshotDateTime
      from InvSnapshot
      where (SnapshotDate < @DateGiven) and (SnapshotType = 'EndOfDay')
      order by SnapshotDate desc;

      /* If only date is given, then  SS2 is the end of day snapshot of current day */
      select top 1 @vSS2_Id       = SnapshotId,
                   @vSS2_DateTime = SnapshotDateTime
      from InvSnapshot
      where (SnapshotDate = @DateGiven) and (SnapshotType = 'EndOfDay')
      order by RecordId desc;
    end

  /* Get the dates for evaluation of exports */
  select @vSS1_Date = cast(@vSS1_DateTime as date);
  select @vSS2_Date = cast(@vSS2_DateTime as date);

  /* Step 2: Get InvSnapshot values for previous and today's dates requested */
  /* Start with inserting snapshot values of SS2 (today) into Comparison */
  insert into @ttInvComparison
          (SKUId, SKU, Warehouse, Ownership, InventoryKey, InventoryClass1, InventoryClass2, InventoryClass3,
           SS2Id, SS2Date, SS2AvailableQty, SS2ReservedQty, SS2OnhandQty, SS2ReceivedQty, SS2ToShipQty,
           SS1Id, SS1Date, SS1AvailableQty, SS1ReservedQty, SS1OnhandQty, SS1ReceivedQty, SS1ToShipQty)
    select min(SKUId), min(SKU), min(Warehouse), min(Ownership), InventoryKey, min(InventoryClass1), min(InventoryClass2), min(InventoryClass3),
           @vSS2_Id, @vSS2_DateTime, sum(AvailableQty), sum(ReservedQty), sum(OnhandQty), sum(ReceivedQty), sum(ToShipQty),
           @vSS1_Id, @vSS1_DateTime, 0, 0, 0, 0, 0
    from InvSnapshot
    where (SnapshotId = @vSS2_Id) and
          (SKU like coalesce(@SKU, '%'))
    group by SnapshotId, InventoryKey;

  /* Insert previous snapshot into temp table to be later updated into @ttInvComparison */
  insert into @ttInvSnapshot
          (SKUId, SKU, Warehouse, Ownership, SnapshotId, InventoryKey,
           InventoryClass1, InventoryClass2, InventoryClass3,
           AvailableQty, ReservedQty, OnhandQty, ReceivedQty, ToShipQty)
    select min(SKUId), min(SKU), min(Warehouse), min(Ownership), SnapshotId, InventoryKey,
           min(InventoryClass1), min(InventoryClass2), min(InventoryClass3),
           sum(AvailableQty), sum(ReservedQty), sum(OnhandQty), sum(ReceivedQty), sum(ToShipQty)
    from InvSnapshot
    where (SnapshotId = @vSS1_Id) and
          (SKU like coalesce(@SKU, '%'))
    group by SnapshotId, InventoryKey;

  -- /* include records from both previous and current snapshots */
  -- merge @ttInvComparison IC
  -- using @ttInvSnapshot S1
  --   on (IC.InventoryKey = S1.InventoryKey)
  -- when matched
  --   /* when matched, Update comparison with S1 info */
  --   then update
  --     set IC.SS1Id           = @vSS1_Id,
  --         IC.SS1Date         = @vSS1_DateTime,
  --         IC.SS1AvailableQty = S1.AvailableQty,
  --         IC.SS1ReservedQty  = S1.ReservedQty,
  --         IC.SS1OnhandQty    = S1.OnhandQty,
  --         IC.SS1ReceivedQty  = S1.ReceivedQty,
  --         IC.SS1ToShipQty    = S1.ToShipQty
  -- when not matched by target
  --   /* means there are records in S1 which do not have corresponding records in S2 */
  --   then insert (SKUId, SKU, Warehouse, Ownership, InventoryKey, InventoryClass1, InventoryClass2, InventoryClass3,
  --                SS1Id, SS1Date, SS1AvailableQty, SS1ReservedQty, SS1OnhandQty, SS1ReceivedQty, SS1ToShipQty,
  --                SS2Id, SS2Date, SS2AvailableQty, SS2ReservedQty, SS2OnhandQty, SS2ReceivedQty, SS2ToShipQty)
  --        values (S1.SKUId, S1.SKU, S1.Warehouse, S1.Ownership, S1.InventoryKey, S1.InventoryClass1, S1.InventoryClass2, S1.InventoryClass3,
  --                @vSS1_Id, @vSS1_DateTime, S1.AvailableQty, S1.ReservedQty, S1.OnhandQty, S1.ReceivedQty, S1.ToShipQty,
  --                @vSS2_Id, @vSS2_DateTime, 0, 0, 0, 0, 0)
  -- when not matched by source
  --   /* meaning there are records in S2 but no corresponding records in S1 */
  --   then update
  --     set IC.SS1Id           = @vSS1_Id,
  --         IC.SS1Date         = @vSS1_DateTime,
  --         IC.SS1AvailableQty = 0,
  --         IC.SS1ReservedQty  = 0,
  --         IC.SS1OnhandQty    = 0,
  --         IC.SS1ReceivedQty  = 0,
  --         IC.SS1ToShipQty    = 0;

  /* Get the Inventory keys for the records in S1 but not in IC */
  insert into @InvKeys (InventoryKey)
    select S1.InventoryKey from @ttInvSnapshot S1 except select IC.InventoryKey from @ttInvComparison IC;

  /* insert into Comparions records in S1 which do not have corresponding record in S2 */
  insert into @ttInvComparison
          (SKUId, SKU, Warehouse, Ownership, InventoryKey, InventoryClass1, InventoryClass2, InventoryClass3,
           SS1Id, SS1Date, SS1AvailableQty, SS1ReservedQty, SS1OnhandQty, SS1ReceivedQty, SS1ToShipQty,
           SS2Id, SS2Date, SS2AvailableQty, SS2ReservedQty, SS2OnhandQty, SS2ReceivedQty, SS2ToShipQty)
    select S1.SKUId, S1.SKU, S1.Warehouse, S1.Ownership, S1.InventoryKey, S1.InventoryClass1, S1.InventoryClass2, S1.InventoryClass3,
           @vSS1_Id, @vSS1_DateTime, S1.AvailableQty, S1.ReservedQty, S1.OnhandQty, S1.ReceivedQty, S1.ToShipQty,
           @vSS2_Id, @vSS2_DateTime, 0, 0, 0, 0, 0
    from @ttInvSnapshot S1 join @InvKeys IK on (IK.InventoryKey = S1.InventoryKey);

  /* Update Comparison with SS1 info for matching records between SS1 and SS2 (which are already in Comparison) */
  update IC
  set IC.SS1Id           = @vSS1_Id,
      IC.SS1Date         = @vSS1_DateTime,
      IC.SS1AvailableQty = S1.AvailableQty,
      IC.SS1ReservedQty  = S1.ReservedQty,
      IC.SS1OnhandQty    = S1.OnhandQty,
      IC.SS1ReceivedQty  = S1.ReceivedQty,
      IC.SS1ToShipQty    = S1.ToShipQty
  from @ttInvComparison IC join @ttInvSnapshot S1 on (IC.InventoryKey = S1.InventoryKey);

  /* Step 3: Get subset of vwExports, sum of transQty between the period, and insert into new table */
  /* Take a subset of the vwExports table */
  insert into @ttExports
          (TransType, TransEntity, SKUId, Warehouse, Ownership, BusinessUnit,
           InventoryClass1, InventoryClass2, InventoryClass3, TransQty)
    select E.TransType, E.TransEntity, E.SKUId, E.Warehouse, E.Ownership, E.BusinessUnit,
           E.InventoryClass1, E.InventoryClass2, E.InventoryClass3, sum(E.TransQty)
    from Exports E
    where (E.TransDate between @vSS1_Date and @vSS2_Date) and -- for performance
          (E.TransDateTime between @vSS1_DateTime and @vSS2_DateTime) and
          (E.TransType in ('InvCh', 'Ship') and E.TransEntity in ('LPND') OR
           E.TransType in ('InvCh','Recv') and E.TransEntity in ('LPND', 'LPN', 'RV')) and
          (E.Status in ('Y', 'N'))
    group by E.TransType, E.TransEntity, E.SKUId, E.Warehouse, E.Ownership, E.BusinessUnit, E.InventoryClass1, E.InventoryClass2, E.InventoryClass3;

  if (charindex('D', @Debug) > 0) select 'Exports', * from @ttExports;
  if (charindex('D', @Debug) > 0) select 'InvComp', * from @ttInvComparison;

  /* Join the export table subset with comparison temp table */
  with recv_cte(InventoryKey, ExpReceivedQty)
  as
  (
    select exp.InventoryKey, sum(exp.TransQty)
    from @ttExports exp
      join @ttInvComparison TT on exp.InventoryKey = TT.InventoryKey
    where exp.TransType = 'Recv'
    group by exp.InventoryKey
  ),
  invch_cte(InventoryKey, ExpInvChanges)
  as
  (
    select exp.InventoryKey, sum(exp.TransQty)
    from @ttExports exp
      join @ttInvComparison TT on exp.InventoryKey = TT.InventoryKey
    where exp.TransType = 'InvCh'
    group by exp.InventoryKey
  ),
  ship_cte(InventoryKey, ExpShippedQty)
  as
  (
    select exp.InventoryKey, sum(exp.TransQty)
    from @ttExports exp
      join @ttInvComparison TT on exp.InventoryKey = TT.InventoryKey
    where exp.TransType = 'Ship'
    group by exp.InventoryKey
  )
  update IC
  set ExpReceivedQty = coalesce(recv.ExpReceivedQty, 0),
      ExpInvChanges  = coalesce(invch.ExpInvChanges, 0),
      ExpShippedQty  = coalesce(ship.ExpShippedQty,  0)
  from @ttInvComparison IC
    left join recv_cte recv   on IC.InventoryKey = recv.InventoryKey
    left join invch_cte invch on IC.InventoryKey = invch.InventoryKey
    left join ship_cte ship   on IC.InventoryKey = ship.InventoryKey;

  /* Step 4: insert into the new table with the values fetched */
  /* Inventory comparisons of SKUs inserted into the new table */
  if (charindex('S', @ResultDataSet) > 0)
    insert into InvComparison (SKUId, SKU, Warehouse, Ownership, InventoryKey,
                               InventoryClass1, InventoryClass2, InventoryClass3,
                               SS1Id, SS1Date, SS1AvailableQty, SS1ReservedQty,
                               SS1OnhandQty, SS1ReceivedQty, SS1ToShipQty,
                               SS2Id, SS2Date, SS2AvailableQty, SS2ReservedQty,
                               SS2OnhandQty, SS2ReceivedQty, SS2ToShipQty,
                               ExpReceivedQty, ExpInvChanges, ExpShippedQty, ExtPackedQty,
                               Notes, BusinessUnit, CreatedBy)
      select TT.SKUId, TT.SKU, TT.Warehouse, TT.Ownership, TT.InventoryKey,
             TT.InventoryClass1, TT.InventoryClass2, TT.InventoryClass3,
             TT.SS1Id, TT.SS1Date, TT.SS1AvailableQty, TT.SS1ReservedQty,
             TT.SS1OnhandQty, TT.SS1ReceivedQty, TT.SS1ToShipQty,
             TT.SS2Id, TT.SS2Date, TT.SS2AvailableQty, TT.SS2ReservedQty,
             TT.SS2OnhandQty, TT.SS2ReceivedQty, TT.SS2ToShipQty,
             TT.ExpReceivedQty, TT.ExpInvChanges, TT.ExpShippedQty, 0 /* Packed Qty */,
             '' /* Notes */, @BusinessUnit, @UserId
      from @ttInvComparison TT
   else
    select * from @ttInvComparison where (Variance <> 0);

ErrorHandler:
  if (coalesce(@vMessageName,'') <> '')
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_CreateComparison */

Go
