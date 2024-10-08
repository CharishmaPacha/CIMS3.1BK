/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/19  RKC     pr_Exports_ExplodeConsolidatedOrder : Pass the xmlRulesData to rules to Fetch the Freight charges for Orders on loads
                      pr_Exports_OrderData: Calculate the Freight charges for each order (CID-1378)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_ExplodeConsolidatedOrder') is not null
  drop Procedure pr_Exports_ExplodeConsolidatedOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_ExplodeConsolidatedOrder: When a consolidated order is shipped,
   need to explode the consolidate order back to original orders. This procedure
   gets all the original orders and exports them each.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_ExplodeConsolidatedOrder
  (@TransType          TTypeCode,
   @OrderId            TRecordId,
   @LoadId             TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReasonCode         TReasonCode,
   @xmlRulesData       TXML)
as
  declare  @vOrgOrderId        TRecordId,
           @vConsolidationKey  TUDF,
           @vRecordId          TRecordId,
           @vReturnCode        TInteger,
           @vMessageName       TMessageName,
           @vTotalLPNsWeight   TWeight,
           @vTotalLPNsVolume   TVolume,
           @vTotalUnitsShipped TQuantity,
           @vFreightCharges    TMoney,
           @vShipVia           TShipVia,
           @vFreightTerms      TDescription;

  declare @ttOriginalOrders    TEntityKeysTable;
begin
  SET NOCOUNT ON;

  set @vRecordId = 0;

  /* Get the total LPNs weight and volume for the order */
  select @vTotalLPNsWeight = sum(coalesce(EstimatedWeight, ActualWeight)),
         @vTotalLPNsVolume = sum(coalesce(EstimatedVolume, ActualVolume))
  from LPNs
  where (OrderId = @OrderId); /* Get the Weight and Volume for the Master PickTicket */

  /* Get the Total shipped counts against MasterPT */
  select @vTotalUnitsShipped = UnitsShipped,
         @vShipVia           = ShipVia,
         @vFreightTerms      = FreightTerms
  from OrderHeaders
  where (OrderId = @OrderId);

  /* Get the Freight charges  based on rules */
  exec pr_RuleSets_Evaluate 'Export_FreightCharges', @xmlRulesData, @vFreightCharges output;

  /* Get the key value from the master, this is the link between master PT and
     original orders */
  select @vConsolidationKey = UDF30
  from OrderHeaders
  where OrderId = @OrderId;

  /* Load the Original OrderId */
  insert into @ttOriginalOrders (EntityId, EntityKey)
    select OH.OrderId, OH.PickTicket
    from OrderHeaders OH
    where (UDF29 = @vConsolidationKey);

  /* Loop through the all the Orders */
  while exists (select * from @ttOriginalOrders where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId   = RecordId,
                   @vOrgOrderId = EntityId
      from @ttOriginalOrders
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Update the Original Orders with the Shipped details */
      update OrderHeaders
      set ShipVia      = @vShipVia,
          FreightTerms = @vFreightTerms
      where OrderId = @vOrgOrderId;

      /* To Generate the Exports against the original Order */
      exec pr_Exports_ConsolidatedOrderData @TransType, @vOrgOrderId, null, @LoadId, @BusinessUnit, @UserId, @ReasonCode, @vTotalLPNsWeight, @vTotalLPNsVolume, @vTotalUnitsShipped, @vFreightCharges;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_ExplodeConsolidatedOrder */

Go
