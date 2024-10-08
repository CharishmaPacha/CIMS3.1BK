/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/21  MS      Changed record type as DCMSRC (JL-63)
  2019/03/14  RIA     Added SKU Attributes (HPI-2485)
  2018/04/24  RV      Added RouterConfirmation (S2G-233)
  2018/01/09  OK      Added Note (S2G-51)
  2017/05/25  OK      Added RecordType for Location (CIMS-1555)
  2017/05/22  NB      Initial revision.
------------------------------------------------------------------------------*/

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