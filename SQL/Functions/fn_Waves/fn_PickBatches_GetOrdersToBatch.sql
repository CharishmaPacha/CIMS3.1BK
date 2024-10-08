/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/05  MS      fn_PickBatches_GetOrdersToBatch: Corrections to use latest UDF's (HA-804)
  2015/07/01  TK      fn_PickBatches_GetOrdersToBatch: changed to use like statement.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_PickBatches_GetOrdersToBatch') is not null
  drop Function fn_PickBatches_GetOrdersToBatch;
Go
/*------------------------------------------------------------------------------
  Proc fn_PickBatches_GetOrdersToBatch:  This function returns the
    Orders to batch that match the given ruleid.
    The orders that are considered are from the list of Orders given in OrderInfo
------------------------------------------------------------------------------*/
Create Function fn_PickBatches_GetOrdersToBatch
  (@OrderInfo     TEntityKeysTable readonly,
   @BatchingRules TPickBatchRules  readonly,
   @RuleId        TRecordId,
   @BusinessUnit  TBusinessUnit)
returns
  /* temp table  to return data */
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

  declare @OrdersToBatch       table
          (OrderId             TRecordId,
           OrderDetailId       TRecordId,
           PickTicket          TPickTicket,
           OrderType           TOrderType,
           OrderDate           TDate,
           PickZone            TZoneId,
           Status              TStatus,
           Priority            TPriority,
           NumLines            TCount,
           NumSKUs             TCount,
           NumUnits            TCount,
           TotalWeight         TWeight,
           TotalVolume         TVolume,
           NumLPNs             TCount,
           InnerPacks          TCount,
           SoldToId            TCustomerId,
           ShipToId            TShipToId,
           ShipVia             TShipVia,
           ShipFrom            TShipFrom,
           ShipToStore         TShipToStore,
           Account             TCustomerId,
           Warehouse           TWarehouse,
           Ownership           TOwnership,
           PickBatchGroup      TWaveGroup,
           OrderCategory1      TOrderCategory,
           OrderCategory2      TOrderCategory,
           OrderCategory3      TOrderCategory,
           OrderCategory4      TOrderCategory,
           OrderCategory5      TOrderCategory,
           UDF1                TUDF,
           UDF2                TUDF,
           UDF3                TUDF,
           UDF4                TUDF,
           UDF5                TUDF,
           BusinessUnit        TBusinessUnit);

  /* View orders to batch cross join with batching rules taking much time. So instead of this first filter the view orders
     to batch with selected orders to batch */
  insert into @OrdersToBatch (OrderId, OrderDetailId, PickTicket, OrderType, OrderDate, PickZone, Status, Priority, NumLines,
                              NumSKUs, NumUnits, TotalWeight, TotalVolume, NumLPNs, InnerPacks, SoldToId, ShipToId, ShipVia, ShipFrom,
                              ShipToStore, Account, Warehouse, Ownership, PickBatchGroup, OrderCategory1, OrderCategory2,
                              OrderCategory3, OrderCategory4, OrderCategory5, UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit)
    select OD.OrderId, 0, OD.PickTicket, OD.OrderType, OD.OrderDate, OD.PickZone, OD.Status, OD.Priority, OD.NumLines,OD.NumSKUs,
           OD.NumUnits, OD.TotalWeight, OD.TotalVolume, OD.NumLPNs, OD.NumLPNs, OD.SoldToId, OD.ShipToId, OD.ShipVia, OD.ShipFrom,
           OD.ShipToStore, OD.Account, OD.Warehouse, OD.Ownership, OD.PickBatchGroup, OD.OrderCategory1, OD.OrderCategory2,
           OD.OrderCategory3, OD.OrderCategory4, OD.OrderCategory5, OD.OH_UDF1, OD.OH_UDF2, OD.OH_UDF3, OD.OH_UDF4, OD.OH_UDF5, OD.BusinessUnit
    from  vwOrdersToBatch OD
      join @OrderInfo OI on (OD.OrderId = OI.EntityId);

  /* Insert data into table  */
  insert into @OrderDetailsToBatch
     select OD.OrderId,
            0,
            OD.PickTicket,
            OD.PickZone,
            OD.Status,
            OD.Priority,
            OD.NumLines,
            OD.NumSKUs,
            OD.NumUnits,
            coalesce(OD.TotalWeight, 0),
            coalesce(OD.TotalVolume, 0),
            OD.NumLPNs,
            OD.NumLPNs, --Num Innerpacks
            OD.Warehouse,
            OD.Ownership,
            OD.PickBatchGroup
     from @OrdersToBatch OD cross join @BatchingRules BR
     where (coalesce(OD.OrderType, '') = coalesce(BR.OrderType,     coalesce(OD.OrderType, ''))) and
           (coalesce(OD.Priority,  '') = coalesce(BR.OrderPriority, coalesce(OD.Priority,  ''))) and
           (coalesce(OD.SoldToId,  '') like coalesce(BR.SoldToId + '%',   coalesce(OD.SoldToId,  ''))) and
           (coalesce(OD.ShipToId,  '') like coalesce(BR.ShipToId + '%',      coalesce(OD.ShipToId,  ''))) and
           (coalesce(OD.ShipVia,   '') like coalesce(BR.ShipVia + '%',    coalesce(OD.ShipVia,   ''))) and
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
           (coalesce(OD.UDF1,      '') = coalesce(BR.OH_UDF1,       coalesce(OD.UDF1,      ''))) and
           (coalesce(OD.UDF2,      '') = coalesce(BR.OH_UDF2,       coalesce(OD.UDF2,      ''))) and
           (coalesce(OD.UDF3,      '') = coalesce(BR.OH_UDF3,       coalesce(OD.UDF3,      ''))) and
           (coalesce(OD.UDF4,      '') = coalesce(BR.OH_UDF4,       coalesce(OD.UDF4,      ''))) and
           (coalesce(OD.UDF5,      '') = coalesce(BR.OH_UDF5,       coalesce(OD.UDF5,      ''))) and
           (OD.NumUnits <= BR.OrderUnits) and
           (coalesce(OD.TotalWeight, 0) between coalesce(BR.OrderWeightMin, 0) and coalesce(BR.OrderWeightMax, 99999)) and
           (coalesce(OD.TotalVolume, 0) between coalesce(BR.OrderVolumeMin, 0) and coalesce(BR.OrderVolumeMax, 99999)) and
           (OD.BusinessUnit            = @BusinessUnit) and
           (BR.RecordId                = @RuleId)
     order by OD.PickBatchGroup, Priority, OD.Account, OD.OrderDate;

  return;
end /* fn_PickBatches_GetOrdersToBatch */

Go
