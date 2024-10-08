/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/30  TK      fn_OrderHeaders_OrderQualifiedToShip: migrated from HPI
                      pr_OrderHeaders_UnWaveOrders: Code optimization
                      pr_OrderHeaders_DisQualifiedOrders: Inital Revision (S2G-530)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_OrderHeaders_OrderQualifiedToShip') is not null
  drop Function fn_OrderHeaders_OrderQualifiedToShip;
Go
/*------------------------------------------------------------------------------
  fn_OrderHeaders_OrderQualifiedToShip: Returns Boolean value 'Y/N' based upon the
    computations to be made before we ship an order.

  ValidationFlags: S - Ship Complete Validation, K - Kit validation
------------------------------------------------------------------------------*/
Create Function fn_OrderHeaders_OrderQualifiedToShip
  (@OrderId          TRecordId  = null,
   @Operation        TOperation = null,
   @ValidationFlags  TFlags     = 'SK')
  returns TFlag
as
begin
  declare @vOrderQualifiedToShip    TFlag,
          @vOrderId                 TRecordId,
          @vOrderType               TTypeCode,
          @vOrderedDate             TDateTime,

          @vAllocatedUnits          TQuantity,
          @vOrderedUnits            TQuantity,

          @vSCPercent               TPercent,
          @vSCThresholdDays         TInteger,
          @vOrderAllocPercent       TPercent;

  select @vOrderQualifiedToShip = 'N' /* No */;

  /* get Order info */
  if (@OrderId is not null)
    select @vOrderId         = OrderId,
           @vOrderType       = OrderType,
           @vOrderedDate     = OrderDate,
           @vSCPercent       = coalesce(ShipCompletePercent, 0), -- By Default ShipComplete percent is 100 for some clients
           @vSCThresholdDays = 999
    from OrderHeaders
    where (OrderId = @OrderId);

  /* get the Order Allocation Percentage */
  select @vAllocatedUnits = sum(UnitsAssigned),
         @vOrderedUnits   = sum(UnitsAuthorizedToShip)
  from OrderDetails
  where (OrderId = @vOrderId);

  /* if nothing allocated, then order is not qualifed to ship, so return */
  if (@vAllocatedUnits = 0) or (@vOrderedUnits = 0)
    return @vOrderQualifiedToShip;

  /* if order type is bulk then we should return back as Yes because we don't have any
     shipcomplete% on bulk orders */
  if (@vOrderType = 'B' /* Bulk */)
    begin
      select @vOrderQualifiedToShip = 'Y' /* Yes */;

      return @vOrderQualifiedToShip;
    end

  /* compute order allocation percentage */
  select @vOrderAllocPercent = coalesce((@vAllocatedUnits * 1.0 / @vOrderedUnits) * 100, 0);

  /* If Kits are partially allocated, then the order is disqualified for shipping.
      Kits lines are identified by the parent line type being A
      Kit is partially allocated if the Components allocated for all lines are not for same number of Kits
      ODC.UnitsAuthorizedToShip / ODK.UnitsOrdered = UnitsOfComponentPerKit
      ODC.UnitsAssigned / (ODC.UnitsAuthorizedToShip / ODK.UnitsOrdered) = Number of Kits for which we have allocated the components
      if Min/Max of Number of Kits is not same, then it means that the diff. components are allocated to make diff. kits.
  */
  if (charindex('K', @ValidationFlags) <> 1) and
     (exists(select ODK.HostOrderLine
             from OrderDetails ODK join OrderDetails ODC on (ODK.OrderId = ODC.OrderId) and (ODK.HostOrderLine = ODC.UDF7)
             where (ODK.OrderId  = @vOrderId) and
                   ((ODK.LineType = 'A' /* Assembly */) and (ODK.UnitsOrdered > 0)) and
                   (ODC.LineType in ('1', '2')) and (ODC.UnitsOrdered > 0)
             group by ODK.HostOrderLine
             having Min(ODC.UnitsAssigned / (ODC.UnitsAuthorizedToShip * 1.0 / ODK.UnitsOrdered)) <>
                    Max(ODC.UnitsAssigned / (ODC.UnitsAuthorizedToShip * 1.0 / ODK.UnitsOrdered))))
   return @vOrderQualifiedToShip;

 /* Since the default value for @vOrderQualifiedToShip is set to 'N', let's verify the conditions where Order can be Qualified

     Conditions to Qualify Order to Ship:
     1. Qualify, if Order Allocation percentage is greater than or equal to Ship Complete percent.
     2. Qualify, if Order has at least one unit to ship and it has passed its ship complete due date.
  */
  if (charindex('S', @ValidationFlags) = 0) /* If SC validation is not required */
     or
     (@vOrderAllocPercent >= @vSCPercent)
     or
     ((@vOrderAllocPercent > 0) and (datediff(d, @vOrderedDate, current_timestamp) > @vSCThresholdDays))
    select @vOrderQualifiedToShip = 'Y'/* Yes */;

  return @vOrderQualifiedToShip;
end /* fn_OrderHeaders_OrderQualifiedToShip */

Go
