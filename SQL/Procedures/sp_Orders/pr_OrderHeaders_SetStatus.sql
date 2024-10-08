/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/28  VS      pr_OrderHeaders_SetStatus: Bulk Order should mark as Picked after Pick all allocated Units (BK-410)
  2021/07/02  AY      pr_OrderHeaders_SetStatus: Evaluate Transfer Order status based upon remaining units to ship (HA-2959)
  2021/05/14  VS/AY   pr_OrderHeaders_SetStatus: Should not consider PickedLPNCount and LPNCount for Picked status (BK-334)
  2021/04/20  TK      pr_OrderHeaders_Recount & pr_OrderHeaders_SetStatus:
  2021/03/26  PK      pr_OrderHeaders_SetStatus: Do not override estimated values if nothing is allocated (HA-GoLive)
  2021/03/25  OK      pr_OrderHeaders_SetStatus: Considered new temp lpns as well to consider Order as packed (HA-2434)
  2021/03/06  OK      pr_OrderHeaders_SetStatus: Changes to calculate the PackingComplete status by control variable (HA-2095)
  2021/03/05  PK      pr_OrderHeaders_SetStatus: Ported changes done by Pavan (HA-2152)
  2020/12/18  VS      pr_OrderHeaders_SetStatus: Update the proper status on the Order for Bulk Order (HA-1812)
  2020/10/30  RKC     pr_OrderHeaders_SetStatus: Made changes to calculate the correct status (HA-1610)
  2020/08/18  SK      pr_OrderHeaders_SetStatus: Added logic to populate TotalShipmentValue for Orders (HA-1267)
  2020/06/16  RKC     pr_OrderHeaders_SetStatus: Removed the considering ToBeReservedLineCount in Order type not equal to B (HA-960)
  2019/05/13  TK      pr_OrderHeaders_SetStatus: When bulk order is picked and dropped for DTS wave, system will transfer inventory to DTS Picklane,
                      pr_OrderHeaders_SetStatus: Make/Break Kit orders should always be picked unless it is closed (S2GCA-570) (S2GCA-586)
  2018/09/29  AY      pr_OrderHeaders_SetStatus: Changed calculation of NumCases to include any status (S2GCA-306)
  2018/09/29  RT      pr_OrderHeaders_SetStatus: Added New temp and Picking status for Numcases count,
  2018/08/06  AY      pr_OrderHeaders_SetStatus: Update TotalSalesAmount with actual value shipped (OB2-466)
  2018/08/01  TK      pr_OrderHeaders_SetStatus: Consider units being packed as picked units (OB2-455)
  2017/07/18  KL      pr_OrderHeaders_SetStatus: Bug fix to update BulkOrder Status properly (SRI-808)
  2017/07/04  OK      pr_OrderHeaders_SetStatus: Restrict to not revert the status for Cancelled, Completed, Shipped orders.
  2017/03/14  YJ      pr_OrderHeaders_SetStatus: Added changes to update ShippedDate column (HPI-1409)
  2016/10/29  VM      pr_OrderHeaders_SetStatus: Temporarily consider 'Picking' status order also to be marked as 'Packed' if all units packed (HPI-957)
  2016/08/26  AY      pr_OrderHeaders_SetStatus: Intialize NumLines (HPI-529)
  2016/07/16  TK      pr_OrderHeaders_SetStatus: Bug fix to update Order Status to packed when all picked units are packed
  2015/12/30  DK      pr_OrderHeaders_SetStatus: Bug fix to update Order status as Waved when all the LPN related to order are Unallocated (FB-569).
  2015/12/03  RV      pr_OrderHeaders_SetStatus: Replenish Order not being marked as Completed after putaway all units (FB-517)
  2015/05/10  AY      pr_OrderHeaders_SetStatus: Order not being marked as Packed appropriately.
  2015/03/23  TK      pr_OrderHeaders_SetStatus: Exclude LPN Detail quantities if OnHandStatus is Directed.
  2015/03/03  DK      pr_OrderHeaders_SetStatus: Modified to validate BulkOrderId.
  2015/01/22  TK      pr_OrderHeaders_SetStatus: Removed 'In Progress' status
  2015/01/07  VM      Procedure pr_OrderHeaders_SetStatus: Fix - Get NumUnits as UnitsPicked
  2014/09/11  AY      pr_OrderHeaders_SetStatus: Corrections as the counts would be off if there were multiple SKU LPNs
  2014/08/17  AY      pr_OrderHeaders_SetStatus: Setup for Loaded status on Orders
  2014/07/09  TD      pr_OrderHeaders_SetStatus:Updating Bulk Pick Ticket Status as picked if all the units are picked.
                      pr_OrderHeaders_SetStatus: Fixed the issue of updating Order status.
  2014/01/16  PK      pr_OrderHeaders_Recount: Calling pr_OrderHeaders_SetStatus after order recounting to update the status.
  2013/12/20  AY      pr_OrderHeaders_SetStatus: Changed to compute and use UnitsPicked to determine if Order is
  2103/10/23  TD      pr_OrderHeaders_SetStatus:Small fix to update batch status from batched to inprogress.
  2013/09/16  PK      pr_OrderHeaders_AddOrUpdate, pr_OrderHeaders_SetStatus: Changes related to the change of Order Status Code.
  2012/10/06  TD      pr_OrderHeaders_SetStatus: Calling pr_Shipment_SetStatus proc to update shipment status
  2012/08/17  AY      pr_OrderHeaders_SetStatus: Support pre-allocating of LPNs against orders.
  2012/07/05  AY      pr_OrderHeaders_SetStatus: Use LPN counts to determine status
  2011/11/29  PK      pr_OrderHeaders_SetStatus : Do not consider OrderLine of type 'F' (Fees line) to calculate Status
  2011/10/15  NB      pr_OrderHeaders_SetStatus: Update Status to Packed.
  2011/10/02  AY      pr_OrderHeaders_SetStatus: Update Status to Completed/Shipped as applicable.
  2011/01/23  AY      Migrated from RFConnect pr_OrderHeaders_SetStatus,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_SetStatus') is not null
  drop Procedure pr_OrderHeaders_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_SetStatus:
    This procedure is used to change/set the 'Status' of the Order. At present
      the procedure is very limited to work with the Statuses used in the
      implemenation of RFConnect with AX.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it calculates the status updates.

   Options: D - Recompute Order detail counts, L - Recompute LPN counts

   StatusCalcMethod: There is question on when we want to consider an order to
     be considered as packed. We have several choices and it may change from
     customer to customer and hence we use a control var whose values are
     UnitsToShip: Means we consider the Order as packed when all units are packed
                  i.e. if Order is for 100 units, then all 100 have to be packed
     UnitsAllocated: Means we consider the Order as packed if all allocated units
                     are packed. this is the default
     ShipCompletePercent: We consider order as packed when atleast the shipcomplete
                          percent units have been packed. i.e. if Total To Ship
                          units is 150 and shipment percent is 75% then at least 112.5
                          or 113 unit are packed.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_SetStatus
  (@OrderId      TRecordId,
   @Status       TStatus = null output,
   @UserId       TUserId = null,
   @Options      TFlags  = 'DL',
   @Debug        TFlags  = null) -- future use
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription,

          @vBulkOrderId                TRecordId,
          @vOrderType                  TOrderType,
          @vPickBatchNo                TPickBatchNo,
          @vReservedLineCount          TCount,
          @vToBeReservedLineCount      TCount,
          @vBatchedLineCount           TCount,
          @vTotalLineCount             TCount,
          @vUnitsAuthorizedToShip      TQuantity,
          @vUnitsAssigned              TQuantity,
          @vUnitsAssignedToShip        TQuantity,
          @vUnitsAllocated             TQuantity,
          @vUnitsPutaway               TQuantity,
          @vUnitsNewTemp               TQuantity,
          @vUnitsPicked                TCount,
          @vUnitsPacked                TCount,
          @vUnitsShipped               TQuantity,
          @vUnitsPreallocated          TQuantity,
          @vUnitsToAllocate            TQuantity,
          @vShipmentValue              TMoney,
          @vShippedValue               TMoney,
          @vNumCasesCount              TCount,
          @vOrderThresholdUnits        TInteger,
          @vShipCompletePercent        TPercent,

          /* LPN Counts */
          @vLPNsAssigned               TCount,
          @vLPNToBePackedCount         TCount,
          @vLPNLoadedCount             TCount,
          @vLPNStagedCount             TCount,
          @vLPNPickedCount             TCount,
          @vLPNAllocatedCount          TCount,
          @vLPNPutawayCount            TCount,
          @vLPNNewTempCount            TCount,

          @vLPNCount                   TCount,
          @vLPNInTransitCount          TCount,

          @vPickedLPNsCount            TCount,
          @vPackedLPNsCount            TCount,
          @vStagedLPNsCount            TCount,
          @vLoadedLPNsCount            TCount,
          @vShippedLPNsCount           TCount,

          @vPickedUnits                TCount,
          @vPackedUnits                TCount,
          @vStagedUnits                TCount,
          @vLoadedUnits                TCount,
          @vShippedUnits               TCount,

          @vFulfilledLines             TCount,
          @vNumLines                   TCount,
          @vTotalWeight                TWeight,
          @vTotalVolume                TVolume,

          @vPackingComplete            TFlag,
          @vDebug                      TFlag = 'N',

          /* Controls */
          @vOrderTypesToShip           TControlValue,
          @vOrderTypesToComplete       TControlValue,
          @vIsMultipleShipmentOrder    TControlValue,
          @vStatusCalcMethod           TControlValue,

          /* Loads/Shipment Related */
          @vPrevOrderStatus            TStatus,
          @vShipmentId                 TShipmentId,
          @OrderShipments              TEntityKeysTable,
          @vShipmentCount              TCount,
          @vCount                      TInteger,
          @vBusinessUnit               TBusinessUnit,

          @ttLPNCounts                 TEntityStatusCounts;

  declare @ttOrderDetails table (OrderDetailId          TRecordId,
                                 LineType               TTypeCode,
                                 PickBatchNo            TPickBatchNo,
                                 UnitWeight             TWeight,
                                 UnitVolume             TVolume,
                                 UnitsShipped           TQuantity,
                                 UnitSalePrice          TUnitPrice,
                                 UnitsAssigned          TQuantity,
                                 UnitsToAllocate        TQuantity,
                                 UnitsPreallocated      TQuantity,
                                 UnitsAuthorizedToShip  TQuantity);
