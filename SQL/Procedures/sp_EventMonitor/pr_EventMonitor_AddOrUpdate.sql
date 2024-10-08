/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/05/27  RV      pr_EventMonitor_AddOrUpdate: Get message subject, body and DB profile Name from controls.
  2015/04/06  NB      pr_EventMonitor_AddOrUpdate: Enhanced to return the EventId
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EventMonitor_AddOrUpdate') is not null
  drop Procedure pr_EventMonitor_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_EventMonitor_AddOrUpdate:
    Procedure handles inserting or updating the EventMonitor with new event info
      or updating an existing event details

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
      <Name>AlertInterval</Name>
      <Value>10</Value>
    </ParamInfo>
    <ParamInfo>
      <Name>EventDetails</Name>
      <Value>TEST INSTANCE DE</Value>
    </ParamInfo>
    <ParamInfo>
      <Name>BusinessUnit</Name>
      <Value>SRI</Value>
    </ParamInfo>
  </InputParams>

  The above XML will insert a new Event as below

  EventType-EventName-AlertInterval-EventDetails         -BusinessUnit
  'JOB'     'DEEUN'    10           TEST INSTANCE DE      SRI
------------------------------------------------------------------------------*/
Create Procedure pr_EventMonitor_AddOrUpdate
  (@EventDetails TXML,
   @EventId      TRecordId output)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vEventId        TRecordId,
          @vEventType      TEntity,
          @vEventName      TName,
          @vBusinessUnit   TBusinessUnit,
          @vAlertInterval  TInteger,
          @vEventDetails   TVarchar;

  declare @vInputParams  TInputParams;
begin /* pr_EventMonitor_AddOrUpdate */

  select @vReturnCode   = 0,
          @vMessageName = null;

  /* read the values for parameters */
  insert into @vInputParams
    select * from dbo.fn_GetInputParams(@EventDetails);

  /* Initialize param variables */
  select @vEventType    = null,
         @vEventName    = null,
         @vBusinessUnit = null;

   /* read param variables */
  select @vEventType     = case when ParamName = 'EVENTTYPE'     then ParamValue else @vEventType     end,
         @vEventName     = case when ParamName = 'EVENTNAME'     then ParamValue else @vEventName     end,
         @vBusinessUnit  = case when ParamName = 'BUSINESSUNIT'  then ParamValue else @vBusinessUnit  end,
         @vAlertInterval = case when ParamName = 'ALERTINTERVAL' then ParamValue else @vAlertInterval end,
         @vEventDetails  = case when ParamName = 'EVENTDETAILS'  then ParamValue else @vEventDetails  end
  from @vInputParams;

  if (coalesce (@vEventType, '') = '' )
    set @vMessageName = 'EventMonitor_EventTypeIsNull';
  else
  if (coalesce (@vEventName, '') = '' )
    set @vMessageName = 'EventMonitor_EventNameIsNull';
  else
  if (coalesce (@vBusinessUnit, '') = '' )
    set @vMessageName = 'EventMonitor_BusinessUnitIsNull';

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vEventId = null;
  select @vEventId = RecordId
  from EventMonitor
  where (EventType    = @vEventType   ) and
        (EventName    = @vEventName   ) and
        (BusinessUnit = @vBusinessUnit);

  /* The event exists, therefore update the last run at field with current time stamp */
  if (@vEventId is not null)
    begin
      update EventMonitor
      set AlertInterval = @vAlertInterval,
          EventDetails  = @vEventDetails
      where (RecordId = @vEventId);
    end
  else
    begin
      insert into EventMonitor(EventType, EventName, AlertInterval, EventDetails, BusinessUnit)
        select @vEventType, @vEventName, @vAlertInterval, @vEventDetails, @vBusinessUnit;

      select @vEventId = RecordId
      from EventMonitor
      where (EventType    = @vEventType   ) and
            (EventName    = @vEventName   ) and
            (BusinessUnit = @vBusinessUnit);
    end

  select @EventId = @vEventId;
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_EventMonitor_AddOrUpdate */

Go
