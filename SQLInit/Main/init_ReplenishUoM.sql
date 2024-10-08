/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/03/21  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Replenish UoMs
 -----------------------------------------------------------------------------*/
declare @UoMs TLookUpsTable, @LookUpCategory TCategory = 'ReplenishUoM';

insert into @UoMs
       (LookUpCode,   LookUpDescription,            Status)
values ('LPN',        'Pallets',                    'A'),
       ('CS',         'Cases',                      'A'),
       ('EA',         'Eaches',                     'A')

exec pr_LookUps_Setup @LookUpCategory, @UoMs, @LookUpCategoryDesc = 'Replenish UoM';

Go
