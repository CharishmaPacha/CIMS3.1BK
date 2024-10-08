/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/11  OK      DefaultFilterCondition for TaskId should be Equals (HA-1424)
  2020/05/11  NB      Added SKUDesc field to update for Contains Default Filter(CIMSV3-844)
  2020/05/08  MS      Comment field Filter should default with Contains
  2020/04/30  NB      Renamed Init_FieldGroups to Init_Fields_Update(CIMSV3-844)
  2020/04/10  MS      Initial revision.
------------------------------------------------------------------------------*/

/*******************************************************************************
 This file will have all the updates needed on Fields
 This file should always be run after Init_Fields file
*******************************************************************************/
/*******************************************************************************
                          FieldGroups
*******************************************************************************/

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Key Fields'
where FieldName in ('LPN', 'SKU', 'Pallet', 'Location', 'PickBatchNo', 'WaveNo', 'PickTicket', 'LoadNumber', 'TaskId', 'ReceiptNumber');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Inbound'
where FieldName in ('ReceiptNumber', 'ReceiverNumber');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Outbound'
where FieldName in ('ShipVia', 'FreightTerms');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Customer Info'
where FieldName in ('SoldToId', 'SoldToName', 'CustomerName', 'ShipToStore',
                    'ShipToId', 'ShipToName', 'ShipToAddressLine1', 'ShipToAddressLine2', 'ShipToCity', 'ShipToState', 'ShipToZip', 'ShipToCountry', 'ShipToCityStateZip');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Classification'
where FieldName in ('OrderCategory1', 'OrderCategory2', 'OrderCategory3', 'OrderCategory4', 'OrderCategory5');

/* LPN */
update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Inventory Class'
where FieldName in ('Lot', 'InventoryClass1', 'InventoryClass2', 'InventoryClass3', 'ExpiryDate', 'InventoryStatus');

/* SKU */
update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Pack Configuration'
where FieldName in ('UnitsPerInnerPack', 'InnerPacksPerLPN', 'UnitsPerLPN', 'PalletTie', 'PalletHigh');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Dimensions'
where FieldName in ('UnitWeight', 'UnitVolume', 'UnitLength', 'UnitWidth', 'UnitHeight',
                    'InnerPackWeight',  'InnerPackVolume', 'InnerPackLength', 'InnerPackWidth', 'InnerPackHeight');

/* Generic Counts */
update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Counts'
where FieldName in ('NumBatches', 'NumOrders', 'NumPallets', 'NumLPNs', 'NumPackages', 'NumInnerpacks',
                    'NumUnits', 'NumSKUs', 'NumLocations', 'NumLines',
                    'UnitsPicked', 'UnitsPacked', 'UnitsToPack', 'UnitsStaged', 'UnitsToStage', 'UnitsLoaded', 'UnitsToLoad', 'UnitsShipped',
                    'LPNsPicked', 'LPNsPacked', 'LPNsStaged', 'LPNsLoaded', 'LPNsToLoad', 'LPNsShipped');

/* Generic Dates */
update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'Dates'
where FieldName in ('ExpiryDate', 'CreatedDate', 'ModifiedDate', 'OrderDate', 'NB4Date', 'ShipDate',
                    'DesiredShipDate', 'CancelDate', 'DateOrdered', 'DateShipped', 'ETACountry', 'ETACity', 'ETAWarehouse');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'UDFs'
where FieldName like ('UDF%');

update Fields
set FieldGroups = coalesce(FieldGroups + ',', '') + 'UDFs'
where FieldName like ('%_UDF%');

Go
/*******************************************************************************
                          DefaultFilterCondition
*******************************************************************************/

/* Contains - All fields which have values in free text format */
update Fields
set DefaultFilterCondition = 'Contains'
where FieldName in (/* General Fields */
                    'Comment', 'Description', 'OperationDescription', 'LayoutDescription',
                    /* Reference Fields in Supporting Tables */
                    'LookUpDescription', 'LookUpDisplayDescription', 'RuleSetDescription', 'RuleDescription', 'LayoutDescription',
                    'SelectionDescription',
                    /* WMS Table Fields */
                    'SKUDescription', 'SKU1Description', 'SKU2Description', 'SKU3Description', 'SKU4Description', 'SKU5Description',
                    'SKUDesc', 'ShipToDescription', 'ShipViaDescription', 'BatchDescription');

/* Exception cases */

/* TaskId is integer field but cannot have 'Equals or Greaterthan'. Should be 'Equals' */
update Fields
set DefaultFilterCondition = 'Equals'
where FieldName in ('TaskId');

Go

/*******************************************************************************
                          DataType
*******************************************************************************/

/* Contains - All fields which have values with db data type different from actual values */
update Fields
set DataType = 'xml'
where FieldName in ('PrintJobNotifications');

Go