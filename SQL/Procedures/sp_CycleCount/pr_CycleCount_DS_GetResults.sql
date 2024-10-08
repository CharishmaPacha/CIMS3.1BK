/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/17  AY      pr_CycleCount_DS_GetResults: Added AbsUnitsChange (HA-3093)
  2021/03/13  SK      pr_CycleCount_DS_GetResults: set absUnitsChange and save as Count1 (HA-2270)
  2021/03/11  AY      pr_CycleCount_DS_GetResults: set absPercentUnitsChange (HA-2247)
  2021/03/11  OK      pr_CycleCount_DS_GetResults: Changes to return LocationId as we are considering this in automated column UniqueId (HA-2248)
  2020/01/04  KBB     pr_CycleCount_DS_GetResults: Corrected the BusinessUnit (OB2-1331)
              KBB     pr_CycleCount_DS_GetResults :made changes to get TaskId  field data into XML (HA-1445)
  2020/09/01  AY/SK   pr_CycleCount_DS_GetResults: Converted pr_CycleCount_GetResults for V3 (CIMSV3-1026)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_DS_GetResults') is not null
  drop Procedure pr_CycleCount_DS_GetResults;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_DS_GetResults: Shows the results of the Cycle count summarized
   by Batch & Location. In CycleCountResults table, we have details of each LPN
   scanned or missed and this procedure summarizes all those details.
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_DS_GetResults
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  /* Input variables */
  declare  @BatchNo        TTaskBatchNo = null,
           @LocationType   TTypeCode    = null,
           @StartDate      TDateTime    = null,
           @EndDate        TDateTime    = null,
           @BusinessUnit   TBusinessUnit,
           @UserId         TUserId;

  declare  @ReturnCode     TInteger,
           @vMessageName   TMessageName,
           @CCRowCount     TCount,
           @vPickZone      TZoneId,
           @vTaskId        TRecordId,
           @vBatchNo       TTaskBatchNo,
           @vPutawayClass  TCategory,
           @vPrevLPNs      TCount,
           @vNumLPNs       TCount,
           @PrevNumSKUs    TCount,
           @NewNumSKus     TCount,
           @SKUVariance    TCount,
           @OldValue       TCount,
           @NewValue       TCount,
           @vStartDate     Date,
           @vEndDate       Date;

  declare @ttCycleCountVariance TCycleCountVariance;

