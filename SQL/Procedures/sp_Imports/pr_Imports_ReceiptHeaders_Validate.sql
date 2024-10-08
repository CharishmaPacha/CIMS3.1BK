/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/10  SV      pr_Imports_ReceiptHeaders_Validate: Changes to validate Warehouse if not passed (FBV3-181)
  2021/06/30  RKC     pr_Imports_ReceiptHeaders, pr_Imports_ReceiptHeaders_Validate, pr_InterfaceLog_AddDetails: Made changes to Replaced temp table with hash table (HA-2933)
  2021/04/16  SV      pr_Imports_ReceiptDetails_Validate: Initial Version
                      pr_Imports_ReceiptDetails_AddSpecialSKUs, pr_Imports_ReceiptDetails:
                        Replaced temp table with hash table
                      Added pr_Imports_ReceiptHeaders_Validate, pr_Imports_ReceiptHeaders
                        Changes to insert RH and RD from hash tables (OB2-1777)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ReceiptHeaders_Validate') is not null
  drop Procedure pr_Imports_ReceiptHeaders_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ReceiptHeaders_Validate: This proc doesn't require any of the
    parameters. Here the heart of the proc is #ReceiptHeadersImport in which its
    data will be inserted at pr_Imports_ReceiptHeaders and validating its data
    and updating the necessary fields will be taken care here.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ReceiptHeaders_Validate
as
  declare @vReturnCode              TInteger;

begin
  set @vReturnCode = 0;

  /* If the user trying to insert an existing record into the db or trying to update or delete the non
     existing record then we need to resolve what to do based upon control value */
  insert into #ImportValidations (RecordId, EntityId, EntityKey, RecordType, KeyData, EntityStatus, InputXML,
                                        SourceSystem, BusinessUnit, RecordAction, HostRecId)
    select  RH.RecordId, RH.ReceiptId, RH.ReceiptNumber, RH.RecordType, RH.ReceiptNumber, null /* To be used to fetch Status */, convert(nvarchar(max), RH.InputXML),
            RH.SourceSystem, RH.BusinessUnit,
            dbo.fn_Imports_ResolveAction('RH', RH.RecordAction, RH.ReceiptId, RH.BusinessUnit, null /* UserId */), RH.HostRecId
    from #ReceiptHeadersImport RH;

  /* Validate BU, Ownership & WH */
  update #ImportValidations
  set EntityStatus = RH.Status,
      ResultXML    = coalesce(RV.ResultXML, '') + dbo.fn_Imports_ValidateInputData('ReceiptOrder', RH.ReceiptNumber, RH.ReceiptId, RV.RecordAction, RH.BusinessUnit, RH.Ownership, RH.Warehouse)
  from #ImportValidations RV join #ReceiptHeadersImport RH on RH.RecordId = RV.RecordId;

  /* If action itself was invalid, then report accordingly */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', RV.EntityKey)
  from #ImportValidations RV
  where (RV.RecordAction = 'X' /* Invalid Action */);

  /* Cannot delete RH if something has been received against it */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROH_CannotDeleteReceipt', RV.EntityKey)
  from #ImportValidations RV
  where (RV.RecordAction = 'D' /* Delete */) and (RV.EntityStatus not in ('I' /* Initial */, 'T' /* InTransit*/));

  /* Cannot insert/Update a closed/canceled RH */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ROH_CannotInsertUpdateClosedReceipt', RV.EntityKey)
  from #ImportValidations RV
  where (RV.EntityStatus in ('C' /* Closed */, 'X' /* Canceled */)) and
        (RV.RecordAction <> 'R' /* ReOpen */);

  /* Validate SourceSystem record */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSourceSystem', RV.EntityKey)
  from #ImportValidations RV
  where (dbo.fn_IsValidLookUp('SourceSystem', RV.SourceSystem, RV.BusinessUnit, '') is not null);

  /* Validate SourceSystem with Receipt record */
  update RV
  set RV.RecordAction = 'E' /* Error */,
      RV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_CannotChangeSourceSystem', RV.EntityKey)
  from #ImportValidations RV
    join ReceiptHeaders RH on RH.ReceiptId = RV.EntityId and RH.SourceSystem <> RV.SourceSystem
  where RV.RecordAction in ('U', 'D' /* Update, Delete */);

  /* Update new RecordAction if there are errors */
  update #ImportValidations
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update with new action */
  update RH
  set RH.RecordAction = RHV.RecordAction
  from #ReceiptHeadersImport RH join #ImportValidations RHV on (RH.RecordId = RHV.RecordId);

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ReceiptHeaders_Validate */

Go
