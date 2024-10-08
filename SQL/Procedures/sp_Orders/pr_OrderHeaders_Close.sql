/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_OrderHeaders_Close: Validate units shipped for single shipment orders only (HA-2756)
  2021/04/19  AY      pr_OrderHeaders_Close: Changes to allow partial shipment of Transfers (HA GoLive)
  2021/03/12  TK      pr_OrderHeaders_Close: Mark Order as shipped based upon status calc controls variable (HA-2102)
  2021/02/25  PK      pr_OrderHeaders_Close: Get the Load Info to send in exports when the order is marked as shipped from orders page (HA-2071)
  2020/11/29  PK      pr_OrderHeaders_CloseReworkLPNs: Mapped OrderDetailId to send OD.UDFs to host(HA-1723).
  2020/11/10  AY/RKC  pr_OrderHeaders_Close: Fix issue with partial shipments (HA-1665)
  2020/10/21  TK      pr_OrderHeaders_Close: Bug fix in using charindex for OrderType (HA-1350)
  2020/09/16  AJM     pr_OrderHeaders_CloseReworkLPNs: Made changes to display AT message appropriately (HA-598)
  2020/09/11  TK      pr_OrderHeaders_CloseKitOrder: Initial Revision (HA-1238)
  2020/06/23  TK      pr_OrderHeaders_CloseReworkOrder: Update UnitsShipped while closing rework order (HA-833)
  2020/06/04  OK      pr_OrderHeaders_CloseReworkLPNs: CHanges to pass Source System (HA-815)
  2020/05/30  TK      pr_OrderHeaders_CloseReworkLPNs: Recalc Pallet Status (HA-623)
  2020/05/16  TK      pr_OrderHeaders_CloseReworkLPNs: Changes to log AT (HA-543)
  2020/05/15  TK      pr_OrderHeaders_Close: Rework order type 'R' -> 'RW' (HA-543)
  2020/05/13  MS      pr_OrderHeaders_CloseReworkLPNs: Use pr_PrepareHashTable for #ExportRecords (HA-350)
  2020/05/10  TK      pr_OrderHeaders_CloseReworkLPNs: Initial Revision (HA-475)
  2020/04/03  MS      pr_OrderHeaders_CloseBPT: Changes to caller (JL-65)
  2019/04/19  TK      pr_OrderHeaders_Close: Changes to invoke different procedure to close rework orders
                      pr_OrderHeaders_CloseReworkOrder: Initial Revision
  2018/11/15  TD      pr_OrderHeaders_CloseBPT:Changed datatype to avoid compatibility issues (OB2-739)
  2018/09/25  SPP     pr_OrderHeaders_Close: Modify the action names from close order to closePickTicket (CIMS-1941)
                      pr_OrderHeaders_Close: Bug fix for closing the order (S2G-630)
  2018/04/08  SV      pr_OrderDetails_Modify, pr_OrderHeaders_AfterClose, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close, pr_OrderHeaders_Modify (HPI-1842)
  2017/09/13  MV      pr_OrderHeaders_Close:  Added validation to not close the order if associated with load (HPI-1650)
  2017/07/24  TK      pr_OrderHeaders_CloseBPT: Unallocate if there is any inventory assigned to the Orders, if the Order is being closed (HPI-1597)
  2017/04/22  RV      pr_OrderHeaders_CloseBPT: Added PickTicket and Wave to the message description.(HPI-1256)
  2017/04/07  RV      pr_OrderHeaders_CloseBPT: Intial version (HPI-1256)
  2017/01/20  VM      pr_OrderHeaders_Close: Do not allow to close if there are any open tasks for the order (HPI-1301)
  2016/08/30  AY/SV   pr_OrderHeaders_Close/AfterClose: Send LoadId in ShipOH/OD records when shipped against a Load. (HPI-546)
  2016/08/15  PK      pr_OrderHeaders_Close: Added validation to prevent shipping of Order if any
  2015/03/25  DK      pr_OrderHeaders_Close: Added Control Variables to determine LPN status to close.
  2015/01/22  YJ      Added Picked status for pr_OrderHeaders_Close
  2015/01/02  AY      pr_OrderHeaders_Close: Allow to close an order only if something has been shipped against it
  2013/11/19  TD      pr_OrderHeaders_Close: Validating order status based on the shipment count.
  2013/10/28  NY      pr_OrderHeaders_Close: Added Control Variables to determine Order status to ship/complete.
  2013/10/19  PK      pr_OrderHeaders_Close: Updating the order based on the Shipped and AuthorizedToShip counts.
  2012/12/28  VM      pr_OrderHeaders_Close, pr_OrderHeaders_AfterClose: Handled log AT in one place
  2012/11/24  PKS     Added AT functionality to pr_OrderDetails_Modify, pr_OrderHeaders_CancelPickTicket, pr_OrderHeaders_Close
  2012/09/05  PKS     pr_OrderHeaders_Close: Validation issue was fixed.
  2012/06/13  NY      pr_OrderHeaders_Close: Added Additional validation on OrderClose to close only status of PKWC.
  2012/02/03  PK      pr_OrderHeaders_Close: Updating Batch Status on Order Close.
  2011/11/03  PKS/AY  pr_OrderHeaders_Close: Added addtional validations and also to
  2011/10/26  PKS/AY  pr_OrderHeaders_Close: Bug fixes in conditional checks
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Close') is not null
  drop Procedure pr_OrderHeaders_Close;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Close: Closing an Order is the final step of processing an
    Order. When the Order is closed ther are different actions to be taken against
    different types of Orders. Special Order types like Rework/Kit are handled
    separately and the core of this procedure is to handle transfer and customer
    orders.

  Apart from the validatons when an Order is closed we have to
  - Update the Order status as Shipped/Completed/Cancelled based upon what has happened
  - Close the LPNs (Ship or Consume them)
  - Perform the after close functions (exports, shipment notifications)

  Usage:
    Close function is called when the order on a Load is shipped.
    Close function can be called by user request from UI. This is the scenario
      when the order is not completely shipped but there is no intention to
      ship the order anymore.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Close
  (@OrderId      TRecordId,
   @PickTicket   TPickTicket,
   @ForceClose   TFlags = 'N',
   @LoadId       TRecordId,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vOrderId                  TRecordId,
          @vOrderType                TOrderType,
          @vShipCompletePercent      TPercent,
          @vStatus                   TStatus,
          @vNewStatus                TStatus,
          @vLPNId                    TRecordId,
          @vLPNQuantity              TQuantity,
          @vPickBatchNo              TPickBatchNo,
          @vControlValue             TControlValue,
          @vAuditActivity            TActivityType,
          @vActivityDateTime         TDateTime,
          @vUnitsShipped             TQuantity,
          @vUnitsAuthorizedToShip    TQuantity,
          @vUnitsAssigned            TQuantity,
          @vLPNsShippedUnits         TQuantity,
          @vMissingTrackingNos       TCount,
          @vCarrier                  TCarrier,
          @vIsSmallPackageCarrier    TFlag,
          @vShipVia                  TShipVia,

          /* Controls */
          @vOrderTypesToShip         TDescription,
          @vLPNStatusToClose         TStatus,
          @vOrderStatusToClose       TStatus,
          @vOrderTypesToComplete     TFlags,
          @vCCToOrderClose           TControlCode,
          @vStatusCalcMethod         TControlValue,
          @vIsMultiShipmentOrder     TFlags;
begin
  select @vReturnCode              = 0,
         @LoadId                   = nullif(@LoadId, 0),
         @vMessageName             = null,
         @vOrderTypesToShip        = dbo.fn_Controls_GetAsString('OrderClose', 'Ship', 'CET'/* Customer, Ecom, Transfer */, @BusinessUnit, null/* UserId */),
         @vOrderTypesToComplete    = dbo.fn_Controls_GetAsString('OrderClose', 'Complete', 'O'/* Out reserve */, @BusinessUnit, null/* UserId */),
         @vIsMultiShipmentOrder    = dbo.fn_Controls_GetAsString('OrderClose', 'IsMultiShipmentOrder', 'Y'/* Yes */, @BusinessUnit, null/* UserId */),
         @vStatusCalcMethod        = dbo.fn_Controls_GetAsString('OrderClose', 'StatusCalcMethod', 'UnitsAllocated', @BusinessUnit, null/* UserId */);

  /* If OrderId is not known, fetch it */
  if (@OrderId is null)
    select @OrderId = OrderId from OrderHeaders where PickTicket = @PickTicket and BusinessUnit = @BusinessUnit;

  /* Get Order Info */
  select @vOrderId              = OrderId,
         @vOrderType            = OrderType,
         @vStatus               = Status,
         @vPickBatchNo          = PickBatchNo,
         @vShipVia              = ShipVia,
         @vCCToOrderClose       = OrderType + '_' + @vIsMultiShipmentOrder,
         @vShipCompletePercent  = ShipCompletePercent,
         @vIsMultiShipmentOrder = IsMultiShipmentOrder
  from OrderHeaders
  where (OrderId = @OrderId);

  /* PK: 02-25-2021: When using Close Order direction from UI, then Get the Order LoadId
                     to send in the exports */
  if (@LoadId is null)
    begin
      select @LoadId = coalesce(LoadId, 0)
      from OrderShipments OS
        join Shipments S on (OS.ShipmentId = S.ShipmentId)
      where (OS.OrderId = @vOrderId) and
            (S.LoadId   is not null) and
            (S.Status   <> 'S' /* Shipped */);
    end

  /* If it is a rework order then invoke procedure to close it */
  if (@vOrderType in ('RW' /* Rework */))
    begin
      exec pr_OrderHeaders_CloseReworkOrder @vOrderId, default /* Operation */, default /* ReasonCode */,
                                            @BusinessUnit, @UserId;

      goto ExitHandler;
    end
  else
  /* If it is a kit order then invoke  procedure to close kit orders */
  if (@vOrderType in ('MK', 'BK'/* Make/Break Kits */))
    begin
      exec pr_OrderHeaders_CloseKitOrder @vOrderId, default /* Operation */, default /* ReasonCode */,
                                         @BusinessUnit, @UserId;

      goto ExitHandler;
    end

  /* Control Values */
  select @vLPNStatusToClose = dbo.fn_Controls_GetAsString('OrderClose_' + @vOrderType, 'ValidLPNStatusToClose', 'DLE' /* Packed/Loaded/Staged */, @BusinessUnit, null/* UserId */);
  select @vOrderStatusToClose = dbo.fn_Controls_GetAsString('OrderClose_' + @vOrderType, 'ValidOrderStatusToClose', 'WIPCKG' /* Waved/InProgress/Picked/Picking/Packed/Staged */, @BusinessUnit, null/* UserId */);

  -- Not setup in controls!!
  select @vControlValue = dbo.fn_Controls_GetAsString('OrderClose', @vCCToOrderClose, 'N',  @BusinessUnit, @UserId)

  /* Get the Shipped and UnitsAuthorizedToShip count */
  select @vUnitsShipped          = sum(UnitsShipped),
         @vUnitsAuthorizedToShip = sum(UnitsAuthorizedToShip),
         @vUnitsAssigned         = sum(UnitsAssigned)
  from OrderDetails
  where (OrderId = @vOrderId);

  /* Get the Shipvia of the order */
  select @vCarrier               = Carrier,
         @vIsSmallPackageCarrier = IsSmallPackageCarrier
  from ShipVias
  where (ShipVia = @vShipVia);

  /* Get count of LPNs which are not in valid status. */
  select @vMissingTrackingNos = sum(case when coalesce(TrackingNo, '') = '' then 1 else 0 end)
  from LPNs
  where (OrderId = @vOrderId);

  /* Validations */
  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsRequired';
  else
  if (@vOrderId is null)
    set @vMessageName = 'OrderDoesNotExist';
  else
  if (@vStatus in ('S' /* Shipped */, 'D' /* Completed */))
    set @vMessageName = 'OrderAlreadyClosed'
  else
  if (@vStatus in ('X' /* Canceled */, 'E' /* Cancel in progress */))
    set @vMessageName = 'OrderCanceledAndCannotbeClosed'
  else
  /* When invoked from UI (LoadId = 0), then ensure that the Order is not associated with any open Load
     When invoked from Load Shipping (LoadId is passed in) then we don't need this check
     if the ForceClose is No because we can have mulitple shipments and another shipment
     can be open in that case, else if it is not, then we have to ensure there is no other shipment */
  if ((coalesce(@LoadId, 0) = 0) or (@ForceClose = 'Y')) and
     (exists (select * from vwOrderShipments OS
                join Loads L on (L.LoadId = OS.LoadId)
              where ((OS.OrderId = @vOrderId) and
                     (coalesce(OS.LoadId, 0) <> 0) and
                     (OS.ShipmentStatus <> 'S') and
                     (L.Status not in ('S' /* Shipped */,'X' /* Canceled */)))))
    set @vMessageName = 'CannotCloseOrderOnLoad';
  else
  if (@vOrderType in ('R', 'RU', 'RP'))
    set @vMessageName = 'CannotCloseReplenishOrders';
  else
  if (@vIsMultishipmentOrder = 'N') and
     (exists(select * from TaskDetails
             where (OrderId = @vOrderId) and (Status not in ('C' /* Completed */, 'X' /* Cancelled */))))
    select @vMessageName = 'CloseOrderAllTasksNotCompleted';
  else
  if ((dbo.fn_IsInList(@vOrderType, 'E' /* E-Comm */) <> 0) and
     (@ForceClose = 'N' /* No */) and
     (exists (select * from LPNs
              where ((OrderId = @vOrderId) and
                     (Status <> 'S' /* Shipped */)))))
    set @vMessageName = 'CloseOrderAllUnitsAreNotShipped';
  else
  if (@ForceClose = 'N' /* No */) and
     (@vIsMultishipmentOrder = 'N') and
     (exists (select * from LPNs
              where ((OrderId = @vOrderId) and
                     (dbo.fn_IsInList(Status, @vLPNStatusToClose) = 0))))
    set @vMessageName = 'CloseOrderAllUnitsAreNotLoaded';
  else
  if ((dbo.fn_IsInList(@vStatus, @vOrderStatusToClose) = 0))
    set @vMessageName = 'OrderStatusInvalidForClosing';
  else
  if (@vIsSmallPackageCarrier = 'Y' /* Yes */) and
     (@vMissingTrackingNos > 0)
    set @vMessageName = 'ClosePickTicket_SomeLPNsMissingTrkNos';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Assigning status 'completed' if ordertype is transfer, for other types of order
     the status is shipped */
  if (charindex(@vStatus, 'NW' /* Not yet started Picking */) <> 0)
   begin
     select @vStatus = 'X' /* Canceled */
   end
  else
  if (charindex(@vOrderType, @vOrderTypesToComplete) <> 0) and
     ((@ForceClose = 'Y') or (@vUnitsShipped = @vUnitsAuthorizedToShip))
    select @vStatus = 'D' /* Completed */
  else
  if (@ForceClose = 'Y') or (@vUnitsShipped = @vUnitsAuthorizedToShip)
    select @vStatus = 'S' /* Shipped */
  else
  /* When StatusCalcMethod is by UnitsAllocated then mark the order as shipped when all units assigned are shipped */
  if (@vStatusCalcMethod = 'UnitsAllocated') and (@vUnitsShipped = @vUnitsAssigned)
    select @vStatus = 'S' /* Shipped */
  else
  /* When StatusCalcMethod is by ShipCompletePercent then mark the order as shipped when ShipCompletePercent is met */
  if (@vStatusCalcMethod = 'ShipCompletePercent') and ((@vUnitsShipped * 1.0 / @vUnitsAuthorizedToShip) * 100 >= @vShipCompletePercent)
    select @vStatus = 'S' /* Shipped */

  /* if Transfer/Out-Reserve orders are being marked as completed, we need to
     mark all LPNs as consumed */
  if (charindex(@vOrderType, @vOrderTypesToComplete) <> 0) and
     (@vStatus = 'D' /* Completed */)
    exec pr_OrderHeaders_CloseLPNs @vOrderId, 'Consume', null /* All statuses */, @BusinessUnit, @UserId;

  if (charindex(@vOrderType, @vOrderTypesToShip) <> 0) and
     (@vStatus = 'S' /* Shipped */)
    exec pr_OrderHeaders_CloseLPNs @vOrderId, 'Ship', @vLPNStatusToClose, @BusinessUnit, @UserId;

  /* Check to see if the Order has already been Shipped or completed */
  select @vNewStatus = Status
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Since LPNs have been shipped/consumed the OD numbers would have changed, fetch again */
  select @vUnitsShipped  = sum(UnitsShipped),
         @vUnitsAssigned = sum(UnitsAssigned)
  from OrderDetails
  where (OrderId = @vOrderId);

  /* Get LPNs Shipped Units */
  select @vLPNsShippedUnits = sum(Quantity)
  from LPNs
  where (OrderId = @vOrderId) and
        (Status in ('S' /* Shipped */));

  /* Sanity Checks: All these validations may have been done earlier, but we do them again
     after the Order is shipped to ensure we do not have any discrepencies during shipping process */

  /* For Transfer orders, previously shipped LPNs are not associated with Order any more so,
     the counts' won't match, so skip this check for Transfer Orders */
  if (@vOrderType <> 'T' /* Transfer */) and (@vLPNsShippedUnits <> @vUnitsShipped)
    set @vMessageName = 'MismatchOfUnitsShipped';
  else
  if (@vUnitsShipped = 0) or (@vLPNsShippedUnits = 0)
    set @vMessageName = 'OrderToBeCanceled'; -- If nothing has been shipped, cannot close the Order, has to be canceled
  else
  /* If order is marked as shipped, then all allocated units should have been shipped */
  if (@vStatus in ('S', 'D' /* Shipped or Completed */)) and (@vUnitsAssigned <> @vUnitsShipped)
    set @vMessageName = 'OrderNotShippedComplete';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If the order has not already been shipped or completed, then do so */
  if (@vNewStatus not in ('S', 'D' /* Shipped or completed */)) and
     (@vStatus in ('S', 'D' /* Shipped or Completed */)) and
     (@vUnitsAssigned = @vUnitsShipped)
    begin
      exec pr_OrderHeaders_SetStatus @vOrderId, @vStatus output, @UserId;

      /* Do the necessary updates that need to be done after an order has been closed */
      if (charindex(@vStatus, 'SDX' /* Shipped, Completed or Canceled */) <> 0)
        exec pr_OrderHeaders_AfterClose @vOrderId, @vOrderType, @vStatus, @LoadId, null/* ReasonCode */,
                                        @BusinessUnit, @UserId, 'Y'/* GenerateExports */, 'Order_Close'/* Operation */;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Close */

Go
