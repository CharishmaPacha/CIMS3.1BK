/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  RIA     Added AMF_Packing_OrderAlreadyPacked (OB2-1882)
  2021/06/13  RIA     Added AMF_NoMatchingItemsForFilteredValue (HA-1688)
  2021/04/29  RIA     Added AMF_LPNInquiry_MultiSKUPicklane (OB2-1768)
  2021/04/05  AY      Revised messages AMF_Transfer_LPNQtyIsZero (HA-2542)
  2021/03/18  RIA     Added AMF_Returns_InvalidInput, AMF_Returns_RMAClosed (OB2-1357)
  2021/03/03  RIA     Changed description for AMF_ConfigurePrinter_Successful (HA-2113)
  2021/02/26  RIA     Added AMF_ShipLabelCancel_Successful (HA-2087)
  2021/01/06  RIA     Added AMF_CreateInvLPN_Successful, AMF_ScanLPNWithoutQty (HA-1839)
  2020/07/04  SK      Added AMF_CycleCount_Successful (CIMSV3-788)
  2020/06/24  RIA     Added AMF_QtyCannotbeGreaterThanQtyToAllocate (HA-832)
  2020/05/28  SK      Added AMF_ShipCartonsActv_Successful (HA-640)
  2020/05/08  AY      Renamed AMF_LocOrLPNQtyIsZero to AMF_Transfer_LocOrLPNQtyIsZero (OB2-1119)
  2020/04/03  RT      Included AMF_ConfigurePrinter_Successful (HA-81)
  2020/04/01  VM      Added AMF_ChangeWarehouse_Successful (HA-79)
  2020/03/18  RIA     Added AMF_AllLPNsReceivedAgainstTheReceipt, AMF_AllUnitsReceivedAgainstTheReceipt (CIMSV3-652)
  2020/03/17  RIA     Added AMF_ReceivingPaused (CIMSV3-652)
  2020/01/27  RIA     Added AMF_NoLPNsAssociatedWithLoad (CIMSV3-690)
  2020/01/23  RIA     Added AMF_LPNOrPalletAddedToLoad, AMF_LPNOrPalletRemovedFromLoad (CIMSV3-690)
  2020/01/18  RIA     Added AMF_SKUIsNotSetupForLocation (CIMSV3-655)
  2019/12/20  RIA     Added AMF_Packing_OrderAlreadyShipped, AMF_Packing_OrderAlreadyCancelled,
                      AMF_Packing_OrderNotAllocated, AMF_Packing_ScannedLPNNotAllocated,
                      AMF_Packing_PalletNotAssociatedWithSingleOrder, AMF_Packing_UnableToIdentifyOrder (CIMSV3-622)
  2019/11/27  RIA     Added AMF_PAByLoc_Done, AMF_PAByLoc_ReservedLPNNonPickableLoc,
                      AMF_PAByLoc_CannotPAMultiSKULPNToPL (CIMSV3-647)
  2019/10/30  RIA     Added AMF_CannotPAPartialUnitsToNonPicklane (CIMSV3-631)
  2019/10/30  RIA     Added AMF_LocOrLPNQtyIsZero (CIMSV3-632)
  2019/10/23  RIA     Added AMF_PalletNeedNotBeLocated (CID-947)
  2019/07/08  RIA     Added AMF_SingleLineDoesnotNeedBuildCart (CID-GoLive)
  2019/06/22  RIA     Changed description for VAS confirmation messages (CID-577)
  2019/06/21  RIA     Initial revision
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
select MessageName, Description into #AMFMessages from Messages where MessageName = '#';

/*------------------------------------------------------------------------------*/
/* Additional Messages built for V3 */
/*------------------------------------------------------------------------------*/

insert into #AMFMessages
            (MessageName,                             Description)
      select 'AMF_ClearCart_Successful',              'Cart %1 is cleared successfully'
union select 'AMF_ClearCart_NotCleared',              'Cart %1 is not cleared'

union select 'AMF_LPNAdjusted_Successful',            'LPN %1 is adjusted successfully'

union select 'AMF_SingleLineDoesnotNeedBuildCart',    'Single Line Does not need Build Cart'

/*------------------------------------------------------------------------------*/
/* VAS Instructions */
/*------------------------------------------------------------------------------*/
union select 'AMF_VAS_LPNNotAssociatedWithAnyOrder',  'LPN is not associated with any Order'
union select 'AMF_VAS_OrderDoesNotRequireVAS',        'Order does not require VAS'
union select 'AMF_VASComplete_CartonNotInVASArea',    'Carton/Tote is not in the VAS area to complete VAS operations'
union select 'AMF_VASComplete_LPNPicking',            'Carton/Tote has not been picked complete yet to complete VAS'
union select 'AMF_VASComplete_LPNNotPicked',          'Carton/Tote not in Picked Status to complete VAS'
union select 'AMF_VASLPNMove_Successfull',            'VAS completed on LPN %1 and is moved to Location %2 successfully'
union select 'AMF_VASLPNMove_Unsuccessful',           'VAS complete operation failed on LPN %2 and is not moved'

/*------------------------------------------------------------------------------*/
/* Build Pallet */
/*------------------------------------------------------------------------------*/
union select 'AMF_PalletNeedNotBeLocated',            'Pallet is empty and need not be located'

