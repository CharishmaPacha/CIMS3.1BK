/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/11  PKK     pr_Shipping_VoidShipLabels, pr_Shipping_ShipLabelsInsert_New: Made changes to void the shiplabels and generate the new one (BK-867)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ShipLabelsInsert_New') is not null
  drop Procedure pr_Shipping_ShipLabelsInsert_New;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ShipLabelsInsert_New: Ship labels may need to be requested for
    an order or a particular LPN or selectively be passed in via #ShipLabelsToInsert.
    This procedure evaluates them by removing from the list if the label is
    already available. If not, validates to make sure the label can be generated
    and if so, inserts the labels as batches and even creates an API request as
    needed.

  #ShipLabelsToInsert TShipLabels
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ShipLabelsInsert_New
  (@Module           TName,
   @Operation        TOperation,
   @OrderId          TRecordId     = null,
   @LPNId            TRecordId     = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessageName,

          @vLPN                     TLPN,
          @vLPNStatus               TStatus,
          @vLPNOrderId              TRecordId,
          @vInvalidLPNStatusToVoid  TStatus,
          @vOrderId                 TRecordId,
          @vPickTicket              TPickTicket,
          @vOrderStatus             TStatus,
          @vShipVia                 TShipVia,
          @vIsSmallPackageCarrier   TFlag,
          @vCarrier                 TCarrier,
          @vNextProcessBatch        TBatch,
          @vRecordCount             TCount,
          @vNumBatches              TCount,
          @vMaxLabelsPerBatch       TInteger,
          @xmlRulesData             TXML,
          @vNumLabelsInserted       TCount;

  declare @ttShipLabelsToInsert    TShipLabels;

begin
  select @vReturnCode = 0,
         @vOrderId    = @OrderId;

  /* Caller could pass in LPNs via #ShipLabelsToInsert, if not, then create one */
  if (object_id('tempdb..#ShipLabelsToInsert') is null) select * into #ShipLabelsToInsert from @ttShipLabelsToInsert;

  /* Max labels to batch to generate labels */
  select @vMaxLabelsPerBatch = dbo.fn_Controls_GetAsInteger('GenerateShipLabels', 'MaxLabelsToGenerate', '200', @BusinessUnit, @UserId)

  if exists (select * from #ShipLabelsToInsert)
    goto GenerateNewShiplabel;

  /* If LPN is given then get the info to validate */
  if (coalesce(@LPNId, 0) <> 0)
    begin
      select @vLPN = LPN from LPNs where (LPNId = @LPNId) and LPNType in ('S');

      insert into #ShipLabelsToInsert(EntityId, EntityType, EntityKey, CartonType, OrderId, TaskId, WaveId, WaveNo, LabelType)
        select LPNId, 'L', LPN, CartonType, OrderId, TaskId, PickBatchId, PickBatchNo, ''
        from LPNs
        where (LPNId = @LPNId) and LPNType in ('S');
    end
  else
  /* If OrderId is given the get all the LPNs related to the order */
  if (coalesce(@OrderId, 0) <> 0)
    begin
      select @vPickTicket = PickTicket from OrderHeaders where (OrderId = @OrderId);

      insert into #ShipLabelsToInsert(EntityId, EntityType, EntityKey, CartonType, OrderId, TaskId, WaveId, WaveNo, LabelType)
        select LPNId, 'L', LPN, CartonType, OrderId, TaskId, PickBatchId, PickBatchNo, ''
        from LPNs
        where (OrderId = @OrderId) and (LPNType in ('S'));
    end

  /* Build xml to evaluate the rules for insertion cartons into ShipLabels table */
--   select @xmlRulesData = dbo.fn_XMLNode('RootNode',
--                            dbo.fn_XMLNode('Operation',              @Operation) +
--                            dbo.fn_XMLNode('Module',                 @Module) +
--                            dbo.fn_XMLNode('WaveId',                 '') +
--                            dbo.fn_XMLNode('WaveNo',                 '') +
--                            dbo.fn_XMLNode('WaveType',               '') +
--                            dbo.fn_XMLNode('LPNId',                  '') +
--                            dbo.fn_XMLNode('LPN',                    '') +
--                            dbo.fn_XMLNode('OrderId',                '') +
--                            dbo.fn_XMLNode('Carrier',                '') +
--                            dbo.fn_XMLNode('IsSmallPackageCarrier',  '') +
--                            dbo.fn_XMLNode('Validation',             '') +
--                            dbo.fn_XMLNode('BusinessUnit',           @BusinessUnit) +
--                            dbo.fn_XMLNode('UserId',                 @UserId));

  /*-------------------- Fill relevant data for rules --------------------*/

  GenerateNewShiplabel:

  update SLTI
  set WaveType = W.WaveType
  from #ShipLabelsToInsert SLTI join Waves W on (SLTI.WaveId = W.WaveId);

  update SLTI
  set PickTicket            = OH.PickTicket,
      RequestedShipVia      = OH.ShipVia,
      ShipVia               = OH.ShipVia,
      Carrier               = SV.Carrier,
      IsSmallPackageCarrier = SV.IsSmallPackageCarrier,
      BusinessUnit          = OH.BusinessUnit
  from #ShipLabelsToInsert SLTI
    join OrderHeaders OH on (OH.OrderId = SLTI.OrderId)
    join ShipVias     SV  on (SV.ShipVia  = OH.ShipVia) and (SV.BusinessUnit = OH.BusinessUnit)

  /* Determine the carrier interface and process the create shipment of ship label records */
  exec pr_Carrier_CreateShipment @Module, @Operation, @BusinessUnit, @UserId

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_ShipLabelsInsert_New */

Go
