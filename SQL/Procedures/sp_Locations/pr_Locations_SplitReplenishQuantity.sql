/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/02  TK      pr_Locations_SplitReplenishQuantity: Added Lock to deny updates until the transaction is completed (CID-1508)
  2020/07/29  VS      pr_Locations_SplitReplenishQuantity: Made changes to improve the Performance (S2GCA-1211)
  2019/08/28  AY      pr_Locations_SplitReplenishQuantity: Bug fix with loosing ReservedQty on D lines (CID-Support)
  2018/05/30  TK      pr_Locations_SplitReplenishQuantity: Update reserved qty when a new line is added (S2GCA-818)
  2018/03/21  AY      pr_Locations_SplitReplenishQuantity: Recompute dependencies on Replenish PA into Location.
  2018/03/15  TD      pr_Locations_SplitReplenishQuantity:Updating innerpacks on the lpndetails (S2G-432)
  2018/03/04  VM      pr_Locations_SplitReplenishQuantity: @vMessage => @vActivityLogMessage for consistency (S2G-344)
  2018/02/13  TK      pr_Locations_SplitReplenishQuantity: Changes to update Reserved Qty on reserved Lines (S2G-152)
  2017/09/27  TK      pr_Locations_SplitReplenishQuantity: Changes to swap replenish orders on the D lines (HPI-1676)
  2017/09/13  TK      pr_Locations_SplitReplenishQuantity: Changes to consider DR lines first and then D lines while putaway replenish LPN (HPI-1672)
  2017/07/14  RV      pr_Locations_SplitReplenishQuantity: Send ProdId to pr_ActivityLog_LPN (HPI-1584)
  2017/06/14  OK      pr_Locations_SplitReplenishQuantity: Enhanced to prevent wrong updates if multiple transactions are started at same time (GNC-1540)
  2017/03/22  AY/VM   pr_Locations_SplitReplenishQuantity: Bug fix causing inventory variance (GNC)
  2017/03/09  VM      pr_Locations_SplitReplenishQuantity: Split Task detail and ToLPN detail as well when there is no R line on FromLPN (HPI-1447)
  2017/03/04  VM      pr_Locations_SplitReplenishQuantity: Made changes to call the new procedure pr_TasksDetails_TransferUnits,
  2017/02/23  VM      pr_Locations_SplitReplenishQuantity: Variable names corrected to be self explanatory (HPI-1415)
  2016/12/09  VM      pr_Locations_SplitReplenishQuantity:
  2016/10/05  AY      pr_Locations_SplitReplenishQuantity: Added new param to satisfy the PA LPN replenish order lines first and then remaining later (HPI-GoLive)
              AY/VM   pr_Locations_SplitReplenishQuantity: Change of priority in releasing lines (HPI-GoLive)
  2016/09/20  AY      pr_Locations_SplitReplenishQuantity: Relieve the replenish qty as much as possible
              SV      pr_Locations_SplitReplenishQuantity: Added AT upon splitting the Replenish lines during putaway (HPI-684)
  2016/09/18  VM      pr_Locations_SplitReplenishQuantity: Delete ToSplit Line like in GNC (HPI-GoLive)
  2016/09/17  VM      pr_Locations_SplitReplenishQuantity:
  2016/09/16  VM      pr_Locations_SplitReplenishQuantity: Transfer ReplenishOrder details to DR line from ToSplit line (HPI-GoLive)
  2016/09/15  VM      pr_Locations_SplitReplenishQuantity: Corrected activity logging (HPI-GoLive)
  2016/08/11  SV      pr_Locations_SplitReplenishQuantity: Added AT upon converting the Directed line to Reserved line (HPI-458)
  2016/08/05  PK      pr_Locations_SplitReplenishQuantity: Merging TaskDetails and TempLPN details if there are any duplicates.
  2016/08/02  SV      pr_Locations_SplitReplenishQuantity: Resolved the issue with unique constraint - Migration from NBD (HPI-405)
  2016/03/28  TK      pr_Locations_SplitReplenishQuantity: Enhanced to Log Activity (NBD-314)
  2016/03/10  TK      pr_Locations_SplitReplenishQuantity: Bug fixes migrated from GNC (NBD-274)
  2014/06/08  TD      Added pr_Locations_SplitReplenishQuantity.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_SplitReplenishQuantity') is not null
  drop Procedure pr_Locations_SplitReplenishQuantity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_SplitReplenishQuantity: When Replenishment is triggered the
    Logical LPN would have Directed Qty. Later, this directed qty may be allocated
    against for different waves/orders. When inventory has been putaway to the location,
    then these Directed/Directed Reserve Lines should be updated to reflect the
    new inventory. Directed Reserved would be changed to Reserved and Directed
    would be changed to Available. However, it is not as simple as that as the
    qty Putaway may not be exact match of these lines and hence the lines may be split

  Example 1: If an LPN were to have the following details
  Loc1 - 10 units - Directed
          2 units - Directed Reserved
  and an LPN of 12 has been putaway into the location then these lines would be
  changed to 10 Units - Available, 2 Units Reserved.

