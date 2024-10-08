/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/01  GAG     File consolidation changes (CIMSV3-2473)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Import File Types
 -----------------------------------------------------------------------------*/
declare @FileTypes TLookUpsTable, @LookUpCategory TCategory = 'ImportFileType';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @FileTypes
       (LookUpCode,  LookUpDescription,        Status)
values ('SPL',       'SKU Price List',         'A'),
       ('LOC',       'Location',               'A'),
       ('PL',        'Packing List',           'I'),
       ('RT',        'Report Templates',       'A'),
       ('ZT',        'ZPL Templates',          'A'),
       ('LRI',       'Load Routing Info',      'A'),
       ('LRI_WM',    'Walmart Routing Info',   'A'),
       ('LRI_TAR',   'Target Routing Info',    'A'),
       ('INV',       'Inventory',              'A')

exec pr_LookUps_Setup @LookUpCategory, @FileTypes;

Go

/*------------------------------------------------------------------------------*/
/* Import Record Types */
/*------------------------------------------------------------------------------*/
declare @ImportRecordTypes TEntityTypesTable, @Entity TEntity = 'ImportRecordType';

/* The record types are listed below in the order of sequence in which they have to processed. This sequence should not be disturbed unless an change in the
   respective processing sequence
   Any new record types have to be inserted in the proper sequence */
insert into @ImportRecordTypes
       (TypeCode,   TypeDescription,         Status)
values ('SKU',      'SKU',                   'A'   ),
       ('UPC',      'UPC',                   'A'   ),
       ('SPP',      'SKU Prepack',           'A'   ),

       ('RH',       'Receipt Header (RH)',   'A'   ),
       ('ROH',      'Receipt Header (ROH)',  'I'   ),
       ('RD',       'Receipt Detail (RD)',   'A'   ),
       ('ROD',      'Receipt Detail (ROD)',  'I'   ),
       ('VEN',      'Vendor',                'A'   ),

       ('SOH',      'Order Header (SOH)',    'I'   ),
       ('OH',       'Order Header (OH)',     'A'   ),
       ('SOD',      'Order Detail (SOD)',    'I'   ),
       ('OD',       'Order Detail (OD)',     'A'   ),
       ('CNT',      'Address (Contact)',     'A'   ),

       ('ASNL',     'ASN LPNs',              'A'   ),
       ('ASNLH',    'ASN LPN Header',        'A'   ),
       ('ASNLD',    'ASN LPN Detail',        'A'   ),

       ('CT',       'Carton Type',           'A'   ),
       ('LOC',      'Location',              'A'   ),
       ('NOTE',     'Notes',                 'A'   ),
       ('DCMSRC',   'Router Confirmation',   'A'   ),
       ('SKUA',     'SKU Attributes',        'A'   );

exec pr_EntityTypes_Setup @Entity, @ImportRecordTypes;

Go

/*------------------------------------------------------------------------------*/
/* InterfaceLog Statuses */
/*------------------------------------------------------------------------------*/
declare @InterfaceLogStatuses TStatusesTable, @Entity TEntity = 'InterfaceLog';

insert into @InterfaceLogStatuses
       (StatusCode,  StatusDescription,  Status)
values ('S',         'Succeeded',        'A'),
       ('F',         'Failed',           'A'),
       ('P',         'Processing',       'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @InterfaceLogStatuses;

Go

/*------------------------------------------------------------------------------
 Upload Processed Flags
 -----------------------------------------------------------------------------*/
declare @Export TLookUpsTable, @LookUpCategory TCategory = 'ProcessedFlag';

insert into @Export
       (LookUpCode,  LookUpDescription,    Status)
values ('Y',         'Processed',          'A'),
       ('N',         'Not yet Processed',  'A'),
       ('I',         'Ignored',            'A'),
       ('H',         'On Hold',            'A'),
       ('X',         'Cancelled',          'A')

exec pr_LookUps_Setup @LookUpCategory, @Export, @LookUpCategoryDesc = 'Export Processed Flag';

Go

/*------------------------------------------------------------------------------
 Source System
 -----------------------------------------------------------------------------*/
declare @SourceSystems TLookUpsTable, @LookUpCategory TCategory = 'SourceSystem';

insert into @SourceSystems
       (LookUpCode,   LookUpDescription,      Status)
values ('HOST',       'Host',                 'A');

exec pr_LookUps_Setup @LookUpCategory, @SourceSystems, @LookUpCategoryDesc = 'Source Systems';

Go

/*------------------------------------------------------------------------------*/
/* Transaction Type */
/*------------------------------------------------------------------------------*/
declare @TransactionTypes TEntityTypesTable, @Entity TEntity = 'Transaction';

insert into @TransactionTypes
       (TypeCode,   TypeDescription,         Status)
values ('Recv',     'Receipts',              'A'),
       ('Return',   'Returns',               'A'),
       ('RMA',      'Returns Receiving',     'A'),
       ('InvCh',    'Inventory Changes',     'A'),
       ('Res',      'Reservation',           'I'),
       ('UnRes',    'UnReservation',         'I'),
       ('Pick',     'Picked',                'I'),
       ('Ship',     'Shipped',               'A'),
       ('PhotoIn',  'Photo In',              'I'),
       ('PhotoOut', 'Photo Out',             'I'),
       ('Xfer',     'Transfers',             'I'),
       ('SKUCh',    'SKU Change',            'I'),
       ('UPC+',     'UPC Added',             'I'),
       ('UPC-',     'UPC Removed',           'I'),
       ('ROOpen',   'RO Reopen',             'A'),
       ('ROClose',  'RO Close',              'A'),
       ('PTCancel', 'PT Cancel',             'A'),
       ('PTStatus', 'PT Status',             'A'),
       ('PTError',  'PT Exception',          'A'),
       ('WHXfer',   'WH Change',             'A'),
       ('EDI753',   'EDI 753',               'A')

exec pr_EntityTypes_Setup @Entity, @TransactionTypes;

Go

/*------------------------------------------------------------------------------*/
/* Transaction Entity */
/*------------------------------------------------------------------------------*/
declare @TransactionEntityTypes TEntityTypesTable, @Entity TEntity = 'TransEntity';

insert into @TransactionEntityTypes
       (TypeCode,  TypeDescription,        Status)
values ('LPN',     'LPN',                  'A'),
       ('LPND',    'LPN Detail',           'A'),
       ('Pallet',  'Pallet',               'A'),
       ('RH',      'Receipt Header',       'A'),
       ('RD',      'Receipt Details',      'A'),
       ('OH',      'Order Header',         'A'),
       ('OD',      'Order Details',        'A'),
       ('SKU',     'SKU Details',          'I'),
       ('RV',      'Receiver',             'A'),
       ('Load',    'Loads',                'A')

exec pr_EntityTypes_Setup @Entity, @TransactionEntityTypes;

Go
