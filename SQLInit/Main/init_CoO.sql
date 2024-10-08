/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2019/09/10  SPP     Added new lookups (CID-136) (Ported from Prod)
  2014/04/16  TK      Changes made to control data using procedure
  2012/05/01  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Countries Of Origin */
/*------------------------------------------------------------------------------*/
declare @CoO TLookUpsTable, @LookUpCategory TCategory = 'CoO';

insert into @CoO
       (LookUpCode,  LookUpDescription,  Status)
values ('US',        'United States',    'A'),
       ('AF',        'Afghanistan',      'A'),
       ('CN',        'China',            'A'),
       ('ID',        'Indonesia',        'A'),
       ('LK',        'Sri Lanka',        'A'),
       ('IN',        'India',            'A'),
       ('BG',        'Bangladesh',       'A'),
       ('CH',        'China',            'A'),
       ('EG',        'Egypt',            'A'),
       ('HT',        'Haiti',            'A'),
       ('MG',        'Madagascar',       'A'),
       ('USA',       'United States',    'A'),
       ('VN',        'Vietnam',          'A')

exec pr_LookUps_Setup @LookUpCategory, @CoO, @LookUpCategoryDesc = 'Country of Origin';

Go
