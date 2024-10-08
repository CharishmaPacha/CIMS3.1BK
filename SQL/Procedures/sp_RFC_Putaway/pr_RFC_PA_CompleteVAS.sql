/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/20  AY      pr_RFC_PA_CompleteVAS: Change pr_LPNs_Move to not recount Pallet if not needed (HA-3009)
  2017/04/12  TK      pr_RFC_PA_CompleteVAS & pr_RFC_ValidatePutawayLPNs:
  2017/03/31  PSK     pr_RFC_PA_CompleteVAS: Added validation to prevent using this for voided LPNs (HPI-1402)
  2017/02/23  TK      pr_RFC_PA_CompleteVAS: Do not allow complete production if LPN is not in Production Location or if
                        there are any open picks to be completed against the picked LPN (HPI-1325)
              PK      pr_RFC_PA_CompleteVAS: Considering Sew-2 orders under PickZone of PR, PR+ to be processed in
                        Complete Production process.
  2016/12/19  ??      pr_RFC_PA_CompleteVAS: Modified check condition (HPI-GoLive)
  2016/12/07  PK      pr_RFC_PA_CompleteVAS: Added a check to not to allow complete production on New Temp status LPNs.
  2016/11/15  AY      pr_RFC_PA_CompleteVAS: Changes to have LotNo be PickTicket or SalesOrder
  2016/11/07  AY      pr_RFC_PA_CompleteVAS: Added validation to prevent using this for Cart positions (HPI-GoLive)
  2016/10/20  ??      pr_RFC_PA_CompleteVAS: Modified check to consider WaveFlag PickBatchNo, and check for where clause to consider OrderCategory1 as 'Name Badges'(HPI-GoLive)
  2016/10/13  AY      pr_RFC_PA_CompleteVAS: Clear pallet of LPN (HPI-GoLive)
  2016/10/12  PK      pr_RFC_PA_CompleteVAS: Updating the LPNStatus to putaway to not to generate any +Ve exports.
  2016/09/26  VM      pr_RFC_PA_CompleteVAS: Migrated from PROD DB (HPI-GoLive)
  2016/09/13  AY      pr_RFC_PA_CompleteVAS: Use fn_LPNs_GetScannedLPN (HPI-GoLive)
  2016/09/08  TK      pr_RFC_PA_CompleteVAS: Bug fix - not to allow complete production when there is less inventory (HPI-561)
  2016/08/01  OK      pr_RFC_PA_CompleteVAS:
                        Enhanced to mark the LPNs as packed after Production if that belongs to Production Order
                        Restricted reducing the inventory from the picklane if Order is non Engraving orders (HPI-557)
  2016/08/30  AY      pr_RFC_PA_CompleteVAS: Validate qty for reduction of inventory (HPI-551)
  2016/07/27  AY      pr_RFC_PA_CompleteVAS: Reduce inventory from picklane
                      Enhanced to log the AuditTrail on Location (HPI-293).
  2016/07/29  AY      pr_RFC_PA_CompleteVAS: Maintain Engraving status using UDF10 instead of UDF5 (HPI-393)
  2016/07/12  DK      pr_RFC_PA_CompleteVAS: Corrected messages (HPI-257).
  2016/06/24  OK      Added pr_RFC_PA_CompleteVAS to putaway all the LPNs to scanned Location
                      Changes to log AT against (HPI-183)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_PA_CompleteVAS') is not null
  drop Procedure pr_RFC_PA_CompleteVAS;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_PA_CompleteVAS:

  Input:
  <CompleteVAS>
    <Operation>EngravingPutaway</Operation>
    <LocationId>12</LocationId>
    <Location>P01-002-1</Location>
    <LPN>C000003254</LPN>
    <BusinessUnit>HPI</BusinessUnit>
    <UserId>rfcadmin</UserId>
    <DeviceId>Pocket_PC</DeviceId>
  </CompleteVAS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_PA_CompleteVAS
  (@xmlInput     TXML,
   @xmlResult    TXML  output)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vMessage         TDescription,
          @vRecordId        TRecordId,

          @vLocationId      TRecordId,
          @vLocation        TLocation,
          @vLocationType    TLocationType,
          @vLocationStatus  TStatus,
          @vLocationPAZone  TZoneId,
          @vProdDropZone    TZoneId,
          @vLPNId           TRecordId,
          @vLPN             TLPN,
          @vLPNType         TTypeCode,
          @vLPNLotNo        TLot,
          @vLPNStatus       TStatus,
          @vNewLPNStatus    TStatus,
          @vLPNLocationId   TRecordId,
          @vLPNPalletId     TRecordId,
          @vOperation       TOperation,
          @vOrderId         TRecordId,
          @vLPNOrderId      TRecordId,
          @vOrderType       TTypeCode,
          @vOrderPickZone   TZoneId,
          @vVASRequirement  TOrderCategory,
          @vOpenPicksCount  TCount,

          /* Logical LPN */
          @vLogicalLPNId        TRecordId,
          @vLogicalLPN          TLPN,
          @vLogicalLPNDetailId  TRecordId,
          @vLogicalLPNLocationId
                                TRecordId,
          @vLogicalAvailQty     TQuantity,
          @vAdjustSKUId         TRecordId,
          @vAdjustQty           TQuantity,

          /* XML related */
          @xmlInputInfo     XML,
          @xmlResultInfo    XML,
          @vDeviceId        TDeviceId,
          @vBusinessUnit    TBusinessUnit,
          @vUserId          TUserId,

          @xmlRulesData     TXML,
          @vActivityLogId   TRecordId;

  declare @ttLPNDetails table (LPNId       TRecordId,
                               LPNDetailId TRecordId,
                               SKUId       TRecordId,
                               Quantity    TQuantity,
                               RecordId    TRecordid identity (1,1));

