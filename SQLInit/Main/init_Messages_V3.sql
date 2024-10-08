/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2021/07/29  RV      Added OrderHeader_ConvertToSetSKUs_* (OB2-1948)
  2021/07/21  PKD     LPN_ModifyOwnership_*:changed to LPN_ChangeOwnership_* (OB2-1954)
  2021/07/15  BSP     Added LPNs_ModifyLPNType_* messages (0B2-1955)
  2021/07/14  SRP     Added LPNs_ChangeSKU_* related messages (OB2-1953)
  2021/07/14  GAG     Added LPN Modify Carton Type/Weight related messages (OB2-1956)
  2021/07/13  PKK     Added LPNs_RemoveZeroQtySKUs_* messages (OB2-1957)
  2021/06/29  SJ      Added Loads_CreateLoad_Successful (CIMSV3-1514)
  2021/06/28  SPP     Added Layout related (OB2-1481)
  2021/06/28  SPP     Added LayoutFields Related (OB2-1478)
  2021/06/22  SV      Added Load_ManageLoads_CreateLoad_Successful (CIMSV3-1517)
  2021/06/22  KBB     Added Mapping Add and Edit and Delete Actions (OB2-1475,OB2-1476)
  2021/06/22  SPP     Added Printers related messages (OB2-1520, OB2-1521)
  2021/06/22  SPP     Added Cycle count related messages (OB2-1555)
  2021/06/15  VM      Added OD_ModifyDetails_* (CIMSV3-1515)
  2021/06/17  SAK     Added AddOrdersToWave Messages (CIMSV3-1516)
  2021/06/16  KBB     Added Loads_Modify_* Messages (CIMSV3-1501)
  2021/06/15  RKC     Added OrderDetails_CancelPTLine_*, OrderDetails_CancelRemainingQty_* messages (CIMSV3-1500)
  2021/06/16  PKK     Added Order_CancelPickTicket_* (CIMSV3-1487)
  2021/06/10  VM      Added OrderHeader_ModifyShipDetails_* (OB2-1887)
  2021/06/10  SJ      Added messages for Loads_ModifyApptDetails (OB2-1872)
  2021/06/10  SJ      Added messages for Loads_ModifyBoLInfo (OB2-1871)
  2021/06/10  SAK     Added messages for Waves Reallocate (OB2-1860)
  2021/06/08  KBB     Added Messages for Confirm Load as Shipped (OB2-1874)
  2021/06/04  SJ      Added messages for Cancel PTLine (OB-1820)
  2021/06/03  SJ      Added messages for AssignToUser & UnassignUser (OB-1821)
  2021/05/31  AJM     Added messages for ModifyPickTicket (OB2-1800)
  2021/05/26  SAK     Added messages for Waves modify, ReleaseForAllocation and Reallocate (OB2-1801)
  2021/05/24  AJM     Added messages for Cancel Waves (OB2-1811)
  2021/05/21  SJ      Added Messages for Generate Waves (OB2-1805 & OB2-1806)
  2020/12/14  RT      Initial revision for V2 clients to upgrade with V3 (CID-1569)
------------------------------------------------------------------------------*/

Go

/*
  UI Notify Types:
    null -  ignore the message
    'W'  -  Warning
    'I'  -  Information
    'E'  -  Error
    'X'  -  Exception
*/

/* Create temp table */
select MessageName, Description into #Messages from Messages where MessageName = '#';

insert into #Messages
            (MessageName,                                   Description)
      select 'ModifyPickTicket_InvalidOrderType',           'Cannot modify PickTicket %1 of this order type'
union select 'ModifyPickTicket_InvalidOrderStatus',         'Cannot modify PickTicket %1 in %2 status'

