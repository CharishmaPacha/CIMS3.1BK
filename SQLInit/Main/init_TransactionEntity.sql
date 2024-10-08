/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  SK      Added Load Entity type (HA-1896)
  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/28  VM      Added Receiver
  2014/04/16  TK      Changes made to control data using procedure
  2013/08/02  TD      Added SKU entity as XSCargo need SKU changes.
  2012/03/16  PK      Added Pallet Entity as TD Needs Pallets to Putaway.
  2011/08/17  YA      Added space between words in descriptions.
  2011/02/09  PK      Added BusinessUnit field in EntityType table.
  2010/12/08  VK      Initial Revision.
------------------------------------------------------------------------------*/

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
