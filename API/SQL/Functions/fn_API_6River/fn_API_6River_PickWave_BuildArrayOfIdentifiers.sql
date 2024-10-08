/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/04  TK      fn_API_6River_PickWave_BuildArrayOfIdentifiers: Initial Revision (CID-1599)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_API_6River_PickWave_BuildArrayOfIdentifiers') is not null
  drop Function fn_API_6River_PickWave_BuildArrayOfIdentifiers;
Go
/*------------------------------------------------------------------------------
  fn_API_6River_PickWave_BuildArrayOfIdentifiers: Returns the customized array of identifiers for 6River

  Function will return identifiers in the following format

  "identifiers": [
          {
            "label": "UPC",
            "allowedValues": [
              "847153194206"
            ]
          },
          {
            "label": "COO",
            "allowedValues": [
              "CN",
              "LK",
              "US",
              "VN"
            ]
          }
        ]
------------------------------------------------------------------------------*/
Create Function fn_API_6River_PickWave_BuildArrayOfIdentifiers
  (@TaskDetailId  TRecordId)
  --------------------------
   returns        TVarChar
as
begin
  declare @vCoOAllowedValues    TVarchar,
          @vIdentifiersArray    TVarchar;

  /* Stuff all allowed COO Values */
  select @vCoOAllowedValues = stuff((select ',' + '"' + LookUpCode + '"'
                                     from LookUps
                                     where LookUpCategory = 'CoO' and
                                           Status = 'A' /* Active */
                                     FOR XML PATH('')), 1, 1, '');

  /* Build Array of Identifiers */
  select @vIdentifiersArray = (select case when UPC is not null then '[{"label":"UPC","allowedValues":["' + UPC + '"]}'
                                           else '[{"label":"LOCATION","allowedValues":["' + Location + '"]}'
                                      end +
                                      case when dbo.fn_OrderHeaders_IsInternationalOrder(OrderId) = 'Y' then ',' + '{"label":"COO","allowedValues":[' + @vCoOAllowedValues + ']}'
                                           else ''
                                      end + ']'
                               from vwUIPickTaskDetails
                               where (TaskDetailId = @TaskDetailId));

  return (@vIdentifiersArray);
end /* fn_API_6River_PickWave_BuildArrayOfIdentifiers */

Go
