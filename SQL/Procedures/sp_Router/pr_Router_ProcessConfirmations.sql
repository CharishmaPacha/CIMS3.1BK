/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/03  MS      pr_Router_ProcessConfirmations: Changes to update pallet status (JL-65)
  2020/03/18  MS      pr_Router_ProcessConfirmations: Change DCMS to DCMS terminology (JL-63, JL-64)
  2020/02/18  AY      pr_Router_ProcessConfirmations: Process receipt diverts (JL-63, JL-64)
  2018/07/17  AY/PK   pr_Router_ProcessConfirmations: Added changes to consider 'No Load' while inserting into @ttLPNsConfirmed, get DesiredShipDate: Migrated from Prod (S2G-727)
  2018/07/09  AY/TK   pr_Router_ProcessConfirmations: Recalc Order & Wave counts after processing (S2G-1010)
  2018/06/09  YJ      pr_Router_ProcessConfirmations: Added condition in the join to get L.UCCBarcode: Migrated from staging (S2G-727)
  2018/04/27  AY      pr_Router_ProcessConfirmations: Add diverted LPNs to Loads (S2G-703)
  2014/06/05  PV      pr_Router_ProcessConfirmations: Fixed issue with infinite loop.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Router_ProcessConfirmations') is not null
  drop Procedure pr_Router_ProcessConfirmations;
