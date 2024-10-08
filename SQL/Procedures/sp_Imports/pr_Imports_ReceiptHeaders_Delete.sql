/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/17  BSP     pr_Imports_ReceiptHeaders_Delete: Ported from Onsite (JLCA-438)
                      pr_Imports_ReceiptHeaders_Delete: Added new proc
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ReceiptHeaders_Delete') is not null
  drop Procedure pr_Imports_ReceiptHeaders_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ReceiptHeaders_Delete: Procedure to process the Record actions
  D  - Delete - which deletes only RH and
  DR - Delete Recursive which deletes RH and Intransit LPNs

  if RH cannot be deleted, it just marks it as cancelled and voids the Intransit LPNs
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ReceiptHeaders_Delete
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @RHsProcessed       TEntityValuesTable;
begin /* pr_Imports_ReceiptHeaders_Delete */
  SET NOCOUNT ON;

  /* If the RH does not have anything received or intransit, then proceed with the requested delete */
  delete R
  output Deleted.ReceiptId ,'Receipt', Deleted.ReceiptId, Deleted.ReceiptNumber, 'AT_ReceiptHeaderDeleted', IRH.RecordAction, Deleted.BusinessUnit, IRH.ModifiedBy
  into @RHsProcessed (RecordId, EntityType, EntityId, EntityKey, UDF1, UDF2, UDF3, UDF4)
  from ReceiptHeaders R
    join #ReceiptHeadersImport IRH on (R.ReceiptId = IRH.ReceiptId)
  where (R.UnitsReceived = 0) and (R.UnitsInTransit = 0) and
        (IRH.RecordAction = 'D' /* Delete */);

  /* If the RH cannot be deleted because there are some units received against it, then cancel it only */
  update R
  set R.Status = 'X' /* Canceled */
  output Deleted.ReceiptId,'Receipt', Deleted.ReceiptId, Deleted.ReceiptNumber, 'AT_ReceiptHeaderCanceled', IRH.RecordAction, Deleted.BusinessUnit, IRH.ModifiedBy
  into @RHsProcessed (RecordId, EntityType, EntityId, EntityKey, UDF1, UDF2, UDF3, UDF4)
  from ReceiptHeaders R
    join #ReceiptHeadersImport IRH on (R.ReceiptId = IRH.ReceiptId)
    where (R.UnitsReceived <> 0) and (R.UnitsInTransit = 0) and
          (IRH.RecordAction = 'D' /* Delete */);

  /* Delete Receipts recursively */
  delete R
  output Deleted.ReceiptId, 'Receipt', Deleted.ReceiptId, Deleted.ReceiptNumber, 'AT_ReceiptHeaderDeleted', IRH.RecordAction, Deleted.BusinessUnit, IRH.ModifiedBy
  into @RHsProcessed (RecordId, EntityType, EntityId, EntityKey, UDF1, UDF2, UDF3, UDF4)
  from ReceiptHeaders R
    join #ReceiptHeadersImport IRH on (R.ReceiptId = IRH.ReceiptId)
  where (R.UnitsReceived  = 0) and
        (IRH.RecordAction = 'DR' /* Delete */);

  /*---------------*/
  /* Note: When RHs are deleted, RDs are deleted on cascade, so there is no need to handle that */
  /*---------------*/

  /* Delete the Intransit LPNs if RH was deleted as we have no use for them */
  delete L
  from LPNS L
    join @RHsProcessed RHP on (RHP.EntityId = L.ReceiptId) and (RHP.UDF1 = 'AT_ReceiptHeaderDeleted')
  where (L.Status = 'T' /* InTransit */);

  /* Void the remaining Intransit LPNs if RH was cancelled */
  update L
  set Status = 'V'
  output Inserted.LPNId, 'LPN', Inserted.LPNId, Inserted.LPN, RHP.UDF1, RHP.UDF2, RHP.UDF3, RHP.UDF4
  into @RHsProcessed (RecordId, EntityType, EntityId, EntityKey, UDF1, UDF2, UDF3, UDF4)
  from LPNs L
    join @RHsProcessed RHP on (RHP.EntityId = L.ReceiptId) and (RHP.UDF1 = 'AT_ReceiptHeaderCanceled')
  where (L.Status = 'T' /* In transit */);

  /* If the RH was deleted, then delete the Received Counts of the Receipt as
     there is no foreign key between ReceiptHeaders and ReceivedCounts */
  delete RC
  from ReceivedCounts RC
    join @RHsProcessed RHP on (RHP.EntityId = RC.ReceiptId) and (RHP.UDF1 = 'AT_ReceiptHeaderDeleted')

  /* Capture audit info */
  insert into #ImportRHAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
    select RHP.EntityType, RHP.EntityId, RHP.EntityKey, RHP.UDF1 /* ActivityType */, RHP.UDF2 /* Action */, RHP.UDF3, RHP.UDF4
    from @RHsProcessed RHP

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ReceiptHeaders_Delete */

Go
