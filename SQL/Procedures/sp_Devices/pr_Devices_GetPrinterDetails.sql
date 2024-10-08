/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_GetPrinterDetails') is not null
  drop Procedure pr_Devices_GetPrinterDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_GetPrinterDetails: Returns all printers associated with
     the Entity Type
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_GetPrinterDetails
  (@PrinterName       TDeviceId = null,
   @LabelFormatName   TName     = null,
   @DeviceId          TDeviceId = null
  )
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription,
          @vPrintSize          varchar(50);

begin /* pr_Devices_GetPrinterDetails */
  select @ReturnCode   = 0,
         @Messagename  = null;

  /* Validations */

  if (@MessageName is not null)
    goto ErrorHandler;

  /* If Printer Name is not given, identify it using the LabelFormat and Device */
  if (@PrinterName is null)
    begin
      select @vPrintSize = labelformats.PrintOptions.value('(/printoptions/printsize)[1]','varchar(50)')
      from LabelFormats
      where LabelFormatName = @LabelFormatName;

      select top 1 @PrinterName = MappedPrinterId
      from vwDevicePrinters
      where (StockSize          = @vPrintSize) and
            ((PrintRequestSource = @DeviceId ) or
             (PrintRequestSource = '*'       ))
      order by SortSeq;
    end

  select
    DeviceId,
    DeviceType,
    SerialNo,
    Make,
    Model,
    SourcedFrom,
    PurchaseDate,
    Status,
    WarrantyStart,
    WarrantyExpiry,
    WarrantyReferenceNo,
    LastServiced,
    AssignedToDept,
    AssignedToUser,
    Warehouse,

    Configuration,

    CurrentUserId,
    CurrentOperation,
    CurrentResponse
  from Devices
  where ( DeviceId = @PrinterName );

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Devices_GetPrinterDetails */

Go
