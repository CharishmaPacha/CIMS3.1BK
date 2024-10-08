/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_AMF_TransactionFailed') is not null
  drop Function fn_AMF_TransactionFailed;
Go
/*------------------------------------------------------------------------------
  fn_AMF_TransactionFailed:

  Function returns True when the input XML is an Error XML of V2 Format
------------------------------------------------------------------------------*/
Create Function fn_AMF_TransactionFailed
  (@InputXML  xml)
  --------------------
   Returns    TBoolean
as
begin /* fn_AMF_TransactionFailed */
  declare @vErrorMessage TMessage;

  select @vErrorMessage = Record.Col.value('ErrorMessage[1]',    'TMessage')
  from @InputXML.nodes('/ERRORDETAILS/ERRORINFO') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @InputXML = null ) );

  return (Case when (@vErrorMessage is not null) then 1 else 0 end);
end /* fn_AMF_TransactionFailed */

Go

