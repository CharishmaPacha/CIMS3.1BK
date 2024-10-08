/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/16  NB      Added fn_AMF_SubstituteFormAttributes(CIMSV3-773)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_SubstituteFormAttributes') is not null
  drop Function fn_AMF_SubstituteFormAttributes;
Go
/*------------------------------------------------------------------------------
  fn_AMF_SubstituteFormAttributes:

  Iterates through all form attributes for FORMATTR in the given form's HTML, replaces
  the attribute place holders with their respective attribute values or defaults
------------------------------------------------------------------------------*/
Create Function fn_AMF_SubstituteFormAttributes
  (@FormName         TVarChar,
   @FormAttributes   TAMFFormAttributes READONLY,
   @DeviceCategory   TName,
   @BusinessUnit     TBusinessUnit)
---------------------
   Returns  TVarChar
as
begin
  declare @vFormHtml             TVarChar,
          @vRecordId             TRecordId,
          @vAttributeName        varchar(128),
          @vAttributeValue       varchar(1000),
          @vPlaceHolderString    TVarChar,
          @vPlaceHolderStartPos  TInteger,
          @vPlaceHolderEndPos    TInteger;

  /* Retrieve the Form Raw HTML */
  select @vFormHtml = F.RawHtml
  from AMF_Forms F
  where (F.FormName = @FormName) and (DeviceCategory = coalesce(@DeviceCategory, DeviceCategory)) and (BusinessUnit = coalesce(@BusinessUnit, BusinessUnit));

  /* Process input form attributes */
  select @vRecordId = 0;
  while (exists (select RecordId from @FormAttributes where RecordId > @vRecordId))
    begin
      select top 1
             @vRecordId       = RecordId,
             @vAttributeName  = AttributeName,
             @vAttributeValue = AttributeValue
      from @FormAttributes
      where (RecordId > @vRecordId)
      order by RecordId;

      if (@vAttributeName like 'FORMATTR_%')
        select @vAttributeName = '[' + @vAttributeName + ']';

      select @vFormHtml = replace(@vFormHtml, @vAttributeName, @vAttributeValue);
    end

  /* clean up place holders which have no values given in the input attributes table */
  while (charindex('[FORMATTR_', @vFormHtml) > 0)
    begin
      select @vPlaceHolderStartPos = charindex('[FORMATTR_', @vFormHtml) + 1,
             @vPlaceHolderEndPos   = charindex(']', @vFormHtml, @vPlaceHolderStartPos),
             @vPlaceHolderString   = substring(@vFormHtml, @vPlaceHolderStartPos - 1 /* include the start char */, (@vPlaceHolderEndPos - @vPlaceHolderStartPos + 2 /* include the start and end chars */));

      select @vFormHtml = replace(@vFormHtml, @vPlaceHolderString, '');
    end
ExitHandler:
  return (@vFormHtml);
end /* fn_AMF_SubstituteFormAttributes */

Go

