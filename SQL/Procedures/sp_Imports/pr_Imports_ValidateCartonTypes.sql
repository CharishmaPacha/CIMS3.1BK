/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/06/30  OK      Added pr_Imports_CartonTypes, pr_Imports_ValidateCartonTypes.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateCartonTypes') is not null
  drop Procedure pr_Imports_ValidateCartonTypes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateCartonTypes:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateCartonTypes
  (@ttCartonTypesImports  TCartonTypesImportType  READONLY)
as
  declare @vReturnCode              TInteger,
          @ttCartonTypesValidation  TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Get value from import table for validation */
  insert into @ttCartonTypesValidation (RecordId, EntityId, EntityKey, InputXML, BusinessUnit, RecordAction, HostRecId)
    select C.RecordId, C.CartonTypeId, C.CartonType, convert(nvarchar(max), C.InputXML), C.BusinessUnit,
    dbo.fn_Imports_ResolveAction('CT', C.RecordAction, C.CartonTypeId, C.BusinessUnit, null /* UserId */), C.HostRecId
    from @ttCartonTypesImports C;

  /* Execute Validations */

  /* Validate EntityKey, BU, ignore Ownership & Warehouse */
  update @ttCartonTypesValidation
  set ResultXML = coalesce(CT.ResultXML, '') +
                  dbo.fn_Imports_ValidateInputData('Import_CartonType', CT.EntityKey, CT.EntityId,
                                                   CT.RecordAction, CT.BusinessUnit, '@@' /* Ownership */, '@@' /* Warehouse */)
  from @ttCartonTypesValidation CT join @ttCartonTypesImports C on CT.RecordId = C.RecordId;

  /* If action itself was invalid, then report accordingly */
  update CT
  set CT.RecordAction = 'E' /* Error */,
      CT.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', CT.EntityKey)
  from @ttCartonTypesValidation CT
  where (CT.RecordAction = 'X' /* Invalid Action */);

  /* Update RecordAction when there are errors */
  update @ttCartonTypesValidation
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  update @ttCartonTypesValidation
  set ResultXML    = dbo.fn_XMLNode('Errors', ResultXML)
  where (RecordAction = 'E');

  select * from @ttCartonTypesValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateCartonTypes */

Go
