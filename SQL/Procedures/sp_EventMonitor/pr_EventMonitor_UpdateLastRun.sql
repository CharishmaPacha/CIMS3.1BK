/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/07  AY      pr_EventMonitor_UpdateLastRun: Bug fixes
  pr_EventMonitor_UpdateLastRun: Enhanced to add eventmonitor record
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EventMonitor_UpdateLastRun') is not null
  drop Procedure pr_EventMonitor_UpdateLastRun;
Go
/*------------------------------------------------------------------------------
  Proc pr_EventMonitor_UpdateLastRun:

  Procedure updates the last run at value for the given event

  Input XML format should match the following

  <InputParams>
    <ParamInfo>
      <Name></Name>
      <Value></Value>
    </ParamInfo>
  </InputParams>

  Ex:
  <InputParams>
    <ParamInfo>
      <Name>EventType</Name>
      <Value>JOB</Value>
    </ParamInfo>
    <ParamInfo>
      <Name>EventName</Name>
      <Value>DERUN</Value>
    </ParamInfo>
    <ParamInfo>
      <Name>BusinessUnit</Name>
      <Value>SRI</Value>
    </ParamInfo>
  </InputParams>

  The above XML will update the LastRunAt for below Event

  EventType-EventName-BusinessUnit
  'JOB'     'DEEUN'   SRI

------------------------------------------------------------------------------*/
Create Procedure pr_EventMonitor_UpdateLastRun
  (@EventDetails TXML)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vEventId        TRecordId,
          @vEventType      TEntity,
          @vEventName      TName,
          @vBusinessUnit   TBusinessUnit,
          @vAddEventDetails     TXML;

  declare @vInputParams  TInputParams;
begin /* pr_EventMonitor_UpdateLastRun */
  select @vReturnCode = 0;
  /* read the values for parameters */
  insert into @vInputParams
    select * from dbo.fn_GetInputParams(@EventDetails);

  /* Initialize param variables */
  select @vEventType    = null,
         @vEventName    = null,
         @vBusinessUnit = null,
         @vEventId      = null;

   /* read param variables */
  select @vEventType    = case when ParamName = 'EVENTTYPE'    then ParamValue else @vEventType    end,
         @vEventName    = case when ParamName = 'EVENTNAME'    then ParamValue else @vEventName    end,
         @vBusinessUnit = case when ParamName = 'BUSINESSUNIT' then ParamValue else @vBusinessUnit end
  from @vInputParams;

  /* There are instances where BusinessUnit may  not be sent from the caller
     For example : A Console application which has no access to DB or having no settings
     In such instances, take the first active BusinessUnit as the value */
  if (@vBusinessUnit is null)
    begin
      select Top 1 @vBusinessUnit = BusinessUnit
      from vwBusinessUnits;
    end

  /* Find the event to update */
  select @vEventId = RecordId
  from EventMonitor
  where (EventType    = @vEventType   ) and
        (EventName    = @vEventName   ) and
        (BusinessUnit = @vBusinessUnit);

  /* If the event doesn't exist, then add it based upon control var */
  if (@vEventId is null) and
     (dbo.fn_Controls_GetAsBoolean('EventMonitor', 'AutoAdd',  'Y' /* Yes */,  @vBusinessUnit, null /* UserId */) = 'Y' /* Yes */)
    begin
      select @vAddEventDetails = '<InputParams>' +
                                    '<ParamInfo>' +
                                      '<Name>EventType</Name>' +
                                      '<Value>' + @vEventType + '</Value>' +
                                    '</ParamInfo>' +
                                    '<ParamInfo>' +
                                      '<Name>EventName</Name>' +
                                      '<Value>'+ @vEventName + '</Value>' +
                                    '</ParamInfo>'+
                                    '<ParamInfo>'+
                                      '<Name>AlertInterval</Name>'+
                                      '<Value>60</Value>'+
                                    '</ParamInfo>'+
                                    '<ParamInfo>'+
                                      '<Name>EventDetails</Name>'+
                                      '<Value>AUTO ADDED EVENT</Value>'+
                                    '</ParamInfo>'+
                                    '<ParamInfo>'+
                                      '<Name>BusinessUnit</Name>'+
                                      '<Value>' + @vBusinessUnit + '</Value>'+
                                    '</ParamInfo>'+
                                  '</InputParams>';

      exec pr_EventMonitor_AddOrUpdate @vAddEventDetails,
                                       @vEventId output;

      /* set alert message with the event type and name */
    end

  if (@vEventId is null)
    begin
      set @vMessageName = 'NoEventWithGivenTypeName';
      goto ErrorHandler;
    end

  /* Update last run time */
  update EventMonitor
  set LastRunAt = current_timestamp
  where (RecordId = @vEventId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_EventMonitor_UpdateLastRun */

Go
