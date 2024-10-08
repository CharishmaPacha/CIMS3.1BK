                                                    /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2017/12/03  CK      Setup ABC Classes
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 ABC Classes
 -----------------------------------------------------------------------------*/
declare @ABCClasses TLookUpsTable, @LookUpCategory TCategory = 'ABCClasses';

insert into @ABCClasses
       (LookUpCode,  LookUpDescription,         Status)
values ('A',        'Fast Mover',               'A'),
       ('B',        'Moderate Mover',           'A'),
       ('C',        'Slow Mover',               'A')

exec pr_LookUps_Setup @LookUpCategory, @ABCClasses, @LookUpCategoryDesc = 'ABC Classes';

Go
