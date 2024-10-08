/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/13  RT      pr_Tasks_GetHeaderLabelData: Removed the millisec in date to adjust in the label (BK-534)
  2020/12/23  AJM     pr_Tasks_GetHeaderLabelData: Added ScheduledDate, AssignedTo (HA-1802)
  2020/07/27  AY      pr_Tasks_GetHeaderLabelData: Added ShipToName (HA-1224)
  2020/06/12  AJM     pr_Tasks_GetHeaderLabelData : Included new fields NumLocations , NumDestinatons (HA-634)
  2020/05/28  RV      pr_Tasks_GetHeaderLabelData: Temp fix to replace new line special characters with semicolon to avoid xml conversion issues (HA-667)
  2020/02/04  PHK     pr_Tasks_GetHeaderLabelData: Made changes to show the Cart/Tote count (CID-1296)
  2020/01/22  AY      pr_Tasks_GetHeaderLabelData: Code optimizations
  2019/08/21  AY      pr_Tasks_GetHeaderLabelData/pr_Tasks_GetLabelsToPrint: Set LabelPrinted flag on printing instead of when data is shown to user (CID-976)
  2019/08/19  AJ      pr_Tasks_GetHeaderLabelData: Made changes to update LabelsPrinted flag, PrintedDateTime and
  2019/06/08  AY      pr_Tasks_GetHeaderLabelData: Added NumPicks in dataset (CID-209)
              AY      pr_Tasks_GetHeaderLabelData: Revamp & optimize (CID-329)
  2019/06/03  MS      pr_Tasks_GetHeaderLabelData: Migrated changes from OB Prod & Madec changes to print ReplenishType (CID-329)
  2019/05/23  PHK     pr_Tasks_GetHeaderLabelData: Added Priority field to diaplay the Priority value in the header labels(CID-406)
  2019/05/21  KSK     pr_Tasks_GetHeaderLabelData:Made changes to print the NumLPNs count for taskheader Label (CID-329)
  2019/05/02  PHK     pr_Tasks_GetHeaderLabelData: Added NumLPNs(CID-329)
  2019/01/21  OK      pr_Tasks_GetHeaderLabelData: Changes to exclude cancelled picks from task (HPI-2344)
  2018/12/11  PHK     pr_Tasks_GetHeaderLabelData: Added CartType to print on Task Header Label (HPI-2233)
  2018/11/19  MS      pr_Tasks_GetHeaderLabelData:Made changes to return the required data to Task_4x6HeaderLabel_SingleLine, Added Warehouse field to be displayed on the label (OB2-742)
  2018/11/18  AY      pr_Tasks_GetHeaderLabelData: Performance improvements
  2018/11/13  VM      pr_Tasks_GetHeaderLabelData: Return NumOrders as OrderCount on wave when it is Bulk order (OB2-704)
  2018/10/15  YJ      Do not migrated: pr_Tasks_GetHeaderLabelData: Added PickTicket, SalesOrder, Comments, CustPO to dataset: Migrated from Prod (S2GCA-98)
  2018/08/03  AY/RT   pr_Tasks_GetHeaderLabelData: Made changes to return the required data to Task_4x6HeaderLabel, Added required fields to be displayed on the label (OB2-394)
  2017/12/28  RV      pr_Tasks_GetHeaderLabelData:TaskCategory5 update code moved to tasks recount to update the before print labels
  2016/10/26  PSK     pr_Tasks_GetHeaderLabelData: Changes made to print Created date.(HPI-937)
  2016/09/19  PSK     pr_Tasks_GetHeaderLabelData: Migrated from Production & added "PicksFor" (HPI-709)
  2016/09/15  PSK     pr_Tasks_GetHeaderLabelData: Added Picksfrom to the data set (HPI-666)
  2016/08/27  PSK     pr_Tasks_GetHeaderLabelData: Changes made to print the Account Name. (HPI-523)
  2016/08/18  PK      pr_Tasks_GetHeaderLabelData: Returning TaskCategory5 (PROD) to print on the TaskHeader label.
  2016/07/20  TK      pr_Tasks_GetHeaderLabelData: Changes return Order count (HPI-334)
  2015/08/04  TK      pr_Tasks_GetHeaderLabelData: Generalised code for all kind of Waves
  2015/07/03  TK      pr_Tasks_GetHeaderLabelData: Initial Revision (ACME-210)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_GetHeaderLabelData') is not null
  drop Procedure pr_Tasks_GetHeaderLabelData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_GetHeaderLabelData: Returns data set for the Task Header Label
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_GetHeaderLabelData
  (@TaskId  TRecordId)
