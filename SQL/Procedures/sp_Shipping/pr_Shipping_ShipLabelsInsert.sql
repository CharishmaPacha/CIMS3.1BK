/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/27  NB      pr_Shipping_ShipLabelsInsert changes to create temptables needed for pr_Carrier_CreateShipment (CIMSV3-2454)
  2022/07/11  PKK     pr_Shipping_VoidShipLabels, pr_Shipping_ShipLabelsInsert_New: Made changes to void the shiplabels and generate the new one (BK-867)
                      pr_Shipping_ShipLabelsInsert: Changes to insert PickTicket in ShipLabels (HA-2413)
  2020/07/29  RV      pr_Shipping_ShipLabelsInsert: Made changes to insert TaskId in ship labels table (S2GCA-1199)
  2020/06/26  RV      pr_Shipping_ShipLabelsInsert, pr_Shipping_ValidateToShip: Made changes to show messages with entity details (HA-745)
  2019/08/30  RV      pr_Shipping_ShipLabelsInsert: Initial version (CID-1008)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ShipLabelsInsert') is not null
  drop Procedure pr_Shipping_ShipLabelsInsert;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ShipLabelsInsert: insert into the ship labels if the packages are related to SPG
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ShipLabelsInsert
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

  declare @ttShipLabelsToInsert    TShipLabels,
          @ttValidations           TValidations;

begin
  select @vReturnCode = 0,
         @vOrderId    = @OrderId;

  /* Caller could pass in LPNs via #ShipLabelsToInsert, if not, then create one */
  if (object_id('tempdb..#ShipLabelsToInsert') is null) select * into #ShipLabelsToInsert from @ttShipLabelsToInsert;

  /* Max labels to batch to generate labels */
  select @vMaxLabelsPerBatch = dbo.fn_Controls_GetAsInteger('GenerateShipLabels', 'MaxLabelsToGenerate', '200', @BusinessUnit, @UserId)

  /* If Shiplabels to process are given, then ignore OrderId, LPNId */
  if exists (select * from #ShipLabelsToInsert)
    select @vMessageName = @vMessageName -- do nothing.
  else
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

  /* Update Wave, OH, ShipVia info to be saved and used for processing */
  update SLTI
  set WaveType = W.WaveType
  from #ShipLabelsToInsert SLTI join Waves W on (SLTI.WaveId = W.WaveId);

  update SLTI
  set PickTicket            = OH.PickTicket,
      TotalPackages         = OH.LPNsAssigned,
      RequestedShipVia      = OH.ShipVia,
      ShipVia               = OH.ShipVia,
      Carrier               = SV.Carrier,
      IsSmallPackageCarrier = SV.IsSmallPackageCarrier,
      BusinessUnit          = OH.BusinessUnit
  from #ShipLabelsToInsert SLTI
    join OrderHeaders OH on (OH.OrderId = SLTI.OrderId)
    join ShipVias     SV  on (SV.ShipVia  = OH.ShipVia) and (SV.BusinessUnit = OH.BusinessUnit)

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

  if (object_id('tempdb..#OrdersToValidate') is null)
    select distinct OH.*
    into #OrdersToValidate
    from #ShipLabelsToInsert SL
      join vwOrderHeaders OH on (SL.OrderId = OH.OrderId);

  /* Determine the carrier interface and process the create shipment of ship label records */
  exec pr_Carrier_CreateShipment @Module, @Operation, @BusinessUnit, @UserId

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_ShipLabelsInsert */

Go
