/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_GetDisqualifiedOrdersToShip') is not null
  drop Procedure pr_Load_GetDisqualifiedOrdersToShip;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_GetDisqualifiedOrdersToShip: This procedure returns the orders
    on the Load that are not qualified for shipping so that they can be removed
    from the Load so that Load can be successfully shipped.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_GetDisqualifiedOrdersToShip
  (@LoadId       TLoadId,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,

          /* Loads Related */
          @vLoadNumber             TLoadNUmber,
          @vLoadStatus             TStatus,
          @vLoadId                 TLoadId,
          @vDebug                  TFlags = 'T',
          @vTime                   TDatetime,
          @vValidOrderStatusToShip TControlValue;

  /* Declare temptable  */
  declare @ttOrdersToRemove  TRecountKeysTable;

begin /* pr_Load_GetDisqualifiedOrdersToShip */

  select @vReturnCode     = 0,
         @vMessageName    = null

  /* Get Load Info here..*/
  select @vLoadId      = LoadId,
         @vLoadNumber  = LoadNumber,
         @vLoadStatus  = Status
  from Loads
  where (LoadId = @LoadId);

  select @vValidOrderStatusToShip   = dbo.fn_Controls_GetAsString('OrderClose', 'ValidOrderStatusToShip', 'PKWCG',  @BusinessUnit, @UserId);

  if (charindex('T', @vDebug) > 0) exec pr_PrintTime @vTime out, null, 'Remove Orders with open tasks';

  /* HPI Specific: Remove the orders if the orders has any open tasks */
  insert into @ttOrdersToRemove (EntityId)
    select distinct OS.OrderId
    from vwOrderShipments OS
      join TaskDetails TD on (TD.OrderId = OS.OrderId)
    where (OS.LoadId = @LoadId) and (TD.Status not in ('C' /* Completed */, 'X' /* Cancelled */));

  /* HPI Specific: Remove the orders which do not have tracking numbers on lpns */
  insert into @ttOrdersToRemove (EntityId)
    select distinct OS.OrderId
    from vwOrderShipments OS
      join LPNs L on (L.OrderId = OS.OrderId)
    where (OS.LoadId = @LoadId) and
          ((coalesce(L.TrackingNo, '') = '') or
           (L.TrackingNo = '-'));

  /* HPI Specific: Remove the orders which shipped mismatched(greater than or less than required) units */
  insert into @ttOrdersToRemove (EntityId)
    select distinct OS.OrderId
    from vwOrderShipments OS
      join OrderDetails  OD  on (OD.OrderId       = OS.OrderId)
      join LPNDetails    LD  on (LD.OrderId       = OD.OrderId) and
                                (LD.OrderDetailId = OD.OrderDetailId) and
                                (LD.OnhandStatus  = 'R')
      --join LPNs          L   on (L.OrderId        = OS.OrderId)
    where (OS.LoadId = @LoadId)
    group by OD.OrderDetailId, OS.OrderId, OD.UnitsAssigned
    having (sum(LD.Quantity) <> (OD.UnitsAssigned));

  /* Get the Invalid status orders */
  insert into @ttOrdersToRemove (EntityId)
    select distinct OS.OrderId
    from vwOrderShipments OS
      join OrderHeaders OH on (OH.OrderId = OS.OrderId)
    where (OS.LoadId = @LoadId) and
          (charindex(OH.Status, @vValidOrderStatusToShip) = 0);

  /* Return the Disqualified orders from the Load */
  select distinct EntityId from @ttOrdersToRemove;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_GetDisqualifiedOrdersToShip */

Go