union select 'OrderHeader_ConvertToSetSKUs_NoneUpdated',        'Note: None of the selected Orders have been convert to sets'
union select 'OrderHeader_ConvertToSetSKUs_SomeUpdated',        'Note: %RecordsUpdated out of %TotalRecords selected Orders have been converted to sets'
union select 'OrderHeader_ConvertToSetSKUs_Successful',         'Note: All selected (%TotalRecords) Orders have been converted successfully'
union select 'OrderHeader_ConvertToSetSKUs_InvalidOrderType',   'Cannot convert to set SKUs Order %1 type %2'
union select 'OrderHeader_ConvertToSetSKUs_InvalidOrderStatus', 'Cannot convert to set SKUs Order %1 in %2 status'

union select 'Order_CancelPickTicket_InvalidOrderType',     'Cannot Cancel PickTicket %1 of this order type'
union select 'Order_CancelPickTicket_InvalidOrderStatus',   'Cannot Cancel PickTicket %1 in %2 status'
union select 'Order_CancelPickTicket_SomeUnitsAreShipped',  'Cannot Cancel PickTicket some units are shippeed, close the PickTicket instead'
union select 'Order_CancelPickTicket_OrderOnLoad',          'Cannot Cancel a PickTicket that is associated with a Load. Please remove PickTicket from load and then cancel'

union select 'Order_ClosePickTicket_InvalidOrderType',      'Cannot close PickTicket %1 of this order type'
union select 'Order_ClosePickTicket_InvalidOrderStatus',    'Cannot close PickTicket %1 in %2 status'

union select 'OrderHeader_CancelPickTicket_NoneUpdated',    'Note: None of selected PickTickets are cancelled'
union select 'OrderHeader_CancelPickTicket_SomeUpdated',    'Note: %RecordsUpdated of %TotalRecords selected PickTickets are cancelled'
union select 'OrderHeader_CancelPickTicket_Successful',     'Note: All selected PickTickets (%RecordsUpdated) have been cancelled successfully'

union select 'OrderHeader_ClosePickTicket_NoneUpdated',     'Note: None of selected PickTickets are closed'
union select 'OrderHeader_ClosePickTicket_SomeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected PickTickets are closed'
union select 'OrderHeader_ClosePickTicket_Successful',      'Note: All selected PickTickets (%RecordsUpdated) have been closed successfully'

union select 'OrderHeader_ModifyPickTicket_NoneUpdated',    'Note: None of the selected Orders are modified'
union select 'OrderHeader_ModifyPickTicket_SomeUpdated',    'Note: %RecordsUpdated of %TotalRecords selected Orders are modified'
union select 'OrderHeader_ModifyPickTicket_Successful',     'Note: All selected Orders (%RecordsUpdated) have been modified successfully'

union select 'OrderHeader_ModifyShipDetails_NoneUpdated',   'Note: None of the selected Orders are modified with new Ship Details'
union select 'OrderHeader_ModifyShipDetails_SomeUpdated',   'Note: Ship Details modified on %RecordsUpdated of %TotalRecords selected Orders'
union select 'OrderHeader_ModifyShipDetails_Successful',    'Note: Ship Details modified successfully on selected %RecordsUpdated Order(s)'

union select 'OrderHeader_RemoveOrdersFromWave_NoneUpdated', 'Note: None of selected Orders are removed'
union select 'OrderHeader_RemoveOrdersFromWave_SomeUpdated', 'Note: %RecordsUpdated of %TotalRecords selected Orders are removed from the wave'
union select 'OrderHeader_RemoveOrdersFromWave_Successful',  'Note: All selected Orders (%RecordsUpdated) have been removed successfully'

union select 'Wave_RemoveOrders_NotValidWaveStatus',         'Wave is in invalid status and orders cannot be removed anymore'
union select 'Wave_RemoveOrders_WaveAlreadyReleased',        'Order %1 cannot be removed from Wave %2 as Wave is already released and you do not have authorization to Remove orders from Released Waves'
union select 'Wave_RemoveOrders_AllocationInProgress',       'Orders cannot be removed from Wave %2 as allocation is in-progress, please try again after few minutes'
union select 'Wave_RemoveOrders_CancelShipCartons',          'Cancel the Ship Carton %2 first and then remove the Order %1 from the Wave %3'
union select 'Wave_RemoveOrders_NotOnWave',                  'Order %1 is not associated with any wave to be removed from a Wave'
union select 'Wave_RemoveOrders_InvalidOrderStatus',         'Order %1 is %2 and cannot be removed from Wave %3'
union select 'Wave_RemoveOrders_OrderInReservationProcess',  'Order %1 has units assigned, unallocate those units and then remove order from wave'

