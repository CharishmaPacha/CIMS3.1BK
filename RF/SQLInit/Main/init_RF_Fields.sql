/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  RKC     Added AMFUnitsLoaded, AMFLPNsLoaded, AMFPalletsLoaded (HA-2862)
  2021/05/11  AY      Added AMFTotalQtyResvQty (OB2-1792)
  2021/03/13  RIA     Added AMFRMAOrShippingCarton, AMFRMAOrShippingCarton_PH (OB2-1357)
  2021/01/06  RIA     Added AMFInventoryClass1_PH (HA-1766)
  2020/11/19  RIA     Added AMF_SerialNumber, AMFScanSerialNo_PH (CIMSV3-1211)
  2020/11/18  AY      Revised captions for DestLocation/DestZone, added SuggestedZone
  2020/10/29  RIA     Corrected captions and Added AMFSuggestedPallet (JL-211)
  2020/10/22  AY      Added captions for ASN Receiving (JL-271)
  2020/10/18  RIA     Added AMFInnerPacks (CIMSV3-1134)
  2020/10/14  AY      Removed redundant fields
------------------------------------------------------------------------------*/

Go

declare @ttFields TFieldsTable;

/*------------------------------------------------------------------------------
 Field Properties:

------------------------------------------------------------------------------*/

insert into @ttFields
             (FieldName,               Caption,                 Width, Visible, Alignment, MaxLength,  DisplayFormat)
      select  'AMFWaveandPallet',      'Wave/Cart',              100,  1,       null,      null,  null
union select  'AMFPalletOrCart',       'Pallet/Cart',             75,  1,       null,      null,  null
union select  'AMFPickFrom',           'Pick From',               75,  1,       null,      null,  null
union select  'AMFLocationOrLPN',      'Location / LPN',          75,  1,       null,      null,  null
union select  'AMFToPick',             'To Pick',                 75,  1,       null,      null,  null
union select  'AMFLPNToPick',          'LPN To Pick',             75,  1,       null,      null,  null
union select  'AMFPicksCompleted',     'Picks Completed',         75,  1,       null,      null,  null
union select  'AMFPickSKU',            'Pick SKU',                75,  1,       null,      null,  null
union select  'AMFLocationOrSKU',      'Loc / SKU',               75,  1,       null,      null,  null
union select  'AMFLPNOrPicklane',      'LPN / Picklane',          75,  1,       null,      null,  null
union select  'AMFNumPicked',          'Num Picked',              75,  1,       null,      null,  null
union select  'AMFPosition',           'Position',                75,  1,       null,      null,  null
union select  'AMFPickTo',             'Pick To',                 75,  1,       null,      null,  null
union select  'AMFShipTo',             'Ship To Customer',        75,  1,       null,      null,  null
union select  'AMFDropZone',           'Suggested Drop Zone',     75,  1,       null,      null,  null
union select  'AMFDropLocation',       'Suggested Drop Location', 75,  1,       null,      null,  null
union select  'AMFDestZone',           'Destination Zone',        75,  1,       null,      null,  null
union select  'AMFDestLocation',       'Destination Location',    75,  1,       null,      null,  null
union select  'AMFTotalQty',           'Total Qty',               75,  1,       null,      null,  null
union select  'AMFPickingCart',        'Picking Cart',            75,  1,       null,      null,  null
union select  'AMFTotalUnitsToPick',   'Total Units To Pick',     75,  1,       null,      null,  null
union select  'AMFShipCarton',         'Shipping Carton',         75,  1,       null,      null,  null
union select  'AMFCartonTote',         'Carton/Tote',             75,  1,       null,      null,  null
union select  'AMFCartPosition',       'Cart Position',           75,  1,       null,      null,  null
union select  'AMFNumCartonTotes',     '# Carton/Totes',          75,  1,       null,      null,  null
union select  'AMFNumCartonsOnCart',   '# Carton/Totes on Cart',  75,  1,       null,      null,  null
union select  'AMFNumCartonsUsed',     '# Carton/Totes Used',     75,  1,       null,      null,  null
union select  'AMFNumPositions',       '# Positions',             75,  1,       null,      null,  null
union select  'AMFUnitsPicked',        '# Units Picked',          75,  1,       null,      null,  null
union select  'AMFCoO',                'Country of Origin',       75,  1,       null,      null,  null
union select  'AMFNewUnitsPerInnerPack','New Units/Case',         75,  1,       null,      null,  null
union select  'AMFTaskAssignedTo',     'Task Assigned To',        75,  1,       null,      null,  null
union select  'AMFToLPN',              'To LPN',                  75,  1,       null,      null,  null
union select  'AMFNumLPNsOnPallet',    '# LPNs on Pallet',        75,  1,       null,      null,  null
union select  'AMFLPNOrLocationOrPalletOrSKU',
                                       'LPN/Location/Pallet/SKU', 75,  1,       null,      null,  null
