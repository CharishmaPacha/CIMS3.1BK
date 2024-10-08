/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/11/29  VM      File consolidation changes (CIMSV3-2475)
  2020/07/02  AY      Added TL - Task Label
  2020/04/20  NB      Initial Revision(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Document Class */
/*------------------------------------------------------------------------------*/
declare @DocumentClassLookUps TLookUpsTable, @LookUpCategory TCategory = 'DocumentClass';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @DocumentClassLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('LABEL',     'Label',                'A'),
       ('REPORT',    'Report',               'A')

exec pr_LookUps_Setup @LookUpCategory, @DocumentClassLookUps;

Go

/*------------------------------------------------------------------------------*/
 /* Document Type */
/*------------------------------------------------------------------------------*/
declare @DocumentTypesLookUps TLookUpsTable, @LookUpCategory TCategory = 'DocumentType';

insert into @DocumentTypesLookUps
       (LookUpCode,  LookUpDescription,      Status)
values ('SL',        'Ship Label',           'A'),
       ('CL',        'Contents Label',       'A'),
       ('SPL',       'Small Package Label',  'A'),
       ('PSL',       'Pallet Ship Label',    'A'),
       ('PCKL',      'Packing Label',        'A'),
       ('PTag',      'Pallet Tag',           'A'),
       ('PS',        'Price Stickers',       'I'),
       ('RL',        'Return Label',         'I'),
       ('PL',        'Packing list',         'A'),
       ('TL',        'Task Label',           'A'),
       ('PM',        'Packing Manifest',     'A'),
       ('OM',        'Order Manifest',       'A'),
       ('VI',        'VAS Instructions',     'A'),
       ('CI',        'Commercial Invoice',   'A')

exec pr_LookUps_Setup @LookUpCategory, @DocumentTypesLookUps;

Go
