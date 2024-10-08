/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/10  VS      pr_AMF_SubstituteDBDataSet: Get the Printer name and description using dynamic query (HA-2113)
  2021/03/03  RIA     pr_AMF_SubstituteDBDataSet: Added and made changes to pr_AMF_GetFormDetails (HA-2113)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_SubstituteDBDataSet') is not null
  drop Procedure pr_AMF_SubstituteDBDataSet;
Go
/*------------------------------------------------------------------------------
  pr_AMF_SubstituteDBDataSet: V3 RF populates dynamic drop downs in the form
    from the procedure that intiatiates the form. For example, if during Picking
    if we have to show the list of CoOs, we send that list from SQL to RF when
    the picking form is presented i.e. by GetNextPickTask. However, there is no
    such opportunity when the first form of the workflow presented requires a
    dynamic drop down. This proc is to faciliate such a scenario where the
    drop down is to be provided with the dataset in the first form of the workflow.
    The proc will take the input form, and substitute all the dynamic datasetss
    in the formt and return the same.

  Implementation: When such a need exists, the form specifies a placeholder for
  the data set as DBDATASET followed by the actual dataset name to be used
  and the FieldName and Description fields to use.

  Ex: DBDATASET_PRINTERS_PrinterName_PrinterDescription: Here PRINTERS will
  be the dataset, we need to consider using it as is or prefixing with vw. The next
  one is PrinterName which is the code and PrinterDescription is the description.

  Going forward we will be generalizing this and will use dynamic select query instead
  of hardcoding it.

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_SubstituteDBDataSet
  (@InputFormHtml   TVarchar,
   @xmlInput        xml,
   @OutputFormHtml  TVarchar output)
as
  declare @vUserId               TUserId,
          @vBusinessUnit         TBusinessUnit,
          @vDeviceId             TDeviceId,
          @vLoggedInWarehouse    TWarehouse,
          @vDataSetName          TName,
          @vCodeFieldName        TName,
          @vDescFieldName        TName,
          @vNode1                TName,
          @vNode2                TName,
          @vxmlText              xml,
          @vTextXML              TXML,
          @vText                 TVarChar,
          @vSQL                  TNVarChar,
          @vFieldName            TVarChar,
          @vFieldCaption         TVarChar,
          @vPlaceHolderString    TVarChar,
          @vPlaceHolderStartPos  TInteger,
          @vPlaceHolderEndPos    TInteger,
          @vDataSetStartPos      TInteger,
          @vNode1StartPos        TInteger,
          @vNode2StartPos        TInteger,
          @vDataSetEndPos        TInteger,
          @vNode1EndPos          TInteger,
          @vNode2EndPos          TInteger,
          @vFieldNameLength      TInteger;

begin /* pr_AMF_SubstituteDBDataSet */

  select @vUserId         = Record.Col.value('UserName[1]',      'TUserId'      ),
         @vDeviceId       = Record.Col.value('DeviceId[1]',      'TDeviceId'    ),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]',  'TBusinessUnit')
  from @xmlInput.nodes('/Root/SessionInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId, @vUserId, @vBusinessUnit);

  select @OutputFormHtml = @InputFormHtml; /* Initialize the output */

  /* while there are DBDATASETs to fill in in the form, do so */
  while (charindex('[DBDATASET_', @OutputFormHtml) > 0)
    begin
      /* Fetching Starting index and length of the place holder */
      select @vPlaceHolderStartPos = charindex('[DBDATASET', @OutputFormHtml) + 1,
             @vPlaceHolderEndPos   = charindex(']', @OutputFormHtml, @vPlaceHolderStartPos),
             @vPlaceHolderString   = substring(@OutputFormHtml, @vPlaceHolderStartPos - 1 /* include the start char */, (@vPlaceHolderEndPos - @vPlaceHolderStartPos + 2 /* include the start and end chars */)),
             @vFieldNameLength     = @vPlaceHolderEndPos-@vPlaceHolderStartPos - 10 /* length of DBDATASET_ literal */;

      /* if no field name was found in the place holder. replace the place holder with a blank string, to continue to the next one */
      --if (@vFieldNameLength > 0)
      --  begin
      --    select @OutputFormHtml = replace(@OutputFormHtml, @vPlaceHolderString, '');
      --    continue;
      --  end

     /* Dataset name is between the first and second underscore */
     select @vDataSetName   = dbo.fn_SubstringBetweenSeparator(@vPlaceHolderString, '_', 1, 2);
     select @vCodeFieldName = dbo.fn_SubstringBetweenSeparator(@vPlaceHolderString, '_', 2, 3);
     select @vDescFieldName = dbo.fn_SubstringBetweenSeparator(replace(@vPlaceHolderString, ']' ,''), '_', 3, 4);

     /* Fetch the given dataset related information */
     select @vSQL  = 'select @vTextXML = coalesce(@vTextXML, '''')' + ' + ' + '''<option value="''' + ' + ' + @vCodeFieldName + ' + ' + '''">''' + ' + ' + @vDescFieldName + ' + ' + '''</option>'''+
                     ' from ' + @vDataSetName +
                     ' where (Warehouse = ''' + @vLoggedInWarehouse + ''') and
                             (Status    = ''A'')
                      order by SortSeq, ' + @vCodeFieldName + ';'

     /* Run Dynamic SQL */
     select @vTextXML = null;
     execute sp_executesql @vSQL, N'@vTextXML Tvarchar output', @vTextXML = @vTextXML output;

     /* Add this as first node */
     select @vTextXML = '<option value=""> select a value </option>' + @vTextXML

     /* Replace the place holder */
     select @OutputFormHtml = replace(@OutputFormHtml, @vPlaceHolderString, @vTextXML);
   end /* while */

end /* pr_AMF_SubstituteDBDataSet */

Go

