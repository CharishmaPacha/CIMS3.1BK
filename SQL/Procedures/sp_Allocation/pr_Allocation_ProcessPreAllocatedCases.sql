/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/06  VS      pr_Allocation_CreatePickTasks, pr_Allocation_ProcessPreAllocatedCases: Create LPN Pick for Engraving Orders (CID-1187)
  2017/02/03  AY      pr_Allocation_ProcessPreAllocatedCases: Commented account number '74' in check (HPI-GoLive)
  2016/11/02  AY      pr_Allocation_ProcessPreAllocatedCases: Name badges will be shipped separate for 77 (Enterprise) (HPI-GoLive)
  2016/09/30  AY      pr_Allocation_ProcessPreAllocatedCases: Process Specials without picking (HPI-GoLive)
  2016/07/16  TK      pr_Allocation_ProcessPreAllocatedCases: Bug fix to allocate Sew-2 Orders
  2016/07/04  TK      pr_Allocation_ProcessPreAllocatedCases: Inital Revision
                      pr_Allocation_AllocateWave: Included new step to allocate Pre-Reserved cases (HPI-226)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_ProcessPreAllocatedCases') is not null
  drop Procedure pr_Allocation_ProcessPreAllocatedCases;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_ProcessPreAllocatedCases: In some cases, the cases to be
    allocated are predetermined (like Special Orders for HPI) and our normal
    allocation and the rules wouldn't work because we may have multi-SKU cases
    which we have to pick as an LPN pick. The procedure is to address those scenarios.

 Implementation: For the particular wave