/*------------------------------------------------------------------------------*/
/* Transfer Inventory */
/*------------------------------------------------------------------------------*/
union select 'AMF_Transfer_LPNQtyIsZero',             'Scanned LPN is empty and has no inventory to transfer'
union select 'AMF_Transfer_LocationIsEmpty',          'Scanned Location is empty and has no inventory to transfer'

/*------------------------------------------------------------------------------*/
/*Putaway LPN*/
/*------------------------------------------------------------------------------*/
union select 'AMF_CannotPAPartialUnitsToNonPicklane', 'Cannot Putaway Partial units into non Picklane Location'

/*------------------------------------------------------------------------------*/
/* Putaway By Location */
/*------------------------------------------------------------------------------*/
union select 'AMF_PAByLoc_Done',                      'Completed Putaway into Location'
union select 'AMF_PAByLoc_ReservedLPNNonPickableLoc', 'Cannot Putaway LPN that has inventory reserved for an Order into a nonpickable location'
union select 'AMF_PAByLoc_CannotPAMultiSKULPNToPL',   'Cannot Putaway Multi SKUs LPN to picklane, please use Putaway To Picklanes'

/*------------------------------------------------------------------------------*/
/* Inquiry */
/*------------------------------------------------------------------------------*/
union select 'AMF_LPNInquiry_MultiSKUPicklane',       'Use Location Inquiry for Multi SKU Picklanes'

/*------------------------------------------------------------------------------*/
/* Picking */
/*------------------------------------------------------------------------------*/
union select 'AMF_ShipCartonsActv_Successful',        'Ship Carton %1 activated successfully'
union select 'AMF_ShipCartonsActv_SuccessfulPalletized',
                                                      'Activated Ship Carton %1 updated on Pallet %2 successfully'

/*------------------------------------------------------------------------------*/
/* Packing */
/*------------------------------------------------------------------------------*/
union select 'AMF_Packing_OrderAlreadyShipped',       'Scanned Order is already shipped'
union select 'AMF_Packing_OrderAlreadyCancelled',     'Scanned Order is already cancelled'
union select 'AMF_Packing_OrderNotAllocated',         'Scanned Order is not allocated'
union select 'AMF_Packing_ScannedLPNNotAllocated',    'Scanned LPN is not allocated'
union select 'AMF_Packing_PalletNotAssociatedWithSingleOrder',
                                                      'Scanned Pallet is not associated with single order'
union select 'AMF_Packing_UnableToIdentifyOrder',     'Unable to identify scanned order'
union select 'AMF_Packing_OrderAlreadyPacked',        'Scanned Order is already packed'

/*------------------------------------------------------------------------------*/
/* Manage Picklane */
/*------------------------------------------------------------------------------*/
union select 'AMF_SKUIsNotSetupForLocation',          'SKU is not configured for the location'
union select 'AMF_NoMatchingItemsForFilteredValue',   'No matching items for filtered value'

/*------------------------------------------------------------------------------*/
/* Miscellaneous */
/*------------------------------------------------------------------------------*/
union select 'AMF_ChangeWarehouse_Successful',        'Changed login Warehouse to %1 successfully'
union select 'AMF_ConfigurePrinter_Successful',       'Successfully configured the %1 printer for the device'
union select 'AMF_QtyCannotbeGreaterThanQtyToAllocate',
                                                      'Cannot allocate more than required, selected quantity is greater than To Allocate Quantity'

/*------------------------------------------------------------------------------*/
/* Receiving */
/*------------------------------------------------------------------------------*/
union select 'AMF_AllUnitsReceivedAgainstTheReceipt', 'All Units are received against Receipt %1'
union select 'AMF_AllLPNsReceivedAgainstTheReceipt',  'All LPNs are received against Receipt %1'
union select 'AMF_ReceivingPaused',                   'Receiving paused successfully'

/*------------------------------------------------------------------------------*/
/* Returns */
/*------------------------------------------------------------------------------*/
union select 'AMF_Returns_InvalidInput',              'Please scan valid ShipCarton/RMA'
union select 'AMF_Returns_RMAClosed',                 'Cannot accept returns for a closed RMA'

/*------------------------------------------------------------------------------*/
/* Shipping */
/*------------------------------------------------------------------------------*/
union select 'AMF_LPNOrPalletAddedToLoad',            '%1 added successfully to the load %2'
union select 'AMF_LPNOrPalletRemovedFromLoad',        '%1 unloaded successfully from the load %2'
union select 'AMF_NoLPNsAssociatedWithLoad',          'There are no LPNs associated with the load'

union select 'AMF_ShipLabelCancel_Successful',        'Ship Label %1 cancelled successfully'
/*------------------------------------------------------------------------------*/
/* Create Inv LPN */
/*------------------------------------------------------------------------------*/
union select 'AMF_CreateInvLPN_Successful',           'Created %1 LPN having %2 SKU with %3 Units'
union select 'AMF_ScanLPNWithoutQty',                 'Please scan any empty LPN'

/*------------------------------------------------------------------------------*/
/* Cycle Counting */
/*------------------------------------------------------------------------------*/
union select 'AMF_CycleCount_Successful',             'Cycle counted successfully'


Go

/* Delete any existing Messages */
delete from Messages where MessageName like 'AMF_%';

/* Add the new messages */
insert into Messages (MessageName, Description, NotifyType, Status, BusinessUnit)
select MessageName, Description, 'E' /* Error */, 'A' /* Active */, (select Top 1 BusinessUnit from vwBusinessUnits order by SortSeq)
from #AMFMessages;

Go
