/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/22  TK      Updated pr_PickBatch_Modify and pr_PickBatch_PlanBatch to log proper Audit Trail.
  2014/06/02  PKS     pr_PickBatch_PlanBatch: Minor changes made such that all Detail Summary values should return either Zero or positive values only.
  2014/05/27  TD      pr_PickBatch_PlanBatch:Changed captions(Units => # Units) to show in grid.
  2014/04/23  TD      added new procedure pr_PickBatch_PlanBatch,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_PlanBatch') is not null
  drop Procedure pr_PickBatch_PlanBatch;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_PlanBatch:

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

    #5 => If the SKU is non-conveyable, then we would pick from NON-CONV
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_PlanBatch
  (@PickBatchId          TRecordId,
   @InputXML             TXML,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId,
   @xmlResult            TXML = null output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vInputXML             XML,

          @vWaveType             TTypeCode,
          @vWaveId               TRecordId,
          @vWaveNo               TPickBatchNo,
          @vBatchStatus          TStatus,

          @vOperation            TDescription,

          @vNumOrders            TCount,
          @vBatchedUnits         TQuantity,
          @vNumSKUs              TCount,
          @vNumLines             TCount,
          @vModifiedDate         TDateTime,

          @vTotalCases           TInnerPacks,
          @vTotalUnits           TQuantity,
          @vTotalCaseUnits       TQuantity,
          @vSDCases              TInnerPacks,
          @vSDLines              TCount,       --SD - ShipDock
          @vSDSKUs               TCount,
          @vSDUnits              TQuantity,
          @vSDCaseUnits          TQuantity,
          @vSDCaseTotalUnits     TQuantity,

          @vAvgUnitsPerOrder     TInteger,
          @vUnitsPerLine         TInteger,
          @vNumSKUOrdersPerBatch TInteger,

          @vxmlTotalsSummary     XML,
          @vxmlBatchProcessDetails
                                 XML,
          @ttBatchedOrderDetails TBatchedOrderDetails;

 declare @ttBatchProcessDetails table
          (PickBatchId   TRecordId,
           DestZone      TZoneId,
           NumSKUs       TCount,
           NumLines      TCount,
           NumCases      TInteger,
           NumCaseUnits  TInteger,
           NumUnits      TInteger,
           ShipDockCases TInnerPacks,
           TotalUnits as NumCaseUnits + NumUnits);

 declare @ttTotalsSummary table
          (PickBatchId  TRecordId,
           Name         TName,
           Value        TInteger,
           Percentage   TInteger);

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Pick Batch info */
  select @vWaveType     = WaveType,
         @vWaveId       = WaveId,
         @vWaveNo       = WaveNo,
         @vNumOrders    = NumOrders,
         @vNumSKUs      = NumSKUs,
         @vBatchedUnits = NumUnits,
         @vNumLines     = NumLines,
         @vBatchStatus  = Status
  from Waves
  where (WaveId = @PickBatchId);

  /* Validations */
  if (@vWaveId is null)
    set @vMessageName = 'PickBatchInvalid';
  else
  if (@vBatchStatus <> 'N' /* New */)
    set @vMessageName = 'PlanBatch_InvalidStatus';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* convert the input into xml */
  if (@InputXML is not null)
    begin
      select @vInputXML  = convert(xml, @InputXML);

      select @vOperation = Record.Col.value('Action[1]', 'TAction')
      from @vInputXML.nodes('/ModifyPickBatches') as Record(Col);
    end

  /* Process the Order Details and capture data into a temp table */
  insert into @ttBatchedOrderDetails
    exec pr_PickBatch_ProcessOrderDetails @vWaveId, @InputXML, @BusinessUnit, @UserId;

  /* insert all details into CTE, we need to seperate here cases and remaining units - cases here are shipdock cases */
  with ProcessedDetails(SKUId, DestZone, Lines, Cases, RemUnits, UnitsPerInnerpack)
  as
  (
    select SKUId, DestZone, count(OrderDetailId), sum(UnitsAuthorizedToShip / UnitsPerInnerPack),
           sum(UnitsAuthorizedToShip % UnitsPerInnerPack), UnitsPerInnerPack
    from @ttBatchedOrderDetails
    group by SKUId, DestZone, UnitsPerInnerPack
  ),
  /* Insert data into CTE by SKU and DestZone with cases and Units calculation */
  DetailsByZone(SKUId, DestZone, NumSKUs, NumLines, ShippingDockCases, BPTCases, NumUnits, BPTCaseUnits, SPDOCKUnits)
  as
  (
   select SKUId, DestZone, count(distinct SKUId), sum(Lines), sum(Cases), sum(RemUnits / UnitsPerInnerPack),
          sum(RemUnits % UnitsPerInnerPack),  sum((RemUnits / UnitsPerInnerPack) * UnitsPerInnerPack),
          sum(Cases * UnitsPerInnerPack)
   from ProcessedDetails
   group by SKUId, DestZone
  )

  /* insert data into temp table here */
  insert into @ttBatchProcessDetails(PickBatchId, DestZone, NumSKUs, NumLines, NumCases, NumCaseUnits,
                                     NumUnits, ShipDockCases)
    select @PickBatchId, DestZone, count(distinct SKUId), sum(NumLines), sum(BPTCases),
           sum(BPTCaseUnits), sum(NumUnits), sum(ShippingDockCases)
      from DetailsByZone
      group by DestZone

  /* Get shipdock info here */
  select @vSDLines           = count(distinct OrderDetailId),
         @vSDSKUs            = count(distinct SKUId),
         @vSDCaseUnits       = sum((UnitsAuthorizedToShip / UnitsPerInnerpack) * UnitsPerInnerpack),
         @vSDUnits           = sum(UnitsAuthorizedToShip % UnitsPerInnerpack),
         @vSDCaseTotalUnits  = coalesce(@vSDUnits, 0) + coalesce(@vSDCaseUnits, 0)
  from @ttBatchedOrderDetails
  where ((coalesce(UnitsPerInnerPack, 0) > 0) and
         ((UnitsAuthorizedToShip / UnitsPerInnerpack) > 0));

  /* get values here  -Totals */
  select @vTotalUnits     = sum(NumUnits),
         @vTotalCases     = sum(NumCases) + sum(ShipDockCases),
         @vTotalCaseUnits = sum(NumCaseUnits) + @vSDCaseUnits,
         @vSDCases        = sum(ShipDockCases)
  from @ttBatchProcessDetails;

  /* insert SHIPDOCK cases data into temp table here */
  insert into @ttBatchProcessDetails(PickBatchId, DestZone, NumSKUs, NumLines, NumCases, NumCaseUnits, NumUnits)
    select @PickBatchId, 'SHIPDOCK', @vSDSKUs, @vSDLines, @vSDCases, @vSDCaseUnits, 0;

  /* Insert values into total temp table here */
  insert into @ttTotalsSummary(Name, Value, Percentage)
        select '# Case Units',  @vTotalCaseUnits, ceiling((1.0 * @vTotalCaseUnits / @vBatchedUnits) * 100)
  union select '# Units',       @vTotalUnits, (@vTotalUnits * 100 / @vBatchedUnits)
  --union select '# Lines',  @vNumLines,    null
  --union select '# SKUs',   @vNumSKUs,     null

   /* if the action is confirm then we need to commit this transaction */
  if (@vOperation = 'PlanBatch')
    begin
      update OD
      set OD.DestZone     = TBOD.DestZone,
          OD.ModifiedDate = current_timestamp
      from OrderDetails OD
      join @ttBatchedOrderDetails TBOD on (TBOD.OrderDetailId = OD.OrderDetailId)

      /* get attributes from the input xml */
      select @vAvgUnitsPerOrder     = nullif(Record.Col.value('AvgUnitsPerOrder[1]', 'TInteger'), ''),
             @vUnitsPerLine         = nullif(Record.Col.value('UnitsPerLine[1]', 'TInteger'),  ''),
             @vNumSKUOrdersPerBatch = nullif(Record.Col.value('NumSKUOrdersPerBatch[1]', 'TInteger'), '')
      from @vInputXML.nodes('/ModifyPickBatches/Data') as Record(Col);

      /* Update Wave status */
      update Wave
      set Status       = 'B', /* Planned */
          WaveStatus   = 'B',
          ModifiedDate = current_timestamp
      where (WaveId = @vWaveId);

      /* Update pickBatch Attributes here */
      update PickBatchAttributes
      set AvgUnitsPerOrder     = @vAvgUnitsPerOrder,
          UnitsPerLine         = @vUnitsPerLine,
          NumSKUOrdersPerBatch = @vNumSKUOrdersPerBatch
      where (PickBatchId = @vWaveId);

      /* log Audit Trail after clicking on confirm button */
      exec pr_AuditTrail_Insert 'PickBatchPlanned', @UserId, @vModifiedDate, @PickBatchId = @vWaveId;
    end

  /* Build xml here */
  select @vxmlTotalsSummary =(select Name,
                                     coalesce(Value, 0) Value,
                                     coalesce(Percentage, 0) Percentage
                              from @ttTotalsSummary
                              FOR XML RAW('Summary'), TYPE, ELEMENTS XSINIL, ROOT('TotalSummary'))

  /* build details xml here */
  select @vxmlBatchProcessDetails = (select DestZone as Name,
                                            coalesce(NumSKUs,      0) as NumSKUs,
                                            coalesce(NumLines,     0) as NumLines,
                                            coalesce(NumCases,     0) as NumCases,
                                            coalesce(NumCaseUnits, 0) as NumCaseUnits,
                                            coalesce(NumUnits,     0) as NumUnits,
                                            coalesce(TotalUnits,   0) as TotalUnits
                                     from @ttBatchProcessDetails
                                     FOR XML RAW('Details'), TYPE, ELEMENTS XSINIL, ROOT('DetailSummary'))

  /* Consolidate multiple xmls */
  select @xmlResult =  '<BatchProcessSummary>' +
                        cast(coalesce(@vxmlBatchProcessDetails, '') as varchar(max)) +
                        cast(coalesce(@vxmlTotalsSummary, '') as  varchar(max)) +
                       '</BatchProcessSummary>';

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_PickBatch_PlanBatch */

Go