union select 'TaskDetails_Export_SomeUpdated',              '%RecordsUpdated of %TotalRecords selected records have been confirmed to Re-Export'
union select 'TaskDetails_Export_NoneUpdated',              'None of the selected records are Ready to Export'
union select 'TaskDetails_Export_Successful',               'All selected (%TotalRecords) records have been confirmed to Re-Export the data to 6rvr'

union select 'TaskDetails_Export_CompletedOrCanceled',      'Task Detail %1 not updated as it is already completed or cancelled'
union select 'TaskDetails_Export_InvalidPickMethod',        'Task Detail %1 need not be exported as it would be executed in CIMS only'
union select 'TaskDetails_Export_ReadyToExport',            'Task Detail %1 is already in queued for Export'

/*------------------------------------------------------------------------------*/
/* Permissions */
/*------------------------------------------------------------------------------*/

union select 'RolePermissions_RevokePermission_Successful',  'Note: Updated (%RecordsUpdated) Permissions for Role(s) %1 successfully'
union select 'RolePermissions_GrantPermission_Successful',   'Note: Updated (%RecordsUpdated) Permissions for Role(s) %1 successfully'

/*------------------------------------------------------------------------------*/
/* LPNs Entity */
/*------------------------------------------------------------------------------*/
/* LPN Carton Type modify */
union select 'CartonTypeIsRequired',                        'CartonType is required'
union select 'CartonTypeIsInvalid',                         'Invalid Carton Type'
union select 'CartonTypeIsInactive',                        'Selected Carton Type is not active'

union select 'LPNs_ModifyLPNType_NoneUpdated',              'Note: None of the selected LPN are modified with new LPN Type'
union select 'LPNs_ModifyLPNType_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified'
union select 'LPNs_ModifyLPNType_Successful',               'Note: All selected LPNs (%RecordsUpdated) have been modified successfully'
union select 'LPNs_ModifyLPNType_SameLPNType',              'LPN %1 is already of Type "%2" and hence was not updated'

union select 'LPNs_ModifyCartonDetails_NoneUpdated',        'Note: None of the selected LPN(s) are modified with new Carton Type/Weight'
union select 'LPNs_ModifyCartonDetails_SomeUpdated',        'Note: %RecordsUpdated of %TotalRecords selected LPN(s) have been modified'
union select 'LPNs_ModifyCartonDetails_Successful',         'Note: All selected LPN(s) (%RecordsUpdated) have been modified successfully'

union select 'LPNs_ChangeOwnership_NoneUpdated',            'Note: None of the selected LPNs are changed to selected Owner'
union select 'LPNs_ChangeOwnership_SomeUpdated',            'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified with selected Owner'
union select 'LPNs_ChangeOwnership_Successful',             'Note: All selected LPNs (%RecordsUpdated) have been modified with selected Owner'
union select 'LPNs_ChangeOwnership_NotPutaway',             'LPN %1 is in %2 status and Ownership can only be changed on Putaway LPNs'
union select 'LPNs_ChangeOwnership_SameOwner',              'LPN %1 is already for owner %3 and hence was not updated'

union select 'LPNs_ChangeSKU_NoneUpdated',                  'Note: None of the selected LPNs are modified with selected SKU'
union select 'LPNs_ChangeSKU_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected LPNs have been modified with selected SKU'
union select 'LPNs_ChangeSKU_Successful',                   'Note: All selected LPNs (%RecordsUpdated) have been modified successfully with selected SKU'

union select 'LPNs_ChangeSKU_MultiSKULPN',                  'Cannot change SKU on LPN %1 as it has multiple SKUs in it.'
union select 'LPNs_ChangeSKU_ReservedLPN',                  'Cannot change SKU on LPN %1 as the quantity is reserved'
union select 'LPNs_ChangeSKU_HasDirectedQty',               'Cannot change SKU on Picklane %1 as it has quantity being directed to it'
union select 'LPNs_ChangeSKU_InvalidStatus',                'Cannot change SKU on LPN %1 as it is in %2 status'

