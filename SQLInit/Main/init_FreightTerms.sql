/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2019/07/25  AY      Added Sender/Disable Prepaid (CID-GoLive)
  2018/07/13  AY/PK   Added LookUpCode 'RECEIVER': Migrated from Prod (S2G-727)
  2017/09/06  DK      Added DDP and DDU (FB-1020)
  2016/02/17  YJ      Added COD,CONSIGNEE (NBD-90)
  2014/04/16  TK      Changes made to control data using procedure
  2012/06/18  TD      Initial revision.
------------------------------------------------------------------------------*/

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
