/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_GetFieldCaption') is not null
  drop Function fn_AMF_GetFieldCaption;
Go
/*------------------------------------------------------------------------------
  fn_AMF_GetFieldCaption:

  Returns the Caption for the given Field, CultureName and BusinessUnit
------------------------------------------------------------------------------*/
Create Function fn_AMF_GetFieldCaption
  (@FieldName      TName,
   @CultureName    TName,
   @BusinessUnit   TBusinessUnit)
---------------------
   Returns  TName
as
begin /* fn_AMF_GetFieldCaption */
  declare @vFieldCaption    TName,
          @vDefaultCaption  TName;

  /* Read the culturename specific caption from Fields */
  select @vFieldCaption = Caption
  from Fields
  where (FieldName    = @FieldName   ) and
        (CultureName  = @CultureName ) and
        (BusinessUnit = @BusinessUnit);

  /* If there is no entry for the culturename specific field, then fetch the default from standard set */
  if (@vFieldCaption is null)
    begin
      select @vDefaultCaption = Caption
      from Fields
      where (FieldName    = @FieldName   ) and
            (CultureName  = 'en-US'      ) and
            (BusinessUnit = @BusinessUnit);
    end

  return coalesce(@vFieldCaption, @vDefaultCaption, @FieldName);
end /* fn_AMF_GetFieldCaption */

Go