begin
  select @ReturnCode   = 0,
         @vMessageName = null,
         @OldValue     = 0,
         @NewValue     = 0;

  select @BusinessUnit = BusinessUnit from BusinessUnits;

  select @vTaskId = Record.Col.value('TaskId[1]', 'TRecordId')
  from @xmlInput.nodes('/Root/Data') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ) );

  /* Get BatchNo of the task */
  select @BatchNo = BatchNo
  from Tasks
  where (TaskId = @vTaskId);

  /* Validations */
  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsInvalid';
  else
  if (@LocationType is not null) and
     (not exists(select *
                 from EntityTypes
                 where (Entity   = 'Location') and
                       (TypeCode = @LocationType) and
                       (Status   = 'A')))
    set @vMessageName  = 'LocationTypeDoesNotExist';
  else
  if (@BatchNo is not null) and
     (not exists(select *
                 from Tasks
                 where BatchNo = @BatchNo))
    set @vMessageName = 'BatchNoDoesNotExist';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Converting Datetime to date to return result based on selected dates */
  select @vStartDate = cast(convert(varchar, @StartDate, 101 /* mm/dd/yyyy */) as Date),
         @vEndDate   = cast(convert(varchar, @EndDate,   101 /* mm/dd/yyyy */) as Date);

  /* Theoretically % Change would be = Change / Original, but if original qty = 0, it would be infinite
     but for sake of computations, we are going to set it at 100% */
  insert into @ttCycleCountVariance (
           BatchNo, TaskId, TaskDetailId, Transactiondate, TransactionTime,
           LocationId, Location, LocationType, LocationTypeDesc, StorageTypeDesc, PickZone, BusinessUnit, Warehouse,
           PreviousUnits, NewUnits, AbsUnitsChange, PercentUnitsChange, UnitsAccuracy,
           PrevLPNS, NumLPNs, PreviousNumSKUs, NewNumSKUs, PercentSKUsChange, SKUsAccuracy, OldValue, NewValue,
           PrevInnerPacks, NewInnerPacks, InnerPacksChange, PercentIPChange, IPAccuracy, vwCCR_UDF3, RecordId)
    select Min(CR.BatchNo), Min(CR.TaskId), Min(CR.TaskDetailId), cast(convert(varchar, Min(CR.CreatedDate),   101 /* mm/dd/yyyy */) as DateTime), Min(CR.CreatedDate),
           Min(LocationId), CR.Location, CR.LocationType, CR.LocationTypeDesc, CR.StorageTypeDesc, CR.PickZone, CR.BusinessUnit, CR.Warehouse,
           sum(coalesce(CR.PrevQuantity, 0)), sum(CR.FinalQuantity), sum(CR.AbsQuantityChange),
           /* PercentUnitsChange */
           Case
             when sum(CR.PrevQuantity) > 0 then
               cast ((((convert(float, sum(CR.FinalQuantity)) - convert(float, sum(CR.PrevQuantity))) / convert(float, sum(CR.PrevQuantity))) * 100) as  Decimal(15,2))
             /* If Location dont have any Qty before and found inventory during CC then consider it as 100% */
             when sum(CR.PrevQuantity) = 0 and sum(CR.FinalQuantity) > 0 then
               cast (100 as Decimal(10,2))
             when sum(CR.PrevQuantity) = 0 and sum(CR.FinalQuantity) = 0 then
               cast (0 as Decimal(10,2))
             else
               null
           end,
           /* UnitsAccuracy */
           Case
             when sum(CR.PrevQuantity) > 0 then
               cast ((100 - ABS((((convert(float, sum(CR.FinalQuantity)) - convert(float, sum(CR.PrevQuantity))) / convert(float, sum(CR.PrevQuantity))) * 100)))  as  Decimal(15,2))
             /* If PrevQuantity and NewQuantity both are zero then consider this as a 100 percent */
             when (sum(CR.PrevQuantity) = 0) and (sum(CR.FinalQuantity) = 0) then
               cast(100 as decimal(5,2))
             /* if any of the PrevQuantity or NewQuantity is zero then consider this as zero percent */
             when (sum(CR.PrevQuantity) = 0) or (sum(CR.FinalQuantity) = 0) then
               cast(0 as decimal(5,2))
             else
               null
           end,
           sum(CR.PrevLPNs), sum(CR.NumLPNs),
           sum(CR.OldSKUCount),     /* PreviousNumSKUs */
           sum(CR.CurrentSKUCount), /* NewNumSKUs      */
           /* PercentSKUsChange */
           Case
             when sum(CR.OldSKUCount) > 0 then
               cast ((((convert(float, sum(CR.CurrentSKUCount)) - convert(float, sum(CR.OldSKUCount))) / convert(float, sum(CR.OldSKUCount))) * 100) as  Decimal(15,2))
             /* If SKU is not exists in Location earlier and found during CC then consider this as 100 percent */
             when sum(CR.OldSKUCount) = 0 and sum(CR.CurrentSKUCount) > 0 then
               cast(100 as decimal(5,2))
             when sum(CR.OldSKUCount) = 0 and sum(CR.CurrentSKUCount) = 0 then
               cast(0 as decimal(5,2))
             else
               null
           end,
           /* SKUsAccuracy */
           Case
             when sum(CR.OldSKUCount) > 0 then
               cast ((100 - ABS((((convert(float, sum(CR.CurrentSKUCount)) - convert(float, sum(CR.OldSKUCount))) / convert(float, sum(CR.OldSKUCount))) * 100)))  as  Decimal(15,2))
             when (sum(CR.OldSKUCount) = 0) and (sum(CR.CurrentSKUCount) = 0) then
               cast(100 as decimal(5,2))
             when (sum(CR.OldSKUCount) = 0) or (sum(CR.CurrentSKUCount) = 0) then
               cast(0 as decimal(5,2))
             else
               null
           end,
           convert(integer, sum(coalesce(CR.PrevQuantity, 0) * UnitCost)),
           convert(integer,sum(CR.FinalQuantity * UnitCost)),
           sum(CR.PrevInnerPacks),sum(CR.FinalInnerPacks),sum(CR.InnerPacksChange),
           /* PercentIPsChange */
           Case
             when sum(CR.PrevInnerPacks) > 0 then
               cast ((((convert(float, sum(CR.FinalInnerPacks)) - convert(float, sum(CR.PrevInnerPacks))) / convert(float, sum(CR.PrevInnerPacks))) * 100) as  Decimal(15,2))
             when sum(CR.PrevInnerPacks) = 0 and sum(CR.FinalInnerPacks) > 0 then
               cast(100 as decimal(5,2))
             when sum(CR.PrevInnerPacks) = 0 and sum(CR.FinalInnerPacks) = 0 then
               cast(0 as decimal(5,2))
             else
               null
           end,
           /* IPsAccuracy */
           Case
             when sum(CR.PrevInnerPacks) > 0 then
               cast ((100 - ABS((((convert(float, sum(CR.FinalInnerPacks)) - convert(float, sum(CR.PrevInnerPacks))) / convert(float, sum(CR.PrevInnerPacks))) * 100)))  as  Decimal(15,2))
             when (sum(CR.PrevInnerPacks) = 0) and (sum(CR.FinalInnerPacks) = 0) then
               cast(100 as decimal(5,2))
             when (sum(CR.PrevInnerPacks) = 0) or (sum(CR.FinalInnerPacks) = 0) then
               cast(0 as decimal(5,2))
             else
               null
           end,
           CR.CreatedBy,
           row_number() over(order by CR.BatchNo, CR.Location)
    from vwCycleCountResults CR
    where (CR.TransactionDate between coalesce(@vStartDate, TransactionDate) and coalesce(@vEndDate, TransactionDate)) and
          (CR.BusinessUnit = @BusinessUnit) and
          (CR.LocationType = coalesce(@LocationType, CR.LocationType)) and
          (CR.BatchNo      = coalesce(@BatchNo,      CR.BatchNo))
    group by CR.BatchNo, CR.Location, CR.LocationType, CR.LocationTypeDesc, CR.StorageTypeDesc, CR.PickZone, CR.CreatedBy, CR.BusinessUnit, CR.Warehouse;

  update @ttCycleCountVariance
  set absPercentUnitsChange = abs(PercentUnitsChange),
      Count1                = abs(UnitsChange);

  /* Return the results */
  insert into #ResultDataSet
    select * from @ttCycleCountVariance;

ErrorHandler:
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_CycleCount_DS_GetResults */

Go
