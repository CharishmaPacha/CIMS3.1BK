/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_BuildErrorXML') is not null
  drop Function fn_AMF_BuildErrorXML;
Go
/*------------------------------------------------------------------------------
  fn_AMF_BuildErrorXML:

  Builds the Error XML in the format suitable for AMF application to process
------------------------------------------------------------------------------*/
Create Function fn_AMF_BuildErrorXML
  (@InputXML     xml)
  -------------------
   Returns       TXML
as
begin /* fn_AMF_BuildErrorXML */
  declare @vErrorMessage TMessage,
          @vErrorXML     TXML;

  select @vErrorMessage = Record.Col.value('ErrorMessage[1]',    'TMessage')
  from @InputXML.nodes('/ERRORDETAILS/ERRORINFO') as Record(Col)
  OPTION (OPTIMIZE FOR (@InputXML = null));

  if (@vErrorMessage is not null)
    begin
      /* Remove any special characters which may mess up the Xml format */
      select @vErrorMessage =  replace(replace(replace(@vErrorMessage, '<', ''), '>', ''), '$', '');
      select @vErrorXML =  '<Errors><Messages>' +
                             dbo.fn_AMF_GetMessageXML(@vErrorMessage) +
                           '</Messages></Errors>';
    end

  return(@vErrorXML);
end /* fn_AMF_BuildErrorXML */

Go

