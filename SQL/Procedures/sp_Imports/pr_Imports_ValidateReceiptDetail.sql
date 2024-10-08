/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/23  VM      pr_Imports_ValidateReceiptHeader & pr_Imports_ValidateReceiptDetail:
  2016/09/20  SV      pr_Imports_ValidateReceiptDetail: For HPI, Sage doen't send the SKU into CIMS for deleting the imported line.
  2016/09/20  AY      pr_Imports_ValidateReceiptDetail: Temp fix to not require SKU on delete (HPI-GoLive)
  2016/09/01  KL      pr_Imports_ValidateReceiptDetail: Added to update ExtraQtyAllowed based on the control value (HPI-512)
  2015/12/03  OK      pr_Imports_ValidateReceiptDetail: Enhanced to validate the ReceiptDeial Ownership with Header Ownership (NBD-58)
  2014/12/02  SK      pr_Imports_ImportRecords, pr_Imports_ReceiptDetails, pr_Imports_ValidateReceiptDetail:
  2014/08/14  NY      pr_Imports_ValidateReceiptDetail: Added coalesce condition to HostReceiptLine.
  2013/09/26  VM      pr_Imports_ValidateReceiptHeader, pr_Imports_ValidateReceiptDetail:
  2013/08/06  PK      pr_Imports_ValidateReceiptDetail: Passing in SKU as a input parameter and also handled
                      pr_Imports_ValidateReceiptDetail: Validate Receipt and SKU by gathering from RD UDF's.
  2011/02/25  VM      pr_Imports_ValidateReceiptDetail: Changed signature to validate the given SKU as well.
                      pr_Imports_ValidateReceiptDetails,pr_Imports_ValidateOrderHeaders
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateReceiptDetail') is not null
  drop Procedure pr_Imports_ValidateReceiptDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateReceiptDetail:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateReceiptDetail
  (@ReceiptDetailImport  TReceiptDetailImportType  READONLY)
as
  declare @vReturnCode              TInteger,
          @vBusinessUnit            TBusinessUnit,
          @ReceiptDetailValidation  TReceiptDetailValidationType;

