/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/31  VS      pr_Alerts_AllocationStatistics: Get the values based on ShowaboveXSeconds in Allocation Statistics alert (HA-2477)
  2021/03/25  VS      pr_Alerts_AllocationStatistics: Do not get operation null records (HA-2426)
  2020/10/30  VS      pr_Alerts_AllocationStatistics: Used generic pivot proc to get the pivot data (cIMSV3-1143)
  2020/10/15  VS      pr_Alerts_AllocationStatistics: Made changes to get the columns dynamically for Statistics (cIMSV3-1037)
  2018/11/20  VS      pr_Alerts_AllocationStatistics: To give Allocation and other Operation time statistics for each day by using Logs (S2GCA-404).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_AllocationStatistics') is not null
  drop Procedure pr_Alerts_AllocationStatistics;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_AllocationStatistics:
  It returns the Wave Allocation Statistics for each wave in the given period

  Period = 0 - means today, 30 means last 30 days.

  Usability:

  ** To run daily after business hours to alert on waves that took more than 60 seconds to allocate
  exec pr_Alerts_AllocationStatistics 'WaveAllocation', 0, 60, 'HA', 'cimsadmin'

  ** To run on last day of month, to alert on waves that took more than 60 seconds to allocate
  exec pr_Alerts_AllocationStatistics 'WaveAllocation', 30, 60, 'HA', 'cimsadmin'

------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_AllocationStatistics
  (@Operation          TDescription,
   @PeriodDays         TInteger,
   @ShowaboveXSeconds  TInteger,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReturnDataSet      TFlags    = 'N',
   @EmailIfNoAlert     TFlags    = 'N')
as
  declare @cols               TVarChar,
          @query              TVarChar,
          @TotalTime          TNVarChar,
          @vStartDate         TDate,
          @vEndDate           TDate,

          @vXML               TVarchar,
          @vSubject           TDescription,
          @vBody              TVarchar,
          @vEmailId           TControlValue,
          @vProfileName       TName,
          @vFieldList         TVarchar,
          @vFieldCaptions     TVarchar,
          @vOptions           xml,
          @vAlertCategory     TCategory,
          @vTable             TVarchar;

begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vEndDate       = getdate();
  select @vStartDate     = dateadd(day, -1 * @PeriodDays, @vEndDate);
  select @vAlertCategory = 'Alert_' + @Operation;

  /* Insert the log details into temp table */
  select AL.EntityKey Wave, AL.Operation, datediff_big(second,isnull(AL.StartTime,0),isnull(AL.EndTime,0)) Duration,
         AL.Message SubOperation, W.WaveType WaveType, W.NumOrders, W.NumSKUs, W.NumUnits
  into #ActivityLog
  from CurrActivityLog AL with (nolock)
    join Waves W          with (nolock) on (W.WaveNo = AL.EntityKey) and (W.BusinessUnit = @BusinessUnit)
  where (Operation = @Operation) and (coalesce(AL.Message,'') <> '') and
        (ActivityDate between @vStartDate and @vEndDate);

  if not exists(select * from #ActivityLog) return;

  /* Create the table to hold the pivot results */
  create table #AllocationStatistics (RecordId int identity);

  /* To pivot the data we can provide options and in this case we want to show the
     total time taken as the first aggregate column and Sum the Duration in all the
     columns i.e. for each operation */
  set @vOptions = '<Root>
                    <TotalColumnPosition>Start</TotalColumnPosition>
                    <AggregateOperation>Sum</AggregateOperation>
                  </Root>'

  /* Get the Total time for each operation */
  exec pr_Misc_PivotTable '#ActivityLog', '#AllocationStatistics', 'SubOperation', 'SubOperation', 'Duration', null, @vOptions;

  select top 50 * into #FinalAllocationStatistics from #AllocationStatistics
  where GrandTotal > @ShowaboveXSeconds
  order by GrandTotal desc

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #FinalAllocationStatistics;
      return(0);
    end

  /* Send email if there is data to report */
  if (@EmailIfNoAlert = 'Y') or (exists(select * from #FinalAllocationStatistics))
    exec pr_Email_SendQueryResults @vAlertCategory, @TableName = '#FinalAllocationStatistics', @BusinessUnit =  @BusinessUnit;

end /* pr_Alerts_AllocationStatistics */

Go
