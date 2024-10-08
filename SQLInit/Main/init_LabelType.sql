/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2012/07/03  AA      Added label type 'Ship'
  2012/04/16  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Label Type  */
/*------------------------------------------------------------------------------*/
declare @LabelTypes TEntityTypesTable, @Entity TEntity = 'Label';

insert into @LabelTypes
       (TypeCode,   TypeDescription,       Status)
values ('Location', 'Location',            'A'),
       ('C',        'Cart',                'I'),
       ('LPN',      'LPN',                 'A'),
       ('Pallet',   'Pallet',              'A'),
       ('Ship',     'Shipping Label',      'A'),
       ('SKU',      'SKU',                 'A')

exec pr_EntityTypes_Setup @Entity, @LabelTypes;

Go
