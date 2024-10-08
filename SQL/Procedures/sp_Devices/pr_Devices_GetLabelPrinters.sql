/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_GetLabelPrinters') is not null
  drop Procedure pr_Devices_GetLabelPrinters;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_GetLabelPrinters : Returns all Devices where DeviceType = LabelPrinter.
    Returns XML as a Result with all Devices table Columns
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_GetLabelPrinters
  (@Warehouse     TWarehouse  = null,
   @BusinessUnit  TWarehouse  = null,
   ----------------------------------
   @xmlResult     TXML        output )
as
  declare @ReturnCode   TInteger,
          @MessageName  TMessageName,
          @Message      TDescription;
begin /* pr_Devices_GetLabelPrinters */
  select @ReturnCode   = 0,
         @Messagename  = null;

  /* Validations */

  if (@MessageName is not null)
    goto ErrorHandler;

  exec @ReturnCode = pr_Devices_GetDevices 'LabelPrinter', @Warehouse, @BusinessUnit, @xmlResult output;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));

end /* pr_Devices_GetLabelPrinters */

Go
