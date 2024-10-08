/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/15  VM      File consolidation changes (CIMSV3-2511)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Label Type */
/*------------------------------------------------------------------------------*/
declare @LabelTypesLookUps TLookUpsTable, @LookUpCategory TCategory = 'LabelType';

insert into @LabelTypesLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('SL',        'Ship Label',           'A'),
       ('CL',        'Content Label',        'A'),
       ('SPL',       'Small Package Label',  'A'),
       ('CPL',       'Carrier Pallet Label', 'A'),
       ('PSL',       'Pallet Ship Label',    'A'),
       ('PCKL',      'Packing Label',        'A'),
       ('PL',        'Packing List',         'A'),
       ('CI',        'Commercial Invoice',   'A'),
       ('PTag',      'Pallet Tag',           'A'),
       ('WL',        'Wave Label',           'A'),
       ('TL',        'Task Label',           'A'),
       ('STL',       'Style Label',          'A'),
       ('PS',        'Price Stickers',       'I')

exec pr_LookUps_Setup @LookUpCategory, @LabelTypesLookUps, @LookUpCategoryDesc = 'Label Type';

Go

/*------------------------------------------------------------------------------*/
 /* Label Print Sort Order */
/*------------------------------------------------------------------------------*/
declare @LabelPrintSortOrder TLookUpsTable, @LookUpCategory TCategory = 'LabelPrintSortOrder';

insert into @LabelPrintSortOrder
       (LookUpCode,  LookUpDescription,         Status)
values ('BPL',       'Wave, PickTicket, LPN',   'A')

exec pr_LookUps_Setup @LookUpCategory, @LabelPrintSortOrder, @LookUpCategoryDesc = 'Label Print Sort Sequence';

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

/*------------------------------------------------------------------------------*/
/* Print Label Type */
/*------------------------------------------------------------------------------*/
declare @LabelTypesLookUps TLookUpsTable, @LookUpCategory TCategory = 'RePrintLabelType';

insert into @LabelTypesLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('SL',        'Reprint Ship Label',   'A')

exec pr_LookUps_Setup @LookUpCategory, @LabelTypesLookUps, @LookUpCategoryDesc = 'Reprint Label Type';

Go