begin
begin try
  SET NOCOUNT ON;

  select @xmlInputInfo     = convert(xml, @xmlInput),
         @vRecordId        = 0;

  /* If no input, then exit */
  if (@xmlInput is null)
    return;

  /* Get UserId, BusinessUnit, LPN  from InputParams XML */
  select @vLocationId   = Record.Col.value('LocationId[1]',     'TRecordId'),
         @vLocation     = Record.Col.value('Location[1]',       'TLocation'),
         @vLPN          = Record.Col.value('LPN[1]',            'TLPN'),
         @vOperation    = Record.Col.value('Operation[1]',      'TOperation'),
         @vDeviceId     = Record.Col.value('DeviceId[1]',       'TDeviceId'),
         @vUserId       = Record.Col.value('UserId[1]',         'TUserId'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit')
  from @xmlInputInfo.nodes('CompleteVAS') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInputInfo, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vLPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the LPN info */
  select @vLPNId          = LPNId,
         @vLPNStatus      = Status,
         @vNewLPNStatus   = Status,
         @vLPNType        = LPNType,
         @vLPNLotNo       = Lot,
         @vLPNOrderId     = OrderId,
         @vLPNLocationId  = LocationId,
         @vLPNPalletId    = PalletId
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vLPN, @vBusinessUnit, default /* Options */));

  /* Get the Location Details */
  select @vLocationId     = LocationId,
         @vLocation       = Location,
         @vLocationType   = LocationType,
         @vLocationStatus = Status,
         @vLocationPAZone = PutawayZone
  from Locations
  where (Location     = @vLocation    ) and
        (BusinessUnit = @vBusinessUnit);

  /* Fetch the OrderId */
  select @vOrderId        = OrderId,
         @vVASRequirement = Ordercategory2 /* Production or Engraving */,
         @vOrderType      = OrderType,
         @vOrderPickZone  = PickZone
  from OrderHeaders
  where ((PickTicket = @vLPNLotNo) or (SalesOrder = @vLPNLotNo) or (OrderId = @vLPNOrderId)) and /* As we are not updating the PickTicket's LOT for ProductionOrders */
        (Status not in ('S')) and
        (BusinessUnit = @vBusinessUnit);

  /* get open picks count */
  select @vOpenPicksCount = count(*)
  from TaskDetails
  where (OrderId     = @vLPNOrderId) and
        (TempLabelId = @vLPNId     ) and
        (Status not in ('C', 'X'/* Completed/Cancelled */));

  /* Prepare XML for rules */
  set @xmlRulesData = dbo.fn_XMLNode('RootNode',
                        dbo.fn_XMLNode('LPNId',         @vLPNId) +
                        dbo.fn_XMLNode('LPN',           @vLPN) +
                        dbo.fn_XMLNode('LocationId',    @vLocationId) +
                        dbo.fn_XMLNode('Location',      @vLocation) +
                        dbo.fn_XMLNode('LPNLocationId', @vLPNLocationId) +
                        dbo.fn_XMLNode('OrderId',       @vOrderId) +
                        dbo.fn_XMLNode('OrderPickZone', @vOrderPickZone));

  /* get Prod Drop zone to validate further */

  /* Validations */
  if (nullif(@vLocationId,0) is null)
    select @vMessageName = 'LocationDoesNotExist';
  else
  if (@vLocationStatus in ('I' /* Inactive */))
    select @vMessageName = 'PALocationIsInactive'
  else
  if (coalesce(@vLPN, '') = '')
    select @vMessageName = 'LPNIsRequired';
  else
  if ((@vLPN is not null) and (coalesce(@vLPNId, '') = ''))
    select @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNType =  'L' /* Picklane */)
    select @vMessageName = 'LPNTypeCannotbePickLane';
  else
  if (@vLocationType not in ('D', 'R', 'S'/* Dock, Reserve, Staging */))
    select @vMessageName = 'LocationTypeIsInvalid';
  else
  if (@vLPNLocationId = @vLocationId)
    select @vMessageName = 'LPNIsAlreadyInSameLocation';
  else
  if (@vLPNStatus in ('C' /* Consumed */))
    select @vMessageName = 'LPNConsumed';
  else
  if (@vLPNStatus in ('V' /* Voided */))
    select @vMessageName = 'LPNVoided';
  else
  if (@vLPNStatus in ('S' /* Shipped */))
    select @vMessageName = 'LPNAlreadyShipped';
  else
  if (@vLPNType in ('A' /* Cart */))
    select @vMessageName = 'CompleteVAS_NotRequiredOnCart';
  else
  if (@vLPNStatus in ('F' /* New Temp */))
    select @vMessageName = 'CompleteVAS_RequiresToPickFirst';
  else
  if (@vLPNOrderId is not null) and (@vOpenPicksCount > 0)
    select @vMessageName = 'CompleteVAS_OpenPicksToComplete';
  else
    /* Other custom validations */
    exec pr_RuleSets_Evaluate 'CompleteVAS_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* LPN should not be on a pallet by this time. May be it wasn't dropped off correctly after picking, so clear it */
  if (@vLPNPalletId is not null)
    exec pr_LPNs_SetPallet @vLPNId, null /* Clear Pallet */, @vUserId;

   /* If the LPN is in New status then mark the LPN as Putaway to avoid InvCh transactions which we are sending to SAGE */
  if (@vLPNStatus = 'N'/* New */)
    begin
      update LPNs
      set @vNewLPNStatus  =
          Status          = 'P' /* Putaway */,
          OnhandStatus    = 'A' /* Available */
      where (LPNId        = @vLPNId) and
            (BusinessUnit = @vBusinessUnit);

      update LPNDetails
      set OnhandStatus = 'A' /* Available */
      where (LPNId        = @vLPNId) and
            (OnhandStatus = 'U' /* Unavailable */) and
            (BusinessUnit = @vBusinessUnit);
  end

  /* Move the LPN to the scanned location and set the status of the LPN */
  exec @vReturnCode = pr_LPNs_Move @vLPNId,
                                   @vLPN,
                                   @vNewLPNStatus,
                                   @vLocationId,
                                   @vLocation,
                                   @vBusinessUnit,
                                   @vUserId,
                                   'LP' /* UpdateOption - only Location updates need confirmation on Exports */;

  /* Mark the LPN as Packed if that is the Production Order */
  if ((@vVASRequirement in ('Production', 'Engraving')) or
      ((@vOrderType in ('S'/* Sew-2 */)) and (@vOrderPickZone in ('PR', 'PR+')))) and
     (@vLPNOrderId is not null) and
     (@vLocationType in ('S', 'D'))
    begin
      update LPNs
      set Status = 'D' /* Packed */
      where (LPNId = @vLPNId);

      /* If all the LPNs are marked as Packed then Order should be marked as Paced */
      exec pr_OrderHeaders_SetStatus @vLPNOrderId, null /* Status */, @vUserId;
    end

  /* Update WaveFlag and UDF fields in Order Header */
  if ((@vLPNLotNo is not null) and (@vLPNOrderId is null))
    begin
      update OrderHeaders
      set UDF10    = 'Completed',
          WaveFlag = case when (PickBatchNo is null) and (WaveFlag = 'O' /* Onhold */) then '' /* Can be waved now */
                          else WaveFlag /* No change */
                     end
      where (OrderId = @vOrderId) and
            ((OrderCategory2 in ('Engraving')) or (OrderCategory1 = 'Name Badges'));
    end

  if ((@vVASRequirement = 'Engraving') and (@vLPNOrderId is null)) and (@vLPNStatus = 'N')
    begin
      /* Get the details of the LPN completed so that we can find the Picklane to reduce the inventory from */
      insert into @ttLPNDetails
        select LPNId, LPNDetailId, SKUId, Quantity
        from LPNDetails
        where (LPNId = @vLPNId);

      /* Iterate thru each SKU and adjust it down from a picklane */
      while (exists (select * from @ttLPNDetails where RecordId > @vRecordId))
        begin
          select top 1
                 @vRecordId    = RecordId,
                 @vAdjustSKUId = SKUId,
                 @vAdjustQty   = Quantity
          from @ttLPNDetails
          where (RecordId > @vRecordId)
          order by RecordId;

          /* Find the Logical LPNDetail to adjust */
          select @vLogicalLPNId       = LPNId,
                 @vLogicalLPN         = LPN,
                 @vLogicalLPNDetailId = LPNDetailId,
                 @vLogicalAvailQty    = Quantity
          from vwLPNDetails
          where (LPNType      = 'L' /* Logical */  ) and
                (LocationType = 'K' /* Picklane */ ) and
                (SKUId        = @vAdjustSKUId      ) and
                (OnhandStatus = 'A' /* Available */) and
                (Quantity     > 0);

          /* If we do not have a location or do not have enough to adjust the entire qty, raise an error */
          if (@@rowcount = 0)
            begin
              if (@vRecordId = 1)
                select @vMessageName = 'CompleteVAS_NoPicklaneToAdjustInv';
              else
                select @vMessageName = 'CompleteVAS_NotEnoughInvToAdjust';

              goto ErrorHandler;
            end;

          /* Get the LocationId for that Logical LPN i,e Picklane */
          select @vLogicalLPNLocationId = LocationId
          from Locations
          where (Location     = @vLogicalLPN  ) and
                (BusinessUnit = @vBusinessUnit);

          /* If Available qty is less than what needs to be adjusted, reduced it down */
          select @vAdjustQty = dbo.fn_MinInt(@vAdjustQty, @vLogicalAvailQty);

          /* Calling Core Procedure */
          exec pr_LPNs_AdjustQty @vLogicalLPNId,
                                 @vLogicalLPNDetailId,
                                 @vAdjustSKUId,
                                 null /* SKU */,
                                 0 /* Inner Packs */,
                                 @vAdjustQty,
                                 '-' /* Update Option - Exact Qty */,
                                 'N' /* Export? No */,
                                  0   /* Reason */,
                                  @vLPNId /* Reference */,
                                  @vBusinessUnit,
                                  @vUserId;

          /* Audit Trail */
          exec pr_AuditTrail_Insert 'VAS_InventoryAdjustment', @vUserId, null /* ActivityTimestamp */,
                                    @LPNId          = @vLogicalLPNId,
                                    @LocationId     = @vLogicalLPNLocationId,
                                    @Quantity       = @vAdjustQty,
                                    @Note1          = @vLPN,
                                    @Note2          = @vLPNLotNo; /* LPN LotNo is a PickTicket */
        end
    end

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'VAS_CompleteProduction', @vUserId, null /* ActivityTimestamp */,
                            @LPNId          = @vLPNId,
                            @OrderId        = @vOrderId,
                            @LocationId     = @vLocationId;

  /* Build XmlMessage to RF */
  exec pr_BuildRFSuccessXML 'CompleteProductionSuccess', @xmlResultInfo output;

  set @xmlResult = convert(varchar(max), @xmlResultInfo)

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResultInfo output;
  set @xmlResult = convert(varchar(max), @xmlResultInfo)

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_PA_CompleteVAS */

Go