union select  'AMFPickLane',           'PickLane',                75,  1,       null,      null,  null
union select  'AMFSuggPalletOrLoc',    'Suggested Pallet/Location',
                                                                  75,  1,       null,      null,  null
union select  'AMFScanPalletOrLoc',    'Scan Pallet/Location',    75,  1,       null,      null,  null
union select  'AMFInnerPacks',         'Cases',                   75,  1,       null,      null,  null
union select  'AMFUoMInnerPacks',      'Cases',                   75,  1,       null,      null,  null
union select  'AMFUoMUnitsPerInnerPack',
                                       'Units/Case',              75,  1,       null,      null,  null
union select  'AMFUoMEaches',          'Eaches',                  75,  1,       null,      null,  null
union select  'AMFUoMPrepack',         'Prepack',                 75,  1,       null,      null,  null
union select  'AMFLPNsInTransitWithUnits',
                                       'LPNs In Transit (Units)', 75,  1,       null,      null,  null
union select  'AMFLPNsReceivedWithUnits',
                                       'LPNs Received (Units)',   75,  1,       null,      null,  null
union select  'AMFUnitsRemaining',     '# Remaining',             75,  1,       null,      null,  null
union select  'AMFUnitsToRework',      '# Units To Rework',       75,  1,       null,      null,  null
union select  'AMFAllowMultipleSKUs',  'Allow Multiple SKUs',     75,  1,       null,      null,  null
union select  'AMFMinMaxReplenishLevel',
                                       'Min/Max Replenish Level', 75,  1,       null,      null,  null
union select  'AMFSKUDescription',     'SKU Description',         75,  1,       null,      null,  null
union select  'AMFSKUFilter',          'SKU Filter',              75,  1,       null,      null,  null
union select  'AMFScanLocation',       'Scan Location',           75,  1,       null,      null,  null
union select  'AMFSuggestedLocation',  'Suggested Location',      75,  1,       null,      null,  null
union select  'AMFSuggestedPallet',    'Suggested Pallet',        75,  1,       null,      null,  null
union select  'AMFSuggestedZone',      'Suggested Zone',          75,  1,       null,      null,  null
union select  'AMFWeight',             'Weight',                  75,  1,       null,      null,  null
/* Transfers */
union select  'AMFTransferPicklane',   'Transfer Picklane',       75,  1,       null,      null,  null
union select  'AMFFromLPNOrPicklane',  'From LPN / Picklane',     75,  1,       null,      null,  null
union select  'AMFToLPNOrPicklane',    'To LPN / Picklane',       75,  1,       null,      null,  null
/* Inquiry */
union select  'AMFTotalQtyResvQty',    'Total Quantity, Reserved Qty',
                                                                  75,  1,       null,      null,  null
