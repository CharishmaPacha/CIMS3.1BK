/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/03  MS      pr_Prod_MainProcess, pr_Prod_ProcessATRecord,
                      pr_Prod_ProcessUserActivity, pr_Prod_DS_GetUserProductivity: Changes to insert WH into Productivity table (BK-807)
  2021/07/09  SK      pr_Prod_DS_GetUserProductivity: New procedure (HA-2972)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Prod_DS_GetUserProductivity') is not null
  drop Procedure pr_Prod_DS_GetUserProductivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Prod_DS_GetUserProductivity: Shows the result set summarized by user assignment
  based on the input data sent by the user.

  By default, shows the result set for the past month until now.
------------------------------------------------------------------------------*/
Create Procedure pr_Prod_DS_GetUserProductivity
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  /* Input variables */
  declare  @OperationType  TTypeCode    = null,
           @StartDate      TDateTime    = null,
           @EndDate        TDateTime    = null,
           @SummarizeBy    TString      = null,
           @WaveType       TTypeCode    = null,
           @Warehouse      TWarehouse   = null,
           @BusinessUnit   TBusinessUnit,
           @UserId         TUserId,
           @Mode           TFlags;

  declare  @ReturnCode     TInteger,
           @vMessageName   TMessageName,
           @vValue1        TDescription,
           @vCurrentDate   TDate,
           @vStartDate     TDate,
           @vEndDate       TDate,
           @vNoDaysFrom    TInteger,
           @vOperation     TOperation,
           @vXMLData       TXML,
           @vResult        TResult,
           @vSQL           TSQL;

  declare @ttProdIDs       TEntityKeysTable;