------------------------------------------------------------------------------*/
Create Procedure pr_Locations_SplitReplenishQuantity
  (@SKUId                TRecordId,
   @LocationId           TRecordId,
   @InnerPacks           TInnerPacks,
   @Quantity             TQuantity,
   @ReplenishOrderId     TRecordId,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId)
as
  declare @ReturnCode                  TInteger,
          @MessageName                 TMessageName,
          @Message                     TDescription,
          @vLDActivityLogId            TRecordId,
          @vTDActivityLogId            TRecordId,
          @vActivityLogMessage         TDescription,
          @vActivityType               TActivityType,

          @vAvlbLPNDetailId            TRecordId,
          @vLPNId                      TRecordId,
          @vLPN                        TLPN,
          @vLocationId                 TRecordId,
          @vLocStorageType             TTypeCode,

          @vLDQty                      TQuantity,
          @vLDReservedQty              TQuantity,
          @vLPNDetailIdToProcess       TRecordId,
          @vOrderId                    TRecordId,
          @vOrderDetailId              TRecordId,
          @vReplenishOrderId           TRecordid,
          @vReplenishOrderDetailId     TRecordId,

          @vNote2                      TDescription,
          @vLDOnhandStatus             TStatus,
          @vSplitDRLDId                TRecordId,
          @vReservedLineOrderDetailId  TRecordId,
          @vReservedLineLPNDetailId    TRecordId,
          @vPrevDRQty                  TQuantity,
          @vIPsToUpdate                TQuantity,
          @vQtyToUpdate                TQuantity,
          @vReservedQtyToUpdate        TQuantity,
          @vProcessingQty              TQuantity,
          @vLPNPrevQuantity            TQuantity,
          @vNewLineIPs                 TQuantity,
          @vNewLineQty                 TQuantity,
          @vLPNMaxLine                 TInteger,
          @vTaskDetailId               TRecordId,
          @vInnerPacks                 TInnerPacks,

          @vUnitsPerIP                 TQuantity;

  declare @ttLPNDetails Table
          (RecordId                TRecordId Identity(1,1),
           LPNId                   TRecordId,
           LPNDetailId             TRecordId,
           OrderId                 TRecordId,
           OrderDetailId           TRecordId,
           ReplenishOrderId        TRecordId,
           ReplenishOrderDetailId  TRecordId,
           Quantity                TQuantity,
           ReservedQty             TQuantity,
           OnHandStatus            TStatus,
           Primary Key             (RecordId));