union select 'LPN_RemoveZeroQtySKUs_NoneUpdated',           'Note: None of the selected SKUs have been Removed'
union select 'LPN_RemoveZeroQtySKUs_SomeUpdated',           'Note: (%RecordsUpdated) of (%TotalRecords) selected SKUs are Removed'
union select 'LPN_RemoveZeroQtySKUs_Successful',            'Note: All selected SKUs (%TotalRecords) have been removed successfully'
union select 'Location_RemoveSKUs_InvalidLPNType',          'Selected an invalid LPN. SKU can only be removed from a Picklane Location, so choose LPNs for Picklanes only'
union select 'Location_RemoveSKUs_NonZeroQtySKUs',          'Location %2 have inventory for SKU %1 and cannot be removed until the inventory is depleted from the Location'

/*------------------------------------------------------------------------------*/
/* OrderDetail Entity */
/*------------------------------------------------------------------------------*/
union select 'OD_ModifyDetails_UnitsAssignedGreaterThanToShip', 'Order %1, Line %2, SKU %3, was not updated as Units assigned is greater than Units To Ship'
union select 'OD_ModifyDetails_ToShipGreaterThanUnitsOrdered',  'Order %1, Line %2, SKU %3, was not updated as Unit To Ship is greater than Units Ordered'
union select 'OD_ModifyDetails_OrderStatusIsInvalid',           'Order %1 is in %4 status and therefore Line %2, SKU %3 cannot be modified'
union select 'OD_ModifyDetails_UnitsToShipIsRequired',          'Units to Ship is required to modify the order details'

union select 'CancelPTLine_CancelQtyIsRequired',            'Please enter cancel quantity'
union select 'CancelPTLine_NewUnitsToAllocateRequired',     'Please enter the New units to allocate or use Cancel remaining qty option'
union select 'CancelPTLine_NoUnitsToCancel',                'There are no units available to cancel for PickTicket %1, SKU %2'
union select 'CancelPTLine_CannotCancelPartialQty',         'Cannot cancel the line partly - unallocate any allocated units and/or cancel the total units to ship'
union select 'CancelPTLine_CannotCancelAllocatedQty',       'Cannot cancel allocated quantity. Can only cancel (%3 units) i.e. what remains to be allocated on the Order line for PickTicket %1, SKU %2'
union select 'CancelPTLine_CompletelyAllocated',            'Line is completely allocated, first unallocate the units assigned and then cancel the line'
union select 'CancelPTLine_InvalidOrderStatus',             'PickTicket %1 is in %2 status and cannot be cancelled'

union select 'OrderDetails_CancelPTLine_NoneUpdated',       'Note: None of the selected Order Details have been canceled'
union select 'OrderDetails_CancelPTLine_SomeUpdated',       'Note: %RecordsUpdated out of %TotalRecords selected Order Details have been canceled'
union select 'OrderDetails_CancelPTLine_Successful',        'Note: All selected (%TotalRecords) Order Details have been canceled successfully'
union select 'OrderDetails_CancelPTLine_InvalidOrderStatus','Order %1 has invalid status to cancel Order Details'

union select 'OrderDetails_CancelRemainingQty_NoneUpdated', 'Note: None of the selected Order Details remaining quantity have been canceled'
union select 'OrderDetails_CancelRemainingQty_SomeUpdated', 'Note: %RecordsUpdated out of %TotalRecords selected Order Details remaining quantity have been canceled'
union select 'OrderDetails_CancelRemainingQty_Successful',  'Note: All selected (%TotalRecords) Order Details have been canceled remaining quantity successfully'

