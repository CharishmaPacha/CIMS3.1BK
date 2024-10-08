/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/28  RT      pr_Devices_GetConfiguredPrinter: Changes to use Printers instead of Devices (HA-683)
  2019/08/02  AY      pr_Devices_GetConfiguredPrinter: Added (CID-884)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_GetConfiguredPrinter') is not null
  drop Procedure pr_Devices_GetConfiguredPrinter;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_GetConfiguredPrinter : Returns the printer configured for
    the given workstation
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_GetConfiguredPrinter
  (@WorkStation   TName       = null,
   @vOperation    TOperation  = null,
   @BusinessUnit  TWarehouse  = null,
   ----------------------------------
   @PrinterName   TName        output )
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription,
          @vPrinter      TName,
          @vUserId       TUserId;

begin /* pr_Devices_GetDevices */
  select @vReturnCode   = 0,
         @vMessagename  = null;

 /* Get configured printer for the given workstation */
 if (coalesce(@WorkStation, '') <> '')
   begin
     select @vPrinter = MappedPrinterId
     from DevicePrinterMapping DPM
       left outer join vwPrinters P on (P.PrinterName   = DPM.MappedPrinterId)
     where (DPM.PrintRequestSource = @WorkStation);
   end

  /* If there is no configured printer then get the default printer */
  if (coalesce(@vPrinter, '') = '')
    select @vPrinter = dbo.fn_Controls_GetAsString(@vOperation, 'DefaultPrinter', '', @BusinessUnit, @vUserId);

  /* If we still do not have a valid printer, then get the first available printer */
  if (not exists(select * from vwPrinters where PrinterName = @vPrinter and Status = 'A'))
    select top 1 @vPrinter = PrinterName
    from vwPrinters
    where (BusinessUnit = @BusinessUnit) and
          (Status       = 'A' /* Active */)
    order by SortSeq;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Devices_GetConfiguredPrinter */

Go