begin
  SET NOCOUNT ON;

  select @ReturnCode             = 0,
         @MessageName            = null,
         @vUnitsAuthorizedToShip = null,
         @vUnitsShipped          = null,
         @vShipmentCount         = 0;

  select @vBusinessUnit        = BusinessUnit,
         @vOrderType           = OrderType,
         @vPickBatchNo         = PickBatchNo,
         @vPrevOrderStatus     = Status,
         @vNumLines            = NumLines,
         @vShipCompletePercent = ShipCompletePercent
  from OrderHeaders
  where (OrderId = @OrderId);

  /* if the order is already shipped then we do not need to do any thing to that order */
  if (@vPrevOrderStatus in ('S' /* Shipped */, 'X' /* Cancelled */, 'D' /* Complete */))
    begin
      set @Status = @vPrevOrderStatus;
      goto ExitHandler;
    end

  select @vOrderTypesToShip        = dbo.fn_Controls_GetAsString('OrderClose', 'Ship', 'CET'/* Customer, Ecom, Transfer */, @vBusinessUnit, null/* UserId */),
         @vOrderTypesToComplete    = dbo.fn_Controls_GetAsString('OrderClose', 'Complete', 'O'/* Out reserve */, @vBusinessUnit, null/* UserId */),
         @vIsMultipleShipmentOrder = dbo.fn_Controls_GetAsString('OrderClose', 'IsMultiShipmentOrder', 'Y'/* Yes */, @vBusinessUnit, null/* UserId */),
         @vStatusCalcMethod        = dbo.fn_Controls_GetAsString('OrderClose', 'StatusCalcMethod', 'UnitsAllocated', @vBusinessUnit, null/* UserId */);

  /* Identify if the Order belongs to a Bulk Pick Batch */
  select @vBulkOrderId = null;
  select @vBulkOrderId = OrderId
  from OrderHeaders
  where ((PickBatchNo = @vPickBatchNo) and (OrderType = 'B' /* Bulk Pull*/));

  /* Calculate Status, if not provided */
  if (@Status is null)
    begin
      /* Currently we do not have an option anymore to split an order into multiple waves, so use the OH.PickbatchNo - AY - 2020/06/16 */
      insert into @ttOrderDetails(OrderDetailId, LineType, PickBatchNo, UnitWeight, UnitVolume, UnitsShipped,
                                  UnitSalePrice, UnitsAssigned, UnitsToAllocate, UnitsPreallocated, UnitsAuthorizedToShip)
        select OD.OrderDetailId, OD.LineType, @vPickBatchNo, S.UnitWeight, S.UnitVolume, OD.UnitsShipped,
               coalesce(nullif(OD.UnitSalePrice, 0), nullif(S.UnitPrice, 0)), OD.UnitsAssigned, OD.UnitsToAllocate, OD.UnitsPreallocated, OD.UnitsAuthorizedToShip
        from OrderDetails OD
          join SKUs         S on (OD.SKUId = S.SKUId)
        where (OD.OrderId = @OrderId);

      /* Calculate the Onhandstatus counts of each status */
      select @vReservedLineCount          = sum(case when UnitsAssigned > 0  then 1 else 0 end),
             @vToBeReservedLineCount      = sum(case when ((UnitsAssigned < UnitsAuthorizedToShip) and (coalesce(LineType, '') <> 'F'/* Fees */)) then 1 else 0 end),
             @vUnitsAuthorizedToShip      = sum(UnitsAuthorizedToShip),
             @vUnitsAssigned              = sum(UnitsAssigned),
             @vUnitsShipped               = sum(UnitsShipped),
             @vUnitsToAllocate            = sum(UnitsToAllocate),
             @vBatchedLineCount           = sum(case when PickBatchNo is not null then 1 else 0 end),
             @vTotalLineCount             = count(*),
             @vFulfilledLines             = sum(case when UnitsAssigned >= UnitsPreallocated then 1 else 0 end),
             @vUnitsPreallocated          = sum(UnitsPreallocated),
             @vNumLines                   = count(distinct OrderDetailId),
             @vShipmentValue              = sum(UnitsAssigned * UnitSalePrice),
             @vShippedValue               = sum(coalesce(UnitsShipped, 0) * UnitSalePrice),
             @vTotalWeight                = sum(UnitsAssigned * UnitWeight),
             @vTotalVolume                = sum(UnitsAssigned * UnitVolume)
      from @ttOrderDetails;

      /* Orders can be shipped across several shipments and once shipped, they would not be associated
         with the Order anymore, like for transfers, so we have to disregard the units previously
         shipped when calculating status for Transfers */
      select @vUnitsAssignedToShip = case when @vOrderType = 'T' then dbo.fn_MaxInt(@vUnitsAssigned - @vUnitsShipped, 0)
                                          else @vUnitsAssigned
                                     end;

      /* Check if everything for this order has been picked and packed.
         NumCases: Consider NumCases as 1 if in case
         - TotalNumLines of LPN is more than 1 or LPN SKU is of non-innerpack */
      insert into @ttLPNCounts(Entity, EntityStatus, NumLPNs, NumEntities, NumCases, NumUnits)
        select 'LPN', L.Status,
               count(distinct (L.LPNId)),
               /* NumEntities is being used for Num ship Cartons */
               count (distinct (case when L.LPNType = 'S' then L.LPNId else null end)),
               /* NumCases = Num IPs of Solid Cases + Num Mixed LPNs */
               sum(case when (L.InnerPacks > 0) and L.NumLines = 1 then L.InnerPacks else 0 end) +
               count(distinct (case when L.NumLines > 1 then L.LPNId else null end)),
               sum(LD.Quantity)
        from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
        where (LD.OrderId = @OrderId) and  -- Partial Allocation in Replenish will update OrderId on LD's, so consider LD.OrderId
              (L.Status not in ('V', 'C' /* Voided, Consumed */)) and
              (LD.OnhandStatus <> 'D' /* Directed */)
        group by L.Status;

      /* Check if everything for this order has been picked and packed */
      select @vLPNToBePackedCount = sum(case when (L.EntityStatus not in ('D', 'E', 'L', 'S' /* Packed, Staged, Loaded, Shipped */)) then NumLPNs else 0 end),
             @vLPNLoadedCount     = sum(case when (L.EntityStatus in ('L' /* Loaded */)) then NumLPNs else 0 end),
             @vLPNStagedCount     = sum(case when (L.EntityStatus in ('E' /* Staged */, 'L' /* Loaded */)) then NumLPNs else 0 end),
             @vLPNPickedCount     = sum(case when (L.EntityStatus not in ('F' /* New Temp */, 'P' /* Putaway */, 'A' /* Allocated */)) then NumLPNs else 0 end),
             @vUnitsPicked        = sum(case when (L.EntityStatus not in ('F' /* New Temp */, 'P' /* Putaway */, 'A' /* Allocated */)) then NumUnits else 0 end),
             @vUnitsPacked        = sum(case when (L.EntityStatus in ('G' /* Packing */, 'D' /* Packed */, 'E' /* Staged */, 'L' /* Loaded */, 'S' /* Shipped */)) then NumUnits else 0 end),
             @vLPNAllocatedCount  = sum(case when (L.EntityStatus in ('A' /* Allocated */)) then NumLPNs else 0 end),
             @vUnitsAllocated     = sum(case when (L.EntityStatus in ('A' /* Allocated */)) then NumUnits else 0 end),
             @vLPNPutawayCount    = sum(case when (L.EntityStatus in ('P' /* Putaway */))   then NumLPNs else 0 end),
             @vUnitsPutaway       = sum(case when (L.EntityStatus in ('P' /* Putaway */))   then NumUnits else 0 end),
             @vLPNNewTempCount    = sum(case when (L.EntityStatus in ('F' /* New Temp */))  then NumLPNs else 0 end),
             @vUnitsNewTemp       = sum(case when (L.EntityStatus in ('F' /* New Temp */))  then NumUnits else 0 end),
             @vLPNIntransitCount  = sum(case when (L.EntityStatus in ('T' /* Staged */))    then NumLPNs else 0 end),
             @vLPNCount           = sum(NumLPNs),
             /* To update the counts on the OH */
             /* LPN Status: K - Picked, G-Packing, D - Packed, E - Staged, L - Loaded, S - Shipped */
             @vNumCasesCount     = sum(NumCases),
             @vLPNsAssigned      = sum(NumEntities),
             @vPickedLPNsCount   = sum(case when (charindex(L.EntityStatus, 'KDELS') <> 0)  then NumLPNs  else 0 end),
             @vPackedLPNsCount   = sum(case when (charindex(L.EntityStatus, 'DELS') <> 0)   then NumLPNs  else 0 end),
             @vStagedLPNsCount   = sum(case when (charindex(L.EntityStatus, 'ELS') <> 0)    then NumLPNs  else 0 end),
             @vLoadedLPNsCount   = sum(case when (charindex(L.EntityStatus, 'LS') <> 0)     then NumLPNs  else 0 end),
             @vShippedLPNsCount  = sum(case when (charindex(L.EntityStatus, 'S') <> 0)      then NumLPNs  else 0 end),
             @vPickedUnits       = sum(case when (charindex(L.EntityStatus, 'KGDELS') <> 0) then NumUnits else 0 end),
             @vPackedUnits       = sum(case when (charindex(L.EntityStatus, 'DELS') <> 0)   then NumUnits else 0 end),
             @vStagedUnits       = sum(case when (charindex(L.EntityStatus, 'ELS') <> 0)    then NumUnits else 0 end),
             @vLoadedUnits       = sum(case when (charindex(L.EntityStatus, 'LS') <> 0)     then NumUnits else 0 end),
             @vShippedUnits      = sum(case when (charindex(L.EntityStatus, 'S') <> 0)      then NumUnits else 0 end)
      from @ttLPNCounts L;

      /* Read comments above on StatusCalcMethod */
      select @vOrderThresholdUnits = case when (@vStatusCalcMethod = 'UnitsToShip') then @vUnitsAuthorizedToShip
                                          when (@vStatusCalcMethod = 'ShipCompletePercent') then ceiling(@vUnitsAuthorizedToShip * @vShipCompletePercent/100)
                                          else @vUnitsAssignedToShip
                                     end;

      if (@vBulkOrderId is not null)
        begin
          select @vPackingComplete = Case
                                       when (@vUnitsPacked   > 0            ) and
                                            (@vUnitsPacked >= @vOrderThresholdUnits) and (@vUnitsNewTemp = 0) and
                                            (@vOrderType    <> 'B') then  /* We will not mark bulk order as packed */
                                         'Y' /* Completed */
                                       else
                                         'N' /* Not Completed */
                                     end;
        end
      else
        begin
          select @vPackingComplete = Case
                                       /* If LPNToBePackedCount is null, we still need to set  PackingComplete as 'N' */
                                       when coalesce(@vLPNToBePackedCount, 1) > 0 then
                                         'N' /* Not Completed */
                                       when (@vUnitsPacked >= @vOrderThresholdUnits) and (@vUnitsAssignedToShip > 0) then
                                         'Y' /* Completed */
                                       else
                                         'N'
                                     end;
        end
    end
  else
  if (@Status = 'S' /* Shipped */)
    begin
      /* If the Status is passed in then we won't compute any values but if the order is shipped
         then we need to update shipped counts on the order */
      select @vShippedUnits     = sum(LD.Quantity),
             @vShippedLPNsCount = count(distinct LD.LPNId)
      from LPNDetails LD
        join LPNs L on (LD.LPNId = L.LPNId)
      where (LD.OrderId = @OrderId) and
            (L.Status = 'S'/* Shipped */);

      select @vShippedValue = sum(OD.UnitsShipped * OD.UnitSalePrice)
      from OrderDetails OD
      where (OD.OrderId = @OrderId);
    end

  if (charindex('D', @Debug) > 0)
    begin
      /* Check if everything for this order has been picked and packed */
      select @vLPNsAssigned       LPNsAssigned,
             @vLPNToBePackedCount LPNsToBePacked,
             @vLoadedLPNsCount    LPNLoadedCount,
             @vStagedLPNsCount    LPNStagedCount,
             @vLPNPickedCount     LPNPickedCount,
             @vLPNAllocatedCount  LPNAllocatedCount,
             @vLPNPutawayCount    LPNPutawayCount,
             @vLPNNewTempCount    LPNNewTempCount,
             @vUnitsNewTemp       UnitsNewTemp,
             @vUnitsPutaway       UnitsPutaway,
             @vUnitsAllocated     UnitsAllocated,
             @vUnitsPicked        UnitsPicked,
             @vUnitsPacked        UnitsPacked,
             @vStagedUnits        StagedUnits,
             @vLoadedUnits        LoadedUnits,
             @vLPNIntransitCount  LPNsInTransit,
             @vLPNCount           LPNCount,
             @vPackingComplete    PackingComplete;

      select @vReservedLineCount       ReservedLineCount,
             @vToBeReservedLineCount   ToBeReservedLineCount,
             @vUnitsAuthorizedToShip   UnitsAuthorizedToShip,
             @vUnitsAssigned           UnitsAssigned,
             @vUnitsAssignedToShip     UnitsAssingedToShip,
             @vUnitsShipped            UnitsShipped,
             @vUnitsToAllocate         UnitsToAllocate,
             @vBatchedLineCount        BatchedLineCount,
             @vTotalLineCount          TotalLineCount;
    end

  /* Update Order Header */
  update OrderHeaders
  set @vPrevOrderStatus   = Status,  /* Get the Current Order Status */
      @Status             =
      Status              = case
                              /* We should not revert the status for Cancelled, Completed, Shipped orders */
                              when (charindex(Status, 'XDS' /* Cancelled, Completed, Shipped */) <> 0) then
                                Status
                              /* If status is already determined, then update with it only */
                              when (@Status is not null) then
                                @Status
                              when (Status = 'H' /* Pack & Hold */) then
                                'H' -- do not change
                              when (OrderType in ('MK' , 'BK' /* Make/Break Kits */)) and
                                   (Status in ('C' /* Picking */, 'P' /* Picked */)) and
                                   (coalesce(@vUnitsPicked, 0) >= @vUnitsAssigned) then
                                'P' /* Picked */
                              when (OrderType in ('RU' , 'RP', 'R' /* Replenish Orders */)) and
                                   (Status in ('C' /* Picking */, 'P' /* Picked */)) and
                                   (coalesce(@vLPNCount, 0) = 0) then
                                'D' /* Completed */
                              when (OrderType in ('B'/* Bulk Order */)) and
                                   (Status in ('C' /* Picking */, 'P' /* Picked */)) and
                                   (@vUnitsAuthorizedToShip = @vUnitsAssigned) and
                                  (coalesce(@vLPNCount, 0) = 0) then
                                'D' /* Completed */
                              when ((@vUnitsAuthorizedToShip = @vUnitsShipped) or
                                    ((@vIsMultipleShipmentOrder = 'Y' /* Yes */) and
                                     (@vUnitsAssigned = @vUnitsShipped))) and
                                   (@vUnitsShipped > 0) and
                                   (charindex(OrderType, @vOrderTypesToShip) <> 0) then
                                'S' /* Shipped */
                              when (@vUnitsAuthorizedToShip = @vUnitsShipped) and
                                   (@vUnitsShipped > 0) and
                                   (charindex(OrderType, @vOrderTypesToComplete) <> 0) then
                                'D' /* Completed */
                              when (@vLPNCount > 0) and
                                   (@vLPNCount = @vLPNLoadedCount) and
                                   (@vUnitsAssignedToShip = @vLoadedUnits) then
                                'L' /* Loaded */
                              when (@vLPNCount > 0) and
                                   (@vLPNCount = @vLPNStagedCount) and
                                   (@vUnitsAssignedToShip = @vStagedUnits) then
                                'G' /* Staged */
                              /* All allocated units are packed */
                              when (@vLPNCount > 0) and
                                   (@vPackingComplete = 'Y' /* Yes */) then
                                'K' /* Packed */
                              /* for Bulk PT, we will pick the multiple picks into same tote/LPN.
                                 So we have multiple lines with same LPN */
                              when (OrderType = 'B' /* Bulk Order */) and
                                   (@vUnitsAssigned > 0) and
                                   --(charindex(Status, 'NPWACG') <> 0) and
                                   --(@vToBeReservedLineCount = 0) and /* Bulk order may allocated partially so we need exclude this condition */
                                   (@vUnitsPicked = @vUnitsAssigned) then
                                'P' /* Picked */
                              when (OrderType <> 'B' /* Bulk Order */) and
                                   (@vUnitsAssigned > 0) and
                                   --(@vToBeReservedLineCount = 0) and
                                   --(@vPickedLPNsCount = @vLPNCount) and
                                   (@vPickedUnits = @vUnitsAssignedToShip) then
                                'P' /* Picked */
                              /* Initial, Waved, Allocated/To-Pick and now there is a reservation
                                 against it, then consider it to have started Picking */
                              when --(charindex(Status, 'NWACPG') <> 0) and
                                   (@vReservedLineCount > 0) and
                                   (@vLPNPickedCount > 0) then
                                'C' /* Picking */
                              /* Status can be in marked as Allocated, when prior status is New/Waved */
                              when (charindex(Status, 'NW') <> 0) and
                                   (((@vUnitsPicked <> @vUnitsAssigned) and (@vUnitsAssigned > 0))
                                   or
                                   ((@vLPNInTransitCount > 0) and (@vToBeReservedLineCount = 0))) then
                                'A' /* Allocated */
                              /* There are lines and all lines are Waved, set status to Waved */
                              when (@vTotalLineCount > 0) and (@vBatchedLineCount = @vTotalLineCount) and
                                   (@vUnitsAssigned = 0) then
                                'W' /* Waved */
                              /* If there are no batched lines and order not in downloaded status, then set status to New */
                              when  (@vBatchedLineCount = 0) and (Status <> 'O' /* Downloaded */) then
                                'N' /* New */
                            else
                              Status /* No Change */
                            end,
      ShippedDate         = case when (@Status = 'S') then current_timestamp else ShippedDate end,
      ModifiedDate        = current_timestamp,
      ModifiedBy          = coalesce(@UserId, System_User),
      TotalSalesAmount    = case when (@Status = 'S') then @vShippedValue else TotalSalesAmount end,
      TotalShipmentValue  = coalesce(@vShipmentValue, TotalSalesAmount), /* If no units are assigned should be equal to sales amount */
      NumCases            = coalesce(@vNumCasesCount, NumCases),
      LPNsAssigned        = coalesce(@vLPNsAssigned,    LPNsAssigned),
      LPNsPicked          = coalesce(@vPickedLPNsCount, LPNsPicked),
      LPNsPacked          = coalesce(@vPackedLPNsCount, LPNsPacked),
      LPNsStaged          = coalesce(@vStagedLPNsCount, LPNsStaged),
      LPNsLoaded          = coalesce(@vLoadedLPNsCount, LPNsLoaded),
      LPNsShipped         = coalesce(@vShippedLPNsCount, LPNsShipped),
      UnitsPicked         = coalesce(@vPickedUnits, UnitsPicked),
      UnitsPacked         = coalesce(@vPackedUnits, UnitsPacked),
      UnitsStaged         = coalesce(@vStagedUnits, UnitsStaged),
      UnitsLoaded         = coalesce(@vLoadedUnits, UnitsLoaded),
      /* For transfer orders when shipped we will clear order info on the LPNs, so use UnitsShipped from order details */
      UnitsShipped        = case when @vOrderType = 'T' /* Transfer */ then coalesce(@vUnitsShipped, UnitsShipped)
                                 else coalesce(@vShippedUnits, UnitsShipped)
                            end,
      TotalWeight         = coalesce(nullif(@vTotalWeight, 0), TotalWeight),
      TotalVolume         = coalesce(nullif(@vTotalVolume, 0) * 0.000578704, TotalVolume)
  where (OrderId = @OrderId);

  /* Re-calculate Shipment Status here..*/

  /* In future need to handle it from controls */
  /* Check if the OrderStatus has changed or not. */
  /* P-Packed, L-Loaded, R-ReadyToShip, S-Shipped, D-Completed */
  if ((@vPrevOrderStatus <> @Status) and (charindex(@Status, 'KGLRS') <> 0))
    begin
       /* Get ShipmentId From OrderShipments based on the given OrderId */
       /* Get Shipments here */
       insert into @OrderShipments(EntityId)
       select ShipmentId
       from OrderShipments
       where (OrderId = @OrderId);

       set @vShipmentCount = @@rowcount; /* It will gives the last RecordId */

       if (@vShipmentCount > 0)
         begin   /* if the Order is on one shipment then we need to get that Id.*/
            set @vCount = 1;
            while (@vCount <= @vShipmentCount)
              begin
                 select @vShipmentId = EntityId
                 from @OrderShipments
                 where (RecordId = @vCount);

                 /* Call Shipment set status Proc here...*/
                 if (@vShipmentId is not null)
                   exec pr_Shipment_SetStatus @vShipmentId;

                 set @vCount = @vCount + 1;
              end
         end
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_OrderHeaders_SetStatus */

Go
