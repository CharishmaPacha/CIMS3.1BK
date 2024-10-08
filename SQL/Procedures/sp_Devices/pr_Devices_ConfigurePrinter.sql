/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_ConfigurePrinter') is not null
  drop Procedure pr_Devices_ConfigurePrinter;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_ConfigurePrinter:  This proc will update the given printer to the
        given device Id.
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_ConfigurePrinter
  (@DeviceId       TDeviceId,
   @PrinterId      TDeviceId,
   @UserId         TUserId,
   @Warehouse      TWarehouse,
   @BusinessUnit   TBusinessUnit)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,
          /*  Printer Details info..*/
          @vDeviceType       TLookUpCode,
          @vUpdateDeviceType TLookUpCode;
begin  /* pr_Devices_ConfigurePrinter */
   select @ReturnCode        = 0,
          @Messagename       = null,
          @vUpdateDeviceType = null;

  /* Validations here ...*/
  if (coalesce(@BusinessUnit, '') = '')
   set @MessageName = 'BusinessUnitCannotbeNull';
  else
  if (coalesce(@DeviceId, '') = '')
    set @MessageName = 'DeviceIdCannotbeNull';
  else
  if (coalesce(@PrinterId, '') = '')
    set @MessageName = 'PrinterIdCannotbeNull';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get Device Type Here..*/
  select @vDeviceType = DeviceType
  from Devices
  where (DeviceId = @PrinterId);

  select @vUpdateDeviceType  =  case
                                  when @vDeviceType = 'LabelPrinter'    then
                                    'Label'
                                  when @vDeviceType = 'DocumentPrinter' then
                                    'Document'
                                  when upper(@vDeviceType) = 'PRINTER'  then
                                    'List'
                                  else
                                    'Label'
                                end

  /* Need to do validations if any...in future...*/
  if (exists (select *
              from DevicePrinterMapping
              where (PrintRequestSource = @DeviceId)))
    begin
       /* Update Printer , PrinterType here..*/
       update DevicePrinterMapping
       set MappedPrinterId  = @PrinterId,
           PrintType        = @vUpdateDeviceType,
           ModifiedDate     = current_timestamp,
           ModifiedBy       = coalesce(@UserId, @DeviceId)
       where (PrintRequestSource = @DeviceId);
    end
  else
    begin
       insert into DevicePrinterMapping (PrintRequestSource, MappedPrinterId, PrintType,          BusinessUnit)
                                 select  @DeviceId,          @PrinterId,      @vUpdateDeviceType, @BusinessUnit;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end /* pr_Devices_ConfigurePrinter */

Go
