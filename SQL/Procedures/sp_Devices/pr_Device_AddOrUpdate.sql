/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2020/07/07  NB      Added pr_Devices_GenerateId, changes to pr_Device_AddOrUpdate and pr_Device_Update to verify DeviceId exists(CIMSV3-1011)
  2020/04/06  RT      pr_Device_AddOrUpdate: Included Defualt Printer to update (HA-81)
  2020/04/01  VM      pr_Device_AddOrUpdate: Keep the existing values if they are passed as null when updating (HA-79)
  2017/11/17  TD      pr_Device_AddOrUpdate, pr_Device_Update:Changes to update
  2012/07/10  PK      Added pr_Device_AddOrUpdate.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Device_AddOrUpdate') is not null
  drop Procedure pr_Device_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Device_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_Device_AddOrUpdate
  (@DeviceId         TDeviceId,
   @DeviceType       TLookUpCode,
   @UserId           TUserId,
   @Warehouse        TWarehouseId,
   @Printer          TName,
   @BusinessUnit     TBusinessUnit,
   @CurrentOperation TDescription)
as
  declare @DeviceLienceCount  TCount,
          @DeviceCount        TCount,
          @MessageName        TMessageName,
          @vDeviceId          TDeviceId,
          @vLastLoginDateTime TDateTime;

begin
  /* DeviceIds passed from the Devices may not be unique, hence we are
     using DeviceId + UserId */
  if (not exists(select DeviceId
                 from Devices
                 where (DeviceId = @DeviceId) and (BusinessUnit = @BusinessUnit)))
    select @vDeviceId = @DeviceId + '@' + @UserId;

  select @vLastLoginDateTime = case when @CurrentOperation = 'RFLogin' then current_timestamp else null end;

  /* If the device does not exists in devices table then insert the device details into
     devices table with the warehosue as well or else update the device Warehouse */
  if (not exists(select *
                 from Devices
                 where (DeviceId = @vDeviceId) and (BusinessUnit = @BusinessUnit)))
    begin
      insert into Devices (DeviceId, DeviceName, DeviceType, CurrentUserId, Warehouse, DefaultPrinter, CurrentOperation, BusinessUnit,
                           LastLoginDateTime)
        select @vDeviceId, @vDeviceId, @DeviceType, @UserId, @Warehouse, @Printer, @CurrentOperation, @BusinessUnit,
               @vLastLoginDateTime;
    end
  else
    begin
      update Devices
      set CurrentUserId     = coalesce(@UserId, CurrentUserId),
          Warehouse         = coalesce(@Warehouse, Warehouse),
          DefaultPrinter    = coalesce(@Printer, DefaultPrinter),
          CurrentOperation  = coalesce(@CurrentOperation, CurrentOperation),
          LastLogInDateTime = coalesce(@vLastLoginDateTime, LastLoginDateTime)
      where (DeviceId     = @vDeviceId) and
            (BusinessUnit = @BusinessUnit);
    end

ErrorHandler:
  if (@MessageName is not null)
    exec pr_Messages_ErrorHandler @MessageName;
end /* pr_Device_AddOrUpdate */

Go