/* Packing */
union select  'AMFUnitsPacked',        '# Units Packed',          75,  1,       null,      null,  null
union select  'AMFSKUsPacked',         '# SKUs Packed',           75,  1,       null,      null,  null
/* Putaway */
union select  'AMFPutawayFromLPN',     'Putaway from LPN',        75,  1,       null,      null,  null
union select  'AMFPAQuantity',         'Quantity to Putaway',     75,  1,       null,      null,  null
union select  'AMFPALocation',         'Putaway to Picklane',     75,  1,       null,      null,  null
union select  'AMFPALPNToPutaway',     'LPN to Putaway',          75,  1,       null,      null,  null
union select  'AMFScannedLPNs',        'LPNs Scanned',            75,  1,       null,      null,  null
/* Receiving - Fields are particularly hyphenated so that they wrap as desired */
union select  'AMFReceivingZone',      'Receiving Zone',          75,  1,       null,      null,  null
union select  'AMFReceivingLocation',  'Receiving Location',      75,  1,       null,      null,  null
union select  'AMFToReceive',          'Remaining LPNs (Units)',  75,  1,       null,      null,  null
union select  'AMFLPNsInTransit',      'LPNs In_Transit',         75,  1,       null,      null,  null
union select  'AMFLPNsReceived',       'LPNs Received',           75,  1,       null,      null,  null
union select  'AMFUnitsOrdered',       'Units Ordered',           75,  1,       null,      null,  null
union select  'AMFUnitsReceived',      'Units Received',          75,  1,       null,      null,  null
union select  'AMFUnitsToReceive',     'Units To_Receive',        75,  1,       null,      null,  null
/* Returns */
union select  'AMFRMAOrShippingCarton','LPN/RMA/ShipCarton',      75,  1,       null,      null,  null
union select  'AMFUnitsShipped',       'Units Shipped',           75,  1,       null,      null,  null
union select  'AMFUnitsReturned',      'Units Returned',          75,  1,       null,      null,  null
/* Shipping */
union select  'AMFNewTrackingNo',      'New Tracking #',          75,  1,       null,      null,  null
union select  'AMFFreightCharge',      'Freight Charge',          75,  1,       null,      null,  null
union select  'AMFLPNOrPallet',        'LPN / Pallet',            75,  1,       null,      null,  null
union select  'AMF_SerialNumber',      'Serial Number',           75,  1,       null,      null,  null

union select  'AMFUnitsLoaded',        '# Units Loaded',          75,  1,       null,      null,  null
union select  'AMFLPNsLoaded',         '# LPNs Loaded',           75,  1,       null,      null,  null
union select  'AMFPalletsLoaded',      '# Pallets Loaded',        75,  1,       null,      null,  null

/* Place holders */
union select  'AMFScanLocation_PH',    'Scan or enter a valid Location',               75,  1,       null,      null,  null
union select  'AMFScanPallet_PH',      'Scan a Pallet',                                75,  1,       null,      null,  null
union select  'AMFScanLPN_PH',         'Scan or enter a valid LPN',                    75,  1,       null,      null,  null
union select  'AMFScanLPNPicklane_PH', 'Scan LPN/Picklane',                            75,  1,       null,      null,  null
union select  'AMFScanLPNTrkUCC_PH',   'Scan LPN/Tracking No/UCC Barcode',             75,  1,       null,      null,  null
union select  'AMFScanSKUUPC_PH',      'Scan SKU or UPC',                              75,  1,       null,      null,  null
union select  'AMFScanWaveNo_PH',      'Scan Wave No',                                 75,  1,       null,      null,  null
union select  'AMFScanPickTicket_PH',  'Scan Pick Ticket',                             75,  1,       null,      null,  null
union select  'AMFTaskId_PH',          'Scan or enter TaskId',                         75,  1,       null,      null,  null
union select  'AMFPickingCart_PH',     'Scan a Picking Cart',                          75,  1,       null,      null,  null
union select  'AMFPalletOrCart_PH',    'Scan the Pallet or Cart',                      75,  1,       null,      null,  null
union select  'AMFPickPalletOrCart_PH','Scan the Picking Pallet or Cart',              75,  1,       null,      null,  null
union select  'AMFDropLocation_PH',    'Scan the Location to Drop Pallet/Cart',        75,  1,       null,      null,  null
union select  'AMFShipCarton_PH',      'Scan a Ship Carton',                           75,  1,       null,      null,  null
union select  'AMFCartonTote_PH',      'Scan a Carton/Tote to pick into',              75,  1,       null,      null,  null
union select  'AMFCartPosition_PH',    'Scan a position on the Cart',                  75,  1,       null,      null,  null
union select  'AMFScanPTOrLPNOrToteOrCart_PH',
                                       'Scan PickTicket/Tote/LPN/Cart',                75,  1,       null,      null,  null