begin
  set @vReturnCode = 0;

  insert into @ReceiptDetailValidation (RecordId, ReceiptDetailId, RecordAction, KeyData, ReceiptId, ReceiptNumber,
                                        SKUId, SKU, SKUStatus, QtyReceived, BusinessUnit,
                                        AllowInactiveSKUs, HostReceiptLine, DetailOwnership, InputXML, HostRecId)
    select RD.RecordId, RD.ReceiptDetailId, RD.RecordAction, RD.ReceiptNumber + '.' + RD.HostReceiptLine, RD.ReceiptId, RD.ReceiptNumber,
           RD.SKUId, RD.SKU, RD.SKUStatus, null, RD.BusinessUnit,
           'Y', RD.HostReceiptLine, RD.Ownership, convert(nvarchar(max), RD.InputXML), RD.HostRecId
    from @ReceiptDetailImport RD;

  /* Validate BU, Ownership & WH */
  update @ReceiptDetailValidation
  set ResultXML = coalesce(RDV.ResultXML, '') + dbo.fn_Imports_ValidateInputData('ReceiptDetail', RDV.ReceiptNumber, RDV.ReceiptId, RDV.RecordAction, RDV.BusinessUnit, '@@' /* Owner */, '@@' /* Wh */)
  from @ReceiptDetailValidation RDV join @ReceiptDetailImport RD on RDV.RecordId = RD.RecordId;

  /* Get the valid receipt information */
  update RDV
  set RDV.ReceiptId       = R.ReceiptId,
      RDV.ReceiptType     = R.ReceiptType,
      RDV.ReceiptStatus   = R.Status,
      RDV.HeaderOwnership = R.Ownership
  from @ReceiptDetailValidation RDV
    join ReceiptHeaders R on (RDV.ReceiptNumber = R.ReceiptNumber) and
                             (RDV.Businessunit  = R.BusinessUnit);

  update RDV
  set RDV.ReceiptDetailId = RD.ReceiptDetailId,
      RDV.QtyReceived     = RD.QtyReceived,
      RDV.QtyInTransit    = RD.QtyInTransit
  from  @ReceiptDetailValidation RDV
    join ReceiptDetails RD on (RDV.ReceiptId                     = RD.ReceiptId) and
                              (coalesce(RDV.HostReceiptLine, '') = coalesce(RD.HostReceiptLine,'')) and
                              (RDV.SKUId                         = RD.SKUId) and
                              (RDV.Businessunit                  = RD.BusinessUnit);

  /* If the user trying to insert an existing record into the db or
     trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */
  update @ReceiptDetailValidation
  set @vBusinessUnit    = BusinessUnit,
      RecordAction      = dbo.fn_Imports_ResolveAction('RD', RecordAction, ReceiptDetailId, BusinessUnit, null /* UserId */),
      AllowInactiveSKUs = dbo.fn_Controls_GetAsString('IMPORT_ROD', 'AllowInactiveSKUs', 'Y' /*  No */, @vBusinessUnit, '' /* UserId */);

  /* Validations */
  /* If action itself was invalid, then report accordingly */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', null)
  from @ReceiptDetailValidation RDV
  where (RDV.RecordAction = 'X' /* Invalid Action */);

  /* Cannot insert/Update lines to a closed RH */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROH_CannotInsertUpdateClosedReceipt', RDV.ReceiptNumber)
  from @ReceiptDetailValidation RDV
  where (RDV.ReceiptStatus in ('C' /* Closed */, 'X' /* Canceled */));

  update RDV
  set RDV.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_ReceiptLineAlreadyExists', '')
  from @ReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptDetailId, '') <> '') and (RDV.RecordAction = 'E');

  update RDV
  set RDV.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_ReceiptLineDoesNotExist', '')
  from @ReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptDetailId, '') = '') and (RDV.RecordAction = 'E');

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_SKUIsRequired', SKU)
  from @ReceiptDetailValidation RDV
  where (coalesce(RDV.SKU, '') = '') and (RDV.RecordAction not in ('D')); /* SKU is not required to delete - temp fix */

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSKU', SKU)
  from @ReceiptDetailValidation RDV
  where ((coalesce(RDV.SKUId, '') = '') and (coalesce(RDV.SKU, '') <> ''));

  /* If inserting a record ensure SKU is active */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_SKUIsInactive', SKU)
  from @ReceiptDetailValidation RDV
  where (coalesce(RDV.SKU, '') <> '') and
        (RDV.SKUStatus = 'I') and (RDV.AllowInactiveSKUs <> 'Y') and (RDV.RecordAction = 'I' /* Insert */);

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_ReceiptNumberIsRequired', '')
  from @ReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptNumber, '') = '');

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_InvalidReceiptNumber', ReceiptNumber)
  from @ReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptId, '') = '') and (coalesce(RDV.ReceiptNumber, '') <> '');

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_CannotDeleteReceiptDetail', '')
  from @ReceiptDetailValidation RDV
  where ((RDV.QtyReceived > 0) or (RDV.QtyInTransit > 0)) and
        (RDV.RecordAction = 'D');

  /* Valiate the Header Ownership with Detail Ownership on Insert. We don't update Ownership,
     so we are not checking when Action = U */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_InvalidOwnership', '')
  from @ReceiptDetailValidation RDV
  where (RDV.DetailOwnership <> RDV.HeaderOwnership) and (RDV.RecordAction = 'I');

  /* Update RecordAction where there are errors */
  update @ReceiptDetailValidation
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  -- Update @ReceiptDetailValidation
  -- set ResultXML = dbo.fn_XMLNode('Errors', ResultXML)
  -- where (RecordAction = 'E');

  select * from @ReceiptDetailValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateReceiptDetail */

Go
