/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_GetMessageXML') is not null
  drop Function fn_AMF_GetMessageXML;
Go
/*------------------------------------------------------------------------------
  fn_AMF_GetMessageXML:

  Builds the Error XML in the format suitable for AMF application to process
------------------------------------------------------------------------------*/
Create Function fn_AMF_GetMessageXML
  (@Message     TMessage)
  -----------------------
   Returns  TXML
as
begin /* fn_AMF_GetMessageXML */
  declare @vMessageXML  TXML;
  select @vMessageXML = dbo.fn_XMLNode('Message', dbo.fn_XMLNode('DisplayText', @Message));

  return(@vMessageXML);
end /* fn_AMF_GetMessageXML */

Go

