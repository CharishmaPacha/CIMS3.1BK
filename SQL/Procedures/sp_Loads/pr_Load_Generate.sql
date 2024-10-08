/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/17  AY      pr_Load_GenerateBoLs: Set freight terms on Master BoL (HA-2888)
  2021/04/27  VS      pr_Load_GenerateBoLs: Get the Load.ShipTo for MasterBOL of Transfer Loads (HA-2591)
  2021/04/21  SK/AY   pr_Load_Modify, pr_Load_GenerateBoLs: Option for user to choose group by for the report (HA-2676)
  pr_Load_GenerateBoLs: Update Load.BoLStatus when BoLs are generated (HA-2467)
  2021/03/31  AY      pr_Load_GenerateBoLs: Generate Master BoL when shipping to consolidator (HA GoLive)
  2021/03/23  PHK     pr_Load_GenerateBoLs: Account added to evaluate group criteria (HA-2390)
  2021/03/18  MS      pr_Load_GenerateBoLs: Bug fix to regenerate MasterBol OrderDetails (HA-2334)
  2021/03/16  PK      pr_Load_GenerateBoLs: Ported changes done by Pavan (HA-2287)
  2021/03/04  RKC/VM  pr_Load_GenerateBoLs: If user trying to Regenerate the BOL then delete and regenerate Master BOL and
  2021/02/23  AY      pr_Load_GenerateBoLs: Setup Load.ConsolidatorAddresss (HA-2054)
  pr_Load_GenerateBoLs: Use Master BoL consolidator address
  2021/02/04  RT      pr_Load_GenerateBoLs and pr_Load_Modify: Changes to use BoLLPNs to compute the BoLOrderDEtails and BoLCarrierDetails (FB-2225)
  2021/01/31  AY      pr_Load_GenerateBoLs: Generate BoLs for Master BoL as well (HA-1954)
  2021/01/20  PK      pr_Load_GenerateBoLs, pr_Loads_Action_ModifyBoLInfo, pr_Load_Recount: Ported back changes are done by Pavan (HA-1749) (Ported from Prod)
  2020/11/13  RKC     pr_Load_Generate, pr_Load_AddOrders: Moved the all validation messages to Rules
  2020/07/01  NB      pr_Load_Generate, pr_Load_ValidateAddOrder: changes to consider FromWarehouse and ShipFrom
  2020/06/15  RKC     pr_Load_Generate: Pass the missed parameter to pr_Load_CreateNew (HA-942)
  2020/06/12  RV      pr_Load_Generate: Get the entities from #table and insert messages to result messages to show in V3 (HA-841)
  2019/12/23  AY      pr_Load_GenerateBoLs: Performance fixes (CID-1234)
  2018/05/11  YJ      pr_Load_GenerateBoLs: Changes to update FreightTerms on UnderlyingBoL and on Master BoLs (S2G-806)
  pr_Load_Generate: Introduced concept of LoadGroup for generation (S2G-830)
  2016/07/26  SV      pr_Load_GenerateBoLs: Restricting to create BoL for the Orders having ShipVia other than ShipVia over the Load (TDAX-374)
  2016/07/22  NY      pr_Load_GenerateBoLs: Recount the Load (OB-431)
  2016/05/21  PSK     pr_Load_Generate: Changed to show the update order count (CIMS-921)
  2016/05/04  AY      pr_Load_Generate: Fixed issue of blank loads
  2016/05/03  SV      pr_Load_GenerateBoLs: Changes to show the UserId over the AT Log in UI (CIMS-730)
  2016/05/01  AY      pr_Load_GenerateBoLs: AT and validations added (CIMS-730).
  2016/04/17  AY      pr_Load_Generate: Use OH.ShipFrom for Load.FromWarehouse (NBD-363)
  2016/04/09  AY      pr_Load_GenerateBoLs: Do not copy Pro/Seal/Trailer numbers from Load to BoL.
  2015/12/04  DK      pr_Load_Generate: Bug fix to remove orders from temp table which are already added to load (FB-558).
  2015/09/11  TK      pr_Load_GenerateLoadForWavedOrders: Initial Revision (ACME-328)
  2015/09/02  RV      pr_Load_Generate: Consider Load criteria with respect to PickBatchGroup field instead of UDF1
  2103/10/21  TD      pr_Load_GenerateBoLs: Added contctreftype in join to get valid data.
  2013/10/17  NY      pr_Load_Generate: Added new fields to Generate Load.
  2013/01/29  YA      pr_Load_GenerateBoLs: Modified to update VICSBoLNumber on Loads when BoL is generated.
  2013/01/28  TD      pr_Load_GenerateBoLs: ShipFrom specific to BoLS.
  2013/01/25  YA/TD   pr_Load_GenerateBoLs: Hide ship from address for master bols(temp fix, need to discuss)
  2013/01/22  TD/NB   Added pr_Load_GenerateBoLs procedure
  2012/10/09  TD      pr_Load_Generate: Passing CustPo instead of PickBatchGroup while Load Creation
  2012/08/28  PKS     pr_Load_Generate: 'Case' condition was modified to get proper Success message.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_Generate') is not null
  drop Procedure pr_Load_Generate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_Generate: Procedure to generate Loads for the selected Orders.
     Input can be XML (List of Orderids) or #ttSelectedEntities.

  Process:
  - Collect all Orders into #Loads_AddOrders
  - Apply rules to update Orders and/or eliminate orders that do not qualify
  - Apply rules to determine Load Group for the remaining Orders
  - Determine the Load groups & Load criteria
  - Process each set of criteria, create a Load for it and then add orders to the Load

  '<Orders xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <OrderHeader>
      <OrderId>19</OrderId>
    </OrderHeader>
  </Orders>'
