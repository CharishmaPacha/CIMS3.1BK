/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/26  RT      Added Task Label (BK-534)
  2021/05/26  RV      Added Commercial Invoice (HA-2760)
  2021/04/16  RV      Added Wave label (CIMSV3-964)
  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2019/10/16  RT      Included Carrier Pallet Label (S2GCA-999)
  2018/05/09  RV      Added PSL - Pallet Ship Label (S2G-753)
  2018/12/17  RT      Added Pallet Tag (S2GMI-39)
  2016/04/26  TD      Added PS -Price Stickers
  2016/02/25  AY      Added PCKL Label type
  2014/04/16  TK      Changes made to control data using procedure
  2012/11/05  AA      Initial revision.
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