begin
  SET NOCOUNT ON;

  select @Quantity            = coalesce(@Quantity, 0),
         @InnerPacks          = coalesce(@InnerPacks, 0),
         @vAvlbLPNDetailId    = 0,
         @vActivityLogMessage = 'RepOrderId: ' + cast(coalesce(@ReplenishOrderId, '0') as varchar) + ', Qty: ' + cast(@Quantity as varchar),
         @vProcessingQty      = @Quantity;  /* we are updating input param, so get the quantity to diff variable before updates */

  select @vLPNId           = L.LPNId,
         @vLPN             = L.LPN,
         @vLPNPrevQuantity = L.Quantity,
         @vLocationId      = LOC.LocationId,
         @vLocStorageType  = LOC.StorageType
  from LPNs L
    join Locations LOC on (L.LocationId = LOC.LocationId)
  where (L.LocationId = @LocationId) and
        (L.SKUId      = @SKUId);

  /* get the available line from LPNDetails */
  select @vAvlbLPNDetailId = LPNDetailId,
         @SKUId            = coalesce(@SKUId, SKUId),
         /* Units Per IP will be from the Available line on the Location. However, if Location is empty
            we would compute the UnitsPerIP from the LPN being PA into the location */
         @vUnitsPerIP      = case when InnerPacks > 0 then UnitsPerPackage
                                  when @InnerPacks > 0 then @Quantity/@InnerPacks
                                  else 0
                             end
  from LPNDetails
  where (LPNId        = @vLPNId) and
        (OnhandStatus = 'A' /* Available */) and
        (Quantity     >= 0) and
        (OrderId is null);

  /* Get the LPN details that are directed or Directed reserved that need to be processed. The release of
     the D and DR lines should follow some sequence and here is the logic.

     First prioritize the orders to release DR and then Directed and within that, release the ones
     which are related to the Replenish that is being putaway followed by others.

     Here is the order of prioirty of release
     1. DR lines of the PA LPN replenish order
     2. Orphan DR lines (which do not relate to any replenish order)
     3. D lines of the PA LPN replenish order
     4. if over replenishment, then DR lines of other replenishments as well
     5. Orphan D lines (which do not relate to any replenish order)
     6. D lines of other replenish orders
  */
  insert into @ttLPNDetails(LPNId, LPNDetailId, OrderId, OrderDetailId, ReplenishOrderId, ReplenishOrderDetailId,
                            Quantity, ReservedQty, OnhandStatus)
    select LD.LPNId, LD.LPNDetailId, LD.OrderId, LD.OrderDetailId, LD.ReplenishOrderId, LD.ReplenishOrderDetailId,
           LD.Quantity, LD.ReservedQty, LD.OnhandStatus
    from LPNDetails LD with (UPDLOCK)  -- Do not allow any updates untill transaction is completed
      left outer join OrderHeaders OH on LD.OrderId    = OH.OrderId
      left outer join PickBatches PB on OH.PickBatchNo = PB.BatchNo
    where (LD.LPNId  = @vLPNId) and
          (LD.OnhandStatus in ('DR', 'D' /* Directed Reserved, Directed */)) and
          (LD.Quantity > 0)
    order by case
               when (LD.OnhandStatus = 'DR') and (LD.ReplenishOrderId = @ReplenishOrderId)  then '1'
               when (LD.OnhandStatus = 'DR') and (LD.ReplenishOrderId is null)              then '2'
               when (LD.OnhandStatus = 'DR') and (LD.ReplenishOrderId is not null)          then '3'
               when (LD.OnhandStatus = 'D')  and (LD.ReplenishOrderId = @ReplenishOrderId)  then '4'
               when (LD.OnhandStatus = 'D')  and (LD.ReplenishOrderId is null)              then '5'
               when (LD.OnhandStatus = 'D')  and (LD.ReplenishOrderId is not null)          then '6'
               else '9' /* all combinations covered above, so should never happen */
             end + '-' + dbo.fn_LeftPadNumber(coalesce(PB.Priority,0), 3);

  /* Start log of LPN Details into activitylog */
  exec pr_ActivityLog_LPN 'Loc_SplitReplQty_LPNDetails_Start', @vLPNId, @vActivityLogMessage, @@ProcId,
                          null, @BusinessUnit, @UserId, @vLDActivityLogId output;

  /* Start log of Task details into activitylog */
  exec pr_ActivityLog_LPN 'Loc_SplitReplQty_TaskDetails_Start', @vLPNId, 'ACT_Loc_SplitReplQty', @@ProcId,
                          null, @BusinessUnit, @UserId, @vTDActivityLogId output;

  /* Loop thru and process each of the D/DR lines, until the entire Qty has been processed */
  while ((exists (select * from @ttLPNDetails)) and
         (@Quantity > 0))
    begin
      select top 1 @vLPNDetailIdToProcess   = LPNDetailId,
                   @vLDOnhandStatus         = OnhandStatus,
                   @vLDQty                  = Quantity,
                   @vLDReservedQty          = ReservedQty,
                   @vOrderId                = OrderId,
                   @vOrderDetailId          = OrderDetailId,
                   @vReplenishOrderId       = ReplenishOrderId,
                   @vReplenishOrderDetailId = ReplenishOrderDetailId,
                   @vIPsToUpdate            = case when @vUnitsPerIP > 0 and (@vLocStorageType = 'P')
                                                then dbo.fn_MinInt(@Quantity, @vLDQty) / @vUnitsPerIP
                                                else 0
                                              end,
                   @vQtyToUpdate            = dbo.fn_MinInt(@Quantity, @vLDQty),
                   @vReservedQtyToUpdate    = dbo.fn_MinInt(ReservedQty, @Quantity)
      from @ttLPNDetails
      order by RecordId;

     /* Check if there is an existing line in the same LPN for the OrderDetail of
         the line being processed. If there is, then the intent is to add to this
         line instead of creating two different lines for the same OrderDetail */
      select @vReservedLineOrderDetailId = OrderDetailId,
             @vReservedLineLPNDetailId   = LPNDetailId
      from LPNDetails
      where (LPNId         = @vLPNId) and
            (OrderDetailId = @vOrderDetailId) and
            (OnhandStatus  = 'R' /* reserved */);

      /* There are few of scenarios here...
         -- The line that is being considered for split could have OHStatus of DR or D
         -- The split qty could be greater than line qty or less than it
         -- A line already exists for the Order Detail
         -- An available line exists
      */

      /* Directed line - no available line and qty being PA is more - so just flip from D to A and
         also update @vAvlbLPNDetailId with D line id here as we need to add any remaining quantity
         finally after the loop */
      if ((@Quantity >= @vLDQty) and
          ((@vLDOnhandStatus = 'D') and (coalesce(@vAvlbLPNDetailId, 0) = 0)))
        begin
          update LPNDetails
          set OnhandStatus      = 'A' /* Available */,
              OrderId           = null,
              OrderDetailId     = null,
              @vAvlbLPNDetailId = LPNDetailId
          where (LPNDetailId = @vLPNDetailIdToProcess);

          /* Changed Directed to Available */
          select @vActivityType = 'ReplenishPA_ReleaseDirQty';
        end
      else
      if (@vLDOnhandStatus = 'D' /* Directed */) and
         (@vAvlbLPNDetailId > 0)
        begin
          /* If entire qty is being added to A line, then add entire ReservedQty as well
             as we delete D lines with zero qty
             We had a scenario where D line had Qty = 30, ReservedQty = 35 and when user
             putaway 30 units, we transferred 30 units of both Qty, ReservedQty to A line,
             which left D line with 0 Qty, ReservedQty of 5 units and since Qty was zero on D line
             it got deleted. The change below is to move the 5 units also to A line.
          */
          if (@vQtyToUpdate = @vLDQty)
            select @vReservedQtyToUpdate = @vLDReservedQty;

          /* if we already have available line then we need to update it */
          update LPNDetails
          set InnerPacks  = InnerPacks  + @vIPsToUpdate,
              Quantity    = Quantity    + @vQtyToUpdate,
              ReservedQty = ReservedQty + @vReservedQtyToUpdate
          where (LPNDetailId = @vAvlbLPNDetailId);

         /* AT info */
         select @vActivityType = 'ReplenishPA_AddToAvailableLine',
                @vNote2        = @vAvlbLPNDetailId;
        end
      else /* generate line here */
        begin
          select @vQtyToUpdate = @Quantity,
                 @vIPsToUpdate = case when (@vUnitsPerIP > 0) and (@vLocStorageType = 'P') then @Quantity/@vUnitsPerIP else 0 end;

          exec @ReturnCode = pr_LPNDetails_AddOrUpdate @vLPNId, null /* LPNLine */, null /* CoO */,
                                                       @SKUId, null /* SKU */, @vIPsToUpdate, @vQtyToUpdate,
                                                       0 /* ReceivedUnits */, null /* ReceiptId */,  null /* ReceiptDetailId */,
                                                       null /* OrderId */, null /* OrderDetailId */, null /* OnHandStatus */,
                                                       null /* Operation */, null /* Weight */, null /* Volume */, null /* Lot */,
                                                       @BusinessUnit /* BusinessUnit */, @vAvlbLPNDetailId output;

          /* AT info */
          select @vActivityType = 'ReplenishPA_AddNewLine',
                 @vNote2        = @vAvlbLPNDetailId;
        end

      select @vPrevDRQty = null;

      /* When there is a D/DR line which was greater than the  putaway qty
         we would need to reduce the qty on the line. If the qty goes to zero
         then it would be deleted in the next statement */
      update LPNDetails
      set @vPrevDRQty =
          Quantity    = Quantity - @vQtyToUpdate,
          ReservedQty = ReservedQty - @vReservedQtyToUpdate,
          InnerPacks  = case when @vUnitsPerIP > 0 and @vLocStorageType = 'P' /* case */ then InnerPacks - (@vQtyToUpdate / @vUnitsPerIP)
                             else InnerPacks
                        end
      where (LPNDetailId = @vLPNDetailIdToProcess) and
            (OnHandStatus not in ('A', 'R' /* Reserved */));

      /* If the line that has been processed does not have any more qty, then delete it */
      if (@vPrevDRQty = 0)
        begin
          update LPNDetails
          set LPNId = -1 * LPNId
          where (LPNDetailId = @vLPNDetailIdToProcess) and
                (Quantity    = 0);
        end

      /* Update temp table with the qty change  */
      update @ttLPNDetails
      set Quantity    = Quantity - @vQtyToUpdate,
          ReservedQty = ReservedQty - @vReservedQtyToUpdate
      where (LPNDetailId = @vLPNDetailIdToProcess);

      /* AT Logging */
      exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                                @LPNId         = @vLPNId,
                                -- @vLPNDetailId  = @vSplitDRLDId,
                                @LocationId    = @vLocationId,
                                @SKUId         = @SKUId,
                                @Quantity      = @vQtyToUpdate,
                                @OrderId       = @vOrderId,
                                @OrderDetailId = @vOrderDetailId,
                                @Note1         = @vLPNDetailIdToProcess,
                                @Note2         = @vNote2;

      /* reduce the Qty processed */
      select @Quantity     = @Quantity - @vQtyToUpdate,
             @vSplitDRLDId = null, @vReservedLineOrderDetailId = null,
             @vReservedLineLPNDetailId = null;

      /* If we are quailifying directed lines of other replenish orders then swap replenish orders on them */
      if (@ReplenishOrderId <> @vReplenishOrderId)
        exec pr_LPNDetails_SwapReplenishLines @vLPNId, @SKUId, @vQtyToUpdate, @ReplenishOrderId, @vReplenishOrderId, @vReplenishOrderDetailId;

      /* Delete from temptable if the qty is 0 */
      delete from @ttLPNDetails
      where (Quantity <= 0);

     end /* while loop on @ttLPNDetails to process */

  /* If there is no lines to process and quantity is still remaining then need to update it to
     available line and if there is no available line then add one */
  if (@Quantity > 0)
    if (@vAvlbLPNDetailId > 0)
      update LPNDetails
      set Quantity   = Quantity + @Quantity,
          InnerPacks = case when @vUnitsPerIP > 0 and @vLocStorageType = 'P' /* case */ then InnerPacks + (@Quantity / @vUnitsPerIP)
                            else InnerPacks
                       end
      where (LPNDetailId = @vAvlbLPNDetailId);
    else
      begin
        select @vInnerPacks = case when (@vUnitsPerIP > 0) and (@vLocStorageType = 'P') then @Quantity/@vUnitsPerIP else 0 end;

        exec @ReturnCode = pr_LPNDetails_AddOrUpdate @vLPNId, null /* LPNLine */, null /* CoO */,
                                                     @SKUId, null /* SKU */, @vInnerPacks, @Quantity,
                                                     0 /* ReceivedUnits */, null /* ReceiptId */,  null /* ReceiptDetailId */,
                                                     null /* OrderId */, null /* OrderDetailId */, null /* OnHandStatus */,
                                                     null /* Operation */, null /* Weight */, null /* Volume */, null /* Lot */,
                                                     @BusinessUnit /* BusinessUnit */, @vAvlbLPNDetailId output;
        /* AT info */
        select @vActivityType = 'ReplenishPA_AddNewLine',
               @vNote2        = @vAvlbLPNDetailId;

        /* AT Logging */
        exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                                  @LPNId         = @vLPNId,
                                  @LocationId    = @vLocationId,
                                  @SKUId         = @SKUId,
                                  @Quantity      = @Quantity,
                                  @Note2         = @vNote2;

      end

  /* End log of LPN Details into activitylog */
  exec pr_ActivityLog_LPN 'Loc_SplitReplQty_LPNDetails_End', @vLPNId, @vActivityLogMessage, @@ProcId,
                          null, @BusinessUnit, @UserId, @vLDActivityLogId output;

  /* End log of Task Details into activitylog */
  exec pr_ActivityLog_LPN 'Loc_SplitReplQty_TaskDetails_End', @vLPNId, 'ACT_Loc_SplitReplQty', @@ProcId,
                          null, @BusinessUnit, @UserId, @vTDActivityLogId output;

  /* recount the LPN here */
  exec @ReturnCode = pr_LPNs_Recount @vLPNId, @UserId;

  /* Update dependencies of the Tasks - Needs to be done after LPN Recount above */
  if (exists (select * from LPNDetails where LPNId = @vLPNId and Onhandstatus = 'PR'))
    exec pr_LPNs_RecomputeWaveAndTaskDependencies @vLPNId, null /* Current Qty*/, @vLPNPrevQuantity;

  if (not exists (select * from LPNs where LPNId = @vLPNId and Quantity = @vLPNPrevQuantity + @vProcessingQty))
    select @MessageName = 'UpdateConflict'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* recount Location here */
  exec pr_Locations_UpdateCount @LocationId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_SplitReplenishQuantity */

Go
