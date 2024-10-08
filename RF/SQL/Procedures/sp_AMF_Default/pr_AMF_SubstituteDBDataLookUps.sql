/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/01  RIA     pr_AMF_SubstituteDBDataLookUps: Added and made changes to pr_AMF_GetFormDetails (HA-2517)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_SubstituteDBDataLookUps') is not null
  drop Procedure pr_AMF_SubstituteDBDataLookUps;
Go
/*------------------------------------------------------------------------------
  pr_AMF_SubstituteDBDataLookUps: V3 RF forms need provision to show lookup
    values in drop down controls and this method facilitates building of the
    HTML to show the look up descriptions. So, if a lookup category is specified,
    it would would build the HTML for all the values of that category. This is
    different than the pr_AMF_SubstituteDBDataSet which has provision to show
    one value only where as with DBDataLookUps we show description but provide
    the corresponding code for it as well for saving.

  Implementation: For the data set to be shown for any drop down list, use
     DBDATALOOKUPS_<lookUpCategory> and the drop down list will how the values
     of that lookup category in order of SortSeq & LookUpCode

  Ex: DBDATALOOKUPS_Warehouse: Here Warehouse will be the lookupcategory.

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_SubstituteDBDataLookUps
  (@InputFormHtml   TVarchar,
   @xmlInput        xml,
   @OutputFormHtml  TVarchar output)
as
  declare @vUserId               TUserId,
          @vBusinessUnit         TBusinessUnit,
          @vDeviceId             TDeviceId,
          @vLoggedInWarehouse    TWarehouse,
          @vLookUpCategory       TCategory,
          @vTextXML              TXML,
          @vText                 TVarChar,
          @vSQL                  TNVarChar,
          @vPlaceHolderString    TVarChar,
          @vPlaceHolderStartPos  TInteger,
          @vPlaceHolderEndPos    TInteger;

begin /* pr_AMF_SubstituteDBDataLookUps */

  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',    'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',        'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',        'TDeviceId'    )
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId, @vUserId, @vBusinessUnit);

  select @OutputFormHtml = @InputFormHtml; /* Initialize the output */

  /* while there are DBDATALOOKUPS to fill in in the form, do so */
  while (charindex('[DBDATALOOKUPS_', @OutputFormHtml) > 0)
    begin
      /* Fetching Starting index and length of the place holder */
      select @vPlaceHolderStartPos = charindex('[DBDATALOOKUPS', @OutputFormHtml) + 1,
             @vPlaceHolderEndPos   = charindex(']', @OutputFormHtml, @vPlaceHolderStartPos),
             @vPlaceHolderString   = substring(@OutputFormHtml, @vPlaceHolderStartPos - 1 /* include the start char */, (@vPlaceHolderEndPos - @vPlaceHolderStartPos + 2 /* include the start and end chars */));

     /* LookUpCategory name is between the first underscore and end bracket */
     select @vLookUpCategory   = dbo.fn_SubstringBetweenSeparator(replace(@vPlaceHolderString, ']' , ''), '_', 1, 2);

     select @vSQL  = 'select @vTextXML = coalesce(@vTextXML, '''')' + ' + ' + '''<option value="''' + ' + ' + 'LookUpCode' + ' + ' + '''">''' + ' + ' + 'LookUpDisplayDescription' + ' + ' + '''</option>'''+
                     ' from vwLookUps
                      where (LookUpCategory = ''' + @vLookUpCategory + ''') and
                            (Status    = ''A'')
                      order by SortSeq, LookUpCode;'

     /* Run Dynamic SQL */
     select @vTextXML = null;
     execute sp_executesql @vSQL, N'@vTextXML Tvarchar output', @vTextXML = @vTextXML output;

     /* Add this as first node */
     select @vTextXML = '<option value="">select a value </option>' + @vTextXML

     /* Replace the place holder */
     select @OutputFormHtml = replace(@OutputFormHtml, @vPlaceHolderString, @vTextXML);
   end /* while */

end /* pr_AMF_SubstituteDBDataLookUps */

Go

