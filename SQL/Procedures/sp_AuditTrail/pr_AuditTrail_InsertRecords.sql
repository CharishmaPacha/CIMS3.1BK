/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  TK      pr_AuditTrail_InsertRecords & pr_AuditTrail_Insert:
                        Changes to log more info needed into AuditDetails (HA-3031)
  2020/09/29  SK      pr_AuditTrail_InsertRecords: Added functionality to include logging into Audit details (CIMS-2967)
  2014/05/28  NB      Added pr_AuditTrail_InsertRecords
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AuditTrail_InsertRecords') is not null
  drop Procedure pr_AuditTrail_InsertRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_AuditTrail_InsertRecords: When a number of audit comments are to be
    created for different entities, calling pr_AuditTrail_Insert may dampen
    performance (like during import). So, instead an alternate method has been
    introduced to pass in the entity and corresponding comment so that all of
    them would be inserted at once.
------------------------------------------------------------------------------*/
Create Procedure pr_AuditTrail_InsertRecords
  (@AuditTrailInfo TAuditTrailInfo ReadOnly)
as
  declare @ttAuditTrail Table
         (AuditId     TRecordId,
          Comment     varchar(500),
          Primary Key (AuditId),
          Unique      (Comment));
begin
  /* Save the audit trail with the comment */
  insert into AuditTrail(ActivityType, Comment, BusinessUnit, UserId)
  output Inserted.AuditId, Inserted.Comment into @ttAuditTrail
  select distinct ActivityType, Comment, BusinessUnit, UserId
  from @AuditTrailInfo AI;

  /* insert into Audit Details if populated */
  if (object_id('tempdb..#AuditDetails') is not null)
    begin
      /* Caller may not give all associated info, so fetch the associated info */
      update AD
      set LPN        = coalesce(AD.LPNId,      L.LPN),
          InnerPacks = coalesce(AD.InnerPacks, L.InnerPacks),
          Quantity   = coalesce(AD.Quantity,   L.Quantity),
          PalletId   = coalesce(AD.PalletId,   L.PalletId),
          Pallet     = coalesce(AD.Pallet,     L.Pallet),
          LocationId = coalesce(AD.LocationId, L.LocationId),
          Location   = coalesce(AD.Location,   L.Location),
          OrderId    = coalesce(AD.OrderId,    L.OrderId),
          WaveId     = coalesce(AD.WaveId,     L.PickBatchId),
          ReceiverId = coalesce(AD.ReceiverId, L.ReceiverId),
          ReceiptId  = coalesce(AD.ReceiptId,  L.ReceiptId),
          Ownership  = coalesce(AD.Ownership,  L.Ownership),
          Warehouse  = coalesce(AD.Warehouse,  L.DestWarehouse)
        from #AuditDetails AD
          join LPNs L on (AD.LPNId = L.LPNId)
        where (AD.LPNId is not null) and (AD.LPN is null);

      insert into AuditDetails(AuditId, SKUId, SKU, LPNId, LPN, ToLPNId, ToLPN,
                               Ownership, Warehouse, ToWarehouse, PalletId, Pallet,
                               LocationId, Location, ToLocationId, ToLocation,
                               PrevInnerPacks, InnerPacks, PrevQuantity, Quantity,
                               WaveId, OrderId, TaskId, TaskDetailId,
                               ReceiverId, ReceiptId)
        select TAT.AuditId, TAD.SKUId, TAD.SKU, TAD.LPNId, TAD.LPN, TAD.ToLPNId, TAD.ToLPN,
               TAD.Ownership, TAD.Warehouse, TAD.ToWarehouse, TAD.PalletId, TAD.Pallet,
               TAD.LocationId, TAD.Location, TAD.ToLocationId, TAD.ToLocation,
               TAD.PrevInnerPacks, TAD.InnerPacks, TAD.PrevQuantity, TAD.Quantity,
               TAD.WaveId, TAD.OrderId, TAD.TaskId, TAD.TaskDetailId,
               ReceiverId, ReceiptId
        from #AuditDetails TAD
          join @ttAuditTrail TAT on TAD.Comment = TAT.Comment;
    end

  /* Update Audit entities */
  insert into AuditEntities(AuditId, BusinessUnit,
                            EntityType, EntityId, EntityKey, EntityDetails)
    select ATL.AuditId, AI.BusinessUnit,
           AI.EntityType, AI.EntityId, AI.EntityKey, null
    from @AuditTrailInfo AI
          join @ttAuditTrail ATL on (ATL.Comment = AI.Comment);
end; /* pr_AuditTrail_InsertRecords  */

Go
