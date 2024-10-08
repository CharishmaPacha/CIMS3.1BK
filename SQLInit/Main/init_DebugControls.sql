/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/11  SK      Added pr_Loads_Action_ActivateShipCartons (HA-2808)
  2021/06/06  TK      Added pr_Packing_ClosePackage (BK-348)
  2021/04/17  SK      Included pr_LPNs_Action_ActivateShipCartons (HA-2642)
  2021/04/02  SK      Included reservation & activation procedures (HA-2070)
  2021/03/17  SK      Included pr_LPNs_CreateLPNs (HA-2315)
  2020/12/02  SK      pr_Entities_ExecuteAction_V3: Added Input and Error controls to be logged by default (HA-1717)
  2020/10/30  PK/AY   Included pr_Content_BuildDataStream (HA-1650)
  2020/10/12  RBV     Re-Named pr_Shipping_GetShippingManifestData to pr_Shipping_ShipManifest_GetData (HA-1548)
  2020/07/09  SK      Included pr_Reservation_AutoActivation (HA-906)
  2020/05/28  RV      Included pr_Printing_GetNextPrintJobToProcess (CIMSV3-948)
  2020/04/21  VM      Included pr_Printing_EntityPrintRequest (HA-249)
  2019/04/13  AJ      Included pr_Shipping_AddOrUpdateRoutingRules (S2G-1255)
  2018/12/20  MJ      Change related to DebugOptions for pr_LPNDetails_ConfirmReservation migrated from Prod Onsite (S2G-727)
  2018/10/05  VM      Included pr_Rules_Process (S2GCA-GoLive)
  2018/03/26  OK      Included pr_LPNDetails_Unallocate, pr_Tasks_Cancel (S2G-???)
  2018/03/25  AY      Added cubing procedures
  2018/03/21  VM      Cleanup and Enabled set to N as default (S2G-455)
  2018/03/20  VM      Included pr_Tasks_UpdateDependencies, pr_TaskDetails_ComputeDependencies,
                               pr_LPNs_RecomputeWaveAndTaskDependencies (S2G-455)
  2018/03/04  VM      (S2G-344)
                      Included pr_Allocation_AllocateLPN, pr_LPNDetails_ConfirmReservation
                      Enabled pr_Allocation_AllocateInventory
  2017/09/13  RV      Added pr_TaskDetails_Cancel (HPI-1584)
  2017/08/17  YJ      Added all the RFC Procedures (HPI-1635)
  2017/08/08  YJ      Initial revision (HPI-1609)
------------------------------------------------------------------------------*/
/*
  Debug Options : L - Log activity
                  D - Display log
                  M - Marker to isolate the performace issues

  Enabled       : Y - Yes
                  N - No
*/

delete from DebugControls;

Go

declare @DebugControls TDebugControlsTable;

/*----------------------------------------------------------------------------*/
/* Preprocess */
/*----------------------------------------------------------------------------*/
insert into @DebugControls (ProcName,                             Operation,             DebugOptions,      Enabled,       Module)
                    select 'pr_OrderHeaders_Preprocess',          '',                    'L',               'N',          'Preprocess'

/*----------------------------------------------------------------------------*/
/* Receiving */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_ReceiveToLocation',            null,                  'L',               'N',           'Purchasing'
             union  select 'pr_RFC_ReceiveToLPN',                 null,                  'L',               'N',           'Purchasing'

/*----------------------------------------------------------------------------*/
/* ASNs */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_ReceiveASNLPN',                null,                  'L',               'N',           'ASNs'
             union  select 'pr_RFC_ValidateASNLPN',               null,                  'L',               'N',           'ASNs'

/*----------------------------------------------------------------------------*/
/* Putaway */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_CancelPutawayLPN',             null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_CancelPutawayLPNs',            null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_ConfirmPutawayLPN',            null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_ConfirmPutawayLPNOnPallet',    null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_PA_CompleteVAS',               null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_PA_ConfirmPutawayPallet',      null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_PA_ValidatePutawayPallet',     null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_PutawayLPNsGetNextLPN',        null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_ValidatePutawayByLocation',    null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_ValidatePutawayLPN',           null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_ValidatePutawayLPNs',          null,                  'L',               'N',           'Putaway'
             union  select 'pr_RFC_ValidatePutawayLPNOnPallet',   null,                  'L',               'N',           'Putaway'

