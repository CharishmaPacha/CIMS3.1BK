/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2012/05/12  AY      Added new Owner CB
  2012/05/05  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Owners */
/*------------------------------------------------------------------------------*/
declare @Owner TLookUpsTable, @LookUpCategory TCategory = 'Owner';

insert into @Owner
       (LookUpCode,  LookUpDescription,       Status)
/* SCT */
values ('SCT',       'Supply Chain Tech',     'A'),
/* Demo */
       ('DEMO',      'Supply Chain Tech',     'A'),
/* The Latin Products */
       ('V1',        'Vendor 1',              'A'),
       ('V2',        'Vendor 2',              'A')

exec pr_LookUps_Setup @LookUpCategory, @Owner, @LookUpCategoryDesc = 'Owners';

Go
