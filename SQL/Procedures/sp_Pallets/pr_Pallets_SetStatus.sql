/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  AY      pr_Pallets_SetStatus: Use Built status (BK-319)
  2021/03/05  PK      pr_Pallets_SetStatus: Ported changes done by Pavan (HA-2152)
  2021/01/21  TK      pr_Pallets_SetStatus: OrderId should be null if order count not '1' (HA-1934)
  2020/12/02  AY      pr_Pallets_SetStatus: Revised status computation (HA-1747)
  2020/08/25  VS      pr_Pallets_SetStatus: Update Pallet Status when Transfer Putaway LPN to Pallet (CIMSV3-1076)
  2020/06/23  SK      pr_Pallets_SetStatus: Consider Shipping Pallet Type when evaluating Pallet status to be marked
                        as SG (HA-905)
  2020/05/30  TK      pr_Pallets_SetStatus: When Picked LPNs on picking pallet is marked as putaway then mark
                        pallet type as inventory pallet & status to putaway (HA-623)
  2020/05/15  TK      pr_Pallets_SetStatus: Built status applicable only for receiving & inventory pallet (HA-543)
  2020/05/05  AY      pr_Pallets_SetStatus: Set status to Built if new LPNs added to Pallet
  2020/04/03  MS      pr_Pallets_SetStatus: Changes to update pallettype as receiving pallet (JL-202)
  2020/02/24  MS      pr_Pallets_SetStatus: Changes to update InTransit & Receiving Statuses (JL-124)
  2019/06/03  TD      pr_Pallets_SetStatus:Changes to conisder packed status LPNs as staged pallet (S2GCA-832)
  2018/08/10  AY/PK   pr_Pallets_SetStatus: Added changes to consider PalletType Shipping Pallet as well: Migrated from Staging (S2GCA-98)
  2018/08/07  TD/AY   pr_Pallets_SetStatus: Added check to consider status ('E', 'P'): Migrated from Prod (OB2-190)
  2018/06/08  RV      pr_Pallets_SetStatus: Made changes to clear TaskId while pallet is empty (OB2-494)
  2017/12/27  SV      pr_Pallets_SetStatus: Status corrections upon allocation/unallocation/putaway of the LPNs over an Inv Pallet - WIP (HPI-1518)
  2017/10/26  DK      pr_Pallets_SetStatus: Upgraded to set the pallet status to Picking (CIMS-1653)
                        Included staged type of LPNs as well to set the pallet status to Staged.
                        Bug fix, we will not allocate picking Cart and Picking Pallet.
  2017/09/14  SV      pr_Pallets_SetStatus: Upgrading the procedure for not considering the prev status in setting up the current status (CIMS-1459)
  2017/03/27  ??      pr_Pallets_SetStatus: Modified check to consider PalletType Picking Pallet as well (HPI-GoLive)
  2017/03/23  DK      pr_Pallets_SetStatus: Bug fix to not change Picking Pallet status to allocation (HPI-1471)
  2017/01/11  MV      pr_Pallets_SetStatus: Packing by user clear when all units are packed from the cart (HPI-1247)
  2016/11/15  VM      pr_Pallets_SetStatus: Clear pallet location, if it is shipped (HPI-1055)
  2016/07/18  TK      pr_Pallets_SetStatus: Bug Fix to update Pallet status to Picked when there are some LPNs on the pallet are in Packing Status (HPI-326)
  2016/04/20  TK      pr_Pallets_SetStatus: Bug fix to update Picked status correctly (NBD-407)
  2016/01/04  TK      pr_Pallets_SetStatus: If a Picked LPN is added to a Pallet then we are marking it as picked and while dropping
                        built pallet into a Location we need update its status as Picked (ACME-454)
  2015/12/18  PK      pr_Pallets_SetStatus: Consider Staging location as well to set Pallet status to Putaway when none of the LPN on it is allocated any Order (FB-576)
  2015/12/13  TK      pr_Pallets_SetStatus: Bug fix - consider Status while counting Allocated LPNs
  2015/12/01  VM/RV   pr_Pallets_SetStatus: Set status Allocated if all LPNs on pallet allocated (FB-552)
  2015/07/30  AY      pr_Pallets_SetStatus: LoadedLPNCount computed incorrectly - it is not the LPNs on Load
                        it is LPNs that are loaded into the truck (acme-268)
  2014/09/01  DK      pr_Pallets_SetStatus: Change PalletType only if not a Pick Cart.
  2014/07/19  TD      pr_Pallets_SetStatus:set status as received if the LPNs on the pallet are received.
  2013/12/22  PK      pr_Pallets_SetStatus: As we are not using Transfer Pallets, so we might use empty
                        status pallets, so included empty status in all checks.
  2013/10/19  PK      pr_Pallets_UpdateCount: Updating LoadId and ShipmentId on the Pallet.
                      pr_Pallets_SetStatus: Updating the status of the Pallet.
  2013/05/04  PK      pr_Pallets_SetStatus: Bug fix in packing updating the Modified by on pallet.
  2013/05/04  AY      pr_Pallets_SetStatus: Change PalletType only if not a Pick Cart.
  2012/10/04  AY      pr_Pallets_SetStatus: Revert status back to PA when unallocated,
                        update status of Lost Pallet to PA when Located
  2012/09/06  AY      pr_Pallets_SetStatus: Set Pallet Type as well for obvious scenarios.
  2012/05/18  YA      Reflection of signature changes on pr_Pallets_SetStatus, Inculded UserId as i/p param on pr_Pallets_UpdateCount.
  2012/05/04  YA      pr_Pallets_SetStatus: Updated pallet status to 'R'-Received in case it is in status 'E'-Empty and has no Location
  2012/04/02  AY      pr_Pallets_SetStatus: Changed to compute Qty from LPNs instead of relying the one on Pallet.
  2012/03/29  PK      Added pr_Pallets_UpdateCount, pr_Pallets_SetStatus: Computing Empty Status.
  2011/10/30  VM      pr_Pallets_SetStatus: Bug-fix in clearing PickBatchNo, also include PickBatchId as clearing field
  2011/10/26  AY      pr_Pallets_SetStatus: Clear PickBatchNo when Pallet becomes empty.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_SetStatus') is not null
  drop Procedure pr_Pallets_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_SetStatus:
    This procedure is used to change/set the 'Status' of the Pallet.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it does not do any thing right now.
                 NEED TO ENHANCE TO CALCULATE THE STATUS.
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_SetStatus
  (@PalletId     TRecordId,
   @Status       TStatus = null output,
   @UserId       TUserId = null)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vBusinessUnit       TBusinessUnit,

          @vQuantity           TQuantity,
          @vPalletStatus       TStatus,
          @NewStatus           TStatus,
          @vPalletType         TTypeCode,
          @vNewPalletType      TTypeCode,
          @vLocation           TLocation,
          @vLocationType       TTypeCode,
          @vPickCarts          TTypeCode,
          @vIsPickingCart      TFlags,

          @vLPNCount           TCount,
          @vEmptyCartPositions TCount,
          @vPalletQuantity     TCount,
          @vPutawayQuantity    TCount,
          @vInTransitLPNCount  TCount,
          @vPutawayLPNCount    TCount,
          @vPickingLPNCount    TCount,
          @vPickedLPNCount     TCount,
          @vPackedLPNCount     TCount,
          @vStagedLPNCount     TCount,
          @vLoadedLPNCount     TCount,
          @vShippedLPNCount    TCount,
          @vAllocatedLPNCount  TCount,
          @vReceivedLPNCount   TCount,

          @vOrderId            TRecordId,
          @vOrderCount         TCount;
