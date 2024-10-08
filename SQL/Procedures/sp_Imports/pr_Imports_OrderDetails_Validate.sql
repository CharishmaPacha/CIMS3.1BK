/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails_Validate') is not null
  drop Procedure pr_Imports_OrderDetails_Validate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_OrderDetails_Validate:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails_Validate
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode              TInteger,
          @vOrderId                 TRecordId,
          @vBusinessUnit            TBusinessUnit,
          @vSKUId                   TRecordId,
          @vUpdateValidOrderStatus  TStatus,
          @vDeleteValidOrderStatus  TStatus,
          @vInsertValidOrderStatus  TStatus;

  declare @OrderDetailValidations   TImportValidationType;
begin /* pr_Imports_OrderDetails_Validate */
  select @vReturnCode = 0;
  select top 1 @vBusinessUnit = BusinessUnit from #OrderDetailsImport;

  /* Get control value for valid order status */
  select @vDeleteValidOrderStatus = dbo.fn_Controls_GetAsString('Import_OD', 'DeleteOD_OrderStatusValid', 'O,N' /* Downloaded, New */, @vBusinessUnit, '' /* UserId */),
         @vUpdateValidOrderStatus = dbo.fn_Controls_GetAsString('Import_OD', 'UpdateOD_OrderStatusValid', '', @vBusinessUnit, '' /* UserId */),
         @vInsertValidOrderStatus = dbo.fn_Controls_GetAsString('Import_OD', 'InsertOD_OrderStatusValid', '', @vBusinessUnit, '' /* UserId */);

  /* Insert key information in Order Detail validations table */
  insert into #ImportValidations(RecordId, EntityId, EntityKey, EntityStatus, RecordType, SKU, SKUId, OrderId, PickTicket, HostOrderLine, KeyData, InputXML, BusinessUnit,
                                      RecordAction, HostRecId)
    select ODI.RecordId, ODI.OrderDetailId, ODI.PickTicket, ODI.OHStatus, ODI.RecordType, ODI.SKU, ODI.SKUId, ODI.OrderId, ODI.PickTicket, ODI.HostOrderLine, ODI.PickTicket + '.' + ODI.HostOrderLine, convert(nvarchar(max), ODI.InputXML), ODI.BusinessUnit,
           dbo.fn_Imports_ResolveAction('OD', ODI.RecordAction, ODI.OrderDetailId, ODI.BusinessUnit, null /* UserId */), ODI.HostRecId
    from #OrderDetailsImport ODI;

  /* Update wave information */
  update ODV
  set ODV.WaveId     = W.WaveId,
      ODV.WaveNo     = W.WaveNo,
      ODV.WaveStatus = W.Status
  from #ImportValidations ODV
    left outer join Orderheaders OH on (ODV.OrderId = OH.OrderId)
    left outer join Waves        W  on (OH.PickBatchId = W.WaveId)

  /* If action itself was invalid, then report accordingly */
  update ODV
  set ODV.RecordAction = 'E' /* Error */,
      ODV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', ODV.EntityKey)
  from #ImportValidations ODV
  where (ODV.RecordAction = 'X' /* Invalid Action */);

  /* Validate Business Unit */
  update ODV
  set RecordAction = 'E',
      ResultXML = dbo.fn_Imports_AppendError(ODV.ResultXML, 'BusinessUnitIsRequired', ODV.BusinessUnit)
  from #ImportValidations ODV
  where (coalesce(ODV.BusinessUnit, '') = '');

  update ODV
  set RecordAction = 'E',
      ResultXML    = dbo.fn_Imports_AppendError(ODV.ResultXML, 'Import_InvalidBusinessUnit', ODV.BusinessUnit)
  from #ImportValidations ODV
    left outer join vwBusinessUnits B on (ODV.BusinessUnit = B.BusinessUnit)
  where (coalesce(ODV.BusinessUnit, '') <> '') and (B.BusinessUnit is null);

  /* Validate PickTicket */
  update ODV
  set RecordAction = 'E',
      ResultXML    = dbo.fn_Imports_AppendError(ODV.ResultXML, 'PickTicketIsRequired', ODV.PickTicket)
  from #ImportValidations ODV
  where (coalesce(ODV.PickTicket, '') = '');

  /* Validate OrderId */
  update ODV
  set RecordAction = 'E',
      ResultXML    = dbo.fn_Imports_AppendError(ODV.ResultXML, 'Import_InvalidPickTicket', ODV.PickTicket)
  from #ImportValidations ODV
  where (ODV.OrderId is null) and (ODV.PickTicket is not null);

  /* Validate HostOrderLine */
  update ODV
  set RecordAction = 'E',
      ResultXML    = dbo.fn_Imports_AppendError(ODV.ResultXML, 'HostOrderLineIsRequired', ODV.HostOrderLine)
  from #ImportValidations ODV
  where (coalesce(ODV.HostOrderLine, '') = '');

  /* Order details lines can only be deleted if they are existing in the Order Details table. If
     they do not exist, then we have to ignore those records i.e. mark the those records as processed
     in DE database. To make that happen, we set recordaction to E but with no error message. If
     there is no error message, we mark the record as processed in DE database */
  update ODV
  set ODV.RecordAction = 'E' /* Error */
  from #ImportValidations ODV
  where (ODV.RecordAction = 'IG' /* Ignore */)

  /* Order details can only be deleted if OH is in some statuses, check it */
  update OD
  set OD.RecordAction = 'E',
      OD.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_OD_InvalidStatusToDelete', SKU)
  from #ImportValidations OD
    left outer join Orderheaders OH on (OD.PickTicket = OH.PickTicket)
    left outer join Waves        W  on (OH.PickBatchId = W.WaveId)
  where (OD.RecordAction in ('D' /* Delete */) and
        ((dbo.fn_IsInList(EntityStatus, @vDeleteValidOrderStatus) = 0) or
        (coalesce(W.Status, '') not in ('N' /* New */, '' /* Empty */))));

  /* Order details can only be Inserted if OH is in some statuses, check it */
  update OD
  set OD.RecordAction = 'E',
      OD.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_OD_InvalidStatusToInsert', SKU)
  from #ImportValidations OD
  where (OD.RecordAction in ('I' /* Insert */) and
        ((dbo.fn_IsInList(EntityStatus, @vInsertValidOrderStatus) = 0) or
        (coalesce(WaveStatus, '') not in ('N' /* New */, '' /* Empty */))));

  /* Order details can only be updated if OH is in some statuses, check it */
  update OD
  set OD.RecordAction = 'E',
      OD.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_OD_InvalidStatusToUpdate', SKU)
  from #ImportValidations OD
  where (OD.RecordAction in ('U' /* Update */)) and
        (dbo.fn_IsInList(EntityStatus, @vUpdateValidOrderStatus) = 0);

  /* Order details can only be updated if Wave status is New */
  update OD
  set OD.RecordAction = 'E',
      OD.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_OD_InvalidStatusToUpdate', SKU)
  from #ImportValidations OD
  where (OD.RecordAction in ('U' /* Update */)) and
        (coalesce(WaveStatus, '') not in ('N' /* New */, '' /* Empty */));

  /* Validate SKU - Do not require SKU on Delete */
  update ODV
  set RecordAction = 'E',
      ResultXML    = dbo.fn_Imports_AppendError(ODV.ResultXML, 'SKUIsRequired', ODV.SKU)
  from #ImportValidations ODV
  where (coalesce(ODV.SKU, '') = '') and (ODV.RecordAction <> 'D' /* Delete */);

  update #ImportValidations
  set RecordAction = 'E',
      ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSKU', SKU)
  where (coalesce(SKU, '') <> '') and (SKUId is null) and
        (RecordAction not in ('E', 'D' /* Error/Delete */));

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_OrderDetails_Validate */

Go
