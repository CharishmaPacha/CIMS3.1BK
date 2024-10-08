/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_SubstituteCaptions') is not null
  drop Function fn_AMF_SubstituteCaptions;
Go
/*------------------------------------------------------------------------------
  fn_AMF_SubstituteCaptions:

  Iterates through all place holders for FieldCaptions in the given Text, replaces
  the place holders with their respective field captions or default captions
------------------------------------------------------------------------------*/
Create Function fn_AMF_SubstituteCaptions
  (@Text         TVarChar,
   @CultureName  TName,
   @BusinessUnit TBusinessUnit)
---------------------
   Returns  TVarChar
as
begin /* fn_AMF_SubstituteCaptions */
  declare @vText                 TVarChar,
          @vFieldName            TVarChar,
          @vFieldCaption         TVarChar,
          @vPlaceHolderString    TVarChar,
          @vPlaceHolderStartPos  TInteger,
          @vPlaceHolderEndPos    TInteger,
          @vFieldNameLength      TInteger;

  select @vText = @Text;                   /* Assigning the input value to a local variable */
  while (charindex('[FIELDCAPTION_', @vText) > 0)
    begin
      /* Fetching Starting index and length of the place holder */
      select @vPlaceHolderStartPos = charindex('[FIELDCAPTION_', @vText) + 1,
             @vPlaceHolderEndPos   = charindex(']', @vText, @vPlaceHolderStartPos),
             @vPlaceHolderString   = substring(@vText, @vPlaceHolderStartPos - 1 /* include the start char */, (@vPlaceHolderEndPos - @vPlaceHolderStartPos + 2 /* include the start and end chars */)),
             @vFieldNameLength     = @vPlaceHolderEndPos-@vPlaceHolderStartPos - 13 /* length of FIELDCAPTION_ literal */;
      if (@vFieldNameLength > 0)
        begin
                  /* Get the field name  */
          select @vFieldName = substring(@vText, @vPlaceHolderStartPos + 13 , @vFieldNameLength);
          select @vFieldCaption = dbo.fn_AMF_GetFieldCaption(@vFieldName, @CultureName, @BusinessUnit);
          select @vFieldCaption = coalesce(@vFieldCaption, @vFieldName);
          select @vText = replace(@vText, @vPlaceHolderString, @vFieldCaption);
        end
      else
        begin
          /* no field name was found in the place holder. replace the place holder with a blank string, to continue to the next one */
          select @vText = replace(@vText, @vPlaceHolderString, '');
        end
    end

ExitHandler:
  return (@vText);
end /* fn_AMF_SubstituteCaptions */

Go

