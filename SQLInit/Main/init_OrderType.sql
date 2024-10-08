/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/15  VS      Added Consolidated OrderType (CID-334)
  2019/01/24  TK      Renamed Pack Kits - Make Kits, Unpack Kits - Break Kits (S2GMI-87)
  2014/04/16  TK      Changes made to control data using procedure
  2013/06/17  TD      Added Order Type 'R' Replenish.
  2012/05/12  AY      Changed for TD
  2012/05/10  PK      Added Order Type 'B' Bulk Pull
------------------------------------------------------------------------------*/

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