Go
/*------------------------------------------------------------------------------
  Proc pr_Router_ProcessConfirmations: When LPNs are diverted off the shipping
    sorter into the truck, WSS would send a confirmation of the same. This would
    trigger adding of the LPNs to the appropriate Load. The Load for S2G is
    determined by the DockLocation and ShipDate from the Wave of the LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_Router_ProcessConfirmations
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId = 'DCMSRouter')
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vRecordId           TRecordId,
          @vLPNId              TRecordId,
          @vLPN                TLPN,
          @vLPNStatus          TStatus,
          @vPalletId           TRecordId,
          @vPallet             TPallet,
          @vLocationId         TRecordId,
          @vDestination        TLocation,
          @vActualWeight       TWeight,
          @vOrderId            TRecordId,
          @vShipmentId         TRecordId,
          @vWaveId             TRecordId,
          @vPickTicket         TPickTicket,
          @vShipDate           TDate,
          @vTargetDestination  TLocation,
          @vDivertTime         TDescription,
          @vLoadId             TLoadId,
          @vLoadNumber         TLoadNumber,
          @vReceiptId          TRecordId,
          @vAuditActivity      TActivityType,
          @vProcessStatus      TStatus,
          @xmlInput            xml,
          @xmlResult           xml;

  declare @ttOrdersToUpdate    TEntityKeysTable,
          @ttWavesToUpdate     TEntityKeysTable,
          @ttReceiptsToUpdate  TEntityKeysTable,
          @ttPalletsToUpdate   TRecountKeysTable;

  declare @ttLPNsConfirmed table
          (RCRecordId    TRecordId,
           LPNId         TRecordId,
           LPN           TLPN,
           LPNStatus     TStatus,
           --AlternateLPN  TLPN,
           PalletId      TRecordId,
           Pallet        TPallet,
           LocationId    TRecordId,
           Destination   TLocation,
           OrderId       TRecordId,
           ShipmentId    TRecordId,
           WaveId        TRecordId,
           ReceiptId     TRecordId,
           ActualWeight  TWeight,
           DivertTime    TDescription,
           ProcessedFlag TFlag,
           RecordId      TRecordId       identity (1,1) not null,

           Primary Key (RecordId));
begin
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0;

  /* Fetching Destination information from RouterConfirmation and updating Location
     on LPNs */
  insert into @ttLPNsConfirmed
    select RC.RecordId, L.LPNId, L.LPN, L.Status, L.PalletId, L.Pallet, Loc.LocationId, RC.Destination,
           L.OrderId, L.ShipmentId, L.PickBatchId, L.ReceiptId,
           RC.ActualWeight, RC.DivertTime, 'N' /* Processed Flag */
    from RouterConfirmation RC
     join LPNs                 L   on (L.LPNId = dbo.fn_LPNs_GetScannedLPN(RC.LPN, @BusinessUnit, default))
     left outer join Locations LOC on (Loc.Location = RC.Destination)
    where (RC.ProcessedStatus = 'N' /* No */);

  while (exists (select * from @ttLPNsConfirmed where RecordId > @vRecordId))
    begin
      /* initialize */
      select @vLoadId = 0;

      select top 1 @vLPNId         = LPNId,
                   @vLPN           = LPN,
                   @vLPNStatus     = LPNStatus,
                   @vPalletId      = PalletId,
                   @vPallet        = Pallet,
                   @vLocationId    = LocationId,
                   @vDestination   = Destination,
                   @vOrderId       = OrderId,
                   @vShipmentId    = ShipmentId,
                   @vWaveId        = WaveId,
                   @vReceiptId     = ReceiptId,
                   @vActualWeight  = ActualWeight,
                   @vRecordId      = RecordId,
                   @vProcessStatus = case when OrderId is not null and LPNStatus not in ('K') then 'X' /* Error */ else 'Y' end,
                   @vDivertTime    = DivertTime
      from @ttLPNsConfirmed
      where (RecordId > @vRecordId)
      order by RecordId;

      select @vAuditActivity = case when @vLPNStatus in ('T', 'R' /* Intransit, Received */)
                                 then 'LPNRecvDivert'
                                 else 'LPNShipDivert'
                               end;

      /* Updating Location on LPNs */
      exec @vReturnCode = pr_LPNs_SetLocation @vLPNId, @vLocationId;

      /* Save actual weight from the scale returned by WSS */
      if (@vActualWeight is not null)
        update LPNs set ActualWeight = @vActualWeight where LPNId = @vLPNId;

      /* Create AT to show that we got divert confirmation on the LPN. We are
         doing this first before adding to Load to show in proper sequence in AT */
      exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                @LPNId   = @vLPNId,
                                @OrderId = @vOrderId,
                                @Note1   = @vDestination,
                                @Note2   = @vDivertTime;

      /* Unless if the LPN is in an invalid state, process it */
      if (@vOrderId is not null) and (@vProcessStatus = 'Y' /* Not Error */)
        begin
          /* Get the Dock Location from the Wave */
          select @vTargetDestination = DropLocation,
                 @vShipDate          = ShipDate
          from PickBatches
          where (RecordId = @vWaveId);

          /* If the LPN reached the destination, then process it */
          if (@vDestination = @vTargetDestination)
            begin
              /* Identify the Load to add to */
              select @vLoadId     = LoadId,
                     @vLoadNumber = LoadNumber
              from Loads
              where (Status in ('N', 'I', 'R', 'M', 'L' /* New, Inprogress, ReadyToLoad, Loading, Ready to Ship */)) and
                    ((DesiredShipDate = @vShipDate) or
                     (@vShipDate < DesiredShipDate)) and
                    (DockLocation = @vTargetDestination);

              /* If no Load is identified, then update process status accordingly */
              if (@vLoadId = 0) select @vProcessStatus = 'NL'; -- No Load

              if (@vLoadId > 0)
                begin
                  /* Build the xml for RFC_Shipping_Load */
                  select @xmlInput = (select @vLoadNumber Load, @vLPN ScanLPNOrPallet,
                                             @BusinessUnit BusinessUnit, @UserId UserId
                                      FOR XML RAW('ConfirmLoad'), TYPE, ELEMENTS);

                  /* Add LPN to the selected Load */
                  exec pr_RFC_Shipping_Load @xmlInput, @xmlResult out;

                  /* Keep track of orders to be recounted so that we don't repeatedly
                     update the same order again and again */
                  if (not exists (select * from @ttOrdersToUpdate where EntityId = @vOrderId))
                    insert into @ttOrdersToUpdate (EntityId, EntityKey) select @vOrderId, @vPickTicket;

                  /* Keep track of Waves to be recounted so that we don't repeatedly
                     update the same order again and again */
                  if (not exists (select * from @ttWavesToUpdate where EntityId = @vWaveId))
                    insert into @ttWavesToUpdate (EntityId) select @vWaveId;
                end /* if LoadId > 0 */
            end /* If LPN reached destination */
        end /* If LPN is Picked */

      /* If if this is an Intransit LPN being confirmed, then recalc the RH (later) */
      if (@vLPNStatus in ('T')) and (@vReceiptId is not null)
        begin
          /* Change LPN Status to Received */
          exec pr_LPNs_SetStatus @vLPNId, 'R' /* Received */;

          if (not exists (select * from @ttPalletsToUpdate where EntityId = @vPalletId))
            insert into @ttPalletsToUpdate (EntityId, EntityKey) select @vPalletId, @vPallet;

          if (not exists (select * from @ttReceiptsToUpdate where EntityId = @vReceiptId))
            insert into @ttReceiptsToUpdate (EntityId) select @vReceiptId;
        end

      /* Update status of the record. If Order added to Load, then mark the record as processed */
      update @ttLPNsConfirmed
      set ProcessedFlag = @vProcessStatus
      where (RecordId = @vRecordId);
    end /* while .. @ttLPNsConfirmed */

  /* Update records which have been processed, others will be processed again later */
  update RouterConfirmation
  set ProcessedStatus   = TL.ProcessedFlag,
      ProcessedDateTime = current_timestamp
  from RouterConfirmation RC join @ttLPNsConfirmed TL on (RC.RecordId = TL.RCRecordId)
  where (TL.ProcessedFlag in ('Y', 'X', 'NL'));

  /* Update Pallet Status */
  exec pr_Pallets_Recalculate @ttPalletsToUpdate, '$S' /* Flag */, @BusinessUnit, @UserId;

  /* Compute the counts on the orders and their statuses */
  exec pr_OrderHeaders_Recalculate @ttOrdersToUpdate, '$S' /* Flag to calc status */, @UserId, @BusinessUnit;

  /* Compute the counts on the orders and their statuses */
  exec pr_PickBatch_Recalculate @ttWavesToUpdate, '$S' /* Flag to calc status */, @UserId, @BusinessUnit;

  /* Compute the counts on the orders and their statuses */
  exec pr_ReceiptHeaders_Recalculate @ttReceiptsToUpdate, '$CS' /* Flag to calc status */, @UserId, @BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Router_ProcessConfirmations */

Go
