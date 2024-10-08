/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/08  TK      pr_ActivityLog_LPN: Changes to log LPN info only (S2G-1346)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ActivityLog_LPN') is not null
  drop Procedure pr_ActivityLog_LPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_ActivityLog_LPN: To Log LPN related details of given operation
  ------------------------------------------------------------------------------*/
Create Procedure pr_ActivityLog_LPN
  (@Operation      TDescription,
   @LPNId          TRecordId,
   @Message        TDescription,
   @ProcId         TInteger      = 0,
   @DeviceId       TDeviceId     = null,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = 'CIMS',
   @ActivityLogId  TRecordId     = null output)
as
  declare @vLPN         TLPN,
          @vxmlData     TXML,
          @ReturnCode   TInteger,
          @MessageName  TMessageName;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  select @vLPN         = LPN,
         @BusinessUnit = coalesce(@BusinessUnit, BusinessUnit)
  from LPNs
  where LPNId = @LPNId;

  if (@Operation like '%_LPN_%')
    begin
      /* Log LPN information */
      select @vxmlData = (select *
                          from LPNs
                          where (LPNId = @LPNId)
                          for XML raw('LPNINFO'), elements );

      /* insert into activitylog details */
      exec pr_ActivityLog_AddMessage @Operation, @LPNId, @vLPN, 'LPN',
                                     @Message, @ProcId, @vxmlData, @BusinessUnit, @UserId, null, null, null, null, null,
                                     null, @ActivityLogId output;
    end
  else
  if (@Operation like '%_LPNDetails_%')
    begin
      /* Log LPN Details - HPI-GoLive */
      select @vxmlData = (select *
                          from LPNDetails
                          where (LPNId = @LPNId)
                          order by OnhandStatus
                          for XML raw('LPNDETAILS'), elements );

      /* insert into activitylog details */
      exec pr_ActivityLog_AddMessage @Operation, @LPNId, @vLPN, 'LPN',
                                     @Message, @ProcId, @vxmlData, @BusinessUnit, @UserId, null, null, null, null, null,
                                     null, @ActivityLogId output;
    end
  else
  if (@Operation like '%_TaskDetails_%')
    begin
      /* Log LPN Tasks - HPI-GoLive */
      set @vxmlData = (select *
                       from TaskDetails
                       where (LPNId = @LPNId)
                       order by TaskDetailId
                       for XML raw('TASKDETAILS'), elements );

      /* insert into activitylog details */
      exec pr_ActivityLog_AddMessage @Operation, @LPNId, @vLPN, 'LPN',
                                     @Message, @ProcId, @vxmlData, @BusinessUnit, @UserId, null, null, null, null, null,
                                     null, @ActivityLogId output;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ActivityLog_LPN */

Go
