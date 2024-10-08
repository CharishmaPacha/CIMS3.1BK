/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/07  NB      Added pr_Devices_GenerateId, changes to pr_Device_AddOrUpdate and pr_Device_Update to verify DeviceId exists(CIMSV3-1011)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_GenerateId') is not null
  drop Procedure pr_Devices_GenerateId;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_GenerateId:

  procedure generates a new device id and inserts the device into Device tables
  returns the newly generated deviceid
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_GenerateId
  (@DeviceType       TLookUpCode,
   @UserId           TUserId,
   @BusinessUnit     TBusinessUnit,
   @DeviceId         TDeviceId output)
as
  declare @vMessageName     TMessageName,
          @vDeviceCategory  TCategory;
begin /* pr_Devices_GenerateId */

  /* Control Category for NextSeqNo is Devices_<DeviceType>*/
  select @vDeviceCategory = 'Devices_' + @DeviceType;
  exec pr_Controls_GetNextSeqNoStr @vDeviceCategory, 1, @UserId, @BusinessUnit,
                                   @DeviceId output;

  /*  Add Device Record for Generated Device Id */
  insert into Devices (DeviceId,   DeviceName, DeviceType,   BusinessUnit)
                select @DeviceId,  @DeviceId,  @DeviceType,  @BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;
end /* pr_Devices_GenerateId */

Go