/*----------------------------------------------------------------------------*/
/* Inventory */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_AddSKUToLocation',             null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_AddSKUToLPN',                  null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_AdjustLocation',               null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_AdjustLPN',                    null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ConfirmCreateLPN',             null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ConfirmLocationSetUp',         null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ConfirmLPNDisposition',        null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_CreateLPN',                    null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ExplodePrepack',               null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_Inv_AddLPNToPallet',           null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_Inv_DropBuildPallet',          null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_Inv_MovePallet',               null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_Inv_ValidatePallet',           null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_MoveLPN',                      null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_RemoveSKUFromLocation',        null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_TransferInventory',            null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_TransferPallet',               null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_UpdateSKUAttributes',          null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ValidateLocation',             null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ValidateLPN',                  null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ValidateReceipt',              null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ValidateScannedLPN',           null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ValidateScannedSKU',           null,                  'L',               'N',           'Inventory'
             union  select 'pr_RFC_ValidateSKU',                  null,                  'L',               'N',           'Inventory'
             union  select 'pr_LPNs_CreateLPNs',                  null,                  'L',               'N',           'Inventory'

/*----------------------------------------------------------------------------*/
/* Cycle Count */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_CC_CompleteLocationCC',        null,                  'L',               'N',           'CycleCount'
             union  select 'pr_RFC_CC_StartDirectedLocCC',        null,                  'L',               'N',           'CycleCount'
             union  select 'pr_RFC_CC_StartLocationCC',           null,                  'L',               'N',           'CycleCount'
             union  select 'pr_RFC_CC_ValidateEntity',            null,                  'L',               'N',           'CycleCount'

/*----------------------------------------------------------------------------*/
/* Waving */
/*----------------------------------------------------------------------------*/
             union  select 'pr_PickBatch_AddOrder',               null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_AddOrders',              null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_AddOrUpdate',            null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_AfterRelease',           null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_AutoGenerateBatches',    null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_AutoReleaseBatches',     null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_AutoUnwaveOrders',       null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_BatchSummary',           null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_Cancel',                 null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_CleanupWaves',           null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_CreateBatch',            null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_CreatePickTasks',        null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_DeleteAttributes',       null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_GenerateBatches',        null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_GetInventorySummary',    null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_GetNextBatchNo',         null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_InventorySummary',       null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_IsValidToAddTaskDetail', null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_MarkAsClosed',           null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_MarkAsShipped',          null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_Modify',                 null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_ModifyBatch',            null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_OnRelease',              null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_PlanBatch',              null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_ProcessOrderDetails',    null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_ReAllocateBatches',      null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_Recalculate',            null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_ReleaseBatches',         null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_RemoveOrder',            null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_RemoveOrders',           null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_ReturnOrdersToOpenPool', null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_SetStatus',              null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_SetUpAttributes',        null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_UnwaveOrders',           null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatch_UpdateCounts',           null,                  'L',               'N',           'Waving'

             union  select 'pr_PickBatchDetails_AddOrUpdate',     null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatches_RemoveBPTQty',         null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatchRules_AddOrUpdate',       null,                  'L',               'N',           'Waving'
             union  select 'pr_PickBatchRules_SwapSortseq',       null,                  'L',               'N',           'Waving'

