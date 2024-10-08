/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/11  VS      pr_Shipment_CreateShipments: Update the Load info on the Order if Order has single shipment (HA-2122)
  2021/02/19  TK      pr_Shipment_CreateShipments: Should be able to create shipments for multiple Loads as well (HA-1962)
  2021/01/31  TK      pr_Shipment_CreateShipments: Initial Revision (HA-1947)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_CreateShipments') is not null
  drop Procedure pr_Shipment_CreateShipments;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_CreateShipments: Evaluates #LPNsToLoad and checks if there are
    any active shipments that matches the criteria and if not active shipments found
    then it will create new shipments and adds orders to the new shipments.

  #LPNsToLoad: TLPNsToLoad
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_CreateShipments
  (@LoadId           TRecordId,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vLoadId                  TRecordId,
          @vLoadNumber              TLoadNumber,
          @vLoadType                TTypeCode;

  declare @ttShipmentsCreated       TEntityKeysTable,
          @ttOrdersToUpdate         TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Create required hash tables */
  select * into #OrdersToUpdate from @ttOrdersToUpdate;

  /* Get the Load Info */
  select @vLoadId     = LoadId,
         @vLoadNumber = LoadNumber,
         @vLoadType   = LoadType
  from Loads
  where (LoadId = @LoadId);

  /* Update ShipmentId if there is any active shipment already exists & that is macthing the criteria */
  update LTL
  set ShipmentId = S.ShipmentId
  from #LPNsToLoad LTL
    join Shipments S on (S.ShipTo   = LTL.ShipToId) and
                        (S.SoldTo   = LTL.SoldToId) and
                        (S.ShipVia  = LTL.ShipVia ) and
                        (S.ShipFrom = LTL.ShipFrom) and
                        (S.LoadId   = coalesce(@vLoadId, LTL.LoadId)) and  -- If LoadId is not passed as input then use from #LPNsToLoad table
                        (S.Status  <> 'S'/* Shipped */)
  where (LTL.ShipmentId = 0);

  /* Create new shipments for each group for the LPNs that are still not associated with any shipments */
  insert into Shipments(ShipFrom, ShipVia, SoldTo, ShipTo, FreightTerms, DesiredShipDate,
                        ShipmentType, LoadId, LoadNumber, BusinessUnit, CreatedBy)
    output inserted.ShipmentId into @ttShipmentsCreated (EntityId)
    select LTL.ShipFrom, LTL.ShipVia, LTL.SoldToId, LTL.ShipToId, min(FreightTerms), min(DesiredShipDate),
           min(coalesce(OrderType, @vLoadType, 'C')), coalesce(@vLoadId, LTL.LoadId), coalesce(@vLoadNumber, LTL.LoadNumber),
           @BusinessUnit, @UserId
    from #LPNsToLoad LTL
    where (LTL.ShipmentId = 0)
    group by LTL.LoadId, LTL.LoadNumber, LTL.ShipFrom, LTL.ShipVia, LTL.SoldToId, LTL.ShipToId;

  /* Assign LPNs to the shipments that are newly created above */
  update LTL
  set ShipmentId = S.ShipmentId
  from #LPNsToLoad LTL
    join Shipments S on (S.ShipTo   = LTL.ShipToId) and
                        (S.SoldTo   = LTL.SoldToId) and
                        (S.ShipVia  = LTL.ShipVia ) and
                        (S.ShipFrom = LTL.ShipFrom) and
                        (S.LoadId   = coalesce(@vLoadId, LTL.LoadId)) and
                        (S.Status  <> 'S'/* Shipped */)
    join @ttShipmentsCreated ttSC on (S.ShipmentId = ttSC.EntityId)
  where (LTL.ShipmentId = 0);

  /* Create shipment for order if there isn't one */
  insert into OrderShipments(ShipmentId, OrderId, BusinessUnit, CreatedBy)
    select distinct LTL.ShipmentId, LTL.OrderId, @BusinessUnit, @UserId
    from #LPNsToLoad LTL
      left outer join OrderShipments OS on (LTL.ShipmentId = OS.ShipmentId) and (LTL.OrderId = OS.OrderId)
    where (LTL.ShipmentId > 0) and
          (LTL.OrderId is not null) and   -- Contractor Transfer orders in HA will not be shipped against any order
          (OS.OrderId is null);

  /* If order has single shipment then update Load info on the Order */
  insert into #OrdersToUpdate (EntityId) select distinct OrderId from #LPNsToLoad;
  exec pr_OrderHeaders_UpdateLoadInfo @Operation, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipment_CreateShipments */

Go
