/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/28  RIA     fn_AMF_BuildSuccessXML: Changes to get message description (CIMSV3-659)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_BuildSuccessXML') is not null
  drop Function fn_AMF_BuildSuccessXML;
Go
/*------------------------------------------------------------------------------
  fn_AMF_BuildSuccessXML:

  Builds the Success XML in the format suitable for AMF application to process
  TODO TODO.. the input needs to change to a table type with all the messages and relevant
  information for the message
  the function shall handle building the message from the inputs in the table columns
  for each row, and send back response in the format expected for sucess message
------------------------------------------------------------------------------*/
Create Function fn_AMF_BuildSuccessXML
  (@Message     TMessage)
  -----------------------
   Returns  TXML
as
begin /* fn_AMF_BuildSuccessXML */
  declare @vMessage    TMessage,
          @vSuccessXML TXML;

  select @vMessage = @Message;

  /* Get the description for AMF messages */
  if (@vMessage like 'AMF_%')
    select @vMessage = Description
    from Messages with (nolock)
    where (MessageName = @Message) and
          (Status      = 'A');

  if (@vMessage is not null)
    begin
      /* Remove any special characters which may mess up the Xml format */
      select @vMessage =  replace(replace(replace(@vMessage, '<', ''), '>', ''), '$', '');
      select @vSuccessXML = '<Info><Messages>' +
                              dbo.fn_AMF_GetMessageXML(@vMessage) +
                            '</Messages></Info>';
    end

  return(@vSuccessXML);
end /* fn_AMF_BuildSuccessXML */

Go

