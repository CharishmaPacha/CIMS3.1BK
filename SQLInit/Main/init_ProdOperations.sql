/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/21  AY      Corrected Receiving, setup activation & Shipping
  2021/06/13  SK      Included Reservation (HA-2960)
  2020/09/28  SK      Added activity types (CIMS-2967)
  2018/08/14  DK      Corrected the Activity type to 'PickBatchCompleted' (OB2-564)
  2013/10/10  PKS     Changed Operation value from PickBatch to Picking.
  2013/10/24  PKS     Packing related records added.
  2013/07/17  TD      Initial revision
------------------------------------------------------------------------------*/

/* Explanation

ActivityType  = The activity type recorded under AuditTrail table
Operation     = The parent category under which there can be different activity types
SubOperation  = The sub class category of Operation for tasks assignment break up
EntityType    = Entity against which the operation is executed
Mode          = S - Considers the start of the operation; D - Data operations; E - end of operation
                This is used to decide the user assignment and there by calculate the time taken for each assingment
StandardOp    = Yes/No
UpdateCounts  = N - None; U - Units; LS - LPN SKU
Status        = (A)ctive / (I)nactive
*/

delete from ProdOperations;

 Go

insert into ProdOperations
            (ActivityType,                 Operation,     SubOperation, EntityType,  Mode, StandardOp, UpdateCounts, Status, BusinessUnit)
/*----------------------------------------------------------------------------*/
/* Batch Picking */
/*----------------------------------------------------------------------------*/
      select 'StartBatchPick',             'Picking',     null,         'PickBatch', 'S',  'Y',        'N',          'A',    BusinessUnit  from vwBusinessUnits
union select 'BatchUnitPick',              'Picking',     null,         'PickBatch', 'D',  'Y',        'U',          'A',    BusinessUnit  from vwBusinessUnits
union select 'LPNPick',                    'Picking',     null,         'PickBatch', 'D',  'Y',        'U',          'A',    BusinessUnit  from vwBusinessUnits
union select 'UnitPick',                   'Picking',     null,         'PickBatch', 'D',  'Y',        'U',          'A',    BusinessUnit  from vwBusinessUnits
union select 'PauseBatchPick',             'Picking',     null,         'PickBatch', 'D',  'Y',        'U',          'A',    BusinessUnit  from vwBusinessUnits
union select 'PickBatchCompleted',         'Picking',     null,         'PickBatch', 'D',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits
union select 'PickPalletDropped',          'Picking',     null,         'PickBatch', 'E',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits
union select 'PickTasksConfirm',           'Picking',     null,         'PickBatch', 'E',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits
union select null,                         'Picking',     'BuildCart',  'PickBatch', 'E',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits

union select null,                         'Picking',     'CancelTask', 'PickBatch', 'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits
union select 'LPNShortPicked',             'Picking',     null,         'PickBatch', 'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits
union select 'LPNShortPickedWithAvailableQty',
                                           'Picking',     null,         'PickBatch', 'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits
union select 'OrderShortPicked',           'Picking',     null,         'PickBatch', 'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits
union select 'LPNsOnPickPalletDropped',    'Picking',     null,         'PickBatch', 'E',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Reservation */
/*----------------------------------------------------------------------------*/
union select 'StartReservation',           'Reservation', null,         'PickBatch', 'S',  'Y',        'N',          'A',    BusinessUnit  from vwBusinessUnits
union select 'LPNReservedForWave',         'Reservation', null,         'PickBatch', 'D',  'Y',        'U',          'A',    BusinessUnit  from vwBusinessUnits
union select 'LPNReservedToOrder',         'Reservation', null,         'PickBatch', 'D',  'Y',        'U',          'A',    BusinessUnit  from vwBusinessUnits
union select 'ResvPalletDropped',          'Reservation', null,         'PickBatch', 'E',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Activation */
/*----------------------------------------------------------------------------*/
union select 'Activation',                 'Activation',  null,         'PickBatch', 'D',  'Y',        'N',          'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Cycle Count */
/*----------------------------------------------------------------------------*/
union select 'CCLocationConfirmedEmpty',   'Picking',     null,         'Location',  'D',  'Y',        'LIU',        'I',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Inventory Management */
/*----------------------------------------------------------------------------*/
union select 'LPNMovedToLocation',         'InvManagement', null,       'LPN',       'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'InvTransferLPNToLOC',        'InvManagement', null,       'LPN',       'D',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits
union select 'LPNAdjustQty',               'InvManagement', null,       'LPN',       'D',  'Y',        'LS',         'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Packing */
/*----------------------------------------------------------------------------*/
union select 'PackingStartBatch',          'Packing',       null,       'LPN',       'S',  'Y',        'N',          'A',    BusinessUnit  from vwBusinessUnits
union select 'Packing_PackLPN.SingleSKU',  'Packing',       null,       'LPN',       'D',  'Y',        'LSUO',       'A',    BusinessUnit  from vwBusinessUnits
union select 'Packing_PackLPN.MultipleSKUs',
                                           'Packing',       null,       'LPN',       'D',  'Y',        'LSUO',       'A',    BusinessUnit  from vwBusinessUnits
union select 'PackingCloseLPN',            'Packing',       null,       'LPN',       'D',  'Y',        'N',          'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Putaway */
/*----------------------------------------------------------------------------*/
union select 'PutawayLPNToLocation',       'Putaway',       null,       'LPN',       'E',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'PutawayLPNToPicklane',       'Putaway',       null,       'LPN',       'E',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Receiving */
/*----------------------------------------------------------------------------*/
union select 'StartReceiving',             'Receiving',  null,          'LPN',       'S',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'ReceiveToLPN',               'Receiving',  null,          'LPN',       'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'ReceiveToLocation',          'Receiving',  null,          'Location',  'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Shipping */
/*----------------------------------------------------------------------------*/
union select 'ScanLoadPallet',             'Shipping',  null,          'Pallet',     'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'ScanLoadLPN',                'Shipping',  null,          'LPN',        'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'LPNRemovedFromLoad',         'Shipping',  null,          'LPN',        'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'LPNCaptureTrackingNo',       'Shipping',  null,          'LPN',        'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'PickTicketCaptureTrackingNo','Shipping',  null,          'Order',      'D',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* LogIn */
/*----------------------------------------------------------------------------*/
union select 'RFUserLogin',                'Login',      null,          'LPN',       'S',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits
union select 'RFUserLogout',               'Login',      null,          'LPN',       'E',  'Y',        'LIU',        'A',    BusinessUnit  from vwBusinessUnits

/*----------------------------------------------------------------------------*/
/* Miscellaneous */
/*----------------------------------------------------------------------------*/
union select 'TaskUnassigned',             'Picking',     null,         'Task',      'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits
union select 'TaskDetailCancel_NoCartPosition',
                                           'Picking',     null,         'Task',      'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits
union select 'UnallocateLPNDetail',        'Picking',     null,         'LPNDetail', 'D',  'Y',        'LS',         'I',    BusinessUnit  from vwBusinessUnits

Go
