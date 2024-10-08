/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/06  VS      pr_Load_ValidateAddOrder, pr_Load_ValidateToShip: Validate the ShipFrom based on LoadType (BK-275)
  2021/04/30  SJ      pr_Load_AutoGenerate, pr_Load_ValidateAddOrder: Calling ShipVia.SCAC instead of StandardAttributes.SCAC (HA-2693)
  2020/07/01  NB      pr_Load_Generate, pr_Load_ValidateAddOrder: changes to consider FromWarehouse and ShipFrom
  pr_Load_ValidateAddOrder: Validate to ensure Order and Load have same ShipFrom
  2012/10/30  PKS     pr_Load_ValidateAddOrder: Code was modified such that it will consider Loads whose RoutingStatus is in NotRequired for adding Orders.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_ValidateAddOrder') is not null
  drop Procedure pr_Load_ValidateAddOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_ValidateAddOrder:
     Validate whether a given Order can be added to a given Load. The basic
     validations are Ship Via, Ship To, Sold To, Carrier.

  ShipFrom Of Order and Load should be the same for LTL Loads. For Small package
  loads one load can have Orders of multiple ShipFroms because drop ship orders
  would have diff. Ship Froms and we cannot expect to create a Small Pacakge Load
  for each DropShip customer as all Ground shipments would be one Load.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_ValidateAddOrder
  (@LoadId    TLoadId,
   @OrderId   TRecordId)
as
  declare @ReturnCode            TInteger,
          @MessageName           TMessageName,
          /* Order info */
          @vShipVia              TShipVia,
          @vOrderShipFrom        TShipFrom,
          @vOrderWarehouse       TWarehouse,
          @vDesiredShipDate      TDateTime,
          @vOrderStatus          TStatus,
          /* Load Info */
          @vLoadType              TTypeCode,
          @vLoadStatus            TStatus,
          @vLoadShipVia          TShipVia,
          @vShipViaSCAC          TShipVia,
          @vLoadDesiredShipDate  TDateTime,
          @vLoadRoutingStatus    TStatus,
          @vLoadShipFrom         TShipFrom,
          @vLoadFromWarehouse    TWarehouse,
          @vBusinessUnit          TBusinessUnit,

           /* Carrier Info */
          @vCarrier              TCarrier,
          @vSmallPackageLoadTypes TControlValue,
          /* Logging */
          @vOrderXmlData         TXML,
          @vLoadXmlData          TXML,
          @vActivityLogXml       TXML;

begin /* pr_Load_ValidateAddOrder */
  select @ReturnCode  = 0,
         @Messagename = null;

  /* Get Order Info */
  select @vShipVia         = ShipVia,
         @vOrderStatus     = Status,
         @vDesiredShipDate = DesiredShipDate,
         @vOrderShipFrom   = ShipFrom,
         @vOrderWarehouse  = Warehouse
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get Load Info */
  select @vLoadType            = LoadType,
         @vLoadShipVia         = ShipVia,
         @vLoadDesiredShipDate = DesiredShipDate,
         @vLoadStatus          = Status,
         @vLoadRoutingStatus   = RoutingStatus,
         @vLoadShipFrom        = ShipFrom,
         @vLoadFromWarehouse   = FromWarehouse,
         @vBusinessUnit        = BusinessUnit
  from Loads
  where (LoadId = @LoadId);

  select @vSmallPackageLoadTypes = dbo.fn_Controls_GetAsString('Load', 'SmallPackageLoadTypes', 'FDEG,FDEN,UPSE,UPSN,USPS' /* Default: SPL Loads */,
                                                                @vBusinessUnit, null /* UserId */);

  /* If Order ShipVia is a 'Generic' carrier like - Use Cheapest, See PO etc. then
     those orders can be added to any load as they are not a specific carrier */
  select @vCarrier     = Carrier,
         @vShipViaSCAC = SCAC
  from ShipVias
  where (ShipVia = @vShipVia);

  /* Validate status */
  if (@vLoadStatus in ('X',  /* Cancelled */
                       -- 'L',  /* ReadyToShip */    -- Why Orders cannot be added to Load which are ready to ship??
                       'S')) /* Shipped  */
    set @MessageName = 'Load_AddOrders_InvalidStatus';
  else
  if (@vLoadRoutingStatus not in ( 'P' /* Pending */, 'N' /* Not Required */)) /* If Routing already done, do not allow adding more orders */
    select @MessageName = 'Load_AddOrders_InvalidRoutingStatus';
  else
  if (@vOrderStatus = 'S'/* Shipped */)
    select @MessageName = 'Load_AddOrders_OrderAlreadyShipped';
  else
  if (@vOrderStatus = 'X'/* Canceled */)
    select @MessageName = 'Load_AddOrders_OrderAlreadyCanceled';
  else
  if ((@vCarrier not in ('Generic', 'LTL')) and (@vLoadType <> coalesce(@vShipViaSCAC, '')) and
     (coalesce(@vShipVia, '') <> coalesce(@vLoadShipVia, ''))) /* Validate ShipVias on Load and Order are same or not. */
    select @MessageName = 'Load_AddOrders_ShipViaDifferent';
  else
  if (coalesce(@vOrderShipFrom, '') <> coalesce(@vLoadShipFrom, '')) and
     (@vLoadStatus not in ('N' /* New */)) and
     (dbo.fn_IsInList(@vLoadType, @vSmallPackageLoadTypes) = 0)
    select @MessageName = 'Load_AddOrders_ShipFromDifferent';
  else
  if (coalesce(@vOrderWarehouse, '') <> coalesce(@vLoadFromWarehouse, ''))
    select @MessageName = 'Load_AddOrders_WarehouseDifferent';

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_ValidateAddOrder */

Go
