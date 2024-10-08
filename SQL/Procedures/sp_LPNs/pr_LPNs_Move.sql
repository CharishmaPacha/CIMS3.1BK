/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/30  SV      pr_LPNs_Move: Changes to mark the LPN status as Staged on dropping to Staging location (HA-1584)
  2020/08/28  TK      pr_LPNs_Move & pr_LPNs_ValidateInventoryMovement: Changes to move reserved LPNs
  2020/07/29  TK      pr_LPNs_Move & pr_LPNs_Ship: Changes to generate exports properly on WH transfer (HA-1246)
  2020/07/29  RT      pr_LPNs_Move: LPN SetStatus is calling two times (HA-111)
                      pr_LPNs_BulkMove & pr_LPNs_Move: Changes to export ReasonCode & Reference (HA-1186)
  2020/04/16  VM      pr_LPNs_MoveLPN: Call pr_LPNs_ValidateInventoryMovement for more validations (HA-161)
  2019/05/03  MS      pr_LPNs_Move: Made changes to update Location on Taskdetails if Reserved Qty is > 0 (S2GCA-685)
  2019/02/05  VM/DK   pr_LPNs_Move: Do not move an allocated LPN related to non transfer orders to other Warehouses (FB-1265)
  2018/08/09  RV      pr_LPNs_Move: Made changes to update the status of LPNs based upon the rules (HPI-1997)
  2018/05/08  RV      pr_LPNs_Move: Made changes to send a FromWarehouse to generate Warehouse transfer exports properly
  2017/09/14  SV      pr_LPNs_Move: As we moved the code for generating Recv type of exports to pr_Exports_LPNReceiptConfirmation,
  2016/12/07  TK      pr_LPNs_Move: Return from proc if user is trying to move LPN to its own Location (HPI-1102)
  2016/11/16  RV      pr_LPNs_Move: Remove code to change LPN status to received from InTransit as we already calling procedure
  2016/10/26  RV      pr_LPNs_Move: Updated task detail's Location if allocated LPN is moved to new location (HPI-936)
                      pr_LPNs_Move: Do not clear DestLocation on LPNs destined for picklanes.
  2016/08/18  SV      pr_LPNs_Move: Updating the WH(of dest Loc) over the exports generated (FB-742)
  2016/07/22  NY      pr_LPNs_Move: Passing BusinessUnit for WhXfer Exports procedure(SRI-566).
  2016/07/07  OK      pr_LPNs_Move: Cleanup the unnecessary code (CIMS-1004)
  2016/05/14  VM      pr_LPNs_Move: Update ReceivedQty to be Quantity as users might move Intransit LPNs directly to any location (NBD-517)
  2016/02/03  TK      pr_LPNs_Move: Bug fix to generate Exports with correct Reason Codes (FB-599)
                      pr_LPNs_Move: Use Location_UpdateCounts from SetLocation
  2014/10/29  TK      pr_LPNs_Move: Updated to recount Pallet after putaway.
  2014/08/01  TD      pr_LPNs_CreateInvLPN, pr_LPNs_Move:Pre-Proces the Created inventory LPN.
  2014/07/10  TD      pr_LPNs_Move:Changes to update dest Location as null while putaway into the
  2014/05/18  AY      pr_LPNs_Move: Export InvCh trans on PA of Received LPN if we do not have ReceiptNumber
  2014/03/27  AY      pr_LPNs_Move: Set LastMovedDate
  2014/01/20  TD      pr_LPNs_Lost, pr_LPNs_Move:Changes to move LPN into LOST location instead of mark the LPN as lost
                      pr_LPNs_Move: Not Allowing to Move allocated LPN/Units.
  2014/01/07  AY      pr_LPNs_Move: Bug fix - do not export WHXfer when LPN's Warehouse is not updated
  2013/11/22  PK      pr_LPNs_Move: Added a new input param to pass in reason code.
  2013/11/20  NY      pr_LPNs_Move: Added condition to pass 'InvCh' Export type when we Putaway Inventory LPN.
  2103/08/30  TD      pr_LPNs_Move:validating Warehouse if the LPN in LogicalWarehouse and Location in PhysicalWH.
  2013/03/25  VM      pr_LPNs_Move: If a new LPN is moved to Staging location set it to Received.
  2012/09/14  AY      pr_LPNs_Move: Prevent allocated LPN from being moved to Reserve/Bulk.
  2012/09/11  YA      pr_LPNs_Move: For Intransit/Lost LPNs, if it is moved to a staging location, LPNs should be marked as Received.
              PK      pr_LPNs_Move: Export when Intransit LPN is Putaway.
  2012/08/09  PK      pr_LPNs_Move: Updating ModifiedData and ModifiedBy when moving an LPN.
  2012/07/16  AY      pr_LPNs_Move: Allow moves between Warehouse and generate exports.
  2012/07/05  PK      pr_LPNs_Move: Included Storage Type LA as well to exclude in validation.
  2012/04/10  PK      pr_LPNs_Move: Added a new parameter @UpdateOption to update Location
  2011/10/04  AY      pr_LPNs_Move: Upload Photo In/Out transactions.
  2011/08/11  AY      pr_LPNs_Move: (LOEH specific)
                      pr_LPNs_Move: Call set status seperately to calculate OnhandStatuses
  2010/12/31  VM      pr_LPNs_Move: Set status to 'Putaway', if current status in 'Received/New'.
  2010/12/03  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Move:
  2010/11/29  PK      Added pr_LPNs_Move.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Move') is not null
  drop Procedure pr_LPNs_Move;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Move:
    This proc assumes, the caller will pass a valid LPN and valid Location.

    UpdateOption - E - Generate Exports, L - Update Location counts, P - Pallet Counts
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Move
  (@LPNId          TRecordId,
   @LPN            TLPN,
   @LPNStatus      TStatus,
   @NewLocationId  TRecordId,
   @NewLocation    TLocation,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @UpdateOption   TFlags = 'ELP',
   @ReasonCode     TReasonCode = null,
   @Reference      TReference  = null)