/*----------------------------------------------------------------------------*/
/* Allocation */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Allocation_AllocateBatch',         null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AllocateFromPrePacks',  null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AllocateInventory',     null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AllocateLPN',           null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AllocateLPNToOrders',   null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AllocatePallets',       null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AllocateWave',          null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_AssignLPNtoOrder',      null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_CreateConsolidatedPT',  null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_CreatePickTasks',       null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_CreateTaskDetails',     null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_ExplodePrepack',        null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_FindAllocableLPN',      null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_FindAllocableLPNs',     null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_FindTaskToAddDetail',   null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_GeneratePseudoPicks',   null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_GetOrdersToSoftAllocate',
                                                                  null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_GetTaskStatistics',     null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_IsPalletAllocable',     null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_MaxPrePacksToBreak',    null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_PostEvaluation',        null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_PrepWaveForAllocation', null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_ProcessPreAllocatedCases',
                                                                  null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_ProcessTaskDetails',    null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_SaveOrderQualificationResults',
                                                                  null,                  'L',               'N',           'Allocation'
             union  select 'pr_Allocation_SoftAllocateOrderDetails',
                                                                  null,                  'L',               'N',           'Allocation'

/*----------------------------------------------------------------------------*/
/* LPNDetails */
/*----------------------------------------------------------------------------*/
             union  select 'pr_LPNDetails_ConfirmReservation',    null,                  'LXR',             'N',           'Allocation'
             union  select 'pr_LPNDetails_Unallocate',            null,                  'L',               'N',           'Allocation'

/*----------------------------------------------------------------------------*/
/* Tasks */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Tasks_UpdateDependencies',         null,                  'L',               'N',           'Task'
             union  select 'pr_Tasks_Cancel',                     null,                  'L',               'N',           'Task'

/*----------------------------------------------------------------------------*/
/* TaskDetails */
/*----------------------------------------------------------------------------*/
             union  select 'pr_TaskDetails_Cancel',               null,                  'L',               'N',           'TaskDetail'
             union  select 'pr_TaskDetails_ComputeDependencies',  null,                  'L',               'N',           'TaskDetail'
             union  select 'pr_TasksDetails_SplitUnits',          null,                  'L',               'N',           'TaskDetail'
             union  select 'pr_LPNs_RecomputeWaveAndTaskDependencies',
                                                                  null,                  'L',               'N',           'TaskDetail'

/*----------------------------------------------------------------------------*/
/* Replenishment */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Locations_SplitReplenishQuantity',  null,                  'L',              'N',           'Replenishment'
             union  select 'pr_LPNDetails_CancelReplenishQty',     null,                  'L',              'N',           'Replenishment'

/*----------------------------------------------------------------------------*/
/* Picking */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Picking_ConfirmTaskPicks',         null,                  'L',               'N',           'Picking'

             union  select 'pr_RFC_GetPickTicketInfo',            null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_AddCartonToCart',      null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ConfirmBatchPalletPick',
                                                                  null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ConfirmBatchPick',     null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ConfirmBatchPick_2',   null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ConfirmLPNPick',       null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ConfirmTaskPicks',     null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ConfirmUnitPick',      null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_DropPickedLPN',        null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_DropPickedPallet',     null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_GetBatchPalletPick',   null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_GetBatchPick',         null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_GetLPNPick',           null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_GetPick',              null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_GetPickForLPN',        null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_GetUnitPick',          null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_LPNReservations',      null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_PauseBatch',           null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_SkipBatchPick',        null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_StartBuildCart',       null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_UpdateOrderDetails',   null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ValidatePallet',       null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ValidatePickTicket',   null,                  'L',               'N',           'Picking'
             union  select 'pr_RFC_Picking_ValidateTaskPicks',    null,                  'L',               'N',           'Picking'

/*----------------------------------------------------------------------------*/
/* Reservation */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Reservation_ConfirmFromLPN',       null,                  'LM',              'N',           'Reservation'

/*----------------------------------------------------------------------------*/
/* Activation */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Reservation_ActivateLPNs',         null,                  'LM',              'N',           'Activation'
             union  select 'pr_Reservation_AutoActivation',       null,                  'L',               'N',           'Activation'
             union  select 'pr_LPNs_Action_ActivateShipCartons',  null,                  'LM',              'N',           'Activation'

/*----------------------------------------------------------------------------*/
/* Packing */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Packing_CloseLPN',                 null,                  'L',               'N',           'Packing'
             union  select 'pr_Packing_ClosePackage',             null,                  'LISE',            'N',           'Packing'
             union  select 'pr_Packing_SL_ProcessInput',          null,                  'L',               'N',           'Packing'
             union  select 'pr_RFC_Packing_ClosePackage',         null,                  'LXR',             'Y',           'Packing'

