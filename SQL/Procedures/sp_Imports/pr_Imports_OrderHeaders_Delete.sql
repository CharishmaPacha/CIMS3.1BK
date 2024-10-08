/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/10/15  RV      pr_Imports_OrderHeaders_Delete: Modified procedure to handle as flag changes in pr_LPNs_Unallocate (FB-441).
  2015/01/08  SK      pr_Imports_OrderHeaders_Delete, pr_Imports_AddOrUpdateAddresses: Added procedures
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderHeaders_Delete') is not null
  drop Procedure pr_Imports_OrderHeaders_Delete;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderHeaders_Delete
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderHeaders_Delete
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vRecordId         TRecordId,
          @vOrderId          TRecordId,
          @vPickBatchNo      TPickBatchNo;

  declare @ttOrdersToDelete  TEntityKeysTable,
          @ttLPNsToUpdate    TEntityKeysTable;

begin /* pr_Imports_OrderHeaders_Delete */

  insert into @ttOrdersToDelete
    select OrderId, PickTicket
    from #OrderHeadersImport
    where (RecordAction = 'D' /* Delete */);

  /* Log AT for the orders being deleted */
  insert into #AuditInfo (ActivityType, EntityId, EntityKey, BusinessUnit)
    select distinct 'AT_OrderHeadersDeleted', EntityId, EntityKey, @BusinessUnit
    from @ttOrdersToDelete;

  while (exists(select * from @ttOrdersToDelete))
    begin
      select top 1 @vOrderId  = EntityId,
                   @vRecordId = RecordId
      from @ttOrdersToDelete
      order by RecordId;

      select @vPickBatchNo = null;
      select @vPickBatchNo = PickBatchNo
      from OrderHeaders
      where (OrderId = @vOrderId);

      /* Insert the LPNs which are allocated for the order into a temp table */
      delete from @ttLPNsToUpdate;
      insert into @ttLPNsToUpdate (EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (OrderId = @vOrderId) and
              (Status in ('A'/* Allocated */));

      /* If there are any LPNs which are allocated to the order then unallocate the LPNs */
      if (@@rowcount > 0)
        exec pr_LPNs_Unallocate null /* LPNId */, @ttLPNsToUpdate, 'P'/* PalletPick - Unallocate Pallet */, @BusinessUnit, null /* @ModifiedBy */;

      delete from Orderheaders
      where (OrderId = @vOrderId);

      /* if Order is already on a batch, recalculate batch counts */
      if (coalesce(@vPickbatchNo, '') <> '')
        /* Update the summary fields and counts on the batch */
        exec pr_PickBatch_UpdateCounts @vPickBatchNo;

      /* Delete the record once after it is processed */
      delete from @ttOrdersToDelete where RecordId = @vRecordId;
    end /* while (exists(select * from @ttOrders)) */
end /* pr_Imports_OrderHeaders_Delete */

Go
