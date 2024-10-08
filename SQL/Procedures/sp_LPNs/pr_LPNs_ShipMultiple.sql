/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/06  VS      pr_LPNs_ShipMultiple: Made changes to generate the ShipTransaction for the Transfer Order (HA-3045)
  2021/07/31  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_ShipMultiple:
  2021/04/21  TK      pr_LPNs_ShipMultiple: Load missing values to exports table (HA-2641)
  2021/04/03  TK      pr_LPNs_ShipMultiple: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_ShipMultiple') is not null
  drop Procedure pr_LPNs_ShipMultiple;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_ShipMultiple: All LPNs to be shipped are pass in thru #LPNsToShip.

  The scope of this procedure is to only mark the given LPNs as shipped and
    update the corresponding Order details and generate exports for the LPNs.
    It does not update OH, Shipments or Loads.
    It does inform which of entities have to be recounted Pallets, Locations, Orders

  @Scope: AllOrNone - When it is all or none, then if some of the LPNs cannot be
                      shipped, it wouldn't ship any of the i.e. it either Ships
                      them all or ships none at all.
          Partial   - Ships as many LPNs as can be shipped and then returns the
                      remaining in #ResultMessages.

  #LPNsToShip: To be populated only with EntityId (which is LPNId) and then this
               proc will retrieve all the info based upon that or pass in LPNId
               and all LPN info.

  UpdateOption: This will be used to check what update needs to be done while shipping LPNs
   - 'O': Update Order Status
   - 'W': Update Wave Status
   - 'L': Update Location Counts
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_ShipMultiple
  (@Operation         TOperation = null,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Scope             TOperation = 'Partial')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vProcName          TName,

          @vInTransitWH       TWarehouse,
          @vValidLPNTypes     TControlValue,
          @vValidLPNStatus    TControlValue;

  declare @ttLPNsShipped      TLPNDetails,
          @ttAuditDetails     TAuditDetails,
          @ttAuditTrailInfo   TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create required hash tables */
  select * into #LPNsShipped from @ttLPNsShipped;
  alter table #LPNsShipped add GenerateExports varchar(2) default 'Y';
  select * into #AuditDetails from @ttAuditDetails;

  /* Get the LPN Types to validate the given LPN is able to ship or not */
  select @vValidLPNTypes  = dbo.fn_Controls_GetAsString('Shipping', 'ValidLPNTypes', 'SC' /* ShipCarton, 'Carton' */,  @BusinessUnit, @UserId),
         @vValidLPNStatus = dbo.fn_Controls_GetAsString('Shipping', 'ValidLPNStatus', 'DEL' /* Packed, Staged, 'Loaded' */,  @BusinessUnit, @UserId),
         @vInTransitWH    = dbo.fn_Controls_GetAsString('Exports_ShipTransferOrder', 'InTransitWH', null, @BusinessUnit, @UserId),
         @vProcName       = object_name(@@ProcId);

  /* #LPNsToShip could have been populated with all the info in which case EntityId would be null
     and all the below info is already available. On the other hand, if EntityId is given then we
     assume we just got the entityids and we fetch all the related info of the LPNs */
  update LTS
  set LPNId      = L.LPNId,
      LPN        = L.LPN,
      LPNType    = L.LPNType,
      LPNStatus  = L.Status,
      PalletId   = L.PalletId,
      OrderId    = L.OrderId,
      PickTicket = L.PickTicketNo,
      LoadId     = L.LoadId
  from #LPNsToShip LTS join LPNs L on LTS.EntityId = L.LPNId;

  /* We don't expect caller to give all associated info, so fetch the associated Pallet info */
  update LTS
  set PalletType = P.PalletType
  from #LPNsToShip LTS join Pallets P on LTS.PalletId = P.PalletId;

  /* Update Order and Load info */
  update LTS
  set PickTicket = OH.PickTicket,
      OrderType  = OH.OrderType,
      LoadType   = Load.LoadType
  from #LPNsToShip LTS
    join Loads Load on LTS.LoadId = Load.LoadId
    left outer join OrderHeaders OH on (LTS.OrderId = OH.OrderId);

  /*----------- Validations --------------*/

  /* Eliminate all LPNs that are already shipped */
  delete LTS
  output 'E', 'LPNsToShip_AlreadyShipped', deleted.LPNId, deleted.LPN, deleted.LPNStatus
  into #ResultMessages(MessageType, MessageName, EntityId, EntityKey, Value1)
  from #LPNsToShip LTS
  where (LTS.LPNStatus = 'S' /* Shipped */);

  /* Eliminate all LPNs if their status is not in the list of ValidStatuses to Ship */
  delete LTS
  output 'E', 'LPNsToShip_InvalidStatus', deleted.LPNId, deleted.LPN, deleted.LPNStatus
  into #ResultMessages(MessageType, MessageName, EntityId, EntityKey, Value1)
  from #LPNsToShip LTS
  where (dbo.fn_IsInList(LTS.LPNStatus, @vValidLPNStatus) = 0) and
        (LTS.LPNStatus <> 'S' /* Shipped */); -- Shipped was already convered above with specific error

  /* Eliminate the LPNs if they are of a type that cannot be shipped */
  delete LTS
  output 'E', 'LPNsToShip_InvalidType', deleted.LPNId, deleted.LPN, deleted.LPNType
  into #ResultMessages(MessageType, MessageName, EntityId, EntityKey, Value1)
  from #LPNsToShip LTS
  where (dbo.fn_IsInList(LTS.LPNType, @vValidLPNTypes) = 0);

  /* Delete the LPNs if they are of a type that cannot be shipped */
  delete LTS
  output 'E', 'LPNsToShip_NotOnAnOrder', deleted.LPNId, deleted.LPN, deleted.PickTicket
  into #ResultMessages(MessageType, MessageName, EntityId, EntityKey, Value1)
  from #LPNsToShip LTS
  where (LTS.OrderId = 0);

  /* If all or none and there are errors above, then do not proceed further */
  if (@Scope = 'AllOrNone') and exists (select * from #ResultMessages where MessageType = 'E')
    return (1);

  /* Clear the Location of the LPN, Location will be updated later
     If LPN on Cart, then remove it and clear alternate LPN fields as well */
  update L
  set Status       = 'S' /* Shipped */,
      OnhandStatus = 'U' /* Unavailable */,
      LocationId   = null,
      Location     = null,
      PalletId     = case when charindex(LTS.PalletType, 'CTHF' /* Carts */) > 0 then null else L.PalletId     end,
      Pallet       = case when charindex(LTS.PalletType, 'CTHF' /* Carts */) > 0 then null else L.Pallet       end,
      AlternateLPN = case when charindex(LTS.PalletType, 'CTHF' /* Carts */) > 0 then null else L.AlternateLPN end,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output inserted.LPNId, inserted.LPN, deleted.LocationId, deleted.Location, deleted.PalletId, deleted.Pallet,
         inserted.OrderId, inserted.PickTicketNo, LTS.OrderType, inserted.PickBatchId, inserted.LoadId, inserted.LoadNumber, LTS.LoadType, inserted.ShipmentId
  into #LPNsShipped (LPNId, LPN, LocationId, Location, PalletId, Pallet, OrderId, PickTicket, OrderType, WaveId, LoadId, LoadNumber, LoadType, ShipmentId)
  from LPNs L join #LPNsToShip LTS on L.LPNId = LTS.LPNId;

  /* Update LPN Details */
  update LD
  set OnhandStatus = 'U' /* Unavailable */
  from LPNDetails LD join #LPNsShipped LS on LD.LPNId = LS.LPNId;

  /* Update Order Details */
  ;with LPNShippedUnits(OrderId, OrderDetailId, Quantity) as
  (
    select LD.OrderId, LD.OrderDetailId, sum(LD.Quantity)
    from LPNDetails LD join #LPNsShipped LTS on LD.LPNId = LTS.LPNId
    group by LD.OrderId, LD.OrderDetailId
  )
  update OrderDetails
  set UnitsShipped = UnitsShipped + LSU.Quantity
  from OrderDetails OD
    join LPNShippedUnits LSU on (OD.OrderDetailId = LSU.OrderDetailId) and
                                (OD.OrderId       = LSU.OrderId);

  /* If LPNs are being shipped for a transfer order or shipped thru transfer load then ignore sending exports
     Exports will be sent in Loads_OnShip_Transfers */
  update LS
  set GenerateExports = case when LTS.LoadType = 'Transfer' or LTS.OrderType = 'T' then 'N' else 'Y' end
  from #LPNsShipped LS
    join #LPNsToShip LTS on LS.LPNId = LTS.LPNId;

  /*--------- Exports ---------------*/
  /* Build temp table with the Result set of the procedure */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Generate the Ship Transactions for LPNs, LPN Details, Orders & Order Details */
  insert into #ExportRecords (TransType, TransEntity, TransQty, LPNId, LPNDetailId, OrderId, OrderDetailId, LoadId, ShipmentId, CreatedBy, SortOrder)
    /* Ship Transactions for LPNs */
    select 'Ship', 'LPN', L.Quantity, L.LPNId, null, L.OrderId, null, L.LoadId, L.ShipmentId, @UserId,
           'LPN-' + cast(L.LPNId as varchar) + '-1'
    from #LPNsShipped LS
      join LPNs L on LS.LPNId = L.LPNId
    where GenerateExports = 'Y' /* Yes */
    union all
    /* Ship Transactions for LPN Details */
    select 'Ship', 'LPND', LD.Quantity, LD.LPNId, LD.LPNDetailId, LD.OrderId, LD.OrderDetailId, LS.LoadId, LS.ShipmentId, @UserId,
           'LPN-' + cast(LD.LPNId as varchar) + '-2-' + cast(LD.LPNDetailId as varchar)
    from #LPNsShipped LS
      join LPNDetails LD on LS.LPNId = LD.LPNId
    where GenerateExports = 'Y' /* Yes */

   -- Should order by LPN + TransEntity

  /* Insert Records into Exports table */
  exec pr_Exports_InsertRecords 'Ship', null, @BusinessUnit;

  /*--------- Audit Trail ---------------*/
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, UDF1, UDF2)
    select 'LPN', LPNId, LPN, 'LPNShipped', @BusinessUnit, @UserId, PickTicket, LoadNumber
    from #LPNsShipped;

  /* Build comment */
  update ttAT
  set Comment = dbo.fn_Messages_Build('AT_' + ActivityType, UDF1, UDF2, null, null, null)
  from @ttAuditTrailInfo ttAT;

  /* Log audit details for the LPNs moved */
  insert into #AuditDetails (ActivityType, BusinessUnit, UserId, LPNId, Comment, ToWarehouse)
    select ActivityType, @BusinessUnit, @UserId, LS.LPNId, Comment,
           case when LoadType = 'Transfer' or OrderType = 'T' then @vInTransitWH else null end /* ToWarehouse */ -- Update only for transfer load or any other load with transfer order
    from #LPNsShipped LS
      join @ttAuditTrailInfo ttAT on LS.LPNId = ttAT.EntityId and
                                     ttAT.EntityType = 'LPN';

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /*--------- Recounts ---------------*/
  /* Recount required entities */
  insert into #EntitiesToRecalc (EntityType, EntityId, EntityKey, RecalcOption, Status, ProcedureName, BusinessUnit)
    select distinct 'Pallet', PalletId, Pallet, 'CS' /* Counts & Status */, 'N', @vProcName, @BusinessUnit from #LPNsShipped where PalletId is not null
    union all
    select distinct 'Location', LocationId, Location, '$C' /* defer & Update counts */, 'N', @vProcName, @BusinessUnit from #LPNsShipped where Location is not null;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_ShipMultiple */

Go