/*----------------------------------------------------------------------------*/
/* Printing */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Content_BuildDataStream',          null,                  'L',               'N',           'Printing'
             union  select 'pr_Printing_EntityPrintRequest',      null,                  'L',               'N',           'Printing'
             union  select 'pr_Printing_EntityPrintRequest',      'ReceiveToLPN',        'L',               'N',           'Printing'
             union  select 'pr_Printing_GetNextPrintJobToProcess',
                                                                  'Printing_GetNextJob', 'LI',              'N',           'Printing'

/*----------------------------------------------------------------------------*/
/* Shipping */
/*----------------------------------------------------------------------------*/
             union  select 'pr_LPNs_Ship',                        null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_AddLPNToALoad',           null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_AddOrUpdateRoutingRules', null,                  'LXR',             'Y',           'Shipping'
             union  select 'pr_Shipping_BuildReferences',         null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetBoLData',              null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetBoLDataCarrierDetails',null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetBoLDataCustomerOrderDetails',
                                                                  null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetCommoditiesInfo',      null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetLoadInfo',             null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetLPNData',              null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetPackingListData',      null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetPackingListDetails',   null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetPackingListFormat',    null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetPackingListsToPrint',  null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetShipmentData',         null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_GetShippingAccountDetails',
                                                                  null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_ShipManifest_GetData',    null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipment_MarkAsShipped',           null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_PLGetCommentsXML',        null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_PLGetShipLabelsXML',      null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_SaveLPNData',             null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_SaveShipmentData',        null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_ValidateToShip',          null,                  'L',               'N',           'Shipping'
             union  select 'pr_Shipping_VoidShipLabels',          null,                  'L',               'N',           'Shipping'


             union  select 'pr_RFC_Shipping_CaptureTrackingNoInfo',
                                                                  null,                  'L',               'N',           'Shipping'
             union  select 'pr_RFC_Shipping_Load',                null,                  'L',               'N',           'Shipping'
             union  select 'pr_RFC_Shipping_UnLoad',              null,                  'L',               'N',           'Shipping'
             union  select 'pr_RFC_Shipping_ValidateLoad',        null,                  'L',               'N',           'Shipping'

/*----------------------------------------------------------------------------*/
/* Load */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Load_AddOrder',                    null,                  'L',               'N',           'Load'
             union  select 'pr_Load_AddOrders',                   null,                  'L',               'N',           'Load'
             union  select 'pr_Load_AddShipment',                 null,                  'L',               'N',           'Load'
             union  select 'pr_Load_AutoGenerate',                null,                  'L',               'N',           'Load'
             union  select 'pr_Load_AutoShip',                    null,                  'L',               'N',           'Load'
             union  select 'pr_Load_Cancel',                      null,                  'L',               'N',           'Load'
             union  select 'pr_Load_CreateNew',                   null,                  'L',               'N',           'Load'
             union  select 'pr_Load_FindShipmentForOrder',        null,                  'L',               'N',           'Load'
             union  select 'pr_Load_Generate',                    null,                  'L',               'N',           'Load'
             union  select 'pr_Load_GenerateBoLs',                null,                  'L',               'N',           'Load'
             union  select 'pr_Load_GenerateLoadForWavedOrders',  null,                  'L',               'N',           'Load'
             union  select 'pr_Load_GetDisqualifiedOrdersToShip', null,                  'L',               'N',           'Load'
             union  select 'pr_Load_GetNextSeqNo',                null,                  'L',               'N',           'Load'
             union  select 'pr_Load_MarkAsShipped',               null,                  'L',               'N',           'Load'
             union  select 'pr_Load_Modify',                      null,                  'L',               'N',           'Load'
             union  select 'pr_Load_Recount',                     null,                  'L',               'N',           'Load'
             union  select 'pr_Load_RemoveOrders',                null,                  'L',               'N',           'Load'
             union  select 'pr_Load_SetStatus',                   null,                  'L',               'N',           'Load'
             union  select 'pr_Load_UI_AddOrders',                null,                  'L',               'N',           'Load'
             union  select 'pr_Load_UI_RemoveOrders',             null,                  'L',               'N',           'Load'
             union  select 'pr_Load_Update',                      null,                  'L',               'N',           'Load'
             union  select 'pr_Load_ValidateAddOrder',            null,                  'L',               'N',           'Load'
             union  select 'pr_Load_ValidateAddShipment',         null,                  'L',               'N',           'Load'
             union  select 'pr_Load_ValidateToShip',              null,                  'L',               'N',           'Load'
             union  select 'pr_Loads_Action_ActivateShipCartons', null,                  'L',               'N',           'Load'

