/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/27  RKC     Included Inventory (CIMSV3-1323)
  2020/01/19  AY      Included Load Routing info (HA-1926)
  2020/11/03  SV      Included PL, RT, ZT as a part of demo
  2020/10/20  SV      Included Locations to import from UI (CIMSV3-1120)
  2019/11/05  MJ      Initial revision (CID-1116)
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

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
