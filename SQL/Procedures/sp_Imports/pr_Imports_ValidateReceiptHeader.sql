/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/27  MS      pr_Imports_ReceiptHeaders, fn_Imports_ResolveAction: Made changes to delete records recursively (CIMSV3-1146)
                      pr_Imports_ReceiptHeaders_Delete: Added new proc
                      pr_Imports_ValidateReceiptHeader: Changes to allow reopening the receipt
  2019/01/23  VM      pr_Imports_ValidateReceiptHeader & pr_Imports_ValidateReceiptDetail:
  2018/10/23  VS      pr_Imports_ValidateReceiptHeader, pr_Imports_ValidateOrderHeader: Do not want to update or delete a PO
                      pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader,
                      pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader: Added and accessed HostRecId (CIMSDE-17)
  2016/07/04  TK      pr_Imports_ValidateReceiptHeader: changes made to return proper KeyData (HPI-231)
                      pr_Imports_ValidateReceiptHeader: Fix to read RecordType correctly from input table
  2015/10/20  VS      pr_Imports_ValidateReceiptHeader/ValidationOrderdetails: Modified Procedure to show error messgaes (CIMS-603)
  2014/12/01  SK      pr_Imports_ImportRecords, pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader:
  2013/09/26  VM      pr_Imports_ValidateReceiptHeader, pr_Imports_ValidateReceiptDetail:
                      pr_Imports_OrderHeaders,pr_Imports_OrderDetails,pr_Imports_ValidateReceiptHeader
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateReceiptHeader') is not null
  drop Procedure pr_Imports_ValidateReceiptHeader;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateReceiptHeader:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateReceiptHeader
  (@ReceiptHeaderImport  TReceiptHeaderImportType  READONLY)
as
  declare @vReturnCode              TInteger,
          @ReceiptHeaderValidation  TImportValidationType;
begin
  set @vReturnCode = 0;

  /* If the user trying to insert an existing record into the db or
     trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */
  insert into @ReceiptHeaderValidation (RecordId, EntityId, EntityKey, RecordType, KeyData, EntityStatus, InputXML,
                                        SourceSystem, BusinessUnit, RecordAction, HostRecId)
    select  RH.RecordId, RH.ReceiptId, RH.ReceiptNumber, RH.RecordType, RH.ReceiptNumber, null /* To be used to fetch Status */, convert(nvarchar(max), RH.InputXML),
            RH.SourceSystem, RH.BusinessUnit,
            dbo.fn_Imports_ResolveAction('RH', RH.RecordAction, RH.ReceiptId, RH.BusinessUnit, null /* UserId */), RH.HostRecId
    from #ReceiptHeadersImport RH;

  /* Validate BU, Ownership & WH */
  update @ReceiptHeaderValidation
  set EntityStatus = RH.Status,
      ResultXML    = coalesce(RV.ResultXML, '') + dbo.fn_Imports_ValidateInputData('ReceiptOrder', RH.ReceiptNumber, RH.ReceiptId, RV.RecordAction, RH.BusinessUnit, RH.Ownership, RH.Warehouse)
  from @ReceiptHeaderValidation RV join @ReceiptHeaderImport RH on RH.RecordId = RV.RecordId;

  /* If action itself was invalid, then report accordingly */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', RV.EntityKey)
  from @ReceiptHeaderValidation RV
  where (RV.RecordAction = 'X' /* Invalid Action */);

  /* Cannot delete RH if something has been received against it */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROH_CannotDeleteReceipt', RV.EntityKey)
  from @ReceiptHeaderValidation RV
  where (RV.RecordAction = 'D' /* Delete */) and (RV.EntityStatus not in ('I' /* Initial */, 'T' /* InTransit*/));

  /* Cannot insert/Update a closed/canceled RH */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROH_CannotInsertUpdateClosedReceipt', RV.EntityKey)
  from @ReceiptHeaderValidation RV
  where (RV.EntityStatus in ('C' /* Closed */, 'X' /* Canceled */)) and
        (RV.RecordAction <> 'R' /* ReOpen */);

  /* Validate SourceSystem record */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSourceSystem', RV.EntityKey)
  from  @ReceiptHeaderValidation RV
  where (dbo.fn_IsValidLookUp('SourceSystem', RV.SourceSystem, RV.BusinessUnit, '') is not null);

  /* Validate SourceSystem with Receipt record */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_CannotChangeSourceSystem', RV.EntityKey)
  from @ReceiptHeaderValidation RV
    join ReceiptHeaders RH on RH.ReceiptId = RV.EntityId and RH.SourceSystem <> RV.SourceSystem
  where RV.RecordAction in ('U', 'D' /* Update, Delete */);

  /* Update RecordAction if there are errors */
  update @ReceiptHeaderValidation
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  -- Update @ReceiptHeaderValidation
  -- set ResultXML = dbo.fn_XMLNode('Errors', ResultXML)
  -- where (RecordAction = 'E');

  select * from @ReceiptHeaderValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateReceiptHeader */

Go