/*---------------------------------------------------------------------------------------*/
/* Pick Tasks Related */
/*---------------------------------------------------------------------------------------*/
union select 'Tasks_AssignToUser_NoneUpdated',              'Note: None of the selected PickTasks are assigned'
union select 'Tasks_AssignToUser_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected PickTasks have been assigned'
union select 'Tasks_AssignToUser_Successful',               'Note: All selected PickTasks (%RecordsUpdated) have been assigned successfully'

union select 'Tasks_AssignUser_InvalidStatus',              'Task %1 is not a valid status, hence it cannot be assigned to user'

union select 'Tasks_UnassignUser_NoneUpdated',              'Note: None of the selected PickTasks are Unassigned'
union select 'Tasks_UnassignUser_SomeUpdated',              'Note: %RecordsUpdated of %TotalRecords selected PickTasks have been unassigned'
union select 'Tasks_UnassignUser_Successful',               'Note: All selected PickTasks (%RecordsUpdated) have been unassigned successfully'

union select 'Tasks_UnassignUser_NotAssigned',              'Task cannot be unassinged as it is not assigned to any user yet'
union select 'Tasks_UnassignUser_InvalidStatus',            'Task %1 is not a valid status, hence it cannot be unassigned from user'

/*---------------------------------------------------------------------------------------*/
/* Waves Related: */
/*---------------------------------------------------------------------------------------*/
union select 'WavesCreatedSuccessfully',                    'Successfully generated %1 waves, Generated waves from %2 to %3'
union select 'WaveCreatedSuccessfully',                     'Successfully generated %1 wave - wave %2'
union select 'WavesNotCreated',                             'Unable to generate waves.'

union select 'Waves_Generate_Successful',                   'Wave %1 generated with %2 Order(s)'
union select 'Waves_Generate_SomeOrdersNotWaved',           'Note: %1 of the selected %2 Order(s) have not been waved with selected criteria'

union select 'Waves_Cancel_NoneUpdated',                    'Note: None of the selected #PickBatches are cancelled'
union select 'Waves_Cancel_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been cancelled'
union select 'Waves_Cancel_Successful',                     'Note: All selected #PickBatches (%RecordsUpdated) have been cancelled successfully'

union select 'Waves_ReleaseForAllocation_NoneUpdated',      'Note: None of the selected #PickBatches are released for allocation'
union select 'Waves_ReleaseForAllocation_SomeUpdated',      'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been released for allocation'
union select 'Waves_ReleaseForAllocation_Successful',       'Note: All selected #PickBatches (%RecordsUpdated) have been released for allocation successfully'
union select 'ReleaseForAllocation_InvalidWaveStatus',      'Wave %1 is in %2 status, so the Wave cannot be released now'
union select 'ReleaseForAllocation_WaveHasNoOrders',        'Wave cannot be Released as it does not have orders associated with it.'

union select 'Waves_Modify_NoneUpdated',                    'Note: None of the selected #PickBatches are updated'
union select 'Waves_Modify_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected #PickBatches have been updated'
union select 'Waves_Modify_Successful',                     'Note: All selected #PickBatches (%RecordsUpdated) have been updated successfully'
union select 'Waves_Modify_SamePriority',                   'Wave %1 already is of Priority %2 and hence was not updated'
union select 'Waves_Modify_InvalidStatus',                  'Wave %1 is in %2 status, so the Wave cannot be modified now'

union select 'Waves_Reallocate_NoneUpdated',                'Note: %TotalRecords wave(s) have not been allocated as they may not have not released or already being allocated in the background'
union select 'Waves_Reallocate_SomeUpdated',                'Note: %RecordsUpdated of %TotalRecords waves successfully allocated. Remaining may not have been released or already being allocated in the background'
union select 'Waves_Reallocate_Successful',                 'Note: All selected #PickBatches (%RecordsUpdated) have been Reallocated successfully'

union select 'PickBatch_Waves_Reallocate_NoneUpdated',      'Note: %TotalRecords wave(s) have not been allocated as they may have not been released or already being allocated in the background'
union select 'PickBatch_Waves_Reallocate_SomeUpdated',      'Note: %RecordsUpdated of %TotalRecords waves successfully allocated. Remaining may have not been released or already being allocated in the background'
union select 'PickBatch_Waves_Reallocate_Successful',       'Note: All selected #PickBatches (%RecordsUpdated) have been Reallocated successfully'

