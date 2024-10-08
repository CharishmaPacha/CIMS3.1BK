/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_ShipMultiple:
  2021/03/18  MS      pr_LPNs_BulkMove: Bug fix to avoid duplicate Audit Log (HA-2321)
  2020/08/19  TK      pr_LPNs_BulkMove: Do not log duplicate messages for each Pallet (HA-1310)
  2020/07/26  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_TransferLPNContentsToPicklane:
                      pr_LPNs_BulkMove & pr_LPNs_Move: Changes to export ReasonCode & Reference (HA-1186)
  2020/07/21  RKC     pr_LPNs_BulkMove: Made changes to scan pick-lane and transfer inventory to pick-lane from LPNs
  2020/07/13  TK      pr_LPNs_Action_BulkMove & pr_LPNs_BulkMove: Initial Revision (HA-1115)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_BulkMove') is not null
  drop Procedure pr_LPNs_BulkMove;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_BulkMove: Validates & moves LPNs to the Location specified in the
    temp table #LPNsToMove (TInventoryTransfer). If the Location is a picklane
    it transfers the inventory into the picklane.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_BulkMove
  (@Operation             TOperation = 'LPNMovedToLocation',
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @ReasonCode            TReasonCode = null,
   @Reference             TReference  = null)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,

          @vRecordId                TRecordId,
          @vLPNId                   TRecordId,
          @vLPN                     TLPN,
          @vPalletId                TRecordId,
          @vNewLocationId           TRecordId,
          @vNewLocation             TLocation,
          @vNewLocationType         TTypeCode;

  declare @ttAuditDetails           TAuditDetails,
          @ttAuditTrailInfo         TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Create Required hash tables */
  select * into #AuditDetails from @ttAuditDetails;

  /* Loop thru each LPN and move LPN to new location */
  while exists (select * from #LPNsToMove where RecordId > @vRecordId and ProcessFlag = 'N'/* No */)
    begin
      set @vPalletId = null;

      select top 1 @vRecordId        = RecordId,
                   @vLPNId           = LPNId,
                   @vLPN             = LPN,
                   @vPalletId        = PalletId,
                   @vNewLocationId   = NewLocationId,
                   @vNewLocation     = NewLocation,
                   @vNewLocationType = NewLocationType
      from #LPNsToMove
      where (RecordId > @vRecordId) and
            (ProcessFlag =  'N'/* No */)
      order by RecordId;

      begin try
        if (@vNewLocationType = 'K' /* PickLane location */)
          begin
            set @Operation  = 'LPNContentsXferedToPicklane';

            /* Invoke proc to move LPN contents to the corresponding new location */
            exec pr_LPNs_TransferLPNContentsToPicklane @vLPNId, @vNewLocationId, @BusinessUnit, @UserId;
          end
        else
        /* If  palletid is not null then move all LPNs on the pallet to new location */
        if (@vPalletId is not null)
          begin
            set @Operation = 'PalletMovedToLocation';

            /* Invoke proc to move Pallet & its LPNs to the new Location */
            exec pr_Pallets_SetLocation @vPalletId, @vNewLocationId, 'Y' /* Yes, Update LPNs as well */, @BusinessUnit, @UserId;
          end
        else
          begin
            set @Operation = 'LPNMovedToLocation';

            /* Invoke proc to move LPN to the corresponding new location */
            exec pr_LPNs_Move @vLPNId, @vLPN, null /* LPNStatus */, @vNewLocationId, @vNewLocation, @BusinessUnit, @UserId, default /* UpdateOption */, @ReasonCode, @Reference;
          end

        /* Update as processed and AT related information */
        /* If a pallet is being moved then mark all the LPNs on pallet as processed */
        if (@Operation = 'PalletMovedToLocation')
          update #LPNsToMove
          set ProcessFlag  = 'Y' /* Processed */,
              ActivityType = @Operation,
              Comment      = dbo.fn_Messages_BuildDescription('AT_'+ @Operation, 'LPN', LPN, 'Pallet', Pallet, 'FromLocation', Location, 'ToLocation', NewLocation, null, null, null, null)
          where (PalletId = @vPalletId);
        else
          /* If an LPN is being moved then mark the LPN record as processed */
          update #LPNsToMove
          set ProcessFlag  = 'Y' /* Processed */,
              ActivityType = @Operation,
              Comment      = dbo.fn_Messages_BuildDescription('AT_'+ @Operation, 'LPN', LPN, 'Pallet', Pallet, 'FromLocation', Location, 'ToLocation', NewLocation, null, null, null, null)
          where (RecordId = @vRecordId);

      end try
      begin catch
        /* Mark the LPN as error */
        /* If a pallet is being moved then mark all the LPNs on pallet as error with Error message */
        if (@Operation = 'PalletMovedToLocation')
          update #LPNsToMove
          set ProcessFlag = 'E' /* Error */
          output 'E', inserted.LPNId, inserted.LPN, Error_Message()
            into #ResultMessages (MessageType, EntityId, EntityKey, MessageText)
          where (PalletId = @vPalletId);
        else
          /* If an LPN is being moved then mark the LPN record as error with Error message */
          update #LPNsToMove
          set ProcessFlag = 'E' /* Error */
          output 'E', inserted.LPNId, inserted.LPN, Error_Message()
            into #ResultMessages (MessageType, EntityId, EntityKey, MessageText)
          where (RecordId = @vRecordId);
      end catch
    end /* while Loop end */

  /*---------------- Log Audit Trail ----------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    /* LPN */
    select distinct 'LPN', LPNId, LPN, ActivityType, @BusinessUnit, @UserId, Comment
    from #LPNsToMove
    where (ProcessFlag = 'Y' /* Yes */)
    union
    /* Pallet */
    select distinct 'Pallet', PalletId, Pallet, ActivityType, @BusinessUnit, @UserId, Comment
    from #LPNsToMove
    where (ProcessFlag = 'Y' /* Yes */) and (PalletId is not null)
    union
    /* To Location */
    select distinct 'Location', NewLocationId, NewLocation, ActivityType, @BusinessUnit, @UserId, Comment
    from #LPNsToMove
    where (ProcessFlag = 'Y' /* Yes */)

  /* Log audit details for the LPNs moved */
  insert into #AuditDetails (ActivityType, BusinessUnit, UserId, LPNId, Warehouse, ToWarehouse, Comment)
    select ActivityType, @BusinessUnit, @UserId, LPNId, Warehouse, NewWarehouse, Comment
    from #LPNsToMove
    where (ProcessFlag = 'Y' /* Yes */);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_BulkMove */

Go
