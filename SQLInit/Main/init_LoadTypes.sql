/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/16  PK      Changes to TypeCode "Transfer" (HA-2287)
  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2020/07/01  TK      Added new load type Transfers (HA-830)
  2019/09/05  RKC     Added LTL, TL two new load types (S2GCA-933)
  2019/04/06  MS      Migrated LoadTypes from HPI (CID-215)
  2016/06/13  KN      Added DHL related code (NBD-554).
  2016/02/10  KN      Added USPS Load type (NBD-162).
  2014/04/16  TK      Changes made to control data using procedure
  2012/06/18  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* LoadType */
/*------------------------------------------------------------------------------*/
declare @LoadTypes TEntityTypesTable, @Entity TEntity = 'Load';

insert into @LoadTypes
       (TypeCode,      TypeDescription,        Status)
values ('Transfer',    'Transfer',             'I'),
       ('SINGLEDROP',  'Single Drop',          'A'),
       ('MULTIDROP',   'Multiple Drop',        'A'),
       /* Canadian Small Package carriers */
       ('TFORCE',      'T-Force',              'I'),
       ('PURO',        'Purolator',            'I'),
       ('CANADAPOST',  'Canada Post',          'I'),
       ('CANPAR',      'Canpar',               'I'),
       ('LOOMIS',      'LOOMIS',               'I'),
       /* USA Small Package carriers */
       ('UPS',         'UPS',                  'I'),
       ('FEDEX',       'FEDEX',                'I'),
       ('DHL',         'DHL',                  'I'),
       ('LTL',         'Less than Truck Load', 'A'),
       ('TL',          'Truck load',           'A'),
       /* Generic usage */
       ('SMPKG',       'Small Package',        'A'),
       /* Small Package carriers by Service Class */
       ('FDEG',        'FEDEX Ground',         'A'),
       ('FDEN',        'FEDEX Express',        'A'),
       ('UPSE',        'UPS Express',          'A'),
       ('UPSN',        'UPS',                  'A'),
       ('USPS',        'USPS',                 'A');

exec pr_EntityTypes_Setup @Entity, @LoadTypes;

Go