as
  declare @vRecordId         TRecordId,
          @vNumCases         TInteger,
          @vReplenishType    Tvarchar,
          @vCartonsToDisplay TVarchar,
          @vIsTaskAllocated  TFlags,
          @vOrderId          TRecordId,
          @vNumTempLabels    TCount,
          @vAccountName      TName,
          @vWaveType         TTypeCode,
          @vWaveId           TRecordId,
          @vWaveNo           TWaveNo,
          @vOrigWaveNo       TWaveNo,
          @vWaveNumOrders    TCount;

  declare @ttCartontypes table
    (RecordId        TRecordId    identity(1,1),
     NumCartons      TInteger,
     CartonType      TCartonType,
     CartonTypeDesc  char(20));

begin /* pr_Tasks_GetHeaderLabelData */
  SET NOCOUNT ON;
  set ANSI_WARNINGS ON;

  select @vRecordId         = 0,
         @vCartonsToDisplay = '';

  /* Get the Task info */
  select @vWaveType        = BatchType,
         @vWaveId          = WaveId,
         @vWaveNo          = BatchNo,
         @vOrigWaveNo      = BatchNo, -- This is normally the same as the WaveNo, except for Replenishments
         @vIsTaskAllocated = IsTaskAllocated,
         @vOrderId         = OrderId,
         @vNumTempLabels   = NumTempLabels
  from vwTasks
  where (TaskId = @TaskId);

  /* Update LabelsPrinted to confirm that the Labels are printed and PrintedDateTime to show the time it was printed */
  update Tasks
  set LabelsPrinted   = 'Y' /* Labels Printed */,
      PrintedDateTime = coalesce(nullif(PrintedDateTime, ''), current_timestamp)
  where TaskId = @TaskId;

  /* If the task has temp labels generated, then get the carton types */
  if (@vNumTempLabels > 0)
    begin
      /* Get the distinct CartonTypes generated in the order of SortSeq */
      insert into @ttCartonTypes (NumCartons, CartonType, CartonTypeDesc)
        select count(distinct TempLabel) NumLPNs, CT.CartonType, min(CT.Description)
        from TaskDetails TD
          left outer join LPNs L on (L.LPNId = TD.TempLabelId)
          left outer join CartonTypes CT on (L.CartonType = CT.CartonType)
        where (TD.TaskId = @TaskId) and (TD.Status <> 'X')
        group by CT.CartonType, CT.SortSeq
        order by CT.SortSeq;

      /* Pad to 20 so that the NumCartons are all aligned. Add #13#10 so that each one shows
         on a new line like below on the label
         15AM       - 1
         3AM        - 1
         Note: New line characters (\&) having issue while converting to xml, for temp fix replaced with semi colon (;)
      */
      select @vCartonsToDisplay = @vCartonstoDisplay + CartonTypeDesc + ' ' + cast(NumCartons as varchar) + '\& '
      from @ttCartontypes;
    end

  select @vNumCases = sum(GPI.Cases)
  from LPNs L
    cross apply dbo.fn_LPNs_GetPackedInfo(L.LPNId, 'Task_HeaderLabelInfo' /* Operation */, 'L' /* L - LPN (Option) */) GPI
  where (L.TaskId = @TaskId);

  /* If Replenish wave, then get from original wave */
  if (@vWaveType in ('RU', 'RP'))
    select @vOrigWaveNo = left(@vWaveNo, 9); -- assuming the wave no format will not change.

  /* Get Wave info */
  select @vAccountName   = AccountName,
         @vWaveNumOrders = NumOrders
  from Waves
  where (WaveNo = @vOrigWaveNo);

  /* To return the replenish type of the task */
  select @vReplenishType = OH.OrderCategory1
  from OrderHeaders OH
  where (OH.OrderId = @vOrderId);

  /* Return the dataset for Label */
  with TaskDtlSummary as
  (
    select @TaskId TaskId, Min(TD.UDF1) TD_UDF1, Min(TD.UDF2) TD_UDF2, count(distinct(TD.PickPosition)) PickPositions,
           case when count(distinct OH.CustomerName) = 1    then Min(OH.CustomerName)    else 'Multiple' end CustomerName,
           case when count(distinct OH.CustPO) = 1          then Min(OH.CustPO)          else 'Multiple' end CustPO,
           case when count(distinct OH.ShipToId) = 1        then Min(OH.ShipToId)        else 'Multiple' end ShipToId,
           case when count(distinct OH.ShipToName) = 1      then Min(OH.ShipToName)      else 'Multiple' end ShipToName,
           case when count(distinct OH.ShipToState) = 1     then Min(OH.ShipToState)     else 'Multiple' end ShipToState,
           case when count(distinct OH.ShipToCountry) = 1   then Min(OH.ShipToCountry)   else 'Multiple' end ShipToCountry,
           case when count(distinct OH.ShipVia) = 1         then Min(OH.ShipVia)         else 'Multiple' end ShipVia,
           case when count(distinct OH.OrderCategory1) = 1  then Min(OH.OrderCategory1)  else 'Multiple' end OrderCategory1,
           case when count(distinct OH.OrderCategory2) = 1  then Min(OH.OrderCategory2)  else 'Multiple' end OrderCategory2,
           case when count(distinct OH.OrderCategory3) = 1  then Min(OH.OrderCategory3)  else 'Multiple' end OrderCategory3,
           case when count(distinct OH.OrderCategory4) = 1  then Min(OH.OrderCategory4)  else 'Multiple' end OrderCategory4,
           case when count(distinct OH.OrderCategory5) = 1  then Min(OH.OrderCategory5)  else 'Multiple' end OrderCategory5,
           case when count(distinct OH.AccountName) = 1     then Min(OH.AccountName)     else 'Multiple' end AccountName,
           case when count(distinct OH.DesiredShipDate) = 1 then cast(Min(OH.DesiredShipDate) as varchar(11))
                                                                                         else 'Multiple' end DesiredShipDate,
           case when count(distinct OH.CancelDate) = 1      then cast(Min(OH.CancelDate) as varchar(11))
                                                                                         else 'Multiple' end CancelDate,
           case when count(distinct OH.OrderTypeDescription) = 1
                                                            then Min(OH.OrderTypeDescription)
                                                                                         else 'Multiple' end OrderType,
           case when count(distinct OH.Warehouse) = 1       then Min(OH.Warehouse)       else 'Multiple' end Warehouse
    from TaskDetails TD join vwOrderHeaders OH on TD.OrderId = OH.OrderId
    where (TD.TaskId = @TaskId) and (TD.Status <> 'X')
  )
  select T.TaskId,
         case when dbo.fn_Pickbatch_IsBulkBatch(@vWaveId) ='Y' then @vWaveNumOrders
              else T.NumOrders
         end                          NumOrders,
         T.NumLPNs                    NumLPNs,
         T.NumLPNs                    LPNs, -- deprecated, but it may be used in old Labels
         @vNumCases                   NumCases,
         T.NumTempLabels              NumTempLabels,
         T.NumLocations               NumLocations,
         T.NumDestinatons             NumDestinatons,
         TDS.PickPositions            NumTotes,
         T.TotalInnerPacks            InnerPacks,
         T.TotalUnits                 Quantity,
         T.DetailCount                NumPicks,
         T.BatchNo                    WaveNo,
         T.BatchType                  WaveType,
         T.BatchTypeDesc              WaveTypeDesc,
         T.ScheduledDate              ScheduledDate,
         T.AssignedTo                 AssignedTo,
         T.BatchNo                    BatchNo,       -- deprecated, but it may be used on old labels
         T.BatchTypeDesc              BatchTypeDesc, -- deprecated, but it may be used on old labels, so retain
         T.CartType                   CartType,
         T.PickZone                   PickZone,
         PZ.ZoneDesc                  PickZoneDesc,
         T.PickZones                  PickZones,
         T.DestZone                   DestZone,
         T.TaskCategory5              TaskCategory5,
         @vCartonsToDisplay           CartonTypesList,
         coalesce(@vAccountName, T.AccountName, TDS.AccountName)
                                      AccountName,
         T.TaskSubType                TaskSubType,
         T.TaskSubTypeDescription     TaskSubTypeDesc,
         T.PicksFrom                  PicksFrom,
         T.PicksFor                   PicksFor,
         T.StartLocation              StartLocation,
         T.EndLocation                EndLocation,
         T.StartDestination           StartDestination,
         T.EndDestination             EndDestination,
         @vReplenishType              ReplenishType,
         coalesce(T.PickTicket, 'Multiple')  PickTicket,
         coalesce(T.SalesOrder, 'Multiple')  SalesOrder,
         TDS.TD_UDF1                  Comments,          /* S2GCA Specific - OH.Comments */
         --TDS.TD_UDF2                  CustPO,          /* S2GCA Specific - OH.CustPO */
         TDS.CustomerName,
         TDS.CustPO,
         TDS.ShipToId,
         TDS.ShipToName,
         TDS.ShipToState,
         TDS.ShipToCountry,
         TDS.ShipVia,
         TDS.OrderCategory1,
         TDS.OrderCategory2,
         TDS.OrderCategory3,
         TDS.OrderCategory4,
         TDS.OrderCategory5,
         TDS.DesiredShipDate,
         TDS.CancelDate,
         TDS.OrderType,
         TDS.Warehouse,
         convert(varchar, T.CreatedDate, 0)   CreatedDate,
         T.Priority                   Priority,
         convert(varchar, getdate(), 0)       PrintTime
  from TaskDtlSummary TDS
    join vwTasks                   T  on (TDS.TaskId = T.TaskId  ) -- using view here to avoid retrieving all variables from Tasks above
    left outer join vwPickingZones PZ on (T.PickZone = PZ.ZoneId )
  where (T.TaskId = @TaskId)

end /* pr_Tasks_GetHeaderLabelData */

Go
