/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LabelFormats_GetAllByEntityType') is not null
  drop Procedure pr_LabelFormats_GetAllByEntityType;
Go
/*------------------------------------------------------------------------------
  Proc pr_LabelFormats_GetAllByEntityType: Returns all label formats associated with
     the Entity Type
------------------------------------------------------------------------------*/
Create Procedure pr_LabelFormats_GetAllByEntityType
  (@EntityType        TEntity /* LPN */)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription;

begin /* pr_LabelFormats_GetAllByEntityType */
  select @ReturnCode   = 0,
         @Messagename  = null;

  /* Validations */

  if (@MessageName is not null)
    goto ErrorHandler;

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
  where (EntityType = @EntityType); -- need to add businessunit as well.

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LabelFormats_GetAllByEntityType */

Go