begin /* pr_Pallets_SetStatus */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vNewPalletType = null;

  select @vPalletStatus   = Status,
         @vPalletType     = PalletType,
         @vLocation       = Location,
         @vLocationType   = LocationType,
         @vBusinessUnit   = BusinessUnit,
         @vPalletQuantity = Quantity
  from vwPallets
  where (PalletId = @PalletId);

  select @vPickCarts = dbo.fn_Controls_GetAsString('PalletTypes', 'PickCarts', 'CTH',
                                                   @vBusinessUnit, @UserId);

  select @vIsPickingCart = case when (charindex(@vPalletType, @vPickCarts) <> 0) then 'Y' else 'N' end;

  /* Compute the status if not given */
  if (@Status is null)
    begin
      /* Get pallet quantity to compute pallet status */
      select @vQuantity           = sum(Quantity),
             @vPutawayQuantity    = sum(case when status = 'P' then Quantity else 0 end),
             @vLPNCount           = count(distinct LPNId),
             @vEmptyCartPositions = sum(case when ((Status = 'N' /* New */) and (LPNType = 'A'/* Cart */)) then 1 else 0 end),
             @vInTransitLPNCount  = sum(case when (Status = 'T' /* InTransit */) then 1 else 0 end),
             @vReceivedLPNCount   = sum(case when (Status = 'R' /* Received */) then 1 else 0 end),
             @vPutawayLPNCount    = sum(case when (Status = 'P') then 1 else 0 end),
             @vAllocatedLPNCount  = sum(case when (OrderId is not null) then 1 else 0 end),
             @vPickingLPNCount    = sum(case when (Status in ('U' /* Picking */))then 1 else 0 end),
             /* Since we don't have packing status for pallet, consider LPNs with packing on pallet as picked LPNs */
             @vPickedLPNCount     = sum(case when (charindex(Status, 'KGDEL' /* Picked,Packing,Packed,Staged,Loaded */) > 0) then 1 else 0 end),
             @vPackedLPNCount     = sum(case when (charindex(Status, 'D' /* Packed */) > 0) then 1 else 0 end),
             @vStagedLPNCount     = sum(case when (charindex(Status, 'E' /* Staged */) > 0) then 1 else 0 end),
             @vLoadedLPNCount     = sum(case when (charindex(Status, 'LS' /* Loaded, Shipped */)> 0) then 1 else 0 end),
             @vShippedLPNCount    = sum(case when (Status = 'S'/* Shipped */) then 1 else 0 end),
             @vOrderCount         = count(distinct OrderId),
             @vOrderId            = min(OrderId)
      from LPNs
      where (PalletId = @PalletId);

      /* If there are no LPNs on the pallet then set the counts to zero */
      select @vLPNCount           = coalesce(@vLPNCount,           0),
             @vOrderCount         = coalesce(@vOrderCount,         0),
             @vQuantity           = coalesce(@vQuantity,           0),
             @vEmptyCartPositions = coalesce(@vEmptyCartPositions, 0);

      /* If the Pallet Quantity is 0, then set the pallet status to empty */
      if (coalesce(@vQuantity, 0) = 0)
        set @Status = 'E' /* Empty */;
      else
      if (@vIsPickingCart = 'N') and (@vLPNCount > 0) and (@vLPNCount = @vShippedLPNCount)
        set @Status = 'S' /* Shipped */
      else
      if (@vIsPickingCart = 'N') and (@vLPNCount > 0) and (@vLPNCount = @vLoadedLPNCount)
        set @Status = 'L' /* Loaded */;
      else
      if (@vIsPickingCart = 'N') and (@vLPNCount > 0) and (@vLPNCount = @vStagedLPNCount)
        set @Status = 'SG' /* Staged */;
      else
      if (@vIsPickingCart = 'N') and (@vLPNCount > 0) and (@vLPNCount = @vPackedLPNCount)
        set @Status = 'D' /* Packed */
      else
      /* There may some picked LPNs and some new LPNs, Update to picked if both the LPN counts is equal to Total LPN count */
      if (charindex(@vPalletType, 'C' /* Picking Cart */) > 0) and
         ((@vPickedLPNCount > 0) and (@vLPNCount = @vPickedLPNCount + @vEmptyCartPositions))
        set @Status = 'K' /* Picked */;
      else
      if (charindex(@vPalletType, 'IPS' /* Inventory, Picking Pallet ,Shipping Pallet */) > 0) and
         (@vLPNCount = @vPickedLPNCount) and
         (@vPickedLPNCount > 0)
        set @Status = 'K' /* Picked */
      else
      if (@vPickingLPNCount > 0) or (@vPickedLPNCount > 0)
        set @Status = 'C' /* Picking */;
      else
      if (@vLPNCount = @vAllocatedLPNCount) and
         (charindex(@vPalletType, 'I' /* Inventory */) > 0)
        set @Status = 'A' /* Allocated */;
      else
      /* This is the case where few/all LPNs of the Pallet allocated to different Orders.
         This means that the pick can be treated as LPN Pick and hence Pallet Status will be in Putaway */
      if (charindex(@vPalletType, 'RIP' /* Receiving, Inventory, Picking */) > 0) and
         (@vLocationType in ('R', 'B', 'S' /* Reserve, Bulk, Staging */)) and
         (@vPutawayLPNCount > 0)
        set @Status = 'P' /* Putaway */;
      else
      /* Pallet may not be in a Location, but if built with all Putaway LPNs,
         Pallet should be considered Putaway as well */
      if (@vPalletQuantity = @vPutawayQuantity) and (@vPutawayQuantity > 0)
        set @Status = 'P' /* Putaway */
      else
      if (coalesce(@vLPNCount, 0) > 0) and (@vLPNCount = @vInTransitLPNCount)
        set @Status = 'T'  /* InTransit */;
      else
      /* If all LPNs on Pallet are in received Status, then Pallet should be in Received Status */
      if (coalesce(@vLPNCount, 0) > 0) and (@vLPNCount = @vReceivedLPNCount)
        set @Status = 'R'  /* Received */;
      else
      /* If some LPNs on the Pallet are in received Status and some aren't, then it is in Receiving */
      if (coalesce(@vLPNCount, 0) > 0) and (@vReceivedLPNCount > 0)
        set @Status = 'J' /* Receiving */;
      else
      /* If all else fails because there are diff. status LPNs on same pallet, we would say it is built */
      if (charindex(@vPalletType, @vPickCarts) = 0) and (@vQuantity > 0)
        set @Status = 'B' /* Built */;
    end

  /* Determine Type of Pallet for obvious scenarios, but don't change PickCarts */
  if (charindex(@vPalletType, @vPickCarts) = 0)
    begin
      if (@Status in ('C', 'K' /* Picking, Picked */))
        set @vNewPalletType = 'P' /* Picking Pallet */;
      else
      if (@Status in ('E', 'P' /* Empty, Putaway */))
        set @vNewPalletType = 'I' /* Inventory Pallet */;
      else
      if (@Status in ('T', 'J', 'R' /* InTransit, Receiving, Received */))
        set @vNewPalletType = 'R' /* Receiving Pallet */;
      else
      if (@Status in ('SG', 'L', 'S' /* Staged, Loaded, Shipped */))
        set @vNewPalletType = 'S' /* Shipping Pallet */;
    end

  /* Update Pallet with the status, if the pallet has become empty, clear the
     PickBatchNo so that it can be reused

     ModifiedBy - if the parameter (@UserId) is null and then updating with
     the existing ModifiedBy, if ModifiedBy is null then updating with the
     system user */
  update Pallets
  set @NewStatus   =
      Status       = coalesce(@Status, Status),
      PalletType   = coalesce(@vNewPalletType, PalletType),
      Quantity     = coalesce(@vQuantity, Quantity),
      LocationId   = case
                       when @NewStatus = 'S' /* Shipped */ then null
                       else LocationId
                     end,
      PickBatchNo  = case
                       when @NewStatus = 'E' /* Empty */ then null
                       else PickBatchNo
                     end,
      PackingByUser = case
                        when @Status = 'E' /* Empty */ then null
                        else PackingByUser
                      end,
      PickBatchId  = case
                       when @NewStatus = 'E' /* Empty */ then null
                       else PickBatchId
                     end,
      OrderId      = case
                        when @vLPNCount = @vAllocatedLPNCount and @vOrderCount = 1 then @vOrderId
                        else null
                     end,
      TaskId       = case when @Status in ('E', 'P') then null
                          else TaskId
                     end,
      ModifiedDate = current_timestamp,
      ModifiedBy   = coalesce(@UserId, ModifiedBy, System_User)
  where (PalletId = @PalletId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_SetStatus */

Go
