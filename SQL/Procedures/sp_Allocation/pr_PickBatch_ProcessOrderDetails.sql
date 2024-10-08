/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/06/28  AY      pr_PickBatch_ProcessOrderDetails: Change to set DestZone
                        for non-conveyable items. Renamed proc as per convention
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_ProcessOrderDetails') is not null
  drop Procedure pr_PickBatch_ProcessOrderDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_ProcessOrderDetails:

   This procedure will do multiple operations.
    First One: Update DestZone on OrderDetails

    For this we have 3 cases.
    #1. If the SKU on orderdetail is non Sortable/Scannable then we need to direct the SKU to PTL.
    #2  =>  If the average number of units per order for all orders receiving a SKU
            within a wave exceeds a given number, the entire SKU for that wave
            should be processed through the PTL.

    #3 =>  If the number of units per line for any SKU exceeds a certain parameter,
           those units associated with orders exceeding that units per line
           Parameter will be processed through the PTL.

    #4 =>  If the % of orders within the wave that receive a specific SKU exceeds a
           user defined percentage, then the whole SKU for that wave will be
           processed through the PTL.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_ProcessOrderDetails
  (@PickBatchId      TRecordId,
   @InputXML         TXML = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vInputXML         XML,

          @vWaveType         TTypeCode,
          @vWaveId           TRecordId,
          @vWaveNo           TPickBatchNo,

          @vNumOrders        TInteger,

          /* PickBatch Attributes */
          @IsSortable             TFlag,
          @vDefaultDestination    TName,
          @vAvgUnitsPerOrder      TInteger,
          @vUnitsPerLine          TInteger,
          @vNumSKUOrdersPerBatch  TInteger,

          @ttBatchedOrderDetails  TBatchedOrderDetails;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Pick Batch info */
  select @vWaveType  = BatchType,
         @vWaveId    = RecordId,
         @vWaveNo    = BatchNo,
         @vNumOrders = NumOrders
  from PickBatches
  where (RecordId = @PickBatchId);

  if (@vMessageName is not null)
    goto ErrorHandler;

  insert into @ttBatchedOrderDetails
    select PickBatchId, OrderId, OrderDetailId, SKUId, UnitsOrdered,
           UnitsAuthorizedToShip, UnitsPerInnerPack, UnitsToAllocate, DestZone, null
    from vwPickBatchDetails
    where (PickBatchId = @vWaveId);

  /* if the user send input the required values as xml then we need to process this */
  if (@InputXML is not null)
    begin
      select @vInputXML = convert(xml, @InputXML);

      select @vAvgUnitsPerOrder     = nullif(Record.Col.value('AvgUnitsPerOrder[1]', 'TInteger'), ''),
             @vUnitsPerLine         = nullif(Record.Col.value('UnitsPerLine[1]', 'TInteger'),  ''),
             @vNumSKUOrdersPerBatch = nullif(Record.Col.value('NumSKUOrdersPerBatch[1]', 'TInteger'), '')
      from @vInputXML.nodes('/ModifyPickBatches/Data') as Record(Col);

      /* Get default dest zone here */
      select @vDefaultDestination   = DefaultDestination
      from PickBatchAttributes
      where (PickBatchId = @vWaveId);
    end

  /* if the user does not provide the input values then we need to process this default values.*/
  if ((coalesce(@vAvgUnitsPerOrder, 0) = 0) and (coalesce(@vUnitsPerLine, 0) = 0))
    begin
      /* Get pickBatch attributes here */
      select @vAvgUnitsPerOrder     = AvgUnitsPerOrder,
             @vUnitsPerLine         = UnitsPerLine,
             @vNumSKUOrdersPerBatch = NumSKUOrdersPerBatch,
             @vDefaultDestination   = DefaultDestination
      from PickBatchAttributes
      where (PickBatchId = @vWaveId);
    end

  /* Update dest zone on remaining OrderDetails to default destination for the Wave Type.
     This is sufficient for all wavetypes including the remaining orderlines for RETAIL */
  update @ttBatchedOrderDetails
  set DestZone  = case when S.IsConveyable = 'N' then 'NON-CONV' else @vDefaultDestination end,
      Reference = case when S.IsConveyable = 'N' then 'NON-CONV' else 'DEFAULTDEST' end
  from @ttBatchedOrderDetails BOD join SKUs S on BOD.SKUId = S.SKUId;

  /* if the wavetype is Retail then we will process this */
  if (@vWaveType = 'RETAIL')
    begin
      /* case 1: Update Orderdetails dest zone based on the SKUs sortable nature
         We can set this in preprocess it self  */
      update TBOD
      set DestZone  = 'PTL',
          Reference = case when S.UDF4 = 'Y'       then 'ShipAlone'
                           when S.IsSortable = 'N' then 'NonSortable'
                           else 'NotScannable'
                      end
      from @ttBatchedOrderDetails TBOD
        join vwPickBatchDetails PBD on (PBD.OrderDetailId = TBOD.OrderDetailId)
        join SKUs               S   on (S.SKUId         = TBOD.SKUId) and
                                       ((S.IsSortable   = 'N' /* No */) or
                                        (S.IsScannable  = 'N') or
                                        (S.UDF4         = 'Y' /* ShipAlone = Y */)) and
                                        (S.IsConveyable = 'Y' /* Yes */)
      where (PBD.PickBatchID   = @vWaveId);

      /* Case #3: If the no of Units per line exceeds user defined value */
      update @ttBatchedOrderDetails
      set DestZone  = 'PTL',
          Reference = 'UnitsPerLine'
      where (UnitsAuthorizedToShip > @vUnitsPerLine) and
            (DestZone <> 'NON-CONV');

      /* Case #2: If the Avg units per Order exceeds defined threshold then those lines
                  will be processed on PTL
         Case #4: the % of orders within the wave that receive a specific SKU exceeds a
                  user defined percentage
         For both of these, exclude non-conveyable from the equation */
      with OrderCounts (SKUId, NumOrder, OrderPercentagePerSKU, AvgUnits) As
      (
        select BOD.SKUId,
               count(distinct OrderId),                                     /* count of orders associated with the SKU */
               (1.0 * count(distinct OrderId) / @vNumOrders) * 100,         /* percentage of Orders needing SKU */
               (1.0 * sum(UnitsAuthorizedToShip) / count(distinct OrderId)) /* Get the average units of SKU per Order in batch */
        from @ttBatchedOrderDetails BOD left outer join SKUs S on BOD.SKUId = S.SKUId
        where (S.IsConveyable = 'Y')
        group by BOD.SKUId
      )
      update TBOD
      set DestZone  = 'PTL',
          Reference = case when (OC.OrderPercentagePerSKU > @vNumSKUOrdersPerBatch) then 'HighPercentage'
                           else 'HighAverage'
                      end
      from @ttBatchedOrderDetails TBOD
        join OrderCounts        OC  on (OC.SKUId = TBOD.SKUId)
      where ((OC.OrderPercentagePerSKU > @vNumSKUOrdersPerBatch) or
             (OC.AvgUnits > @vAvgUnitsPerOrder) and
             (DestZone <> 'NON-CONV'));
    end

  /* select from temp table here  */
  select PickBatchId, OrderId, OrderDetailId,
         SKUId, UnitsOrdered, UnitsAuthorizedToShip,
         UnitsPerInnerPack, UnitsToAllocate, DestZone, null /* Reference */
  from @ttBatchedOrderDetails;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_ProcessOrderDetails */

Go
