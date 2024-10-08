/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/05  SJ      pr_Replenish_GenerateOrders: Made changes to get Pick ticket info in the Replenish Order generation (BK-325)
  2021/03/12  PKK     pr_Replenish_GenerateOndemandOrders, pr_Replenish_GenerateOrdersForDynamicLocations: Replaced => Status with Wavestatus (CIMSV3-1416)
                      pr_Replenish_GenerateOrders: Made changes to get PickTicket info in the Replenish Order generation (BK-325)
  2020/06/16  TK      pr_Replenish_GenerateOrders: Changes to return UniqueId & InventoryClasses
  2020/06/15  RKC     pr_Replenish_GenerateOrders:changes to preprocess the replenish order after generated (HA-937)
  2020/06/08  TK      pr_Replenish_GenerateOndemandOrders, pr_Replenish_GenerateOrders, pr_Replenish_OnDemandLocationsToReplenish,
  2020/05/22  KBB     pr_Replenish_GenerateOrders : Changed the  Entity type PickTicket (HA-384)
  2020/05/14  VS      pr_Replenish_GenerateOrders: Made changes for V3 GenerateReplenishOrders action (HA-372)
  2019/09/06  AY      pr_Replenish_GenerateOrders: Performance optimization (CID-1022)
  2019/07/16  SPP     pr_Replenish_GenerateOrders: Added activity log (CID-136) (Ported from Prod)
  2019/07/08  TK      pr_Replenish_GenerateOrders: Bug fix in adding orders to new/existing waves (CID-721)
  2019/05/08  TK      pr_Replenish_GenerateOrders: If replenishing to dynamic picklane we won't have Ownership on dynamic Location/LPN so consider Replenish wave/order Ownership (S2GCA-GoLive)
  2018/06/17  TK      pr_Replenish_GenerateOrdersForDynamicLocations: Initial Revision (S2GCA-63)
  2018/04/11  TK      pr_Replenish_GenerateOrders: Fixed unique key constraint error while generating order for multi-SKU picklanes (S2G-Support)
  2018/04/04  TK      pr_Replenish_GenerateOrders: Fixed issue with generating min-max replenish orders (S2G-Support)
  2018/03/26  TK      pr_Replenish_GenerateOrders & pr_Replenish_GenerateOndemandOrders:
  2018/03/15  TD      pr_Replenish_GenerateOrders:Changes to insert DestLocationId into OrderDetails (S2G-432)
  2016/11/24  PSK     pr_Replenish_GenerateOrders: Changes to show the Replenish order and Wave.in confirmation message (HPI-927)
                      pr_Replenish_GenerateOrders: Setup OrderCategory1 to distinguish between min-max and ondemand waves (HPI-GoLive)
  2016/10/20  TK      pr_Replenish_GenerateOrders: Bug fix -  consider Replenish Qty which is sent form UI (HPI-GoLive)
  2016/10/04  VM      pr_Replenish_GenerateOrders: Changed to update the Account Name(HPI-666)
  2016/03/29  TK      pr_Replenish_GenerateOrders: Generate new Order for the first time and add details to the generated Order (NBD-314)
                      pr_Replenish_GenerateOrders: Bug fix - Pass Ownership to Imports procedure instead of passing BusinessUnit (NBD-175),
  2015/12/08  RV      pr_Replenish_GenerateOrders: Added ReplenishBatchNo as output parameter
  2015/12/06  TK      pr_Replenish_GenerateOrders: Consider Operation while Replenish Qty (ACME-419)
  2015/12/02  RV      pr_Replenish_GenerateOrders: Create Replenish wave if replenish orders are exist and
  2015/11/03  RV      pr_Replenish_GenerateOrders: Added new optional parameter to pass the Pick Batch No to create batch with required format
  2015/03/11  TK      pr_Replenish_GenerateOrders: Enhnaced to update Dest Location and made Location, SKU to be unique.
                      pr_Replenish_GenerateOrders: Enhanced to generate auto replenish batch.
  2014/05/09  PK      pr_Replenish_LocationsToReplenish, pr_Replenish_GenerateOrders:
  2014/05/08  PK      pr_Replenish_LocationsToReplenish, pr_Replenish_GenerateOrders:
  2014/02/10  TD      pr_Replenish_GenerateOrders: Added Warehouse while creating Replenish Orders.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_GenerateOrders') is not null
  drop Procedure pr_Replenish_GenerateOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_GenerateOrders: This procedure is used to generate Replenish
   Orders for the given list of Locations & SKUs. This could be as a result of
   Ondemand Replenishment and/or Min/Max replenishment. If it is for OnDemand
   Replenishment, then there would not be a PickBatchNo passed in and the intent
   is to generate an Order and add to a PickBatch with the number being the original
   PickBatchNo + R. This would allow users to see the corresponding OnDemand wave for
   a given wave.
   For Min/Max input PickBatchNo should be null.
   For Min/Max replenishment, there may be several Replenish Orders and batches generated.

 The given Locations are grouped together to create separate ReplenishOrders for each group.
 We would never mix Locations from muliple Warehouses or owners into same replenish order
 as each order can be only for one Warehouse and owner for allocation purposes.

  LocationsInfo:
  <GENERATEREPLENISHORDER>
    <LOCATIONSINFO>
      <Location>        </Location>
      <SKU>             </SKU>
      <ReplenishUoM>    </ReplenishUoM>
      <QtyToReplenish>  </QtyToReplenish>
    </LOCATIONSINFO>
    <LOCATIONSINFO>
      <Location>        </Location>
      <SKU>             </SKU>
      <ReplenishUoM>    </ReplenishUoM>
      <QtyToReplenish>  </QtyToReplenish>
    </LOCATIONSINFO>
    <OPTIONS>
      <Priority>        </Priority>
      <Operation>       </Operation>
    </OPTIONS>
  </GENERATEREPLENISHORDER>

  Operation: This gives indication as the source of the request i.e. whether it is UI or something else.
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_GenerateOrders
  (@LocationsInfo      TXML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ConfirmMessage     TVarchar output,
   @WaveNo             TWaveNo  = null,
   @ReplenishWaveNo    TWaveNo  output)

