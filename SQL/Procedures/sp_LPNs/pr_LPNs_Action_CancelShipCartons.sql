/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/28  PKK     pr_LPNs_Action_CancelShipCartons: Changes to Get the canceled LPN Count (HA-2701)
  2021/05/14  AY      pr_LPNs_Action_CancelShipCartons: Code optimization (HA-2734)
  2021/02/26  PK      Added pr_LPNs_Action_CancelShipCartons (HA-2087)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_CancelShipCartons') is not null
  drop Procedure pr_LPNs_Action_CancelShipCartons;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_CancelShipCartons: Cancellation of ShipCartons.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_CancelShipCartons
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @Entity                   TEntity,
          @Action                   TAction,
          @Operation                TOperation,

          @vLPNId                   TRecordId,
          @vLPN                     TLPN,

          @vNumShipLabelsSelected   TCount,
          @vShipLabelsCanceled      TCount,

          @vToLPNValidTypes         TControlValue,
          @vToLPNInvalidStatus      TControlValue,
          @vAutoConfirmWavetypes    TControlValue,
          @xmlInput                 xml,
          @xmlOutput                xml;

  declare @ttLPNDetails             TLPNDetails;

  declare @ttOrders           table (OrderId      TRecordId,
                                     WaveId       TRecordId,

                                     RecordId     TRecordId identity(1,1));

  declare @ttLPNDetailSummary table (KeyValue    TEntityKey,
                                     Quantity    TQuantity);
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode         = 0,
         @vMessageName        = null,
         @vShipLabelsCanceled = 0;

  /* Create temp tables */
  select * into #LPNDetails from @ttLPNDetails;
  alter table #LPNDetails add BulkOrderId int, BulkPickTicket varchar(30);

  /* Read input XML */
  select @Entity = Record.Col.value('Entity[1]',  'TEntity'),
         @Action = Record.Col.value('Action[1]',  'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  option(optimize for(@xmlData = null));

  /* Get the selected LPN Count */
  select @vNumShipLabelsSelected = count(*) from #ttSelectedEntities;

  /* Get Controls */
  select @vToLPNValidTypes      = dbo.fn_Controls_GetAsString('LPNShipCartonCancel', 'ValidToLPNTypes', 'S' /* default: shipcarton */, @BusinessUnit, @UserId),
         @vToLPNInvalidStatus   = dbo.fn_Controls_GetAsString('LPNShipCartonCancel', 'InvalidToLPNStatuses', 'CVOSLI' /* default: consumed/void/lost/shipped/loaded/inactive */, @BusinessUnit, @UserId),
         @vAutoConfirmWavetypes = dbo.fn_Controls_GetAsString('LPNShipCartonCancel', 'AutoConfirmWaves', 'CP,BCP,BPP' /* default: CasePick/BulkCasePick */, @BusinessUnit, @UserId);

  /* delete if other than ship cartons are selected to cancel */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNInActivation_LPNTypeIsInvalid', deleted.EntityKey
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1)
  from #ttSelectedEntities SE
    join LPNs L on (L.LPNId = SE.EntityId)
  where (dbo.fn_IsInList(L.LPNType, @vToLPNValidTypes) = 0);

  /* delete if other than ship cartons are selected to cancel */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNInActivation_InvalidLPNStatus', deleted.EntityKey
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1)
  from #ttSelectedEntities SE
    join LPNs L on (L.LPNId = SE.EntityId)
  where (dbo.fn_IsInList(L.Status, @vToLPNInvalidStatus) > 0);

  /* delete ship cartons that belong to invalid wave types */
  delete from SE
  output 'E', deleted.EntityId, deleted.EntityKey, 'LPNInActivation_WaveTypeIsInvalid', deleted.EntityKey
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1)
  from #ttSelectedEntities SE
    join LPNs L on (L.LPNId = SE.EntityId)
    join Waves W on (L.PickBatchId = W.WaveId)
  where (dbo.fn_IsInList(WaveType, @vAutoConfirmWavetypes) = 0);

  /* Get the LPNs Details that needs to canceled from the selected LPNs list */
  insert into #LPNDetails (LPNId, LPNType, LPNStatus, LPNDetailId, LPNLines, SKUId,
                           InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                           ReceiptId, ReceiptDetailId, OrderId, OrderDetailId,
                           Ownership, Warehouse, Lot, CoO,
                           PalletId, WaveId, WaveNo, LoadId, ShipmentId,
                           InventoryClass1, InventoryClass2, InventoryClass3, ProcessedFlag)
    select LD.LPNId, L.LPNType, L.Status, LD.LPNDetailId, L.NumLines, LD.SKUId,
           LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, LD.ReservedQty,
           LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId,
           L.Ownership, L.DestWarehouse, LD.Lot, LD.CoO,
           L.PalletId, L.PickBatchId, L.PickbatchNo, L.LoadId, L.ShipmentId,
           L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, 'N' /* No */
    from #ttSelectedEntities SE
      join LPNs       L  on L.LPNId  = SE.EntityId
      join LPNDetails LD on LD.LPNId = L.LPNId;

  /* Validations */
  if (not exists (select * from #LPNDetails))
    goto BuildMessage;

  /* Populate XML input for cancelling activated shiplabel LPNs procedure: Driven by LPNs */
  select @xmlInput = dbo.fn_XMLNode('CancelActivatedLPNs', +
                     dbo.fn_XMLNode('LPNType',       'S'/* ShipCarton */) +
                     dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                     dbo.fn_XMLNode('UserId',        @UserId));

  /* Cancel Activated ShipLabels */
  exec pr_Reservation_CancelActivatedLPNs @xmlInput, @xmlOutput output;

BuildMessage:
  /* Get the canceled ship label count */
  select @vShipLabelsCanceled = count(distinct LPNId)
  from #LPNDetails
  where ProcessedFlag = 'Y' /* Yes */;

  /* Build response to display to user */
  exec pr_Messages_BuildActionResponse @Entity, @Action, @vShipLabelsCanceled, @vNumShipLabelsSelected;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_CancelShipCartons */

Go
