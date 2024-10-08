/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/24  AY      pr_Reservation_AuditLogging: Capture more info into AuditDetail for reporting (HA-3019)
  2021/03/07  SK      pr_Reservation_AuditLogging: Include pr_AuditTrail_InsertRecords call (HA-2152)
  2021/01/21  SK      pr_Reservation_AuditLogging: Enhanced to include audit activity for To LPNs (HA-1932)
  2020/12/29  RIA     pr_Reservation_AuditLogging: Bug fixes (HA-1790)
  2020/10/05  SK      pr_Reservation_AuditLogging: Added to log audit entries for reservation (CIMSV3-1128)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_AuditLogging') is not null
  drop Procedure pr_Reservation_AuditLogging;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_AuditLogging: This procedure is used to log after reservation
  is done.

  Key notes:
  #FromLPNDetails: This is populated before this call and updated with the reserved quantity
  #ToLPNDetails: This is populated before this call and updated with the reserved quantity

------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_AuditLogging
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vActivityType      TActivityType;

  declare @ttAuditTrail       TAuditTrailInfo,
          @ttAuditDetails     TAuditDetails;

  declare @ttLPNSummary as Table (LPNId         TRecordId,
                                  LPN           TLPN,
                                  WaveId        TRecordId,
                                  WaveNo        TWaveNo,
                                  LocationId    TRecordId,
                                  Location      TLocation,
                                  PalletId      TRecordId,
                                  Pallet        TPallet,
                                  OrderId       TRecordId,
                                  PickTicket    TPickTicket,
                                  Comment       TDescription,
                                  InnerPacks    TInnerPacks,
                                  Quantity      TQuantity,
                                  ActivityType  TActivityType);
begin
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0;

  /* For audit details */
  select * into #AuditDetails from @ttAuditDetails;

  /* Fetch FromLPN Summary which are reserved */
  insert into @ttLPNSummary (ActivityType, LPNId, Quantity)
    select 'Reservation', LPNId, sum(ReservedQty) from #FromLPNDetails group by LPNId having sum(ReservedQty) > 0;

  /* Fetch ToLPN Summary which are activated */
  insert into @ttLPNSummary (ActivityType, LPNId, Quantity)
    select 'Activation', LPNId, sum(Quantity) from #ToLPNDetails where ProcessedFlag = 'A' /* Activated */ group by LPNId;

  /* Update the LPN info to avoid multiple retrieval later */
  update TT
  set LPN        = L.LPN,
      LocationId = L.LocationId,
      Location   = L.Location,
      PalletId   = L.PalletId,
      Pallet     = L.Pallet,
      OrderId    = L.OrderId,
      PickTicket = L.PickTicketNo,
      WaveId     = L.PickBatchId,
      WaveNo     = L.PickBatchNo,
      Comment    = dbo.fn_Messages_BuildDescription('AT_' + ActivityType, 'Units', TT.Quantity, 'LPN', L.LPN, 'Wave', L.PickBatchNo, null, null, null, null, null, null)
  from @ttLPNSummary TT join LPNs L on TT.LPNId = L.LPNId;

  /* Initialize audit trail records for each LPN */
  insert into @ttAuditTrail (EntityType, EntityId, EntityKey, ActivityType, Comment, BusinessUnit, UserId)
    select 'LPN', TT.LPNId, TT.LPN, TT.ActivityType, TT.Comment, @BusinessUnit, @UserId
    from @ttLPNSummary TT;

  /* Initialize audit detail for every From LPN Detail that is reserved */
  insert into #AuditDetails (ActivityType, BusinessUnit, UserId, SKUId, SKU, LPNId, LPN, Quantity,
                             WaveId, WaveNo, LocationId, Location, Comment)
    select TT.ActivityType, @BusinessUnit, @UserId, FLD.SKUId, S.SKU, FLD.LPNId, TT.LPN, FLD.ReservedQty,
           TT.WaveId, TT.WaveNo, TT.LocationId, TT.Location, TT.Comment
    from #FromLPNDetails FLD
      join @ttLPNSummary TT on FLD.LPNId = TT.LPNId
      join SKUs S on FLD.SKUId = S.SKUId
    where (FLD.ReservedQty > 0);

  /* Initialize audit detail for every To LPN Detail that is reserved */
  insert into #AuditDetails (ActivityType, BusinessUnit, UserId, SKUId, SKU, LPNId, LPN, Quantity,
                             WaveId, WaveNo, LocationId, Location, PalletId, Pallet, OrderId, PickTicket, Ownership, Warehouse, Comment)
    select TT.ActivityType, @BusinessUnit, @UserId, TLD.SKUId, S.SKU, TLD.LPNId, TT.LPN, TLD.ReservedQty,
           TT.WaveId, TT.WaveNo, TT.LocationId, TT.Location, TT.PalletId, TT.Pallet, TT.OrderId, TT.PickTicket, TLD.Ownership, TLD.Warehouse, TT.Comment
    from #ToLPNDetails TLD
      join @ttLPNSummary TT on TLD.LPNId = TT.LPNId
      join SKUs S on TLD.SKUId = S.SKUId
    where (TLD.ProcessedFlag = 'A' /* Activated */);

  /* Audit logging - AuditTrail and AuditDetails */
  exec pr_AuditTrail_InsertRecords @ttAuditTrail;

end /* pr_Reservation_AuditLogging */

Go