as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,
          @vDebug                   TFlags,

          @vRecordId                TRecordId,
          @vAuditRecordId           TRecordId,

          @vLocation                TLocation,
          @vLocationId              TRecordId,
          @ReplenishWaveId          TRecordId,
          @vReplenishGroup          TCategory,
          @vInventoryClass1         TInventoryClass,
          @vInventoryClass2         TInventoryClass,
          @vInventoryClass3         TInventoryClass,
          @vWarehouse               TWarehouse,
          @xmlLocationInfo          xml,

          @vOrderId                 TRecordId,
          @vFirstOrderId            TRecordId,
          @vPickTicket              TPickTicket,
          @vOrderType               TTypeCode,
          @vOrderDate               TDateTime,
          @vOrderCategory           TCategory,
          @vNumLines                TInteger,
          @vPriority                TPriority,
          @vOwnership               TOwnership,

          @vOperation               TOperation,
          @vAddToExistingOrder      TFlag,
          @vActivityLogId           TRecordId;

  declare @ttOrders                 TEntityKeysTable,
          @ttOrdersToWave           TEntityKeysTable,
          @ttAuditLocations         TEntityKeysTable,
          @ttLocationsToReplenish   TLocationsToReplenish,
          @ttResultMessages         TResultMessagesTable;

  declare @ttOrderDetails          table (OrderId        TRecordId,
                                          OrderDetailId  TRecordId,
                                          LocationId     TRecordId,
                                          Location       TLocation);
  declare @ttLocationsUpdated      table (DestLocationId TRecordId,
                                          DestLocation   TLocation,
                                          SKUId          TRecordId);