union select 'OrderHeader_AddOrdersToWave_NoneUpdated',     'Note: None of the selected Orders(Detail)s were added to Wave'
union select 'OrderHeader_AddOrdersToWave_SomeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected Orders(Detail)s have been added to Wave successfully'
union select 'OrderHeader_AddOrdersToWave_Successful',      'Note: All selected Order(Detail)s (%RecordsUpdated) have been added to Wave successfully'

union select 'Wave_AddOrders_WaveIsInvalid',                'Given input %1 is not a valid Wave'
union select 'Wave_AddOrders_WaveStatusInvalid',            'Cannot add Order(s) to Wave %1 as it is in %2 status'
union select 'Wave_AddOrders_MultipleWarehouses',           'Cannot add Orders to Wave %1 as the Orders are for multiple Warehouses'
union select 'Wave_AddOrders_MultipleGroups',               'Cannot add Orders to Wave %1 as the Orders are for multiple groups'
union select 'Wave_AddOrders_WaveGroupMismatch',            'Cannot add Order %1 to Wave %2 as Order group (%4) and Wave group (%5) are different'
union select 'Wave_AddOrders_WarehouseMismatch',            'Cannot add Order %1 to Wave %2 as Order Warehouse (%4) and Wave Warehouse (%5) are different'
union select 'Wave_AddOrders_OrderInvalidStatus',           'Cannot add Order %1 to Wave %2 as Order is in %3 status'
union select 'Wave_AddOrders_BulkOrderNotValid',            'Cannot add Bulk Order %1 to Wave %2'
union select 'Wave_AddOrders_ReplenishNotValid',            'Cannot add Replenish Order %1 to Wave %2'

/*-------------------------------------------------------------------------------*/
/* Mapping Actions messages */
/*------------------------------------------------------------------------------*/
union select 'Mapping_Add_Successful',                      'New mapping created successfully'

union select 'Mapping_Edit_NoneUpdated',                    'Note: None of the selected mappings are updated'
union select 'Mapping_Edit_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected Mappings are updated'
union select 'Mapping_Edit_Successful',                     'Note: All selected mappings (%RecordsUpdated) have been updated successfully'

union select 'Mapping_Delete_NoneUpdated',                  'Note: None of the selected mappings are deleted'
union select 'Mapping_Delete_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Mappings are deleted'
union select 'Mapping_Delete_Successful',                   'Note: All selected mappings (%RecordsUpdated) have been deleted successfully'

/*---------------------------------------------------------------------------------------
Ship Label Related:
---------------------------------------------------------------------------------------*/
union select 'ShipLabel_InsertedLPN',                       'Ship labels inserted successfully for LPN %1'
union select 'ShipLabel_InsertedPickTicket',                'Ship labels inserted successfully for Order %2'
union select 'ShipLabel_VoidedLPN',                         'Ship labels voided for LPN %1'
union select 'ShipLabel_VoidedPickTicket',                  'Ship labels voided for Order %2'
union select 'ShipLabel_VoidedLPNs',                        'Note: %3 Ship labels are voided successfully'

union select 'ShipLabels_ModifyPackageDims_NoneUpdated',      'Note: None of the selected ShipLabels Dimensions are modified'
union select 'ShipLabels_ModifyPackageDims_SomeeUpdated',     'Note: %RecordsUpdated of %TotalRecords selected ShipLabels Dimensions have been modified'
union select 'ShipLabels_ModifyPackageDims_Successful',       'Note: All selected ShipLabels Dimensions (%RecordsUpdated) have been modified successfully'

