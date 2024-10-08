/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  TK      pr_OrderHeaders_UpdateLoadInfo: Bug fix in counting Shipments (HA-2608)
  2021/03/15  TK      pr_OrderHeaders_UpdateLoadInfo: Clear load info if there are no shipments (HA-2280)
  2021/03/11  VS      pr_OrderHeaders_UpdateLoadInfo: Initial Version (HA-2122)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_UpdateLoadInfo') is not null
  drop Procedure pr_OrderHeaders_UpdateLoadInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_UpdateLoadInfo: if the Order has single shipment then update the Load info on OrderHeader
    else update Loadnumber as Multiple.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_UpdateLoadInfo
  (@Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName;

begin
  SET NOCOUNT ON;

  /* If order has single shipment then update Load info on the Order */
  ;with OHLoadInfo As
   (
    select OS.OrderId, count(distinct OS.ShipmentId) NumShipments, min(OS.LoadId) LoadId, min(OS.LoadNumber) LoadNumber
    from vwOrderShipments OS
      join #OrdersToUpdate OTU on OS.OrderId = OTU.EntityId
    group by OS.OrderId
   )
   update OH
   set LoadId     = case when OHI.OrderId is null then 0
                         when NumShipments > 1    then 0
                         when NumShipments = 1    then OHI.LoadId
                    end,
       LoadNumber = case when OHI.OrderId is null then null
                         when NumShipments > 1    then 'Multiple'
                         when NumShipments = 1    then OHI.LoadNumber
                    end
   from OrderHeaders OH
     join #OrdersToUpdate OTU on OTU.EntityId = OH.OrderId
     left outer join OHLoadInfo OHI on OHI.OrderId  = OH.OrderId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_UpdateLoadInfo */

Go