/*----------------------------------------------------------------------------*/
/* Tote Operations */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_TO_ConfirmLPN',                null,                  'L',               'N',           'ToteOperations'
             union  select 'pr_RFC_TO_ValidateLPN',               null,                  'L',               'N',           'ToteOperations'

/*----------------------------------------------------------------------------*/
/* Inquiry */
/*----------------------------------------------------------------------------*/
             union  select 'pr_RFC_Inquiry_Location',             null,                  'L',               'N',           'Inquiry'
             union  select 'pr_RFC_Inquiry_LPN',                  null,                  'L',               'N',           'Inquiry'
             union  select 'pr_RFC_Inquiry_Pallet',               null,                  'L',               'N',           'Inquiry'
             union  select 'pr_RFC_Inquiry_SalesOrder',           null,                  'L',               'N',           'Inquiry'
             union  select 'pr_RFC_Inquiry_SKU',                  null,                  'L',               'N',           'Inquiry'

/*----------------------------------------------------------------------------*/
/* Orders */
/*----------------------------------------------------------------------------*/
             union  select 'pr_OrderHeaders_Close',               null,                  'L',               'N',           'SalesOrders'

/*----------------------------------------------------------------------------*/
/* Actions */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Entities_ExecuteAction',           null,                  'L',               'N',           'Actions'
             union  select 'pr_Entities_ExecuteAction_V3',        null,                  'LIE',             'N',           'Actions'

/*----------------------------------------------------------------------------*/
/* Rules */
/*----------------------------------------------------------------------------*/
             union  select 'pr_Rules_Process',                    null,                  'L',               'N',           'Actions'

/*----------------------------------------------------------------------------*/
/* Cubing */
/*----------------------------------------------------------------------------*/
insert into @DebugControls (ProcName, Operation, DebugOptions, Enabled, Module)
                     select Name,     null,      'L',          'N',     'Cubing' from sys.objects where name like 'pr_Cubing%';

/*----------------------------------------------------------------------------*/
/* Printing */
/*----------------------------------------------------------------------------*/
insert into @DebugControls (ProcName, Operation, DebugOptions, Enabled, Module)
                     select Name,     null,      'L',          'N',     'Printing' from sys.objects where name like 'pr_Printing%';

/*----------------------------------------------------------------------------*/
/* Replenish */
/*----------------------------------------------------------------------------*/
insert into @DebugControls (ProcName, Operation, DebugOptions, Enabled, Module)
                     select Name,     null,      'L',          'N',     'Replenishment' from sys.objects where name like 'pr_Replenish%';


/* Enable Logging for all the procedures in Test, Staging and Dev environments */

if ((db_name() like '%Staging%') or (db_name() like '%Test%') or (db_name() like '%Dev%'))
  update @DebugControls set Enabled = 'Y'

exec pr_Setup_DebugControls @DebugControls, 'IU' /* Insert/Update */;

Go

/*
declare @DebugControls TDebugControlsTable;

insert into @DebugControls (ProcName,                             Operation,             DebugOptions,      Enabled,       Module)
                     select Name,                                 '',                    'L',               'N',          '
from sys.objects
where Type = 'P' and Name like 'pr_%'

exec pr_Setup_DebugControls @DebugControls, 'IU' /* Insert/Update */;

*/