------------------------------------------------------------------------------*/
Create Procedure pr_Load_Generate
  (@Orders          TXML,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId = null,
  --------------------------------------
   @NumLoadsCreated TCount       output,
   @FirstLoadNumber TLoadNumber  output,
   @LastLoadNumber  TLoadNumber  output,
   @Message         TMessage     output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @xmlRulesData           TXML,
          /* Order Info */
          @vShipVia               TShipVia,
          @vDesiredShipDate       TDateTime,
          @vCancelDate            TDateTime,
          @vCustPO                TCustPO,
          @vPickBatchGroup        TWaveGroup,
          @ShipToId               TShipToId,
          @vShipFrom              TShipFrom,
          @vWarehouse             TWarehouse,

          @vOrders                XML,
          /* Carrier Info */
          @vCarrier               TCarrier,
          /* Shipment Info */
          @vLoadId                TLoadId,
          @vLoadNumber            TLoadNumber,
          @vDockLocation          TLocation,
          @vLoadGroup             TLoadGroup,
          @vShipDate              TDate,
          @DeliveryDate           TDateTime,
          @Weight                 TWeight,
          @Volume                 TVolume,
          @Priority               TPriority,
          @TransitDays            TCount,
          @ProNumber              TProNumber,
          @SealNumber             TsealNumber,
          @TrailerNumber          TTrailerNumber,
          @ClientLoad             TLoadNumber,
          @MasterBol              TBoLNumber,
          @ShippedDate            TDateTime,
          /* Others */
          @ttOrdersToAdd          TEntityKeysTable,
          @ttLoad_OrdersToAdd     TLoadAddOrders,
          @vOrderCount            TCount,
          @vAddOrdersCount        TCount,
          @vAddToExistingLoads    TControlValue,
          @vDebug                 TFlags,
          @vOperation             TOperation,
          @vLCRecordId            TRecordId;

          /* temp tables */
  declare @ttOrders               TEntityKeysTable;
  declare @ttSelectedEntities     TEntityValuesTable;
  declare @ttLoadCriteria Table
           (RecordId         TRecordId Identity(1,1),
            ShipVia          TShipVia,
            Warehouse        TWarehouse,
            ShipFrom         TShipFrom,
            ShipDate         TDate,
            LoadGroup        TLoadGroup,
            Primary Key      (RecordId));

begin /* pr_Load_Generate */
begin try

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('L' /* Log */, @vDebug) > 0)
    exec pr_ActivityLog_AddMessage 'Orders', null, null, 'Load', null /* message */,
                                   @@ProcId, @Orders, @BusinessUnit, @UserId;

  begin transaction;

  select @vReturnCode     = 0,
         @vMessagename    = null,
         @vOrders         = convert(xml, @Orders),
         @NumLoadsCreated = 0,
         @vLCRecordId     = 0,
         @vOperation      = 'Loads_Generate';

  /* create # table with @ttOrdersToAdd table structure */
  if (object_id('tempdb..#Load_OrdersToAdd') is null)
    select * into #Load_OrdersToAdd from @ttLoad_OrdersToAdd;

  /* Add records from input xml if there are none in entities */
  if (object_id('tempdb..#ttSelectedEntities') is null) and (@vOrders is not null)
    insert into #Load_OrdersToAdd (OrderId)
      select Record.Col.value('OrderId[1]',       'TRecordId')
      from @vOrders.nodes('Orders/OrderHeader') as Record(Col);
  else
  if (object_id('tempdb..#ttSelectedEntities') is not null)
    insert into #Load_OrdersToAdd (OrderId)
      select EntityId from #ttSelectedEntities;

  select @vOrderCount = count(*) from #Load_OrdersToAdd;

  /* Build the data for evaluation of rules to get Valid orders to generate load */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation', @vOperation));

  /* If selected order not valid to generate loads calling rules remove the orders from #Load_OrdersToAdd table */
  exec pr_RuleSets_ExecuteAllRules 'Loads_AddOrders', @xmlRulesData, @BusinessUnit;
  exec pr_RuleSets_ExecuteAllRules 'Loads_Generate', @xmlRulesData, @BusinessUnit; /* Future use - no rules yet */

  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsInvalid';

  if (@vMessageName is not null) goto ErrorHandler;

  select @vAddToExistingLoads = dbo.fn_Controls_GetAsString('Load', 'Generate_AddToExistingLoads',  'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Load Criteria: ShipFrom, ShipVia will always be a criteria to generate Loads.
     Beyond that LoadGroup which varies would be an added criteria */
  insert into @ttLoadCriteria(ShipFrom, Warehouse, ShipVia, ShipDate, LoadGroup)
    select distinct OH.ShipFrom, OH.Warehouse, OH.ShipVia, cast(OH.DesiredShipDate as Date), OH.LoadGroup
    from #Load_OrdersToAdd LO
      join OrderHeaders OH on (LO.OrderId = OH.OrderId);

  if (charindex('D' /* Display */, @vDebug) > 0) select * from @ttLoadCriteria;
  if (charindex('D' /* Display */, @vDebug) > 0) select * from #ttSelectedEntities;

  /* Validations */

  /* Iterate thru the Load Criteria and process load for each one */
  while (exists(select * from @ttLoadCriteria where RecordId > @vLCRecordId)) and
        (exists(select * from #Load_OrdersToAdd))
    begin
      select top 1
             @vLCRecordId = RecordId,
             @vShipVia    = ShipVia,
             @vWarehouse  = Warehouse,
             @vShipFrom   = ShipFrom,
             @vShipDate   = ShipDate,
             @vLoadGroup  = LoadGroup
      from @ttLoadCriteria
      where (RecordId > @vLCRecordId)
      order by RecordId;

      /* Identify the Orders that match this criteria and update the Process status as TOBeProcess */
      update LO
      set LO.ProcessStatus = 'ToBeProcessed',
          LO.PickTicket    = OH.PickTicket
      from #Load_OrdersToAdd LO
        join OrderHeaders OH on (LO.OrderId = OH.OrderId)
      where (OH.ShipVia         = @vShipVia  ) and
            (OH.Warehouse       = @vWarehouse) and
            (OH.ShipFrom        = @vShipFrom ) and
            (OH.DesiredShipDate = @vShipDate ) and
            (OH.LoadGroup       = @vLoadGroup);

      /* If there are no orders to add, then go with next criteria */
      if (@@rowcount = 0) continue;

      /* Reset the Load Values to null. */
      select @vLoadId     = null,
             @vLoadNumber = null;

      /* Find if an outstanding Load exists for the Load Criteria */
      if (@vAddToExistingLoads = 'Y')
        select top 1
               @vLoadId       = LoadId,
               @vLoadNumber   = LoadNumber,
               @vDockLocation = DockLocation
        from Loads
        where (ShipVia         = @vShipVia  ) and
              (FromWarehouse   = @vWarehouse) and
              (ShipFrom        = @vShipFrom ) and
              (DesiredShipDate = @vShipDate ) and
              (LoadGroup       = @vLoadGroup) and
              (Status in ('N' /* New */, 'I' /* In progress */))
        order by LoadId; /* get the load which was created */

      /* No Load exists for the Load Criteria or if we need to create a new Laod each time, create a new Load */
      if (@vLoadId is null)
        begin
          exec pr_Load_CreateNew @UserId           = @UserId,
                                 @BusinessUnit     = @BusinessUnit,
                                 @LoadType         = Default /* Load Type */,
                                 @ShipVia          = @vShipVia,
                                 @DesiredShipDate  = @vShipDate,
                                 @FromWarehouse    = @vWarehouse,
                                 @ShipFrom         = @vShipFrom,
                                 @PickBatchGroup   = @vLoadGroup,
                                 @LoadId           = @vLoadId     output,
                                 @LoadNumber       = @vLoadNumber output,
                                 @Message          = @Message     output;

          /* Read LoadNumber for Load Id */
          select @NumLoadsCreated += 1;

          /* Grab the first Load Number */
          if (@NumLoadsCreated = 1)
            set @FirstLoadNumber = @vLoadNumber;
        end

      if (@vLoadId is null)
        begin
          set @vMessageName = 'Load_Generation_Failed';
          goto ErrorHandler;
        end

      /* Add the orders flagged as TobeProcessed to the given Load */
      exec pr_Load_AddOrders @vLoadNumber, @ttOrdersToAdd, @BusinessUnit, @UserId, 'N' /* Load Recount */, @vOperation;

      /* here build the message to show the which orders added to which load */
      delete LO
      output 'I', 'Loads_AddOrders_OrdersAddedToLoad', deleted.PickTicket, @vLoadNumber
      into #ResultMessages (MessageType, MessageName, Value1, Value2)
      from #Load_OrdersToAdd LO
      where LO.ProcessStatus = 'Done';
    end

  /* Grab the Last Load Number here..*/
  select @LastLoadNumber = @vLoadNumber;

  /* Build the message here.. */
  select @Message = case
                      when (@NumLoadsCreated > 1) then 'Load_Generation_Multi_Successful'
                      when (@NumLoadsCreated = 1) then 'Load_Generation_Successful'
                      when (@NumLoadsCreated = 0) then 'Load_Generation_Successful2'
                    end;

  exec @Message = dbo.fn_Messages_Build @Message, @NumLoadsCreated, @FirstLoadNumber, @LastLoadNumber, @vOrderCount;

  /* Inserted the information to use in V3 application */
  if (object_id('tempdb..#ResultData') is not null)
    insert into #ResultData (FieldName, FieldValue)
            select 'NumLoadsCreated', cast(@NumLoadsCreated as varchar(100))
      union select 'FirstLoadNumber', @FirstLoadNumber
      union select 'LastLoadNumber',  @LastLoadNumber

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

  return(coalesce(@vReturnCode, 0));
end /* pr_Load_Generate */

Go
