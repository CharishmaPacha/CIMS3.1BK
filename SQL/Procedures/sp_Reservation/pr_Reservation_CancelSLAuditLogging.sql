/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/24  VS      pr_Reservation_CancelShipCartons, pr_Reservation_CancelSLAuditLogging: UnAllocate the ShipCarton if BulkOrder doesn't associate with it (HA-3295)
  2021/10/27  MOG     pr_Reservation_CancelSLAuditLogging:log pallet and load info in AT (HA-2830)
                      pr_Reservation_CancelSLAuditLogging (HA-2087)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_CancelSLAuditLogging') is not null
  drop Procedure pr_Reservation_CancelSLAuditLogging;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_CancelSLAuditLogging: This procedure is used to log after reservation
  is done.

  Key notes:
  #FromLPNDetails: This is populated before this call and updated with the reserved quantity
  #ToLPNDetails: This is populated before this call and updated with the reserved quantity

------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_CancelSLAuditLogging
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vActivityType      TActivityType;

  declare @ttAuditTrail       TAuditTrailInfo,
          @ttAuditDetails     TAuditDetails;

  declare @ttLPNSummary as Table (LPNId          TRecordId,
                                  LPN            TLPN,
                                  OrderId        TRecordId,
                                  PickTicket     TPickTicket,
                                  BulkOrderId    TRecordId,
                                  BulkPickTicket TPickTicket,
                                  WaveId         TRecordId,
                                  WaveNo         TWaveNo,
                                  LocationId     TRecordId,
                                  Location       TLocation,
                                  Comment        TVarchar,
                                  Quantity       TQuantity,
                                  ActivityType   TActivityType);
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0;

  /* For audit details */
  select * into #AuditDetails from @ttAuditDetails;

  /* Fetch LPN Summary which are inactiavted and reserved against the Bulk Order */
  insert into @ttLPNSummary (ActivityType, LPNId, OrderId, PickTicket, BulkOrderId, BulkPickTicket, Quantity)
    select 'CancelShipLabel', LD.LPNId, LD.OrderId, OH.PickTicket, BPT.OrderId, BPT.PickTicket, sum(Quantity)
    from #LPNDetails LD
      left outer join OrderHeaders OH on (LD.OrderId = OH.OrderId) and
                                         (OH.OrderType not in ('B' /* Bulk */))
      left outer join OrderHeaders BPT on (LD.BulkOrderId = BPT.OrderId) and
                                          (BPT.OrderType = 'B' /* Bulk */)
    where (ProcessedFlag = 'C' /* Canceled */)
    group by LD.LPNId, LD.OrderId, OH.PickTicket, BPT.OrderId, BPT.PickTicket;

  /* Update the LPN info to avoid multiple retrieval later */
  update TT
  set LPN            = L.LPN,
      LocationId     = L.LocationId,
      Location       = L.Location,
      WaveId         = L.PickBatchId,
      WaveNo         = L.PickBatchNo,
      Comment        = dbo.fn_Messages_BuildDescription('AT_' + ActivityType, 'Units', TT.Quantity, 'LPN', L.LPN, 'Wave', L.PickBatchNo, 'PickTicket', TT.PickTicket, 'BulkOrder', TT.BulkPickTicket, null, null)
  from @ttLPNSummary TT join LPNs L on TT.LPNId = L.LPNId;

  /* Initialize audit trail records for each LPN */
  insert into @ttAuditTrail (EntityType, EntityId, EntityKey, ActivityType, Comment, BusinessUnit, UserId)
    select 'LPN', TT.LPNId, TT.LPN, TT.ActivityType, TT.Comment, @BusinessUnit, @UserId from @ttLPNSummary TT
    union
    select 'PickTicket', TT.OrderId, TT.PickTicket, TT.ActivityType, TT.Comment, @BusinessUnit, @UserId from @ttLPNSummary TT
    union
    select 'BulkPT', TT.BulkOrderId, TT.BulkPickTicket, TT.ActivityType, TT.Comment, @BusinessUnit, @UserId from @ttLPNSummary TT;

  /* Initialize audit detail for every To LPN Detail that is reserved */
  insert into #AuditDetails (ActivityType, BusinessUnit, UserId, SKUId, SKU, LPNId, LPN, Quantity,
                             OrderId, PickTicket, WaveId, WaveNo, LocationId, Location, Comment)
    select TT.ActivityType, @BusinessUnit, @UserId, LD.SKUId, S.SKU, LD.LPNId, TT.LPN, LD.Quantity,
           TT.OrderId, TT.PickTicket, TT.WaveId, TT.WaveNo, TT.LocationId, TT.Location, TT.Comment
    from #LPNDetails LD
      join @ttLPNSummary TT on LD.LPNId = TT.LPNId
      join SKUs S on LD.SKUId = S.SKUId
    where (LD.ProcessedFlag = 'C' /* Canceled */)
    union
    select TT.ActivityType, @BusinessUnit, @UserId, LD.SKUId, S.SKU, LD.LPNId, TT.LPN, LD.Quantity,
           TT.BulkOrderId, TT.BulkPickTicket, TT.WaveId, TT.WaveNo, TT.LocationId, TT.Location, TT.Comment
    from #LPNDetails LD
      join @ttLPNSummary TT on LD.LPNId = TT.LPNId
      join SKUs S on LD.SKUId = S.SKUId
    where (LD.ProcessedFlag = 'C' /* Canceled */);

  /* Audit logging - AuditTrail and AuditDetails */
  exec pr_AuditTrail_InsertRecords @ttAuditTrail;

end /* pr_Reservation_CancelSLAuditLogging */

Go
