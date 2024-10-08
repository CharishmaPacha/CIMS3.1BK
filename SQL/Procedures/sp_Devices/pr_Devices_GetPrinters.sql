/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/22  RT      pr_Devices_GetPrinters: Validate with respect to the empty and null values (FB-1628)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Devices_GetPrinters') is not null
  drop Procedure pr_Devices_GetPrinters;
Go
/*------------------------------------------------------------------------------
  Proc pr_Devices_GetPrinters: Returns all printers associated with
     the Entity Type, Make and chosen label format. When user selects a label
     format, we would present the list of printers to be able to print that
     format to and this procedure returns all of those printers.
------------------------------------------------------------------------------*/
Create Procedure pr_Devices_GetPrinters
  (@EntityType      TEntity, /* LPN */
   @PrinterMake     TMake,
   @LabelFormatName TName
  )
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription;

begin /* pr_PrintService_GetPrinters */
  select @ReturnCode        = 0,
         @Messagename       = null,
         @PrinterMake       = nullif(@PrinterMake, ''),
         @LabelFormatName   = nullif(@LabelFormatName, '');

  /* Validations */

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get all the Printers that can be used for printing the specific label format.
     Note that a Generic printer could be used for printing all labels i.e. like
     a PDF writer

     If no parameter passed just return all active printers
     Validate with respect to the empty and null values through parameters
  */
  if (@EntityType is null) and
     (@PrinterMake is null) and
     (@LabelFormatName is null)
    begin
      select Printers.*
      from Devices Printers
      where ((Printers.Status     = 'A' /* Active */) and
             (Printers.DeviceType = 'Printer'))
      order by SortSeq;
    end
  else
    begin
      select Printers.*
      from Devices Printers
        left join LabelFormats LF on (Printers.Make  = LF.PrinterMake) or
                                     (LF.PrinterMake = 'Generic'     )
      where ((((LF.EntityType       = @EntityType     ) or (@EntityType is null)) and
              ((Printers.Make       = @PrinterMake    ) or (@PrinterMake is null)) and
              ((LF.LabelFormatName  = @LabelFormatName) or (@LabelFormatName is null)) or
               (Printers.Make       = 'Generic'))  and
               (Printers.Status     = 'A' /* Active */) and
               (Printers.DeviceType = 'Printer'))
      order by SortSeq;
    end

   /* How could EntityType or PrinterMake or LabelFormat be null? AY */
ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Devices_GetPrinters */

Go