union select  'AMFScanSKU_PH',         'Scan or enter a valid SKU',                    75,  1,       null,      null,  null
union select  'AMFScanFromLocation_PH','Scan or enter a valid from Location',          75,  1,       null,      null,  null
union select  'AMFScanToLocation_PH',  'Scan or enter a valid to Location',            75,  1,       null,      null,  null
union select  'AMFScanFromLocationOrLPN_PH',
                                       'Scan or enter a valid from Location/LPN',      75,  1,       null,      null,  null
union select  'AMFScanToLocationOrLPN_PH',
                                       'Scan or enter a valid to Location/LPN',        75,  1,       null,      null,  null
union select  'AMFScanLPNOrLocationOrPalletOrSKU_PH',
                                       'Scan or enter LPN/Location/Pallet/SKU',        75,  1,       null,      null,  null
union select  'AMFScanPicklane_PH',    'Scan or enter a valid picklane',               75,  1,       null,      null,  null
union select  'AMFScanLPNOrPallet_PH', 'Scan LPN or Pallet',                           75,  1,       null,      null,  null
union select  'AMFScanLoad_PH',        'Scan or enter Load',                           75,  1,       null,      null,  null
union select  'AMFScanDock_PH',        'Scan or enter Dock',                           75,  1,       null,      null,  null
union select  'AMFFreightCharge_PH',   'Enter Freight Charge',                         75,  1,       null,      null,  null
union select  'AMFNewTracking_PH',     'Scan or enter New Tracking No',                75,  1,       null,      null,  null
union select  'AMFScanPalletOrLoc_PH', 'Scan or enter a valid Pallet or Location',     75,  1,       null,      null,  null
union select  'AMFScanReceiver_PH',    'Scan or enter a valid Receiver Number',        75,  1,       null,      null,  null
union select  'AMFScanReceipt_PH',     'Scan or enter a valid Receipt Number',         75,  1,       null,      null,  null
union select  'AMFScanCustPO_PH',      'Scan or enter a valid CustPO',                 75,  1,       null,      null,  null
union select  'AMFScanWarehouse_PH',   'Scan or enter a valid Warehouse',              75,  1,       null,      null,  null
union select  'AMFScanReceivingZone_PH',
                                       'Scan or enter a valid Receiving Zone',         75,  1,       null,      null,  null
union select  'AMFScanReceivingLocation_PH',
                                       'Scan or enter a valid Receiving Location',     75,  1,       null,      null,  null

union select  'AMFMisc_ChangeWH_PH',   'Scan or enter a new Warehouse to log into',    75,  1,       null,      null,  null
union select  'AMFScanFilterValue_PH', 'Enter SKU/UPC to filter',                      75,  1,       null,      null,  null
union select  'AMFScanBatchNo_PH',     'Scan or enter Batch No',                       75,  1,       null,      null,  null
union select  'AMFScanZone_PH',        'Scan or enter Zone',                           75,  1,       null,      null,  null

union select  'AMFScanSuggLocation_PH','Scan the suggested Location',                  75,  1,       null,      null,  null
union select  'AMFInventoryClass1_PH', 'Scan or enter Inventory Class 1',              75,  1,       null,      null,  null

/* Packing */
union select  'AMFPacking_CartonType_PH',   'select the type of Carton used for packing',       75,  1,       null,      null,  null
union select  'AMFPacking_Weight_PH',       'Enter the weight of the package from the scale',   75,  1,       null,      null,  null
/* Shipping */
union select  'AMFScanSerialNo_PH',    'Scan a valid serial number for this item',     75,  1,       null,      null,  null

/* Returns */
union select  'AMFRMAOrShippingCarton_PH',
                                       'Scan a valid Ship Carton or RMA',              75,  1,       null,      null,  null

/* Add the fields for all Business units.
   Option I  - Insert the above entries for all BUs and after deleting existing ones.
   Option AU - Add and/or Update i.e. Add ones that do not exist and update the ones that exist.
               If you are applying only few fields, use this option */
exec pr_Setup_Fields @ttFields, 'AU' /* Options - Add/Update Setup */, null /* Business Unit */, 'cimsdba' /* UserId */;

/* Temporary Fix - This has to be moved into the above procedure */
update Fields
set CultureName = 'en-US'
where (FieldName in (select FieldName from @ttFields)) and (CultureName is null);

Go
