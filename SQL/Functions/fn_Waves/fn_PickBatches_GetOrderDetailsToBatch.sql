/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/10/01  PK      fn_PickBatches_GetOrderDetailsToBatch: Batching criteria on OD.UDF10 with PBR.UDF1.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_PickBatches_GetOrderDetailsToBatch') is not null
  drop Function fn_PickBatches_GetOrderDetailsToBatch;
Go
/*------------------------------------------------------------------------------
  Proc fn_PickBatches_GetOrderDetailsToBatch:  This function returns the
    OrderDetails to batch that match with the given rule id. The order details
    that are considered are the onlye given in OrderInfo only.
------------------------------------------------------------------------------*/
Create Function fn_PickBatches_GetOrderDetailsToBatch
  (@OrderInfo     TEntityKeysTable readonly,
   @BatchingRules TPickBatchRules  readonly,
   @RuleId        TRecordId,
   @BusinessUnit  TBusinessUnit)
returns
   /* temp table  to return data */
     --@OrderDetailsToBatch  TOrderInfoToBatch
   @OrderDetailsToBatch   table
     (OrderId             TRecordId,
      OrderDetailId       TRecordId,
      PickTicket          TPickTicket,
      PickZone            TZoneId,
      Status              TStatus,
      Priority            TPriority,
      Lines               TCount,
      SKUs                TCount,
      Units               TCount,
      Weight              TWeight,
      Volume              TVolume,
      LPNs                TCount,
      InnerPacks          TCount,
      Warehouse           TWarehouse,
      Ownership           TOwnership,
      PickBatchGroup      TWaveGroup)
as
begin
  /* Insert data into table  */
  insert into @OrderDetailsToBatch
     select OD.OrderId,
            OD.OrderDetailId,
            OD.PickTicket,
            OD.PickZone,
            OD.Status,
            OD.Priority,
            OD.NumLines,
            OD.NumSKUs,
            OD.NumUnits,
            coalesce(OD.OrderDetailWeight, 0),
            coalesce(OD.OrderDetailVolume, 0),
            OD.NumLPNs,
            OD.NumLPNs,    --temporary..not using
            OD.Warehouse,
            OD.Ownership,
            OD.PickBatchGroup
     from vwOrderDetailsTobatch OD cross join @BatchingRules BR
       inner join @OrderInfo OI on (OD.OrderDetailId = OI.EntityId)
     where (coalesce(OD.OrderType, '') = coalesce(BR.OrderType,     coalesce(OD.OrderType, ''))) and
           (coalesce(OD.Priority,  '') = coalesce(BR.OrderPriority, coalesce(OD.Priority,  ''))) and
           (coalesce(OD.SoldToId,  '') like coalesce(BR.SoldToId,   coalesce(OD.SoldToId,  ''))) and
           (coalesce(OD.ShipToId,  '') = coalesce(BR.ShipToId,      coalesce(OD.ShipToId,  ''))) and
           (coalesce(OD.ShipVia,   '') like coalesce(BR.ShipVia + '%',
                                                                    coalesce(OD.ShipVia,   ''))) and
           (coalesce(OD.ShipFrom,  '') like coalesce(BR.ShipFrom,         coalesce(OD.ShipFrom,     ''))) and
           (coalesce(OD.ShipToStore, '') like coalesce(BR.ShipToStore,    coalesce(OD.ShipToStore,  ''))) and
           (coalesce(OD.Account,   '') like coalesce(BR.Account + '%',    coalesce(OD.Account,      ''))) and
           (coalesce(OD.PickZone,  '') = coalesce(BR.PickZone,      coalesce(OD.PickZone,  ''))) and
           (coalesce(OD.PickBatchGroup,  '')  = coalesce(BR.PickBatchGroup, coalesce(OD.PickBatchGroup, ''))) and
           (coalesce(OD.Ownership, '') = coalesce(BR.Ownership,     coalesce(OD.Ownership, ''))) and
           (coalesce(OD.Warehouse, '') = coalesce(BR.Warehouse,     coalesce(OD.Warehouse, ''))) and
           (coalesce(OD.OrderCategory1, '') = coalesce(BR.OH_Category1, coalesce(OD.OrderCategory1, ''))) and
           (coalesce(OD.OrderCategory2, '') = coalesce(BR.OH_Category2, coalesce(OD.OrderCategory2, ''))) and
           (coalesce(OD.OrderCategory3, '') = coalesce(BR.OH_Category3, coalesce(OD.OrderCategory3, ''))) and
           (coalesce(OD.OrderCategory4, '') = coalesce(BR.OH_Category4, coalesce(OD.OrderCategory4, ''))) and
           (coalesce(OD.OrderCategory5, '') = coalesce(BR.OH_Category5, coalesce(OD.OrderCategory5, ''))) and
           (coalesce(OD.OH_UDF1,   '') = coalesce(BR.OH_UDF1,       coalesce(OD.OH_UDF1,   ''))) and
           (coalesce(OD.OH_UDF2,   '') = coalesce(BR.OH_UDF2,       coalesce(OD.OH_UDF2,   ''))) and
           (coalesce(OD.OH_UDF3,   '') = coalesce(BR.OH_UDF3,       coalesce(OD.OH_UDF3,   ''))) and
           (coalesce(OD.OH_UDF4,   '') = coalesce(BR.OH_UDF4,       coalesce(OD.OH_UDF4,   ''))) and
           (coalesce(OD.OH_UDF5,   '') = coalesce(BR.OH_UDF5,       coalesce(OD.OH_UDF5,   ''))) and
           (coalesce(OD.OrderDetailWeight, 0) <= coalesce(BR.OrderDetailWeight, OD.OrderDetailWeight)) and
           (coalesce(OD.OrderDetailVolume, 0) <= coalesce(BR.OrderDetailVolume, OD.OrderDetailVolume)) and
           (coalesce(OD.OD_UDF10,   '') = coalesce(BR.UDF1,          coalesce(OD.OD_UDF10,   ''))) and
           (coalesce(OD.TotalWeight, 0) between coalesce(BR.OrderWeightMin, 0) and coalesce(BR.OrderWeightMax, 99999)) and
           (coalesce(OD.TotalVolume, 0) between coalesce(BR.OrderVolumeMin, 0) and coalesce(BR.OrderVolumeMax, 99999)) and
           (OD.BusinessUnit            = @BusinessUnit) and
           (BR.RecordId                = @RuleId)
     order by OD.CancelDate, OD.PickBatchGroup, Priority;

  return;
end /* fn_PickBatches_GetOrderDetailsToBatch */

Go
