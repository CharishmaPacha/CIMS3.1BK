/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/12  PKK     pr_Replenish_GenerateOndemandOrders, pr_Replenish_GenerateOrdersForDynamicLocations: Replaced => Status with Wavestatus (CIMSV3-1416)
                      pr_Replenish_GenerateOndemandOrders:  Changes to return LocationId & SKUId (HA-938)
  2020/06/08  TK      pr_Replenish_GenerateOndemandOrders, pr_Replenish_GenerateOrders, pr_Replenish_OnDemandLocationsToReplenish,
  2019/06/19  VS      pr_Replenish_GenerateOndemandOrders: Fixed getting duplicate replenish Waves (CID-602)
  2018/04/05  TK      pr_Replenish_GenerateOndemandOrders: Bug fix to update IsReplenished flag properly (S2G-577)
  2018/03/26  TK      pr_Replenish_GenerateOrders & pr_Replenish_GenerateOndemandOrders:
  2018/03/12  TK      pr_Replenish_GenerateOndemandOrders: Changes to create OnDemand order for case storage Locations as well
  2017/02/23  TK      pr_Replenish_GenerateOndemandOrders: Quantity to allocate on any line should exclude reserved qty on it
  2017/01/05  AY      pr_Replenish_GenerateOndemandOrders: Consider 'Mixed' pickzone as 'DC1' as well.
  2016/12/30  TK      pr_Replenish_GenerateOndemandOrders: Consider 'FS' pickzone as 'DC1' while finding location (HPI-1225)
  2016/12/12  AY      pr_Replenish_GenerateOndemandOrders: Not replenishing to Picklanes without any line (HPI-GoLive)
  2016/12/10  AY      pr_Replenish_GenerateOndemandOrders: Find On-Demand location within the same pick zone of the Wave (HPI-GoLive)
  2016/11/27  AY      pr_Replenish_GenerateOndemandOrders: Allocate from DC2 as well now (HPI-GoLive)
  2016/10/04  AY      pr_Replenish_GenerateOndemandOrders: Ondemand replenishments not being created when Location is picked clean (HPI-GoLive)
  2016/09/28  AY      pr_Replenish_GenerateOndemandOrders: Disable replenishment for some SKUs (HPI-810)
  2016/09/16  PSK     pr_Replenish_GenerateOndemandOrders: Changed to update Accountname.(HPI-666)
  2016/09/13  AY      pr_Replenish_GenerateOndemandOrders: Temp change to replenish only to DC1 locations (HPI-GoLive)
  2016/09/06  VM      pr_Replenish_GenerateOndemandOrders: Use coalesce for MaxReplenishLevel (HPI-581)
  2016/07/03  AY      pr_Replenish_GenerateOndemandOrders: ReplenishQty not right when ReplenishUoM = eaches.
  2016/05/10  TK      pr_Replenish_GenerateOndemandOrders: Changed to return replenish batchno (NBD-485)
  2016/05/10  TK      pr_Replenish_GenerateOndemandOrders: Auto release On-Demand replenish Batch (NBD-485)
  2016/05/03  AY      pr_Replenish_GenerateOndemandOrders: Enhanced to create Replenishment even though we have missing SKU info.
  2016/04/05  AY      pr_Replenish_GenerateOndemandOrders: Changed to not create replenish line if there is no picklane
  2016/03/18  TK      pr_Replenish_GenerateOndemandOrders: Update IsReplenish flag to 'Y' only if ReplenishBatch is created (NBD-290)
  2016/03/02  TK      pr_Replenish_GenerateOndemandOrders: Consider Ownership while generating Orders
                      pr_Replenish_GenerateOndemandOrders: Update the Replenish Batch No in Pickbatch attributes (FB-561)
  2015/12/04  AY      pr_Replenish_GenerateOndemandOrders: Restrict replenish to Active locations only and
                      pr_Replenish_GenerateOndemandOrders: Call generate replenish orders if SKUs to replenish exist (FB-554)
                      pr_Replenish_GenerateOndemandOrders: Passing batch number parameter while generating replenish orders  (FB-482)
  2015/10/28  AY      pr_Replenish_GenerateOndemandOrders: Migrated from GNC
  2014/01/05  AY      pr_Replenish_GenerateOndemandOrders: Changes to replenish beyond the
  2014/11/16  TD      pr_Replenish_GenerateOndemandOrders:Updating AllocateFlags when the
  2014/11/14  AY      pr_Replenish_GenerateOndemandOrders: Create replenishment for Max cases
  2014/06/19  TD      pr_Replenish_GenerateOndemandOrders:Changes to create ondemand replensihmnents based on
  2014/05/18  PK      Added pr_Replenish_GenerateOndemandOrders, pr_Replenish_GetProcessDetails.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_GenerateOndemandOrders') is not null
  drop Procedure pr_Replenish_GenerateOndemandOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_GenerateOndemandOrders: Procedure evaluates the given pick batch
    and generates on-demand replenishment orders if the Picklane-Unit storage
    does not have enough inventory to satisfy the orders.

  This assumes that the batch is not yet allocated and should be changed to work
  whether the batch is allocated or not.

  Current implementation:
  - Find the Waves to be replenished
    - For each Wave find the list of SKUs that need to be replenished
      - For each SKU...
        - Find the Static Picklane Location
        - Check the Allocable qty in the location (Directed + Available)
        - if there is not sufficient, then we need to Replenish Ondemand to the Loc
        - Replenish Qty being Max of the MaxReplenishLevel of UnitsNeeded
        - Exception: If SKU Stds are not set and we cannot decide how many Cases or LPNs
          to replenish, then convert ReplenishQty to units and set that.
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_GenerateOndemandOrders
  (@PickBatchNo       TPickBatchNo  = null,
   @BusinessUnit      TBusinessUnit = null,
   @UserId            TUserId       = null,
   @ReplenishBatchNo  TPickBatchNo  = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vRecordId              TRecordId,
          @vWaveId                TRecordId,
          @vWaveNo                TWaveNo,
          @vConfirmMessage        TDescription,
          @vLocationsInfo         XML,
          @vOptions               XML,
          @vDebug                 TFlags,
          @vGenerateReplenishXML  TXML;

  declare @ttReplenishWaves       TEntityKeysTable,
          @ttBatchedOrderDetails  TBatchedOrderDetails,
          @ttLocationsToReplenish TLocationsToReplenish;

  declare @ttOrdersUpdated        TEntityKeysTable;
begin /* pr_Replenish_GenerateOndemandOrders */
begin try
begin transaction
  select @vReturnCode = 0;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Create #Orders Updated table */
  select * into #OrdersUpdated from @ttOrdersUpdated;

  /* get the batches which needs to be replenished into the temp table */
  select @vWaveId = PickBatchId,
         @vWaveNo = PickBatchNo
  from PickBatchAttributes
  where (PickBatchNo   = coalesce(@PickBatchNo, PickBatchNo)) and
        (IsReplenished = 'N' /* No */) and
        (BusinessUnit  = @BusinessUnit);

  /* Find the locations that needs to be replenished */
  insert into @ttLocationsToReplenish (LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, QtyToReplenish, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse)
    exec pr_Replenish_OnDemandLocationsToReplenish @vWaveId;

  if (charindex('D', @vDebug) > 0) select * from @ttLocationsToReplenish;

  if (exists (select * from @ttLocationsToReplenish))
    begin
      /* build the xml with the details for generating replenish order */
      select @vLocationsInfo = (select distinct LocationId      as LocationId,
                                                Location        as Location,
                                                StorageType     as StorageType,
                                                SKUId           as SKUId,
                                                SKU             as SKU,
                                                ReplenishUoM    as ReplenishUoM,
                                                sum(QtyToReplenish)
                                                                as QtyToReplenish,
                                                InventoryClass1 as InventoryClass1,
                                                InventoryClass2 as InventoryClass2,
                                                InventoryClass3 as InventoryClass3,
                                                Ownership       as Ownership,
                                                Warehouse       as Warehouse
                                from @ttLocationsToReplenish
                                group by LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse
                                FOR XML RAW('LOCATIONSINFO'), TYPE, ELEMENTS XSINIL),
             @vOptions       = '<OPTIONS><Priority>1</Priority><Operation>OnDemandReplenish</Operation></OPTIONS>';

      select @vGenerateReplenishXML = '<GENERATEREPLENISHORDER>'
                                       + coalesce(convert(varchar(max), @vLocationsInfo), '')
                                       + coalesce(convert(varchar(max), @vOptions), '') +
                                      '</GENERATEREPLENISHORDER>';

      /* generate the replenish order */
      exec pr_Replenish_GenerateOrders @vGenerateReplenishXML, @BusinessUnit, @UserId,
                                       @vConfirmMessage output, @PickBatchNo, @ReplenishBatchNo output;

      insert into @ttOrdersUpdated(EntityId, EntityKey)
        select EntityId, EntityKey from #OrdersUpdated;

      if (charindex('D', @vDebug) > 0) select @vConfirmMessage Message;
    end

  /* Release the Replenish Wave and update PickBatches Allocate flag so that after the Ondemand repenishment
     is allocated, the wave will be allocated against the directed qty */
  if exists(select * from @ttOrdersUpdated)
    begin
      insert into @ttReplenishWaves(EntityId, EntityKey)
        select distinct PickBatchId, PickBatchNo
        from @ttOrdersUpdated ttO join OrderHeaders OH on (ttO.EntityId = OH.OrderId)
        where (PickBatchNo is not null);

      if (@@rowcount > 0)
        begin
          /* Update the IsReplenished Flag on the batches */
          update PickBatchAttributes
          set IsReplenished = 'Y'/* Yes */
          from PickBatchAttributes
          where (PickBatchNo = @PickBatchNo);

          /* Release Replenish Wave */
          exec pr_Wave_ReleaseForAllocation @ttReplenishWaves, null /* xmlData */, @UserId, @BusinessUnit;

          /* Return all the waves which needs to be re-allocated */
          delete from #ReplenishWavesToAllocate;

          insert into #ReplenishWavesToAllocate(WaveId, WaveNo, WaveType, WaveStatus, IsAllocated, InvAllocationModel, Warehouse, AllocPriority)
            select PB.RecordId, PB.BatchNo, PB.BatchType, PB.Status, 'N'/* No */, PB.InvAllocationModel, PB.Warehouse, 1 /* Alloc Priority */
            from PickBatches PB
              join @ttReplenishWaves ttRW on (PB.RecordId = ttRW.EntityId);
        end
    end

  /* If the wave is replenished then we would have update flag above, so if the flag is not
     updated above then ignore creating on-demand for that wave */
  update PickBatchAttributes
  set IsReplenished = case when IsReplenished = 'N'/* No */ then 'I'/* Ignore */ else IsReplenished end
  from PickBatchAttributes
  where (PickBatchNo = @PickBatchNo);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;

end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_ReRaiseError;
  /* Generate error LOG here */
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_GenerateOndemandOrders */

Go
