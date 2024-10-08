/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2020/09/04  TK      pr_Device_Update: Bug Fix in initializing DeviceId (HA-1392)
  2020/07/07  NB      Added pr_Devices_GenerateId, changes to pr_Device_AddOrUpdate and pr_Device_Update to verify DeviceId exists(CIMSV3-1011)
  2018/08/12  AY      pr_Device_Update: Save current Picking response (OB2-542)
  2017/11/17  TD      pr_Device_AddOrUpdate, pr_Device_Update:Changes to update
  2014/08/14  PK      pr_Device_Update: Updating the Device with current operation.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Device_Update') is not null
  drop Procedure pr_Device_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_Device_Update: Update the response being sent to the user on the device.
   Sometimes we may need to know what we asked the user to do and so we save the
   response.
------------------------------------------------------------------------------*/
Create Procedure pr_Device_Update
  (@DeviceId         TDeviceId,
   @UserId           TUserId,
   @CurrentOperation TDescription,
   @CurrentResponse  varchar(max),
   @ProcId           TInteger = 0)
as
  declare @vDeviceId               TDeviceId,
          @vCurrentPickingResponse varchar(max),
          @vProcName               TName;
begin
  /* Build the device id */
  if (not exists(select DeviceId
                 from Devices
                 where (DeviceId = @DeviceId)))
    select @vDeviceId = @DeviceId + '@' + @UserId;
  else
    select @vDeviceId = @DeviceId;

  if (@ProcId <> 0) select @vProcName = Object_Name(@ProcId);

  if (@vProcName like 'pr_RFC_Picking%') or (@vProcName = 'pr_RFC_GetPickTicketInfo')
    set @vCurrentPickingResponse = @CurrentResponse;

  /* Update the device operations */
  update Devices
  set CurrentUserId          = @UserId,
      CurrentOperation       = @CurrentOperation,
      CurrentResponse        = @CurrentResponse,
      CurrentPickingResponse = @vCurrentPickingResponse,
      LastUsedDateTime       = current_timestamp
  where (DeviceId = @vDeviceId);
end /* pr_Device_Update */

Go
