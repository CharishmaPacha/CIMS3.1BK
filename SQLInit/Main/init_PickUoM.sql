/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/09/18  VM      Script updated with latest format (HA-1425)
  2014/02/20  TD      Initial revision.
------------------------------------------------------------------------------*/

Go
/*------------------------------------------------------------------------------
  PickUoM
 -----------------------------------------------------------------------------*/
declare @PickUoMs TLookUpsTable, @LookUpCategory TCategory = 'PickUoM';

insert into @PickUoMs
       (LookUpCode,  LookUpDescription,      SortSeq,  Status, Visible)
values ('U',         'Units',                1,        'A',    'False'),
       ('C',         'Cases',                2,        'A',    'False'),
       ('B',         'Bulk',                 3,        'A',    'False')

exec pr_LookUps_Setup @LookUpCategory, @PickUoMs, @LookUpCategoryDesc = 'Pick UoM';

Go
