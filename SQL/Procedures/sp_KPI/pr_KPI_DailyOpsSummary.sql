/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_DailyOpsSummary') is not null
  drop Procedure pr_KPI_DailyOpsSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_DailyOpsSummary: Summarize the operational activity for the given
    day and operation
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_DailyOpsSummary
  (@ActivityDate       TDate,
   @Operation          TOperation = 'ALL',
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vXMLRulesData          TXML;

  declare @ttActivity             TInputParams;
begin /* pr_KPI_DailyOpsSummary */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @ActivityDate = coalesce(@ActivityDate, cast(current_timestamp as date));

  if (@Operation in ('Receiving', 'ALL'))
    exec pr_KPI_ReceiversClosed_Daily @ActivityDate, @BusinessUnit, @UserId;

  if (@Operation in ('Putaway', 'ALL'))
    begin
      delete from @ttActivity;
      insert into @ttActivity (ParamValue)
        values ('PutawayLPNToLocation'),
               ('PutawayLPNToPicklane'),
               ('PutawayPallet'),
               ('LPNMovedToLocation'),
               ('PalletMovedToLocation'),
               ('LPNContentsXferedToPicklane');

      exec pr_KPI_PutawayActivity @ActivityDate, 'Putaway', @ttActivity, @BusinessUnit, @UserId;
    end

  if (@Operation in ('Picking', 'ALL'))
    exec pr_KPI_PickingActivity @ActivityDate, @BusinessUnit, @UserId;

  if (@Operation in ('Reservation', 'ALL'))
    exec pr_KPI_SummarizeATActivity_ByWaveType @ActivityDate, 'Reservation', 'LPNPick', @BusinessUnit, @UserId;

  if (@Operation in ('Activation', 'ALL'))
    exec pr_KPI_SummarizeATActivity_ByWaveType @ActivityDate, 'Activation', 'Activation', @BusinessUnit, @UserId;

  if (@Operation in ('Loading', 'ALL'))
    begin
      delete from @ttActivity;
      insert into @ttActivity (ParamValue) values('ScanLoadPallet'), ('ScanLoadLPN');
      exec pr_KPI_SummarizeATActivity @ActivityDate, 'Loading', @ttActivity, @BusinessUnit, @UserId;
    end

  if (@Operation in ('ShippedTransfers', 'ALL'))
    begin
      delete from @ttActivity;
      insert into @ttActivity (ParamValue) values('LPNShipped');
      exec pr_KPI_ShippedTransfers @ActivityDate, @ttActivity, @BusinessUnit, @UserId;
    end

  if (@Operation in ('ReceivedTransfers', 'ALL'))
    begin
      delete from @ttActivity;
      insert into @ttActivity (ParamValue)
        values ('LPNMovedToLocation'),
               ('PalletMovedToLocation'),
               ('LPNContentsXferedToPicklane');

      exec pr_KPI_ReceivedTransfers @ActivityDate, @ttActivity, @BusinessUnit, @UserId;
    end

  if (@Operation in ('Cycle Counting', 'ALL'))
    exec pr_KPI_CycleCountActivity @ActivityDate, @BusinessUnit, @UserId;

  /* Build rules data to finalize KPIs */
  select @vXMLRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('ActivityDate', @ActivityDate) +
                            dbo.fn_XMLNode('Operation',    @Operation) +
                            dbo.fn_XMLNode('KPIClass',     'DailyOpsSummary') +
                            dbo.fn_XMLNode('BusinessUnit', @BusinessUnit));

  /* Invoke proc to execute rules */
  exec pr_RuleSets_ExecuteRules 'KPIs_Finalize', @vXMLRulesData;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_DailyOpsSummary */

Go
