/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/01  VM      File consolidation changes (CIMSV3-2474)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  CarrierOptions
 -----------------------------------------------------------------------------*/
declare @CarrierOptions TLookUpsTable, @LookUpCategory TCategory = 'CarrierOptions';

insert into @CarrierOptions
       (LookUpCode,  LookUpDescription,           Status)
values ('N',         'No Insurance required',     'A'),
       ('IA',        'Insure All Packages',       'A'),
       ('IR',        'Insure considering Rules',  'A')

exec pr_LookUps_Setup @LookUpCategory, @CarrierOptions, @LookUpCategoryDesc = 'Carrier Options';

Go

/*------------------------------------------------------------------------------*/
 /* FreightTerms */
/*------------------------------------------------------------------------------*/
declare @FreightTerms TLookUpsTable, @LookUpCategory TCategory = 'FreightTerms';

insert into @FreightTerms
       (LookUpCode,  LookUpDescription,       Status)
values ('PREPAID',   'Pre-Paid',              'I'),
       ('SENDER',    'Sender',                'A'),
       ('COLLECT',   'Collect',               'A'),
       ('CONSIGNEE', 'Consignee',             'A'),
       ('3RDPARTY',  'Third Party billed',    'A'),
       ('COD',       'Cash on Delivery',      'I'),
       ('DDP',       'Delivered duty paid',   'A'),
       ('DDU',       'Delivered duty unpaid', 'A'),
       ('RECEIVER',  'Receiver',              'A');

exec pr_LookUps_Setup @LookUpCategory, @FreightTerms, @LookUpCategoryDesc = 'Freight Terms';

Go

/*------------------------------------------------------------------------------*/
/* Order Type  */
/*------------------------------------------------------------------------------*/
declare @OrderTypes TEntityTypesTable, @Entity TEntity = 'Order';

insert into @OrderTypes
       (TypeCode,  TypeDescription,      Status)
values ('C',       'Customer',           'A'),
       ('CO',      'Consolidate Order',  'I'),
       ('B',       'Bulk Pull',          'A'),
       ('T',       'Transfer',           'I'),
       ('MK',      'Make Kits',          'I'),
       ('BK',      'Break Kits',         'I'),
       ('RW',      'Rework',             'A'),
       ('RU',      'Replenish Units',    'A'),
       ('RP',      'Replenish Cases',    'A'),
       ('V',       'Vendor Return',      'I');

exec pr_EntityTypes_Setup @Entity, @OrderTypes;

Go

/*------------------------------------------------------------------------------*/
/* Order Status */
/*------------------------------------------------------------------------------*/
declare @OrderStatuses TStatusesTable, @Entity TEntity = 'Order';

insert into @OrderStatuses
       (StatusCode,  StatusDescription,   Status)
values ('N',         'New',               'A'),
       ('I',         'In Progress',       'I'),
       ('W',         'Waved',             'A'),
       ('A',         'Allocated',         'A'),
       ('C',         'Picking',           'A'),
       ('P',         'Picked',            'A'),
       ('K',         'Packed',            'A'),
       ('R',         'Ready To Ship',     'A'),
       ('G',         'Staged',            'A'),
       ('L',         'Loaded',            'A'),
       ('TC',        'To Consolidate',    'I'),
       ('V',         'Invoiced',          'I'),
       ('O',         'Downloaded',        'A')

insert into @OrderStatuses
       (StatusCode,  StatusDescription,  Status,  SortSeq)
values ('S',         'Shipped',          'A',     90),
       ('D',         'Completed',        'A',     91),
       ('E',         'Cancel in Progress',
                                         'I',     92),
       ('X',         'Canceled',         'A',     93),
       ('H',         'Pack & Hold',      'A',     94)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @OrderStatuses;

Go