as
  declare @vReturnCode                    TInteger,
          @MessageName                    TMessageName,
          @Message                        TDescription,

          @vLocationType                  TLocationType,
          @vStorageType                   TStorageType,
          @vOrderType                     TTypeCode,
          @vWaveType                      TTypeCode,
          @vPalletId                      TRecordId,
          @vNewLPNStatus                  TStatus,
          @vOnhandStatus                  TStatus,
          @vOldLocationId                 TRecordId,
          @vLocWarehouse                  TWarehouse,
          @vLPNId                         TRecordId,
          @vLPN                           TLPN,
          @vLPNDestWarehouse              TWarehouse,
          @vLPNNewWarehouse               TWarehouse,
          @vSKUId                         TRecordId,
          @vLPNOrderId                    TRecordId,
          @vLPNType                       TTypeCode,
          @vLPNStatus                     TStatus,
          @vLPNOnhandStatus               TStatus,
          @vPrevLPNStatus                 TStatus,
          @vLPNLocation                   TLocation,
          @vInnerPacks                    TInnerPacks,
          @vQuantity                      TQuantity,
          @vTransQty                      TQuantity,
          @vTransType                     TTypeCode,
          @vReceiptId                     TRecordId,
          @vReceiptNumber                 TReceiptNumber,
          @vReservedQty                   TQuantity,
          @vLPNReasonCode                 TReasonCode,
          @vLocPutawayZone                TLookUpCode,
          @xmlRulesData                   TXML,

          @vDefaultWHXFerReasonCode       TReasonCode,
          @vDefaultLPNMoveReasonCode      TReasonCode,
          @vLPNMoveReasonCode             TReasonCode,
          @vWHXFerReasonCode              TReasonCode,

          @vSyncLPNWithLocationWarehouse  TControlValue,
          @vMoveReservedInvAcrossWHs      TControlValue,
          @vAllowMultipleSKUs             TFlag,
          @vIsValidLocationTypeToPutaway  TFlag;
