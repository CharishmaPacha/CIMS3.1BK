/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/06  VS      pr_OrderHeaders_OnChangeShipDetails: Update the Loadid as 0 for NewShipments (HA-3974)
  2022/08/07  AY      pr_OrderHeaders_OnChangeShipDetails: Corrected temp table name (OBV3-1008)
  2022/04/08  RKC     pr_OrderHeaders_OnChangeShipDetails: Made changes to delete the BoLs once orders ShipVia changed (OBV3-362)
  2021/11/19  AY      pr_OrderHeaders_OnChangeShipDetails: Changed params for pr_Shipping_ShipLabelsInsert (HA-3287)
  2021/08/06  OK      pr_OrderHeaders_OnChangeShipDetails: Changes to use new proc pr_PrintJobs_EvaluatePrintStatus
  2021/05/21  TK      pr_OrderHeaders_OnChangeShipDetails: Update shipments even if Order ship via isn't a small package (HA-2822)
  2021/04/15  TK      pr_OrderHeaders_OnChangeShipDetails: Create new shipments when ship via on the order is changed (HA-2416)
  2021/03/17  PK/YJ   pr_OrderHeaders_OnChangeShipDetails: Ported changes done by Pavan (HA-2306)
  2021/03/16  RKC     pr_OrderHeaders_OnChangeShipDetails: Made changes to avoid the unique constraint (HA-2301)
  2021/02/04  VS      pr_OrderHeaders_VoidTempLabels, pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_OnChangeShipDetails,
  2020/12/17  VS      pr_OrderHeaders_OnChangeShipDetails:update proper printstaus on Task when shipvia is modified (CIMSV3-1283)
  2020/07/03  RV      pr_OrderHeaders_OnChangeShipDetails:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_OnChangeShipDetails') is not null
  drop Procedure pr_OrderHeaders_OnChangeShipDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_OnChangeShipDetails: When ShipVia or other related info
   has changed on the orders and small package labels were already generated, they
   may have to be done again. This procedure evaluates and takes care of that.

 Input is #OrdersShipDetailsModified (defined in pr_OrderHeaders_Action_ModifyShipDetails)
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_OnChangeShipDetails
  (@BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @Message        TMessage output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,
          @vRecordId                  TRecordId,

          @vOrderId                   TRecordId,
          @vOrderShipmentId           TRecordId,
          @vOrderLoadId               TRecordId,
          @vShipmentNumOrders         TCount,
          @vNewShipVia                TShipVia,

          @vShipmentShipVia           TShipVia,
          @vOrderShipVia              TShipVia,
          @vIsCarrierChanged          TFlag,
          @vIsOldCarrierSmallPackage  TFlag,
          @vIsNewCarrierSmallPackage  TFlag;

  declare @ttTasksToEvaluate          TEntityKeysTable,
          @ttLoadsToRecount           TEntityKeysTable,
          @ttPalletsToRecount         TRecountKeysTable,
          @ttLPNsToLoad               TLPNsToLoad,
          @ttShipments                TRecountKeysTable,
          @ttShipmentsToRecount       TEntityKeysTable,
          @ttDeletedShipments         TEntityKeysTable,
          @ttPrintEntitiesToEvaluate  TPrintEntities;

begin
  SET NOCOUNT ON;

  select @vRecordId                 = 0,
         @vIsCarrierChanged         = 'N',
         @vIsOldCarrierSmallPackage = 'N',
         @vIsNewCarrierSmallPackage = 'N';

  /* Return if there is no input to act upon */
  if (object_id('tempdb..#OrdersShipDetailsModified') is null) return;
  if not exists (select * from #OrdersShipDetailsModified) return;
  select * into #LPNsToLoad from @ttLPNsToLoad

  /* Prepare hash table to evaluate Print status */
  if (object_id('tempdb..#ttEntitiesToEvaluate') is null)
    select * into #ttEntitiesToEvaluate from @ttPrintEntitiesToEvaluate;

  /* Get the shipments of the orders for which ship via is changed */
  select LoadId, LoadNumber, OS.OrderId, OS.PickTicket, ShipmentId, BoLId
  into #OrderShipments
  from vwOrderShipments OS
    join #OrdersShipDetailsModified ttO on (ttO.OrderId = OS.OrderId)
  where (OldShipVia <> NewShipVia);

  update ttOSD
  set ttOSD.IsOldShipViaSPG = OSV.IsSmallPackageCarrier,
      ttOSD.IsNewShipViaSPG = NSV.IsSmallPackageCarrier
  from #OrdersShipDetailsModified ttOSD
    left join ShipVias OSV on (OSV.ShipVia = ttOSD.OldShipVia)
    left join ShipVias NSV on (NSV.ShipVia = ttOSD.NewShipVia);

  /* Delete records if there is no change in ShipVia, BillToAccount or FreightTerms */
  delete from #OrdersShipDetailsModified
  where (OldShipVia       = NewShipVia) and
        (OldBillToAccount = NewBillToAccount) and
        (OldFreightTerms  = NewFreightTerms);

  /* delete if it was not SPG - Small Package shipment */
  delete from #OrdersShipDetailsModified where (IsOldShipViaSPG = 'N') and (IsNewShipViaSPG = 'N');

  if not exists(select * from #OrdersShipDetailsModified where (IsOldShipViaSPG = 'Y') or (IsNewShipViaSPG = 'Y'))
    goto UpdateShipments;

  /* When ShipVia changed from UPS/FEDEX/USPS Orders, we need to void the old labels
     as they are no longer applicable */
  while (exists(select * from #OrdersShipDetailsModified where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId                 = OM.RecordId,
                   @vOrderId                  = OM.OrderId,
                   @vNewShipVia               = OM.NewShipVia,
                   @vOrderShipVia             = OM.NewShipVia,
                   @vIsOldCarrierSmallPackage = OM.IsOldShipViaSPG,
                   @vIsNewCarrierSmallPackage = OM.IsNewShipViaSPG,
                   @vIsCarrierChanged         = case when (coalesce(OM.OldShipVia, '') <> coalesce(OM.NewShipvia, '')) then 'Y'
                                                     else 'N' end
      from #OrdersShipDetailsModified OM
      where (OM.RecordId > @vRecordId)
      order by OM.RecordId;

      if (@vIsOldCarrierSmallPackage = 'Y' /* Yes */)
        begin
          exec pr_Shipping_VoidShipLabels @vOrderId,
                                          null /* LPNId */,
                                          default,
                                          @BusinessUnit,
                                          'N' /* RegenerateLabel - No */,
                                          @vMessage output;

          /* Need to clear the temp table */
          delete from @ttTasksToEvaluate;
          delete from #ttEntitiesToEvaluate;

          /* Get the Task to update proper PrintStatus */
          insert into @ttTasksToEvaluate(EntityId)
            select distinct TD.TaskId
            from TaskDetails TD
              left outer join @ttTasksToEvaluate TE on (TD.TaskId = TE.EntityId)
            where (TD.OrderId = @vOrderId) and
                  (Status <> 'X') and
                  (TE.EntityId is null); /* VS: We need to consider completed Status PickTasks because user may pick before change ShipVia */

          insert into #ttEntitiesToEvaluate(EntityId, EntityType)
            select EntityId, 'Task'
            from @ttTasksToEvaluate;

          /* Evaluate print dependencies on Wave and Tasks */
          exec pr_PrintJobs_EvaluatePrintStatus @BusinessUnit, @UserId;
        end

      if (@vIsNewCarrierSmallPackage = 'Y')
        exec pr_Shipping_ShipLabelsInsert 'Orders', 'OnChangeShipDetails', @vOrderId, null /* LPN Id */, @BusinessUnit, @UserId;
    end

UpdateShipments:
  /* If there are shipments already created for the orders then we need to delete the existing one and
     create new shipment with new ship via */
  if not exists (select * from #OrderShipments) goto ExitHandler;

  /****************  Delete old shipments with old ship via  ******************/
  /* Delete order shipments as they are removed from Load */
  delete OS
  output deleted.ShipmentId into @ttShipments (EntityId)
  from OrderShipments OS
    join #OrderShipments ttOS on (ttOS.OrderId = OS.OrderId) and
                                 (ttOS.ShipmentId = OS.ShipmentId)
    join Shipments S on (ttOS.ShipmentId = S.ShipmentId) and
                        (S.Status <> 'S' /* Shipped */);

  /* If there are no orders associated with the shipments then delete them or they may be recounted later */
  delete S
  output deleted.ShipmentId into @ttDeletedShipments(EntityId)
  from Shipments S
    join @ttShipments ttS on S.ShipmentId = ttS.EntityId
    left outer join OrderShipments OS on OS.ShipmentId = S.ShipmentId
  where (OS.RecordId is null) and
        (S.Status <> 'S' /* Shipped */);

  /* Once Shipments are deleted, delete associated BoL's as well */
  delete B
  from BoLs B
    join @ttDeletedShipments DS on (B.ShipmentId = DS.EntityId);

  /****************  Create new shipments with new ship via  ******************/
  /* Get the required info that is needed to create new shipments */
  insert into #LPNsToLoad (LPNId, LPN, PalletId, Pallet, OrderId,  OrderType, DesiredShipDate, FreightTerms,
                           LoadId, LoadNumber, ShipmentId, SoldToId, ShipToId, ShipVia, ShipFrom)
    select L.LPNId, L.LPN, L.PalletId, L.Pallet, OH.OrderId, OH.OrderType, OH.DesiredShipDate, coalesce(OH.FreightTerms, 'PREPAID'),
           coalesce(L.LoadId, OH.LoadId, 0), coalesce(L.LoadNumber, OH.LoadNumber), 0 /* ShipmentId */, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipFrom
    from #OrderShipments OS
      join OrderHeaders OH  on OH.OrderId = OS.OrderId
      left outer join LPNs L on OH.OrderId = L.OrderId   -- by this time LPNs may or may not be associated with orders, so use order into to create new shipments

  /* Invoke procedure that creates shipments for the LPNs/Orders that is cleared above */
  if exists (select * from #LPNsToLoad where ShipmentId = 0)
    exec pr_Shipment_CreateShipments null, 'ChangeOrderShipVia', @BusinessUnit, @UserId;

  /* Update latest ShipmentId on the LPNs */
  update L
  set L.ShipmentId = LTL.ShipmentId
  output inserted.ShipmentId into @ttShipments (EntityId)
  from LPNs L
    join #LPNsToLoad LTL on L.LPNId = LTL.LPNId;

  /* Recount Pallets */
  insert into @ttPalletsToRecount (EntityId, EntityKey) select distinct PalletId, Pallet from #LPNsToLoad;
  exec pr_Pallets_Recalculate @ttPalletsToRecount, 'C', @BusinessUnit, @UserId;

  /* Recount Shipments */
  insert into @ttShipmentsToRecount (EntityId)
    select distinct ShipmentId from @ttShipments ttS join Shipments S on (S.ShipmentId = ttS.EntityId);  -- Reason for join Shipments is that some Shipments may be deleted above so recount the Shipments that are available

  exec pr_Shipment_Recalculate @ttShipmentsToRecount, default, @BusinessUnit, @UserId;;

  /* Load recount - defer */
  insert into @ttLoadsToRecount(EntityId) select distinct LoadId from #OrderShipments;
  exec pr_Load_Recalculate @ttLoadsToRecount;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_OnChangeShipDetails */

Go
