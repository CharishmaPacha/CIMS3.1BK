/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/12/13  AY      pr_Allocation_AssignLPNtoOrder: Handle LPN not having Lot No (HPI-GoLive)
  2016/11/09  ??      pr_Allocation_AssignLPNtoOrder: Included procedure (HPI-GoLive)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_AssignLPNtoOrder') is not null
  drop Procedure pr_Allocation_AssignLPNtoOrder;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_AssignLPNtoOrder: Diff version of the pr_Allocation_ProcessPreAllocatedCases
    to allocate 1 LPN (multi-SKU as well) to an order
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_AssignLPNtoOrder
  (@LPNId       TRecordId,
   @OrderId     TRecordId,
   @Debug       TFlags = 'N')
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,

          @vRecordId             TRecordId,
          @vWaveId               TRecordId,
          @vWaveType             TTypeCode,
          @vWaveNo               TWaveNo,

          @vWarehouse            TWarehouse,
          @vOrderTypetoAllocate  TTypeCode,
          @vAccount              TAccount,

          @vLPNId                TRecordId,
          @vLPNDetailId          TRecordId,
          @vSKUId                TRecordId,
          @vOrderId              TRecordId,
          @vOrderDetailId        TRecordId,
          @vLot                  TLot,
          @vQuantity             TQuantity,
          @Operation             TOperation,
          @vUserId               TUserId,
          @vBusinessUnit         TBusinessUnit;

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

  select @vWaveId       = PickBatchId,
         @vAccount      = Account,
         @vBusinessUnit = BusinessUnit
  from OrderHeaders
  where OrderId = @OrderId;

  /* Get Wave Info */
  select @vWaveId    = RecordId,
         @vWaveNo    = BatchNo,
         @vWaveType  = BatchType,
         @vWarehouse = Warehouse
  from PickBatches
  where (RecordId = @vWaveId);

  /* Get Order Details to Allocate */
  insert into @ttOrderDetailsToAllocate
    select * from dbo.fn_PickBatches_GetOrderDetailsToAllocate(@vWaveId, @vWaveType, @vOrderTypetoAllocate, @Operation)
    where (OrderId = @OrderId);

  update @ttOrderDetailsToAllocate set Lot = coalesce(Lot, '');

  if (charindex('D', @Debug) > 0) select 'ODs to Allocate' Msg, * from @ttOrderDetailsToAllocate;

  /* Get the LPNs which are designated to Orders on the Wave */
  insert into @ttLPNsPreAllocated(EntityId)
    select distinct LPNId
    from LPNs L join OrderHeaders OH on L.Lot = OH.PickTicket
    where (OH.OrderId   = @OrderId) and
          (OH.Warehouse = L.DestWarehouse) and
          (OH.Ownership = L.Ownership) and
          (L.Status     = 'P'/* Putaway */);

  /* Get the LPN Details to allocate  */
  insert into @ttLPNDetailsToAllocate (LPNId, LPNDetailId, Quantity, SKUId, Lot)
    select LPNId, LPNDetailId, Quantity, SKUId, coalesce(Lot, '')
    from LPNDetails LD join @ttLPNsPreAllocated LPA on LD.LPNId = LPA.EntityId

  if (charindex('D', @Debug) > 0) select 'LPNs to Allocate' Msg, * from @ttLPNDetailsToAllocate;

  /* Loop thru each detail and allocate it */
  while exists (select * from @ttLPNsPreAllocated where RecordId > @vRecordId)
    begin
      /* get the next LPN to allocate */
      select top 1 @vRecordId    = RecordId,
                   @vLPNId       = EntityId
      from @ttLPNsPreAllocated
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Clear temp table */
      delete from @ttOrderDetailsAllocated

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
      output Inserted.LPNId, Inserted.LPNDetailId, Inserted.OrderId, Inserted.OrderDetailId, Inserted.SKUId, Inserted.Quantity into @ttOrderDetailsAllocated
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

      /* Add order to be recounted later if it is not in the list already */
      insert into @ttOrdersToRecount (EntityId)
        select distinct OrderId
        from @ttOrderDetailsAllocated ODA left outer join @ttOrdersToRecount OTR on ODA.OrderId = OTR.EntityId
        where OTR.EntityId is null

      /* There may be mutiple LPNs processed in single stretch so delete them */
      delete from @ttLPNsPreAllocated where EntityId in (select distinct LPNId from @ttOrderDetailsAllocated)
    end /* Next LPN */

  if (charindex('D', @Debug) > 0) select @vWaveId, @Operation, @vWarehouse, @vBusinessUnit, @vUserId;

  /* Recount Orders */
  exec pr_OrderHeaders_Recalculate @ttOrdersToRecount, 'S', @vUserId;

  if (charindex('D', @Debug) > 0)
    begin
      select * from LPNs L where LPNId = @LPNId;
      select * from LPNDetails LD where LPNId = @LPNid;
      select * from OrderDetails OD where OrderId = @OrderId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_AssignLPNtoOrder */

Go
