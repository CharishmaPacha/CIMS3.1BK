/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/27  TK      pr_Locations_TransferReservation: Orphan directed line fixes (HPI-2248)
                      pr_Locations_TransferReservation: Prioritize transfers based upon ReplenishOrderId of PA case
  2018/11/21  TK      pr_Locations_TransferReservation: Changes to transfer reservation for replenish order being putaway followed by other DR lines (HPI-2166)
  2018/11/13  TK      pr_Locations_TransferReservation: Changes to Log AT on Wave, PickTicket, Location and LPN (HPI-2116)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_TransferReservation') is not null
  drop Procedure pr_Locations_TransferReservation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_TransferReservation: Transfers reservations to Destnation LPN
   based on the available quantity on Destination LPN

  Input XML:
    <Root>
       <DestLocationId>55393</DestLocationId>
       <ScannedLocationId>75819</ScannedLocationId>
       <SKUId>2889</SKUId>
       <ReplenishOrderId>27231</ReplenishOrderId>
       <BusinessUnit>HPI</BusinessUnit>
       <UserId>tarak</UserId>
    </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_TransferReservation
  (@XMLLocationInfo    xml)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TDescription,
          @vRecordId                    TRecordId,

          @SourceLocationId             TRecordId,
          @DestLocationId               TRecordId,
          @SKUId                        TRecordId,
          @ReplenishOrderId             TRecordId,
          @ReplenishOrderDetailId       TRecordId,
          @QtyTransferred               TQuantity,
          @BusinessUnit                 TBusinessUnit,
          @UserId                       TUserId,

          @vSourceLPNId                 TRecordId,
          @vDestLPNId                   TRecordId,
          @vLPNId                       TRecordId,
          @vLPNDetailId                 TRecordId,
          @vSKUId                       TRecordId,
          @vTransferQty                 TQuantity,
          @vLDQuantity                  TQuantity,
          @vLDOnhandStatus              TStatus,
          @vLDReplOrderId               TRecordId,
          @vLDReplOrderDetailId         TRecordId,

          @vTaskDetailId                TRecordId,
          @vNewTaskDetailId             TRecordId,
          @vNewLPNDetailId              TRecordId,

          @vAvailableLPNDetailId        TRecordId,

          @vSrcLPNDetailId              TRecordId,
          @vSrcOrderId                  TRecordId,
          @vSrcOrderDetailId            TRecordId,
          @vTargetLPNDetailId           TRecordId,
          @vSrcInnerpacks               TInnerPacks,
          @vSrcQuantity                 TQuantity,

          @vDebug                       TFlags,
          @vSourceLDActivityLogId       TRecordId,
          @vSourceTDActivityLogId       TRecordId,
          @vDestLDActivityLogId         TRecordId,
          @vDestTDActivityLogId         TRecordId;

  declare @ttTaskDetails                TTaskInfoTable;

  declare @ttTransferLPNDetails Table
          (RecordId                TRecordId Identity(1,1),
           LPNId                   TRecordId,
           LPNDetailId             TRecordId,
           SKUId                   TRecordId,
           OrderId                 TRecordId,
           OrderDetailId           TRecordId,
           ReplenishOrderId        TRecordId,
           ReplenishOrderDetailId  TRecordId,
           Quantity                TQuantity,
           OnHandStatus            TStatus,
           Primary Key             (RecordId));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vRecordId = 0;

  /* Extract XML data */
  if (@XMLLocationInfo is not null)
    select @SourceLocationId       = Record.Col.value('DestLocationId[1]',         'TRecordId'),
           @DestLocationId         = Record.Col.value('ScannedLocationId[1]',      'TRecordId'),
           @SKUId                  = Record.Col.value('SKUId[1]',                  'TRecordId'),
           @ReplenishOrderId       = Record.Col.value('ReplenishOrderId[1]',       'TRecordId'),
           @ReplenishOrderDetailId = Record.Col.value('ReplenishOrderDetailId[1]', 'TRecordId'),
           @QtyTransferred         = Record.Col.value('Quantity[1]',               'TQuantity'),
           @BusinessUnit           = Record.Col.value('BusinessUnit[1]',           'TBusinessUnit'),
           @UserId                 = Record.Col.value('UserId[1]',                 'TUserId')
    from @XMLLocationInfo.nodes('Root') as Record(Col);

  /* Message for logging */
  select @vMessage = 'RepOrderId: ' + cast(coalesce(@ReplenishOrderId, '0') as varchar) + ', Qty: ' + cast(@QtyTransferred as varchar);

  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (@SourceLocationId is not null)
    select @vSourceLPNId = LPNId
    from LPNs
    where (LocationId = @SourceLocationId) and
          (SKUId      = @SKUId);

  if (@DestLocationId is not null)
    select @vDestLPNId = LPNId
    from LPNs
    where (LocationId = @DestLocationId) and
          (SKUId      = @SKUId);

  if (@vSourceLPNId is null) or (@vDestLPNId is null)
    return;

  /* Start log of Source/Dest LPN/Tasks Details into activitylog */
  if (charindex('L', @vDebug) <> 0)
    begin
      exec pr_ActivityLog_LPN 'Source_LPNDetails',  @vSourceLPNId, @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vSourceLDActivityLogId output;
      exec pr_ActivityLog_LPN 'Source_TaskDetails', @vSourceLPNId, @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vSourceTDActivityLogId output;
      exec pr_ActivityLog_LPN 'Dest_LPNDetails',    @vDestLPNId,   @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vDestLDActivityLogId output;
      exec pr_ActivityLog_LPN 'Dest_TaskDetails',   @vDestLPNId,   @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vDestTDActivityLogId output;
    end

  /* Get all the LPN Details from Source that may need to be processed.
     On Replenish PA, first move the lines associated with the Replenishment that has been putaway */
  insert into @ttTransferLPNDetails(LPNId, LPNDetailId, SKUId, OrderId, OrderDetailId, ReplenishOrderId, ReplenishOrderDetailId,
                                    Quantity, OnhandStatus)
    select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.OrderId, LD.OrderDetailId, LD.ReplenishOrderId, LD.ReplenishOrderDetailId,
           LD.Quantity, LD.OnhandStatus
    from LPNDetails LD
    where (LD.LPNId = @vSourceLPNId) and (LD.Onhandstatus in ('R', 'DR'))
    order by LD.Onhandstatus,
             case when (LD.ReplenishOrderId = @ReplenishOrderId) then 1 else 2 end,
             LD.Quantity; -- first DR lines and then R Lines.

  /* If there is still available qty in destination LPN and there are LPNDetails that can be transferred
     in the source LPN, then process them */
  while (exists (select * from @ttTransferLPNDetails where RecordId > @vRecordId) and
        (@QtyTransferred > 0))
    begin
      /* Initialize */
      select @vAvailableLPNDetailId = null, @vTransferQty = 0, @vTargetLPNDetailId = null;

      /* Get the first record to process */
      select top 1
             @vRecordId            = RecordId,
             @vLPNId               = LPNId,
             @vLPNDetailId         = LPNDetailId,
             @vSKUId               = SKUId,
             @vLDQuantity          = Quantity, -- I think we need to get from LPNDetail and not use the from from Temp table. see below comments.
             @vLDOnhandStatus      = OnhandStatus,
             @vLDReplOrderId       = ReplenishOrderId,
             @vLDReplOrderDetailId = ReplenishOrderDetailId
      from @ttTransferLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Find an available line on destination to deduct from. If there are multiple, then fetch the biggest one */
      select top 1
             @vAvailableLPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNId = @vDestLPNId) and (SKUId = @vSKUId) and (OnhandStatus = 'A') and (Quantity > 0)
      order by Quantity desc;

      /* If there are is no more available qty on the destination, then quit */
      if (@vAvailableLPNDetailId is null) break;

      /* Can only transfer a minimum of source line qty or destination available qty */
      select @vTransferQty = dbo.fn_MinInt(@vLDQuantity, @QtyTransferred);

      /* If we are transferring Directed reserve quantity to which is for other replenish order then we need to swap directed quantities
         of source and target replenish orders else source replenish directed quantity will become an orphan */
      if (@vLDOnHandStatus = 'DR'/* Directed Reserve */) and (@vLDReplOrderId <> @ReplenishOrderId)
        exec pr_LPNDetails_SwapReplenishLines @vLPNId, @vSKUId, @vTransferQty, @ReplenishOrderId, @vLDReplOrderId, @vLDReplOrderDetailId;

      /* If we are transferring reserved quantity then cancel directed quantity of source replenish line, if not done there will be
         an orphan line */
      if (@vLDOnHandStatus = 'R'/* Reserve */)
        exec pr_LPNDetails_CancelReplenishQty @ReplenishOrderId, @ReplenishOrderDetailId, @vTransferQty, @BusinessUnit, @UserId;

      /* Get the task detail associated with LPN detail being transferred */
      select @vTaskDetailId = TaskDetailId
      from TaskDetails
      where (LPNDetailId = @vLPNDetailId);

      /* If From LPNDetail qty is more than available qty, then split the task detail which in turn splits from LPN detail */
      if (@vLDQuantity > @vTransferQty)
        begin
          /* Initialize */
          set @vNewTaskDetailId =  null;

          /* Split Task Detail and its associated LPN Detail */
          exec pr_TaskDetails_SplitDetail @vTaskDetailId, null/* Innerpacks */, @vTransferQty,
                                          default /* Operation */, @BusinessUnit, @UserId,
                                          @vNewTaskDetailId output;

          /* Assign new task detail with split quantity */
          set @vTaskDetailId = @vNewTaskDetailId;

          select @vLPNDetailId = LPNDetailId
          from TaskDetails
          where (TaskDetailId = @vTaskDetailId);
        end

      /* Move the Source LPN Detail to destination */
      update LPNDetails
      set LPNId               = @vDestLPNId,
          LPNLine             = LPNDetailId,
          OnhandStatus        = 'R', -- it could have been a DR or R before
          @vSrcLPNDetailId    = LPNDetailId,
          @vSrcQuantity       = Quantity,
          @vSrcInnerpacks     = Innerpacks,
          @vSrcOrderId        = OrderId,
          @vSrcOrderDetailId  = OrderDetailId
      where (LPNDetailId = @vLPNDetailId);

      /*  Reduce available Qty on the destination LPN */
      exec pr_LPNs_AdjustQty @vDestLPNId, @vAvailableLPNDetailId output, @vSKUId, null,
                             0/* Innerpacks */, @vTransferQty, '-'  /* Update Option - Subtract Qty */,
                             'N'/* Export? No */, 0/* ReasnCode */, null /* Reference */,
                             @BusinessUnit, @UserId;

      /* Update task detail with new LPN info */
      update TaskDetails
      set LPNId      = @vDestLPNId,
          LocationId = @DestLocationId
      where (TaskDetailId = @vTaskDetailId);

      /* Check if there is allocated line for same order detail */
      select @vTargetLPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNId         = @vDestLPNId) and
            (OrderDetailId = @vSrcOrderDetailId) and
            (LPNDetailId   <> @vSrcLPNDetailId);

      /* If there exists a line allocated for same order detail then transfer units from source LPN Detail */
      if (@vTargetLPNDetailId is not null)
        exec pr_TasksDetails_TransferUnits @vSrcLPNDetailId, @vTargetLPNDetailId, @vSrcInnerpacks, @vSrcQuantity, 'TransferReservation', @BusinessUnit, @UserId;

      /* Increase the LPNDetail qty on source LPN if we have transferred a Reserved line */
      if (@vLDOnhandStatus = 'R' /* Reserved */)
        begin
          update LPNDetails
          set Quantity += @vTransferQty
          where (LPNId = @vLPNId) and (OnhandStatus = 'A');

          /* If no available line exists then create one with Transferred qty */
          if (@@rowcount = 0)
            exec pr_LPNDetails_AddOrUpdate @vLPNId, null /* LPNLine */, null /* CoO */,
                                           @vSKUId, null /* SKU */, null /* innerpacks */, @vTransferQty,
                                           0 /* ReceivedUnits */, null /* ReceiptId */, null /* ReceiptDetailId */,
                                           null /* OrderId */, null /* OrderDetailId */, 'A' /* OnHandStatus */, null /* Operation */,
                                           null /* Weight */, null /* Volume */, null /* Lot */,
                                           @BusinessUnit /* BusinessUnit */, @vNewLPNDetailId  output;
        end

      /* If entire line was not processed, then process it again */
      if (@vTransferQty < @vLDQuantity)
        begin
          /* Reduce transferred quantity in temp table */
          update @ttTransferLPNDetails
          set Quantity -= @vTransferQty
          where RecordId = @vRecordId;

          select @vRecordId -= 1;
        end

      /* Reduce qty transferred */
      select @QtyTransferred -= @vTransferQty;

      /* Insert Audit Trail */
      exec pr_AuditTrail_Insert 'TransferReservation', @UserId, null /* ActivityTimestamp */,
                                @LocationId    = @SourceLocationId,
                                @ToLocationId  = @DestLocationId,
                                @SKUId         = @vSKUId,
                                @OrderId       = @vSrcOrderId,
                                @Quantity      = @vTransferQty;
    end

  /* Recount source and destination LPNs to update reserved quantities */
  exec pr_LPNs_Recount @vSourceLPNId;
  exec pr_LPNs_Recount @vDestLPNId;

  /* Recount source and destination Locations to update reserved quantities */
  exec pr_Locations_UpdateCount @SourceLocationId, null/* Location */, '*';
  exec pr_Locations_UpdateCount @DestLocationId, null/* Location */, '*';

  /* Start log of Source/Dest LPN/Tasks Details into activitylog */
  if (charindex('L', @vDebug) <> 0)
    begin
      exec pr_ActivityLog_LPN 'Source_LPNDetails',  @vSourceLPNId, @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vSourceLDActivityLogId output;
      exec pr_ActivityLog_LPN 'Source_TaskDetails', @vSourceLPNId, @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vSourceTDActivityLogId output;
      exec pr_ActivityLog_LPN 'Dest_LPNDetails',    @vDestLPNId,   @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vDestLDActivityLogId output;
      exec pr_ActivityLog_LPN 'Dest_TaskDetails',   @vDestLPNId,   @vMessage, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @ActivityLogId = @vDestTDActivityLogId output;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_TransferReservation */

Go
