/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/02/09  NY      pr_Imports_ValidateSKUPrepacks : Added validation for Component Qty(TDAX-319).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateSKUPrepacks') is not null
  drop Procedure pr_Imports_ValidateSKUPrepacks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateSKUPrepacks:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateSKUPrepacks
  (@SKUPrepacksImport  TSKUPrepacksImportType  READONLY)
as
  declare @vReturnCode              TInteger,
          @SKUPrepacksValidation    TSKUPrepacksImportValidation;
begin
  set @vReturnCode = 0;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  /* Values to be pulled out from the tables for validation */
  insert into @SKUPrepacksValidation(RecordId, RecordAction, RecordType, MasterSKU, ComponentSKU, ComponentQty, Status,
                                 SortSeq, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, InputXML, HostRecId)
    select  S.RecordId, S.RecordAction, 'SMP', S.MasterSKU, S.ComponentSKU, S.ComponentQty,
            S.Status, S.SortSeq, S.BusinessUnit, S.CreatedDate, S.ModifiedDate, S.CreatedBy, S.ModifiedBy,
            convert(nvarchar(max), S.InputXML), S.HostRecId
    from @SKUPrepacksImport S;

  /* Fetching MasterSKUId, and MasterBU value from SKUs table*/
  update SP
  set MasterSKUId = S.SKUId, MasterBU = S.BusinessUnit
    from @SKUPrepacksValidation SP join SKUs S on (SP.MasterSKU = S.SKU) and (SP.BusinessUnit = S.BusinessUnit);

  /* Fetching ComponentSKUId, and ComponentBU value from SKUs table*/
  update SP
  set ComponentSKUId = S.SKUId, ComponentBU = S.BusinessUnit
    from @SKUPrepacksValidation SP join SKUs S on (SP.ComponentSKU = S.SKU) and (SP.BusinessUnit = S.BusinessUnit);

  /* Fetching SKUPrepackId joining SKUPrepacks table using MasterSKUId and ComponentSKUId */
  update SP
  set SP.SKUPrepackId = SKP.SKUPrepackId,
      SP.RecordAction =  dbo.fn_Imports_ResolveAction('SMP', SP.RecordAction, SKP.SKUPrepackId, SP.BusinessUnit, null /* UserId */)
  from @SKUPrepacksValidation SP left outer join SKUPrepacks SKP on
       (SP.MasterSKUId = SKP.MasterSKUId) and (SP.ComponentSKUId = SKP.ComponentSKUId);

  /* Execute Validations */
  /* If action itself was invalid, then report accordingly */
  update SP
  set SP.RecordAction = 'E' /* Error */,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', null)
  from @SKUPrepacksValidation SP
  where (SP.RecordAction = 'X' /* Invalid Action */);

  /* Validating Business Unit */
  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'BusinessUnitIsRequired', BusinessUnit)
  from @SKUPrepacksValidation SP
  where SP.RecordId in (select S.RecordId from @SKUPrepacksImport S
                        where (coalesce(S.BusinessUnit, '') = ''));

  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidBusinessUnit', BusinessUnit)
  from @SKUPrepacksValidation SP
  where SP.RecordId in (select S.RecordId from @SKUPrepacksImport S
                          left outer join vwBusinessUnits B on (S.BusinessUnit = B.BusinessUnit)
                        where (coalesce(S.BusinessUnit, '') <> '') and (coalesce(B.BusinessUnit,'') = ''));

  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_MasterSKUIsRequired', ComponentSKU)
  from @SKUPrepacksValidation SP
  where (coalesce(SP.MasterSKU, '') = '');

  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_MasterSKUIsInvalid', MasterSKU)
  from  @SKUPrepacksValidation SP
  where (coalesce(SP.MasterSKUId, '') = '');

  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ComponentSKUIsRequired', MasterSKU)
  from @SKUPrepacksValidation SP
  where (coalesce(SP.ComponentSKU, '') = '');

  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ComponentSKUIsInvalid', ComponentSKU)
  from @SKUPrepacksValidation SP
  where (coalesce(SP.ComponentSKUId, '') = '');

  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ComponentQtyIsInvalid', ComponentSKU)
  from @SKUPrepacksValidation SP
  where (coalesce(SP.ComponentQty, 0) < 1);

  /* This condition never gets hit but present as a cautionary measure */
  update SP
  set SP.RecordAction = 'E' /* Error*/,
      SP.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'BusinessUnitMismatch', null)
  from @SKUPrepacksValidation SP
  where (SP.MasterBU     <> SP.ComponentBU) or
        (SP.BusinessUnit <> SP.MasterBU) or
        (SP.BusinessUnit <> SP.ComponentBU)

  /* If the user is trying to insert an existing record into the DB or
     trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */

  update SP
  set SP.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'SKUPrePackDetailAlreadyExists', null)
  from @SKUPrepacksValidation SP
  where (coalesce(SP.SKUPrepackId,'') <>  '') and
        (SP.RecordAction  = 'E' /* Error*/)

  update SP
  set SP.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'SKUPrepackDetailDoesNotExist', null)
  from @SKUPrepacksValidation SP
  where (coalesce(SP.SKUPrepackId,'') = '') and
        (SP.RecordAction = 'E' /* Error*/)

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  update @SKUPrepacksValidation
  set ResultXML = dbo.fn_XMLNode('Errors', ResultXML)
  where (RecordAction = 'E');

  select * from @SKUPrepacksValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateSKUPrepacks */

Go
