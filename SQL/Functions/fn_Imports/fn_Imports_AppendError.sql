/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/09/18  NY      Used fn_Imports_AppendError to show validation erros (CIMS-603)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Imports_AppendError') is not null
  drop Function fn_Imports_AppendError;
Go
/*------------------------------------------------------------------------------
  fn_Imports_AppendError: This function appends an XML Node to an XML. Given the
   name and value inputs, it would add <Name>Value</Value> to the <XML>.

  Usage:
  select dbo.fn_Imports_AppendError(<XML>, 'Imports_InvalidEntity', 'C001')
  -- returns <.....><Error>Entity C001 is invalid</Error>
------------------------------------------------------------------------------*/
Create Function fn_Imports_AppendError
  (@ResultXML   TVarchar,
   @MessageName TDescription,
   @Value       TVarChar)
---------------------
   Returns TVarChar
as
begin /* fn_Imports_AppendError */

  /* Get the message description with the value substituted and add to the ResultXML as an XML Error Node */
  return (dbo.fn_XMLAppendNode(@ResultXML, 'Error', dbo.fn_Messages_Build(@MessageName, @Value, null, null, null, null)));

end /* fn_Imports_AppendError */

Go
