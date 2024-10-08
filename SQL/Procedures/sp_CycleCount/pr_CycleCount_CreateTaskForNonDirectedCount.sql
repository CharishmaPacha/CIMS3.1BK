/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/04  SK      pr_CycleCount_CreateTaskForNonDirectedCount: Pass on the default process control value during non directed CC (HA-1841)
  2018/06/06  AY      pr_CycleCount_CreateTaskForNonDirectedCount: New procedure (S2G-217)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_CreateTaskForNonDirectedCount') is not null
  drop Procedure pr_CycleCount_CreateTaskForNonDirectedCount;
Go
/*------------------------------------------------------------------------------
  Proc pr_CycleCount_CreateTaskForNonDirectedCount:
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_CreateTaskForNonDirectedCount
  (@LocationId       TRecordId,
   @Location         TLocation,
   @PickZone         TZoneId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @TaskId           TRecordId output,
   @TaskDetailId     TRecordId output,
   @CountDetail      TTypeCode output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vDefaultProcess    TControlValue,
          @vSubTaskType       TFlags,
          @vCCOptionsXML      TXML,
          @vLocationXML       TXML,
          @vLocationInfo      varchar(max);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vSubTaskType    = 'N' /* Non-Directed */,
         @vDefaultProcess = dbo.fn_Controls_GetAsString('CycleCount', 'DefaultProcess', 'CC' /* Cycle Counting */,
                                                        @BusinessUnit, @UserId);

  set @vCCOptionsXML = (select @vSubTaskType    as SubTaskType,
                               @vDefaultProcess as CCProcess
                        FOR XML PATH('OPTIONS'));

  set @vLocationXML = (select @LocationId   as LocationId,
                              @Location     as Location,
                              @PickZone     as PickZone
                              FOR XML PATH('LOCATIONINFO'));

  select @vLocationInfo  = '<CYCLECOUNTTASKS>'  +
                              @vCCOptionsXML  +
                              @vLocationXML   +
                           '</CYCLECOUNTTASKS>'

  exec pr_CycleCount_CreateTasks @vLocationInfo,
                                 @BusinessUnit,
                                 @UserId,
                                 @FirstTaskId = @TaskId output;

   /* get the count level on the taskdetail */
   select @TaskDetailId = TaskDetailId,
          @CountDetail  = RequestedCCLevel
   from TaskDetails
   where (TaskId     = @TaskId) and
         (LocationId = @LocationId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_CycleCount_CreateTaskForNonDirectedCount */

Go
