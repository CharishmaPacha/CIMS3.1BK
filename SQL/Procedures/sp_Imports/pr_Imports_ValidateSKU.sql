/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/04/07  RKC/AJM pr_Imports_ValidateSKU:Made changes get the correct validation message (JLFL-173)
                      pr_Imports_ValidateSKU, pr_Imports_GetXmlResult, pr_Import_SQLDATAInterfaceLog,
  2021/04/05  TD      pr_Imports_ValidateSKU: Do not validate if UPC is null (BK-75)
  2021/03/02  MS      pr_Imports_ValidateSKU: Made changes to validate if UPC is non-numeric (BK-241)
  2018/10/15  VS      pr_Imports_ValidateSKU: Do not update SAP SKU when we get the update from SAGE for the same (HPI-2011)
                      pr_Imports_SKUs, pr_Imports_ValidateSKU:
  2016/06/01  KL      pr_Imports_ValidateSKU: Added validation for UoM (HPI-97)
  2016/02/09  NY      pr_Imports_ValidateSKUPrepacks : Added validation for Component Qty(TDAX-319).
                      Modified pr_Imports_ValidateSKU to use new functions for Code optimization
  2014/11/27  NB      pr_Imports_ValidateSKU - Code optimization
  2014/10/20  NB      pr_Imports_SKUs, pr_Imports_ImportRecords, pr_Imports_ValidateSKU
  2012/03/27  YA      Created pr_Imports_SKUPrePacks, pr_Imports_ValidateSKUPrePacks.
  2011/01/02  AR      pr_Interface_Import, pr_Imports_SKUs, pr_Imports_ValidateSKU:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateSKU') is not null
  drop Procedure pr_Imports_ValidateSKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateSKU:
     accepts the SKUImports table type with SKU records to validate
     returns the validation results in a dataset of ImportValidationsType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateSKU
as
  declare @vReturnCode   TInteger,
          @vSKU          TSKU;

begin
  set @vReturnCode = 0;

  /* Insert key information in SKU validations table */
  insert into #ImportValidations(RecordId, EntityId, EntityKey, RecordType, KeyData, InputXML, SourceSystem, BusinessUnit,
                              RecordAction, UoM, HostRecId)
    select S.RecordId, S.SKUId, S.SKU, S.RecordType, S.SKU, convert(nvarchar(max), S.InputXML), S.SourceSystem, S.BusinessUnit,
           dbo.fn_Imports_ResolveAction('SKU', S.RecordAction, S.SKUId, S.BusinessUnit, null /* UserId */), S.UoM, HostRecId
    from #ImportSKUs S;

  update #ImportValidations
  set ResultXML = coalesce(SV.ResultXML, '') + dbo.fn_Imports_ValidateInputData('SKU', S.SKU, S.SKUId, SV.RecordAction, S.BusinessUnit, S.Ownership, '@@' /* Warehouse */)
  from #ImportValidations SV join #ImportSKUs S on  S.RecordId = SV.RecordId;

  /* If UoM is invalid, then report accordingly */
  update S
  set S.RecordAction = 'E' /* Error */,
      S.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidUoM', S.EntityKey)
  from #ImportValidations S
       left outer join vwLookUps L on (S.UoM = L.LookUpCode) and
                                      (L.LookUpCategory = 'UoM')
  where (S.UoM is not null) and (coalesce(L.LookUpDescription, '') = '');

  /* If action itself was invalid, then report accordingly */
  update S
  set S.RecordAction = 'E' /* Error */,
      S.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', S.EntityKey)
  from #ImportValidations S
  where (S.RecordAction = 'X' /* Invalid Action */);

  /* If action itself was invalid, then report accordingly */
  update S
  set S.RecordAction = 'E' /* Error */,
      S.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ActionNotSupported', S.EntityKey)
  from #ImportValidations S
  where (S.RecordType = 'SKUA') and (S.RecordAction in ('I', 'D' /* Insert/Delete not supported */));

  /* Validate SourceSystem record */
  update S
  set S.RecordAction = 'E' /* Error */,
      S.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSourceSystem', S.EntityKey)
  from #ImportValidations S
  where (dbo.fn_IsValidLookUp('SourceSystem', S.SourceSystem, S.BusinessUnit, '') is not null);

  /* We do not want to allow any deletes by diff source system.*/
  update S
  set S.RecordAction = 'E' /* Error */,
      S.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_CannotDeleteDiffSourceSystem', S.EntityKey)
  from  #ImportValidations S
    join SKUs S1 on S1.SKUId = S.EntityId and S1.SourceSystem <> S.SourceSystem
  where S.RecordAction in ('D' /* Delete */);

  /* If SKUs are inactive then we will allow update SKUs sent from diff source system */
  update S
  set S.RecordAction = 'E' /* Error */,
      S.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_CannotChangeSourceSystem', S.EntityKey)
  from  #ImportValidations S
    join SKUs S1 on S1.SKUId = S.EntityId and S1.SourceSystem <> S.SourceSystem
  where (S.RecordAction in ('U')) and
        (S1.Status     = 'A' /* Active */);

  /* If UPC is Non-Numeric then mark as Invalid record */
  update SV
  set SV.RecordAction = 'E' /* Error */,
      SV.ResultXML    = dbo.fn_Imports_AppendError(SV.ResultXML, 'Import_InvalidUPC', SV.EntityKey)
  from #ImportValidations SV join #ImportSKUs S on  (S.RecordId = SV.RecordId)
  where (IsNumeric(S.UPC) = '0') and (coalesce(S.UPC, '') <> '');

  /* Update RecordAction when there are errors */
  update #ImportValidations
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateSKU */

Go
