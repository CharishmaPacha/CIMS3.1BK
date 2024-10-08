/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/23  VS      pr_Imports_OrderDetails, pr_Imports_OrderDetails_LoadData, pr_Imports_OrderHeaders
                      pr_Imports_OrderHeaders_LoadData, pr_Imports_OrderHeaders_Validate: Made changes to import the OH & OD through ##Tables (CIMSV3-1604)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderHeaders_Validate') is not null
  drop Procedure pr_Imports_OrderHeaders_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_OrderHeaders_Validate:
  Accepts the OrderHeaderImports table type with OrderHeader records to validate
  returns the validation results in a dataset of ImportValidationsType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderHeaders_Validate
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode   TInteger;

  declare @OrderHeaderValidations TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Insert key information in OrderHeader validations table */
  insert into #ImportValidations (RecordId, EntityId, EntityKey, RecordType, SourceSystem, KeyData, EntityStatus, InputXML, BusinessUnit,
                                       RecordAction, HostRecId)
    select OHI.RecordId, OHI.OrderId, OHI.PickTicket, OHI.RecordType, OHI.SourceSystem, OHI.PickTicket, Status, convert(nvarchar(max), OHI.InputXML), OHI.BusinessUnit,
           dbo.fn_Imports_ResolveAction('OH', OHI.RecordAction, OHI.OrderId, OHI.BusinessUnit, null /* UserId */), OHI.HostRecId
    from #OrderHeadersImport OHI;

  /* Validate BU, Ownership & WH */
  update #ImportValidations
  set ResultXML    = coalesce(OHV.ResultXML, '') + dbo.fn_Imports_ValidateInputData('PickTicket', OHI.PickTicket, OHI.OrderId, OHV.RecordAction, OHI.BusinessUnit, OHI.Ownership, OHI.Warehouse)
  from #ImportValidations OHV join #OrderHeadersImport OHI on OHI.RecordId = OHV.RecordId;

  /* If action itself was invalid, then report accordingly */
  update OHV
  set OHV.RecordAction = 'E' /* Error */,
      OHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', OHV.EntityKey)
  from #ImportValidations OHV
  where (OHV.RecordAction = 'X' /* Invalid Action */);

  /* Validate Delete action records - verify the status of the orders for deletions */
  update OHV
  set OHV.RecordAction = 'E' /* Error */,
      OHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'OrderStatusInvalidForDelete', OHV.EntityKey)
  from #ImportValidations OHV
  where (OHV.RecordAction = 'D' /* Delete */) and
        (charindex(OHV.EntityStatus, 'ONWX' /* Downloaded, New, Waved, Cancelled */) = 0);

  /* Validate update action records - verify the status of the orders for updating */
  update OHV
  set OHV.RecordAction = 'E' /* Error */,
      OHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'OrderStatusInvalidForUpdate', OHV.EntityKey)
  from #ImportValidations OHV
  where (OHV.RecordAction = 'U' /* Update */) and
        (charindex(OHV.EntityStatus, 'ONW' /* Downloaded, New, Waved */) = 0);

  /* Validate SourceSystem record */
  update OHV
  set OHV.RecordAction = 'E' /* Error */,
      OHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSourceSystem', OHV.EntityKey)
  from #ImportValidations OHV
  where (dbo.fn_IsValidLookUp('SourceSystem', OHV.SourceSystem, OHV.BusinessUnit, '') is not null);

  /* Validate update action records - verify the status of the orders for updating */
  update OHV
  set OHV.RecordAction = 'E' /* Error */,
      OHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'OrderStatusInvalidForUpdate', OHV.EntityKey)
  from #ImportValidations OHV
  where (OHV.RecordAction in ('A', 'U' /* Authorization, Update */)) and
        (charindex(OHV.EntityStatus, 'SXD' /* Shipped, Cancelled, Completed */) <> 0);

  /* Validate SourceSystem with OrderHeader record */
  update OHV
  set OHV.RecordAction = 'E' /* Error */,
      OHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_CannotChangeSourceSystem', OHV.EntityKey)
  from #ImportValidations OHV
    join OrderHeaders OH on OH.OrderId = OHV.EntityId and OH.SourceSystem <> OHV.SourceSystem
  where OHV.RecordAction in ('U', 'D') /* Update, Delete */

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_OrderHeaders_Validate */

Go
