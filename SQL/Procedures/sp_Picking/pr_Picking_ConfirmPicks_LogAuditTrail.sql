/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/27  VS      pr_Picking_ConfirmPicks_LogAuditTrail: Corrected the Wave level Activity (HA-1684)
                      pr_Picking_ConfirmPicks_LogAuditTrail: Code to insert entries into audit details (CIMS-2967)
                      pr_Picking_ConfirmTaskPicks_LogAuditTrail renamed to pr_Picking_ConfirmPicks_LogAuditTrail (S2GCA-469)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_ConfirmPicks_LogAuditTrail') is not null
  drop Procedure pr_Picking_ConfirmPicks_LogAuditTrail;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_ConfirmPicks_LogAuditTrail:
    The intent of this core procedure is when we pick multiple task picks at a time,
    we need to log AT for all entities.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_ConfirmPicks_LogAuditTrail
  (@TaskPicksInfo    TTaskDetailsInfoTable READONLY,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Debug            TFlag = 'N' /* No */)
As
  declare @ttTaskPicksAT   TAuditTrailInfo,
          @ttAuditDetails  TAuditDetails;
begin
  /* Temporary Table */
  select * into #AuditDetails from @ttAuditDetails;

  insert into @ttTaskPicksAT (EntityType, EntityId, EntityKey, ActivityType, Comment, BusinessUnit, UserId)
    /* Wave */
    select distinct 'Wave', PickBatchId, PickBatchNo, ActivityType, ATComment, @BusinessUnit, PickedBy
    from  @TaskPicksInfo
    union
    /* Order */
    select distinct 'PickTicket', OrderId, PickTicket, ActivityType, ATComment, @BusinessUnit, PickedBy
    from  @TaskPicksInfo
    union
    /* From Location */
    select distinct 'Location', FromLocationId, FromLocation, ActivityType, ATComment, @BusinessUnit, PickedBy
    from  @TaskPicksInfo
    union
    /* From Pallet? -- VM_20161111: I think yes. If so, we need to join from lpn pallet if exists and get the details on first */
    --select distinct 'Pallet', --, --, ActivityType, ATComment, @BusinessUnit, @UserId
    --from  @TaskPicksInfo
    --union
    /* From LPN */
    select distinct 'LPN', FromLPNId, FromLPN, ActivityType, ATComment, @BusinessUnit, PickedBy
    from  @TaskPicksInfo
    union
    /* To Pallet */
    select distinct 'Pallet', PalletId, Pallet, ActivityType, ATComment, @BusinessUnit, PickedBy
    from  @TaskPicksInfo
    where (PalletId is not null)
    union
    /* To LPN */
    select distinct 'LPN', ToLPNId, ToLPN, ActivityType, ATComment, @BusinessUnit, PickedBy
    from  @TaskPicksInfo
    where (ToLPN is not null);

  if (@Debug = 'Y' /* Yes */) select 'AT'     Message, * from @ttTaskPicksAT;

  /* Populate the audit detail entries */
  insert into #AuditDetails(ActivityType, Comment, BusinessUnit, UserId,
                            SKUId, SKU, LPNId, LPN, ToLPNId, ToLPN,
                            Ownership, Warehouse, ToWarehouse, PalletId, Pallet,
                            LocationId, Location, ToLocationId, ToLocation,
                            PrevInnerPacks, InnerPacks, PrevQuantity, Quantity,
                            WaveId, OrderId, TaskId, TaskDetailId, ReceiverId, ReceiptId)
    select TPI.ActivityType, TPI.ATComment, @BusinessUnit, PickedBy,
           TPI.SKUId, TPI.SKU, TPI.FromLPNId, TPI.FromLPN, TPI.ToLPNId, TPI.ToLPN,
           TPI.FromLPNOwnership, TPI.FromLPNWarehouse, null, TPI.PalletId, TPI.Pallet,
           TPI.FromLocationId, TPI.FromLocation, null, null,
           null, TPI.TDInnerPacks, null, TPI.TDQuantity,
           TPI.PickBatchId, TPI.OrderId, TPI.TaskId, TPI.TaskDetailId, null, null
    from @TaskPicksInfo TPI;

  /* AT to log on confirmed picks */
  exec pr_AuditTrail_InsertRecords @ttTaskPicksAT;

end /* pr_Picking_ConfirmPicks_LogAuditTrail */

Go