begin
begin try
  begin transaction;

  /* Initialize */
  select @vReturnCode     = 0,
         @vNumLines       = 0,
         @vReplenishGroup = '',
         @vFirstOrderId   = null,  --This needs to be null to begin with to ensure we create a new order first time
         @xmlLocationInfo = convert(xml, @LocationsInfo);

  if (@xmlLocationInfo is null)
    goto ErrorHandler;

  /* Create temporary table if do not exist from callers
     Since this is called from Allocation which does not use ResultMessages */
  if (object_id('tempdb..#ResultMessages') is null) select * into #ResultMessages from @ttResultMessages;

  select @vPriority  = Record.Col.value('Priority[1]',  'TPriority'),
         @vOperation = coalesce(nullif(Record.Col.value('Operation[1]', 'TOperation'), ''), 'OnDemandReplenish')
  from @xmlLocationInfo.nodes('GENERATEREPLENISHORDER/OPTIONS') as Record(Col);

  /* Get the Operation & Priority from V3 as UI passes in a diff format in V3 */
  select @vPriority  = Record.Col.value('(Data/Priority)[1]',        'TPriority'),
         @vOperation = coalesce(nullif(Record.Col.value('Action[1]', 'TAction'), ''), 'OnDemandReplenish')
  from @xmlLocationInfo.nodes('GENERATEREPLENISHORDER') as Record(Col);

  exec pr_Debug_GetOptions @@ProcId, @vOperation, @BusinessUnit, @vDebug output;

  exec pr_ActivityLog_AddMessage 'GenReplenishOrder', null, null, 'Wave', null /* Message */, @@ProcId,
                                 @LocationsInfo /* xmlData */, @BusinessUnit, @UserId,
                                 @ActivityLogId = @vActivityLogId output;

  /* Get Controls */
  select @vAddToExistingOrder = dbo.fn_Controls_GetAsBoolean(@vOperation, 'Replenish_AddLocationsToPriorOrders',
                                                             'N'/* No */, @BusinessUnit, @UserId)

  /* Fetch the Locations and then generate replenish Orders for those Locations */
  insert into @ttLocationsToReplenish(LocationId, Location, StorageType, SKUId, SKU, ReplenishUoM, QtyToReplenish,
                                      InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse)
    select distinct Record.Col.value('LocationId[1]',        'TRecordId'),
                    Record.Col.value('Location[1]',          'TLocation'),
                    Record.Col.value('StorageType[1]',       'TTypeCode'),
                    Record.Col.value('SKUId[1]',             'TRecordId'),
                    Record.Col.value('SKU[1]',               'TSKU'),
                    Record.Col.value('ReplenishUoM[1]',      'TUoM'),
                    Record.Col.value('QtyToReplenish[1]',    'TQuantity'),
                    coalesce(Record.Col.value('InventoryClass1[1]',   'TInventoryClass'), ''),
                    coalesce(Record.Col.value('InventoryClass2[1]',   'TInventoryClass'), ''),
                    coalesce(Record.Col.value('InventoryClass3[1]',   'TInventoryClass'), ''),
                    Record.Col.value('Ownership[1]',         'TOwnership'),
                    Record.Col.value('Warehouse[1]',         'TWarehouse')
    from @xmlLocationInfo.nodes('GENERATEREPLENISHORDER/LOCATIONSINFO') as Record(Col)
    OPTION ( OPTIMIZE FOR ( @xmlLocationInfo = null ) );

  /* When calling from UI i.e. Operation = MinMaxReplenish, the QtyToReplenish is not passed in correctly.
     instead of changing UI - where user does not any how have option to change the qty, we are computing
     the qty to be replenished here */
  if (@vOperation = 'MinMaxReplenish')
    begin
      update ttLR
      set ReplenishUoM     = 'EA' /* Eaches */,
          QtyToReplenish   = vwLR.MaxUnitsToReplenish,
          UnitsToReplenish = vwLR.MaxUnitsToReplenish
      from @ttLocationsToReplenish ttLR
        join vwLocationsToReplenish vwLR on (ttLR.UniqueId = vwLR.UniqueId);
    end

  /* Update required info to process all the locations that need to be replenished */
  update ttLR
  set ttLR.LocationId       = LOC.LocationId,
      ttLR.SKUId            = S.SKUId,
      ttLR.UnitsPerCase     = S.UnitsPerInnerpack,
      ttLR.UnitsPerLPN      = S.UnitsPerLPN,
      ttLR.UnitsToReplenish = case when (ttLR.ReplenishUoM = 'EA')  then ttLR.QtyToReplenish
                                   when (ttLR.ReplenishUoM = 'CS')  then ttLR.QtyToReplenish * S.UnitsPerInnerPack
                                   when (ttLR.ReplenishUoM = 'LPN') then ttLR.QtyToReplenish * S.UnitsPerLPN
                                   else 0
                              end,
      /* All the locations with same replenish group will go into the same Order
         For Min-Max we will generate separate Orders for Locations with diff. Dest Zone
         For On-Demand we will generate separate Orders for Locations with diff. Date */
      ttLR.ReplenishGroup   = @vOperation + '-' + Loc.Warehouse + '-' + coalesce(Loc.Ownership, '') +
                              case when (@vOperation = 'MinMaxReplenish') then LOC.PickingZone
                                   when (@vOperation = 'AutoReplenish')   then LOC.PickingZone
                                   else LOC.StorageType + cast(convert(date, getdate()) as varchar)
                              end,
      ttLR.Priority         = @vPriority
  from @ttLocationsToReplenish ttLR
    join Locations LOC on (ttLR.LocationId = LOC.LocationId)
    join SKUs      S   on (ttLR.SKUId      = S.SKUId       )

  if (charindex('D', @vDebug) > 0) select * from @ttLocationsToReplenish;

  /* Loop thru each Location and generate Order and Wave it */
  while exists(select * from @ttLocationsToReplenish where ReplenishGroup > @vReplenishGroup)
    begin
      select top 1 @vReplenishGroup  = ReplenishGroup,
                   @vOrderType       = 'R' + StorageType,
                   @vPriority        = Priority,
                   @vInventoryClass1 = InventoryClass1,
                   @vInventoryClass2 = InventoryClass2,
                   @vInventoryClass3 = InventoryClass3,
                   @vWarehouse       = Warehouse,
                   @vOwnership       = Ownership,
                   @vOrderId         = null /* Initialize */
      from @ttLocationsToReplenish
      where (ReplenishGroup > @vReplenishGroup)
      order by ReplenishGroup;

      /* Find if there is any existing orders for that particular replenish group */
      select @vOrderId        = OrderId,
             @vPickTicket     = PickTicket,
             @ReplenishWaveId = PickBatchId,
             @ReplenishWaveNo = PickBatchNo,
             @vNumLines       = NumLines
      from OrderHeaders
      where (OrderType      = @vOrderType     ) and
            (OrderCategory5 = @vReplenishGroup) and
            (Ownership      = @vOwnership     ) and
            (Archived       = 'N'             ) and -- Order type index uses Archived filter, so this is needed
            ((@vAddToExistingOrder = 'Y') or (OrderId >= @vFirstOrderId)) and
            (Status not in ('D', 'X'/* Completed, Canceled */));

      if (charindex('D', @vDebug) > 0) select 'Add To Existing Order', @vOrderId OrderId, @ReplenishWaveNo ReplenishWave,
                                                                       @vReplenishGroup ReplenishGroup;

      /* If we are not adding to an existing order, then create a new Replenish Order */
      if (@vOrderId is null)
        begin
          exec pr_Replenish_CreateOrder @vOrderType, @vPriority, @vReplenishGroup,
                                        @vWarehouse, @vOwnership, @vOperation,
                                        @BusinessUnit, @UserId, @vOrderId output, @vPickTicket output;

          /* Capture all the Orders to Wave them */
          if (@vOrderId is not null)
            insert into @ttOrdersToWave (EntityId, EntityKey) select @vOrderId, @vPickTicket;
          else
            begin
              set @vMessageName = 'UnableToCreateReplenishOrder'

              goto ErrorHandler;
            end
       end

      /* Save the Orders into a temp table for processing Recount later */
      if not exists(select * from @ttOrders where EntityId = @vOrderId)
        insert into @ttOrders (EntityId, EntityKey) select @vOrderId, @vPickTicket;

      /* If there is already a detail for the location to be replenished then increment
         quantities on it */
      update OD
      set OD.UnitsOrdered              += ttLR.UnitsToReplenish,
          OD.UnitsAuthorizedToShip     += ttLR.UnitsToReplenish,
          OD.OrigUnitsAuthorizedToShip += ttLR.UnitsToReplenish,
          OD.ModifiedDate               = current_timestamp
      output Inserted.DestLocationId, Inserted.DestLocation, Inserted.SKUId into @ttLocationsUpdated(DestLocationId, DestLocation, SKUId)
      from OrderDetails OD
        join @ttLocationsToReplenish ttLR on (OD.DestLocationId = ttLR.LocationId) and
                                             (OD.SKUId = ttLR.SKUId) and
                                             (OD.InventoryClass1 = ttLR.InventoryClass1) and
                                             (OD.InventoryClass2 = ttLR.InventoryClass2) and
                                             (OD.InventoryClass3 = ttLR.InventoryClass3)
      where (OD.OrderId          = @vOrderId       ) and
            (ttLR.ReplenishGroup = @vReplenishGroup);

      /* Insert all the remaining locations into Order Details */
      insert into OrderDetails(OrderId, OrderLine, LineType, HostOrderLine, SKUId, UnitsOrdered,
                               UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsPerInnerPack,
                               InventoryClass1, InventoryClass2, InventoryClass3,
                               LocationId, Location, DestLocationId, DestLocation, BusinessUnit)
        output Inserted.OrderId, Inserted.OrderDetailId, Inserted.LocationId, Inserted.Location into @ttOrderDetails(OrderId, OrderDetailId, LocationId, Location)
        select @vOrderId,
               coalesce(@vNumLines, 0) + row_number() over (order by ttLR.LocationId)/* OrderLine */,
               StorageType/* Line Type */, 0/* HostOrderLine */, ttLR.SKUId, UnitsToReplenish,
               UnitsToReplenish, UnitsToReplenish, UnitsPerCase,
               InventoryClass1, InventoryClass2, InventoryClass3,
               LocationId, Location, LocationId, Location, @BusinessUnit
        from @ttLocationsToReplenish ttLR
          left outer join @ttLocationsUpdated LU on (ttLR.LocationId = LU.DestLocationId) and
                                                    (ttLR.SKUId      = LU.SKUId)
        where (LU.DestLocationId is null) and  -- Excludes the Locations whose quantities updated in above update statement
              (ttLR.ReplenishGroup = @vReplenishGroup);

      if (charindex('D', @vDebug) > 0) select CreatedDate, * from OrderDetails where OrderId = @vOrderId;

      /* If we are adding details to existing order then insert those details into PickBatchDetails table */
      if (@ReplenishWaveId is not null)
        insert into PickBatchDetails(PickBatchId, PickBatchNo, OrderId, OrderDetailId, BusinessUnit, CreatedBy)
          select @ReplenishWaveId, @ReplenishWaveNo, OrderId, OrderDetailId, @BusinessUnit, @UserId
          from @ttOrderDetails;

      /* Get the Locations to log Audit Trail */
      insert into @ttAuditLocations(EntityId, EntityKey)
        select distinct LocationId, Location
        from @ttOrderDetails;

      /* Reset values */
      select @vFirstOrderId   = coalesce(nullif(@vFirstOrderId, 0), @vOrderId),
             @vOrderId        = null,
             @vPickTicket     = null,
             @ReplenishWaveId = null,
             @ReplenishWaveNo = null;

      delete from @ttOrderDetails;
      delete from @ttLocationsUpdated;
    end

  /* Recount & Preprocess the orders */
  exec pr_OrderHeaders_Recalculate @ttOrders, 'CP' /* Counts */, @UserId;

  /* Logging AuditTrail for newly created Replenish Order locations */
  /* Audit Log */
  exec pr_AuditTrail_Insert 'GenerateReplenishOrder', @UserId, null /* audittimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'Location', @ttAuditLocations, @BusinessUnit;

  /* Insert Order Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttOrdersToWave, @BusinessUnit;

  /* If there are any new waves created then they should be waved */
  if exists (select * from @ttOrdersToWave)
    exec pr_Replenish_CreateReplenishWaves @ttOrdersToWave, @vOperation, @BusinessUnit, @UserId,
                                           @WaveNo, @ReplenishWaveId output, @ReplenishWaveNo output;

  /* Need all the orders that are updated to allocate them so capture them to hash table */
  /* We need this hash table while generating on-demand wave, as need to reallocate the orders updated
     and this hash table is not required while generating Min-Max replenishments
     insert into hash table only if it is created */
  if object_id('TempDB.dbo.#OrdersUpdated') is not null
    begin
      delete from #OrdersUpdated;
      insert into #OrdersUpdated (EntityId, EntityKey) select EntityId, EntityKey from @ttOrders;
    end

  /* Confirmation Message */
  insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
   select 'I' /* Info */, 'RO_GenerateOrders', OH.PickBatchNo, OH.PickTicket
   from @ttOrders ttO
     join OrderHeaders OH on (ttO.EntityId = OH.OrderId);

ErrorHandler:
  /* As an exception is raised on error, catch block catches the error and rollbacks transaction */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  exec pr_ActivityLog_AddMessage 'GenReplenishOrder', @ReplenishWaveId, @ReplenishWaveNo, 'Wave', @ConfirmMessage /* Message */, @@ProcId,
                                 @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* Generate error LOG here */
  exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_GenerateOrders */

Go
