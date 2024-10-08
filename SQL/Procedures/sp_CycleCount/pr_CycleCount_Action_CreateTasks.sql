/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/17  SK      pr_CycleCount_Action_CreateTasks, pr_CycleCount_CreateTasks: Added new field mapping to create tasks with RequestedCClevel (HA-1567)
                      pr_CycleCount_Action_CreateTasks: Added new proc to create CC Tasks
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_Action_CreateTasks') is not null
  drop Procedure pr_CycleCount_Action_CreateTasks;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_Action_CreateTasks: Procedure to Create CC Tasks
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_Action_CreateTasks
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML    = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vRecordId          TRecordId,

          @vCCLevel           TFlag,
          @vCCProcess         TOperation,
          @vPriority          TPriority,
          @vScheduledDate     TDateTime,
          @vLocationsxml      xml,
          @vxmlInput          Txml;

begin /* pr_CycleCount_Action_CreateTasks */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null;

  /* Get the form inputs */
  select @vPriority      = Record.Col.value('Priority[1]',      'TPriority'),
         @vScheduledDate = Record.Col.value('ScheduledDate[1]', 'TDateTime'),
         @vCCLevel       = Record.Col.value('CCLevel[1]',       'TFlag'),
         @vCCProcess     = Record.Col.value('CCProcess[1]',     'TOperation')
  from @xmlData.nodes('/Root/Data') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* User may be selecting Locations - but could be including SKUs, so get the distinct locations */
  select distinct dbo.fn_SubstringUptoNthSeparator(EntityKey, '-', 1) LocationId
  into #SelectedLocations
  from #ttSelectedEntities;

  /* Build Location xml */
  select @vLocationsxml = (select L.Location, L.LocationId
                           from #SelectedLocations SL
                              join Locations L on (SL.LocationId = L.LocationId)
                           for XML PATH('LOCATIONINFO'));

  /* Build xml */
  set @vxmlInput = dbo.fn_XMLNode('CYCLECOUNTTASKS',
                     dbo.fn_XMLNode('OPTIONS',
                       dbo.fn_XMLNode('Priority',       @vPriority) +
                       dbo.fn_XMLNode('ScheduledDate',  @vScheduledDate) +
                       dbo.fn_XMLNode('SubTaskType',    @vCCLevel) +
                       dbo.fn_XMLNode('CCProcess',      @vCCProcess)) +
                     cast(@vLocationsxml as varchar(max)));

  exec @vReturnCode = pr_CycleCount_CreateTasks @vxmlInput,
                                                @BusinessUnit,
                                                @UserId,
                                                null,
                                                null,
                                                null,
                                                @vMessage output;

  /* Insert the messages information to display in V3 application */
  insert into #ResultMessages (MessageType, MessageText)
    select 'I' /* Info */, @vMessage;

  return(coalesce(@vReturnCode, 0));
end /* pr_CycleCount_Action_CreateTasks */

Go