/*-------------------------------------------------------------------------------*/
/* Shipments/Load Related */
/*-------------------------------------------------------------------------------*/
union select 'Loads_MarkAsShipped_Successful',              'Note: All selected (%RecordsUpdated) Loads have been shipped'
union select 'Loads_MarkAsShipped_SomeUpdated',             'Note: %RecordsUpdated of %TotalRecords selected Loads have been shipped'
union select 'Loads_MarkAsShipped_NoneUpdated',             'Note: None of the selected Loads are shipped'
union select 'LoadShip_Queued',                             'Selected Load %1 have been queued for closing'
union select 'LoadShip_ErrorProcessing',                    'Load %1: %2'
union select 'Loads_CreateLoad_Successful',                 'Load %1 created successfully'
union select 'Load_ManageLoads_CreateLoad_Successful',      'Load %1 created successfully'

/*-------------------------------------------------------------------------------*/
/* Loads/Modify BoL Info Related */
/*-------------------------------------------------------------------------------*/
union select 'Loads_ModifyBoLInfo_NoneUpdated',             'BoL details were not updated on any of the selected Loads'
union select 'Loads_ModifyBoLInfo_OneUpdated',              'BoL details were updated successfully on the selected Load'
union select 'Loads_ModifyBoLInfo_SomeUpdated',             'BoL details were updated successfully on %RecordsUpdated of %TotalRecords selected Loads'
union select 'Loads_ModifyBoLInfo_Successful',              'BoL details were updated successfully on all selected %RecordsUpdated Loads'

/*-------------------------------------------------------------------------------*/
/* Loads/Modify Appt Details Info Related */
/*-------------------------------------------------------------------------------*/
union select 'Loads_ModifyApptDetails_NoneUpdated',         'Appointment details were not updated on any of the selected Loads'
union select 'Loads_ModifyApptDetails_OneUpdated',          'Appointment details were updated successfully on the selected Load'
union select 'Loads_ModifyApptDetails_SomeUpdated',         'Appointment details were updated successfully on %RecordsUpdated of %TotalRecords selected Loads'
union select 'Loads_ModifyApptDetails_Successful',          'Appointment details were updated successfully on all selected %RecordsUpdated Loads'
union select 'Loads_ModifyApptDetails_InvalidStatus',       'Load %1 is in %2 status and the appointment details cannot be changed now'

/*-------------------------------------------------------------------------------*/
/* Loads/Generate BoLs Info Related */
/*-------------------------------------------------------------------------------*/
union select 'Loads_GenerateBoLs_Successful',               'BoLs generated for selected (%RecordsUpdated) Loads'
union select 'Loads_GenerateBoLs_SomeUpdated',              'BoLs generated for %RecordsUpdated of %TotalRecords selected Loads'
union select 'Loads_GenerateBoLs_NoneUpdated',              'No BoLs were generated for the selected Loads'

/*-------------------------------------------------------------------------------*/
/* Modify Loads  Related */
/*-------------------------------------------------------------------------------*/
union select 'Loads_Modify_NoneUpdated',                    'Note: None of the selected Loads are updated'
union select 'Loads_Modify_SomeUpdated',                    'Note: %RecordsUpdated of %TotalRecords selected Loads have been updated'
union select 'Loads_Modify_Successful',                     'Note: All selected Loads (%RecordsUpdated) have been updated successfully'

/*-------------------------------------------------------------------------------*/
/* Cycle count Related */
/*-------------------------------------------------------------------------------*/
union select 'CycleCountTasks_Cancel_Successful',           'All selected (%TotalRecords) Tasks have been cancelled'
union select 'CycleCountTasks_Cancel_NoneUpdated',          'None of the selected Tasks are cancelled'
union select 'CycleCountTasks_Cancel_SomeUpdated',          '%RecordsUpdated of %TotalRecords selected Tasks have been cancelled'

union select 'CycleCountTaskDetails_Cancel_Successful',     'All selected (%TotalRecords) TaskDetails have been cancelled'
union select 'CycleCountTaskDetails_Cancel_NoneUpdated',    'None of the selected TaskDetails are cancelled'
union select 'CycleCountTaskDetails_Cancel_SomeUpdated',    '%RecordsUpdated of %TotalRecords selected TaskDetails have been cancelled'
union select 'CC_CancelTaskDetails_AlreadyCompleted',       'Cycle count of Location %1 on Batch %2 already Completed.'
union select 'CC_CancelTaskDetails_AlreadyCanceled',        'Cycle count of Location %1 on Batch %2 Cancelled.'

