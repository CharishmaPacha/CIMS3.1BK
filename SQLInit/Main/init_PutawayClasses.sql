/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/04/21  AY      Added values used in the rules (HA-209)
  2015/05/02  AY      Revised to generic classes
  2014/04/16  TK      Changes made to control data using procedure
  2011/09/15  VM      Trailing space removed in 'Fragrances'
  2011/07/27  TD      SetUp  Putaway Classes.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Putaway Classes
 -----------------------------------------------------------------------------*/
declare @PutawayClasses TLookUpsTable, @LookUpCategory TCategory = 'PutawayClasses';

insert into @PutawayClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('01',        'Generic',          'A')

exec pr_LookUps_Setup @LookUpCategory, @PutawayClasses, @LookUpCategoryDesc = 'Putaway Classes';

Go

/*------------------------------------------------------------------------------
 LPNPutaway Classes
 -----------------------------------------------------------------------------*/
declare @PutawayClasses TLookUpsTable, @LookUpCategory TCategory = 'LPNPutawayClasses';

insert into @PutawayClasses
       (LookUpCode,  LookUpDescription,  Status)
values ('FL',        'Full LPN',         'A'),
       ('PL',        'Partial LPN',      'A'),
       ('QC',        'QC LPN',           'A'),
       ('RC',        'Replenish LPN',    'A'),
       ('1',         '1',                'I'),
       ('2',         '2',                'I'),
       ('3',         '3',                'I')

exec pr_LookUps_Setup @LookUpCategory, @PutawayClasses, @LookUpCategoryDesc = 'LPN Putaway Classes';

Go