begin
  SET NOCOUNT ON;

  select @vSyncLPNWithLocationWarehouse = dbo.fn_Controls_GetAsString('Inventory', 'SyncLPNWithLocationWarehouse', 'N' /* No */, @BusinessUnit, @UserId),
         @vMoveReservedInvAcrossWHs     = dbo.fn_Controls_GetAsString('Inventory', 'MoveReservedInvAcrossWHs',     'N' /* No */, @BusinessUnit, @UserId);

  /* Get Reason codes for Move/XFer Inventory */
  select @vDefaultWHXFerReasonCode  = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'DefaultWHXFer',  '130' /* CIMS Default */, @BusinessUnit, null),
         @vDefaultLPNMoveReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'DefaultLPNMove', '102' /* CIMS Default */, @BusinessUnit, null),
         @vWHXFerReasonCode         = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'WHXFer',         null /* Default */,       @BusinessUnit, null),
         @vLPNMoveReasonCode        = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'LPNMove',        null /* Default */,       @BusinessUnit, null);

  /* 1. Validation
     ##VM - Do we need to consider the following Ctrl var validations
       -> Multiple SKUs allowed in NewLocation???
       -> ???NewLocation allows SKU or not - Currently LocationSKU not using???
       -> NewLocation Max Limit or NO Limit ???
  */
  if (@NewLocationId is null) and (@NewLocation is not null)
    select @NewLocationId = LocationId
    from Locations
    where (Location = @NewLocation) and (BusinessUnit = @BusinessUnit);

  /* Validation - Location Type should be other than Picklane Location */
  select @vLocationType      = LocationType,
         @NewLocationId      = LocationId,
         @NewLocation        = Location,
         @vStorageType       = StorageType,
         @vLocPutawayZone    = PutawayZone,
         @vLocWarehouse      = Warehouse,
         @vAllowMultipleSKUs = AllowMultipleSKUs
  from Locations
  where (LocationId = @NewLocationId);

  if (@LPNId is null) and (@LPN is not null)
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);

  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vLPNDestWarehouse = DestWarehouse,
         @vLPNType          = LPNType,
         @vSKUId            = nullif(SKUId, ''),
         @vLPNStatus        = Status,
         @vLPNOnhandStatus  = OnhandStatus,
         @vPrevLPNStatus    = coalesce(@LPNStatus, Status),
         @vPalletId         = PalletId,
         @vLPNOrderId       = OrderId,
         @vReceiptId        = ReceiptId,
         @vReceiptNumber    = ReceiptNumber,
         @vReservedQty      = ReservedQty,
         @vLPNLocation      = Location,
         @vLPNReasonCode    = ReasonCode
  from LPNs
  where (LPNId = @LPNId);

  if (@vLPNOrderId is not null)
    select @vOrderType = OrderType,
           @vWaveType  = WaveType
    from vwOrderHeaders
    where (OrderId = @vLPNOrderId);

  /* If user is trying to move LPN to its own Location, then return */
  if (@NewLocation = coalesce(@vLPNLocation, ''))
    goto ExitHandler;

  /* Build the data for evaluation of rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('LPNId',           @LPNId) +
                         dbo.fn_XMLNode('Status',          @vLPNStatus) +
                         dbo.fn_XMLNode('LPNOnhandStatus', @vLPNOnhandStatus) +
                         dbo.fn_XMLNode('LocationId',      @NewLocationId) +
                         dbo.fn_XMLNode('LocationType',    @vLocationType) +
                         dbo.fn_XMLNode('LocPutawayZone',  @vLocPutawayZone) +
                         dbo.fn_XMLNode('ReceiptId',       @vReceiptId) +
                         dbo.fn_XMLNode('OrderId',         @vLPNOrderId) +
                         dbo.fn_XMLNode('OrderType',       @vOrderType) +
                         dbo.fn_XMLNode('WaveType',        @vWaveType) +
                         dbo.fn_XMLNode('FromWarehouse',   @vLPNDestWarehouse) +
                         dbo.fn_XMLNode('ToWarehouse',     @vLocWarehouse) +
                         dbo.fn_XMLNode('Operation',       'MoveLPN') +
                         dbo.fn_XMLNode('Validation',      'SyncLPNWithLocWH')
                         );

  /* Validations */
  if (@vLocationType = 'K' /* Picklane */)
    set @MessageName = 'CannotMoveLPNintoPickLane';
  else
  /* Restrict user to move LPN to Location, if the SKU of LPN being moved is not same as the SKU present in Location */
  if (@vAllowMultipleSKUs = 'N' /* No */) and
     (@vSKUId is not null) and
     (exists (select * from LPNs where LocationId = @NewLocationId and SKUId <> @vSKUId))
    set @MessageName = 'LocationDoesNotAllowMultipleSKUs';
  else
  if (@ReasonCode = '102' /* Cycle Counting */) and (@vLPNStatus = 'A'/* Allocated */)
    set @MessageName = 'LPNMove_CannotMoveAllocatedLPN';
  else
  if (@ReasonCode = '102' /* Cycle Counting */) and (@vReservedQty > 0)
    set @MessageName = 'LPNMove_CannotMoveAllocatedUnits';
  else
  if (((@vLPNType in ('C' /* Carton */, 'S'/* Ship Carton */)) and
       (@vPalletId is null) and (@vStorageType not in ('L' /* LPNs */, 'LA' /* Pallets & LPNs */))) or
      ((@vLPNType in ('C'/* Carton */, 'S' /* Ship Carton */)) and
       (@vPalletId is not null) and (@vStorageType not in ('A' /* Pallets */, 'LA' /* Pallets & LPNs */))))
    set @MessageName = 'LPNAndStorageTypeMismatch';
  else
  /* For staged LPNs it can be moved to Staging locations only */
  if (@vLPNStatus = 'E'/* Staged */) and
     (@vLocationType not in ('D', 'S'/* Dock, Staging */))
    set @MessageName = 'LPNMove_CanOnlyBeStaged';
  else
  if (@vLPNOrderId is not null) and (@ReasonCode <> '102' /* CC- Move LPN */) and
     (@vLocationType in ('R', 'B' /* Reserve, Bulk */))
    set @MessageName = 'LPNMove_NoAllocatedLPNinPickableLocation';
  else
  /* Do not allow Allocated/Partially Allocated LPNs to move to other Warehouse Locations */
  /* Not all clients wants to move reserved inventory between Warehouses but for HA
     they would like to move reserved inventory between contractor Warehouse to 04 or 08 Warehouses.
     If MoveReservedInvAcrossWHs is set to 'Y' then we need to define rules to move reserved inventory for RuleSet 'LPNMove_Validations' */
  if (@vReservedQty > 0) and (@vLocWarehouse <> @vLPNDestWarehouse) and
     (@vOrderType <> 'T'/* Transfer */) and (@vMoveReservedInvAcrossWHs = 'N' /* No */)
    select @MessageName = 'LPNMove_CannotMoveAllocatedLPNToOtherWarehouses';
  else
   /* Cannot move LPN into a location which does not match the Warehouse of the LPN */
    select @MessageName = dbo.fn_Putaway_ValidateWarehouse(@vLocWarehouse, @vLPNDestWarehouse, 'LPNMove', @BusinessUnit);

  if (@MessageName is not null)
    goto ErrorHandler;

  /* More validations - if there are any exceptions, catch block catches to raise the error */
  exec @vReturnCode = pr_LPNs_ValidateInventoryMovement @vLPNId, null /* @ToPalletId */, @NewLocationId, 'MoveLPN', @BusinessUnit, @UserId;

  /* Identify any status change when LPN is moved */
  exec pr_RuleSets_Evaluate 'LPNMove_ChangeStatus', @xmlRulesData, @vNewLPNStatus output;

  /* IF rules don't define the new status, then use the previous logic */
  if (@vNewLPNStatus is null)
    if (@vLPNStatus in ('N' /* New */, 'R' /* Received */, 'T' /* In Transit */, 'O' /* Lost */)) and
       (@vLocationType in ('R' /* Reserve */, 'B' /* Bulk */))
      set @vNewLPNStatus = 'P' /* Putaway */;
    else
    /* For New/Intransit, if it is moved to a staging location the LPNs should be marked as Received */
    if (@vLPNStatus in ('N' /* New */, 'T' /* In Transit */)) and
       (@vLocationType in ('C' /* Conveyor */, 'D' /* Dock */, 'S'/* Staging */)) and
       (@vReceiptId is not null)
      set @vNewLPNstatus = 'R' /* Received */;
    else
    /* For Lost, if it is moved to a staging location the LPNs should be marked as New */
    if (@vLPNStatus in ('O' /* Lost */) and
       (@vLocationType in ('S'/* Staging */)))
      set @vNewLPNstatus = 'N' /* New */

  /* Update LPN with New Location and update the Warehouse of the LPN to be that
     of the Location */
  update LPNs
  set @vOldLocationId    = LocationId,
      @vInnerPacks       = InnerPacks,
      @vQuantity         = Quantity,
      @vNewLPNStatus     = coalesce(@vNewLPNStatus, Status),
      @vOnhandStatus     = OnhandStatus,
      @vLPNNewWarehouse  =
      DestWarehouse      = case when (@vSyncLPNWithLocationWarehouse = 'N' /* No */) then DestWarehouse
                                /* if SyncLPN withLocWH and LPN status is not reserved then use LocWH */
                                when (Onhandstatus <> 'R' /* Reserved */) then @vLocWarehouse
                                /* if SyncLPNwithLocWH and LPN status is reserved then use LocWH
                                   only if Inv can be moved across WHs */
                                when (@vMoveReservedInvAcrossWHs = 'Y') then @vLocWarehouse
                                else DestWarehouse
                           end,
      LastMovedDate      = case when coalesce(LocationId, 0) <> coalesce(@NewLocationId, 0)
                                then current_timestamp
                                else LastMovedDate
                           end,
      ModifiedDate       = current_timestamp,
      ModifiedBy         = coalesce(@UserId, System_User)
  where (LPNId = @vLPNId);

  /* Update the new loaction on the LPN and clear the DestLocation and DestZone on the LPN */
  exec @vReturnCode = pr_LPNs_SetLocation @vLPNId, @NewLocationId, @NewLocation, @UpdateOption;

  /* Update ReceivedUnits = Quantity as user moving InTransit LPN directly to a location */
  if (@vLPNStatus = 'T' /* In transit */) and (@vReceiptId is not null)
    exec pr_LPNs_MarkAsReceived @vLPNId, @vReceiptId;

  /* New status should update to LPNs */
  exec @vReturnCode = pr_LPNs_SetStatus @vLPNId, @vNewLPNStatus output;

  /* Updated task detail's Location if Reserved Qty is greater than zero */
  if (@vReservedQty > 0)
    update TD
    set LocationId = @NewLocationId
    from TaskDetails TD
      join Tasks T on (T.TaskId = TD.TaskId)
    where (TD.LPNId = @vLPNId) and
          (T.status not in ('X' /* Cancel */, 'C' /* Completed */)) and
          (TD.status not in ('X' /* Cancel */, 'C' /* Completed */));

  /* if a New LPN has been putaway for the first time, then create an
     Inventory Change transaction. On the other hand, if a Received LPN has
     been putaway for the first time, create a Receipt Transaction */
  if (@vReturnCode = 0) and
     (@vPrevLPNStatus in ('N' /* New */, 'O' /* Lost */)) and
     (@vNewLPNStatus = 'P' /* Putaway */)
    begin
      /* If it is new LPN, then the reason for creating the new LPN was already specified at the time
         of creation, so use that, else use the passed in ReasonCode or default reasoncode i.e. CC */
      if (@vPrevLPNStatus = 'N' /* New */)
        set @ReasonCode = coalesce(@vLPNReasonCode, @vLPNMoveReasonCode, @vDefaultLPNMoveReasonCode);
      else
        /* Lost LPN - use passed in reason code */
        set @ReasonCode = coalesce(@ReasonCode, @vLPNMoveReasonCode, @vDefaultLPNMoveReasonCode);

      exec @vReturnCode = pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                             @LPNId      = @vLPNId,
                                             @TransQty   = @vQuantity,
                                             @ReasonCode = @ReasonCode,
                                             @Reference  = @Reference,
                                             @CreatedBy  = @UserId;
    end
  else
  /* Generating Exports for the LPNs which are in Intransit and Received Status */
  if (@vReturnCode = 0) and (@vReceiptId is not null) and -- For Transfers there may not be ReceiptId
     (@vPrevLPNStatus in ('R' /* Received */, 'T' /* In Transit */)) and
     (@vNewLPNStatus = 'P' /* Putaway */)
    begin
      /* There are three possibilities for a LPN to be received.
           1. Receipts got imported with a set of Intansit LPNs generated. Here the ReceiptId on these LPNs.
           2. By means Receivers, we create Instansit LPNs and we receive into it. Here, generated LPNs have Receipt info.
           3. Receipt doesn't have any Intransit LPN info over it. Hence we generate LPNs(with new status) and receive into. */

        /* All these categories are validated in the below procedure and will send the respective transactions */
        exec @vReturnCode = pr_Exports_LPNReceiptConfirmation @vReceiptId,
                                                              @vLPNId,
                                                              null /* LPNDetailId */,
                                                              @vQuantity,
                                                              @NewLocationId,
                                                              @vLPNDestWarehouse, /* From LPN Warehouse */
                                                              @UserId;
    end
  else /* If the LPN is moving from LOST Location to another Location then we
          need to export that as INVMove */
  if (@vReturnCode = 0) and
     (coalesce(@vPrevLPNStatus, @vNewLPNStatus) = 'P' /* putaway */) and
     (@vLPNLocation = 'LOST')
    begin
      exec @vReturnCode = pr_Exports_LPNData 'InvMove' /* Inventory Move */,
                                             @LPNId          = @vLPNId,
                                             @TransQty       = @vQuantity,
                                             @FromLocationId = @vOldLocationId,
                                             @FromLocation   = @vLPNLocation,
                                             @ToLocationId   = @NewLocationId,
                                             @ToLocation     = @NewLocation,
                                             @ReasonCode     = @ReasonCode,
                                             @Reference      = @Reference,
                                             @CreatedBy      = @UserId;
    end
  else
  if (@vOnhandStatus in ('A', 'R' /* Available, Reserved */)) and
     (coalesce(@vLPNDestWarehouse, '') <> coalesce(@vLPNNewWarehouse, ''))
    begin
      /* Set to default  reason if specific ones are not setup */
      select @ReasonCode = coalesce(@ReasonCode, @vWHXFerReasonCode, @vDefaultWHXFerReasonCode);

      exec pr_Exports_WarehouseTransfer @LPNId        = @vLPNId,
                                        @TransQty     = null,
                                        @LocationId   = @vOldLocationId,
                                        @ToLocationId = @NewLocationId,
                                        @BusinessUnit = @BusinessUnit,
                                        @OldWarehouse = @vLPNDestWarehouse,
                                        @NewWarehouse = @vLPNNewWarehouse,
                                        @ReasonCode   = @ReasonCode,
                                        @Reference    = @Reference,
                                        @CreatedBy    = @UserId;
    end

  /* Update Pallet count after Putaway LPN on Pallet. But sometimes LPN Move is called
     from Pallet procedure which would do the updates anyway after it processes all LPNs, so
     don't need to do this when not required */
  if (@vPalletId is not null) and (@vLPNType <> 'A' /* Cart Position */) and (charindex('P', @UpdateOption) > 0)
    exec pr_Pallets_UpdateCount @vPalletId, @UpdateOption = '*';

  -- Done in SetLocation above

  -- /* There are some times, we move a newly created LPN to a new Location.
  --    In that case, we will not have a Location on the LPN, so do not require
  --    Location Counts on it Ex: We call this procedure from pr_Receipts_ReceiveInventory
  --    */
  --  if (@vOldLocationId is not null) and
  --     (charindex('**', @UpdateOption) <> 0)
  --   begin
  --     /* Update Old Location Counts (-NumLPNs, -InnerPacks, -Quantity) */
  --     exec @vReturnCode = pr_Locations_UpdateCount @LocationId   = @vOldLocationId,
  --                                                  @NumLPNs      = 1,
  --                                                  @InnerPacks   = @vInnerPacks,
  --                                                  @Quantity     = @vQuantity,
  --                                                  @UpdateOption = '-' /* Subtract */;
  --
  --     if (@vReturnCode > 0)
  --       goto ExitHandler;
  --   end
  --
  -- if (charindex('**', @UpdateOption) <> 0)
  --   begin
  --     /* Update New Location Counts (+NumLPNs, +InnerPacks, +Quantity) */
  --     exec @vReturnCode = pr_Locations_UpdateCount @LocationId   = @NewLocationId,
  --                                                  @NumLPNs      = 1,
  --                                                  @InnerPacks   = @vInnerPacks,
  --                                                  @Quantity     = @vQuantity,
  --                                                  @UpdateOption = '+' /* Add */;
  --
  --     if (@vReturnCode > 0)
  --       goto ExitHandler;
  --   end

ErrorHandler:
  exec @vReturnCode = pr_Messages_ErrorHandler @MessageName, @vLPN;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Move */

Go
