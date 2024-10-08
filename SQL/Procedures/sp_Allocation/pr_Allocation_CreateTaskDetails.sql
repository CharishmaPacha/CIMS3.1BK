/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/05  TK      pr_Allocation_CreateTaskDetails: Code Revamp (HA-1487)
  2018/08/15  TK      pr_Allocation_CreateTaskDetails: Bug Fix to update dest Location and Zone on TaskDetails (OB2-573)
  2018/02/20  TK      pr_Allocation_AllocateWave: Added step to update Wave & Task Dependencies
                      pr_Allocation_CreatePickTasks & pr_Allocation_CreateTaskDetails:
                        Changes to update WaveId on Tasks/Task Details (S2G-152)
  2017/07/20  TK      pr_Allocation_AllocateWave, pr_Allocation_AllocateInventory & pr_Allocation_CreateTaskDetails:
                        Added markers to check time delays (HPI-1608)
  2017/07/05  DK      pr_Allocation_CreateTaskDetails: Enhanced to send OrderType to TaskCategory rules (HPI-1571)
  2017/02/06  AY      pr_Allocation_CreateTaskDetails: Start using rules to determine Pick Type and pick as Units only
                        for Pick To Cart wave. (HPI-1366)
  2016/09/27  AY      pr_Allocation_CreateTaskDetails: Temp fix to force all engraving labels to be unit picks
  2016/08/22  AY      pr_Allocation_CreateTaskDetails: Compute TaskGroup1, 2 & Task Category 5
  2016/08/19  TK      pr_Allocation_CreateTaskDetails: Bug fix to update DestLocation on Task Details (HPI-484)
  2016/06/25  AY      pr_Allocation_CreateTaskDetails: New procedure (HPI-162)
                      pr_Allocation_CreatePickTasks: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_CreateTaskDetails') is not null
  drop Procedure pr_Allocation_CreateTaskDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_CreateTaskDetails: This procedure is used to create pick
    tasks details when a Wave is allocated. i.e. all the allocations that result
    from a wave being allocated are saved in TaskDetails with no TaskId. These
    details will be grouped together into tasks later.

    If every thing went well then we will define task sub type here based on the innerpacks.
    We have 3 task sub types here. LPNs, Cases and Units.
    LPN Type- If all the LPN qty is allocated for a task then we will treat that as LPN Pick.
      For example we have 5 innerpacks on the LPN and we have allocated 5 innerpacks then we will
      treat that as LPN Task.
    Case Type - If the  Qty on the LPN is not equall to Allcoated Qty in-terms of Cases.
       For example we have 5 innerpacks on the LPN.But we have allocated 4 ot less than 4 Innerpacks.
       then we will treat that as Case Pick.

    Unit Type Pick-  this just like units picks. Less than Innerpacks.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_CreateTaskDetails
  (@WaveId                TRecordId,
   @DetailsToCreateTasks  TTaskInfoTable readonly,
   @Operation             TOperation = null,
   @Warehouse             TWarehouse,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage,
          @vRecordId         TRecordId,

          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo,
          @vWaveType         TTypeCode,
          @vWaveNumUnits     TQuantity,
          @vNumPicksCreated  TCount,
          @vAccount          TAccount,

          @vPickType         TTypeCode,
          @vPrevPickType     TTypeCode,
          @vDestZone         TZoneId,
          @vDestLocation     TLocation,
          @vReplLocationType TTypeCode,
          @vIsTaskAllocated  TFlags,
          @vIsLabelGenerated TFlags,

          @vControlCategory  TCategory,
          @vOwnership        TOwnership,

          @xmlRulesData      TXML;

  declare @ttTaskInfo                TTaskInfoTable,
          @ttDetailsToCreateTasks    TTaskInfoTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @vNumPicksCreated  = 0;

  /* Get Wave Details */
  select @vWaveId          = RecordId,
         @vWaveNo          = BatchNo,
         @vWaveType        = BatchType,
         @vControlCategory = 'PickBatch_' + BatchType,
         @vWaveNumUnits    = NumUnits,
         @vAccount         = Account,
         @vOwnership       = Ownership
  from PickBatches
  where (RecordId = @WaveId);

  /* if caller passed in task info thru hash table then insert them into temp table to process further */
  if (object_id('tempdb..#TaskInfo') is not null) and
     (exists (select * from #TaskInfo))
    insert into @ttDetailsToCreateTasks (PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId,
                                         LPNDetailId, SKUId, UnitsToAllocate,
                                         DestZone, DestLocationId, DestLocation)
      select WaveId, WaveNo, OrderId, OrderDetailId, OrderType, LPNId,
             LPNDetailId, SKUId, UnitsToAllocate,
             DestZone, DestLocationId, DestLocation
      from #TaskInfo;
  else
    /* Get task info from input table variable */
    insert into @ttDetailsToCreateTasks (PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId,
                                         LPNDetailId, SKUId, UnitsToAllocate,
                                         DestZone, DestLocationId, DestLocation)
      select PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId,
             LPNDetailId, SKUId, UnitsToAllocate,
             DestZone, DestLocationId, DestLocation
      from @DetailsToCreateTasks;

  /* insert into tempo table from the input here as input table cannot be modified */
  insert into @ttTaskInfo(PickBatchId, PickBatchNo, OrderId, OrderDetailId, OrderType, LPNId,
                          LPNDetailId, UnitsToAllocate, SKUId, InnerPacks,
                          PickPath, TotalWeight, TotalVolume, UnitWeight, UnitVolume,
                          DestZone, TempLabelId, TempLabel, CartonType)
    exec pr_Allocation_SumPicksFromSameLocation @ttDetailsToCreateTasks, @vWaveId;

  /* Update the temptable here with the additional info that is required */
  update TI
  /* For LPN Picks consider one LPN as one Innerpack */
  set Innerpacks   = case when (LOC.LocationType <> 'K'/* Picklane */) and (L.Quantity = TI.UnitsToAllocate) and (L.PickingClass in ('FL' /* Full LPN */,'PL' /* Partial LPN */, 'OL' /* Open LPN */)) then 1
                          when LOC.StorageType = 'U' /* Units */  then 0
                          else coalesce(LD.InnerPacks, 0)
                     end,
      LocationId   = LOC.LocationId,
      Location     = LOC.Location,
      LocationType = coalesce(LOC.LocationType, ''),
      StorageType  = LOC.StorageType,
      Warehouse    = L.DestWarehouse,
      Ownership    = L.Ownership,
      PickPath     = LOC.PickPath,
      PickZone     = coalesce(LOC.PickingZone, ''),
      DestZone     = coalesce(TI.DestZone, '*'),
      CartonType   = L.CartonType,
      PickType     = Case
                      when (LOC.LocationType <> 'K'/* Picklane */) and (L.Quantity = TI.UnitsToAllocate) and (L.PickingClass in ('FL' /* Full LPN */,'PL' /* Partial LPN */, 'OL' /* Open LPN */))
                        then  'L' /* LPN */
                      when (L.PickingClass in ('LP' /* LPN Pick */))
                        then  'L' /* LPN */
                      when (LOC.LocationType = 'K' /* picklane */) and (LOC.StorageType = 'P' /* Packages */)
                        then 'CS' /* Cases */
                      when (LOC.LocationType = 'K' /* Picklane */) and (left(LOC.StorageType, 1) = 'U' /* Units */)
                        then 'U' /* Units */
                      when (LOC.LocationType <> 'K'/* Picklane */) and (L.InnerPacks >= LD.InnerPacks) and (coalesce(LD.InnerPacks, 0) > 0) --In the perfect world, we will never have more case on lpndetails than the LPN.
                        then 'CS' /* Cases */
                      when (coalesce(LD.InnerPacks, 0) < 1)
                        then 'U' /* Units */
                      when  (coalesce(LD.InnerPacks, 0) >= 1)
                        then 'CS' /* Cases */
                      else
                        'U' /* Units */
                    end
  from @ttTaskInfo  TI
  --left outer join SKUs         S   on  (TI.SKUId         = S.SKUId)
    left outer join LPNs         L   on  (TI.LPNId         = L.LPNId)
    left outer join LPNDetails   LD  on  (TI.LPNDetailId   = LD.LPNDetailId)
    left outer join Locations    LOC on  (L.LocationId     = LOC.LocationId);

  /* We need to create a separate task for the LPN Pick Type or Each picklane location */
  /* if the task is LPN pick and Order is Replenish Order and replenish location
     is case storage then we need to update status as ReadyToPick else onhold */
  if (@vWaveType in ('RU', 'RP', 'R' /* Replenish Orders */))
    begin
      update TI
      set DestLocation     = LOC.Location,
          DestZone         = LOC.PutawayZone,
          DestLocationType = LOC.LocationType
      from @ttTaskInfo TI
        left outer join OrderDetails OD  on (TI.OrderDetailId  = OD.OrderDetailId)
        left outer join Locations    LOC on (OD.DestLocationId = LOC.LocationId)
    end

  /* Insert task Details now, will process them later */
  insert into TaskDetails(TaskId, Status, PickType, WaveId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId, SKUId,
                          LocationId, InnerPacks, Quantity, PickZone, DestZone, DestLocation,
                          TempLabelId, TempLabel, TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
                          BusinessUnit, CreatedBy)
    select 0, 'NC'/* Not Categorized */, PickType, PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId, SKUId,
           LocationId, InnerPacks, UnitsToAllocate, PickZone, DestZone, DestLocation,
           TempLabelId, TempLabel, TDCategory1, TDCategory2, TDCategory3, TDCategory4, TDCategory5,
           @BusinessUnit, @UserId
    from @ttTaskInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_CreateTaskDetails */

Go