------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_ProcessPreAllocatedCases
  (@WaveId       TRecordId,
   @Operation    TDescription,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @Debug        TFlags = 'N')
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,
          @vDebug                TFlags,
          @vControlCategory      TCategory,

          @vRecordId             TRecordId,
          @vWaveId               TRecordId,
          @vWaveType             TTypeCode,
          @vWaveNo               TWaveNo,

          @vWarehouse            TWarehouse,
          @vOrderTypetoAllocate  TTypeCode,
          @vAccount              TAccount,
          @vCreatePickTasks      TControlValue,

          @vLPNId                TRecordId,
          @vLPNDetailId          TRecordId,
          @vSKUId                TRecordId,
          @vOrderId              TRecordId,
          @vOrderDetailId        TRecordId,
          @vLot                  TLot,
          @vQuantity             TQuantity;

  declare @ttOrderDetailsToAllocate TOrderDetailsToAllocateTable,
          @ttLPNsPreAllocated       TEntityKeysTable,
          @ttTaskInfo               TTaskInfoTable,
          @ttOrdersToRecount        TEntityKeysTable;

  declare @ttLPNDetailsToAllocate table (LPNId        TRecordId,
                                         LPNDetailId  TRecordId,
                                         Quantity     TQuantity,
                                         SKUId        TRecordId,
                                         Lot          TLot,

                                         RecordId     TRecordId identity(1,1));

  declare @ttOrderDetailsAllocated table (LPNId          TRecordId,
                                          LPNDetailId    TRecordId,
                                          OrderId        TRecordId,
                                          OrderDetailId  TRecordId,
                                          SKUId          TRecordId,
                                          Quantity       TQuantity,

                                          RecordId       TRecordId identity(1,1));

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;
  select @vDebug = coalesce(nullif(@Debug, ''), @vDebug);

  /* Get Wave Info */
  select @vWaveId          = RecordId,
         @vWaveNo          = BatchNo,
         @vControlCategory = 'Wave_' + WaveType,
         @vWaveType        = WaveType,
         @vWarehouse       = Warehouse,
         @vAccount         = Account
  from Waves
  where (RecordId = @WaveId);

  /* Get the default PicksLeftForDisplay control variable*/
  select @vCreatePickTasks = dbo.fn_Controls_GetAsString(@vControlCategory, 'PickTaskCreate', 'Y'/* Default */, @BusinessUnit, @UserId)

  /* Get Order Details to Allocate */
  insert into @ttOrderDetailsToAllocate
    select * from dbo.fn_PickBatches_GetOrderDetailsToAllocate(@vWaveId, @vWaveType, @vOrderTypetoAllocate, @Operation);

  if (charindex('D', @vDebug) > 0) select 'ODs to Allocate' Msg, * from @ttOrderDetailsToAllocate;

  /* Get the LPNs which are designated to Orders on the Wave */
  insert into @ttLPNsPreAllocated(EntityId)
    select LPNId
    from LPNs L join OrderHeaders OH on L.Lot = OH.PickTicket
    where (OH.PickBatchId = @vWaveId) and
          (OH.Warehouse   = L.DestWarehouse) and
          (OH.Ownership   = L.Ownership) and
          (L.OrderId is null) and
          (L.Status       = 'P'/* Putaway */);

  /* Get the LPN Details to allocate  */
  insert into @ttLPNDetailsToAllocate (LPNId, LPNDetailId, Quantity, SKUId, Lot)
    select LPNId, LPNDetailId, Quantity, SKUId, Lot
    from LPNDetails LD join @ttLPNsPreAllocated LPA on LD.LPNId = LPA.EntityId

  if (charindex('D', @Debug) > 0) select 'LPNs to Allocate' Msg, * from @ttLPNDetailsToAllocate;

  /* Loop thru each LPN and allocate it */
  while exists (select * from @ttLPNsPreAllocated where RecordId > @vRecordId)
    begin
      /* get the next LPN to allocate */
      select top 1 @vRecordId = RecordId,
                   @vLPNId    = EntityId
      from @ttLPNsPreAllocated
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Clear temp table */
      delete from @ttOrderDetailsAllocated;

      /* Verify if all details of the LPN can be allocated to the existing order details,
         if so, then update the LPNs, ODs and temp tables */
      if (not exists (select *
                      from @ttLPNDetailsToAllocate LDTA
                        join @ttOrderDetailsToAllocate ODTA on (LDTA.Lot      =  ODTA.Lot) and
                                                               (LDTA.SKUId    =  ODTA.SKUId) and
                                                               (LDTA.Quantity <= ODTA.UnitsToAllocate)
                      where (LDTA.LPNId = @vLPNId)))
        continue;

      if (charindex('D', @Debug) > 0)
        select 'Allocating' Msg, @vLPNId, *   from @ttLPNDetailsToAllocate LDTA
          join @ttOrderDetailsToAllocate ODTA on (LDTA.Lot      =  ODTA.Lot) and
                                                 (LDTA.SKUId    =  ODTA.SKUId) and
                                                 (LDTA.Quantity <= ODTA.UnitsToAllocate)
        where (LDTA.LPNId = @vLPNId);

      /* Update Order info on the LPN Details and output the allocations to temp table */
      update LD
      set LD.OrderId       = ODTA.OrderId,
          LD.OrderDetailId = ODTA.OrderDetailId,
          LD.OnhandStatus  = 'R' /* Reserved */
      output Inserted.LPNId, Inserted.LPNDetailId, Inserted.OrderId, Inserted.OrderDetailId,
             Inserted.SKUId, Inserted.Quantity
      into @ttOrderDetailsAllocated
      from LPNDetails LD
        join @ttLPNDetailsToAllocate LDTA on (LD.LPNDetailId = LDTA.LPNDetailId)
        join @ttOrderDetailsToAllocate ODTA on (LDTA.Lot      =  ODTA.Lot) and
                                               (LDTA.SKUId    =  ODTA.SKUId) and
                                               (LDTA.Quantity <= ODTA.UnitsToAllocate)
      where (LD.LPNId = @vLPNId);

      /* Associate LPN with the Wave */
      update LPNs
      set PickBatchId = @vWaveId,
          PickBatchNo = @vWaveNo
      where (LPNId = @vLPNId);

      /* Update UnitsAssigned on the Order Details */
      update OrderDetails
      set UnitsAssigned += ODA.Quantity
      from OrderDetails OD join @ttOrderDetailsAllocated ODA on OD.OrderDetailId = ODA.OrderDetailId;

      /* Reduce the UnitsToAllocate */
      update ODTA
      set UnitsToAllocate -= ODA.Quantity
      from @ttOrderDetailsToAllocate ODTA join @ttOrderDetailsAllocated ODA on ODTA.OrderDetailId = ODA.OrderDetailId;

      /* Recount LPN */
      exec pr_LPNs_Recount @vLPNId;

      /* Insert results to create Tasks Details to create an LPN Pick */
      insert into @ttTaskInfo (PickBatchId, PickBatchNo, OrderId, OrderDetailId, LPNId, LPNDetailId, SKUId, UnitsToAllocate)
        select @vWaveId, @vWaveNo, OrderId, OrderDetailId, LPNId, LPNDetailId, SKUId, Quantity
        from @ttOrderDetailsAllocated;

      /* Add order to be recounted later if it is not in the list already */
      insert into @ttOrdersToRecount (EntityId)
        select distinct OrderId
        from @ttOrderDetailsAllocated ODA left outer join @ttOrdersToRecount OTR on ODA.OrderId = OTR.EntityId
        where OTR.EntityId is null

      /* There may be mutiple LPNs processed in single stretch so delete them */
      delete from @ttLPNsPreAllocated where EntityId in (select distinct LPNId from @ttOrderDetailsAllocated)
    end /* Next LPN */

  if (charindex('D', @vDebug) > 0) select 'TaskInfo', * from @ttTaskInfo;
  if (charindex('D', @vDebug) > 0) select @vWaveId, @Operation, @vWarehouse, @BusinessUnit, @UserId;
  if (charindex('D', @vDebug) > 0) select * from @ttTaskInfo;

  /* Insert Task Details. They do not pick as they are employee labels only.
     They take them and pack them directly by going to shipping docs and printing SL and PL for each LPN */
  if (@vCreatePickTasks = 'Y')
    exec pr_Allocation_CreateTaskDetails @vWaveId, @ttTaskInfo, @Operation, @vWarehouse, @BusinessUnit, @UserId;

  if (charindex('D', @vDebug) > 0) select * from Tasks where Batchno = @vWaveNo;

  /* Recount Orders */
  exec pr_OrderHeaders_Recalculate @ttOrdersToRecount, 'S', @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_ProcessPreAllocatedCases */

Go
