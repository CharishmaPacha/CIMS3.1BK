/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_GetDevices') is not null
  drop Procedure pr_Devices_GetDevices;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_GetDevices : Returns all Devices of device type.
    Returns XML as a Result with all Devices table Columns
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_GetDevices
  (@DeviceType    TLookUpCode = null,
   @Warehouse     TWarehouse  = null,
   @BusinessUnit  TWarehouse  = null,
   ----------------------------------
   @xmlResult     TXML        output )
as
  declare @ReturnCode   TInteger,
          @MessageName  TMessageName,
          @Message      TDescription;
begin /* pr_Devices_GetDevices */
  select @ReturnCode   = 0,
         @Messagename  = null;

  /* Validations */

  if (@MessageName is not null)
    goto ErrorHandler;

  set @xmlResult = convert(varchar(MAX),(select *
                                          from Devices
                                          where (((DeviceType = @DeviceType) or (@DeviceType is null)) and
                                                 ((Warehouse  = @Warehouse)  or (@Warehouse is null)) and
                                                 ((BusinessUnit = @BusinessUnit)))
                                          FOR XML RAW('DEVICESINFO'), TYPE, ELEMENTS XSINIL, ROOT('DEVICESDETAILS')));

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Devices_GetDevices */

Go
