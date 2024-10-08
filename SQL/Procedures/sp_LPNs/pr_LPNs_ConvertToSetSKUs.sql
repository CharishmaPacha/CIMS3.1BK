/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/30  RV      pr_LPNs_ConvertToSetSKUs: Initial version (OB2-1947)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_ConvertToSetSKUs') is not null
  drop Procedure pr_LPNs_ConvertToSetSKUs;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_ConvertToSetSKUs:

  This procedure converts the component SKUs to set SKUs and this procedure doesn't have any validations
  and caller procedure should take care of deleting the invalid statuses of LPNs. As of now we are calling
  this procedure from pallet drop and we will call this procedure in actions.
  This procedure identity the set and component SKUs and add new detail with set SKU with possible quantity
  and delete the component SKUs. Also send the positive inventory change exports for the Set SKUs and negative
  inventory change for the component SKUs
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_ConvertToSetSKUs
  (@ttLPNsToConvert  TEntityKeysTable readonly,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vRecordId        TRecordId,

          @vOrderId          TRecordId,
          @vOrderDetailId    TRecordId,
          @vLPNId            TRecordId,
          @vLPNDetailId      TRecordId,
          @vSKUId            TRecordId,

          @vHostOrderLineNo  THostOrderLine,
          @vQuantity         TQuantity,
          @vLDQuantity       TQuantity,
          @vPossibleSetQty   TQuantity,
          @vTotalSetQuantity TQuantity,

          @vReasonCode       TReasonCode,
          @vReference        TReference;

  declare @ttODsToConvertSetSKUs    TOrderDetailsToConvertSetSKUs;
begin
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vLDQuantity      = 0;

  if (object_id('tempdb..#LPNsToConvertSets') is null)   select * into #LPNsToConvertSets   from @ttLPNsToConvert;
  if (object_id('tempdb..#ODsToConvertSetSKUs') is null) select * into #ODsToConvertSetSKUs from @ttODsToConvertSetSKUs;

  /* Fetch the component SKUs of picked LPNs and corresponding order details */
  insert into #ODsToConvertSetSKUs (OrderDetailId, OrderId, HostOrderLine, LineType, ParentLineId, ParentHostLineNo,
                                    UnitsPerInnerPack, UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, UnitsToAllocate,
                                    LPNId, LPNDetailId, SKUId, UnitsPicked,
                                    KitsToShip, KitsPicked, Lot)
    select OD.OrderDetailId, OD.OrderId, OD.HostOrderLine, OD.LineType, OD.ParentLineId, OD.ParentHostLineNo,
           coalesce(nullif(OD.UnitsPerInnerPack, 0), 1), OD.UnitsOrdered, OD.UnitsAuthorizedToShip, OD.UnitsAssigned, OD.UnitsToAllocate,
           LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.Quantity,
           OD.UnitsAuthorizedToShip/coalesce(nullif(OD.UnitsPerInnerPack, 0), 1),
           LD.Quantity/coalesce(nullif(OD.UnitsPerInnerPack, 0), 1), OD.Lot
    from #LPNsToConvertSets LTC
      join LPNDetails LD on (LD.LPNId = LTC.EntityId) and (LD.OnhandStatus = 'R' /* Reserved */)
      join OrderDetails OD on (OD.OrderDetailId = LD.OrderDetailId) and (OD.LineType = 'C');

  /* Exit if there are no components SKUs for the LPNs */
  if (@@rowcount = 0)
    return;

  /* Fetch the set SKUs of the picked order details and any other components of the sets that may not
     be in the given LPNs */
  insert into #ODsToConvertSetSKUs (OrderDetailId, OrderId, HostOrderLine, LineType, ParentLineId, ParentHostLineNo,
                                    UnitsPerInnerPack, UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, UnitsToAllocate,
                                    LPNId, LPNDetailId, SKUId, UnitsPicked,
                                    KitsToShip, KitsPicked, Lot)
    select distinct OD.OrderDetailId, OD.OrderId, OD.HostOrderLine, OD.LineType, OD.ParentLineId, OD.ParentHostLineNo,
                    coalesce(nullif(OD.UnitsPerInnerPack, 0), 1), OD.UnitsOrdered, OD.UnitsAuthorizedToShip, OD.UnitsAssigned, OD.UnitsToAllocate,
                    ODTC.LPNId, LD.LPNDetailId, OD.SKUId, LD.Quantity,
                    OD.UnitsAuthorizedToShip/coalesce(nullif(OD.UnitsPerInnerPack, 0), 1),
                    LD.Quantity/coalesce(nullif(OD.UnitsPerInnerPack, 0), 1), OD.Lot
    from #ODsToConvertSetSKUs ODTC
      join OrderDetails OD on ((OD.OrderId = ODTC.OrderId) and (((OD.HostOrderLine = ODTC.ParentHostLineNo) and (OD.LineType = 'S') ) or
                                                                ((OD.ParentHostLineNo = ODTC.ParentHostLineNo) and (OD.LineType = 'C'))))
      left join LPNDetails LD on (LD.OrderDetailId = OD.OrderDetailId)
    where (OD.OrderDetailId not in (select OrderDetailId from #ODsToConvertSetSKUs));

  /* Delete component lines if corresponding set line is not available */
  delete ODTC1
  from  #ODsToConvertSetSKUs ODTC1
    left join #ODsToConvertSetSKUs ODTC2 on (ODTC1.ParentHostLineNo = ODTC2.HostOrderLIne)
  where (ODTC2.OrderId is null) and (ODTC1.LineType = 'C');

  /* Find out the max possible Sets for the Set SKUs based upon the LPN detail quantity */
  with MaxSetQuantity as
  (
     select ODTC.LPNId, ODTC.OrderId, ODTC.ParentHostLineNo, min(coalesce(ODTC.KitsPicked, 0)) KitsToConvert
     from #ODsToConvertSetSKUs ODTC
     group by ODTC.LPNId, ODTC.OrderId, ODTC.ParentHostLineNo
  )
  update ODTC
  set ODTC.KitsToConvert  = MSQ.KitsToConvert,
      ODTC.UnitsToConvert = MSQ.KitsToConvert * UnitsPerInnerPack
  from #ODsToConvertSetSKUs ODTC
    join MaxSetQuantity MSQ on (MSQ.LPNId = ODTC.LPNId) and (MSQ.ParentHostLineNo = ODTC.ParentHostLineNo);

  /* Update the possible set quantity */
  update SODTC
  set SODTC.KitsToConvert  = CODTC.KitsToConvert,
      SODTC.UnitsToConvert = CODTC.UnitsToConvert
  from #ODsToConvertSetSKUs SODTC
    join #ODsToConvertSetSKUs CODTC on (CODTC.LPNId = SODTC.LPNId) and (CODTC.ParentHostLineNo = SODTC.HostOrderLine)
  where (SODTC.LineType = 'S');

  /* Delete details if even single set also not possible */
  delete from #ODsToConvertSetSKUs where KitsToConvert = 0;

  /* Exist if there are set details to convert */
  if not exists (select * from #ODsToConvertSetSKUs)
    return;

  /* Reduce the component detail quantity from component SKUs on order details */
  update OD
  set OD.UnitsAssigned         -= ODTC.UnitsToConvert,
      OD.UnitsAuthorizedToShip -= ODTC.UnitsToConvert
  from OrderDetails OD
    join #ODsToConvertSetSKUs ODTC on (OD.OrderDetailId = ODTC.OrderDetailId)
  where (ODTC.LineType = 'C');

  /* Add the component detail quanity to the set SKUs on order details */
  update OD
  set OD.UnitsAuthorizedToShip += ODTC.KitsToConvert,
      OD.UnitsAssigned         += ODTC.KitsToConvert
  from OrderDetails OD
    join #ODsToConvertSetSKUs ODTC on (OD.OrderDetailId = ODTC.OrderDetailId)
  where (ODTC.LineType = 'S');

  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Update Weight and Volume */
  update ODTC
  set Weight = coalesce(ODTC.UnitsToConvert * S.UnitWeight, 0.0),
      Volume = coalesce(ODTC.UnitsToConvert * S.UnitVolume, 0.0)
  from #ODsToConvertSetSKUs ODTC
    join SKUs S on (S.SKUId = ODTC.SKUId);

  /* Reduce the component details quantity on LPN details */
  update LD
  set LD.Quantity  -= ODTC.UnitsToConvert,
      LD.Weight     = coalesce(LD.Weight, 0) - ODTC.Weight,
      LD.Volume     = coalesce(LD.Volume, 0) - ODTC.Volume,
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  output 'InvCh', -deleted.Quantity, deleted.LPNId, deleted.LPNDetailId, deleted.SKUId, @UserId
  into #ExportRecords (TransType, TransQty, LPNId, LPNDetailId, SKUId, CreatedBy)
  from LPNDetails LD
    join #ODsToConvertSetSKUs ODTC on (LD.LPNDetailId = ODTC.LPNDetailId)
  where (ODTC.LineType = 'C');

  /* Delete the converted sets LPN details with the quantity as zero */
  delete LD
  from LPNDetails LD
    join #ExportRecords E on (E.LPNDetailId = LD.LPNDetailId)
  where (LD.Quantity = 0);

  /* If already set exists then add the possible quantity to the set */
  update LD
  set LD.Quantity  = Quantity + ODTC.UnitsToConvert,
      LD.Weight    = coalesce(LD.Weight, 0) + ODTC.Weight,
      LD.Volume    = coalesce(LD.Volume, 0) + ODTC.Volume,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output 'InvCh', inserted.Quantity, inserted.LPNId, inserted.LPNDetailId, inserted.SKUId, @UserId
  into #ExportRecords (TransType, TransQty, LPNId, LPNDetailId, SKUId, CreatedBy)
  from LPNDetails LD join
    #ODsToConvertSetSKUs ODTC on (LD.LPNDetailId = ODTC.LPNDetailId)
  where (ODTC.LineType = 'S');

  /* Add new detail line if not exists for the set SKUs */
  insert into LPNDetails(LPNId, OnhandStatus, SKUId, Quantity, ReservedQty, OrderId, OrderDetailId,
                         Weight, Volume, Lot, BusinessUnit, CreatedBy)
  output 'InvCh', inserted.Quantity, inserted.LPNId, inserted.LPNDetailId, inserted.SKUId, @UserId
  into #ExportRecords (TransType, TransQty, LPNId, LPNDetailId, SKUId, CreatedBy)
    select LPNId, 'R' /* Reserved */, SKUId, KitsToConvert, KitsToConvert, OrderId, OrderDetailId,
           Weight, Volume, Lot, @BusinessUnit, @UserId
    from #ODsToConvertSetSKUs
    where (LineType = 'S') and
          (coalesce(LPNDetailId, 0) = 0);

  /* Exports */
  exec pr_Exports_InsertRecords 'InvCh', 'LPN' /* TransEntity - LPN */, @BusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_ConvertToSetSKUs */

Go
