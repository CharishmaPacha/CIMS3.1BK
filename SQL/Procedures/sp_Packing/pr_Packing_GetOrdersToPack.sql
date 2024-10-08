/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/13  VS      pr_Packing_GetOrdersToPack: Made changes for performance improvement (S2GCA-1212)
  2015/10/08  DK      pr_Packing_GetOrdersToPack: Enhanced to show other than bulk orders in OrderPacking screen (FB-418).
  2015/02/20  DK      Added pr_Packing_GetOrdersToPack and pr_Packing_GetDetailsToPack
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetOrdersToPack') is not null
  drop Procedure pr_Packing_GetOrdersToPack;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetOrdersToPack:
  procedure return orders ready to be packed
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetOrdersToPack
  (@PackingCriteria TXML)
as
  declare @vOrderId      TRecordId,
          @ValidOrderId  TRecordId,
          @vPalletId     TRecordId,
          @ValidPalletId TRecordId,
          @vReturnCode   TInteger,
          @vMessageName  TMessageName;

  declare @vInputParams       TInputParams;
begin
  /* Temp table based on vwOrdersToPack structure */
  select * into #OrdersToPack from vwOrdersToPack where 1 = 2;

  /* read the values for parameters */
  insert into @vInputParams
    select * from dbo.fn_GetInputParams(@PackingCriteria);

  /* Initialize param variables */
  select @vOrderId = null,
         @vPalletId = null;

  /* read param variables */
  select @vOrderId   = case when ParamName = 'ORDERID'  then ParamValue else @vOrderId  end,
         @vPalletId  = case when ParamName = 'PALLETID' then ParamValue else @vPalletId end
  from @vInputParams;

  /* Validate Pallet  given */
  if (@vPalletId is not null)
    begin
      select @ValidPalletId = PalletId
      from Pallets
      where (PalletId = @vPalletId);

      if (@ValidPalletId is null)
        set @vMessageName = 'PalletDoesNotExist';
    end

  /* Validate Order  given */
  if (@vOrderId is not null)
    begin
      select @ValidOrderId = OrderId
      from OrderHeaders
      where (OrderId = @vOrderId)

      if (@ValidOrderId is null)
        set @vMessageName = 'PickTicketIsInvalid';
    end

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If PalletId is not null, Assume it is the Picking Cart, and user is packing for a batch/cart */
  if (@vPalletId is not null)
    begin
      insert into #OrdersToPack
      select *
      from vwOrdersToPack
      where (PalletId = @vPalletId) and (OrderId > 0);
    end
  else
    begin
      /* Send back all the Orders ready to be packed, for Batches containing Bulk Pull Orders in Picked/Packing Status */
      with BulkPullBatches(PickBatchNo)
       as
       (
        select distinct PickBatchNo from OrderHeaders  OH
        join PickBatches PB on PB.BatchNo = OH.PickBatchNo and PB.Status in ('K' /* Picked */, 'A' /* Packing */, 'P' /* Picking */)
        where (OH.OrderType = 'B') and (OH.Archived = 'N') and (OH.Status not in ('S', 'D', 'X'))
       ),
       OrdersToPack(OrderId)
       as
       (
        select OrderId from OrderHeaders  OH
        join BulkPullBatches BPB on BPB.PickBatchNo = OH.PickBatchNo
        where (OH.OrderType <> 'B' /* Bulk Pull */) and OH.Status in ('W' /* Batched */, 'P' /* Picked */)
       )
       insert into #OrdersToPack
       select coalesce(LPNId, 0), coalesce(LPN,''), coalesce(LPNType,''), coalesce(LPNTypeDescription,''), coalesce(Status,''), coalesce(StatusDescription,''),
              coalesce(CoO,''), coalesce(InnerPacks, 0), coalesce(Quantity, 0), coalesce(SKUCount, 0), coalesce(PalletId, 0),  coalesce(Pallet, ''),
              coalesce(LocationId, 0), coalesce(Location, ''), coalesce(Ownership, ''), coalesce(ShipmentId, 0), coalesce(LoadId, 0),  coalesce(ASNCase, '') ,
              coalesce(VOTP.OrderId, 0),coalesce(PickTicket, '') as PickTicket, coalesce(SalesOrder, '') , coalesce(PickBatchId, 0),  coalesce(PickBatchNo, ''),
              coalesce(ShipVia, ''), coalesce(ShipViaDescription, ''), coalesce(DesiredShipDate, ''), coalesce(CancelDate, 0), coalesce(OrderPriority, 0), coalesce(OrderStatus,''),
              coalesce(OrderStatusDescription, ''), coalesce(OrderShortPick, ''), coalesce(OrderComplete, ''), coalesce(OrderCategory1, ''), coalesce(OrderCategory2, ''),
              coalesce(OrderCategory3, ''), coalesce(OrderCategory4, ''), coalesce(OrderCategory5, ''), coalesce(OH_UDF1, ''), coalesce(OH_UDF2, ''), coalesce(OH_UDF3, ''),
              coalesce(OH_UDF4, ''), coalesce(OH_UDF5, ''), coalesce(OH_UDF6, ''), coalesce(OH_UDF7, ''), coalesce(OH_UDF8, ''), coalesce(OH_UDF9, ''), coalesce(OH_UDF10, ''),
              coalesce(UDF1, ''), coalesce(UDF2, ''), coalesce(UDF3, ''), coalesce(UDF4, ''), coalesce(UDF5, ''), coalesce(vwUDF1, ''), coalesce(vwUDF2, ''), coalesce(vwUDF3, ''),
              coalesce(vwUDF4, ''), coalesce(vwUDF5, ''), coalesce(BusinessUnit, '')
       from vwBulkOrdersToPack VOTP
       join OrdersToPack OTP on OTP.OrderId = VOTP.OrderId;

    end

    select * from #OrdersToPack;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_GetOrdersToPack */

Go