begin
  select @ReturnCode   = 0,
         @vMessageName = null,
         @vSQL         = '';

  select @BusinessUnit = BusinessUnit from BusinessUnits;

  select @vCurrentDate = current_timestamp;

  select @OperationType = Record.Col.value('Operation[1]',     'TTypeCode'),
         @StartDate     = Record.Col.value('StartDateTime[1]', 'TDate'),
         @EndDate       = Record.Col.value('EndDateTime[1]',   'TDate'),
         @SummarizeBy   = Record.Col.value('SummarizeBy[1]',   'TString'),
         @WaveType      = Record.Col.value('WaveType[1]',      'TTypeCode'),
         @Warehouse     = Record.Col.value('Warehouse[1]',     'TWarehouse'),
         @UserId        = Record.Col.value('UserId[1]',        'TUserId'),
         @Mode          = Record.Col.value('Mode[1]',          'TFlags')
  from @xmlInput.nodes('/Root/Data') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* Validations */
  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsInvalid';

  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1;

  /* Temporary tables */
  select * into #ttProdIds from @ttProdIds;
  select * into #ProductivityDS from vwProductivity where (1 = 2); /* build table based on the structure of view */
  alter table #ProductivityDS alter column Duration varchar(8);

  /* Drop not null constraints on the temporary table
     Since summary fields may or may not necessarily populate these fields
     For e.g. ProductivityId field */
  exec pr_Table_DropNullConstraints '#ProductivityDS';

  /* Set dates if not given */
  if (coalesce(@StartDate, '') = '')
    begin
      select @vNoDaysFrom = dbo.fn_Controls_GetAsInteger('Productivity', 'NoDaysFrom', 30, @BusinessUnit, @UserId);

      select @vStartDate = dateadd(dd, -@vNoDaysFrom, @vCurrentDate);
    end
  else
    select @vStartDate = @StartDate;

  if (coalesce(@EndDate, '') = '')
    select @vEndDate = @vCurrentDate;
  else
    select @vEndDate = @EndDate;

  /* Get operation description */
  select @vOperation  = dbo.fn_LookUps_GetDesc('Operation', @OperationType, @BusinessUnit, null /* DescField */),
         @SummarizeBy = case when @SummarizeBy = '' then 'None' else @SummarizeBy end,
         @WaveType    = nullif(@WaveType, ''),
         @Warehouse   = nullif(@Warehouse, ''),
         @Mode        = coalesce(nullif(@Mode, ''), 'R' /* Result */);

  /* Get productivity data for the time period specified & the operation chosen by User */
  insert into #ttProdIds (EntityId)
    select ProductivityId
    from Productivity
    where (ActivityDate >= @vStartDate) and
          (ActivityDate <= @vEndDate) and
          (Operation = @vOperation) and
          (WaveType = coalesce(@WaveType, WaveType)) and
          (Warehouse = coalesce(@Warehouse, Warehouse))
    order by ProductivityId;

  /* Rules input xml for data set processing */
  select @vXMLData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Operation',     @vOperation)   +
                            dbo.fn_XMLNode('SummarizeBy',   @SummarizeBy)  +
                            dbo.fn_XMLNode('Warehouse',     @Warehouse)    +
                            dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',        @UserId));

  /* Summarize appropriately as requested by client */
  exec pr_RuleSets_ExecuteRules 'Productivity_DataSet', @vXMLData;

  /* Final updates */
  exec pr_RuleSets_ExecuteRules 'Productivity_DataSetUpdates', @vXMLData;

  /* Return the results */
  if (@Mode <> 'V' /* View */)
    insert into #ResultDataSet (ProductivityId, Operation, SubOperation, JobCode, Assignment, ActivityDate,
                                NumAssignments, NumWaves, NumOrders, NumLocations, NumPallets, NumLPNs, NumTasks, NumPicks, NumSKUs, NumUnits,
                                Weight, Volume, EntityType, EntityId, EntityKey,
                                SKUId, SKU, LPNId, LPN, LocationId, Location, PalletId, Pallet, ReceiptId, ReceiptNumber, ReceiverId, ReceiverNumber,
                                OrderId, PickTicket, WaveNo, WaveId, WaveType, WaveTypeDesc, TaskId, TaskDetailId,
                                DayNumber, Day, DayMonth, WeekNumber, Week, MonthWeek, MonthNumber, MonthShort, Month, Year,
                                StartDateTime, EndDateTime, Duration, DurationInSecs, DurationInMins, DurationInHrs,
                                UnitsPerMin, UnitsPerHr, Comment, Status, Archived, DeviceId, UserId, UserName,
                                ParentRecordId, BusinessUnit, Warehouse, Ownership, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy)
      select ProductivityId, Operation, SubOperation, JobCode, Assignment, ActivityDate,
             NumAssignments, NumWaves, NumOrders, NumLocations, NumPallets, NumLPNs, NumTasks, NumPicks, NumSKUs, NumUnits,
             Weight, Volume, EntityType, EntityId, EntityKey,
             SKUId, SKU, LPNId, LPN, LocationId, Location, PalletId, Pallet, ReceiptId, ReceiptNumber, ReceiverId, ReceiverNumber,
             OrderId, PickTicket, WaveNo, WaveId, WaveType, WaveTypeDesc, TaskId, TaskDetailId,
             DayNumber, Day, DayMonth, WeekNumber, Week, MonthWeek, MonthNumber, MonthShort, Month, Year,
             StartDateTime, EndDateTime, Duration, DurationInSecs, DurationInMins, DurationInHrs,
             UnitsPerMin, UnitsPerHr, Comment, Status, Archived, DeviceId, UserId, UserName,
             ParentRecordId, BusinessUnit, Warehouse, Ownership, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy
      from #ProductivityDS;
  /* return the data set as view */
  else
    select ProductivityId, Operation, SubOperation, JobCode, Assignment, ActivityDate,
           NumAssignments, NumWaves, NumOrders, NumLocations, NumPallets, NumLPNs, NumTasks, NumPicks, NumSKUs, NumUnits,
           Weight, Volume, EntityType, EntityId, EntityKey,
           SKUId, SKU, LPNId, LPN, LocationId, Location, PalletId, Pallet, ReceiptId, ReceiptNumber, ReceiverId, ReceiverNumber,
           OrderId, PickTicket, WaveNo, WaveId, WaveType, WaveTypeDesc, TaskId, TaskDetailId,
           DayNumber, Day, DayMonth, WeekNumber, Week, MonthWeek, MonthNumber, MonthShort, Month, Year,
           StartDateTime, EndDateTime, Duration, DurationInSecs, DurationInMins, DurationInHrs,
           UnitsPerMin, UnitsPerHr, Comment, Status, Archived, DeviceId, UserId, UserName,
           ParentRecordId, BusinessUnit, Warehouse, Ownership, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy
    from #ProductivityDS;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Prod_DS_GetUserProductivity */

Go
