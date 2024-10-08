/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LabelFormats_GetDetailsByName') is not null
  drop Procedure pr_LabelFormats_GetDetailsByName;
Go
/*------------------------------------------------------------------------------
  Proc pr_LabelFormats_GetDetailsByName: Returns all the info associated with the
    label format in order to print label.
------------------------------------------------------------------------------*/
Create Procedure pr_LabelFormats_GetDetailsByName
  (@LabelFormatName   TName)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription;

begin /* pr_LabelFormats_GetDetailsByName */
  select @ReturnCode   = 0,
         @Messagename  = null;

  /* Validations */
  /* Check if the Label Format exists */
  if not exists(select RecordId
                from LabelFormats
                where (LabelFormatName = @LabelFormatName))
    set @MessageName = 'LabelFormatNotFound'

  if (@MessageName is not null)
    goto ErrorHandler;

 /*select @vPrinterType = vPrinterType
  from LabelFormats
  where ((EntityType = @EntityType) and
         (LabelFormatDesc = @LabelFormatDesc));

  select @vPrinterShareName = vPrinterShareName
  from PrintersWorkStationMapping PWSM
    left join Printers P on PWSM.PrinterName = P.PrinterName
  where ((PWSM.CleintIP    = @ClientIP) and
         (PWSM.PrinterType = @vPrinterType))

  if (@vPrinterShareName  is null)
     select @vPrinterShareName = vPrinterShareName
     from PrintersWorkStationMapping PWSM
       left join Printers P on PWSM.PrinterName = P.PrinterName
  where ((PWSM.CleintIP    is null) and
         (PWSM.PrinterType = @vPrinterType))
  */

  /* Uniqueness on the table is EntityType, LabelFormatName and BusinessUnit, so
     we need all these params to actually return the right data - AY */
  select RecordId,
         EntityType,
         LabelFormatName
         LabelFormatDesc,
         LabelFileName,
         PrintOptions,
         PrinterMake,
         Status,
         SortSeq,
         BusinessUnit,
         CreatedDate,
         ModifiedDate,
         CreatedBy,
         ModifiedBy
  from LabelFormats
  where (LabelFormatName = @LabelFormatName);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LabelFormats_GetDetailsByName */

Go
