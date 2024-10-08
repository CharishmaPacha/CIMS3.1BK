/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/15  MRK     pr_Imports_ImportRecords, pr_Imports_ImportRecords, pr_Imports_ValidateASNLPNDetails, pr_InterfaceLog_AddDetails
  pr_Imports_ValidateASNLPNDetails: Correceted changes to validate SKUDimentions
  pr_Imports_ValidateVendor, pr_Imports_ValidateASNLPNs, pr_Imports_ValidateASNLPNDetails.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateASNLPNDetails') is not null
  drop Procedure pr_Imports_ValidateASNLPNDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateASNLPNDetail: This procedure is used to validate the
    ASN LPNDetails being imported. This can be run independently when importing
    only ASN Details or in the case of single records of ASN i.e. LPN Hdr + Dtl
    this would be invoked after the Headers are validated. So, if the Headers
    is already deemed as having an error, then there is no reason to process
    the details again.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateASNLPNDetails
  (@ttImportASNLPNDetail  TASNLPNImportType READONLY)
as
  declare @vReturnCode                  TInteger,
          @vValidateReceipts            TControlValue,
          @vValidateUnitsPerPackage     TControlValue,
          @vAllowInactiveSKUs           TControlValue = 'Y',
          @vBusinessUnit                TBusinessUnit,
          @ttASNLPNDetailValidation     TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Get value from import table for validation */
  insert into @ttASNLPNDetailValidation (RecordId, RecordType, EntityId, EntityKey, EntityStatus, LPNId, LPN, SKUId, SKU,
                                         ReceiptId, ReceiptNumber, ReceiptDetailId, InputXML, Warehouse,BusinessUnit,
                                         RecordAction, HostRecId)
    select ALD.RecordId, ALD.RecordType, ALD.LPNId, ALD.LPN, ALD.Status,ALD.LPNId, ALD.LPN, ALD.SKUId, ALD.SKU,
           ALD.ReceiptId, ALD.ReceiptNumber, ALD.ReceiptDetailId, convert(nvarchar(max), ALD.InputXML), ALD.DestWarehouse, ALD.BusinessUnit,
           dbo.fn_Imports_ResolveAction('ASNLD', ALD.RecordAction, ALD.LPNDetailId, ALD.BusinessUnit, null /* UserId */), ALD.HostRecId
    from @ttImportASNLPNDetail ALD
    where (RecordAction <> 'E'); -- Exclude the records which were already marked as errors

  /* Get BusinessUnit from @ttImportASNLPNDetail */
  select top 1 @vBusinessUnit = Businessunit from @ttImportASNLPNDetail

  /* If the user trying to insert an existing record into the db or
                 trying to update or delete the non existing record
    then we need to resolve what to do based upon control value */
  select @vValidateReceipts        = dbo.fn_Controls_GetAsString('IMPORT_ASNLD', 'ValidateReceipt',   'N' /*  No */,  @vBusinessUnit, '' /* UserId */),
         @vAllowInactiveSKUs       = dbo.fn_Controls_GetAsString('IMPORT_ASNLD', 'AllowInactiveSKUs', 'Y' /*  Yes */, @vBusinessUnit, '' /* UserId */),
         @vValidateUnitsPerPackage = dbo.fn_Controls_GetAsString('IMPORT_ASNLD', 'ValidateUnitsPerPackage','Y' /*  Yes */, @vBusinessUnit, '' /* UserId */);

  /* Execute Validations */

  /* If action itself was invalid, then report accordingly */
  update ALDV
  set ALDV.RecordAction = 'E' /* Error */,
      ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', null)
  from @ttASNLPNDetailValidation ALDV
  where (ALDV.RecordAction = 'X' /* Invalid Action */);

  /* Validate BU, ignore Ownership & Warehouse */
  update @ttASNLPNDetailValidation
  set ResultXML = coalesce(ResultXML, '') +
                  dbo.fn_Imports_ValidateInputData('LPN', LPN, LPNId,
                                                   RecordAction, BusinessUnit, '@@' /* Ownership */, Warehouse /* Warehouse */)

  /* If SKU was invalid, then report accordingly */
  update ALDV
  set ALDV.RecordAction = 'E' /* Error */,
      ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSKU', ALDV.SKU)
  from @ttASNLPNDetailValidation ALDV
  where (ALDV.SKUId is null);

  /* If we are not to allow inactive SKUs, then report accordingly */
  if (@vAllowInactiveSKUs <> 'Y' /* Yes */)
    update ALDV
    set ALDV.RecordAction = 'E' /* Error */,
        ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_SKUIsInactive', ALDV.SKU)
    from @ttASNLPNDetailValidation ALDV
      join SKUs S on S.SKUId = ALDV.SKUId
    where (S.Status = 'I' /* Inactive */);

  /* If LPN was invalid, then report accordingly */
  update ALDV
  set ALDV.RecordAction = 'E' /* Error */,
      ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_LPNIsInvalid', ALDV.LPN)
  from @ttASNLPNDetailValidation ALDV
  where (ALDV.LPNId is null);

  /* If Receipt was invalid, then report accordingly */
  if (@vValidateReceipts = 'Y')
    update ALDV
    set ALDV.RecordAction = 'E' /* Error */,
        ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'ReceiptIsInvalid', ALDV.ReceiptNumber)
    from @ttASNLPNDetailValidation ALDV
    where (ALDV.ReceiptId is null);

  /* If Receipt Detail was invalid, then report accordingly */
  if (@vValidateReceipts = 'Y')
    update ALDV
    set ALDV.RecordAction = 'E' /* Error */,
        ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'ReceiptDetailIsInvalid', ALDV.ReceiptDetailId)
    from @ttASNLPNDetailValidation ALDV
    where (ALDV.ReceiptDetailId is null);

  /* If LPN Detail already exists, then report accordingly */
  update ALDV
  set ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LPNLineAlreadyExists', '')
  from @ttASNLPNDetailValidation ALDV
       join LPNDetails LD on (ALDV.LPNId  = LD.LPNId) and
                             (ALDV.SKUId  = LD.SKUId)
  where (LD.LPNDetailId is not null);

  /* If LPN Detail was Invalid, then report accordingly */
  update ALDV
  set ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LPNLineIsInvalid', '')
  from @ttASNLPNDetailValidation ALDV
       join LPNDetails LD on (ALDV.LPNId  = LD.LPNId) and
                             (ALDV.SKUId  = LD.SKUId)
  where (ALDV.RecordAction = 'X' /* Invalid Action */) and
        (LD.LPNDetailId is null);

  /* If LPN is not inTransit, then we cannot change the details anymore */
  update ALDV
  set ALDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LPNAlreadyPutaway', '')
  from @ttASNLPNDetailValidation ALDV
  where (ALDV.EntityStatus not in ('T' /* Intransit */, 'N' /* New */, 'R' /* Received */));

  /* validate SKU package here.. assumption is client will give valid data.
     i.e quantity will be multiples of innerpacks and Packages */
  update ALDV
  set ALDV.RecordAction = 'E' /* Error */,
      ALDV.ResultXML    = dbo.fn_Imports_AppendError(ALDV.ResultXML, 'LPNInnerPacksAndQtyMismatch', '')
  from @ttASNLPNDetailValidation ALDV
       join @ttImportASNLPNDetail ALD on ALD.RecordId = ALDV.RecordId
  where (@vValidateUnitsPerPackage = 'Y')    and
        (coalesce(ALD.InnerPacks, 0)  > 0) and
        ((ALD.Quantity % coalesce(ALD.InnerPacks, 1) > 0));

  /* Update RecordAction when there are errors */
  update @ttASNLPNDetailValidation
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  update @ttASNLPNDetailValidation
  set ResultXML = dbo.fn_XMLNode('Errors', ResultXML)
  where (RecordAction = 'E');

  select * from @ttASNLPNDetailValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateASNLPNDetails */

Go