union select 'CC_CancelTask_AlreadyCompleted',              'Cycle count Task %1 already Completed. Cannot cancel task'
union select 'CC_CancelTask_AlreadyCanceled',               'Cycle count Task %1 already Cancelled. Cannot cancel task'
union select 'CycleCountTasks_Cancel',                      'Cycle Count Task %1 cancelled successfully'
union select 'CC_PalletInDifferentLocation',                'Scanned Pallet is in a different Location. Please scan new Pallet instead'
/*-------------------------------------------------------------------------------*/
/* Printers Related */
/*-------------------------------------------------------------------------------*/
union select 'PrinterAlreadyExists',                        'Printer already exists with that name'
union select 'PrinterDoesNotExist',                         'Printer does not exist to Edit or Delete'
union select 'PrinterNameIsrequired',                       'Printer Name is required and should be unique'
union select 'PrinterDescIsrequired',                       'Printer Description is required'

union select 'Printers_Add_Successful',                     'Printer %1 added successfully'
union select 'Printers_Edit_Successful',                    'Printer details updated successfully for Printer %1'
union select 'Printers_Delete_Successful',                  'Selected Printer(s) deleted successfully'

union select 'Printers_ResetStatus_Successful',             'Note: Status of all selected Printers has been reset successfully'
union select 'Printers_ResetStatus_SomeUpdated',            'Note: Status of %PrintersUpdated of %TotalPrinters selected printers has been reset successfully'
union select 'Printers_ResetStatus_NoneUpdated',            'Note: None of the selected Printers statuses are reset'
union select 'Printers_ResetStatus_AlreadyInReadyStatus',   'Printer %1, cannot reset as already in Ready status'

/*---------------------------------------------------------------------------------------
LayoutFields Related:
---------------------------------------------------------------------------------------*/
union select 'LayoutFields_Edit_Successful',                'Layout Field details updated successfully'

/*---------------------------------------------------------------------------------------
Layouts Related:
---------------------------------------------------------------------------------------*/
union select 'Layouts_CannotDeleteOthersLayouts',           'Layout was created by another user and can only be deleted by user who created it'

union select 'Layouts_SelectionAddedSuccessfully',          'Layout selection added successfully'
union select 'Layouts_SelectionSavedSuccessfully',          'Layout selection saved successfully'

union select 'Layouts_CannotEditSystemLayout',              'User does not have permissions to edit System Layout'
union select 'Layouts_CannotChangeStandardLayoutCategory',  'Standard layout cannot be changed to be role or user specific'
union select 'Layouts_CannotAddStandardLayout',             'User does not have permissions to add Standard Layout'
union select 'Layouts_CannotEditStandardLayout',            'User does not have permissions to edit Standard Layout'

union select 'Layouts_CannotEditOthersLayouts',             'Layout was created by another user and can only be modified by the user who created it'

union select 'Layouts_Modify_NoneUpdated',                  'Note: None of the selected Layouts have been modified'
union select 'Layouts_Modify_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Layouts have been modified'
union select 'Layouts_Modify_Successful',                   'Note: All selected (%TotalRecords) Layouts have been modified successfully'

union select 'Layouts_Delete_NoneUpdated',                  'Note: None of the selected Layouts are deleted'
union select 'Layouts_Delete_SomeUpdated',                  'Note: %RecordsUpdated of %TotalRecords selected Layouts are deleted'
union select 'Layouts_Delete_Successful',                   'Note: All selected (%RecordsUpdated) Layouts have been deleted successfully'

Go

/* Replace the environment name */
update #Messages
set Description = replace(Description, '#Environment', 'Dev');

/* Add the new messages */
insert into Messages (MessageName, Description, NotifyType, Status, BusinessUnit)
select MessageName, Description, 'E' /* Error */, 'A' /* Active */, (select Top 1 BusinessUnit from vwBusinessUnits order by SortSeq)
from #Messages;

Go
