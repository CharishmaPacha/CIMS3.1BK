/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2017/12/03  TD      Setup Location Classes
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Location Classes
 -----------------------------------------------------------------------------*/
declare @LocClasses TLookUpsTable, @LookUpCategory TCategory = 'LocationClasses';

insert into @LocClasses
       (LookUpCode,  LookUpDescription,         Status)
values ('RP',        'Reserve Pallet Racks',    'A'),
       ('RF',        'Reserve Floor Locations', 'A'),
       ('P1',        'Picklanes',               'A'),
       ('B',         'Bulk Locations',          'A')

exec pr_LookUps_Setup @LookUpCategory, @LocClasses, @LookUpCategoryDesc = 'Location Classes';

Go
