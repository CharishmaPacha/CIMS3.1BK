/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/27  MS      pr_Imports_UPCs, pr_Imports_ValidateUPC: Enhance pr_Imports_UPCs to handle OPENXML (CIMS-1841)
  2013/07/31  NY      Added procedure pr_Imports_UPCs, pr_Imports_ValidateUPC(ta9176).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateUPC') is not null
  drop Procedure pr_Imports_ValidateUPC;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateUPC:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateUPC
  (@ttUPCsToImport  TSKUAttributeImportType READONLY)
as
  declare @vReturnCode     TInteger,

          @UPCValidation   TImportValidationType;
begin
  select @vReturnCode = 0;

  /* insert values into validation table type */
  insert into @UPCValidation(RecordId, EntityId, EntityKey, RecordType, KeyData, SKU, SKUId, InputXML,
                             BusinessUnit, RecordAction, HostRecId)
    select UI.RecordId, UI.SKUId, UI.SKU, UI.RecordType, UI.UPC, UI.SKU,UI.SKUId, convert(nvarchar(max), UI.InputXML),
           UI.BusinessUnit, UI.RecordAction, UI.HostRecId
    from @ttUPCsToImport UI;

  update UV
  set RecordAction = dbo.fn_Imports_ResolveAction('UPC', UV.RecordAction, SA.AttributeValue, UV.BusinessUnit, null /* UserId */)
  from @UPCValidation UV
    left outer join SKUAttributes SA on (UV.EntityId = SA.SKUId) and (UV.KeyData = SA.AttributeValue) and (SA.AttributeType = 'UPC')

  /* Validations */
  /* Validate EntityKey, BU, ignore Ownership & Warehouse */
  update @UPCValidation
  set ResultXML = coalesce(UV.ResultXML, '') +
                  dbo.fn_Imports_ValidateInputData('Import_UPC', UV.KeyData, UV.RecordId,
                                                   UV.RecordAction, UV.BusinessUnit, '@@' /* Ownership */, '@@' /* Warehouse */)
  from @UPCValidation UV join @ttUPCsToImport UI on UV.RecordId = UI.RecordId;

  /* Error if the action cannot be done because of conflicts i.e. Inserting an already existing Record or
     updating a non existing record */
    /* If action itself was invalid, then report accordingly */
  update UV
  set UV.RecordAction = 'E' /* Error */,
      UV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', UV.EntityKey)
  from @UPCValidation UV
  where (UV.RecordAction = 'X' /* Invalid Action */);

  /* Check if the UPC exists for the given SKU */
  update @UPCValidation
  set ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_UPCDoesNotExist', '')
  where  (RecordAction = 'E' /* Error*/) and
          RecordId in (select UI.RecordId from @ttUPCsToImport UI
                         left outer join SKUAttributes SA on (UI.SKUId = SA.SKUId) and (UI.UPC = SA.AttributeValue) and (SA.AttributeType = 'UPC')
                       where (coalesce(SA.AttributeValue, '') = ''));

  update @UPCValidation
  set RecordAction = 'E' /* Error*/,
      ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_UPCAlreadyExistsForAnotherSKU', '')
  where RecordId in (select UI.RecordId from @ttUPCsToImport UI
                        join SKUAttributes SA on (UI.UPC = SA.AttributeValue)
                     where (SA.AttributeType = 'UPC') and
                           (SA.SKUId <> UI.SKUId) and
                           (UI.RecordAction in ('I'/* Insert */, 'U' /* Update */)))

  /* Validate SKU */
  update @UPCValidation
  set RecordAction = 'E' /* Error*/,
      ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'SKUIsRequired', '')
  where (coalesce(SKU, '') = '');

  update @UPCValidation
  set RecordAction = 'E' /* Error*/,
      ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'SKUIsInvalid', '')
  where (coalesce(SKUId, '') = '');

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  --update @UPCValidation
  --set ResultXML = dbo.fn_XMLNode('<Errors>', ResultXML)
  --where (RecordAction = 'E' /* Error*/);

  select * from @UPCValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateUPC */

Go
