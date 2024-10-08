/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/29  VS      pr_Imports_ReceiptDetails, pr_Imports_ReceiptDetails_Validate: Removed table variable for InterfaceLogDetails (HA-3014)
  2021/04/16  SV      pr_Imports_ReceiptDetails_Validate: Initial Version
                      pr_Imports_ReceiptDetails_AddSpecialSKUs, pr_Imports_ReceiptDetails:
                        Replaced temp table with hash table
                      Added pr_Imports_ReceiptHeaders_Validate, pr_Imports_ReceiptHeaders
                        Changes to insert RH and RD from hash tables (OB2-1777)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ReceiptDetails_Validate') is not null
  drop Procedure pr_Imports_ReceiptDetails_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ReceiptDetails_Validate: This proc doesn't require any of the
    parameters. Here the heart of the proc is #ReceiptDetailsImport in which its
    data will be inserted at pr_Imports_ReceiptHeaders and validating its data
    and updating the necessary fields will be taken care here.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ReceiptDetails_Validate
as
  declare @vReturnCode              TInteger,
          @vBusinessUnit            TBusinessUnit,
          @ReceiptDetailValidation  TReceiptDetailValidationType;

begin
  set @vReturnCode = 0;

  if object_id('tempdb..#ttReceiptDetailValidation') is null
    select * into #ttReceiptDetailValidation from @ReceiptDetailValidation;

  insert into #ttReceiptDetailValidation (RecordId, ReceiptDetailId, RecordAction, KeyData, ReceiptId, ReceiptNumber,
                                        SKUId, SKU, SKUStatus, QtyReceived, BusinessUnit,
                                        AllowInactiveSKUs, HostReceiptLine, DetailOwnership, InputXML, HostRecId)
    select RD.RecordId, RD.ReceiptDetailId, RD.RecordAction, RD.ReceiptNumber + '.' + RD.HostReceiptLine, RD.ReceiptId, RD.ReceiptNumber,
           RD.SKUId, RD.SKU, RD.SKUStatus, null, RD.BusinessUnit,
           'Y', RD.HostReceiptLine, RD.Ownership, convert(nvarchar(max), RD.InputXML), RD.HostRecId
    from #ReceiptDetailsImport RD;

  /* Validate BU, Ownership & WH */
  update #ttReceiptDetailValidation
  set ResultXML = coalesce(RDV.ResultXML, '') + dbo.fn_Imports_ValidateInputData('ReceiptDetail', RDV.ReceiptNumber, RDV.ReceiptId, RDV.RecordAction, RDV.BusinessUnit, '@@' /* Owner */, '@@' /* Wh */)
  from #ttReceiptDetailValidation RDV join #ReceiptDetailsImport RD on RDV.RecordId = RD.RecordId;

  /* Get the valid receipt information */
  update RDV
  set RDV.ReceiptId       = R.ReceiptId,
      RDV.ReceiptType     = R.ReceiptType,
      RDV.ReceiptStatus   = R.Status,
      RDV.HeaderOwnership = R.Ownership
  from #ttReceiptDetailValidation RDV
    join ReceiptHeaders R on (RDV.ReceiptNumber = R.ReceiptNumber) and
                             (RDV.Businessunit  = R.BusinessUnit);

  update RDV
  set RDV.ReceiptDetailId = RD.ReceiptDetailId,
      RDV.QtyReceived     = RD.QtyReceived,
      RDV.QtyInTransit    = RD.QtyInTransit
  from  #ttReceiptDetailValidation RDV
    join ReceiptDetails RD on (RDV.ReceiptId                     = RD.ReceiptId) and
                              (coalesce(RDV.HostReceiptLine, '') = coalesce(RD.HostReceiptLine,'')) and
                              (RDV.SKUId                         = RD.SKUId) and
                              (RDV.Businessunit                  = RD.BusinessUnit);

  /* If the user trying to insert an existing record into the db or
     trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */
  update #ttReceiptDetailValidation
  set @vBusinessUnit    = BusinessUnit,
      RecordAction      = dbo.fn_Imports_ResolveAction('RD', RecordAction, ReceiptDetailId, BusinessUnit, null /* UserId */),
      AllowInactiveSKUs = dbo.fn_Controls_GetAsString('IMPORT_ROD', 'AllowInactiveSKUs', 'Y' /*  No */, @vBusinessUnit, '' /* UserId */);

  /* Validations */
  /* If action itself was invalid, then report accordingly */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', null)
  from #ttReceiptDetailValidation RDV
  where (RDV.RecordAction = 'X' /* Invalid Action */);

  /* Cannot insert/Update lines to a closed RH */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROH_CannotInsertUpdateClosedReceipt', RDV.ReceiptNumber)
  from #ttReceiptDetailValidation RDV
  where (RDV.ReceiptStatus in ('C' /* Closed */, 'X' /* Canceled */));

  update RDV
  set RDV.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_ReceiptLineAlreadyExists', '')
  from #ttReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptDetailId, '') <> '') and (RDV.RecordAction = 'E');

  update RDV
  set RDV.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_ReceiptLineDoesNotExist', '')
  from #ttReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptDetailId, '') = '') and (RDV.RecordAction = 'E');

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_SKUIsRequired', SKU)
  from #ttReceiptDetailValidation RDV
  where (coalesce(RDV.SKU, '') = '') and (RDV.RecordAction not in ('D')); /* SKU is not required to delete - temp fix */

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSKU', SKU)
  from #ttReceiptDetailValidation RDV
  where ((coalesce(RDV.SKUId, '') = '') and (coalesce(RDV.SKU, '') <> ''));

  /* If inserting a record ensure SKU is active */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_SKUIsInactive', SKU)
  from #ttReceiptDetailValidation RDV
  where (coalesce(RDV.SKU, '') <> '') and
        (RDV.SKUStatus = 'I') and (RDV.AllowInactiveSKUs <> 'Y') and (RDV.RecordAction = 'I' /* Insert */);

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_ReceiptNumberIsRequired', '')
  from #ttReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptNumber, '') = '');

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_InvalidReceiptNumber', ReceiptNumber)
  from #ttReceiptDetailValidation RDV
  where (coalesce(RDV.ReceiptId, '') = '') and (coalesce(RDV.ReceiptNumber, '') <> '');

  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_CannotDeleteReceiptDetail', '')
  from #ttReceiptDetailValidation RDV
  where ((RDV.QtyReceived > 0) or (RDV.QtyInTransit > 0)) and
        (RDV.RecordAction = 'D');

  /* Valiate the Header Ownership with Detail Ownership on Insert. We don't update Ownership,
     so we are not checking when Action = U */
  update RDV
  set RDV.RecordAction = 'E' /* Error */,
      RDV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROD_InvalidOwnership', '')
  from #ttReceiptDetailValidation RDV
  where (RDV.DetailOwnership <> RDV.HeaderOwnership) and (RDV.RecordAction = 'I');

  /* Update RecordAction where there are errors */
  update #ttReceiptDetailValidation
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update with new action and other fields */
  update RD
  set RD.RecordAction    = RDV.RecordAction,
      RD.ReceiptId       = RDV.ReceiptId,
      RD.SKUId           = RDV.SKUId,
      RD.ReceiptDetailId = RDV.ReceiptDetailId,
      RD.ReceiptType     = RDV.ReceiptType,
      RD.ResultXML       = RDV.ResultXML
  from #ReceiptDetailsImport RD join #ttReceiptDetailValidation RDV on (RD.RecordId = RDV.RecordId);

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ReceiptDetails_Validate */

Go
